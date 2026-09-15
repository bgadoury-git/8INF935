#include "Processing.h"
#include "PhysicsEngine.h"
#include "Bullet.h"
#include "GraphicsConstants.h"
#include <vector>
#include <iostream>

#ifdef _DEBUG
    #include "Test.h"
#endif

struct Sketch : public Processing::PApplet {
    std::vector<Particle<float>*> particles;

    void settings() override { size(ScreenWidth, ScreenHeight); }
    void setup()    override { background(0); 
    particles.push_back(new Bullet(Point3D<float>(320.0f, 180.0f, 0.0f), Vector3D<float>(50.0f, 0.0f, 0.0f)));
    }
    void draw()     override {
        background(0);
        fill(255, 140, 0);

		//get delta time in seconds
        
		for (auto* particle : particles) {
			particle->applyVerletIntegration(deltaTime);
            particle->draw();
        }

		//std::cout << "Particle count: " << Particle<float>::particleCount << std::endl;
    }
};

int main() {
#ifdef _DEBUG
    Test::run();
#endif // _DEBUG
   
    auto sketch = std::make_unique<Sketch>();
	sketch->run();

	return 0;
}