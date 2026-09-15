#include "Processing.h"
#include "Sketch.h"
#include <memory>

#ifdef _DEBUG
#include "Test.h"
#endif

int main() {
#ifdef _DEBUG
    Test::run();
#endif

    auto sketch = std::make_unique<Sketch>();
    sketch->run();

    return 0;
}