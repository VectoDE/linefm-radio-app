// lfpack: baut setup.exe aus Stub, App-Dateien, Setup-Oberflaeche und
// Produktdaten. Nur fuer die CI (und lokale Builds), wird nicht ausgeliefert.
//
//   lfpack --stub <setup-stub.exe> --uninstaller <setup-stub.exe>
//          --app <Release-Ordner der App> --ui <Release-Ordner der Oberflaeche>
//          --ui-file <Archivpfad>=<Datei> (mehrfach, z. B. LICENSE.txt, fonts/...)
//          --product <installer.ini> --version <x.y.z[-suffix]> --out <setup.exe>
#include <cstdio>
#include <cstring>
#include <future>
#include <map>
#include <thread>

#include "../common/archive.h"
#include "../common/base.h"

using namespace lf;

namespace {

struct Source {
  std::string archive_path;  // mit '/'
  std::wstring file;
};

void Print(const std::wstring& text) {
  const std::string utf8 = WideToUtf8(text) + "\n";
  fwrite(utf8.data(), 1, utf8.size(), stdout);
  fflush(stdout);
}

int Fail(const std::wstring& text) {
  Print(L"lfpack: Fehler: " + text);
  return 1;
}

void CollectDir(const std::wstring& root, const std::wstring& rel,
                const std::string& prefix, std::vector<Source>* out) {
  WIN32_FIND_DATAW data = {};
  const std::wstring dir = rel.empty() ? root : JoinPath(root, rel);
  HANDLE find = ::FindFirstFileExW(JoinPath(dir, L"*").c_str(),
                                   FindExInfoBasic, &data,
                                   FindExSearchNameMatch, nullptr, 0);
  if (find == INVALID_HANDLE_VALUE) return;
  std::vector<std::wstring> names;
  do {
    const std::wstring name = data.cFileName;
    if (name == L"." || name == L"..") continue;
    names.push_back(name);
  } while (::FindNextFileW(find, &data));
  ::FindClose(find);
  std::sort(names.begin(), names.end());  // reproduzierbare Reihenfolge
  for (const auto& name : names) {
    const std::wstring child_rel = rel.empty() ? name : rel + L"/" + name;
    const std::wstring full = JoinPath(root, child_rel);
    const DWORD attr = ::GetFileAttributesW(full.c_str());
    if (attr & FILE_ATTRIBUTE_REPARSE_POINT) continue;
    if (attr & FILE_ATTRIBUTE_DIRECTORY) {
      CollectDir(root, child_rel, prefix, out);
    } else {
      // Debug-Symbole und Hilfsdateien nicht ausliefern.
      const std::wstring lower = Lower(name);
      if (lower.size() > 4 && (lower.compare(lower.size() - 4, 4, L".pdb") == 0 ||
                               lower.compare(lower.size() - 4, 4, L".lib") == 0 ||
                               lower.compare(lower.size() - 4, 4, L".exp") == 0)) {
        continue;
      }
      out->push_back({prefix + WideToUtf8(child_rel), full});
    }
  }
}

struct Blob {
  std::vector<uint8_t> raw;
  std::vector<uint8_t> stored;
  bool compressed = false;
  uint64_t offset = 0;
};

}  // namespace

