@echo off
REM Builds and runs your sketch -- the one command this package is built
REM around. Finds your .cpp file(s) one directory up (wherever you dropped
REM this processing-cpp folder), compiles, links, and runs. Requires
REM MSYS2 (g++, ar) on PATH.
REM
REM Usage:
REM   processing-cpp\run.bat
REM   processing-cpp\run.bat main.cpp app.cpp
REM
REM Caches two things so repeated runs stay fast: the engine itself
REM (processing-cpp\lib\libprocessing_cpp.a) and a precompiled header
REM for Processing.h (processing-cpp\include\Processing.h.gch -- g++
REM only looks for a .gch file next to the header it precompiles, so it
REM has to live in include\, not next to the engine in lib\). Neither
REM is required for correctness; delete both and the next run rebuilds
REM them from scratch.
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%\.."
set "PROJECT_DIR=%CD%"

where g++ >nul 2>nul
if errorlevel 1 (
    echo error: g++ not found on PATH.
    echo Install a C++ compiler ^(MSYS2^), then try again -- see the "Dependencies" section of processing-cpp\README.md.
    exit /b 1
)

set "SOURCES=%*"
if "%SOURCES%"=="" (
    set "SOURCES="
    for %%f in (*.cpp) do set "SOURCES=!SOURCES! %%f"
)
if "%SOURCES%"=="" (
    echo error: no .cpp files found in %PROJECT_DIR%
    echo Put your sketch's .cpp file next to the processing-cpp folder, or run:
    echo   processing-cpp\run.bat path\to\your_file.cpp
    exit /b 1
)

echo Building: %SOURCES%

REM Must match the DEFINES used for the PCH build exactly, or g++ will
REM reject the cached .gch as stale and silently fall back to parsing
REM Processing.h from source every time (with a -Winvalid-pch warning).
set "DEFINES=-DPROCESSING_HAS_STB_IMAGE -DPROCESSING_HAS_STB_TRUETYPE -D_USE_MATH_DEFINES"

set "ENGINE_DIR=%SCRIPT_DIR%"
set "LIB_DIR=%ENGINE_DIR%lib"
set "LIB_A=%LIB_DIR%\libprocessing_cpp.a"
set "PCH_FILE=%ENGINE_DIR%include\Processing.h.gch"
set "BUILD_LOG=%TEMP%\processing-cpp-build-%RANDOM%.log"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

goto :main

REM Runs one build command, capturing its output to BUILD_LOG so it can
REM be scanned for known failure patterns if it fails. Mirrors run.sh's
REM run_build_step: same two patterns (missing GLFW/GLEW headers at
REM compile time, missing GLFW/GLEW at link time), same fallback to "see
REM the output above" for anything else. Batch has no clean equivalent
REM of bash's output="$(...)" capture, so this goes through a temp file
REM instead -- printed either way, kept only long enough to grep. This
REM routine sits ABOVE :main and is only ever reached via `call`, never
REM by execution falling into it top-down -- the `goto :main` right
REM above is what makes that safe to place here.
REM
REM Takes the step description as %1, then the rest of the line as the
REM command to run. NOTE: `shift` does not update %* in cmd.exe -- %*
REM always reflects the full original argument list, regardless of how
REM many times shift has been called. So instead of shifting past %1,
REM this captures %* up front and strips the %1 text from its front
REM (the standard, documented way to get "everything after the first
REM argument" in batch, since there is no %2-and-onward slice syntax).
:run_build_step
set "STEP_DESC=%~1"
set "REST=%*"
call set "REST=%%REST:*%1=%%"
%REST% >"%BUILD_LOG%" 2>&1
set "STEP_RESULT=%ERRORLEVEL%"
type "%BUILD_LOG%"
if not "%STEP_RESULT%"=="0" (
    echo.
    findstr /C:"GLFW/glfw3.h" /C:"GL/glew.h" "%BUILD_LOG%" >nul
    if not errorlevel 1 (
        echo error: %STEP_DESC% failed -- GLFW or GLEW headers not found.
        echo See the "Dependencies" section of processing-cpp\README.md to install them.
    ) else (
        findstr /C:"cannot find -lglfw" /C:"cannot find -lGLEW" "%BUILD_LOG%" >nul
        if not errorlevel 1 (
            echo error: %STEP_DESC% failed -- GLFW or GLEW library not found at link time.
            echo See the "Dependencies" section of processing-cpp\README.md to install them.
        ) else (
            echo error: %STEP_DESC% failed. See the output above.
        )
    )
    del "%BUILD_LOG%" >nul 2>nul
    exit /b 1
)
del "%BUILD_LOG%" >nul 2>nul
goto :eof

:main
set NEED_ENGINE_BUILD=0
if not exist "%LIB_A%" set NEED_ENGINE_BUILD=1

if %NEED_ENGINE_BUILD%==1 (
    echo Compiling engine ^(first run; ~10-15s^)...
    call :run_build_step "engine compile" g++ -std=c++2c -O2 -c -I"%ENGINE_DIR%include" %DEFINES% "%ENGINE_DIR%src\Processing.cpp" -o "%LIB_DIR%\Processing.o"
    if errorlevel 1 exit /b 1
    call :run_build_step "engine compile" g++ -std=c++2c -O2 -c -I"%ENGINE_DIR%include" %DEFINES% "%ENGINE_DIR%src\Processing_defaults.cpp" -o "%LIB_DIR%\Processing_defaults.o"
    if errorlevel 1 exit /b 1
    ar rcs "%LIB_A%" "%LIB_DIR%\Processing.o" "%LIB_DIR%\Processing_defaults.o"
    del "%LIB_DIR%\Processing.o" "%LIB_DIR%\Processing_defaults.o"
)

set NEED_PCH_BUILD=0
if not exist "%PCH_FILE%" set NEED_PCH_BUILD=1

if %NEED_PCH_BUILD%==1 (
    echo Precompiling Processing.h ^(first run; speeds up every build after this one^)...
    REM -pthread has to be here too, matching the final compile below --
    REM it defines _REENTRANT during compilation, not just at link time,
    REM so without it here g++ rejects this .gch as stale on every build
    REM and silently re-parses Processing.h from source instead (caught
    REM by actually building this package and checking with the
    REM -Winvalid-pch warning flag -- it's not a build failure, the
    REM caching just quietly stops working).
    call :run_build_step "header precompile" g++ -std=c++2c -I"%ENGINE_DIR%include" %DEFINES% -pthread -x c++-header "%ENGINE_DIR%include\Processing.h" -o "%PCH_FILE%"
    if errorlevel 1 exit /b 1
)

call :run_build_step "sketch compile" g++ -std=c++2c -I"%ENGINE_DIR%include" %DEFINES% %SOURCES% -L"%LIB_DIR%" -lprocessing_cpp -lglfw3 -lglew32 -lopengl32 -lglu32 -lcomdlg32 -lshell32 -lole32 -luuid -mwindows -pthread -o "%PROJECT_DIR%\.processing-cpp-build.exe"
if errorlevel 1 exit /b 1

echo Running...
"%PROJECT_DIR%\.processing-cpp-build.exe"
