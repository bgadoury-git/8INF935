#pragma once

#include "Processing.h"
#include "GraphicsConstants.h"
#include "AimSolvers.h"
#include "ProjectileFactory.h"
#include "TargetGoal.h"
#include "Arena.h"
#include <vector>
#include <memory>
#include <string>

struct Sketch : public Processing::PApplet {
    std::vector<std::unique_ptr<Particle<float>>> particles;
    AimMode currentAimMode{ AimMode::TurretSpherical };
    SelectedProjectile currentProjectile{ SelectedProjectile::Bullet };
    bool showTrajectories{ false };
    TargetGoal goal{ 120.0f };

    void settings() override {
        size(ScreenWidth, ScreenHeight, Processing::P3D);
    }

    void setup() override {}

    void draw() override {
        Arena::setupLighting(*this);
        Arena::draw(*this);
        goal.draw(*this);

        updateAndRenderParticles();
        renderAimPreview();
        renderHUD();
    }

    void mousePressed() override {
        Vector3D<float> velocity = computeCurrentAimVelocity();
        particles.push_back(
            ProjectileFactory::create(currentProjectile, Point3D<float>(0.0f, 0.0f, 0.0f), velocity)
        );
    }

    void mouseWheel(int delta) override {
        constexpr int optionCount = static_cast<int>(SelectedProjectile::Count);
        int step = (delta > 0) ? 1 : -1;
        int nextIndex = (static_cast<int>(currentProjectile) + step) % optionCount;
        if (nextIndex < 0) {
            nextIndex += optionCount;
        }
        currentProjectile = static_cast<SelectedProjectile>(nextIndex);
    }

    void keyPressed() override {
        if (key == 'm' || key == 'M') {
            currentAimMode = (currentAimMode == AimMode::RayGroundTarget)
                ? AimMode::TurretSpherical
                : AimMode::RayGroundTarget;
        }
        if (key == 't' || key == 'T') {
            showTrajectories = !showTrajectories;
        }
    }

private:
    Vector3D<float> computeCurrentAimVelocity() const {
        float muzzleSpeed = ProjectileFactory::getBaseSpeed(currentProjectile);

        if (currentAimMode == AimMode::RayGroundTarget) {
            return getAimGroundTarget(
                static_cast<float>(mouseX), static_cast<float>(mouseY),
                static_cast<float>(width), static_cast<float>(height),
                muzzleSpeed
            );
        }
        return getAimTurret(
            static_cast<float>(mouseX), static_cast<float>(mouseY),
            static_cast<float>(width), static_cast<float>(height),
            muzzleSpeed
        );
    }

    void updateAndRenderParticles() {
        for (auto it = particles.begin(); it != particles.end();) {
            auto& particle = *it;

            particle->applyVerletIntegration(deltaTime);
            particle->draw();

            if (showTrajectories) {
                renderParticleTrace(*particle);
            }

            const Point3D<float>& pos = particle->getPosition();
            goal.checkHit(pos);

            if (Arena::isOutOfBounds(pos)) {
                it = particles.erase(it); // unique_ptr automatically frees memory
            }
            else {
                ++it;
            }
        }
    }

    void renderParticleTrace(Particle<float>& particle) {
        std::vector<Point3D<float>> trajectory = particle.getTrajectory(20, 10.0f);

        for (const auto& point : trajectory) {
            pushMatrix();
            translate(point.getX(), -point.getY(), point.getZ());
            fill(255, 255, 0, 100);
            sphere(2.0f);
            popMatrix();
        }

        stroke(255, 255, 0, 150);
        strokeWeight(2.0f);
        for (size_t i = 0; i + 1 < trajectory.size(); ++i) {
            line(trajectory[i].getX(), -trajectory[i].getY(), trajectory[i].getZ(),
                trajectory[i + 1].getX(), -trajectory[i + 1].getY(), trajectory[i + 1].getZ());
        }
        noStroke();
    }

    void renderAimPreview() {
        Point3D<float> origin(0.0f, 0.0f, 0.0f);
        Vector3D<float> gravity(0.0f, -static_cast<float>(GRAVITY), 0.0f);
        Vector3D<float> aimVelocity = computeCurrentAimVelocity();

        auto aimTrajectory = predictAimTrajectory(origin, aimVelocity, gravity, 0.999f, 35, 30.0f);

        stroke(0, 255, 128, 180);
        strokeWeight(2.0f);
        noFill();

        beginShape();
        for (const auto& pt : aimTrajectory) {
            vertex(pt.getX(), -pt.getY(), pt.getZ());
        }
        endShape();

        noStroke();
    }

    void renderHUD() {
        camera(); // Reset to default 2D ortho matrix

        fill(230);
        textSize(22);
        std::string modeText = (currentAimMode == AimMode::RayGroundTarget)
            ? "Ground Target Plane (Raycast)"
            : "Turret (Pitch/Yaw Spherical)";

        std::string projectileText = ProjectileFactory::getDisplayName(currentProjectile);

        text("Particle Count: " + std::to_string(Particle<float>::particleCount) +
            "    FPS: " + std::to_string(Processing::PApplet::getFrameRate()), 15, 30);
        text("Aim Mode [M]: " + modeText, 15, 60);
        text("Current Projectile [Scroll]: " + projectileText, 15, 90);
        text(std::string("Display trajectories for all projectiles [T]: ") + (showTrajectories ? "ON" : "OFF"), 15, 120);
        text("Score / Goals: " + std::to_string(goal.getScore()), 15, 150);
    }
};