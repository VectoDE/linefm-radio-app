#include "archive.h"

#include <compressapi.h>

#include <algorithm>
#include <cstring>

namespace lf {

// --- PE-Hilfen --------------------------------------------------------------

bool PeOverlayEnd(HANDLE file, uint64_t* end) {
  LARGE_INTEGER size = {};
  if (!::GetFileSizeEx(file, &size)) return false;
  *end = static_cast<uint64_t>(size.QuadPart);

  auto read_at = [&](uint64_t offset, void* buffer, DWORD length) {
    OVERLAPPED ov = {};
    ov.Offset = static_cast<DWORD>(offset);
    ov.OffsetHigh = static_cast<DWORD>(offset >> 32);
    DWORD read = 0;
    return ::ReadFile(file, buffer, length, &read, &ov) && read == length;
  };

  IMAGE_DOS_HEADER dos = {};
  if (!read_at(0, &dos, sizeof(dos)) || dos.e_magic != IMAGE_DOS_SIGNATURE) {
    return true;  // keine PE-Datei: ganze Datei zaehlt
  }
  DWORD signature = 0;
  if (!read_at(static_cast<uint64_t>(dos.e_lfanew), &signature,
               sizeof(signature)) ||
      signature != IMAGE_NT_SIGNATURE) {
    return true;
  }
  const uint64_t optional_offset =
      static_cast<uint64_t>(dos.e_lfanew) + sizeof(DWORD) +
      sizeof(IMAGE_FILE_HEADER);
  WORD magic = 0;
  if (!read_at(optional_offset, &magic, sizeof(magic))) return true;
  IMAGE_DATA_DIRECTORY security = {};
  if (magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC) {
    IMAGE_OPTIONAL_HEADER64 header = {};
    if (!read_at(optional_offset, &header, sizeof(header))) return true;
    if (header.NumberOfRvaAndSizes > IMAGE_DIRECTORY_ENTRY_SECURITY) {
      security = header.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY];
    }
  } else if (magic == IMAGE_NT_OPTIONAL_HDR32_MAGIC) {
    IMAGE_OPTIONAL_HEADER32 header = {};
    if (!read_at(optional_offset, &header, sizeof(header))) return true;
    if (header.NumberOfRvaAndSizes > IMAGE_DIRECTORY_ENTRY_SECURITY) {
      security = header.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY];
    }
  }
  // Bei der Sicherheitstabelle ist VirtualAddress ein Datei-Offset.
  if (security.VirtualAddress != 0 && security.Size != 0 &&
      security.VirtualAddress <= *end) {
    *end = security.VirtualAddress;
  }
  return true;
}

// --- Kompression ------------------------------------------------------------

bool DecompressLzms(const uint8_t* data, size_t size, uint8_t* out,
                    size_t out_size) {
  DECOMPRESSOR_HANDLE handle = nullptr;
  if (!::CreateDecompressor(COMPRESS_ALGORITHM_LZMS, nullptr, &handle)) {
    return false;
  }
  SIZE_T produced = 0;
  const BOOL ok =
      ::Decompress(handle, data, size, out, out_size, &produced);
  ::CloseDecompressor(handle);
  return ok && produced == out_size;
}

bool CompressLzms(const uint8_t* data, size_t size,
                  std::vector<uint8_t>* out) {
  if (size < 4096) return false;
  COMPRESSOR_HANDLE handle = nullptr;
  if (!::CreateCompressor(COMPRESS_ALGORITHM_LZMS, nullptr, &handle)) {
    return false;
  }
  SIZE_T needed = 0;
  ::Compress(handle, data, size, nullptr, 0, &needed);
  bool ok = false;
  if (needed > 0) {
    out->resize(needed);
    SIZE_T produced = 0;
    if (::Compress(handle, data, size, out->data(), out->size(), &produced)) {
      out->resize(produced);
      ok = produced + 64 < size;  // nur behalten, wenn es spuerbar kleiner ist
    }
  }
  ::CloseCompressor(handle);
  return ok;
}

// --- Dateien ----------------------------------------------------------------

bool WriteWholeFile(const std::wstring& path, const void* data, size_t size,
                    DWORD* error) {
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    if (error != nullptr) *error = ::GetLastError();
    return false;
  }
  const auto* bytes = static_cast<const uint8_t*>(data);
  size_t left = size;
  bool ok = true;
  while (left > 0) {
    const DWORD chunk = static_cast<DWORD>(std::min<size_t>(left, 1u << 24));
    DWORD written = 0;
    if (!::WriteFile(file, bytes, chunk, &written, nullptr) ||
        written != chunk) {
      ok = false;
      if (error != nullptr) *error = ::GetLastError();
      break;
    }
    bytes += chunk;
    left -= chunk;
  }
  if (ok && !::FlushFileBuffers(file)) {
    ok = false;
    if (error != nullptr) *error = ::GetLastError();
  }
  ::CloseHandle(file);
  if (!ok) ::DeleteFileW(path.c_str());
  return ok;
}

