# Setup-Engine fuer den Windows-Installer von LINEFM Radio.
#
#   setup_stub.exe  Stub von setup.exe und zugleich uninstall.exe
#   lfpack.exe      Packer (nur Build), haengt die Nutzlast an den Stub
#
# Bauen (Developer-Eingabeaufforderung oder CI):
#   cmake -S installer/windows/engine -B build/installer-engine -A x64 -DLF_VERSION=1.2.3
#   cmake --build build/installer-engine --config Release
#
# Keine Fremdbibliotheken. Statische C-Laufzeit (/MT), damit setup.exe ohne
# Visual-C++-Redistributable startet.
cmake_minimum_required(VERSION 3.20)
cmake_policy(SET CMP0091 NEW)
project(linefm_setup_engine LANGUAGES CXX RC)

if(NOT MSVC)
  message(FATAL_ERROR "Die Setup-Engine wird mit MSVC gebaut.")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(LF_VERSION "0.0.0" CACHE STRING "Versionsnummer (x.y.z) fuer die Versionsressource")
string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)" _lf_match "${LF_VERSION}")
if(NOT _lf_match)
  message(FATAL_ERROR "LF_VERSION muss mit x.y.z beginnen, ist '${LF_VERSION}'")
endif()
set(LF_VERSION_MAJOR ${CMAKE_MATCH_1})
set(LF_VERSION_MINOR ${CMAKE_MATCH_2})
set(LF_VERSION_PATCH ${CMAKE_MATCH_3})

include("${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/copyright.cmake")

set(LF_ICON "${CMAKE_CURRENT_SOURCE_DIR}/../../../windows/runner/resources/app_icon.ico")
file(TO_NATIVE_PATH "${LF_ICON}" LF_ICON_NATIVE)
string(REPLACE "\\" "\\\\" LF_ICON_RC "${LF_ICON_NATIVE}")
set(LF_MANIFEST_RC "${CMAKE_CURRENT_SOURCE_DIR}/res/setup.manifest")
file(TO_NATIVE_PATH "${LF_MANIFEST_RC}" LF_MANIFEST_NATIVE)
string(REPLACE "\\" "\\\\" LF_MANIFEST_RC "${LF_MANIFEST_NATIVE}")
configure_file(res/setup.rc.in "${CMAKE_CURRENT_BINARY_DIR}/setup.rc" @ONLY)

set(LF_COMMON
  src/common/archive.cpp
  src/common/base.cpp
  src/common/secure.cpp
)

# Gemeinsame Haertung: Control Flow Guard, ASLR, DEP, CET, Spectre-Schutz,
# Warnungen als Fehler.
function(lf_harden target)
  target_compile_definitions(${target} PRIVATE
    UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX _WIN32_WINNT=0x0A00)
  target_compile_options(${target} PRIVATE
    /W4 /WX /permissive- /utf-8 /guard:cf /Qspectre /sdl /GS /EHsc /Zi)
  target_link_options(${target} PRIVATE
    /guard:cf /DYNAMICBASE /HIGHENTROPYVA /NXCOMPAT /CETCOMPAT
    /DEBUG /OPT:REF /OPT:ICF /INCREMENTAL:NO)
endfunction()

add_executable(setup_stub WIN32
  ${LF_COMMON}
  src/stub/engine.cpp
  src/stub/main.cpp
  "${CMAKE_CURRENT_BINARY_DIR}/setup.rc"
)
lf_harden(setup_stub)
# Schutz gegen DLL-Planting im Download-Ordner:
# - /DEPENDENTLOADFLAG:0x800 laedt statische Importe nur aus System32.
# - Nicht-KnownDLLs werden zusaetzlich verzoegert geladen, also erst nach
#   SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_SYSTEM32) in wWinMain.
target_link_options(setup_stub PRIVATE
  /DEPENDENTLOADFLAG:0x800
  /MANIFEST:NO
  /DELAYLOAD:cabinet.dll
  /DELAYLOAD:rstrtmgr.dll
  /DELAYLOAD:version.dll
  /DELAYLOAD:bcrypt.dll
  /DELAYLOAD:shell32.dll
  /DELAYLOAD:ole32.dll
)
target_link_libraries(setup_stub PRIVATE
  bcrypt cabinet rstrtmgr version shell32 ole32 advapi32 user32 uuid delayimp)

add_executable(lfpack
  ${LF_COMMON}
  src/packer/main.cpp
)
lf_harden(lfpack)
target_link_libraries(lfpack PRIVATE bcrypt cabinet shell32 ole32 advapi32 user32)
