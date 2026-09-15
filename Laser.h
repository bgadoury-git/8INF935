#pragma once
#include "Particle.h"
#include "Processing.h"
#include "GraphicsConstants.h"
#include <numbers>

class Laser : public Particle<float>
{
public:
    Laser(const Point3D<float>& pos = {}, const Vector3D<float>& vel = {})
        : Particle(pos, vel, {}, 0.1f, 0.999f, false) {
    }

    inline static const float baseSpeed{ 5000.0f };

    void draw() const override {
        const auto pos = getPosition();
        const auto vel = getVelocity();
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        Vector3D<float> dir = vel;
        dir.normalize();

        // Generate perpendicular axes to build an oscillating sine helix around the beam
        Vector3D<float> arbitraryUp(0.0f, 1.0f, 0.0f);
        if (std::abs(dir.getY()) > 0.95f) {
            arbitraryUp = Vector3D<float>(1.0f, 0.0f, 0.0f);
        }

        // side = dir x arbitraryUp
        Vector3D<float> side(
            dir.getY() * arbitraryUp.getZ() - dir.getZ() * arbitraryUp.getY(),
            dir.getZ() * arbitraryUp.getX() - dir.getX() * arbitraryUp.getZ(),
            dir.getX() * arbitraryUp.getY() - dir.getY() * arbitraryUp.getX()
        );
        side.normalize();

        // up = side x dir
        Vector3D<float> normal(
            side.getY() * dir.getZ() - side.getZ() * dir.getY(),
            side.getZ() * dir.getX() - side.getX() * dir.getZ(),
            side.getX() * dir.getY() - side.getY() * dir.getX()
        );
        normal.normalize();

        float time = static_cast<float>(Processing::PApplet::millis()) * 0.008f;
        constexpr float totalLength = 160.0f; // Significantly extended beam length
        constexpr int samples = 28;
        const float step = totalLength / static_cast<float>(samples);

        applet->pushMatrix();

        // -------------------------------------------------------------------------
        // 1. Central Core Beam (Straight green energy trunk)
        // -------------------------------------------------------------------------
        Point3D<float> tail(
            pos.getX() - dir.getX() * totalLength,
            pos.getY() - dir.getY() * totalLength,
            pos.getZ() - dir.getZ() * totalLength
        );

        // Outer plasma green wash
        applet->stroke(30, 255, 90, 80);
        applet->strokeWeight(9.0f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // Vibrant neon green
        applet->stroke(60, 255, 120, 200);
        applet->strokeWeight(4.5f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // Hot white-lime central beam
        applet->stroke(225, 255, 235, 255);
        applet->strokeWeight(1.8f);
        applet->line(tail.getX(), -tail.getY(), tail.getZ(),
            pos.getX(), -pos.getY(), pos.getZ());

        // -------------------------------------------------------------------------
        // 2. Twin Helical Energy Waves (Sine / Cosine ribbons coiled around the beam)
        // -------------------------------------------------------------------------
        applet->stroke(0, 255, 140, 190);
        applet->strokeWeight(2.2f);
        applet->noFill();

        // First spiral ribbon
        applet->beginShape();
        for (int i = 0; i <= samples; ++i) {
            float d = static_cast<float>(i) * step;
            float progress = 1.0f - (d / totalLength); // Tapers off toward the tail
            float wavePhase = time * 12.0f - d * 0.08f;
            float waveAmp = 5.0f * progress;

            float offX = (side.getX() * std::sin(wavePhase) + normal.getX() * std::cos(wavePhase)) * waveAmp;
            float offY = (side.getY() * std::sin(wavePhase) + normal.getY() * std::cos(wavePhase)) * waveAmp;
            float offZ = (side.getZ() * std::sin(wavePhase) + normal.getZ() * std::cos(wavePhase)) * waveAmp;

            applet->vertex(
                pos.getX() - dir.getX() * d + offX,
                -(pos.getY() - dir.getY() * d + offY),
                pos.getZ() - dir.getZ() * d + offZ
            );
        }
        applet->endShape();

        // Counter-rotating / phase-shifted secondary ribbon
        applet->stroke(140, 255, 200, 160);
        applet->strokeWeight(1.5f);

        applet->beginShape();
        for (int i = 0; i <= samples; ++i) {
            float d = static_cast<float>(i) * step;
            float progress = 1.0f - (d / totalLength);
            float wavePhase = time * 12.0f - d * 0.08f + std::numbers::pi_v<float>;
            float waveAmp = 5.0f * progress;

            float offX = (side.getX() * std::sin(wavePhase) + normal.getX() * std::cos(wavePhase)) * waveAmp;
            float offY = (side.getY() * std::sin(wavePhase) + normal.getY() * std::cos(wavePhase)) * waveAmp;
            float offZ = (side.getZ() * std::sin(wavePhase) + normal.getZ() * std::cos(wavePhase)) * waveAmp;

            applet->vertex(
                pos.getX() - dir.getX() * d + offX,
                -(pos.getY() - dir.getY() * d + offY),
                pos.getZ() - dir.getZ() * d + offZ
            );
        }
        applet->endShape();

        // -------------------------------------------------------------------------
        // 3. Leading Tip Focus Node
        // -------------------------------------------------------------------------
        applet->noStroke();
        applet->translate(pos.getX(), -pos.getY(), pos.getZ());

        // Outer emission flare
        applet->fill(50, 255, 120, 110);
        applet->emissive(0, 255, 100);
        applet->sphere(4.5f);

        // Inner bright point
        applet->fill(235, 255, 240, 255);
        applet->emissive(180, 255, 200);
        applet->sphere(2.2f);

        applet->emissive(0, 0, 0);
        applet->popMatrix();
        applet->noStroke();
    }
};

