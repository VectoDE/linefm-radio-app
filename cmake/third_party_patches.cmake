# Pinned build-time patches for third-party plugin and native sources.
#
# Every entry fixes a warning or error that third-party code prints during the
# native build, so that the build log stays free of warnings (see
# tool/check_build_logs.py). Each patch is an exact text replacement:
#   - patched text already present  -> nothing to do (idempotent)
#   - original text present         -> replace it
#   - neither                       -> FATAL_ERROR, because the upstream file
#                                      changed: re-check whether the upstream
#                                      release fixed it and drop the entry.
# The matching upstream reports are listed in docs/BUILD_WARNINGS.md.

function(third_party_patch file original patched)
  if(NOT EXISTS "${file}")
    message(FATAL_ERROR "third_party_patch: ${file} not found. "
      "The dependency moved or was removed; update cmake/third_party_patches.cmake.")
  endif()
  file(READ "${file}" content)
  string(FIND "${content}" "${patched}" patched_at)
  if(NOT patched_at EQUAL -1)
    return()
  endif()
  string(FIND "${content}" "${original}" original_at)
  if(original_at EQUAL -1)
    message(FATAL_ERROR "third_party_patch: expected text not found in ${file}. "
      "Upstream changed this file; check whether the fix shipped and drop the patch.")
  endif()
  string(REPLACE "${original}" "${patched}" content "${content}")
  file(WRITE "${file}" "${content}")
  message(STATUS "Patched ${file}")
endfunction()

# Plugin CMake files. Call before include(flutter/generated_plugins.cmake);
# the plugin sources are reached through flutter/ephemeral/.plugin_symlinks.
function(third_party_patch_plugins platform)
  set(links "${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral/.plugin_symlinks")
  if(platform STREQUAL "windows")
    set(mk "${links}/media_kit_libs_windows_audio/windows/CMakeLists.txt")
    # CMP0175: add_custom_command(TARGET) needs an explicit build stage.
    # The old implicit behaviour was POST_BUILD, so this keeps it unchanged.
    third_party_patch("${mk}"
      "TARGET \"\${PROJECT_NAME}_LIBMPV_EXTRACT\"\n    COMMAND"
      "TARGET \"\${PROJECT_NAME}_LIBMPV_EXTRACT\"\n    POST_BUILD\n    COMMAND")
    # make_directory() is deprecated since CMake 3.0.
    third_party_patch("${mk}"
      "  make_directory(\"\${LIBMPV_SRC}\")"
      "  file(MAKE_DIRECTORY \"\${LIBMPV_SRC}\")")
    # cargokit: Get-Item without -Force fails on hidden directories such as
    # %USERPROFILE%\AppData, which holds the pub cache on Windows.
    third_party_patch("${links}/smtc_windows/cargokit/cmake/resolve_symlinks.ps1"
      "\$item = Get-Item \$realPath"
      "\$item = Get-Item -Force -LiteralPath \$realPath")
  elseif(platform STREQUAL "linux")
    third_party_patch("${links}/media_kit_libs_linux/linux/CMakeLists.txt"
      "    make_directory(\"\${MIMALLOC_SRC}\")"
      "    file(MAKE_DIRECTORY \"\${MIMALLOC_SRC}\")")
  endif()
endfunction()
