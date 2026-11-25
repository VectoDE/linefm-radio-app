// Nutzlast-Format von setup.exe.
//
//   setup.exe = [Stub-EXE][Archiv][Fusszeile (64 Byte)][evtl. Authenticode]
//
// Archiv (Little Endian):
//   ArchiveHeader
//   Index: entry_count Eintraege (IndexEntry + Pfad in UTF-8, '/' getrennt)
//   Datenbereich: komprimierte Dateien (LZMS, Compression-API), gleiche
//   Inhalte nur einmal (Deduplizierung ueber SHA-256)
//
// Pfad-Praefixe: "app/" = Programmdateien, "ui/" = Setup-Oberflaeche,
// "meta/product.ini" = Produktdaten, "meta/uninstall.exe" = Deinstallierer.
//
// Fusszeile: Magic, Offset und Laenge des Archivs, SHA-256 ueber das ganze
// Archiv. Signiert die CI setup.exe, deckt die Authenticode-Signatur Stub,
// Archiv und Fusszeile ab; die Fusszeile steht dann direkt vor der
// Zertifikatstabelle.
#pragma once

#include "base.h"

#include <map>
#include <memory>

namespace lf {

constexpr char kArchiveMagic[8] = {'L', 'F', 'A', 'R', 'C', 'H', '0', '1'};
constexpr char kFooterMagic[8] = {'L', 'F', 'P', 'A', 'Y', 'L', 'D', '1'};

#pragma pack(push, 1)
struct ArchiveHeader {
  char magic[8];
  uint32_t entry_count;
  uint32_t reserved;
  uint64_t index_size;  // Bytes des Index direkt nach dem Header
};

struct IndexEntryHeader {
  uint32_t flags;  // kEntryCompressed
  uint32_t path_size;
  uint64_t size;       // Originalgroesse
  uint64_t stored_size;
  uint64_t data_offset;  // relativ zum Beginn des Datenbereichs
  uint8_t sha256[32];    // SHA-256 des Originals
};

struct PayloadFooter {
  char magic[8];
  uint64_t archive_offset;
  uint64_t archive_size;
  uint8_t sha256[32];
  uint64_t reserved;
};
#pragma pack(pop)

static_assert(sizeof(PayloadFooter) == 64, "Fusszeile muss 64 Byte haben");

constexpr uint32_t kEntryCompressed = 1;
// Groesste zulaessige Einzeldatei (Schutz vor manipulierten Indexwerten).
constexpr uint64_t kMaxEntrySize = 1ull << 31;

struct ArchiveEntry {
  std::wstring path;  // mit '/' wie im Archiv
  uint32_t flags = 0;
  uint64_t size = 0;
  uint64_t stored_size = 0;
  uint64_t data_offset = 0;
  uint8_t sha256[32] = {};
};

// Liest die Nutzlast aus einer Datei (setup.exe selbst).
class Payload {
 public:
  Payload() = default;
  ~Payload();
  Payload(const Payload&) = delete;
  Payload& operator=(const Payload&) = delete;

  // Oeffnet die Datei schreibgeschuetzt (andere duerfen nicht schreiben),
  // sucht die Fusszeile und liest den Index. Prueft NICHT den Gesamt-Hash.
  bool Open(const std::wstring& path, std::wstring* error);
  // SHA-256 ueber das ganze Archiv gegen die Fusszeile pruefen.
  bool VerifyArchiveHash(std::wstring* error);
  bool has_payload() const { return has_payload_; }

  const std::vector<ArchiveEntry>& entries() const { return entries_; }
  const ArchiveEntry* Find(const std::wstring& path) const;
  // Liest, entpackt und prueft den SHA-256 eines Eintrags.
  bool Extract(const ArchiveEntry& entry, std::vector<uint8_t>* out,
               std::wstring* error);
  bool ExtractToFile(const ArchiveEntry& entry, const std::wstring& path,
                     std::wstring* error);
  // Produktdaten aus meta/product.ini.
  bool ReadProduct(Product* product, std::wstring* error);

 private:
  bool ReadAt(uint64_t offset, void* buffer, size_t size);

  HANDLE file_ = INVALID_HANDLE_VALUE;
  bool has_payload_ = false;
  PayloadFooter footer_ = {};
  uint64_t data_start_ = 0;  // absoluter Offset des Datenbereichs
  std::vector<ArchiveEntry> entries_;
};

// Entpackt LZMS-Daten (Compression-API, Puffermodus).
bool DecompressLzms(const uint8_t* data, size_t size, uint8_t* out,
                    size_t out_size);
// Packt mit LZMS. Gibt false zurueck, wenn sich Packen nicht lohnt.
bool CompressLzms(const uint8_t* data, size_t size,
                  std::vector<uint8_t>* out);

// Schreibt eine Datei vollstaendig (CREATE_ALWAYS). Fuer neue Dateien in
// privaten Ordnern.
bool WriteWholeFile(const std::wstring& path, const void* data, size_t size,
                    DWORD* error = nullptr);
bool ReadWholeFile(const std::wstring& path, std::vector<uint8_t>* out);

// Ende des Nutzbereichs einer PE-Datei: Beginn der Authenticode-Tabelle
// (falls vorhanden), sonst Dateigroesse.
bool PeOverlayEnd(HANDLE file, uint64_t* end);

}  // namespace lf
