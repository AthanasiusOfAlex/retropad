# retropad

A Petzold-style Win32 Notepad clone written in mostly plain C. It keeps the classic menus, accelerators, word wrap toggle, status bar, find/replace, font picker, time/date insertion, and BOM-aware load/save. Printing is intentionally omitted.

The build is CMake driven by [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) — clang targeting `x86_64-w64-mingw32` against the UCRT. The same commands work on macOS, Linux, and Windows, and the resulting `retropad.exe` is statically linked, so it is a single self-contained file that runs on any modern Windows and under Wine or CrossOver.

## Build on macOS or Linux

Fetch the pinned toolchain once (~750 MB into `tools/llvm-mingw`, which is gitignored):

```bash
./scripts/update-llvm-mingw.sh
```

If you already have the same llvm-mingw release elsewhere, point `RETROPAD_LLVM_MINGW` at it instead and skip the download:

```bash
export RETROPAD_LLVM_MINGW=/path/to/llvm-mingw
```

Then build:

```bash
./build.sh
```

`--config Debug|Release|all` picks a configuration (default: both), and `--clean` wipes the build directories first.

## Build on Windows

Install the toolchain, which `cmake/toolchain-x86_64-mingw.cmake` then discovers under `%LOCALAPPDATA%`:

```powershell
winget install MartinStorsjo.LLVM-MinGW.UCRT
```

Then build with the PowerShell driver, which takes the same options:

```powershell
./build.ps1
```

## Manual CMake

Both scripts are thin wrappers; the underlying commands are:

```bash
cmake -S . -B build/x86_64-Release -DCMAKE_BUILD_TYPE=Release --toolchain cmake/toolchain-x86_64-mingw.cmake
```

```bash
cmake --build build/x86_64-Release -j
```

On Windows add `-G "MinGW Makefiles"` to the configure step.

## Output

```
build/x86_64-Debug/retropad.exe
build/x86_64-Release/retropad.exe
```

Only x86-64 is built. The toolchain file is parameterized by architecture, so adding ARM64 later means dropping in `cmake/toolchain-aarch64-mingw.cmake` and widening the arch list in the two build scripts.

## Run

On Windows, double-click `retropad.exe` or start it from a prompt.

On macOS or Linux, run it under Wine or CrossOver:

```bash
./scripts/run-retropad.sh
```

`--config Debug|Release` picks which build to launch; it defaults to Release and falls back to whichever one exists.

The script finds a launcher in this order: `$RETROPAD_WINE`, then `wine` or `wine64` on `PATH`, then CrossOver's bundled Wine. Any file arguments are translated to the `Z:` drive Wine maps the host root filesystem to — though note that retropad currently discards its command line (`wWinMain` does `(void)lpCmdLine`), so passing a file has no effect today. Open files with File → Open or by dragging them onto the window.

CrossOver needs a bottle and has none by default. The script uses `$RETROPAD_BOTTLE`, defaulting to `atk`; create one once with:

```bash
/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxbottle --bottle atk --create --template win11_64
```

Set `CX_BOTTLE_PATH` if your bottles are not where CrossOver usually puts them.

## Features & notes

- Menus/accelerators: File, Edit, Format, View, Help; classic Notepad key bindings (Ctrl+N/O/S, Ctrl+F, F3, Ctrl+H, Ctrl+G, F5, etc.).
- Word Wrap toggles horizontal scrolling; status bar auto-hides while wrapped, restored when unwrapped.
- Find/Replace dialogs (standard `FINDMSGSTRING`), Go To (disabled when word wrap is on).
- Font picker (ChooseFont), time/date insertion, drag-and-drop to open files.
- File I/O: detects UTF-8/UTF-16 BOMs, falls back to UTF-8/ANSI heuristic; saves with UTF-8 BOM by default.
- Printing/page setup menu items show a "not implemented" notice by design.
- Icon: linked as the main app icon from `res/retropad.ico` via `retropad.rc`.
- No application manifest, matching the original MSVC build: controls render in the classic comctl32 v5 style, and the app is not DPI-aware.

## Project layout

- `retropad.c` — WinMain, window proc, UI logic, find/replace, menus, layout.
- `file_io.c/.h` — file open/save dialogs and encoding-aware load/save helpers.
- `resource.h` — resource IDs.
- `retropad.rc` — menus, accelerators, dialogs, version info, icon.
- `res/retropad.ico` — application icon.
- `CMakeLists.txt` — the build.
- `cmake/toolchain-x86_64-mingw.cmake` — locates llvm-mingw and selects the cross compiler.
- `build.sh` / `build.ps1` — one-command build drivers.
- `scripts/update-llvm-mingw.sh` — downloads and checksums the pinned toolchain.
- `scripts/run-retropad.sh` — runs the built `.exe` under Wine or CrossOver.
- `binaries/` — the original MSVC-built artifacts, kept from upstream; new builds go to `build/`.

## Common build hiccups

- `llvm-mingw not found at …` — run `./scripts/update-llvm-mingw.sh`, or set `RETROPAD_LLVM_MINGW`.
- `run-retropad.sh: no retropad.exe found` — build it first with `./build.sh`.
- `CrossOver bottle 'atk' not found` — create it with the `cxbottle` command above, or set `RETROPAD_BOTTLE` to a bottle you already have.
- The build reports five `-Wunused-parameter` warnings. They are pre-existing and harmless; `-Wall -Wextra` is the equivalent of the `/W4` the original MSVC build used.
