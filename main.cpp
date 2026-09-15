#include "Processing.h"
#include "Sketch.h"
#include <memory>
#include <windows.h>
#include <mmsystem.h>

#pragma comment(lib, "winmm.lib")

#ifdef _DEBUG
#include "Test.h"
#endif

int main() {
#ifdef _DEBUG
    Test::run();
#endif

#ifdef _WIN32
    timeBeginPeriod(1); // Requests 1ms timer precision from the OS scheduler
#endif

    auto sketch = std::make_unique<Sketch>();
    sketch->run();

#ifdef _WIN32
    timeEndPeriod(1);   // Restore when exiting
#endif

    return 0;
}