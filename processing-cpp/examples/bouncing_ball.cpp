// bouncing_ball.cpp -- a complete sketch, no Processing IDE involved.
// Build: see this package's README.md.
#include "Processing.h"

struct BouncingBall : public Processing::PApplet {
    float x = 0, y = 0;
    float vx = 180, vy = 140;
    float radius = 30;

    void settings() override {
        size(640, 360);
    }

    void setup() override {
        windowTitle("processing-cpp standalone example");
        x = width / 2.0f;
        y = height / 2.0f;
    }

    void draw() override {
        x += vx * deltaTime;
        y += vy * deltaTime;

        if (x < radius || x > width - radius)  vx = -vx;
        if (y < radius || y > height - radius) vy = -vy;

        background(20);
        noStroke();
        fill(255, 140, 0);
        circle(x, y, radius * 2);
    }

    void keyPressed() override {
        if (key == ' ') { vx = -vx; vy = -vy; }
    }
};

int main() {
    BouncingBall sketch;
    sketch.run();
    return 0;
}