int wmain(int argc, wchar_t** argv) {
  std::wstring stub, uninstaller, app_dir, ui_dir, product_path, version, out;
  std::vector<Source> extras;
  for (int i = 1; i < argc; ++i) {
    const std::wstring a = argv[i];
    auto next = [&]() { return i + 1 < argc ? std::wstring(argv[++i]) : L""; };
    if (a == L"--stub") stub = next();
    else if (a == L"--uninstaller") uninstaller = next();
    else if (a == L"--app") app_dir = next();
    else if (a == L"--ui") ui_dir = next();
    else if (a == L"--product") product_path = next();
    else if (a == L"--version") version = next();
    else if (a == L"--out") out = next();
    else if (a == L"--ui-file") {
      const std::wstring spec = next();
      const size_t eq = spec.find(L'=');
      if (eq == std::wstring::npos) return Fail(L"--ui-file erwartet pfad=datei");
      extras.push_back({"ui/" + WideToUtf8(spec.substr(0, eq)), spec.substr(eq + 1)});
    } else {
      return Fail(L"Unbekannter Parameter " + a);
    }
  }
  if (stub.empty() || uninstaller.empty() || app_dir.empty() || ui_dir.empty() ||
      product_path.empty() || version.empty() || out.empty()) {
    return Fail(L"Parameter fehlen (siehe Kopf von packer/main.cpp)");
  }

  // Produktdaten: Datei + Version, Pflichtfelder pruefen.
  std::vector<uint8_t> ini_raw;
  if (!ReadWholeFile(product_path, &ini_raw)) return Fail(L"Produktdatei fehlt");
  std::string ini(ini_raw.begin(), ini_raw.end());
  if (!ini.empty() && ini.back() != '\n') ini += "\n";
  ini += "version=" + WideToUtf8(version) + "\n";
  Product product;
  std::wstring error;
  if (!ParseProduct(ini, &product, &error)) return Fail(error);

  std::vector<Source> sources;
  CollectDir(FullPath(app_dir), L"", "app/", &sources);
  if (sources.empty()) return Fail(L"App-Ordner leer: " + app_dir);
  bool has_exe = false;
  for (const auto& s : sources) {
    if (EqualsI(Utf8ToWide(s.archive_path), L"app/" + product.exe_name)) {
      has_exe = true;
    }
  }
  if (!has_exe) return Fail(L"Programmdatei fehlt im App-Ordner");
  const size_t app_count = sources.size();
  CollectDir(FullPath(ui_dir), L"", "ui/", &sources);
  if (sources.size() == app_count) return Fail(L"UI-Ordner leer: " + ui_dir);
  for (const auto& e : extras) sources.push_back(e);
  sources.push_back({"meta/uninstall.exe", FullPath(uninstaller)});

  // Inhalte lesen, deduplizieren.
  std::map<std::string, size_t> by_hash;
  std::vector<Blob> blobs;
  struct Entry {
    std::string path;
    size_t blob;
    uint8_t sha[32];
  };
  std::vector<Entry> entries;
  auto add = [&](const std::string& path, std::vector<uint8_t> data) {
    Entry entry;
    entry.path = path;
    Sha256Buffer(data.data(), data.size(), entry.sha);
    const std::string key = ToHex(entry.sha, 32);
    auto it = by_hash.find(key);
    if (it == by_hash.end()) {
      Blob blob;
      blob.raw = std::move(data);
      blobs.push_back(std::move(blob));
      it = by_hash.emplace(key, blobs.size() - 1).first;
    }
    entry.blob = it->second;
    entries.push_back(entry);
  };
  for (const auto& s : sources) {
    std::vector<uint8_t> data;
    if (!ReadWholeFile(s.file, &data)) return Fail(L"Nicht lesbar: " + s.file);
    add(s.archive_path, std::move(data));
  }
  add("meta/product.ini", std::vector<uint8_t>(ini.begin(), ini.end()));

  // Parallel packen (LZMS ist langsam, aber stark).
  {
    std::vector<std::future<void>> jobs;
    const unsigned workers = std::max(1u, std::thread::hardware_concurrency());
    std::atomic<size_t> next_blob{0};
    for (unsigned w = 0; w < workers; ++w) {
      jobs.push_back(std::async(std::launch::async, [&]() {
        for (;;) {
          const size_t i = next_blob++;
          if (i >= blobs.size()) return;
          Blob& b = blobs[i];
          b.compressed = CompressLzms(b.raw.data(), b.raw.size(), &b.stored);
          if (!b.compressed) b.stored = b.raw;
        }
      }));
    }
    for (auto& j : jobs) j.get();
  }

  // Archiv zusammensetzen.
  std::vector<uint8_t> index;
  for (const auto& e : entries) {
    const Blob& b = blobs[e.blob];
    IndexEntryHeader h = {};
    h.flags = b.compressed ? kEntryCompressed : 0;
    h.path_size = static_cast<uint32_t>(e.path.size());
    h.size = b.raw.size();
    h.stored_size = b.stored.size();
    std::memcpy(h.sha256, e.sha, 32);
    (void)h;
    index.insert(index.end(), reinterpret_cast<uint8_t*>(&h),
                 reinterpret_cast<uint8_t*>(&h) + sizeof(h));
    index.insert(index.end(), e.path.begin(), e.path.end());
  }
  uint64_t offset = 0;
  for (auto& b : blobs) {
    b.offset = offset;
    offset += b.stored.size();
  }
  // Offsets nachtragen.
  {
    size_t pos = 0;
    for (const auto& e : entries) {
      IndexEntryHeader h = {};
      std::memcpy(&h, index.data() + pos, sizeof(h));
      h.data_offset = blobs[e.blob].offset;
      std::memcpy(index.data() + pos, &h, sizeof(h));
      pos += sizeof(h) + e.path.size();
    }
  }

  std::vector<uint8_t> stub_data;
  if (!ReadWholeFile(stub, &stub_data)) return Fail(L"Stub fehlt");
  while (stub_data.size() % 8 != 0) stub_data.push_back(0);

  ArchiveHeader header = {};
  std::memcpy(header.magic, kArchiveMagic, 8);
  header.entry_count = static_cast<uint32_t>(entries.size());
  header.index_size = index.size();

  std::vector<uint8_t> archive;
  archive.insert(archive.end(), reinterpret_cast<uint8_t*>(&header),
                 reinterpret_cast<uint8_t*>(&header) + sizeof(header));
  archive.insert(archive.end(), index.begin(), index.end());
  for (const auto& b : blobs) {
    archive.insert(archive.end(), b.stored.begin(), b.stored.end());
  }
  // Gesamtgroesse auf 8 Byte ausrichten: signtool haengt die Signatur an
  // einer 8-Byte-Grenze an, die Fusszeile muss direkt davor stehen.
  while (archive.size() % 8 != 0) archive.push_back(0);

  PayloadFooter footer = {};
  std::memcpy(footer.magic, kFooterMagic, 8);
  footer.archive_offset = stub_data.size();
  footer.archive_size = archive.size();
  Sha256Buffer(archive.data(), archive.size(), footer.sha256);

  std::vector<uint8_t> result;
  result.reserve(stub_data.size() + archive.size() + sizeof(footer));
  result.insert(result.end(), stub_data.begin(), stub_data.end());
  result.insert(result.end(), archive.begin(), archive.end());
  result.insert(result.end(), reinterpret_cast<uint8_t*>(&footer),
                reinterpret_cast<uint8_t*>(&footer) + sizeof(footer));
  DWORD code = 0;
  if (!WriteWholeFile(FullPath(out), result.data(), result.size(), &code)) {
    return Fail(L"Ausgabe nicht schreibbar: " + FormatWin32Error(code));
  }

  uint64_t raw_total = 0;
  for (const auto& e : entries) raw_total += blobs[e.blob].raw.size();
  Print(L"lfpack: " + product.name + L" " + product.version);
  Print(L"  Dateien: " + std::to_wstring(entries.size()) + L" (einzigartig " +
        std::to_wstring(blobs.size()) + L")");
  Print(L"  Rohgroesse: " + std::to_wstring(raw_total / 1024) + L" KiB");
  Print(L"  setup.exe: " + std::to_wstring(result.size() / 1024) + L" KiB");
  Print(L"  SHA-256 Archiv: " + Utf8ToWide(ToHex(footer.sha256, 32)));
  return 0;
}
