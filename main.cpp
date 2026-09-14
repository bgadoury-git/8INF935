#include "Processing.h"
#include "PhysicsEngine.h"

#ifdef _DEBUG
    #include "Test.h"
#endif
    
#include <iostream>

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

#ifdef _DEBUG
    Test::run();
#endif // _DEBUG

	Sketch sketch;
	sketch.run();

	return 0;
}