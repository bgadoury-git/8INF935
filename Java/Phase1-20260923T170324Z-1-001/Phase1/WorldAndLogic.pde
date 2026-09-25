// ==========================================
// Arena, TargetGoal, AimSolvers & Factory
// ==========================================

class Arena {
    final float Extent = 2560.0f;
    final float Spacing = 40.0f;
    final float WallHeight = 1200.0f;
    final float WallThickness = 10.0f;
    final float MaxCeilingHeight = 2000.0f;

    // Depth (Z) at which the grassy plain ends and the water begins.
    // The cannon sits on the plain side (Z < ShoreZ), the boats float
    // on the water side (Z >= ShoreZ), matching TargetGoal's spawn range.
    final float ShoreZ = 150.0f;

    void setupLighting(processing.core.PApplet app) {
        app.background(130, 190, 232); // open sky
        app.camera(0.0f, -40.0f, -520.0f,
                   0.0f, 0.0f, 0.0f,
                   0.0f, 1.0f, 0.0f);
        app.lights();
        app.ambientLight(130, 135, 140);
        app.directionalLight(255, 250, 232, -0.35f, -0.75f, -0.4f);
    }

    void draw(processing.core.PApplet app) {
        float floorTopY = GraphicsConstants.floorY - 2.0f;

        // --- Plain (grass), from the back wall up to the shoreline ---
        float plainDepth = ShoreZ - (-Extent);
        app.noStroke();
        app.fill(70, 120, 60);
        app.pushMatrix();
        app.translate(0.0f, floorTopY, -Extent + plainDepth * 0.5f);
        app.box(Extent * 2.0f, 4.0f, plainDepth);
        app.popMatrix();

        // --- Water, from the shoreline to the far wall ---
        float waterDepth = Extent - ShoreZ;
        app.fill(40, 95, 165, 235);
        app.pushMatrix();
        app.translate(0.0f, floorTopY, ShoreZ + waterDepth * 0.5f);
        app.box(Extent * 2.0f, 4.0f, waterDepth);
        app.popMatrix();

        // --- Shoreline strip ---
        app.fill(210, 195, 150);
        app.pushMatrix();
        app.translate(0.0f, floorTopY - 0.5f, ShoreZ);
        app.box(Extent * 2.0f, 3.0f, 26.0f);
        app.popMatrix();

        // --- Grass Grid (plain only) ---
        app.stroke(95, 150, 90, 160);
        app.strokeWeight(1.0f);
        for (float coord = -Extent; coord <= Extent; coord += Spacing) {
            app.line(coord, GraphicsConstants.floorY, -Extent, coord, GraphicsConstants.floorY, ShoreZ);
        }
        for (float coord = -Extent; coord <= ShoreZ; coord += Spacing) {
            app.line(-Extent, GraphicsConstants.floorY, coord, Extent, GraphicsConstants.floorY, coord);
        }

        // --- Water ripples (water side only) ---
        app.stroke(170, 220, 240, 140);
        for (float coord = ShoreZ + Spacing; coord <= Extent; coord += Spacing * 2.0f) {
            app.line(-Extent, GraphicsConstants.floorY, coord, Extent, GraphicsConstants.floorY, coord);
        }
        app.noStroke();

        // --- Boundary Walls (distant hills / haze) ---
        app.fill(75, 110, 95, 160);
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
    private float DeckOffset = 50.0f;

    // Boat geometry, derived once from m_radius and shared by draw() and
    // checkHit() so the hitbox always matches what is actually drawn.
    private float m_hullRadius;
    private float m_hullDepth;
    private float m_mastHeight;

    public TargetGoal(float radius) {
        m_radius = radius;
        m_hullRadius = m_radius * 0.55f;
        m_hullDepth = m_hullRadius * 0.6f;
        m_mastHeight = m_radius * 1.6f;
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
        // Vertical extent of the boat: from the bottom of the hull (underwater)
        // up to the tip of the sail. Anything outside this band is a clean miss —
        // this is what stops "hits" registering deep below the hull.
        float deckY = -(GraphicsConstants.floorY - DeckOffset);
        float hullBottomY = deckY - m_hullDepth;
        float sailTopY = deckY + m_mastHeight;

        float py = particlePos.getY();
        if (py < hullBottomY || py > sailTopY) {
            return false;
        }

        float dx = particlePos.getX() - m_position.getX();
        float dz = particlePos.getZ() - m_position.getZ();

        boolean hit;
        if (py >= deckY) {
            // Sail band: the triangle only bulges toward +X (world), the mast
            // itself sits at dx = 0. Keep only a thin margin on the empty
            // side (-X) so aiming past the mast, away from the sail, misses.
            float sailRadius = m_hullRadius * 1.10f;
            float mastMargin = m_hullRadius * 0.25f;
            hit = (dx >= -mastMargin) && ((dx * dx + dz * dz) <= (sailRadius * sailRadius));
        } else {
            // Hull band: hugs the drawn hull closely, symmetric around the mast.
            float hullHitRadius = m_hullRadius * 1.05f;
            hit = (dx * dx + dz * dz) <= (hullHitRadius * hullHitRadius);
        }

        if (hit) {
            ++m_score;
            reset();
            return true;
        }
        return false;
    }

    void draw(processing.core.PApplet app) {
        // Drawn upright, facing the cannon (no rotateX), so it reads as a
        // boat sitting on the water rather than a decal painted on the ground.
        app.pushMatrix();
        app.translate(m_position.getX(), GraphicsConstants.floorY - DeckOffset, m_position.getZ());

        int segments = 14;

        // --- Hull: half circle, flat edge on the waterline, bulging downward ---
        app.stroke(70, 42, 22);
        app.strokeWeight(1.5f);
        app.fill(120, 78, 48);
        app.beginShape();
        for (int i = 0; i <= segments; ++i) {
            float t = PI * (float)i / (float)segments;
            float hx = cos(t) * m_hullRadius;
            float hy = sin(t) * m_hullDepth;
            app.vertex(hx, hy, 0.0f);
        }
        app.endShape(CLOSE);
        app.noStroke();

        // --- Mast ---
        app.stroke(70, 48, 28);
        app.strokeWeight(3.0f);
        app.line(0.0f, 0.0f, 0.0f, 0.0f, -m_mastHeight, 0.0f);
        app.noStroke();

        // --- Sail (simple triangle) ---
        app.fill(245, 245, 235, 235);
        app.triangle(0.0f, -m_mastHeight,
                     0.0f, -m_mastHeight * 0.08f,
                     m_hullRadius * 1.05f, -m_mastHeight * 0.5f);

        app.popMatrix();
        app.noStroke();
    }

    int getScore() { return m_score; }
    Point3D getPosition() { return m_position; }
    float getRadius() { return m_radius; }
}

// Purely visual launcher standing on the plain, centered on the
// projectile spawn point (0,0,0). Does not affect spawn origin,
// physics or aiming in any way — display only, built from plain boxes.
class Cannon {
    void draw(processing.core.PApplet app) {
        app.noStroke();

        // Support pillar linking the firing point down to the ground
        float pillarHeight = GraphicsConstants.floorY;
        app.fill(65, 65, 72);
        app.pushMatrix();
        app.translate(0.0f, pillarHeight * 0.5f +100, 0.0f);
        app.box(50.0f, pillarHeight -150, 50.0f);
        app.popMatrix();

        // Base plate resting on the plain
        app.fill(50, 50, 58);
        app.pushMatrix();
        app.translate(0.0f, GraphicsConstants.floorY - 6.0f, 0.0f);
        app.box(110.0f, 12.0f, 110.0f);
        app.popMatrix();

        // Turret body, at the projectiles' firing height
        app.fill(95, 100, 112);
        app.pushMatrix();
        app.translate(0.0f, 150.0f, 0.0f);
        app.box(70.0f, 55.0f, 70.0f);
        app.popMatrix();

        // Barrel, pointing toward the water/boats (+Z)
        app.fill(40, 40, 46);
        app.pushMatrix();
        app.translate(0.0f, 150.0f, 55.0f);
        app.box(24.0f, 24.0f, 90.0f);
        app.popMatrix();
    }
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

        Point3D origin = new Point3D(0.0f, -150.0f, 0.0f);
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
