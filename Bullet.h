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
        const auto pos = getPosition();
        const auto vel = getVelocity();
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        Vector3D<float> dir = vel;
        dir.normalize();

        // Perpendicular vectors to draw shockwave vapor rings
        Vector3D<float> arbitraryUp(0.0f, 1.0f, 0.0f);
        if (std::abs(dir.getY()) > 0.95f) {
            arbitraryUp = Vector3D<float>(1.0f, 0.0f, 0.0f);
        }

        Vector3D<float> side(
            dir.getY() * arbitraryUp.getZ() - dir.getZ() * arbitraryUp.getY(),
            dir.getZ() * arbitraryUp.getX() - dir.getX() * arbitraryUp.getZ(),
            dir.getX() * arbitraryUp.getY() - dir.getY() * arbitraryUp.getX()
        );
        side.normalize();

        Vector3D<float> up(
            side.getY() * dir.getZ() - side.getZ() * dir.getY(),
            side.getZ() * dir.getX() - side.getX() * dir.getZ(),
            side.getX() * dir.getY() - side.getY() * dir.getX()
        );
        up.normalize();

        applet->pushMatrix();

        // -------------------------------------------------------------------------
        // 1. Hypervelocity Tracer Streak (Gradient Lead Line)
        // -------------------------------------------------------------------------
        constexpr float streakLength = 70.0f;
        Point3D<float> tail(
            pos.getX() - dir.getX() * streakLength,
            pos.getY() - dir.getY() * streakLength,
            pos.getZ() - dir.getZ() * streakLength
        );

        // Warm amber outer trail
        applet->stroke(255, 140, 30, 90);
        applet->strokeWeight(10.0f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // Bright yellow mid streak
        applet->stroke(255, 210, 60, 200);
        applet->strokeWeight(4.5f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // Incandescent white core streak
        applet->stroke(255, 255, 240, 255);
        applet->strokeWeight(1.8f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // -------------------------------------------------------------------------
        // 2. Transonic Expansion Rings (Mach Shock Cones)
        // -------------------------------------------------------------------------
        constexpr int ringCount = 3;
        constexpr int ringSegments = 16;
        constexpr float ringSpacing = 18.0f;

        for (int r = 1; r <= ringCount; ++r) {
            float fr = static_cast<float>(r);
            float lag = fr * ringSpacing;
            float radius = 3.5f + fr * 4.0f;

            float cx = pos.getX() - dir.getX() * lag;
            float cy = -(pos.getY() - dir.getY() * lag);
            float cz = pos.getZ() - dir.getZ() * lag;

            applet->stroke(255, 180, 50, 160 - r * 45);
            applet->strokeWeight(1.5f);
            applet->noFill();

            applet->beginShape();
            for (int i = 0; i <= ringSegments; ++i) {
                float theta = (static_cast<float>(i) / ringSegments) * 6.2831853f;
                float ox = (side.getX() * std::cos(theta) + up.getX() * std::sin(theta)) * radius;
                float oy = -(side.getY() * std::cos(theta) + up.getY() * std::sin(theta)) * radius;
                float oz = (side.getZ() * std::cos(theta) + up.getZ() * std::sin(theta)) * radius;

                applet->vertex(cx + ox, cy + oy, cz + oz);
            }
            applet->endShape();
        }

        // -------------------------------------------------------------------------
        // 3. Projectile Head (Metallic Core + Heating Plasma)
        // -------------------------------------------------------------------------
        applet->noStroke();
        applet->translate(pos.getX(), -pos.getY(), pos.getZ());

        // Aerodynamic bow-shock glow
        applet->fill(255, 110, 0, 95);
        applet->emissive(230, 80, 0);
        applet->sphere(7.5f);

        // Friction-heated copper-tungsten shell
        applet->fill(255, 175, 45, 230);
        applet->emissive(255, 120, 20);
        applet->sphere(4.8f);

        // White-hot tip
        applet->fill(255, 255, 230, 255);
        applet->emissive(255, 240, 180);
        applet->sphere(2.4f);

        applet->emissive(0, 0, 0);
        applet->popMatrix();
        applet->noStroke();
    }
};

