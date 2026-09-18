#pragma once

#include "C:\Users\Admin\source\repos\8INF935\processing-cpp\include\Processing.h"
#include "GraphicsConstants.h"
#include "AimSolvers.h"
#include "ProjectileFactory.h"
#include "TargetGoal.h"
#include "Arena.h"
#include "PhysicsConstants.h"
#include <vector>
#include <memory>
#include <string>
#include <cmath>
#include <chrono>
#include <format>
#include <random>
#include <numbers>

enum class GameState {
    Menu,
    Playing,
    GameOver
};

struct Sketch : public Processing::PApplet {
    // --- State Machine ---
    GameState currentState{ GameState::Menu };

    // --- Gameplay State ---
    const int neededGoal{ 10 };
    std::vector<std::unique_ptr<Particle<float>>> particles;
    AimMode currentAimMode{ AimMode::TurretSpherical };
    SelectedProjectile currentProjectile{ SelectedProjectile::Bullet };
    bool showTrajectories{ false };
    TargetGoal goal{ 120.0f };
    float totalTime{};
    int confettiCount{ 1000 };
    float accumulator{ 0 };

    // --- Timing ---
    float customDeltaTime{};
    float customFPS{};

    void settings() override {
        //size(ScreenWidth, ScreenHeight, Processing::P3D);
        fullScreen(Processing::P3D);
        frameRate(240);
    }

    void setup() override {}

    void draw() override {
        actualiseDeltaTime();

        switch (currentState) {
        case GameState::Menu:
            drawMenuScreen();
            break;
        case GameState::Playing:
            drawGameplay();
            break;
        case GameState::GameOver:
            drawGameOverScreen();
            break;
        }
    }

    // ==========================================
    // Lifecycle & State Transitions
    // ==========================================

    void resetGame() {
        particles.clear();
        goal.resetValues();
        totalTime = 0;
        currentState = GameState::Playing;
    }

    // ==========================================
    // Render Functions
    // ==========================================

    void drawMenuScreen() {
        reset2DContext();
        background(20, 24, 35);

        textAlign(Processing::CENTER, Processing::CENTER);

        fill(0, 220, 255);
        textSize(42);
        text("PROJECTILE SIMULATOR", width / 2.0f, height / 2.0f - 80.0f);

        fill(220);
        textSize(20);
        text("Mouse Click: Fire Projectile", width / 2.0f, height / 2.0f - 10.0f);
        text("Mouse Wheel: Cycle Ammo Type", width / 2.0f, height / 2.0f + 20.0f);
        text("[M]: Toggle Aim Mode | [T]: Display All Trajectories", width / 2.0f, height / 2.0f + 50.0f);

        fill(50, 255, 140);
        textSize(24);
        text("Press [SPACE] or [ENTER] to Start", width / 2.0f, height / 2.0f + 120.0f);
    }

    void drawGameplay() {
        Arena::setupLighting(*this);
        Arena::draw(*this);
        goal.draw(*this);

        spawnConfettis(confettiCount * customDeltaTime);

        // Clamp frame time to handle hitches/breakpoints
        float frameTime = std::min(customDeltaTime, MAX_FRAME_TIME);

        accumulator += frameTime;

        while (accumulator >= FIXED_TIMESTEP) {
            updateParticles(FIXED_TIMESTEP); // Pass fixed step, not variable time!
            accumulator -= FIXED_TIMESTEP;
        }

        RenderParticles();
        renderAimPreview();
        renderHUD();

        // Game over trigger check: out of shots and no active projectiles in flight
        if (goal.getScore() == neededGoal) {
            particles.clear();
            currentState = GameState::GameOver;
        }
    }

    void drawGameOverScreen() {
        reset2DContext();
        background(15, 15, 20);

        textAlign(Processing::CENTER, Processing::CENTER);

        fill(70, 255, 70);
        textSize(48);
        text("GOAL REACHED", width / 2.0f, height / 2.0f - 60.0f);

        fill(230);
        textSize(24);
        std::string str = std::format("{:.2f}", totalTime);
        text("Final Time: " + str + " s", width / 2.0f, height / 2.0f);

        fill(100, 200, 255);
        textSize(20);
        text("Press [R] to Play Again", width / 2.0f, height / 2.0f + 60.0f);
        text("Press [SPACE] or [ESC] for Menu", width / 2.0f, height / 2.0f + 90.0f);
    }

    // ==========================================
    // Input Handling
    // ==========================================

    void mousePressed() override {
        if (currentState != GameState::Playing) return;

        Vector3D<float> velocity = computeCurrentAimVelocity();
        particles.push_back(
            ProjectileFactory::create(currentProjectile, Point3D<float>(0.0f, 0.0f, 0.0f), velocity)
        );
    }

    void mouseWheel(int delta) override {
        if (currentState != GameState::Playing) return;

        constexpr int optionCount = static_cast<int>(SelectedProjectile::Count);
        int step = (delta > 0) ? 1 : -1;
        int nextIndex = (static_cast<int>(currentProjectile) + step) % optionCount;
        if (nextIndex < 0) {
            nextIndex += optionCount;
        }
        currentProjectile = static_cast<SelectedProjectile>(nextIndex);
    }

