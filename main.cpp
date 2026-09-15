#include "Processing.h"
#include "PhysicsEngine.h"
#include "Bullet.h"
#include "GraphicsConstants.h"
#include <vector>
#include <cmath>
#include <memory>
#include <numbers>
#include <string>

#ifdef _DEBUG
#include "Test.h"
#endif

// =============================================================================
// Trajectory Prediction Helpers
// =============================================================================

template <std::floating_point T = float>
std::vector<Point3D<T>> predictAimTrajectory(
    const Point3D<T>& origin,
    const Vector3D<T>& initialVelocity,
    const Vector3D<T>& acceleration,
    T damping,
    int precision = 30,
    T totalTime = static_cast<T>(3.0))
{
    if (precision < 4) { precision = 4; }

    std::vector<Point3D<T>> trajectory;
    trajectory.reserve(precision + 1);

    T timeStep = totalTime / static_cast<T>(precision);
    T dampingFactor = std::pow(damping, timeStep);

    Point3D<T> currentPos = origin;
    Vector3D<T> currentVel = initialVelocity;

    trajectory.push_back(currentPos);

    for (int i = 0; i < precision; ++i) {
        currentPos = currentPos + currentVel * timeStep + acceleration * (static_cast<T>(0.5) * timeStep * timeStep);
        currentVel += acceleration * timeStep;
        currentVel *= dampingFactor;

        trajectory.push_back(currentPos);
    }

    return trajectory;
}

// =============================================================================
// Aim Modes & Solvers
// =============================================================================

enum class AimMode {
    RayGroundTarget,
    TurretSpherical
};

inline Vector3D<float> getAimGroundTarget(
    float mouseX, float mouseY,
    float screenWidth, float screenHeight,
    float speed = 500.0f)
{
    float ndcX = (2.0f * mouseX) / screenWidth - 1.0f;
    float ndcY = (2.0f * mouseY) / screenHeight - 1.0f;

    Point3D<float> camPos(0.0f, -40.0f, -520.0f);

    constexpr float fov = std::numbers::pi_v<float> / 3.0f;
    float aspect = screenWidth / screenHeight;
    float halfHeight = std::tan(fov * 0.5f);
    float halfWidth = halfHeight * aspect;

    Vector3D<float> rayDir(-ndcX * halfWidth, ndcY * halfHeight, 1.0f);
    rayDir.normalize();

    // Intersect horizontal plane at Y = 0
    constexpr float targetY = 0.0f;
    float t = (targetY - camPos.getY()) / rayDir.getY();

    Point3D<float> targetPoint;
    if (t > 0.0f) {
        targetPoint = Point3D<float>(
            camPos.getX() + rayDir.getX() * t,
            targetY,
            camPos.getZ() + rayDir.getZ() * t
        );
    }
    else {
        targetPoint = Point3D<float>(
            camPos.getX() + rayDir.getX() * 1000.0f,
            camPos.getY() + rayDir.getY() * 1000.0f,
            camPos.getZ() + rayDir.getZ() * 1000.0f
        );
    }

    Point3D<float> origin(0.0f, 0.0f, 0.0f);
    Vector3D<float> fireDir(
        targetPoint.getX() - origin.getX(),
        targetPoint.getY() - origin.getY(),
        targetPoint.getZ() - origin.getZ()
    );
    fireDir.normalize();

    return fireDir * speed;
}

inline Vector3D<float> getAimTurret(
    float mouseX, float mouseY,
    float screenWidth, float screenHeight,
    float speed = 500.0f)
{
    float u = (mouseX - screenWidth * 0.5f) / (screenWidth * 0.5f);
    float v = (mouseY - screenHeight * 0.5f) / (screenHeight * 0.5f);

    constexpr float maxYaw = 1.047197f;    // ~60 degrees
    constexpr float minPitch = -0.174533f; // ~ -10 degrees
    constexpr float maxPitch = 1.308997f;  // ~ 75 degrees

    float yaw = -u * maxYaw;
    float pitch = minPitch + (1.0f - (v + 1.0f) * 0.5f) * (maxPitch - minPitch);

    Vector3D<float> dir(
        std::sin(yaw) * std::cos(pitch),
        std::sin(pitch),
        std::cos(yaw) * std::cos(pitch)
    );
    dir.normalize();

    return dir * speed;
}

