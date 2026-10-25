// ==========================================
// Physics Engine & Particle Classes
// ==========================================
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
    
    private Point3D m_previousPosition;
    private boolean m_firstVerletStep = true;
    
    private Material m_material = Material.STEEL;
    
    private Vector3D m_forceAccum = new Vector3D();
    private Vector3D m_lastAcceleration = new Vector3D();

    void addForce(Vector3D force) {
        m_forceAccum.setX(m_forceAccum.getX() + force.getX());
        m_forceAccum.setY(m_forceAccum.getY() + force.getY());
        m_forceAccum.setZ(m_forceAccum.getZ() + force.getZ());
    }

    void clearAccumulator() {
        m_forceAccum.setX(0.0f);
        m_forceAccum.setY(0.0f);
        m_forceAccum.setZ(0.0f);
    }

    Vector3D getForceAccumulator() { return m_forceAccum; }

    boolean hasFiniteMass() { return m_inverseMass > 0.0f; }

    Vector3D computeAcceleration() {
        if (m_inverseMass <= 0.0f) {
            return new Vector3D();
        }
        return m_acceleration.add(m_forceAccum.mult(m_inverseMass));
    }
    
    Vector3D getAppliedForce() {
        if (m_inverseMass <= 0.0f) return new Vector3D();
        return new Vector3D(
            m_forceAccum.getX() + m_acceleration.getX() * getMass(),
            m_forceAccum.getY() + m_acceleration.getY() * getMass(),
            m_forceAccum.getZ() + m_acceleration.getZ() * getMass()
        );
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
    void setVelocity(Vector3D newVelocity) {
        m_velocity = newVelocity; 
        if (m_previousPosition != null && m_position != null) {
            m_previousPosition.setX(m_position.getX() - newVelocity.getX() * PhysicsConstants.FIXED_TIMESTEP);
            m_previousPosition.setY(m_position.getY() - newVelocity.getY() * PhysicsConstants.FIXED_TIMESTEP);
            m_previousPosition.setZ(m_position.getZ() - newVelocity.getZ() * PhysicsConstants.FIXED_TIMESTEP);
        }
    }
    
    Vector3D getAcceleration() { return m_acceleration; }
    void setAcceleration(Vector3D newAcceleration) { m_acceleration = newAcceleration; }
    
    Vector3D getTotalAcceleration() { return computeAcceleration(); }
    Vector3D getLastAcceleration() { return new Vector3D(m_lastAcceleration.getX(), m_lastAcceleration.getY(), m_lastAcceleration.getZ()); }
    
    float getMass() { return m_inverseMass > 0.0f ? 1.0f / m_inverseMass : 0.0f; }
    void setMass(float mass) { m_inverseMass = (mass > 0.0f) ? (1.0f / mass) : 0.0f; }
    
    float getInverseMass() { return m_inverseMass; }
    void setInverseMass(float inverseMass) { m_inverseMass = inverseMass; }
    
    float getLinearDamping() { return m_linearDamping; }
    void setLinearDamping(float damping) { m_linearDamping = damping; }
    
    boolean getAffectedByGravity() { return m_affectedByGravity; }
    void setAffectedByGravity(boolean affected) { m_affectedByGravity = affected; }
    
    Material getMaterial() { return m_material; }
    void setMaterial(Material material) { m_material = material; }

    void applyImpulse(Vector3D impulse) {
        if (m_inverseMass <= 0.0f) return;
        setVelocity(m_velocity.add(impulse.mult(m_inverseMass)));
    }

    void applyVerletIntegration(float deltaTime) {
        if (m_inverseMass <= 0.0f) return;
        Vector3D a = computeAcceleration();

        float halfDtSq = 0.5f * deltaTime * deltaTime;
        m_position.setX(m_position.getX() + m_velocity.getX() * deltaTime + a.getX() * halfDtSq);
        m_position.setY(m_position.getY() + m_velocity.getY() * deltaTime + a.getY() * halfDtSq);
        m_position.setZ(m_position.getZ() + m_velocity.getZ() * deltaTime + a.getZ() * halfDtSq);

        Vector3D newAcceleration = computeAcceleration(); 
        float halfDt = 0.5f * deltaTime;
        m_velocity.setX(m_velocity.getX() + (a.getX() + newAcceleration.getX()) * halfDt);
        m_velocity.setY(m_velocity.getY() + (a.getY() + newAcceleration.getY()) * halfDt);
        m_velocity.setZ(m_velocity.getZ() + (a.getZ() + newAcceleration.getZ()) * halfDt);

        float dampingFactor = (float)Math.pow(m_linearDamping, deltaTime);
        m_velocity.setX(m_velocity.getX() * dampingFactor);
        m_velocity.setY(m_velocity.getY() * dampingFactor);
        m_velocity.setZ(m_velocity.getZ() * dampingFactor);
    }
    
    void integrateEuler(float deltaTime) {
        if (m_inverseMass <= 0.0f) return;
        Vector3D a = computeAcceleration();

        m_position.setX(m_position.getX() + m_velocity.getX() * deltaTime);
        m_position.setY(m_position.getY() + m_velocity.getY() * deltaTime);
        m_position.setZ(m_position.getZ() + m_velocity.getZ() * deltaTime);

        m_velocity.setX(m_velocity.getX() + a.getX() * deltaTime);
        m_velocity.setY(m_velocity.getY() + a.getY() * deltaTime);
        m_velocity.setZ(m_velocity.getZ() + a.getZ() * deltaTime);

        float factor = (float)Math.pow(m_linearDamping, deltaTime);
        m_velocity.setX(m_velocity.getX() * factor);
        m_velocity.setY(m_velocity.getY() * factor);
        m_velocity.setZ(m_velocity.getZ() * factor);
    }

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

    void integrate(float t, IntegrationMode mode) {
        switch(mode) {
            case VelocityVerlet: applyVerletIntegration(t); break;
            case Euler:          integrateEuler(t); break;
            case PositionVerlet: integrateVerlet(t); break;
        }
        
        // Essential for Force Debug Render
        m_lastAcceleration = computeAcceleration(); 
        clearAccumulator();
    }

    void draw() {
        println("Drawing Particle at position: " + m_position);
    }
    float getRadius() { return 1.0f; }
    void moveSilently(Vector3D offset) {
        m_position = m_position.add(offset);
        if (m_previousPosition != null) {
            m_previousPosition = m_previousPosition.add(offset);
        }
    }
}
