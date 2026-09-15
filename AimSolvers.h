#pragma once

#include "PhysicsEngine.h"
#include <vector>
#include <cmath>
#include <numbers>
#include <algorithm>
#include <concepts>

enum class AimMode {
    RayGroundTarget,
    TurretSpherical
};

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
    float clampedX = std::clamp(mouseX, 0.0f, screenWidth);
    float clampedY = std::clamp(mouseY, 0.0f, screenHeight);

    float normY = clampedY / screenHeight;
    float normX = (clampedX - screenWidth * 0.5f) / (screenWidth * 0.5f);

    constexpr float maxYaw = 1.047197f;
    float yaw = -normX * maxYaw;

    constexpr float minPitch = -0.959931f; // ~ -55 degrees
    constexpr float maxPitch = 1.221730f; // ~ +70 degrees

    float smoothT = normY * normY * (3.0f - 2.0f * normY);
    float pitch = maxPitch - smoothT * (maxPitch - minPitch);

    Vector3D<float> dir(
        std::sin(yaw) * std::cos(pitch),
        std::sin(pitch),
        std::cos(yaw) * std::cos(pitch)
    );
    dir.normalize();

    return dir * speed;
}