cmake_minimum_required(VERSION 3.20)
project(retropad VERSION 1.0.0 LANGUAGES C RC)

# Plain C throughout. The source declares variables mid-block and inside switch
# cases, so C99 is the floor; C11 is what the toolchain gives for free.
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# retropad.rc is UTF-8 and contains one non-ASCII character (the © in the About
# box). windres decodes its input as CP1252 unless told otherwise, which turns
# that into "Â©" on screen -- a wrong-looking dialog rather than a build error,
# so it is worth setting even though nothing fails without it.
if(MINGW)
    string(APPEND CMAKE_RC_FLAGS " --codepage=65001")
endif()

add_executable(retropad
    retropad.c
    file_io.c
    retropad.rc
)

# UNICODE/_UNICODE were command-line-only in the original NMAKE build and
# nothing in the source defines them. The code calls the -W entry points
# explicitly almost everywhere, but not quite: SB_SETTEXT and MAKEINTRESOURCE
# still resolve through these.
target_compile_definitions(retropad PRIVATE
    UNICODE
    _UNICODE
    _WIN32_WINNT=0x0A00
    WINVER=0x0A00
)

# windres resolves both #include "resource.h" and the ICON statement's
# res/retropad.ico payload against its include path, and it runs with the build
# tree as its working directory.
target_include_directories(retropad PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

if(CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # The NMAKE build used /W4; this is the near equivalent.
    target_compile_options(retropad PRIVATE -Wall -Wextra)
elseif(MSVC)
    target_compile_options(retropad PRIVATE /W4)
endif()

# GUI subsystem: no console window opens alongside the app.
set_target_properties(retropad PROPERTIES WIN32_EXECUTABLE TRUE)

if(MINGW)
    # -municode selects the wmain/wWinMain startup object. Without it the link
    # fails with "undefined reference to 'WinMain'", since retropad.c defines
    # wWinMain. Wanted at compile time as well as link time.
    target_compile_options(retropad PRIVATE -municode)

    # -static leaves the executable with no dependency on llvm-mingw's own
    # runtime DLLs (libunwind, libwinpthread), so a single retropad.exe runs on
    # any modern Windows and under CrossOver with nothing beside it.
    target_link_options(retropad PRIVATE -municode -static)
endif()

# Lowercase and extension-less: the mingw sysroot ships libuser32.a etc., which
# matters on a case-sensitive host, and MSVC accepts the same spelling.
target_link_libraries(retropad PRIVATE
    user32
    gdi32
    comdlg32
    comctl32
    shell32
)
