// ==========================================
// Physics Engine & Particle Classes
// ==========================================
//enum IntegrationMode {
//   VelocityVerlet, Euler, PositionVerlet
//}
// IntegrationMode moved to Integration.pde (modes renamed, Euler -> SemiImplicitEuler)

// The translation integrators (applyVerletIntegration, integrateEuler, integrateVerlet) are
// replaced by LinearMotion (Integration.pde).
// A RigidBody integrates its translation through its gravityCenter particle.

class Particle {
    private LinearMotion m_motion; // position, velocity and x_{n-1}
    private Vector3D m_acceleration;
    private float m_inverseMass;
    private float m_linearDamping;
    private boolean m_affectedByGravity;
    
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

    public Particle() {
        this(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 0.999f, true);
    }

    public Particle(Point3D pos, Vector3D vel, Vector3D accel, float mass, float damping, boolean affectedByGravity) {
        m_motion = new LinearMotion(pos, vel); // copies pos and vel, initializes x_{n-1}
        m_acceleration = accel;
        m_inverseMass = (mass > 0.0f) ? (1.0f / mass) : 0.0f;
        m_linearDamping = damping;
        m_affectedByGravity = affectedByGravity;
        // La gravité n'est PLUS ajoutée ici : elle vient du GravityGenerator (ForceGenerators.pde),
        // enregistré dans le ForceRegistry. L'ajouter aussi ici la comptait deux fois.
    }

    Point3D getPosition() { return m_motion.position; }
    void setPosition(Point3D newPosition) { m_motion.setPosition(newPosition); }

    Vector3D getVelocity() { return m_motion.velocity; }
    void setVelocity(Vector3D newVelocity) {
        m_motion.setVelocity(newVelocity); // also rewrites x_{n-1}, so Position Verlet keeps the new velocity
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
        setVelocity(getVelocity().add(impulse.mult(m_inverseMass)));
    }

    // First half of a substep: only does something in Velocity Verlet (half-kick + drift)
    void preForce(float dt, IntegrationMode mode) {
        if (m_inverseMass <= 0.0f) return;
        m_motion.preForce(dt, mode);
    }

    // Second half of a substep: integrates with the forces of THIS step, then clears the accumulator
    void postForce(float dt, IntegrationMode mode) {
        if (m_inverseMass > 0.0f) {
            m_motion.postForce(dt, mode, computeAcceleration(), m_linearDamping);
        }

        // Essential for Force Debug Render
        m_lastAcceleration = computeAcceleration();
        clearAccumulator();
    }

    // Full step when the forces are already in the accumulator (tests).
    // In Velocity Verlet the forces are NOT re-evaluated after the drift here:
    // the simulation uses integrateStep() (Integration.pde).
    void integrate(float t, IntegrationMode mode) {
        preForce(t, mode);
        postForce(t, mode);
    }

    void draw() {
        println("Drawing Particle at position: " + getPosition());
    }
    float getRadius() { return 1.0f; }
    void moveSilently(Vector3D offset) {
        m_motion.translate(offset); // moves x and x_{n-1} together (velocity unchanged)
    }
}
