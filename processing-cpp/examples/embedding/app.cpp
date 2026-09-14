// app.cpp -- the only file in this example that touches Processing.h.
#include "Processing.h"
#include "app.h"
#include <algorithm>
#include <vector>

using namespace Processing;

namespace {

struct Particle {
    PVector pos;
    PVector vel;
    float life = 1.0f;

    void draw() {
        fill(255, 200, 60, life * 255);
        circle(pos.x, pos.y, 8);
    }
};

struct ParticleView : public PApplet {
    std::vector<Particle> particles;

    void settings() override { size(800, 500); }
    void setup()    override { windowTitle("processing-cpp -- embedded in an existing project"); }

    void spawn(float x, float y) {
        Particle p;
        p.pos = PVector(x, y);
        p.vel = PVector::random2D() * random(60.0f, 200.0f);
        particles.push_back(p);
    }

    void draw() override {
        if (isMousePressed()) spawn(mouseX, mouseY);

        background(0);
        noStroke();
        for (auto& p : particles) {
            p.pos += p.vel * deltaTime;
            p.life -= deltaTime * 0.6f;
            p.draw();
        }
        particles.erase(
            std::remove_if(particles.begin(), particles.end(),
                            [](const Particle& p) { return p.life <= 0.0f; }),
            particles.end());
    }
};

} // namespace

void run_particle_view() {
    ParticleView view;
    view.run();
}