bool ReadWholeFile(const std::wstring& path, std::vector<uint8_t>* out) {
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                              nullptr, OPEN_EXISTING, 0, nullptr);
  if (file == INVALID_HANDLE_VALUE) return false;
  LARGE_INTEGER size = {};
  bool ok = ::GetFileSizeEx(file, &size) &&
            static_cast<uint64_t>(size.QuadPart) <= kMaxEntrySize;
  if (ok) {
    out->resize(static_cast<size_t>(size.QuadPart));
    size_t done = 0;
    while (ok && done < out->size()) {
      const DWORD chunk =
          static_cast<DWORD>(std::min<size_t>(out->size() - done, 1u << 24));
      DWORD read = 0;
      ok = ::ReadFile(file, out->data() + done, chunk, &read, nullptr) &&
           read == chunk;
      done += read;
    }
  }
  ::CloseHandle(file);
  return ok;
}

// --- Payload ----------------------------------------------------------------

Payload::~Payload() {
  if (file_ != INVALID_HANDLE_VALUE) ::CloseHandle(file_);
}

bool Payload::ReadAt(uint64_t offset, void* buffer, size_t size) {
  auto* bytes = static_cast<uint8_t*>(buffer);
  while (size > 0) {
    OVERLAPPED ov = {};
    ov.Offset = static_cast<DWORD>(offset);
    ov.OffsetHigh = static_cast<DWORD>(offset >> 32);
    const DWORD chunk = static_cast<DWORD>(std::min<size_t>(size, 1u << 24));
    DWORD read = 0;
    if (!::ReadFile(file_, bytes, chunk, &read, &ov) || read != chunk) {
      return false;
    }
    bytes += chunk;
    offset += chunk;
    size -= chunk;
  }
  return true;
}

bool Payload::Open(const std::wstring& path, std::wstring* error) {
  // FILE_SHARE_READ ohne FILE_SHARE_WRITE: niemand kann die Nutzlast waehrend
  // des Laufs veraendern (die laufende EXE ist ohnehin gegen Schreiben
  // gesperrt).
  file_ = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                        OPEN_EXISTING, FILE_FLAG_RANDOM_ACCESS, nullptr);
  if (file_ == INVALID_HANDLE_VALUE) {
    if (error != nullptr) {
      *error = L"Setup-Datei nicht lesbar: " + FormatWin32Error(::GetLastError());
    }
    return false;
  }
  uint64_t end = 0;
  if (!PeOverlayEnd(file_, &end) || end < sizeof(PayloadFooter)) {
    return true;  // keine Nutzlast (z. B. uninstall.exe)
  }
  PayloadFooter footer = {};
  if (!ReadAt(end - sizeof(footer), &footer, sizeof(footer)) ||
      std::memcmp(footer.magic, kFooterMagic, sizeof(kFooterMagic)) != 0) {
    return true;
  }
  if (footer.archive_size < sizeof(ArchiveHeader) ||
      footer.archive_offset + footer.archive_size + sizeof(footer) != end) {
    if (error != nullptr) *error = L"Nutzlast beschaedigt (Fusszeile)";
    return false;
  }
  ArchiveHeader header = {};
  if (!ReadAt(footer.archive_offset, &header, sizeof(header)) ||
      std::memcmp(header.magic, kArchiveMagic, sizeof(kArchiveMagic)) != 0 ||
      header.index_size > footer.archive_size - sizeof(header) ||
      header.index_size > (64u << 20) || header.entry_count > 100000) {
    if (error != nullptr) *error = L"Nutzlast beschaedigt (Kopf)";
    return false;
  }
  std::vector<uint8_t> index(static_cast<size_t>(header.index_size));
  if (!ReadAt(footer.archive_offset + sizeof(header), index.data(),
              index.size())) {
    if (error != nullptr) *error = L"Nutzlast beschaedigt (Index)";
    return false;
  }
  data_start_ = footer.archive_offset + sizeof(header) + header.index_size;
  const uint64_t data_size = footer.archive_size - sizeof(header) -
                             header.index_size;
  size_t pos = 0;
  for (uint32_t i = 0; i < header.entry_count; ++i) {
    IndexEntryHeader eh = {};
    if (pos + sizeof(eh) > index.size()) {
      if (error != nullptr) *error = L"Nutzlast beschaedigt (Eintrag)";
      return false;
    }
    std::memcpy(&eh, index.data() + pos, sizeof(eh));
    pos += sizeof(eh);
    if (eh.path_size == 0 || eh.path_size > 1024 ||
        pos + eh.path_size > index.size() || eh.size > kMaxEntrySize ||
        eh.stored_size > kMaxEntrySize ||
        eh.data_offset > data_size ||
        eh.stored_size > data_size - eh.data_offset ||
        ((eh.flags & kEntryCompressed) == 0 && eh.stored_size != eh.size)) {
      if (error != nullptr) *error = L"Nutzlast beschaedigt (Eintrag)";
      return false;
    }
    ArchiveEntry entry;
    entry.path = Utf8ToWide(std::string(
        reinterpret_cast<const char*>(index.data() + pos), eh.path_size));
    pos += eh.path_size;
    // Pfade duerfen den Zielordner nicht verlassen.
    if (entry.path.empty() || entry.path.find(L"..") != std::wstring::npos ||
        entry.path.find(L':') != std::wstring::npos ||
        entry.path.find(L'\\') != std::wstring::npos ||
        entry.path.front() == L'/') {
      if (error != nullptr) *error = L"Nutzlast enthaelt unzulaessigen Pfad";
      return false;
    }
    entry.flags = eh.flags;
    entry.size = eh.size;
    entry.stored_size = eh.stored_size;
    entry.data_offset = eh.data_offset;
    std::memcpy(entry.sha256, eh.sha256, sizeof(entry.sha256));
    entries_.push_back(std::move(entry));
  }
  footer_ = footer;
  has_payload_ = true;
  return true;
}

