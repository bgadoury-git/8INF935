#pragma once
#include "Particle.h"
#include "Processing.h"
#include "GraphicsConstants.h"

class Fireball : public Particle<float>
{
public:
    Fireball(const Point3D<float>& pos = {}, const Vector3D<float>& vel = {})
        : Particle(pos, vel, {}, 0.1f, 0.999f, true) {
    }

    inline static const float baseSpeed{ 250.0f };

    void draw() const override {
        const auto pos = getPosition();
        const auto vel = getVelocity();
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        Vector3D<float> dir = vel;
        dir.normalize();

        // Time-based wave drivers for organic flickering and expansion
        float t = static_cast<float>(Processing::PApplet::millis()) * 0.007f;
        float corePulse = std::sin(t * 7.0f) * 3.5f;
        float outerPulse = std::sin(t * 11.0f + 1.2f) * 6.0f;

        applet->pushMatrix();
        applet->noStroke();

        // -------------------------------------------------------------------------
        // 1. Extended Turbulent Wake / Flame Ribbons
        // -------------------------------------------------------------------------
        constexpr int trailSegments = 9;
        for (int i = 1; i <= trailSegments; ++i) {
            float fi = static_cast<float>(i);
            float lag = fi * 14.0f;

            // Swirling offsets around the flight vector
            float angle = t * 9.0f + fi * 1.1f;
            float radius = 5.0f + fi * 2.8f;
            float swirlX = std::cos(angle) * radius;
            float swirlY = std::sin(angle * 1.3f) * radius;

            applet->pushMatrix();
            applet->translate(
                pos.getX() - dir.getX() * lag + swirlX,
                -(pos.getY() - dir.getY() * lag) + swirlY,
                pos.getZ() - dir.getZ() * lag
            );

            // Color shifts from bright orange down to deep charred red/black smoke
            int r = 255;
            int g = std::max(0, 150 - i * 16);
            int b = 0;
            int alpha = std::max(15, 170 - i * 18);

            applet->fill(r, g, b, alpha);
            applet->emissive(r / 2.0f, g / 3.0f, 0);
            applet->sphere(16.0f - fi * 1.1f + std::sin(t * 12.0f + fi) * 2.0f);
            applet->popMatrix();
        }

        // -------------------------------------------------------------------------
        // 2. Main Body (Concentric Incandescent Volumes)
        // -------------------------------------------------------------------------
        applet->translate(pos.getX(), -pos.getY(), pos.getZ());

        // Wild erratic micro-flickers around the core
        for (int j = 0; j < 4; ++j) {
            float fj = static_cast<float>(j);
            float jetAngle = t * 13.0f + fj * 1.57f;
            float jx = std::cos(jetAngle) * (8.0f + outerPulse * 0.3f);
            float jy = std::sin(jetAngle * 0.8f) * (8.0f + outerPulse * 0.3f);
            float jz = std::sin(jetAngle * 1.5f) * 6.0f;

            applet->pushMatrix();
            applet->translate(jx, jy, jz);
            applet->fill(255, 60, 0, 75);
            applet->emissive(230, 40, 0);
            applet->sphere(14.0f + std::cos(t * 10.0f + fj) * 3.0f);
            applet->popMatrix();
        }

        // Outer plasma corona
        applet->fill(255, 45, 0, 55);
        applet->emissive(220, 30, 0);
        applet->sphere(34.0f + outerPulse);

        // Primary fire shell
        applet->fill(255, 100, 0, 140);
        applet->emissive(245, 90, 0);
        applet->sphere(24.0f + corePulse);

        // Dense inner blaze
        applet->fill(255, 195, 20, 210);
        applet->emissive(255, 180, 20);
        applet->sphere(16.0f + corePulse * 0.5f);

        // Hyperthermic white-hot core
        applet->fill(255, 255, 220, 255);
        applet->emissive(255, 255, 200);
        applet->sphere(8.5f);

        applet->emissive(0, 0, 0);
        applet->popMatrix();
    }
};

