// ==========================================
// Integration: modes, one physics substep, shared translation integrator
// ==========================================

// The three integrators available for rigid bodies (and their gravityCenter particle).
//  - SemiImplicitEuler: v first, then x with the NEW v (symplectic, stable).
//  - PositionVerlet:    x_{n+1} = x_n + (x_n - x_{n-1}) + a dt². Velocity is implicit and lives
//                       "at the half step". Algebraically the same scheme as SemiImplicitEuler with
//                       a velocity shifted by half a step (only the first step and the damping differ).
//  - VelocityVerlet:    kick-drift-kick. Forces are re-evaluated AFTER the drift, at the new
//                       position (hence the two-half loop below).
enum IntegrationMode {
    SemiImplicitEuler, PositionVerlet, VelocityVerlet
}

IntegrationMode nextIntegrationMode(IntegrationMode mode) {
    IntegrationMode[] all = IntegrationMode.values();
    return all[(mode.ordinal() + 1) % all.length];
}

// ------------------------------------------
// One physics substep for a set of rigid bodies.
// cmt
//   1. preForce : (VV only) half-kick with the previous step's acceleration + drift
//   2. forces   : all generators, evaluated at the CURRENT position / orientation
//   3. postForce: integration (Euler / Verlet) or second half-kick (VV), then clear accumulators
// cmt
// Forces are still evaluated only ONCE per step, as in phase 2: we only moved that evaluation
// after the drift. In phase 2, Velocity Verlet re-read the same accumulator after the drift
// (a_{n+1} = a_n), so it degenerated as soon as the force depended on position (spring).
// ------------------------------------------
void integrateStep(ArrayList<RigidBody> bodies, ForceRegistry registry, float dt, IntegrationMode mode) {
    for (RigidBody b : bodies) b.preForce(dt, mode);
    registry.updateForces(dt);
    for (RigidBody b : bodies) b.postForce(dt, mode);
}

// ==========================================
// LinearMotion: state and integration of the TRANSLATION
// ------------------------------------------
// Owned by Particle; a RigidBody uses it through its gravityCenter particle.
// Cleanliness rule: every mode keeps the WHOLE state up to date (velocity AND previousPosition),
// so the mode can be switched (key [I]) at any step without a jump.
// ==========================================
class LinearMotion {
    Point3D position;          // modified in place: callers may keep the reference from getPosition()
    Vector3D velocity;
    Point3D previousPosition;  // x_{n-1} for Position Verlet

    private boolean m_firstVerletStep = true;     // Position Verlet has no history yet
    private boolean m_hasCache = false;           // VV: previous step's acceleration available?
    private Vector3D m_cachedAcceleration = new Vector3D();
    private boolean m_drifted = false;            // VV: preForce already did half-kick + drift
    private IntegrationMode m_lastMode = null;

    LinearMotion(Point3D position, Vector3D velocity) {
        this.position = new Point3D(position.getX(), position.getY(), position.getZ());
        this.velocity = new Vector3D(velocity.getX(), velocity.getY(), velocity.getZ());
        this.previousPosition = new Point3D();
        syncPreviousPosition();
    }

    // x_{n-1} = x_n - v * dt: keeps Position Verlet consistent with the current velocity
    void syncPreviousPosition() {
        float dt = PhysicsConstants.FIXED_TIMESTEP;
        previousPosition.setX(position.getX() - velocity.getX() * dt);
        previousPosition.setY(position.getY() - velocity.getY() * dt);
        previousPosition.setZ(position.getZ() - velocity.getZ() * dt);
    }

    void setPosition(Point3D p) {
        position.setX(p.getX());
        position.setY(p.getY());
        position.setZ(p.getZ());
        syncPreviousPosition(); // teleport: the velocity is kept
    }

    void setVelocity(Vector3D v) {
        velocity.setX(v.getX());
        velocity.setY(v.getY());
        velocity.setZ(v.getZ());
        syncPreviousPosition(); // otherwise Position Verlet would "forget" the new velocity
    }

    // Move without changing the velocity (e.g. penetration correction)
    void translate(Vector3D offset) {
        addTo(position, offset, 1.0f);
        addTo(previousPosition, offset, 1.0f);
    }