bool Payload::VerifyArchiveHash(std::wstring* error) {
  if (!has_payload_) return false;
  Sha256 sha;
  std::vector<uint8_t> buffer(1 << 20);
  uint64_t offset = footer_.archive_offset;
  uint64_t left = footer_.archive_size;
  while (left > 0) {
    const size_t chunk =
        static_cast<size_t>(std::min<uint64_t>(left, buffer.size()));
    if (!ReadAt(offset, buffer.data(), chunk)) {
      if (error != nullptr) *error = L"Nutzlast nicht lesbar";
      return false;
    }
    sha.Update(buffer.data(), chunk);
    offset += chunk;
    left -= chunk;
  }
  uint8_t digest[32] = {};
  if (!sha.Final(digest) ||
      std::memcmp(digest, footer_.sha256, sizeof(digest)) != 0) {
    if (error != nullptr) {
      *error = L"Pruefsumme der Nutzlast stimmt nicht (Download beschaedigt?)";
    }
    return false;
  }
  return true;
}

const ArchiveEntry* Payload::Find(const std::wstring& path) const {
  for (const auto& entry : entries_) {
    if (EqualsI(entry.path, path)) return &entry;
  }
  return nullptr;
}

bool Payload::Extract(const ArchiveEntry& entry, std::vector<uint8_t>* out,
                      std::wstring* error) {
  std::vector<uint8_t> stored(static_cast<size_t>(entry.stored_size));
  if (!stored.empty() &&
      !ReadAt(data_start_ + entry.data_offset, stored.data(), stored.size())) {
    if (error != nullptr) *error = L"Nutzlast nicht lesbar: " + entry.path;
    return false;
  }
  if (entry.flags & kEntryCompressed) {
    out->resize(static_cast<size_t>(entry.size));
    if (!DecompressLzms(stored.data(), stored.size(), out->data(),
                        out->size())) {
      if (error != nullptr) *error = L"Entpacken fehlgeschlagen: " + entry.path;
      return false;
    }
  } else {
    *out = std::move(stored);
  }
  uint8_t digest[32] = {};
  if (!Sha256Buffer(out->data(), out->size(), digest) ||
      std::memcmp(digest, entry.sha256, sizeof(digest)) != 0) {
    if (error != nullptr) *error = L"Pruefsumme stimmt nicht: " + entry.path;
    return false;
  }
  return true;
}

bool Payload::ExtractToFile(const ArchiveEntry& entry, const std::wstring& path,
                            std::wstring* error) {
  std::vector<uint8_t> data;
  if (!Extract(entry, &data, error)) return false;
  DWORD code = 0;
  if (!WriteWholeFile(path, data.data(), data.size(), &code)) {
    if (error != nullptr) {
      *error = L"Schreiben fehlgeschlagen: " + path + L" (" +
               FormatWin32Error(code) + L")";
    }
    return false;
  }
  return true;
}

bool Payload::ReadProduct(Product* product, std::wstring* error) {
  const ArchiveEntry* entry = Find(L"meta/product.ini");
  if (entry == nullptr) {
    if (error != nullptr) *error = L"Produktdaten fehlen in der Nutzlast";
    return false;
  }
  std::vector<uint8_t> data;
  if (!Extract(*entry, &data, error)) return false;
  return ParseProduct(std::string(data.begin(), data.end()), product, error);
}

}  // namespace lf
