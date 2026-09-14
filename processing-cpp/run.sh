#!/usr/bin/env bash
# Builds and runs your sketch -- the one command this whole package is
# built around. Finds your .cpp file(s) one directory up (wherever you
# dropped this processing-cpp/ folder), compiles, links, and runs.
#
# Usage:
#   ./processing-cpp/run.sh                  # auto-detects .cpp files next to this folder
#   ./processing-cpp/run.sh main.cpp app.cpp # explicit, e.g. a multi-file sketch
#
# Two things get cached here so repeated runs stay fast, both rebuilt
# automatically only when their inputs change:
#   - the engine itself, compiled once into processing-cpp/lib/
#   - a precompiled header for Processing.h, written next to it as
#     processing-cpp/include/Processing.h.gch (g++ only looks for a .gch
#     file in the SAME directory as the header it precompiles -- it
#     can't live in lib/ alongside the engine, even though that would
#     read more naturally)
# Neither cache is required for correctness -- delete processing-cpp/lib/
# and Processing.h.gch and the next run just rebuilds both from scratch.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

if ! command -v g++ >/dev/null 2>&1; then
    echo "error: g++ not found on PATH." >&2
    echo "Install a C++ compiler, then try again -- see the \"Dependencies\" section of processing-cpp/README.md." >&2
    exit 1
fi

# Wraps a build command so a failure gets a one-line, specific cause
# instead of just whatever raw error g++/ld printed. Every g++/ar call in
# this script goes through here -- the engine build is the first thing
# that touches GLFW/GLEW (Processing.h includes both directly), so a
# missing-dependency failure can show up there, in the PCH build, or in
# the final compile, depending on what is/isn't already cached.
run_build_step() {
    local description="$1"
    shift
    local output
    if ! output="$("$@" 2>&1)"; then
        echo "$output" >&2
        echo "" >&2
        if echo "$output" | grep -qE "GLFW/glfw3\.h|GL/glew\.h"; then
            echo "error: $description failed -- GLFW or GLEW headers not found." >&2
            echo "See the \"Dependencies\" section of processing-cpp/README.md to install them." >&2
        elif echo "$output" | grep -qE "cannot find -lglfw|cannot find -lGLEW"; then
            echo "error: $description failed -- GLFW or GLEW library not found at link time." >&2
            echo "See the \"Dependencies\" section of processing-cpp/README.md to install them." >&2
        else
            echo "error: $description failed. See the output above." >&2
        fi
        exit 1
    fi
}

if [ "$#" -gt 0 ]; then
    SOURCES=("$@")
else
    SOURCES=()
    while IFS= read -r -d '' f; do
        SOURCES+=("$f")
    done < <(find . -maxdepth 1 -name '*.cpp' -print0)

    if [ "${#SOURCES[@]}" -eq 0 ]; then
        echo "error: no .cpp files found in $PROJECT_DIR" >&2
        echo "Put your sketch's .cpp file next to the processing-cpp/ folder, or run:" >&2
        echo "  processing-cpp/run.sh path/to/your_file.cpp" >&2
        exit 1
    fi
fi

echo "Building: ${SOURCES[*]}"

OS="$(uname -s)"
case "$OS" in
    Darwin)
        GL_LIBS=(-lglfw -lGLEW -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo)
        COMPILE_FLAGS=()
        ;;
    Linux)
        GL_LIBS=(-lglfw -lGLEW -lGL -lGLU -lm -pthread)
        # -pthread isn't just a link flag -- it also defines _REENTRANT
        # during compilation. The PCH build below has to see the same
        # define, or g++ rejects the cached .gch as stale and silently
        # re-parses Processing.h from source every time (caught by
        # actually building the package and checking with -Winvalid-pch
        # -- it doesn't show up as a build failure, just quietly stops
        # being fast).
        COMPILE_FLAGS=(-pthread)
        ;;
    *)
        echo "error: unrecognized OS '$OS' -- on Windows, use run.bat instead" >&2
        exit 1
        ;;
esac

# DEFINES must be IDENTICAL between the PCH build below and the final
# sketch compile further down, and so must COMPILE_FLAGS above -- g++
# only uses a .gch if every relevant flag matches the compile it's being
# considered for. A mismatch doesn't break the build, it just silently
# falls back to parsing Processing.h from source (with a -Winvalid-pch
# warning if you pass that flag to check), so the caching would quietly
# stop helping. Defined once here so the two invocations can't drift
# apart from each other.
DEFINES=(-DPROCESSING_HAS_STB_IMAGE -DPROCESSING_HAS_STB_TRUETYPE)

ENGINE_DIR="$SCRIPT_DIR"
LIB_DIR="$ENGINE_DIR/lib"
LIB_A="$LIB_DIR/libprocessing_cpp.a"
PCH_FILE="$ENGINE_DIR/include/Processing.h.gch"
mkdir -p "$LIB_DIR"

NEED_ENGINE_BUILD=0
if [ ! -f "$LIB_A" ]; then
    NEED_ENGINE_BUILD=1
else
    for src in "$ENGINE_DIR/src/Processing.cpp" "$ENGINE_DIR/src/Processing_defaults.cpp"; do
        if [ "$src" -nt "$LIB_A" ]; then
            NEED_ENGINE_BUILD=1
        fi
    done
fi

if [ "$NEED_ENGINE_BUILD" -eq 1 ]; then
    echo "Compiling engine (first run, or engine source changed; ~10-15s)..."
    run_build_step "engine compile" \
        g++ -std=c++2c -O2 -c -I"$ENGINE_DIR/include" "${DEFINES[@]}" \
            "$ENGINE_DIR/src/Processing.cpp" -o "$LIB_DIR/Processing.o"
    run_build_step "engine compile" \
        g++ -std=c++2c -O2 -c -I"$ENGINE_DIR/include" "${DEFINES[@]}" \
            "$ENGINE_DIR/src/Processing_defaults.cpp" -o "$LIB_DIR/Processing_defaults.o"
    run_build_step "engine archive" \
        ar rcs "$LIB_A" "$LIB_DIR/Processing.o" "$LIB_DIR/Processing_defaults.o"
    rm -f "$LIB_DIR/Processing.o" "$LIB_DIR/Processing_defaults.o"
fi

NEED_PCH_BUILD=0
if [ ! -f "$PCH_FILE" ]; then
    NEED_PCH_BUILD=1
elif [ "$ENGINE_DIR/include/Processing.h" -nt "$PCH_FILE" ]; then
    NEED_PCH_BUILD=1
fi

if [ "$NEED_PCH_BUILD" -eq 1 ]; then
    echo "Precompiling Processing.h (first run, or it changed; speeds up every build after this one)..."
    run_build_step "header precompile" \
        g++ -std=c++2c -I"$ENGINE_DIR/include" "${DEFINES[@]}" "${COMPILE_FLAGS[@]}" \
            -x c++-header "$ENGINE_DIR/include/Processing.h" -o "$PCH_FILE"
fi

OUT="$PROJECT_DIR/.processing-cpp-build"
run_build_step "sketch compile" \
    g++ -std=c++2c -I"$ENGINE_DIR/include" "${DEFINES[@]}" "${SOURCES[@]}" \
        -L"$LIB_DIR" -lprocessing_cpp "${GL_LIBS[@]}" \
        -o "$OUT"

echo "Running..."
exec "$OUT"
