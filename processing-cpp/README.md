# processing-cpp (plug-and-play)

This is [Processing](https://processing.org)'s API — `size()`, `ellipse()`,
`mouseX`, `draw()`, and the rest of it — implemented natively in C++.
There's no Processing IDE involved, no `.pde` files, no transpiler, and no
build system to set up. Unzip this folder, write a `.cpp` file next to
it, and run one script.

If you're already building your project with CMake, you probably want the
separate CMake release instead — look for `processing-cpp-cmake.zip` on
the same page you got this from, or check the project's repository. This
folder doesn't need CMake at all, and isn't meant to be used with it.

## Quick start

1. Unzip this folder into your project, however you like — as
   `processing-cpp/` sitting next to your own code is the usual way.
2. Write a sketch (see below, or copy `examples/bouncing_ball.cpp` to get
   started).
3. Run it:

```sh
   ./processing-cpp/run.sh
```

That's the entire workflow. `run.sh` finds your `.cpp` file, compiles it
against the engine, links it, and runs the result, in one step. The first
time you run it, it also compiles the engine itself and precompiles
`Processing.h`, which together take about 15-20 seconds. Every run after
that reuses both of those and only has to compile your own file, so it's
fast — well under a second on most machines.

On Windows, run `run.bat` the same way (from an MSYS2 shell, or by
double-clicking it).

## If your project is a git repo

`run.sh` caches its build outputs in two places: `processing-cpp/lib/`
and `processing-cpp/include/Processing.h.gch`. This folder already
includes a `.gitignore` covering both, so they won't get committed if you
run `git add processing-cpp`.

It can't cover `run.sh`'s other output, though: the compiled sketch
itself, `.processing-cpp-build`, lands one level up, at the root of
*your* project, not inside `processing-cpp/`. Add this line to your own
project's `.gitignore`:

```
.processing-cpp-build*
```

(The trailing `*` catches `.processing-cpp-build.exe` on Windows too.)

## Writing a sketch

```cpp
#include "Processing.h"

struct Sketch : public Processing::PApplet {
    void settings() override { size(640, 360); }
    void setup()    override { background(0); }
    void draw()     override {
        background(0);
        fill(255, 140, 0);
        circle(mouseX, mouseY, 40);
    }
};

int main() {
    Sketch sketch;
    sketch.run();
    return 0;
}
```

You inherit from `PApplet`, override whichever lifecycle methods you need
(`setup`, `draw`, `mousePressed`, `keyPressed`, and so on), and call
`.run()` in `main()`. Everything in the
[Processing reference](https://processing.org/reference) — `background()`,
`fill()`, `circle()`, `mouseX`, `width`, `height` — is available as a
member you inherit, so you can call it directly inside your overrides
without writing `Processing::` in front of it.

The one exception: if you write a *helper* class that isn't a `PApplet`
itself (a `Particle`, a `Boid`, anything like that) and it also wants to
call these functions, add one line near the top of that file:

```cpp
using namespace Processing;
```

`examples/embedding/` shows exactly this.

## More than one source file?

`run.sh` with no arguments picks up every `.cpp` file it finds next to
itself and builds them together, so a small multi-file sketch works with
no extra effort. If you want to be explicit, or your files live somewhere
else, list them directly:

```sh
./processing-cpp/run.sh main.cpp app.cpp
```

## What's actually happening under the hood

`run.sh` isn't doing anything magic — it runs the same command you'd type
by hand, with the right flags already filled in for your operating system:

```sh
g++ -std=c++2c -I include main.cpp     src/Processing.cpp src/Processing_defaults.cpp     -DPROCESSING_HAS_STB_IMAGE -DPROCESSING_HAS_STB_TRUETYPE     -lglfw -lGLEW -lGL -lGLU -lm -pthread     -o my_sketch && ./my_sketch
```

On macOS, the link line is
`-lglfw -lGLEW -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo`
instead. On Windows with MSYS2, it's
`-lglfw3 -lglew32 -lopengl32 -lglu32 -lcomdlg32 -lshell32 -lole32 -luuid -mwindows -pthread -D_USE_MATH_DEFINES`.
This is mostly useful if you want to wire processing-cpp into your own
Makefile, editor build task, or something other than `run.sh` — you don't
need to read this section to just use the library.

(`run.sh` itself does a little more than this — it caches the compiled
engine and a precompiled header for `Processing.h` so repeated runs are
fast, as described above. Neither is required for a *working* build, only
for a *fast* one; the command above is enough to get a sketch running.)

## Requirements

Any recent g++ or clang with C++2c support works. All three major
platforms are supported: Linux, macOS, and Windows via MSYS2.

## Installing GLFW, GLEW, and a compiler

```sh
# Ubuntu / Debian
sudo apt install g++ libglfw3-dev libglew-dev

# Arch
sudo pacman -S gcc glfw glew

# macOS (Homebrew)
brew install glfw glew

# Windows, via MSYS2
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-glfw mingw-w64-x86_64-glew
```

## The two examples included here

- **`examples/bouncing_ball.cpp`** is the sketch shown above, with a
  little more in it — an orange ball bouncing around the window, space
  bar reverses it. Try it with:

```sh
  ./processing-cpp/run.sh processing-cpp/examples/bouncing_ball.cpp
```

- **`examples/embedding/`** shows how to drop a sketch into a project
  that already exists, without the rest of that project ever needing to
  know GLFW, GLEW, or `PApplet` exist. The `PApplet` subclass and the
  `#include "Processing.h"` live only inside `app.cpp`; `main.cpp` — and
  by extension the rest of a real project — only sees `app.h`'s plain
  `run_particle_view()` function. Try it with:

```sh
  ./processing-cpp/run.sh processing-cpp/examples/embedding/main.cpp processing-cpp/examples/embedding/app.cpp
```

## Using this from VS Code instead of a terminal

If you'd rather press a key than type `./processing-cpp/run.sh`, copy the
task file this package includes into your own project's `.vscode/`
folder:

```sh
mkdir -p .vscode
cp processing-cpp/vscode-task/tasks.json .vscode/tasks.json
```

After that, **Ctrl+Shift+B** (**Cmd+Shift+B** on macOS) builds and runs
your sketch. Compile errors show up in VS Code's Problems panel instead
of as raw terminal text. The task doesn't do anything `run.sh` doesn't
already do — it just calls `run.sh` (or `run.bat` on Windows) for you,
so there's nothing here that can drift out of sync with the plain
command-line instructions above.

## License

The engine is licensed under the **GNU Lesser General Public License
v2.1** (see `LICENSE`). LGPL is meant to allow linking from proprietary
software, unlike plain GPL, but it comes with real obligations, notably
around static linking, which is what `run.sh`/`run.bat` do here by
default (the engine gets compiled into `lib/libprocessing_cpp.a` and
linked directly into your sketch's binary). LGPL 2.1 requires that anyone
you distribute that binary to be able to relink it against a modified
version of the engine. In practice, that means making the engine's
object files (or this source) available alongside your binary, not just
the binary itself.

This isn't legal advice, and the specifics depend on how you're
distributing your project. Read `LICENSE` itself, and talk to an actual
lawyer if it matters for what you're shipping. It's flagged here mainly
so it doesn't come as a surprise after the fact.

`include/stb_image.h`, `stb_image_write.h`, and `stb_truetype.h` are
bundled third-party libraries (by Sean Barrett and contributors), not
part of the engine. They're each dual-licensed under MIT or public
domain (your choice), which is unrestricted enough that it doesn't add
anything beyond what's already true of the LGPL 2.1 engine itself. Their
full license text is included at the bottom of each of those files.

## Where this comes from

This release is built by `scripts/generate_dragdrop.py` in the main
CppMode repo, and it's generated directly from that repo's real engine
source (`src/Processing.h`, `src/Processing.cpp`) — the very same code
CppMode's Processing IDE plugin compiles your sketches against. If you
got this folder somewhere other than that repo, it's a snapshot of the
engine at some point in time; check the repo for anything newer.

If you're curious how this relates to writing a sketch inside the actual
Processing IDE with CppMode installed: the IDE's transpiler takes a
Processing-style sketch (free-standing `setup()` and `draw()` functions,
no class) and mechanically rewrites it into exactly the
`struct Sketch : public PApplet { ... }; sketch.run();` shape shown above.
There's no hidden behavior in that translation. Writing that shape
yourself, by hand, in a plain C++ file, produces the same program. This
release just lets you start from that shape directly, without going
through the IDE or the transpiler to get there.
