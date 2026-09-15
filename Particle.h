#pragma once
#include "Point3D.h"
#include "Vector3D.h"
#include "PhysicsConstants.h"
#include <vector>

template <std::floating_point T = double>
class Particle {
public:
    static inline int particleCount{ 0 };

private:
    Point3D<T> m_position{};
    Vector3D<T> m_velocity{};
    Vector3D<T> m_acceleration{};
    T m_inverseMass{ static_cast<T>(1.0) };
    T m_linearDamping{ static_cast<T>(0.999) }; // damping per tick or half-life
    bool m_affectedByGravity{ true };

    Vector3D<T> computeAcceleration() const {
        if (m_inverseMass <= static_cast<T>(0)) {
            return Vector3D<T>{};
        }

        Vector3D<T> totalAccel = m_acceleration;

        //Acculator will be implemented later, for now we just return the current acceleration

        return totalAccel;
    }

public:
    Particle(const Point3D<T>& pos = {},
        const Vector3D<T>& vel = {},
        const Vector3D<T>& accel = {},
        T mass = static_cast<T>(1),
        T damping = static_cast<T>(0.999),
        bool affectedByGravity = true)
        : m_position(pos),
        m_velocity(vel),
        m_acceleration(accel),
        m_inverseMass(mass > static_cast<T>(0) ? static_cast<T>(1) / mass : static_cast<T>(0)),
        m_linearDamping(damping),
        m_affectedByGravity(affectedByGravity) {
        if (m_affectedByGravity) {
            m_acceleration += Vector3D<T>(0, -static_cast<T>(GRAVITY), 0);
        }
        ++particleCount;
    }

    Particle(const Particle& other)
        : m_position(other.m_position),
        m_velocity(other.m_velocity),
        m_acceleration(other.m_acceleration),
        m_inverseMass(other.m_inverseMass),
        m_linearDamping(other.m_linearDamping),
        m_affectedByGravity(other.m_affectedByGravity) {
        ++particleCount;
    }

    Particle(Particle&& other) noexcept
        : m_position(std::move(other.m_position)),
        m_velocity(std::move(other.m_velocity)),
        m_acceleration(std::move(other.m_acceleration)),
        m_inverseMass(other.m_inverseMass),
        m_linearDamping(other.m_linearDamping),
        m_affectedByGravity(other.m_affectedByGravity) {
        ++particleCount;
    }

    Particle& operator=(const Particle& other) = default;

    Particle& operator=(Particle&& other) noexcept = default;

    ~Particle() {
        --particleCount;
    }

    Point3D<T> getPosition() const { return m_position; }
    Vector3D<T> getVelocity() const { return m_velocity; }
    Vector3D<T> getAcceleration() const { return m_acceleration; }
    Vector3D<T> getTotalAcceleration() const { return computeAcceleration(); }
    T getMass() const { return m_inverseMass > static_cast<T>(0) ? static_cast<T>(1) / m_inverseMass : static_cast<T>(0); }
    T getInverseMass() const { return m_inverseMass; }
    T getLinearDamping() const { return m_linearDamping; }
    bool getAffectedByGravity() const { return m_affectedByGravity; }

    void applyVerletIntegration(T deltaTime) {
        if (m_inverseMass <= static_cast<T>(0)) return;

        // 1. Drift: update position
        m_position = m_position + m_velocity * deltaTime + m_acceleration * (static_cast<T>(0.5) * deltaTime * deltaTime);

        // 2. Evaluate new acceleration
        Vector3D<T> newAcceleration = computeAcceleration();

        // 3. Kick: update velocity
        m_velocity += (m_acceleration + newAcceleration) * (static_cast<T>(0.5) * deltaTime);

        // 4. 4. Time-corrected damping
        m_velocity *= std::pow(m_linearDamping, deltaTime);

        // 5. Cache acceleration for next frame
        m_acceleration = newAcceleration;
    }

    virtual void draw() const {
        // Placeholder for drawing the particle
        std::cout << "Drawing Particle at position: " << m_position << std::endl;
    }

    std::vector<Point3D<T>> getTrajectory(int precision, T Time) const {
        if (precision <= 4) { precision = 4; }
        std::vector<Point3D<T>> m_trajectory;
        m_trajectory.reserve(precision + 1);

        T timeStep = Time / static_cast<T>(precision);
        Vector3D<T> accel = computeAcceleration();
        Point3D<T> currentPos = m_position;
        Vector3D<T> currentVel = m_velocity;
        T dampingFactor = std::pow(m_linearDamping, timeStep);

        m_trajectory.push_back(currentPos);

        for (int i = 0; i < precision; ++i) {
            currentPos = currentPos + currentVel * timeStep + accel * (static_cast<T>(0.5) * timeStep * timeStep);
            currentVel += accel * timeStep;
            currentVel *= dampingFactor;

            m_trajectory.push_back(currentPos);
        }

        return m_trajectory;
    }
};

