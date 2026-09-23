// ==========================================
// Definitions and Constants
// ==========================================

interface GraphicsConstants {
    int ScreenWidth = 1920;
    int ScreenHeight = 1080;
    float floorY = 300.0f;
}

interface PhysicsConstants {
    float FIXED_TIMESTEP = 1.0f / 60.0f;
    float MAX_FRAME_TIME = 0.25f;
    float GRAVITY = 9.81f;
}

enum SelectedProjectile {
    Bullet,
    Ball,
    Laser,
    Fireball,
    Confetti
}

enum AimMode {
    RayGroundTarget,
    TurretSpherical
}
