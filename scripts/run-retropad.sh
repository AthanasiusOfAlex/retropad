#!/bin/bash
# Runs the cross-compiled retropad.exe on a Unix host, under Wine or CrossOver.
#
#   ./scripts/run-retropad.sh                    Release build, no file
#   ./scripts/run-retropad.sh --config Debug     Debug build
#   ./scripts/run-retropad.sh notes.txt          open notes.txt
#   ./scripts/run-retropad.sh path/to/other.exe  run some other build
#
# Launcher search order:
#   1. $RETROPAD_WINE, if set.
#   2. `wine`, then `wine64`, on PATH. Which of the two Ubuntu's packages
#      leave behind varies by release, so try both.
#   3. CrossOver's bundled wine, which is what a Mac dev box usually has.
#
# CrossOver's wine refuses to start without a bottle, and falls back to one
# named "default" that a fresh install does not have. So the bottle is named
# explicitly ($RETROPAD_BOTTLE, default "atk" -- the bottle athanasius-tool-kit
# already creates) and looked for under CX_BOTTLE_PATH. Export that if your
# bottles live somewhere other than the usual place. Create one with:
#
#   /Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxbottle \
#       --bottle atk --create --template win11_64
set -e

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

CROSSOVER_DIR="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin"
CONFIG="Release"
EXE=""
ARGS=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config) CONFIG="$2"; shift ;;
        -h|--help)
            echo "usage: $0 [--config Debug|Release] [file-or-exe ...]"
            exit 0 ;;
        *.exe) EXE="$1" ;;
        *) ARGS+=("$1") ;;
    esac
    shift
done

# Default to the requested config, but fall back to the other one rather than
# failing: "I built Debug and typed the short command" is the common case.
if [ -z "$EXE" ]; then
    for candidate in "build/x86_64-${CONFIG}/retropad.exe" \
                     "build/x86_64-Release/retropad.exe" \
                     "build/x86_64-Debug/retropad.exe"; do
        if [ -f "$PROJECT_ROOT/$candidate" ]; then
            EXE="$PROJECT_ROOT/$candidate"
            break
        fi
    done
fi

if [ -z "$EXE" ] || [ ! -f "$EXE" ]; then
    echo "run-retropad.sh: no retropad.exe found. Build one first:" >&2
    echo "  ./build.sh --config $CONFIG" >&2
    exit 1
fi

WINE_ARGS=""

if [ -n "${RETROPAD_WINE:-}" ]; then
    WINE="$RETROPAD_WINE"
elif command -v wine > /dev/null 2>&1; then
    WINE="$(command -v wine)"
elif command -v wine64 > /dev/null 2>&1; then
    WINE="$(command -v wine64)"
elif [ -x /usr/lib/wine/wine64 ]; then
    # Debian and Ubuntu put the runtime here; whether anything on PATH
    # points at it depends on which of the wine packages got installed.
    WINE=/usr/lib/wine/wine64
elif [ -x "$CROSSOVER_DIR/wine" ]; then
    WINE="$CROSSOVER_DIR/wine"
    BOTTLE="${RETROPAD_BOTTLE:-atk}"
    export CX_BOTTLE_PATH="${CX_BOTTLE_PATH:-$HOME/Library/Application Support/CrossOver/Bottles}"
    WINE_ARGS="--bottle $BOTTLE"

    if [ ! -d "$CX_BOTTLE_PATH/$BOTTLE" ]; then
        echo "run-retropad.sh: CrossOver bottle '$BOTTLE' not found under" >&2
        echo "  $CX_BOTTLE_PATH" >&2
        echo "Create it once with:" >&2
        echo "  \"$CROSSOVER_DIR/cxbottle\" --bottle $BOTTLE --create --template win11_64" >&2
        echo "Or set RETROPAD_BOTTLE to a bottle you already have." >&2
        exit 1
    fi
else
    echo "run-retropad.sh: no Wine found." >&2
    echo "  Install wine, or set RETROPAD_WINE to a launcher." >&2
    exit 127
fi

# retropad takes a file to open on its command line, and it is a Windows
# program: a Unix path means nothing to it. Wine maps the host root at Z:, so
# an absolute /a/b becomes Z:\a\b.
to_windows_path() {
    local p="$1"
    case "$p" in
        [A-Za-z]:*|"Z:"*) echo "$p" ;;          # already a Windows path
        /*)  echo "Z:${p//\//\\}" ;;
        *)   local abs; abs="$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")"
             echo "Z:${abs//\//\\}" ;;
    esac
}

WIN_ARGS=()
for a in ${ARGS+"${ARGS[@]}"}; do
    WIN_ARGS+=("$(to_windows_path "$a")")
done

# Wine narrates its startup on stderr; retropad's own output is the only thing
# worth reading here. Override by exporting WINEDEBUG yourself.
export WINEDEBUG="${WINEDEBUG:--all}"

# WINE_ARGS is deliberately unquoted: it is either empty or a two-word option
# pair, and an empty quoted "" would become an argv entry of its own.
# shellcheck disable=SC2086
exec "$WINE" $WINE_ARGS "$EXE" ${WIN_ARGS+"${WIN_ARGS[@]}"}
