#pragma once

#include "PhysicsEngine.h"
#include "Bullet.h"
#include "Ball.h"
#include "Laser.h"
#include "Fireball.h"
#include "Confetti.h"
#include <memory>
#include <string>

enum class SelectedProjectile {
    Bullet = 0,
    Ball,
    Laser,
    Fireball,
    Confetti,
    Count
};

class ProjectileFactory {
public:
    static float getBaseSpeed(SelectedProjectile type) {
        switch (type) {
        case SelectedProjectile::Ball:     return Ball::baseSpeed;
        case SelectedProjectile::Laser:    return Laser::baseSpeed;
        case SelectedProjectile::Fireball: return Fireball::baseSpeed;
        case SelectedProjectile::Confetti: return Confetti::baseSpeed;
        case SelectedProjectile::Bullet:
        default:                           return Bullet::baseSpeed;
        }
    }

    static bool getDefaultGravityState(SelectedProjectile type) {
        switch (type) {
        case SelectedProjectile::Ball:     return Ball::defaultGravityState;
        case SelectedProjectile::Laser:    return Laser::defaultGravityState;
        case SelectedProjectile::Fireball: return Fireball::defaultGravityState;
        case SelectedProjectile::Confetti: return Confetti::defaultGravityState;
        case SelectedProjectile::Bullet:
        default:                           return Bullet::defaultGravityState;
        }
    }


    static std::string getDisplayName(SelectedProjectile type) {
        switch (type) {
        case SelectedProjectile::Ball:     return "Cannon ball";
        case SelectedProjectile::Laser:    return "Laser";
        case SelectedProjectile::Fireball: return "Fireball";
        case SelectedProjectile::Confetti: return "Confetti";
        case SelectedProjectile::Bullet:
        default:                           return "Bullet";
        }
    }

    static std::unique_ptr<Particle<float>> create(
        SelectedProjectile type,
        const Point3D<float>& origin,
        const Vector3D<float>& velocity)
    {
        switch (type) {
        case SelectedProjectile::Ball:
            return std::make_unique<Ball>(origin, velocity);
        case SelectedProjectile::Laser:
            return std::make_unique<Laser>(origin, velocity);
        case SelectedProjectile::Fireball:
            return std::make_unique<Fireball>(origin, velocity);
        case SelectedProjectile::Confetti: 
            return std::make_unique<Confetti>(origin, velocity);
        case SelectedProjectile::Bullet:
        default:
            return std::make_unique<Bullet>(origin, velocity);
        }
    }
};