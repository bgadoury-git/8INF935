// ==========================================
// Physics Engine & Particle Classes
// ==========================================
// Add to the top of your global scope or as a nested enum
enum IntegrationMode {
    VelocityVerlet, Euler, PositionVerlet
}

class Particle {
    private Point3D m_position;
    private Vector3D m_velocity;
    private Vector3D m_acceleration;
    private float m_inverseMass;
    private float m_linearDamping;
    private boolean m_affectedByGravity;
    
    // --- NEW STATE FOR POSITION VERLET ---
    private Point3D m_previousPosition;
    private boolean m_firstVerletStep = true;

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
        m_previousPosition = new Point3D(pos.getX(), pos.getY(), pos.getZ());
        
        if (m_affectedByGravity) {
            m_acceleration = m_acceleration.add(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f));
        }
    }

    Point3D getPosition() { return m_position; }
    void setPosition(Point3D newPosition) { m_position = newPosition; }
    
    Vector3D getVelocity() { return m_velocity; }
    void setVelocity(Vector3D newVelocity) { m_velocity = newVelocity; }
    
    Vector3D getAcceleration() { return m_acceleration; }
    void setAcceleration(Vector3D newAcceleration) { m_acceleration = newAcceleration; }
    
    Vector3D getTotalAcceleration() { return computeAcceleration(); }
    
    float getMass() { return m_inverseMass > 0.0f ? 1.0f / m_inverseMass : 0.0f; }
    void setMass(float mass) { m_inverseMass = (mass > 0.0f) ? (1.0f / mass) : 0.0f; }
    
    float getInverseMass() { return m_inverseMass; }
    void setInverseMass(float inverseMass) { m_inverseMass = inverseMass; }
    
    float getLinearDamping() { return m_linearDamping; }
    void setLinearDamping(float damping) { m_linearDamping = damping; }
    
    boolean getAffectedByGravity() { return m_affectedByGravity; }
    void setAffectedByGravity(boolean affected) { m_affectedByGravity = affected; }

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
    
    // --- NEW EULER INTEGRATION ---
    void integrateEuler(float deltaTime) {
        if (m_inverseMass <= 0.0f) return;
        Vector3D a = computeAcceleration();

        // p <- p + v*t (In-place to avoid GC)
        m_position.setX(m_position.getX() + m_velocity.getX() * deltaTime);
        m_position.setY(m_position.getY() + m_velocity.getY() * deltaTime);
        m_position.setZ(m_position.getZ() + m_velocity.getZ() * deltaTime);

        // v <- v + a*t
        m_velocity.setX(m_velocity.getX() + a.getX() * deltaTime);
        m_velocity.setY(m_velocity.getY() + a.getY() * deltaTime);
        m_velocity.setZ(m_velocity.getZ() + a.getZ() * deltaTime);

        // v <- v * d^t (frame-rate independent damping)
        float factor = (float)Math.pow(m_linearDamping, deltaTime);
        m_velocity.setX(m_velocity.getX() * factor);
        m_velocity.setY(m_velocity.getY() * factor);
        m_velocity.setZ(m_velocity.getZ() * factor);
    }

    // --- NEW POSITION VERLET INTEGRATION ---
    void integrateVerlet(float deltaTime) {
        if (m_inverseMass <= 0.0f) return;
        Vector3D a = computeAcceleration();
        float factor = (float)Math.pow(m_linearDamping, deltaTime);
        
        float dispX, dispY, dispZ;

        if (m_firstVerletStep) {
            dispX = m_velocity.getX() * deltaTime * factor;
            dispY = m_velocity.getY() * deltaTime * factor;
            dispZ = m_velocity.getZ() * deltaTime * factor;
            a = new Vector3D(a.getX() * 0.5f, a.getY() * 0.5f, a.getZ() * 0.5f);
            m_firstVerletStep = false;
        } else {
            dispX = (m_position.getX() - m_previousPosition.getX()) * factor;
            dispY = (m_position.getY() - m_previousPosition.getY()) * factor;
            dispZ = (m_position.getZ() - m_previousPosition.getZ()) * factor;
        }

        m_previousPosition = new Point3D(m_position.getX(), m_position.getY(), m_position.getZ());

        float tSq = deltaTime * deltaTime;
        m_position.setX(m_position.getX() + dispX + a.getX() * tSq);
        m_position.setY(m_position.getY() + dispY + a.getY() * tSq);
        m_position.setZ(m_position.getZ() + dispZ + a.getZ() * tSq);

        m_velocity.setX((m_position.getX() - m_previousPosition.getX()) / deltaTime);
        m_velocity.setY((m_position.getY() - m_previousPosition.getY()) / deltaTime);
        m_velocity.setZ((m_position.getZ() - m_previousPosition.getZ()) / deltaTime);
    }

    // --- NEW MASTER INTEGRATION ROUTER ---
    void integrate(float t, IntegrationMode mode) {
        switch(mode) {
            case VelocityVerlet: applyVerletIntegration(t); break;
            case Euler:          integrateEuler(t); break;
            case PositionVerlet: integrateVerlet(t); break;
        }
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