// =============================================================================
// Bullet selection
// =============================================================================


// =============================================================================
// Application Sketch
// =============================================================================

struct Sketch : public Processing::PApplet {
    std::vector<Particle<float>*> particles;
    AimMode currentAimMode{ AimMode::RayGroundTarget };
    constexpr static float bulletMuzzleSpeed{ 500.0f };

    void settings() override {
        size(ScreenWidth, ScreenHeight, Processing::P3D);
    }

    void setup() override {
        spawnBullet(computeCurrentAimVelocity());
    }

    void draw() override {
        renderEnvironment();
        updateAndRenderParticles();
        renderAimPreview();
        renderHUD();
    }

    void mousePressed() override {
        spawnBullet(computeCurrentAimVelocity());
    }

    void keyPressed() override {
        // Press 'M' to toggle between Raycast and Turret aiming models
        if (key == 'm' || key == 'M') {
            currentAimMode = (currentAimMode == AimMode::RayGroundTarget)
                ? AimMode::TurretSpherical
                : AimMode::RayGroundTarget;
        }
    }

    ~Sketch() override {
        for (Particle<float>* particle : particles) {
            delete particle;
        }
        particles.clear();
    }

private:
    Vector3D<float> computeCurrentAimVelocity() const {
        if (currentAimMode == AimMode::RayGroundTarget) {
            return getAimGroundTarget(
                static_cast<float>(mouseX),
                static_cast<float>(mouseY),
                static_cast<float>(width),
                static_cast<float>(height),
                bulletMuzzleSpeed
            );
        }
        return getAimTurret(
            static_cast<float>(mouseX),
            static_cast<float>(mouseY),
            static_cast<float>(width),
            static_cast<float>(height),
            bulletMuzzleSpeed
        );
    }

    void spawnBullet(const Vector3D<float>& initialVelocity) {
        particles.push_back(new Bullet(Point3D<float>(0.0f, 0.0f, 0.0f), initialVelocity));
    }

    void renderEnvironment() {
        background(18, 24, 38);
        camera(0.0f, -40.0f, -520.0f,
            0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f);
        lights();
        ambientLight(70, 80, 110);
        directionalLight(220, 220, 220, -0.4f, -0.8f, -0.5f);

        drawFloor();
    }

    void updateAndRenderParticles() {
        for (auto it = particles.begin(); it != particles.end();) {
            Particle<float>* particle = *it;

            particle->applyVerletIntegration(deltaTime);
            particle->draw();

            // Render live trajectory trace
            std::vector<Point3D<float>> trajectory = particle->getTrajectory(20, 10.0f);

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

            // Cull particles that fall below the boundary
            if (particle->getPosition().getY() <= -floorY) {
                delete particle;
                it = particles.erase(it);
            }
            else {
                ++it;
            }
        }
    }

    void renderAimPreview() {
        Point3D<float> origin(0.0f, 0.0f, 0.0f);
        Vector3D<float> gravity(0.0f, -static_cast<float>(GRAVITY), 0.0f);
        Vector3D<float> aimVelocity = computeCurrentAimVelocity();

        auto aimTrajectory = predictAimTrajectory(origin, aimVelocity, gravity, 0.999f, 35, 10.0f);

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

        text("Particle Count: " + std::to_string(Particle<float>::particleCount) +
            "    FPS: " + std::to_string(Processing::PApplet::getFrameRate()), 15, 30);
        text("Aim Mode [M]: " + modeText, 15, 60);
    }

    void drawFloor() {
        constexpr float extent = 2560.0f;
        constexpr float spacing = 40.0f;

        noStroke();
        fill(35, 48, 68);
        pushMatrix();
        translate(0.0f, floorY - 2.0f, 0.0f);
        box(extent * 2.0f, 4.0f, extent * 2.0f);
        popMatrix();

        stroke(90, 110, 140);
        strokeWeight(1.0f);
        for (float coordinate = -extent; coordinate <= extent; coordinate += spacing) {
            line(coordinate, floorY, -extent, coordinate, floorY, extent);
            line(-extent, floorY, coordinate, extent, floorY, coordinate);
        }
        noStroke();
    }
};

// =============================================================================
// Main Entry Point
// =============================================================================

int main() {
#ifdef _DEBUG
    Test::run();
#endif

    auto sketch = std::make_unique<Sketch>();
    sketch->run();

    return 0;
}