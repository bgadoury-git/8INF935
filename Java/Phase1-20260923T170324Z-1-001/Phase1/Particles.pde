// ==========================================
// Physics Engine & Particle Classes
// ==========================================

class Particle {
    private Point3D m_position;
    private Vector3D m_velocity;
    private Vector3D m_acceleration;
    private float m_inverseMass;
    private float m_linearDamping;
    private boolean m_affectedByGravity;

    Vector3D computeAcceleration() {
        if (m_inverseMass <= 0.0f) {
            return new Vector3D();
        }
        return m_acceleration;
    }

    public Particle() {
        this(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 0.999f, true);
    }

    public Particle(Point3D pos, Vector3D vel, Vector3D accel, float mass, float damping, boolean affectedByGravity) {
        m_position = pos;
        m_velocity = vel;
        m_acceleration = accel;
        m_inverseMass = (mass > 0.0f) ? (1.0f / mass) : 0.0f;
        m_linearDamping = damping;
        m_affectedByGravity = affectedByGravity;
        
        if (m_affectedByGravity) {
            m_acceleration = m_acceleration.add(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f));
        }
    }

    Point3D getPosition() { return m_position; }
    void setPosition(Point3D newPosition) { m_position = newPosition; }
    Vector3D getVelocity() { return m_velocity; }
    void setVelocity(Vector3D newVelocity) { m_velocity = newVelocity; }
    Vector3D getAcceleration() { return m_acceleration; }
    Vector3D getTotalAcceleration() { return computeAcceleration(); }
    float getMass() { return m_inverseMass > 0.0f ? 1.0f / m_inverseMass : 0.0f; }
    float getInverseMass() { return m_inverseMass; }
    float getLinearDamping() { return m_linearDamping; }
    boolean getAffectedByGravity() { return m_affectedByGravity; }

    void applyVerletIntegration(float deltaTime) {
        if (m_inverseMass <= 0.0f) return;

        // 1. Drift (In-place mutation to avoid heap allocation)
        float halfDtSq = 0.5f * deltaTime * deltaTime;
        m_position.setX(m_position.getX() + m_velocity.getX() * deltaTime + m_acceleration.getX() * halfDtSq);
        m_position.setY(m_position.getY() + m_velocity.getY() * deltaTime + m_acceleration.getY() * halfDtSq);
        m_position.setZ(m_position.getZ() + m_velocity.getZ() * deltaTime + m_acceleration.getZ() * halfDtSq);

        Vector3D newAcceleration = computeAcceleration(); 

        // 2. Kick
        float halfDt = 0.5f * deltaTime;
        m_velocity.setX(m_velocity.getX() + (m_acceleration.getX() + newAcceleration.getX()) * halfDt);
        m_velocity.setY(m_velocity.getY() + (m_acceleration.getY() + newAcceleration.getY()) * halfDt);
        m_velocity.setZ(m_velocity.getZ() + (m_acceleration.getZ() + newAcceleration.getZ()) * halfDt);

        // 3. Time-corrected damping
        float dampingFactor = (float)Math.pow(m_linearDamping, deltaTime);
        m_velocity.setX(m_velocity.getX() * dampingFactor);
        m_velocity.setY(m_velocity.getY() * dampingFactor);
        m_velocity.setZ(m_velocity.getZ() * dampingFactor);
        
        // (Acceleration is updated safely by reference in Java)
    }

    void draw() {
        println("Drawing Particle at position: " + m_position);
    }

    ArrayList<Point3D> getTrajectory(int precision, float Time) {
        if (precision <= 4) { precision = 4; }
        ArrayList<Point3D> m_trajectory = new ArrayList<Point3D>();

        float timeStep = Time / (float)precision;
        Vector3D accel = computeAcceleration();
        Point3D currentPos = m_position;
        Vector3D currentVel = m_velocity;
        float dampingFactor = (float)Math.pow(m_linearDamping, timeStep);

        m_trajectory.add(currentPos);

        for (int i = 0; i < precision; ++i) {
            currentPos = currentPos.add(currentVel.mult(timeStep)).add(accel.mult(0.5f * timeStep * timeStep));
            currentVel = currentVel.add(accel.mult(timeStep));
            currentVel = currentVel.mult(dampingFactor);

            m_trajectory.add(currentPos);
        }

        return m_trajectory;
    }
}

class Ball extends Particle {
    public static final float baseSpeed = 150.0f;
    public static final boolean defaultGravityState = true;

    public Ball(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
    }