    void keyPressed() override {
        if (currentState == GameState::Menu) {
            if (key == ' ' || keyCode == Processing::ENTER) {
                resetGame();
            }
            return;
        }

        if (currentState == GameState::GameOver) {
            if (key == 'r' || key == 'R') {
                resetGame();
            }
            else if (key == ' ' || keyCode == Processing::ENTER) {
                currentState = GameState::Menu;
            }
            return;
        }

        if (currentState == GameState::Playing) {
            if (key == 'm' || key == 'M') {
                currentAimMode = (currentAimMode == AimMode::RayGroundTarget)
                    ? AimMode::TurretSpherical
                    : AimMode::RayGroundTarget;
            }
            if (key == 't' || key == 'T') {
                showTrajectories = !showTrajectories;
            }
            // Direct force to Game Over for testing
            if (key == 'g' || key == 'G') {
                currentState = GameState::GameOver;
            }

            if (key == 'w' || key == 'W')
                confettiCount += 100;
            if ((key == 's' || key == 'S') && confettiCount > 0)
                confettiCount -= 100;
        }
    }

    void actualiseDeltaTime() {
        static auto lastTime = std::chrono::steady_clock::now();
        auto currentTime = std::chrono::steady_clock::now();

        std::chrono::duration<float, std::milli> elapsedMs = currentTime - lastTime;
        lastTime = currentTime;

        customDeltaTime = elapsedMs.count() / 1000.0f;
        customFPS = (customDeltaTime > 0.0f) ? (1.0f / customDeltaTime) : 0.0f;

        if (currentState == GameState::Playing)
            totalTime += customDeltaTime;
    }

private:
    void reset2DContext() {
        camera();          // Resets matrix to ortho 2D projection
        noLights();        // Turns off P3D lighting calculation for clean flat text
        noStroke();
    }

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

    void updateParticles(float timestep){
        for (auto it = particles.begin(); it != particles.end();) {
            auto& particle = *it;
            particle->applyVerletIntegration(timestep);

            const Point3D<float>& pos = particle->getPosition();

            if (goal.checkHit(pos) || Arena::isOutOfBounds(pos)) {
                it = particles.erase(it);
            }
            else {
                ++it;
            }
        }
    }

    void RenderParticles() {
        for (auto it = particles.begin(); it != particles.end();) {
            auto& particle = *it;

            particle->draw();

            if (showTrajectories) {
                renderParticleTrace(*particle);
            }

            ++it;
        }
    }

    void renderParticleTrace(Particle<float>& particle) {
        std::vector<Point3D<float>> trajectory = particle.getTrajectory(20, 10.0f);

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
        Vector3D<float> acceleration{};

        if (ProjectileFactory::getDefaultGravityState(currentProjectile))
            acceleration += gravity;

        auto aimTrajectory = predictAimTrajectory(origin, aimVelocity, acceleration, 0.999f, 35, 30.0f);

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
        reset2DContext();
        textAlign(Processing::LEFT, Processing::BASELINE);

        fill(230);
        textSize(22);
        std::string modeText = (currentAimMode == AimMode::RayGroundTarget)
            ? "Ground Target Plane (Raycast)"
            : "Turret (Pitch/Yaw Spherical)";

        std::string projectileText = ProjectileFactory::getDisplayName(currentProjectile);

        text("Particle Count: " + std::to_string(Particle<float>::particleCount) +
            "    FPS: " + std::to_string(std::lround(customFPS)) +
            "   ms/frame: " + std::to_string(std::lround(customDeltaTime * 1000.0f)), 15, 30);
        text("Aim Mode [M]: " + modeText, 15, 60);
        text("Current Projectile [Scroll]: " + projectileText, 15, 90);
        text(std::string("Display trajectories [T]: ") + (showTrajectories ? "ON" : "OFF"), 15, 120);
        text("Score : " + std::to_string(goal.getScore()) + "/" + neededGoal, 15, 150);
        text("Confettis per seconds : " + std::to_string(confettiCount) + " [W] + 100 [S] -100", 15, 180);
        text("Go to end scren : [G]", 15, 210);
    }

    void spawnConfettis(float quantity) {
        // Random engine
        static std::mt19937 rng(std::random_device{}());

        // Cone parameters
        const float maxSpreadAngle = 30.0f * (std::numbers::pi_v<float> / 180.0f); // 30-degree half-angle cone
        const float cosMax = std::cos(maxSpreadAngle);

        // Uniform distributions
        std::uniform_real_distribution<float> distCosTheta(cosMax, 1.0f); // Uniform areal spread
        std::uniform_real_distribution<float> distPhi(0.0f, 2.0f * std::numbers::pi_v<float>);
        std::uniform_real_distribution<float> distSpeed(250.0f, 400.0f); // Variable launch speeds

        for (int i = 0; i < quantity; ++i)
        {
            float cosTheta = distCosTheta(rng);
            float sinTheta = std::sqrt(1.0f - cosTheta * cosTheta);
            float phi = distPhi(rng);
            float speed = distSpeed(rng);

            // Directional vector pointed up (+Y) with spread along X and Z
            Vector3D<float> velocity(
                speed * sinTheta * std::cos(phi), // X (lateral)
                speed * cosTheta,                 // Y (upward)
                speed * sinTheta * std::sin(phi)  // Z (depth)
            );

            particles.push_back(
                ProjectileFactory::create(SelectedProjectile::Confetti, Point3D<float>(0.0f, -floorY, 600.0f), velocity)
            );
        }
    }
};