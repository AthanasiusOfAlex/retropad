# Cross-compile retropad for x86-64 Windows with llvm-mingw (clang + UCRT).
#
# On a Unix host the toolchain is expected in tools/llvm-mingw, which
# scripts/update-llvm-mingw.sh downloads. RETROPAD_LLVM_MINGW overrides that,
# so a second checkout that already has the same llvm-mingw release (for
# instance athanasius-tool-kit) can be borrowed instead of downloading 750 MB
# a second time.
#
# On Windows the toolchain is discovered under WinGet, installed with:
#   winget install MartinStorsjo.LLVM-MinGW.UCRT

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" OR CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    if(DEFINED ENV{RETROPAD_LLVM_MINGW})
        file(TO_CMAKE_PATH "$ENV{RETROPAD_LLVM_MINGW}" _llvm_root)
    else()
        set(_llvm_root "${CMAKE_CURRENT_LIST_DIR}/../tools/llvm-mingw")
    endif()
    set(_llvm_bin "${_llvm_root}/bin")
    set(_exe_suffix "")
else()
    # Normalize LOCALAPPDATA to use forward slashes (avoids \U escape parse error)
    file(TO_CMAKE_PATH "$ENV{LOCALAPPDATA}" _local_app_data)

    # Discover the llvm-mingw installation under WinGet (newest version wins)
    file(GLOB _llvm_dirs
        "${_local_app_data}/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/llvm-mingw-*-ucrt-x86_64"
    )
    list(SORT _llvm_dirs ORDER DESCENDING)
    list(GET _llvm_dirs 0 _llvm_root)
    set(_llvm_bin "${_llvm_root}/bin")
    set(_exe_suffix ".exe")
    set(CMAKE_MAKE_PROGRAM "${_llvm_bin}/mingw32-make.exe" CACHE FILEPATH "")
endif()

if(NOT EXISTS "${_llvm_bin}")
    message(FATAL_ERROR
        "llvm-mingw not found at ${_llvm_bin}.\n"
        "Run ./scripts/update-llvm-mingw.sh, or point RETROPAD_LLVM_MINGW at an "
        "existing llvm-mingw installation.")
endif()

# retropad is plain C, so no C++ compiler is named here. windres, rather than
# llvm-rc, because retropad.rc is GNU-flavoured enough to want the windres
# front end (it #includes <windows.h> and needs the preprocessor).
set(CMAKE_C_COMPILER  "${_llvm_bin}/x86_64-w64-mingw32-clang${_exe_suffix}")
set(CMAKE_RC_COMPILER "${_llvm_bin}/x86_64-w64-mingw32-windres${_exe_suffix}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