    // ---- first half of the step ----
    void preForce(float dt, IntegrationMode mode) {
        if (mode != m_lastMode) {
            m_hasCache = false;   // the cached acceleration comes from another mode: don't trust it
            m_lastMode = mode;
        }
        m_drifted = false;
        if (mode == IntegrationMode.VelocityVerlet && m_hasCache) {
            addTo(velocity, m_cachedAcceleration, 0.5f * dt);   // half-kick: v_{n+1/2}
            copyInto(previousPosition, position);
            addTo(position, velocity, dt);                      // drift: x_{n+1}
            m_drifted = true;
        }
    }

    // ---- second half of the step: a = acceleration computed by THIS step's generators ----
    void postForce(float dt, IntegrationMode mode, Vector3D a, float damping) {
        float factor = (float)Math.pow(damping, dt);   // d^dt: loss per second independent of dt

        switch (mode) {
            case SemiImplicitEuler: {
                addTo(velocity, a, dt);                        // v_{n+1} = v_n + a dt
                scale(velocity, factor);
                copyInto(previousPosition, position);
                addTo(position, velocity, dt);                 // x_{n+1} = x_n + v_{n+1} dt
                break;
            }
            case PositionVerlet: {
                float dispX, dispY, dispZ;
                float accelScale = dt * dt;
                if (m_firstVerletStep) {
                    // no history: displacement v dt + 1/2 a dt²
                    dispX = velocity.getX() * dt * factor;
                    dispY = velocity.getY() * dt * factor;
                    dispZ = velocity.getZ() * dt * factor;
                    accelScale *= 0.5f;
                } else {
                    dispX = (position.getX() - previousPosition.getX()) * factor;
                    dispY = (position.getY() - previousPosition.getY()) * factor;
                    dispZ = (position.getZ() - previousPosition.getZ()) * factor;
                }
                copyInto(previousPosition, position);
                position.setX(position.getX() + dispX + a.getX() * accelScale);
                position.setY(position.getY() + dispY + a.getY() * accelScale);
                position.setZ(position.getZ() + dispZ + a.getZ() * accelScale);
                // implicit velocity ("half-step" velocity)
                velocity.setX((position.getX() - previousPosition.getX()) / dt);
                velocity.setY((position.getY() - previousPosition.getY()) / dt);
                velocity.setZ((position.getZ() - previousPosition.getZ()) / dt);
                break;
            }
            case VelocityVerlet: {
                if (!m_drifted) {
                    // first step (or mode change): no cache.
                    // full kick-drift-kick with a_{n+1} ≈ a_n: exact for a constant force.
                    addTo(velocity, a, 0.5f * dt);
                    copyInto(previousPosition, position);
                    addTo(position, velocity, dt);
                }
                addTo(velocity, a, 0.5f * dt);                 // second half-kick with a_{n+1}
                scale(velocity, factor);
                copyInto(m_cachedAcceleration, a);
                m_hasCache = true;
                m_lastMode = mode;
                break;
            }
        }
        m_drifted = false;
        m_firstVerletStep = false;   // after any step, the history is valid
    }

    // ---- small in-place helpers (Point3D / Vector3D operations return new objects) ----
    private void addTo(Point3D p, Vector3D v, float s) {
        p.setX(p.getX() + v.getX() * s);
        p.setY(p.getY() + v.getY() * s);
        p.setZ(p.getZ() + v.getZ() * s);
    }
    private void addTo(Vector3D target, Vector3D v, float s) {
        target.setX(target.getX() + v.getX() * s);
        target.setY(target.getY() + v.getY() * s);
        target.setZ(target.getZ() + v.getZ() * s);
    }
    private void scale(Vector3D v, float s) {
        v.setX(v.getX() * s);
        v.setY(v.getY() * s);
        v.setZ(v.getZ() * s);
    }
    private void copyInto(Point3D target, Point3D src) {
        target.setX(src.getX()); target.setY(src.getY()); target.setZ(src.getZ());
    }
    private void copyInto(Vector3D target, Vector3D src) {
        target.setX(src.getX()); target.setY(src.getY()); target.setZ(src.getZ());
    }
}
