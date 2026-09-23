// ==========================================
// Arena, TargetGoal, AimSolvers & Factory
// ==========================================

class Arena {
    final float Extent = 2560.0f;
    final float Spacing = 40.0f;
    final float WallHeight = 1200.0f;
    final float WallThickness = 10.0f;
    final float MaxCeilingHeight = 2000.0f;

    void setupLighting(processing.core.PApplet app) {
        app.background(18, 24, 38);
        app.camera(0.0f, -40.0f, -520.0f,
                   0.0f, 0.0f, 0.0f,
                   0.0f, 1.0f, 0.0f);
        app.lights();
        app.ambientLight(70, 80, 110);
        app.directionalLight(220, 220, 220, -0.4f, -0.8f, -0.5f);
    }

    void draw(processing.core.PApplet app) {
        // --- Floor Base ---
        app.noStroke();
        app.fill(35, 48, 68);
        app.pushMatrix();
        app.translate(0.0f, GraphicsConstants.floorY - 2.0f, 0.0f);
        app.box(Extent * 2.0f, 4.0f, Extent * 2.0f);
        app.popMatrix();

        // --- Floor Grid ---
        app.stroke(90, 110, 140);
        app.strokeWeight(1.0f);
        for (float coord = -Extent; coord <= Extent; coord += Spacing) {
            app.line(coord, GraphicsConstants.floorY, -Extent, coord, GraphicsConstants.floorY, Extent);
            app.line(-Extent, GraphicsConstants.floorY, coord, Extent, GraphicsConstants.floorY, coord);
        }
        app.noStroke();

        // --- Boundary Walls ---
        app.fill(45, 60, 85, 180);
        float wallCenterY = GraphicsConstants.floorY - (WallHeight * 0.5f);

        app.pushMatrix(); app.translate(0.0f, wallCenterY, -Extent); app.box(Extent * 2.0f, WallHeight, WallThickness); app.popMatrix();
        app.pushMatrix(); app.translate(0.0f, wallCenterY, Extent); app.box(Extent * 2.0f, WallHeight, WallThickness); app.popMatrix();
        app.pushMatrix(); app.translate(-Extent, wallCenterY, 0.0f); app.box(WallThickness, WallHeight, Extent * 2.0f); app.popMatrix();
        app.pushMatrix(); app.translate(Extent, wallCenterY, 0.0f); app.box(WallThickness, WallHeight, Extent * 2.0f); app.popMatrix();
    }

    boolean isOutOfBounds(Point3D pos) {
        return (pos.getY() <= -GraphicsConstants.floorY) ||
               (pos.getY() >= MaxCeilingHeight) ||
               (Math.abs(pos.getX()) >= Extent) ||
               (Math.abs(pos.getZ()) >= Extent);
    }
}

class TargetGoal {
    private float m_radius;
    private Point3D m_position;
    private int m_score;

    public TargetGoal(float radius) {
        m_radius = radius;
        m_position = new Point3D(0.0f, -GraphicsConstants.floorY, 600.0f);
        m_score = 0;
    }

    void resetValues() {
        m_score = 0;
        m_position = new Point3D(0.0f, -GraphicsConstants.floorY, 600.0f);
    }

    void reset() {
        float x = (float)ThreadLocalRandom.current().nextDouble(-800.0, 800.0);
        float z = (float)ThreadLocalRandom.current().nextDouble(300.0, 1500.0);
        m_position = new Point3D(x, -GraphicsConstants.floorY, z);
    }

