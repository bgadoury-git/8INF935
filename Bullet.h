#pragma once
#include "Particle.h"
#include "Processing.h"
#include "GraphicsConstants.h"

class Bullet : public Particle<float>
{
public:
    Bullet(const Point3D<float>& pos = {}, const Vector3D<float>& vel = {})
        : Particle(pos, vel, {}, 0.1f, 0.999f, true) {
    }

    inline static const float baseSpeed { 500.0f };
 
	void draw() const override {
        const auto position = getPosition();
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        applet->pushMatrix();
        applet->translate(
            position.getX(),
            -position.getY(),
            position.getZ()
        );
        applet->fill(255, 70, 25);
        applet->emissive(80, 10, 0);
        applet->sphere(8.0f);
        applet->popMatrix();
	}
};

