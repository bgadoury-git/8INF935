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
#include <array>
#include <algorithm>
#include <omp.h>
#include <windows.h>
#include <string>

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

    // Contiguous Swap-and-Pop Pool
    static constexpr size_t MAX_CONFETTI_POOL = 10'000'000;
    std::array<Confetti, MAX_CONFETTI_POOL> Confettis;
    int activeConfetti{ 0 };
    float confettiSpawnAccumulator{ 0.0f };
    size_t confettiRecycleCursor{ 0 };

    AimMode currentAimMode{ AimMode::TurretSpherical };
    SelectedProjectile currentProjectile{ SelectedProjectile::Bullet };
    bool showTrajectories{ false };
    TargetGoal goal{ 120.0f };
    float totalTime{};
    int confettiSpawnAmount{ 0'000 };
    float accumulator{ 0 };
    bool solidColor{ true };

    GLuint confettiVBO{ 0 };
    bool vboInitialized{ false };
    bool useVBO{ true };
    bool cullConfettis{ false };

    // --- Timing ---
    float customDeltaTime{};
    float customFPS{};
    float smoothedDeltaTime{ 0.0f };

    void settings() override {
        fullScreen(Processing::P3D);
        frameRate(10000);
    }

    void setup() override {
        /*
        // Disable VSync to completely uncap the frame rate from the monitor refresh rate
            typedef BOOL(WINAPI* PFNWGLSWAPINTERVALEXTPROC)(int);
        PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT =
            (PFNWGLSWAPINTERVALEXTPROC)wglGetProcAddress("wglSwapIntervalEXT");
        if (wglSwapIntervalEXT) {
            wglSwapIntervalEXT(0); // 0 = Disable VSync, 1 = Enable VSync
        }*/
    }

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
        clearConfetti();
        goal.resetValues();
        totalTime = 0;
        currentState = GameState::Playing;
    }

    void clearConfetti() {
        activeConfetti = 0;
        confettiSpawnAccumulator = 0.0f;
        confettiRecycleCursor = 0;
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

        spawnConfettis(confettiSpawnAmount * customDeltaTime);

        // Clamp frame time to handle hitches/breakpoints
        float frameTime = std::min(customDeltaTime, MAX_FRAME_TIME);

        accumulator += frameTime;

        while (accumulator >= FIXED_TIMESTEP) {
            updateParticles(FIXED_TIMESTEP);
            accumulator -= FIXED_TIMESTEP;
        }

        RenderParticles();
        renderAimPreview();
        renderHUD();

        // Game over trigger check
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
            if (key == 'g' || key == 'G') {
                currentState = GameState::GameOver;
            }
            if (key == 'w' || key == 'W')
                confettiSpawnAmount += 10000;
            if ((key == 's' || key == 'S') && confettiSpawnAmount > 0)
                confettiSpawnAmount -= 10000;
            if (key == 'c' || key == 'C') {
                solidColor = !solidColor;
            }
            if (key == 'v' || key == 'V') {
                useVBO = !useVBO;
            }
        }
    }

    void actualiseDeltaTime() {
        static auto lastTime = std::chrono::steady_clock::now();
        auto currentTime = std::chrono::steady_clock::now();

        std::chrono::duration<float, std::milli> elapsedMs = currentTime - lastTime;
        lastTime = currentTime;

        // Raw delta time for accurate physics and game time accumulation
        customDeltaTime = elapsedMs.count() / 1000.0f;

        if (currentState == GameState::Playing)
            totalTime += customDeltaTime;

        // Exponential Moving Average (EMA) for smooth HUD display
        // alpha = 0.05f to 0.1f gives a nice, readable balance between stability and responsiveness
        constexpr float smoothingAlpha = 0.08f;
        if (smoothedDeltaTime == 0.0f) {
            smoothedDeltaTime = customDeltaTime;
        }
        else {
            smoothedDeltaTime = smoothingAlpha * customDeltaTime + (1.0f - smoothingAlpha) * smoothedDeltaTime;
        }

        customFPS = (smoothedDeltaTime > 0.0f) ? (1.0f / smoothedDeltaTime) : 0.0f;
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

    // O(1) swap-and-pop removal to maintain dense memory
    void killConfetti(size_t index) {
        if (activeConfetti <= 0 || index >= static_cast<size_t>(activeConfetti)) return;

        Confettis[index] = Confettis[activeConfetti - 1];
        --activeConfetti;
    }

    void updateParticles(float timestep) {
        // 1. Dynamic player projectiles (kept sequential due to small count and vector erasure)
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

        // 2. Parallel Confetti Verlet Integration
        // Distribute the 1,000,000 elements across all available CPU cores
        const int count = activeConfetti;

        #pragma omp parallel for schedule(static)
        for (int i = 0; i < count; ++i) {
            Confettis[i].applyVerletIntegration(timestep);
        }

        //Optional: Sequential Culling pass
        // If you re-enable goal hit or arena boundary culling, run it here sequentially
        //so swap-and-pop (killConfetti) does not cause thread collisions:
        
        if (cullConfettis)
        {
            for (size_t i = 0; i < static_cast<size_t>(activeConfetti);) {
                const Point3D<float>& pos = Confettis[i].getPosition();
                if (pos.getY() < -floorY) {
                    killConfetti(i);
                }
                else {
                    ++i;
                }
            }
        }
    }

    struct RGBColor {
        int r, g, b;
    };

    void RenderParticles() {
        constexpr float tailTime = 0.035f;
        const size_t count = static_cast<size_t>(activeConfetti);

        // 6 distinct palette colors defined using plain integers
        constexpr RGBColor palette[6] = {
            {255, 70, 70},   // Red
            {70, 255, 120},  // Green
            {70, 160, 255},  // Blue
            {255, 220, 50},  // Yellow
            {255, 120, 220}, // Magenta
            {50, 255, 255}   // Cyan
        };

        strokeWeight(2.5f);
        noFill();

        if (!useVBO)
        {
            if (solidColor)
            {
                stroke(255, 70, 70, 255);
                beginShape(Processing::LINES);

                for (size_t i = 0; i < count; ++i) {
                    const auto& c = Confettis[i];
                    const Point3D<float> head = c.getPosition();
                    const Vector3D<float> vel = c.getVelocity();

                    vertex(
                        head.getX() - vel.getX() * tailTime,
                        -(head.getY() - vel.getY() * tailTime),
                        head.getZ() - vel.getZ() * tailTime
                    );

                    vertex(
                        head.getX(),
                        -head.getY(),
                        head.getZ()
                    );
                }

                endShape();
            }
            else
            {
                // SINGLE-PASS BINNING: Scan the array once, sort into 6 color vectors
                std::vector<float> colorBuffers[6];
                size_t estimatedPerColor = (count / 6) * 6 + 6;
                for (int p = 0; p < 6; ++p) {
                    colorBuffers[p].reserve(estimatedPerColor);
                }

                for (int i = 0; i < count; ++i) {
                    const auto& c = Confettis[i];
                    int p = c.colorIndex;
                    if (p < 0 || p >= 6) p = 0;

                    const Point3D<float> head = c.getPosition();
                    const Vector3D<float> vel = c.getVelocity();

                    colorBuffers[p].push_back(head.getX() - vel.getX() * tailTime);
                    colorBuffers[p].push_back(-(head.getY() - vel.getY() * tailTime));
                    colorBuffers[p].push_back(head.getZ() - vel.getZ() * tailTime);
                    colorBuffers[p].push_back(head.getX());
                    colorBuffers[p].push_back(-head.getY());
                    colorBuffers[p].push_back(head.getZ());
                }

                // Draw each color batch
                for (int p = 0; p < 6; ++p) {
                    if (colorBuffers[p].empty()) continue;

                    stroke(palette[p].r, palette[p].g, palette[p].b, 255);
                    beginShape(Processing::LINES);
                    for (size_t j = 0; j < colorBuffers[p].size(); j += 6) {
                        vertex(colorBuffers[p][j + 0], colorBuffers[p][j + 1], colorBuffers[p][j + 2]);
                        vertex(colorBuffers[p][j + 3], colorBuffers[p][j + 4], colorBuffers[p][j + 5]);
                    }
                    endShape();
                }
            }
            noStroke();
        }
        else {
            if (solidColor)
            {
                auto* applet = Processing::PApplet::g_papplet;
                if (applet) {
                    // CRITICAL: Force Processing to flush its internal shader color/stroke uniforms 
                    // back to normal, overwriting whatever tint the Bullet left behind.
                    applet->stroke(255, 70, 70, 255);
                    applet->noFill();
                }

                // 1. Initialize VBO once (Position: 3 floats, Color: 4 floats = 7 floats per vertex)
                if (!vboInitialized) {
                    glGenBuffers(1, &confettiVBO);
                    glBindBuffer(GL_ARRAY_BUFFER, confettiVBO);
                    glBufferData(GL_ARRAY_BUFFER, MAX_CONFETTI_POOL * 14 * sizeof(float), nullptr, GL_STREAM_DRAW);
                    vboInitialized = true;
                }

                glBindBuffer(GL_ARRAY_BUFFER, confettiVBO);

                // 2. Map buffer range for zero-copy parallel writing
                float* gpuPtr = (float*)glMapBufferRange(
                    GL_ARRAY_BUFFER,
                    0,
                    count * 14 * sizeof(float),
                    GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT
                );

                if (gpuPtr != nullptr) {
                    constexpr float r = 255.0f / 255.0f;
                    constexpr float g = 70.0f / 255.0f;
                    constexpr float b = 70.0f / 255.0f;
                    constexpr float a = 1.0f;

#pragma omp parallel for schedule(static)
                    for (int i = 0; i < count; ++i) {
                        const auto& c = Confettis[i];
                        const Point3D<float> head = c.getPosition();
                        const Vector3D<float> vel = c.getVelocity();

                        size_t baseIdx = i * 14;

                        // --- Vertex 1 (Tail) ---
                        gpuPtr[baseIdx + 0] = head.getX() - vel.getX() * tailTime;
                        gpuPtr[baseIdx + 1] = -(head.getY() - vel.getY() * tailTime);
                        gpuPtr[baseIdx + 2] = head.getZ() - vel.getZ() * tailTime;
                        gpuPtr[baseIdx + 3] = r;
                        gpuPtr[baseIdx + 4] = g;
                        gpuPtr[baseIdx + 5] = b;
                        gpuPtr[baseIdx + 6] = a;

                        // --- Vertex 2 (Head) ---
                        gpuPtr[baseIdx + 7] = head.getX();
                        gpuPtr[baseIdx + 8] = -head.getY();
                        gpuPtr[baseIdx + 9] = head.getZ();
                        gpuPtr[baseIdx + 10] = r;
                        gpuPtr[baseIdx + 11] = g;
                        gpuPtr[baseIdx + 12] = b;
                        gpuPtr[baseIdx + 13] = a;
                    }

                    glUnmapBuffer(GL_ARRAY_BUFFER);
                }

                // 3. SECURE STATE GUARD
                glDisableClientState(GL_NORMAL_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);

                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_COLOR_ARRAY);

                glVertexPointer(3, GL_FLOAT, 7 * sizeof(float), (void*)0);
                glColorPointer(4, GL_FLOAT, 7 * sizeof(float), (void*)(3 * sizeof(float)));

                glDrawArrays(GL_LINES, 0, static_cast<GLsizei>(count) * 2);

                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_COLOR_ARRAY);
                glBindBuffer(GL_ARRAY_BUFFER, 0);
            }
            else // Multi-color mode
            {
                if (!vboInitialized) {
                    glGenBuffers(1, &confettiVBO);
                    glBindBuffer(GL_ARRAY_BUFFER, confettiVBO);
                    glBufferData(GL_ARRAY_BUFFER, MAX_CONFETTI_POOL * 14 * sizeof(float), nullptr, GL_STREAM_DRAW);
                    vboInitialized = true;
                }

                glBindBuffer(GL_ARRAY_BUFFER, confettiVBO);

                // 1. Map the buffer for writing
                float* gpuPtr = (float*)glMapBufferRange(
                    GL_ARRAY_BUFFER,
                    0,
                    count * 14 * sizeof(float),
                    GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT
                );

                if (gpuPtr != nullptr) {
                    // Palette converted to normalized floats (0.0 to 1.0)
                    constexpr float paletteRGB[6][3] = {
                        {255.0f / 255.0f,  70.0f / 255.0f,  70.0f / 255.0f},  // Red
                        { 70.0f / 255.0f, 255.0f / 255.0f, 120.0f / 255.0f},  // Green
                        { 70.0f / 255.0f, 160.0f / 255.0f, 255.0f / 255.0f},  // Blue
                        {255.0f / 255.0f, 220.0f / 255.0f,  50.0f / 255.0f},  // Yellow
                        {255.0f / 255.0f, 120.0f / 255.0f, 220.0f / 255.0f},  // Magenta
                        { 50.0f / 255.0f, 255.0f / 255.0f, 255.0f / 255.0f}   // Cyan
                    };

                    // 2. Parallel write straight into the VBO block
                    #pragma omp parallel for schedule(static)
                    for (int i = 0; i < count; ++i) {
                        const auto& c = Confettis[i];
                        int p = c.colorIndex;
                        if (p < 0 || p >= 6) p = 0;

                        const Point3D<float> head = c.getPosition();
                        const Vector3D<float> vel = c.getVelocity();

                        size_t baseIdx = i * 14;

                        // --- Vertex 1 (Tail) ---
                        gpuPtr[baseIdx + 0] = head.getX() - vel.getX() * tailTime;
                        gpuPtr[baseIdx + 1] = -(head.getY() - vel.getY() * tailTime);
                        gpuPtr[baseIdx + 2] = head.getZ() - vel.getZ() * tailTime;
                        gpuPtr[baseIdx + 3] = paletteRGB[p][0];
                        gpuPtr[baseIdx + 4] = paletteRGB[p][1];
                        gpuPtr[baseIdx + 5] = paletteRGB[p][2];
                        gpuPtr[baseIdx + 6] = 1.0f; // Alpha

                        // --- Vertex 2 (Head) ---
                        gpuPtr[baseIdx + 7] = head.getX();
                        gpuPtr[baseIdx + 8] = -head.getY();
                        gpuPtr[baseIdx + 9] = head.getZ();
                        gpuPtr[baseIdx + 10] = paletteRGB[p][0];
                        gpuPtr[baseIdx + 11] = paletteRGB[p][1];
                        gpuPtr[baseIdx + 12] = paletteRGB[p][2];
                        gpuPtr[baseIdx + 13] = 1.0f; // Alpha
                    }

                    glUnmapBuffer(GL_ARRAY_BUFFER);
                }

                // 3. Draw everything in a single VBO state pass
                glDisableClientState(GL_NORMAL_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);

                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_COLOR_ARRAY);

                glVertexPointer(3, GL_FLOAT, 7 * sizeof(float), (void*)0);
                glColorPointer(4, GL_FLOAT, 7 * sizeof(float), (void*)(3 * sizeof(float)));

                glDrawArrays(GL_LINES, 0, static_cast<GLsizei>(count) * 2);

                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_COLOR_ARRAY);
                glBindBuffer(GL_ARRAY_BUFFER, 0);
            }
        }
        
        for (auto& particle : particles) {
            particle->draw();
            if (showTrajectories) {
                renderParticleTrace(*particle);
            }
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

    std::string formatWithCommas(int value) {
        std::string s = std::to_string(value);
        int n = static_cast<int>(s.length());
        int insertPosition = n - 3;
        while (insertPosition > 0) {
            s.insert(insertPosition, ",");
            insertPosition -= 3;
        }
        return s;
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

        text("Particle instance Count: " + formatWithCommas(Particle<float>::particleCount) +
            "    FPS: " + std::to_string(std::lround(customFPS)) +
            "   ms/frame: " + std::to_string(std::lround(smoothedDeltaTime * 1000.0f)), 15, 30);
        text("Aim Mode [M]: " + modeText, 15, 60);
        text("Current Projectile [Scroll]: " + projectileText, 15, 90);
        text(std::string("Display trajectories [T]: ") + (showTrajectories ? "ON" : "OFF"), 15, 120);
        text("Score : " + std::to_string(goal.getScore()) + "/" + neededGoal, 15, 150);
        text("Confettis per second : " + formatWithCommas(confettiSpawnAmount) + " [W] + 10 000 [S] -10 000", 15, 180);
        text("Go to end screen : [G]", 15, 210);
        text("Active Confettis: " + formatWithCommas(activeConfetti), 15, 240);
        text("Make Confettis uniform: [C]", 15, 270);
        text("VBO enabled [V] " + std::string(useVBO ? "ON" : "OFF"), 15, 300);
        text("Cull confettis at floor level [V] " + std::string(cullConfettis ? "ON" : "OFF"), 15, 300);
    }

void spawnConfettis(float quantity) {
        confettiSpawnAccumulator += quantity;
        int toSpawn = static_cast<int>(confettiSpawnAccumulator);
        confettiSpawnAccumulator -= toSpawn;

        if (toSpawn <= 0) return;

        static std::mt19937 rng(std::random_device{}());

        // Tightly clustered horizontal spread (X and Z)
        std::uniform_real_distribution<float> distHorizontal(-75.0f, 75.0f);

        // Strong, high-speed upward velocity (Y)
        std::uniform_real_distribution<float> distUpward(200.0f, 250.0f);

        for (int i = 0; i < toSpawn; ++i) {
            Vector3D<float> velocity(
                distHorizontal(rng), // Tight X spread
                distUpward(rng),     // Fast upward thrust
                distHorizontal(rng)  // Tight Z spread
            );

            size_t targetIndex = 0;

            if (static_cast<size_t>(activeConfetti) < MAX_CONFETTI_POOL) {
                targetIndex = static_cast<size_t>(activeConfetti);
                ++activeConfetti;
            }
            else {
                targetIndex = confettiRecycleCursor;
                confettiRecycleCursor = (confettiRecycleCursor + 1) % MAX_CONFETTI_POOL;
            }

            Confettis[targetIndex].setPosition(Point3D<float>(0.0f, -floorY, 600.0f));
            Confettis[targetIndex].setVelocity(velocity);
        }
    }
};