    @Override
    void draw() {
        Point3D pos = getPosition();
        Vector3D vel = getVelocity();

        Vector3D dir = vel.normalized();
        float time = millis() * 0.006f;

        pushMatrix();

        // 1. Smoke
        int puffCount = 6;
        for (int i = 1; i <= puffCount; ++i) {
            float lag = i * 16.0f;
            float wobbleX = sin(time * 4.0f + i * 1.5f) * (i * 2.2f);
            float wobbleY = cos(time * 3.5f + i * 2.0f) * (i * 2.2f);

            pushMatrix();
            translate(
                pos.getX() - dir.getX() * lag + wobbleX,
                -(pos.getY() - dir.getY() * lag) + wobbleY,
                pos.getZ() - dir.getZ() * lag
            );
            noStroke();
            int grayVal = 40 + i * 14;
            fill(grayVal, grayVal, grayVal, max(20, 160 - i * 24));
            sphere(10.0f + i * 2.4f);
            popMatrix();
        }

        // Embers
        for (int k = 1; k <= 3; ++k) {
            float sparkLag = k * 9.0f;
            float sx = sin(time * 18.0f + k * 2.7f) * 6.0f;
            float sy = cos(time * 14.0f + k * 3.1f) * 6.0f;

            pushMatrix();
            translate(
                pos.getX() - dir.getX() * sparkLag + sx,
                -(pos.getY() - dir.getY() * sparkLag) + sy,
                pos.getZ() - dir.getZ() * sparkLag
            );
            fill(255, 170, 30, 240);
            emissive(255, 120, 0);
            sphere(2.2f);
            popMatrix();
        }

        // 2. Cast-Iron Core
        translate(pos.getX(), -pos.getY(), pos.getZ());
        noStroke();
        fill(42, 45, 50);
        specular(180, 190, 205);
        shininess(8.0f);
        sphere(24.0f);

        // 3. Fuse
        float fuseX = -dir.getX() * 12.0f;
        float fuseY = 16.0f;
        float fuseZ = -dir.getZ() * 12.0f;

        pushMatrix();
        translate(fuseX, -fuseY, fuseZ);
        fill(255, 230, 150, 255);
        emissive(255, 160, 20);
        sphere(3.5f + sin(time * 25.0f) * 1.0f);
        popMatrix();

        specular(0, 0, 0);
        emissive(0, 0, 0);
        popMatrix();
    }
}

class Bullet extends Particle {
    public static final float baseSpeed = 500.0f;
    public static final boolean defaultGravityState = true;

    public Bullet(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
    }
 
