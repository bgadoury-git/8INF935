#pragma once
#pragma once
#include "Particle.h"
#include "Processing.h"
#include "GraphicsConstants.h"

class Ball : public Particle<float>
{
public:
    inline static const float baseSpeed{ 50.0f };
    inline static const bool defaultGravityState{ true };

    Ball(const Point3D<float>& pos = {}, const Vector3D<float>& vel = {})
        : Particle(pos, vel, {}, 0.1f, 0.999f, defaultGravityState) {
    }

    void draw() const override {
        const auto pos = getPosition();
        const auto vel = getVelocity();
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        Vector3D<float> dir = vel;
        dir.normalize();

        float time = static_cast<float>(Processing::PApplet::millis()) * 0.006f;

        applet->pushMatrix();

        // -------------------------------------------------------------------------
        // 1. Heavy Black Powder Smoke & Burning Fuse Sparks Trail
        // -------------------------------------------------------------------------
        constexpr int puffCount = 6;
        for (int i = 1; i <= puffCount; ++i) {
            float fi = static_cast<float>(i);
            float lag = fi * 16.0f;

            // Expanding, turbulent billow
            float wobbleX = std::sin(time * 4.0f + fi * 1.5f) * (fi * 2.2f);
            float wobbleY = std::cos(time * 3.5f + fi * 2.0f) * (fi * 2.2f);

            applet->pushMatrix();
            applet->translate(
                pos.getX() - dir.getX() * lag + wobbleX,
                -(pos.getY() - dir.getY() * lag) + wobbleY,
                pos.getZ() - dir.getZ() * lag
            );
            applet->noStroke();
            // Grimy soot transitioning to faint gray smoke
            int grayVal = 40 + i * 14;
            applet->fill(grayVal, grayVal, grayVal, std::max(20, 160 - i * 24));
            applet->sphere(10.0f + fi * 2.4f);
            applet->popMatrix();
        }

        // Erratic orange fuse embers drifting behind
        for (int k = 1; k <= 3; ++k) {
            float fk = static_cast<float>(k);
            float sparkLag = fk * 9.0f;
            float sx = std::sin(time * 18.0f + fk * 2.7f) * 6.0f;
            float sy = std::cos(time * 14.0f + fk * 3.1f) * 6.0f;

            applet->pushMatrix();
            applet->translate(
                pos.getX() - dir.getX() * sparkLag + sx,
                -(pos.getY() - dir.getY() * sparkLag) + sy,
                pos.getZ() - dir.getZ() * sparkLag
            );
            applet->fill(255, 170, 30, 240);
            applet->emissive(255, 120, 0);
            applet->sphere(2.2f);
            applet->popMatrix();
        }

        // -------------------------------------------------------------------------
        // 2. Heavy Cast-Iron Core (Matte Charcoal with Specular Highlight)
        // -------------------------------------------------------------------------
        applet->translate(pos.getX(), -pos.getY(), pos.getZ());
        applet->noStroke();

        // Cast-iron rough outer surface
        applet->fill(42, 45, 50);
        applet->specular(180, 190, 205);
        applet->shininess(8.0f);
        applet->sphere(24.0f);

        // -------------------------------------------------------------------------
        // 3. Spitting Burning Fuse on the Cannonball
        // -------------------------------------------------------------------------
        // Fuse positioned slightly offset to the top-rear
        float fuseX = -dir.getX() * 12.0f;
        float fuseY = 16.0f;
        float fuseZ = -dir.getZ() * 12.0f;

        // Burning fuse tip flare
        applet->pushMatrix();
        applet->translate(fuseX, -fuseY, fuseZ);
        applet->fill(255, 230, 150, 255);
        applet->emissive(255, 160, 20);
        applet->sphere(3.5f + std::sin(time * 25.0f) * 1.0f);
        applet->popMatrix();

        // Reset material properties
        applet->specular(0, 0, 0);
        applet->emissive(0, 0, 0);
        applet->popMatrix();
    }
};