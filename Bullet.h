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
 
	void draw() const override {
        Processing::fill(255, 0, 0);

        constexpr float canvasHeight = ScreenHeight;
        const float screenY = canvasHeight - getPosition().getY();

        Processing::circle(
            getPosition().getX(),
            screenY,
            5
        );
	}
};