    boolean checkHit(Point3D particlePos) {
        if (particlePos.getY() <= -GraphicsConstants.floorY) {
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

    void draw(processing.core.PApplet app) {
        app.pushMatrix();
        app.translate(m_position.getX(), GraphicsConstants.floorY - 4.5f, m_position.getZ());
        app.rotateX(-PI * 0.5f);

        app.fill(255, 50, 50, 220);
        app.stroke(255, 180, 180);
        app.strokeWeight(3.0f);
        app.circle(0.0f, 0.0f, m_radius * 2.0f);

        app.fill(255, 220, 30, 240);
        app.noStroke();
        app.circle(0.0f, 0.0f, m_radius * 0.8f);

        app.popMatrix();
        app.noStroke();
    }

    int getScore() { return m_score; }
    Point3D getPosition() { return m_position; }
    float getRadius() { return m_radius; }
}

class AimSolvers {
    ArrayList<Point3D> predictAimTrajectory(Point3D origin, Vector3D initialVelocity, Vector3D acceleration, float damping, int precision, float totalTime) {
        if (precision < 4) precision = 4;

        ArrayList<Point3D> trajectory = new ArrayList<Point3D>();
        float timeStep = totalTime / (float)precision;
        float dampingFactor = (float)Math.pow(damping, timeStep);

        Point3D currentPos = origin;
        Vector3D currentVel = initialVelocity;

        trajectory.add(currentPos);

        for (int i = 0; i < precision; ++i) {
            currentPos = currentPos.add(currentVel.mult(timeStep)).add(acceleration.mult(0.5f * timeStep * timeStep));
            currentVel = currentVel.add(acceleration.mult(timeStep));
            currentVel = currentVel.mult(dampingFactor);

            trajectory.add(currentPos);
        }
        return trajectory;
    }

    Vector3D getAimGroundTarget(float mouseX, float mouseY, float screenWidth, float screenHeight, float speed) {
        float ndcX = (2.0f * mouseX) / screenWidth - 1.0f;
        float ndcY = (2.0f * mouseY) / screenHeight - 1.0f;

        Point3D camPos = new Point3D(0.0f, -40.0f, -520.0f);
        final float fov = PI / 3.0f;
        float aspect = screenWidth / screenHeight;
        float halfHeight = (float)Math.tan(fov * 0.5f);
        float halfWidth = halfHeight * aspect;

        Vector3D rayDir = new Vector3D(-ndcX * halfWidth, ndcY * halfHeight, 1.0f).normalized();

        final float targetY = 0.0f;
        float t = (targetY - camPos.getY()) / rayDir.getY();

        Point3D targetPoint;
        if (t > 0.0f) {
            targetPoint = new Point3D(camPos.getX() + rayDir.getX() * t, targetY, camPos.getZ() + rayDir.getZ() * t);
        } else {
            targetPoint = new Point3D(camPos.getX() + rayDir.getX() * 1000.0f, camPos.getY() + rayDir.getY() * 1000.0f, camPos.getZ() + rayDir.getZ() * 1000.0f);
        }

        Point3D origin = new Point3D(0.0f, 0.0f, 0.0f);
        Vector3D fireDir = new Vector3D(
            targetPoint.getX() - origin.getX(),
            targetPoint.getY() - origin.getY(),
            targetPoint.getZ() - origin.getZ()
        ).normalized();

        return fireDir.mult(speed);
    }

    Vector3D getAimTurret(float mouseX, float mouseY, float screenWidth, float screenHeight, float speed) {
        float clampedX = constrain(mouseX, 0.0f, screenWidth);
        float clampedY = constrain(mouseY, 0.0f, screenHeight);

        float normY = clampedY / screenHeight;
        float normX = (clampedX - screenWidth * 0.5f) / (screenWidth * 0.5f);

        final float maxYaw = 1.047197f;
        float yaw = -normX * maxYaw;

        final float minPitch = -0.959931f; 
        final float maxPitch = 1.221730f; 

        float smoothT = normY * normY * (3.0f - 2.0f * normY);
        float pitch = maxPitch - smoothT * (maxPitch - minPitch);

        Vector3D dir = new Vector3D(
            (float)(Math.sin(yaw) * Math.cos(pitch)),
            (float)Math.sin(pitch),
            (float)(Math.cos(yaw) * Math.cos(pitch))
        ).normalized();

        return dir.mult(speed);
    }
}

class ProjectileFactory {
    float getBaseSpeed(SelectedProjectile type) {
        switch (type) {
            case Ball:     return Ball.baseSpeed;
            case Laser:    return Laser.baseSpeed;
            case Fireball: return Fireball.baseSpeed;
            case Confetti: return Confetti.baseSpeed;
            case Bullet:
            default:       return Bullet.baseSpeed;
        }
    }

    boolean getDefaultGravityState(SelectedProjectile type) {
        switch (type) {
            case Ball:     return Ball.defaultGravityState;
            case Laser:    return Laser.defaultGravityState;
            case Fireball: return Fireball.defaultGravityState;
            case Confetti: return Confetti.defaultGravityState;
            case Bullet:
            default:       return Bullet.defaultGravityState;
        }
    }

    String getDisplayName(SelectedProjectile type) {
        switch (type) {
            case Ball:     return "Cannon ball";
            case Laser:    return "Laser";
            case Fireball: return "Fireball";
            case Confetti: return "Confetti";
            case Bullet:
            default:       return "Bullet";
        }
    }

    Particle create(SelectedProjectile type, Point3D origin, Vector3D velocity) {
        switch (type) {
            case Ball:     return new Ball(origin, velocity);
            case Laser:    return new Laser(origin, velocity);
            case Fireball: return new Fireball(origin, velocity);
            case Confetti: return new Confetti(origin, velocity);
            case Bullet:
            default:       return new Bullet(origin, velocity);
        }
    }
}