    @Override
    void draw() {
        Point3D pos = getPosition();
        Vector3D vel = getVelocity();
        Vector3D dir = vel.normalized();

        Vector3D arbitraryUp = new Vector3D(0.0f, 1.0f, 0.0f);
        if (Math.abs(dir.getY()) > 0.95f) {
            arbitraryUp = new Vector3D(1.0f, 0.0f, 0.0f);
        }

        Vector3D side = new Vector3D(
            dir.getY() * arbitraryUp.getZ() - dir.getZ() * arbitraryUp.getY(),
            dir.getZ() * arbitraryUp.getX() - dir.getX() * arbitraryUp.getZ(),
            dir.getX() * arbitraryUp.getY() - dir.getY() * arbitraryUp.getX()
        ).normalized();

        Vector3D up = new Vector3D(
            side.getY() * dir.getZ() - side.getZ() * dir.getY(),
            side.getZ() * dir.getX() - side.getX() * dir.getZ(),
            side.getX() * dir.getY() - side.getY() * dir.getX()
        ).normalized();

        pushMatrix();

        // 1. Tracer Streak
        final float streakLength = 70.0f;
        Point3D tail = new Point3D(
            pos.getX() - dir.getX() * streakLength,
            pos.getY() - dir.getY() * streakLength,
            pos.getZ() - dir.getZ() * streakLength
        );

        stroke(255, 140, 30, 90);
        strokeWeight(10.0f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        stroke(255, 210, 60, 200);
        strokeWeight(4.5f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        stroke(255, 255, 240, 255);
        strokeWeight(1.8f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        // 2. Shock Cones
        final int ringCount = 3;
        final int ringSegments = 16;
        final float ringSpacing = 18.0f;

        for (int r = 1; r <= ringCount; ++r) {
            float lag = r * ringSpacing;
            float radius = 3.5f + r * 4.0f;

            float cx = pos.getX() - dir.getX() * lag;
            float cy = -(pos.getY() - dir.getY() * lag);
            float cz = pos.getZ() - dir.getZ() * lag;

            stroke(255, 180, 50, 160 - r * 45);
            strokeWeight(1.5f);
            noFill();

            beginShape();
            for (int i = 0; i <= ringSegments; ++i) {
                float theta = ((float)i / ringSegments) * 6.2831853f;
                float ox = (side.getX() * cos(theta) + up.getX() * sin(theta)) * radius;
                float oy = -(side.getY() * cos(theta) + up.getY() * sin(theta)) * radius;
                float oz = (side.getZ() * cos(theta) + up.getZ() * sin(theta)) * radius;

                vertex(cx + ox, cy + oy, cz + oz);
            }
            endShape();
        }

        // 3. Projectile Head
        noStroke();
        translate(pos.getX(), -pos.getY(), pos.getZ());

        fill(255, 110, 0, 95);
        emissive(230, 80, 0);
        sphere(7.5f);

        fill(255, 175, 45, 230);
        emissive(255, 120, 20);
        sphere(4.8f);

        fill(255, 255, 230, 255);
        emissive(255, 240, 180);
        sphere(2.4f);

        emissive(0, 0, 0);
        popMatrix();
        noStroke();
    }
}

class Confetti extends Particle {
    public static final float baseSpeed = 50.0f;
    public static final boolean defaultGravityState = true;

    boolean isActive = false;
    int colorIndex = 0;

    public Confetti() {
        this(new Point3D(), new Vector3D());
    }

    public Confetti(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
        colorIndex = ThreadLocalRandom.current().nextInt(6);
    }

    @Override
    void draw() {
        Point3D head = getPosition();
        Vector3D vel = getVelocity();

        final float tailTime = 0.035f;
        Point3D tail = new Point3D(
            head.getX() - vel.getX() * tailTime,
            head.getY() - vel.getY() * tailTime,
            head.getZ() - vel.getZ() * tailTime
        );

        int r = (int)random(255);
        int g = (int)random(255);
        int b = (int)random(255);

        stroke(r, g, b, 255);
        strokeWeight(2.5f);
        line(tail.getX(), -tail.getY(), tail.getZ(),
             head.getX(), -head.getY(), head.getZ());
        noStroke();
    }
}

class Fireball extends Particle {
    public static final float baseSpeed = 250.0f;
    public static final boolean defaultGravityState = true;

    public Fireball(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
    }

    @Override
    void draw() {
        Point3D pos = getPosition();
        Vector3D vel = getVelocity();
        Vector3D dir = vel.normalized();

        float t = millis() * 0.007f;
        float corePulse = sin(t * 7.0f) * 3.5f;
        float outerPulse = sin(t * 11.0f + 1.2f) * 6.0f;

        pushMatrix();
        noStroke();

        // 1. Wake
        final int trailSegments = 9;
        for (int i = 1; i <= trailSegments; ++i) {
            float lag = i * 14.0f;
            float angle = t * 9.0f + i * 1.1f;
            float radius = 5.0f + i * 2.8f;
            float swirlX = cos(angle) * radius;
            float swirlY = sin(angle * 1.3f) * radius;

            pushMatrix();
            translate(
                pos.getX() - dir.getX() * lag + swirlX,
                -(pos.getY() - dir.getY() * lag) + swirlY,
                pos.getZ() - dir.getZ() * lag
            );

            int r = 255;
            int g = max(0, 150 - i * 16);
            int b = 0;
            int alpha = max(15, 170 - i * 18);

            fill(r, g, b, alpha);
            emissive(r / 2.0f, g / 3.0f, 0);
            sphere(16.0f - i * 1.1f + sin(t * 12.0f + i) * 2.0f);
            popMatrix();
        }

        // 2. Main Body
        translate(pos.getX(), -pos.getY(), pos.getZ());

        for (int j = 0; j < 4; ++j) {
            float jetAngle = t * 13.0f + j * 1.57f;
            float jx = cos(jetAngle) * (8.0f + outerPulse * 0.3f);
            float jy = sin(jetAngle * 0.8f) * (8.0f + outerPulse * 0.3f);
            float jz = sin(jetAngle * 1.5f) * 6.0f;

            pushMatrix();
            translate(jx, jy, jz);
            fill(255, 60, 0, 75);
            emissive(230, 40, 0);
            sphere(14.0f + cos(t * 10.0f + j) * 3.0f);
            popMatrix();
        }

        fill(255, 45, 0, 55);
        emissive(220, 30, 0);
        sphere(34.0f + outerPulse);

        fill(255, 100, 0, 140);
        emissive(245, 90, 0);
        sphere(24.0f + corePulse);

        fill(255, 195, 20, 210);
        emissive(255, 180, 20);
        sphere(16.0f + corePulse * 0.5f);

        fill(255, 255, 220, 255);
        emissive(255, 255, 200);
        sphere(8.5f);

        emissive(0, 0, 0);
        popMatrix();
    }
}

class Laser extends Particle {
    public static final float baseSpeed = 5000.0f;
    public static final boolean defaultGravityState = false;

    public Laser(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
    }

    @Override
    void draw() {
        Point3D pos = getPosition();
        Vector3D vel = getVelocity();
        Vector3D dir = vel.normalized();

        Vector3D arbitraryUp = new Vector3D(0.0f, 1.0f, 0.0f);
        if (Math.abs(dir.getY()) > 0.95f) {
            arbitraryUp = new Vector3D(1.0f, 0.0f, 0.0f);
        }

        Vector3D side = new Vector3D(
            dir.getY() * arbitraryUp.getZ() - dir.getZ() * arbitraryUp.getY(),
            dir.getZ() * arbitraryUp.getX() - dir.getX() * arbitraryUp.getZ(),
            dir.getX() * arbitraryUp.getY() - dir.getY() * arbitraryUp.getX()
        ).normalized();

        Vector3D normal = new Vector3D(
            side.getY() * dir.getZ() - side.getZ() * dir.getY(),
            side.getZ() * dir.getX() - side.getX() * dir.getZ(),
            side.getX() * dir.getY() - side.getY() * dir.getX()
        ).normalized();

        float time = millis() * 0.008f;
        final float totalLength = 160.0f;
        final int samples = 28;
        final float step = totalLength / (float)samples;

        pushMatrix();

        Point3D tail = new Point3D(
            pos.getX() - dir.getX() * totalLength,
            pos.getY() - dir.getY() * totalLength,
            pos.getZ() - dir.getZ() * totalLength
        );

        stroke(30, 255, 90, 80);
        strokeWeight(9.0f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        stroke(60, 255, 120, 200);
        strokeWeight(4.5f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        stroke(225, 255, 235, 255);
        strokeWeight(1.8f);
        line(tail.getX(), -tail.getY(), tail.getZ(), pos.getX(), -pos.getY(), pos.getZ());

        stroke(0, 255, 140, 190);
        strokeWeight(2.2f);
        noFill();

        beginShape();
        for (int i = 0; i <= samples; ++i) {
            float d = (float)i * step;
            float progress = 1.0f - (d / totalLength);
            float wavePhase = time * 12.0f - d * 0.08f;
            float waveAmp = 5.0f * progress;

            float offX = (side.getX() * sin(wavePhase) + normal.getX() * cos(wavePhase)) * waveAmp;
            float offY = (side.getY() * sin(wavePhase) + normal.getY() * cos(wavePhase)) * waveAmp;
            float offZ = (side.getZ() * sin(wavePhase) + normal.getZ() * cos(wavePhase)) * waveAmp;

            vertex(
                pos.getX() - dir.getX() * d + offX,
                -(pos.getY() - dir.getY() * d + offY),
                pos.getZ() - dir.getZ() * d + offZ
            );
        }
        endShape();

        stroke(140, 255, 200, 160);
        strokeWeight(1.5f);

        beginShape();
        for (int i = 0; i <= samples; ++i) {
            float d = (float)i * step;
            float progress = 1.0f - (d / totalLength);
            float wavePhase = time * 12.0f - d * 0.08f + PI;
            float waveAmp = 5.0f * progress;

            float offX = (side.getX() * sin(wavePhase) + normal.getX() * cos(wavePhase)) * waveAmp;
            float offY = (side.getY() * sin(wavePhase) + normal.getY() * cos(wavePhase)) * waveAmp;
            float offZ = (side.getZ() * sin(wavePhase) + normal.getZ() * cos(wavePhase)) * waveAmp;

            vertex(
                pos.getX() - dir.getX() * d + offX,
                -(pos.getY() - dir.getY() * d + offY),
                pos.getZ() - dir.getZ() * d + offZ
            );
        }
        endShape();

        noStroke();
        translate(pos.getX(), -pos.getY(), pos.getZ());

        fill(50, 255, 120, 110);
        emissive(0, 255, 100);
        sphere(4.5f);

        fill(235, 255, 240, 255);
        emissive(180, 255, 200);
        sphere(2.2f);

        emissive(0, 0, 0);
        popMatrix();
        noStroke();
    }
}
