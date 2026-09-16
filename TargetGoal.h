#pragma once

#include "Processing.h"
#include "PhysicsEngine.h"
#include "GraphicsConstants.h"
#include <random>
#include <numbers>

class TargetGoal {
public:
    TargetGoal(float radius = 120.0f)
        : m_radius(radius), m_position(0.0f, -floorY, 600.0f), m_score(0) {
    }

    void resetValues() {
        m_score = 0;
        m_position = { 0.0f, -floorY, 600.0f };
    }

    void reset() {
        static std::mt19937 rng(std::random_device{}());
        std::uniform_real_distribution<float> distX(-800.0f, 800.0f);
        std::uniform_real_distribution<float> distZ(300.0f, 1500.0f);

        m_position = Point3D<float>(distX(rng), -floorY, distZ(rng));
    }

    bool checkHit(const Point3D<float>& particlePos) {
        // Impact check on ground plane
        if (particlePos.getY() <= -floorY) {
            float dx = particlePos.getX() - m_position.getX();
            float dz = particlePos.getZ() - m_position.getZ();
            if ((dx * dx + dz * dz) <= (m_radius * m_radius)) {
                ++m_score;
                reset();
                return true;
            }
        }
        return false;
    }

    void draw(Processing::PApplet& app) const {
        app.pushMatrix();
        app.translate(m_position.getX(), floorY - 4.5f, m_position.getZ());
        app.rotateX(-std::numbers::pi_v<float> *0.5f);

        // Outer Ring
        app.fill(255, 50, 50, 220);
        app.stroke(255, 180, 180);
        app.strokeWeight(3.0f);
        app.circle(0.0f, 0.0f, m_radius * 2.0f);

        // Bullseye Inner Disc
        app.fill(255, 220, 30, 240);
        app.noStroke();
        app.circle(0.0f, 0.0f, m_radius * 0.8f);

        app.popMatrix();
        app.noStroke();
    }

    int getScore() const { return m_score; }
    const Point3D<float>& getPosition() const { return m_position; }
    float getRadius() const { return m_radius; }

private:
    float m_radius;
    Point3D<float> m_position;
    int m_score;
};