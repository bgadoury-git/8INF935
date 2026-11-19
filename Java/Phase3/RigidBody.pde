// ==========================================
// RigidBody & Derived Body Classes
// ==========================================

class RigidBody {
    private Matrix4 RotationMatrix;
    private Quaternion RotationQuaternion;
    Particle gravityCenter;

    // ---------- rotational dynamics ----------
    private Vector3D m_angularMomentum = new Vector3D();     // L (world)
    private Matrix3 m_inertiaBody;                           // I    (local, constant)
    private Matrix3 m_inverseInertiaBody;                    // I^-1 (local, constant)
    private Matrix3 m_inverseInertiaWorld = new Matrix3();   // derived
    private Vector3D m_angularVelocity = new Vector3D();     // omega, derived
    private float m_angularDamping = 1.0f;
    private Vector3D m_torqueAccum = new Vector3D();
    private Vector3D m_lastAngularAcceleration = new Vector3D();

    // internal state of the angular integration
    private boolean m_firstAngularVerletStep = true;
    private boolean m_hasTorqueCache = false;
    private Vector3D m_cachedTorque = new Vector3D();
    private boolean m_angularDrifted = false;
    private IntegrationMode m_lastAngularMode = null;

    public RigidBody() {
        this.RotationQuaternion = new Quaternion();
        this.gravityCenter = new GravityCenter(new Point3D(), new Vector3D());
        this.RotationMatrix = new Matrix4(RotationQuaternion, gravityCenter.getPosition());
        setInertiaTensor(defaultInertiaTensor()); // PLACEHOLDER until a shape computes its own
    }

    public RigidBody(Point3D position, Quaternion orientation, float mass) {
        this.RotationQuaternion = (orientation != null) ? orientation.normalized() : new Quaternion();
        this.gravityCenter = new GravityCenter(position, new Vector3D());
        this.gravityCenter.setMass(mass);
        this.RotationMatrix = new Matrix4(RotationQuaternion, gravityCenter.getPosition());
        // Placeholder: subclasses replace it in computeGravityCenter(). computeInertiaTensor()
        // cannot be called here: subclass fields are not initialized yet during the parent constructor.
        setInertiaTensor(defaultInertiaTensor());
    }

    // "Bare" body with a given local inertia tensor (tests, demos)
    public RigidBody(Point3D position, Quaternion orientation, float mass, Matrix3 inertiaTensorLocal) {
        this(position, orientation, mass);
        setInertiaTensor(inertiaTensorLocal);
    }

    // --- Getters ---
    Matrix4 getRotationMatrix() {
        updateTransformMatrix();
        return RotationMatrix;
    }

    Quaternion getRotationQuaternion() {
        return RotationQuaternion;
    }

    Particle getGravityCenter() {
        return gravityCenter;
    }

    Point3D getPosition() {
        return gravityCenter.getPosition();
    }

    // --- Setters ---
    void setRotationMatrix(Matrix4 rotationMatrix) {
        this.RotationMatrix = rotationMatrix;
    }

    void setRotationQuaternion(Quaternion rotationQuaternion) {
        this.RotationQuaternion = rotationQuaternion.normalized();
        updateDerivedData();
    }

    void setGravityCenter(Particle gravityCenter) {
        this.gravityCenter = gravityCenter;
        updateTransformMatrix();
    }

    void setPosition(Point3D position) {
        this.gravityCenter.setPosition(position);
        updateTransformMatrix();
    }

    void updateTransformMatrix() {
        if (RotationMatrix == null) {
            RotationMatrix = new Matrix4();
        }
        Point3D pos = (gravityCenter != null) ? gravityCenter.getPosition() : new Point3D();
        Quaternion q = (RotationQuaternion != null) ? RotationQuaternion : new Quaternion();
        RotationMatrix.setOrientationAndPosition(q, pos);
    }

    // Maps a %TotalWeight ratio (relative to uniform share) to a Blue -> Green -> Red gradient
    int weightPercentToColor(float massSharePct, float uniformSharePct, int alpha) {
        int cLow  = color(45, 135, 255, alpha);   // Low %TotalWeight (Blue)
        int cMid  = color(60, 225, 130, alpha);   // Average %TotalWeight (Green)
        int cHigh = color(255, 65, 50, alpha);    // High %TotalWeight (Red-Orange)

        if (uniformSharePct <= 1e-6f) return cMid;
        float ratio = massSharePct / uniformSharePct;

        if (ratio <= 1.0f) {
            float t = constrain(ratio, 0.0f, 1.0f);
            return lerpColor(cLow, cMid, t);
        } else {
            float t = constrain((ratio - 1.0f) / 1.5f, 0.0f, 1.0f);
            return lerpColor(cMid, cHigh, t);
        }
    }

    // --- Virtual Functions ---
    Point3D interceptLine(Point3D a, Point3D b) {
        return null;
    }

    void computeGravityCenter() {
        refreshInertia(); // also calls updateTransformMatrix
    }

    // LOCAL inertia tensor (center of mass = origin of the local frame).
    // Subclasses recompute it from their mass distribution.
    Matrix3 computeInertiaTensor() {
        return new Matrix3(m_inertiaBody);
    }

    void draw() {
        if (gravityCenter != null) {
            gravityCenter.draw();
            drawCenterOfMassBeacon();
        }
    }

    // High-visibility Center of Mass indicator visible through translucent geometry
    void drawCenterOfMassBeacon() {
        Point3D pos = gravityCenter.getPosition();
        hint(DISABLE_DEPTH_TEST);
        pushMatrix();
        translate(pos.getX(), pos.getY(), pos.getZ());

        // Bright core sphere
        noStroke();
        fill(255, 235, 40);
        sphereDetail(16);
        sphere(5.5f);

        // High-contrast 3D crosshair axes
        strokeWeight(2.5f);
        float arm = 14.0f;
        stroke(255, 50, 220);
        line(-arm, 0, 0, arm, 0, 0);
        line(0, -arm, 0, 0, arm, 0);
        line(0, 0, -arm, 0, 0, arm);

        // Outer halo ring
        noFill();
        stroke(255, 235, 40, 210);
        strokeWeight(1.5f);
        ellipse(0, 0, 22.0f, 22.0f);

        popMatrix();
        hint(ENABLE_DEPTH_TEST);
    }

    // ==================================================================
    // Dynamics (phase 3 integrator)
    // ==================================================================

    // ---------- Inertia tensor ----------

    // Solid sphere of radius 1: PLACEHOLDER until the shape computes its own tensor
    Matrix3 defaultInertiaTensor() {
        float i = 0.4f * gravityCenter.getMass();
        Matrix3 m = new Matrix3();
        m.setDiagonal(i, i, i);
        return m;
    }

    // Recompute the tensor from the current mass distribution (shape changed, etc.)
    void refreshInertia() {
        setInertiaTensor(computeInertiaTensor());
    }

    void setInertiaTensor(Matrix3 inertiaLocal) {
        if (!hasFiniteMass()) {
            m_inertiaBody = zeroMatrix3();
            m_inverseInertiaBody = zeroMatrix3();
        } else {
            float meanDiag = (inertiaLocal.get(0, 0) + inertiaLocal.get(1, 1) + inertiaLocal.get(2, 2)) / 3.0f;
            float det = inertiaLocal.determinant();
            if (meanDiag <= 0.0f || Math.abs(det) < 1e-6f * meanDiag * meanDiag * meanDiag) {
                // Degenerate distribution (aligned masses...): the tensor cannot be inverted.
                // Use an isotropic tensor of the same "size" so the simulation keeps running.
                println("RigidBody: singular inertia tensor, isotropic fallback used");
                float i = (meanDiag > 0.0f) ? meanDiag : 0.4f * getMass();
                inertiaLocal = new Matrix3();
                inertiaLocal.setDiagonal(i, i, i);
            }
            m_inertiaBody = new Matrix3(inertiaLocal);
            m_inverseInertiaBody = inertiaLocal.inverse();
        }
        updateDerivedData();
    }

    Matrix3 getInertiaTensorLocal() { return new Matrix3(m_inertiaBody); }
    Matrix3 getInertiaTensorWorld() { return m_inertiaBody.changeBasis(new Matrix3(RotationQuaternion)); }
    Matrix3 getInverseInertiaTensorWorld() { return new Matrix3(m_inverseInertiaWorld); }

    private Matrix3 zeroMatrix3() {
        Matrix3 m = new Matrix3();
        m.setDiagonal(0.0f, 0.0f, 0.0f);
        return m;
    }

    // ---------- Derived data: ONE place, fixed order ----------
    void updateDerivedData() {
        RotationQuaternion.normalize();                                     // unit q
        updateTransformMatrix();                                            // Matrix4 (R + position)
        if (m_inverseInertiaBody == null) return;                           // during construction
        Matrix3 rotation = new Matrix3(RotationQuaternion);                 // R
        m_inverseInertiaWorld = m_inverseInertiaBody.changeBasis(rotation); // R I^-1 R^T
        refreshAngularVelocity();                                           // omega = I^-1_world L
    }

    private void refreshAngularVelocity() {
        m_angularVelocity = m_inverseInertiaWorld.transform(m_angularMomentum);
    }

    // ---------- Forces and torques ----------

    // Force at the center of mass, no torque
    void addForce(Vector3D force) {
        gravityCenter.addForce(force);
    }

    // Force at a WORLD point
    void addForceAtPoint(Vector3D force, Point3D worldPoint) {
        addForce(force);
        Vector3D r = worldPoint.sub(getPosition());
        addTorque(r.cross(force));
    }

    // Force at a BODY point follows the body's rotation
    void addForceAtBodyPoint(Vector3D force, Point3D localPoint) {
        addForceAtPoint(force, RotationMatrix.transform(localPoint));
    }

    void addTorque(Vector3D torque) {
        m_torqueAccum = m_torqueAccum.add(torque);
    }

    // ---------- Impulses ----------

    // At the center of mass: Δv = J / m
    void applyImpulse(Vector3D impulse) {
        gravityCenter.applyImpulse(impulse);
    }

    // At the point returned by interceptLine: delta_v = J / m and delta_L = r × J
    void applyImpulseAtPoint(Vector3D impulse, Point3D worldPoint) {
        if (!hasFiniteMass()) return;
        applyImpulse(impulse);
        Vector3D r = worldPoint.sub(getPosition());
        applyAngularImpulse(r.cross(impulse));
    }

    void applyAngularImpulse(Vector3D deltaL) {
        if (!hasFiniteMass()) return;
        m_angularMomentum = m_angularMomentum.add(deltaL);
        refreshAngularVelocity();
    }

    // ---------- Integration: first half of the step (Velocity Verlet only) ----------
    void preForce(float dt, IntegrationMode mode) {
        if (!hasFiniteMass()) return;
        gravityCenter.preForce(dt, mode);                 // translation (LinearMotion)

        if (mode != m_lastAngularMode) {
            m_hasTorqueCache = false;
            m_lastAngularMode = mode;
        }
        m_angularDrifted = false;
        if (mode == IntegrationMode.VelocityVerlet && m_hasTorqueCache) {
            addScaled(m_angularMomentum, m_cachedTorque, 0.5f * dt);   // half-kick: L_{n+1/2}
            driftOrientation(dt);                                      // drift: q_{n+1}
            m_angularDrifted = true;
        }
        // force generators must see the UP-TO-DATE transform
        if (mode == IntegrationMode.VelocityVerlet) updateDerivedData();
    }

    // ---------- Integration: second half of the step ----------
    void postForce(float dt, IntegrationMode mode) {
        Vector3D alpha = new Vector3D();
        if (hasFiniteMass()) {
            alpha = m_inverseInertiaWorld.transform(m_torqueAccum);   // a = I^-1 torque (debug)
        }
        // translation: integrates, records the last acceleration, clears the force accumulator
        gravityCenter.postForce(dt, mode);
        if (hasFiniteMass()) {
            integrateAngular(dt, mode);
            updateDerivedData();
        }
        m_lastAngularAcceleration = alpha;
        m_torqueAccum = new Vector3D();
    }

    private void integrateAngular(float dt, IntegrationMode mode) {
        Vector3D torque = m_torqueAccum;
        float factor = (float)Math.pow(m_angularDamping, dt);

        switch (mode) {
            case SemiImplicitEuler: {
                addScaled(m_angularMomentum, torque, dt);          // L_{n+1} = L_n + torque dt
                scale(m_angularMomentum, factor);
                driftOrientation(dt);                             // q_n -> q_{n+1} with L_{n+1}
                break;
            }
            case PositionVerlet: {
                // Like the translation: L "lives at the half step". First step = half-kick only.
                float kick = m_firstAngularVerletStep ? 0.5f * dt : dt;
                addScaled(m_angularMomentum, torque, kick);
                scale(m_angularMomentum, factor);
                driftOrientation(dt);
                break;
            }
            case VelocityVerlet: {
                if (!m_angularDrifted) {
                    // first step (no cache): full kick-drift-kick with torque_{n+1} ≈ torque_n
                    addScaled(m_angularMomentum, torque, 0.5f * dt);
                    driftOrientation(dt);
                }
                addScaled(m_angularMomentum, torque, 0.5f * dt);   // second half-kick
                scale(m_angularMomentum, factor);
                m_cachedTorque = new Vector3D(torque.getX(), torque.getY(), torque.getZ());
                m_hasTorqueCache = true;
                break;
            }
        }
        m_angularDrifted = false;
        m_firstAngularVerletStep = false;
    }

    // Rotate q during dt with L fixed (the angular "drift").

    private void driftOrientation(float dt) {
        refreshAngularVelocity();                                   // omega(q_n)
        Quaternion half = new Quaternion(RotationQuaternion);
        half.addScaledVector(m_angularVelocity, 0.5f * dt);
        half.normalize();
        Vector3D omegaMid = m_inverseInertiaBody.changeBasis(new Matrix3(half)).transform(m_angularMomentum);
        RotationQuaternion.addScaledVector(omegaMid, dt);
        RotationQuaternion.normalize();
        // the "official" omega (I^-1_world(q_{n+1}) L) is recomputed by updateDerivedData()
    }

    // Shortcut for tests (forces already in the accumulators). Simulation: integrateStep().
    void integrate(float dt, IntegrationMode mode) {
        preForce(dt, mode);
        postForce(dt, mode);
    }

    // ---------- Accessors ----------
    Vector3D getVelocity() { return gravityCenter.getVelocity(); }
    void setVelocity(Vector3D v) { gravityCenter.setVelocity(v); }
    float getMass() { return gravityCenter.getMass(); }
    float getInverseMass() { return gravityCenter.getInverseMass(); }
    boolean hasFiniteMass() { return gravityCenter.hasFiniteMass(); }

    Vector3D getAngularMomentum() { return copy(m_angularMomentum); }
    void setAngularMomentum(Vector3D L) {
        if (!hasFiniteMass()) return;
        m_angularMomentum = copy(L);
        refreshAngularVelocity();
    }

    Vector3D getAngularVelocity() { return copy(m_angularVelocity); }
    void setAngularVelocity(Vector3D omega) {
        if (!hasFiniteMass()) return;
        m_angularMomentum = getInertiaTensorWorld().transform(omega);
        refreshAngularVelocity();
    }

    Point3D localToWorld(Point3D local) { return RotationMatrix.transform(local); }
    Point3D worldToLocal(Point3D world) { return RotationMatrix.transformInverse(world); }
    Vector3D localDirectionToWorld(Vector3D local) { return RotationMatrix.transformDirection(local); }

    float getRotationalKineticEnergy() { return 0.5f * m_angularVelocity.dot(m_angularMomentum); }

    float getLinearDamping() { return gravityCenter.getLinearDamping(); }
    void setLinearDamping(float d) { gravityCenter.setLinearDamping(d); }
    float getAngularDamping() { return m_angularDamping; }
    void setAngularDamping(float d) { m_angularDamping = d; }

    Vector3D getForceAccumulator() { return copy(gravityCenter.getForceAccumulator()); }
    Vector3D getTorqueAccumulator() { return copy(m_torqueAccum); }
    Vector3D getLastAcceleration() { return gravityCenter.getLastAcceleration(); }
    Vector3D getLastAngularAcceleration() { return copy(m_lastAngularAcceleration); }

    // ---------- helpers ----------
    private Vector3D copy(Vector3D v) { return new Vector3D(v.getX(), v.getY(), v.getZ()); }
    private void addScaled(Vector3D target, Vector3D v, float s) {
        target.setX(target.getX() + v.getX() * s);
        target.setY(target.getY() + v.getY() * s);
        target.setZ(target.getZ() + v.getZ() * s);
    }
    private void scale(Vector3D v, float s) {
        v.setX(v.getX() * s);
        v.setY(v.getY() * s);
        v.setZ(v.getZ() * s);
    }
}

// ==========================================
// InertiaAccumulator: sum of inertia tensors (ch. 9)
// ------------------------------------------

class InertiaAccumulator {
    float ix, iy, iz;      // moments (diagonal)
    float ixy, ixz, iyz;   // products of inertia (appear with a minus sign off the diagonal)

    void addPointMass(float m, float x, float y, float z) {
        ix += m * (y * y + z * z);
        iy += m * (x * x + z * z);
        iz += m * (x * x + y * y);
        ixy += m * x * y;
        ixz += m * x * z;
        iyz += m * y * z;
    }

    // Own (diagonal) tensor of a continuous piece, around its own center
    void addLocalDiagonal(float jx, float jy, float jz) {
        ix += jx; iy += jy; iz += jz;
    }

    Matrix3 toMatrix() {
        Matrix3 m = new Matrix3();
        m.setInertiaTensorCoeffs(ix, iy, iz, ixy, ixz, iyz);
        return m;
    }
}

// ==========================================
// GeometricBody
// ==========================================
class GeometricBody extends RigidBody {
    Point3D geometricCenter;

    public GeometricBody() {
        super();
        this.geometricCenter = new Point3D();
    }

    public GeometricBody(Point3D position, Quaternion orientation, float mass) {
        super(position, orientation, mass);
        this.geometricCenter = new Point3D();
    }

    Point3D getGeometricCenter() {
        return geometricCenter;
    }

    void setGeometricCenter(Point3D geometricCenter) {
        this.geometricCenter = geometricCenter;
    }

    void massDistribution() {}
}

// ==========================================
// TriangleBody
// ==========================================
class TriangleBody extends GeometricBody {
    float x1, y1, z1;
    float x2, y2, z2;
    float x3, y3, z3;

    float w1 = 1.0f, w2 = 1.0f, w3 = 1.0f;
    float m1, m2, m3;

    public TriangleBody(Point3D position, Quaternion orientation, float totalMass,
                        float x1, float y1, float z1,
                        float x2, float y2, float z2,
                        float x3, float y3, float z3) {
        this(position, orientation, totalMass, x1, y1, z1, x2, y2, z2, x3, y3, z3, 1.0f, 1.0f, 1.0f);
    }

    public TriangleBody(Point3D position, Quaternion orientation, float totalMass,
                        float x1, float y1, float z1,
                        float x2, float y2, float z2,
                        float x3, float y3, float z3,
                        float w1, float w2, float w3) {
        super(position, orientation, totalMass);
        this.x1 = x1; this.y1 = y1; this.z1 = z1;
        this.x2 = x2; this.y2 = y2; this.z2 = z2;
        this.x3 = x3; this.y3 = y3; this.z3 = z3;
        massDistribution(w1, w2, w3);
        computeGravityCenter();
    }

    void massDistribution(float w1, float w2, float w3) {
        this.w1 = Math.max(0.0f, w1);
        this.w2 = Math.max(0.0f, w2);
        this.w3 = Math.max(0.0f, w3);
        massDistribution();
    }

    @Override
    void massDistribution() {
        float totalMass = (gravityCenter != null) ? gravityCenter.getMass() : 0.0f;
        float weightSum = w1 + w2 + w3;
        if (weightSum > 0.0f) {
            m1 = totalMass * (w1 / weightSum);
            m2 = totalMass * (w2 / weightSum);
            m3 = totalMass * (w3 / weightSum);
        } else {
            float third = totalMass / 3.0f;
            m1 = m2 = m3 = third;
        }
    }

    @Override
    void computeGravityCenter() {
        float cx = (x1 + x2 + x3) / 3.0f;
        float cy = (y1 + y2 + y3) / 3.0f;
        float cz = (z1 + z2 + z3) / 3.0f;

        float totalMass = m1 + m2 + m3;
        if (totalMass > 0.0f) {
            float gx = (m1 * x1 + m2 * x2 + m3 * x3) / totalMass;
            float gy = (m1 * y1 + m2 * y2 + m3 * y3) / totalMass;
            float gz = (m1 * z1 + m2 * z2 + m3 * z3) / totalMass;

            x1 -= gx; y1 -= gy; z1 -= gz;
            x2 -= gx; y2 -= gy; z2 -= gz;
            x3 -= gx; y3 -= gy; z3 -= gz;
            geometricCenter = new Point3D(cx - gx, cy - gy, cz - gz);
        } else {
            geometricCenter = new Point3D(cx, cy, cz);
        }
        refreshInertia(); // inertia tensor + transform (was updateTransformMatrix)
    }

    // 3 point masses at the vertices (already centered on the center of mass)
    @Override
    Matrix3 computeInertiaTensor() {
        InertiaAccumulator acc = new InertiaAccumulator();
        acc.addPointMass(m1, x1, y1, z1);
        acc.addPointMass(m2, x2, y2, z2);
        acc.addPointMass(m3, x3, y3, z3);
        return acc.toMatrix();
    }

    @Override
    Point3D interceptLine(Point3D a, Point3D b) {
        updateTransformMatrix();
        Matrix4 transform = getRotationMatrix();
        Point3D localA = transform.transformInverse(a);
        Point3D localB = transform.transformInverse(b);

        Vector3D dir = localB.sub(localA);

        Vector3D v0 = new Vector3D(x1, y1, z1);
        Vector3D v1 = new Vector3D(x2, y2, z2);
        Vector3D v2 = new Vector3D(x3, y3, z3);

        Vector3D edge1 = v1.sub(v0);
        Vector3D edge2 = v2.sub(v0);
        Vector3D h = dir.cross(edge2);
        float det = edge1.dot(h);

        if (Math.abs(det) < 1e-6f) return null;

        float invDet = 1.0f / det;
        Vector3D orig = new Vector3D(localA.getX(), localA.getY(), localA.getZ());
        Vector3D s = orig.sub(v0);
        float u = invDet * s.dot(h);
        if (u < 0.0f || u > 1.0f) return null;

        Vector3D q = s.cross(edge1);
        float v = invDet * dir.dot(q);
        if (v < 0.0f || u + v > 1.0f) return null;

        float t = invDet * edge2.dot(q);
        if (t >= 0.0f && t <= 1.0f) {
            Point3D localHit = localA.add(dir.mult(t));
            return transform.transform(localHit);
        }
        return null;
    }

    @Override
    void draw() {
        updateTransformMatrix();
        float totalMass = (gravityCenter != null && gravityCenter.getMass() > 0.0f)
            ? gravityCenter.getMass() : 1.0f;
        float uniformPct = 1.0f / 3.0f;

        int c1 = weightPercentToColor(m1 / totalMass, uniformPct, 210);
        int c2 = weightPercentToColor(m2 / totalMass, uniformPct, 210);
        int c3 = weightPercentToColor(m3 / totalMass, uniformPct, 210);

        pushMatrix();
        applyMatrix(getRotationMatrix().toPMatrix3D());
        stroke(255, 220);
        strokeWeight(1.5f);
        beginShape(TRIANGLES);
        fill(c1); vertex(x1, y1, z1);
        fill(c2); vertex(x2, y2, z2);
        fill(c3); vertex(x3, y3, z3);
        endShape();
        popMatrix();

        super.draw();
    }
}

// ==========================================
// SquareBody (Rectangular Prism / Box)
// ==========================================
class SquareBody extends GeometricBody {
    float width, height, depth;
    float[] cornerWeights = { 1, 1, 1, 1, 1, 1, 1, 1 };
    float[] cornerMasses = new float[8];

    public SquareBody(Point3D position, Quaternion orientation, float totalMass, float size) {
        this(position, orientation, totalMass, size, size, size);
    }

    public SquareBody(Point3D position, Quaternion orientation, float totalMass,
                      float width, float height, float depth) {
        super(position, orientation, totalMass);
        this.width = width;
        this.height = height;
        this.depth = depth;
        massDistribution();
        computeGravityCenter();
    }

    public SquareBody(Point3D position, Quaternion orientation, float totalMass,
                      float width, float height, float depth, Vector3D massBias) {
        super(position, orientation, totalMass);
        this.width = width;
        this.height = height;
        this.depth = depth;
        massDistribution(massBias);
        computeGravityCenter();
    }

    public SquareBody(Point3D position, Quaternion orientation, float totalMass,
                      float width, float height, float depth, float[] cornerWeights) {
        super(position, orientation, totalMass);
        this.width = width;
        this.height = height;
        this.depth = depth;
        massDistribution(cornerWeights);
        computeGravityCenter();
    }

    void massDistribution(Vector3D bias) {
        float bx = (bias != null) ? bias.getX() : 0.0f;
        float by = (bias != null) ? bias.getY() : 0.0f;
        float bz = (bias != null) ? bias.getZ() : 0.0f;

        for (int i = 0; i < 8; i++) {
            float sx = ((i & 1) == 0) ? -1.0f : 1.0f;
            float sy = ((i & 2) == 0) ? -1.0f : 1.0f;
            float sz = ((i & 4) == 0) ? -1.0f : 1.0f;
            cornerWeights[i] = Math.max(0.01f, 1.0f + sx * bx + sy * by + sz * bz);
        }
        massDistribution();
    }

    void massDistribution(float[] weights) {
        if (weights != null && weights.length == 8) {
            for (int i = 0; i < 8; i++) {
                cornerWeights[i] = Math.max(0.0f, weights[i]);
            }
        }
        massDistribution();
    }

    @Override
    void massDistribution() {
        float totalMass = (gravityCenter != null) ? gravityCenter.getMass() : 0.0f;
        float weightSum = 0.0f;
        for (int i = 0; i < 8; i++) weightSum += cornerWeights[i];

        if (weightSum > 0.0f) {
            for (int i = 0; i < 8; i++) {
                cornerMasses[i] = totalMass * (cornerWeights[i] / weightSum);
            }
        } else {
            for (int i = 0; i < 8; i++) {
                cornerMasses[i] = totalMass / 8.0f;
            }
        }
    }

    @Override
    void computeGravityCenter() {
        float totalMass = 0.0f;
        float gx = 0.0f, gy = 0.0f, gz = 0.0f;
        float hx = width * 0.5f, hy = height * 0.5f, hz = depth * 0.5f;

        for (int i = 0; i < 8; i++) {
            float cx = ((i & 1) == 0) ? -hx : hx;
            float cy = ((i & 2) == 0) ? -hy : hy;
            float cz = ((i & 4) == 0) ? -hz : hz;
            gx += cornerMasses[i] * cx;
            gy += cornerMasses[i] * cy;
            gz += cornerMasses[i] * cz;
            totalMass += cornerMasses[i];
        }

        if (totalMass > 0.0f) {
            gx /= totalMass;
            gy /= totalMass;
            gz /= totalMass;
        }
        geometricCenter = new Point3D(-gx, -gy, -gz);
        refreshInertia(); // inertia tensor + transform (was updateTransformMatrix)
    }

    // 8 point masses at the corners. In the local frame (origin = center of mass),
    // corner i is at geometricCenter + (+-w/2, +-h/2, +-d/2), as in draw().
    @Override
    Matrix3 computeInertiaTensor() {
        InertiaAccumulator acc = new InertiaAccumulator();
        float hx = width * 0.5f, hy = height * 0.5f, hz = depth * 0.5f;
        for (int i = 0; i < 8; i++) {
            float cx = geometricCenter.getX() + (((i & 1) == 0) ? -hx : hx);
            float cy = geometricCenter.getY() + (((i & 2) == 0) ? -hy : hy);
            float cz = geometricCenter.getZ() + (((i & 4) == 0) ? -hz : hz);
            acc.addPointMass(cornerMasses[i], cx, cy, cz);
        }
        return acc.toMatrix();
    }

    @Override
    Point3D interceptLine(Point3D a, Point3D b) {
        updateTransformMatrix();
        Matrix4 transform = getRotationMatrix();
        Point3D localA = transform.transformInverse(a);
        Point3D localB = transform.transformInverse(b);
        Vector3D dVec = localB.sub(localA);

        float cx = geometricCenter.getX();
        float cy = geometricCenter.getY();
        float cz = geometricCenter.getZ();

        float[] minB = { cx - width * 0.5f, cy - height * 0.5f, cz - depth * 0.5f };
        float[] maxB = { cx + width * 0.5f, cy + height * 0.5f, cz + depth * 0.5f };
        float[] orig = { localA.getX(), localA.getY(), localA.getZ() };
        float[] dir  = { dVec.getX(), dVec.getY(), dVec.getZ() };

        float tMin = 0.0f;
        float tMax = 1.0f;

        for (int i = 0; i < 3; i++) {
            if (Math.abs(dir[i]) < 1e-6f) {
                if (orig[i] < minB[i] || orig[i] > maxB[i]) return null;
            } else {
                float invD = 1.0f / dir[i];
                float t1 = (minB[i] - orig[i]) * invD;
                float t2 = (maxB[i] - orig[i]) * invD;
                if (t1 > t2) {
                    float tmp = t1;
                    t1 = t2;
                    t2 = tmp;
                }
                tMin = Math.max(tMin, t1);
                tMax = Math.min(tMax, t2);
                if (tMin > tMax) return null;
            }
        }

        Point3D localHit = localA.add(dVec.mult(tMin));
        return transform.transform(localHit);
    }

    @Override
    void draw() {
        updateTransformMatrix();
        float totalMass = (gravityCenter != null && gravityCenter.getMass() > 0.0f)
            ? gravityCenter.getMass() : 1.0f;
        float uniformPct = 1.0f / 8.0f;

        float hx = width * 0.5f, hy = height * 0.5f, hz = depth * 0.5f;
        float[][] corners = new float[8][3];
        int[] cornerColors = new int[8];

        for (int i = 0; i < 8; i++) {
            corners[i][0] = ((i & 1) == 0) ? -hx : hx;
            corners[i][1] = ((i & 2) == 0) ? -hy : hy;
            corners[i][2] = ((i & 4) == 0) ? -hz : hz;
            cornerColors[i] = weightPercentToColor(cornerMasses[i] / totalMass, uniformPct, 195);
        }

        int[][] quads = {
            {0, 1, 3, 2}, // -Z face
            {4, 5, 7, 6}, // +Z face
            {0, 2, 6, 4}, // -X face
            {1, 3, 7, 5}, // +X face
            {0, 1, 5, 4}, // -Y face
            {2, 3, 7, 6}  // +Y face
        };

        pushMatrix();
        applyMatrix(getRotationMatrix().toPMatrix3D());
        translate(geometricCenter.getX(), geometricCenter.getY(), geometricCenter.getZ());

        stroke(255, 210);
        strokeWeight(1.4f);
        beginShape(QUADS);
        for (int[] q : quads) {
            for (int idx : q) {
                fill(cornerColors[idx]);
                vertex(corners[idx][0], corners[idx][1], corners[idx][2]);
            }
        }
        endShape();

        popMatrix();
        super.draw();
    }
}

// ==========================================
// cylenderBody (Aligned along local Y-axis)
// ==========================================
class cylenderBody extends GeometricBody {
    float radius;
    float height;

    float topWeight = -1.0f, bottomWeight = -1.0f, lateralWeight = -1.0f;
    float topCapMass, bottomCapMass, lateralMass;

    public cylenderBody(Point3D position, Quaternion orientation, float totalMass,
                        float radius, float height) {
        super(position, orientation, totalMass);
        this.radius = radius;
        this.height = height;
        massDistribution();
        computeGravityCenter();
    }

    public cylenderBody(Point3D position, Quaternion orientation, float totalMass,
                        float radius, float height,
                        float topWeight, float bottomWeight, float lateralWeight) {
        super(position, orientation, totalMass);
        this.radius = radius;
        this.height = height;
        massDistribution(topWeight, bottomWeight, lateralWeight);
        computeGravityCenter();
    }

    void massDistribution(float topWeight, float bottomWeight, float lateralWeight) {
        this.topWeight = Math.max(0.0f, topWeight);
        this.bottomWeight = Math.max(0.0f, bottomWeight);
        this.lateralWeight = Math.max(0.0f, lateralWeight);
        massDistribution();
    }

    @Override
    void massDistribution() {
        float totalMass = (gravityCenter != null) ? gravityCenter.getMass() : 0.0f;

        if (topWeight >= 0.0f && bottomWeight >= 0.0f && lateralWeight >= 0.0f) {
            float weightSum = topWeight + bottomWeight + lateralWeight;
            if (weightSum > 0.0f) {
                topCapMass = totalMass * (topWeight / weightSum);
                bottomCapMass = totalMass * (bottomWeight / weightSum);
                lateralMass = totalMass * (lateralWeight / weightSum);
                return;
            }
        }

        float capArea = (float)Math.PI * radius * radius;
        float sideArea = 2.0f * (float)Math.PI * radius * height;
        float totalArea = 2.0f * capArea + sideArea;

        if (totalArea > 0.0f) {
            topCapMass = totalMass * (capArea / totalArea);
            bottomCapMass = totalMass * (capArea / totalArea);
            lateralMass = totalMass * (sideArea / totalArea);
        } else {
            topCapMass = bottomCapMass = lateralMass = totalMass / 3.0f;
        }
    }

    @Override
    void computeGravityCenter() {
        float totalMass = topCapMass + bottomCapMass + lateralMass;
        float halfH = height * 0.5f;
        float gy = 0.0f;

        if (totalMass > 0.0f) {
            gy = (topCapMass * halfH + bottomCapMass * (-halfH) + lateralMass * 0.0f) / totalMass;
        }

        geometricCenter = new Point3D(0.0f, -gy, 0.0f);
        refreshInertia(); // inertia tensor + transform (was updateTransformMatrix)
    }

    // Continuous pieces + parallel axis theorem
    @Override
    Matrix3 computeInertiaTensor() {
        InertiaAccumulator acc = new InertiaAccumulator();
        float r2 = radius * radius;
        float halfH = height * 0.5f;
        float yc = geometricCenter.getY();

        acc.addLocalDiagonal(0.25f * topCapMass * r2, 0.5f * topCapMass * r2, 0.25f * topCapMass * r2);
        acc.addPointMass(topCapMass, 0.0f, yc + halfH, 0.0f);

        acc.addLocalDiagonal(0.25f * bottomCapMass * r2, 0.5f * bottomCapMass * r2, 0.25f * bottomCapMass * r2);
        acc.addPointMass(bottomCapMass, 0.0f, yc - halfH, 0.0f);

        float side = 0.5f * lateralMass * r2 + lateralMass * height * height / 12.0f;
        acc.addLocalDiagonal(side, lateralMass * r2, side);
        acc.addPointMass(lateralMass, 0.0f, yc, 0.0f);

        return acc.toMatrix();
    }

    @Override
    Point3D interceptLine(Point3D a, Point3D b) {
        updateTransformMatrix();
        Matrix4 transform = getRotationMatrix();
        Point3D localA = transform.transformInverse(a);
        Point3D localB = transform.transformInverse(b);
        Vector3D dir = localB.sub(localA);

        float cy = geometricCenter.getY();
        float ox = localA.getX(), oy = localA.getY() - cy, oz = localA.getZ();
        float dx = dir.getX(), dy = dir.getY(), dz = dir.getZ();
        float halfH = height * 0.5f;

        float bestT = Float.MAX_VALUE;
        boolean hit = false;

        float A = dx * dx + dz * dz;
        float B = 2.0f * (ox * dx + oz * dz);
        float C = ox * ox + oz * oz - radius * radius;

        if (A > 1e-6f) {
            float disc = B * B - 4.0f * A * C;
            if (disc >= 0.0f) {
                float sqrtDisc = (float)Math.sqrt(disc);
                float[] ts = { (-B - sqrtDisc) / (2.0f * A), (-B + sqrtDisc) / (2.0f * A) };
                for (float t : ts) {
                    if (t >= 0.0f && t <= 1.0f) {
                        float y = oy + t * dy;
                        if (y >= -halfH && y <= halfH && t < bestT) {
                            bestT = t;
                            hit = true;
                        }
                    }
                }
            }
        }

        if (Math.abs(dy) > 1e-6f) {
            float[] capYs = { halfH, -halfH };
            for (float capY : capYs) {
                float t = (capY - oy) / dy;
                if (t >= 0.0f && t <= 1.0f && t < bestT) {
                    float x = ox + t * dx;
                    float z = oz + t * dz;
                    if (x * x + z * z <= radius * radius) {
                        bestT = t;
                        hit = true;
                    }
                }
            }
        }

        if (!hit) return null;

        Point3D localHit = localA.add(dir.mult(bestT));
        return transform.transform(localHit);
    }

    @Override
    void draw() {
        updateTransformMatrix();
        float totalMass = (gravityCenter != null && gravityCenter.getMass() > 0.0f)
            ? gravityCenter.getMass() : 1.0f;
        float uniformPct = 1.0f / 3.0f;

        int cTop  = weightPercentToColor(topCapMass / totalMass, uniformPct, 205);
        int cBot  = weightPercentToColor(bottomCapMass / totalMass, uniformPct, 205);
        int cSide = weightPercentToColor(lateralMass / totalMass, uniformPct, 205);

        pushMatrix();
        applyMatrix(getRotationMatrix().toPMatrix3D());
        translate(geometricCenter.getX(), geometricCenter.getY(), geometricCenter.getZ());
        stroke(255, 200);
        strokeWeight(1.2f);

        int detail = 24;
        float halfH = height * 0.5f;

        // Lateral surface with vertical %TotalWeight gradient between bottom, mid, and top
        beginShape(QUAD_STRIP);
        for (int i = 0; i <= detail; i++) {
            float angle = TWO_PI * i / detail;
            float x = cos(angle) * radius;
            float z = sin(angle) * radius;
            fill(lerpColor(cBot, cSide, 0.5f));
            vertex(x, -halfH, z);
            fill(lerpColor(cTop, cSide, 0.5f));
            vertex(x,  halfH, z);
        }
        endShape();

        // Top cap (+Y)
        fill(cTop);
        beginShape(TRIANGLE_FAN);
        vertex(0, halfH, 0);
        for (int i = 0; i <= detail; i++) {
            float angle = TWO_PI * i / detail;
            vertex(cos(angle) * radius, halfH, sin(angle) * radius);
        }
        endShape();

        // Bottom cap (-Y)
        fill(cBot);
        beginShape(TRIANGLE_FAN);
        vertex(0, -halfH, 0);
        for (int i = 0; i <= detail; i++) {
            float angle = TWO_PI * i / detail;
            vertex(cos(angle) * radius, -halfH, sin(angle) * radius);
        }
        endShape();

        popMatrix();
        super.draw();
    }
}

// ==========================================
// GraphBody, Faces & Complex Pattern Enum
// ==========================================
enum GraphShapePattern {
    TORUS,
    HELIX,
    STARBURST,
    TREFOIL_KNOT,
    DUMBBELL,
    CLUSTER
}

class GraphNode {
    Point3D localPos;
    float weight;
    ArrayList<GraphNode> neighbors;

    GraphNode(Point3D localPos, float weight) {
        this.localPos = localPos;
        this.weight = weight;
        this.neighbors = new ArrayList<GraphNode>();
    }
}

class GraphFace {
    GraphNode a, b, c;

    GraphFace(GraphNode a, GraphNode b, GraphNode c) {
        this.a = a;
        this.b = b;
        this.c = c;
    }
}

class GraphBody extends RigidBody {
    ArrayList<GraphNode> nodes;
    ArrayList<GraphFace> faces;
    int nodeCount;
    GraphShapePattern shapePattern;
    float shapeRadius = 7.0f;
    float jitterRatio = 0.15f;
    float nodeHitRadius = 1.2f;
    Vector3D weightSkew = new Vector3D(0.0f, 0.0f, 0.0f);

    public GraphBody(Point3D position, Quaternion orientation, float totalMass) {
        this(position, orientation, totalMass, 16, GraphShapePattern.TORUS, 7.0f, 0.15f, new Vector3D());
    }

    public GraphBody(Point3D position, Quaternion orientation, float totalMass,
                     int n, GraphShapePattern pattern) {
        this(position, orientation, totalMass, n, pattern, 7.0f, 0.15f, new Vector3D());
    }

    public GraphBody(Point3D position, Quaternion orientation, float totalMass,
                     int n, GraphShapePattern pattern, Vector3D weightSkew) {
        this(position, orientation, totalMass, n, pattern, 7.0f, 0.15f, weightSkew);
    }

    public GraphBody(Point3D position, Quaternion orientation, float totalMass,
                     int n, GraphShapePattern pattern, float shapeRadius,
                     float jitterRatio, Vector3D weightSkew) {
        super(position, orientation, totalMass);
        this.nodes = new ArrayList<GraphNode>();
        this.faces = new ArrayList<GraphFace>();
        this.nodeCount = Math.max(3, n);
        this.shapePattern = (pattern != null) ? pattern : GraphShapePattern.TORUS;
        this.shapeRadius = shapeRadius;
        this.jitterRatio = Math.max(0.0f, jitterRatio);
        this.weightSkew = (weightSkew != null) ? weightSkew : new Vector3D();

        generateShape();
        distributeWeights(this.weightSkew);
        computeGravityCenter();
    }

    void generateShape(int n, GraphShapePattern pattern, Vector3D skew) {
        this.nodeCount = Math.max(3, n);
        this.shapePattern = (pattern != null) ? pattern : GraphShapePattern.TORUS;
        this.weightSkew = (skew != null) ? skew : new Vector3D();
        generateShape();
        distributeWeights(this.weightSkew);
        computeGravityCenter();
    }

    void generateShape() {
        nodes.clear();
        faces.clear();
        float jitter = shapeRadius * jitterRatio;
        float goldenAngle = (float)(Math.PI * (3.0 - Math.sqrt(5.0)));

        for (int i = 0; i < nodeCount; i++) {
            float t = (nodeCount > 1) ? (float)i / (nodeCount - 1) : 0.5f;
            float jx = random(-jitter, jitter);
            float jy = random(-jitter, jitter);
            float jz = random(-jitter, jitter);
            Point3D pos;

            switch (shapePattern) {
                case TORUS: {
                    float majorR = shapeRadius;
                    float minorR = shapeRadius * 0.35f;
                    float u = (TWO_PI * i) / nodeCount + random(-0.15f, 0.15f);
                    float v = goldenAngle * i * 2.0f + random(-0.3f, 0.3f);
                    float r = majorR + minorR * (float)Math.cos(v);
                    pos = new Point3D(
                        r * (float)Math.cos(u) + jx * 0.5f,
                        minorR * (float)Math.sin(v) + jy * 0.5f,
                        r * (float)Math.sin(u) + jz * 0.5f
                    );
                    break;
                }

                case HELIX: {
                    float turns = 2.5f;
                    float angle = t * turns * TWO_PI + random(-0.15f, 0.15f);
                    float y = (t - 0.5f) * (shapeRadius * 2.2f) + jy * 0.5f;
                    float r = shapeRadius * 0.65f + random(-jitter, jitter);
                    pos = new Point3D(
                        r * (float)Math.cos(angle),
                        y,
                        r * (float)Math.sin(angle)
                    );
                    break;
                }

                case STARBURST: {
                    int numArms = Math.max(4, Math.min(8, nodeCount / 3));
                    int armIdx = i % numArms;
                    float armProgress = (float)(i / numArms) / Math.max(1, (nodeCount / numArms));
                    float yDir = 1.0f - 2.0f * ((armIdx + 0.5f) / numArms);
                    float rAtY = (float)Math.sqrt(Math.max(0.0f, 1.0f - yDir * yDir));
                    float theta = goldenAngle * armIdx;
                    float dist = shapeRadius * (0.2f + 0.9f * armProgress);
                    pos = new Point3D(
                        (float)Math.cos(theta) * rAtY * dist + jx * 0.4f,
                        yDir * dist + jy * 0.4f,
                        (float)Math.sin(theta) * rAtY * dist + jz * 0.4f
                    );
                    break;
                }

                case TREFOIL_KNOT: {
                    float phi = (TWO_PI * i) / nodeCount + random(-0.1f, 0.1f);
                    float scale = shapeRadius * 0.35f;
                    float x = (float)(Math.sin(phi) + 2.0 * Math.sin(2.0 * phi)) * scale + jx * 0.4f;
                    float y = (float)(Math.cos(phi) - 2.0 * Math.cos(2.0 * phi)) * scale + jy * 0.4f;
                    float z = (float)(-Math.sin(3.0 * phi)) * scale + jz * 0.4f;
                    pos = new Point3D(x, y, z);
                    break;
                }

                case DUMBBELL: {
                    float bridgeFraction = 0.25f;
                    if (t < bridgeFraction) {
                        float bt = (t / bridgeFraction) * 2.0f - 1.0f;
                        pos = new Point3D(
                            bt * shapeRadius * 0.7f,
                            jy * 0.35f,
                            jz * 0.35f
                        );
                    } else {
                        float side = (i % 2 == 0) ? 1.0f : -1.0f;
                        float lobeR = shapeRadius * 0.45f;
                        float u = random(-1.0f, 1.0f);
                        float theta = random(0.0f, TWO_PI);
                        float s = (float)Math.sqrt(Math.max(0.0f, 1.0f - u * u));
                        float r = lobeR * (0.5f + 0.5f * random(0.0f, 1.0f));
                        pos = new Point3D(
                            side * shapeRadius * 0.85f + r * s * (float)Math.cos(theta),
                            r * u,
                            r * s * (float)Math.sin(theta)
                        );
                    }
                    break;
                }

                case CLUSTER:
                default: {
                    float r = shapeRadius * (float)Math.pow(random(0.0f, 1.0f), 0.6f);
                    float u = random(-1.0f, 1.0f);
                    float theta = random(0.0f, TWO_PI);
                    float s = (float)Math.sqrt(Math.max(0.0f, 1.0f - u * u));
                    pos = new Point3D(
                        r * s * (float)Math.cos(theta),
                        r * u,
                        r * s * (float)Math.sin(theta)
                    );
                    break;
                }
            }

            nodes.add(new GraphNode(pos, 1.0f));
        }

        int kNeighbors = Math.min(4, nodeCount - 1);
        for (int i = 0; i < nodeCount; i++) {
            GraphNode current = nodes.get(i);
            boolean[] chosen = new boolean[nodeCount];
            chosen[i] = true;

            for (int k = 0; k < kNeighbors; k++) {
                int bestIdx = -1;
                float bestDistSq = Float.MAX_VALUE;
                for (int j = 0; j < nodeCount; j++) {
                    if (chosen[j]) continue;
                    float dSq = current.localPos.distanceSquaredTo(nodes.get(j).localPos);
                    if (dSq < bestDistSq) {
                        bestDistSq = dSq;
                        bestIdx = j;
                    }
                }
                if (bestIdx != -1) {
                    chosen[bestIdx] = true;
                    connectNodes(current, nodes.get(bestIdx));
                }
            }
        }

        if (shapePattern == GraphShapePattern.TORUS ||
            shapePattern == GraphShapePattern.HELIX ||
            shapePattern == GraphShapePattern.TREFOIL_KNOT) {
            for (int i = 0; i < nodeCount - 1; i++) {
                connectNodes(nodes.get(i), nodes.get(i + 1));
            }
            if (shapePattern != GraphShapePattern.HELIX && nodeCount > 2) {
                connectNodes(nodes.get(nodeCount - 1), nodes.get(0));
            }
        }

        buildFaces();
    }

    void connectNodes(GraphNode a, GraphNode b) {
        if (a == b) return;
        if (!a.neighbors.contains(b)) a.neighbors.add(b);
        if (!b.neighbors.contains(a)) b.neighbors.add(a);
    }

    // Ensures every node belongs to at least one triangular plane (GraphFace)
    void buildFaces() {
        faces.clear();
        int count = nodes.size();
        if (count < 3) return;

        // 1. Close open 4-node quad windows by adding the shorter diagonal edge
        for (int i = 0; i < count; i++) {
            GraphNode ni = nodes.get(i);
            for (int j = i + 1; j < count; j++) {
                GraphNode nj = nodes.get(j);
                if (!ni.neighbors.contains(nj)) continue;

                for (int k = j + 1; k < count; k++) {
                    GraphNode nk = nodes.get(k);
                    if (!nj.neighbors.contains(nk) || ni.neighbors.contains(nk)) continue;

                    for (int l = i + 1; l < count; l++) {
                        if (l == j || l == k) continue;
                        GraphNode nl = nodes.get(l);
                        if (nk.neighbors.contains(nl) && nl.neighbors.contains(ni) && !nj.neighbors.contains(nl)) {
                            float diagIK = ni.localPos.distanceSquaredTo(nk.localPos);
                            float diagJL = nj.localPos.distanceSquaredTo(nl.localPos);
                            if (diagIK <= diagJL) {
                                connectNodes(ni, nk);
                            } else {
                                connectNodes(nj, nl);
                            }
                        }
                    }
                }
            }
        }

        // 2. Extract all closed 3-node cycles (triangular windows)
        boolean[] inFace = new boolean[count];
        for (int i = 0; i < count; i++) {
            GraphNode ni = nodes.get(i);
            for (int j = i + 1; j < count; j++) {
                GraphNode nj = nodes.get(j);
                if (!ni.neighbors.contains(nj)) continue;

                for (int k = j + 1; k < count; k++) {
                    GraphNode nk = nodes.get(k);
                    if (ni.neighbors.contains(nk) && nj.neighbors.contains(nk)) {
                        faces.add(new GraphFace(ni, nj, nk));
                        inFace[i] = true;
                        inFace[j] = true;
                        inFace[k] = true;
                    }
                }
            }
        }

        // 3. Guarantee every remaining node belongs to at least one triangle
        for (int i = 0; i < count; i++) {
            if (inFace[i]) continue;
            GraphNode node = nodes.get(i);

            int best1 = -1, best2 = -1;
            float d1 = Float.MAX_VALUE, d2 = Float.MAX_VALUE;

            for (int j = 0; j < count; j++) {
                if (i == j) continue;
                float dSq = node.localPos.distanceSquaredTo(nodes.get(j).localPos);
                if (dSq < d1) {
                    d2 = d1; best2 = best1;
                    d1 = dSq; best1 = j;
                } else if (dSq < d2) {
                    d2 = dSq; best2 = j;
                }
            }

            if (best1 != -1 && best2 != -1) {
                GraphNode n1 = nodes.get(best1);
                GraphNode n2 = nodes.get(best2);
                connectNodes(node, n1);
                connectNodes(node, n2);
                connectNodes(n1, n2);
                faces.add(new GraphFace(node, n1, n2));
                inFace[i] = true;
                inFace[best1] = true;
                inFace[best2] = true;
            }
        }
    }

    void distributeWeights() {
        distributeWeights(this.weightSkew);
    }

    void distributeWeights(Vector3D skew) {
        if (nodes.isEmpty()) return;
        this.weightSkew = (skew != null) ? skew : new Vector3D();
        float totalMass = (gravityCenter != null) ? gravityCenter.getMass() : 0.0f;

        if (this.weightSkew.lengthSquared() < 1e-6f) {
            float weightPerNode = totalMass / nodes.size();
            for (GraphNode node : nodes) {
                node.weight = weightPerNode;
            }
            return;
        }

        float[] rawWeights = new float[nodes.size()];
        float weightSum = 0.0f;
        float invScale = 1.0f / Math.max(1.0f, shapeRadius);

        for (int i = 0; i < nodes.size(); i++) {
            Point3D p = nodes.get(i).localPos;
            Vector3D posVec = new Vector3D(p.getX(), p.getY(), p.getZ());
            float projection = posVec.dot(this.weightSkew) * invScale;
            float w = (float)Math.exp(projection);
            rawWeights[i] = w;
            weightSum += w;
        }

        for (int i = 0; i < nodes.size(); i++) {
            nodes.get(i).weight = totalMass * (rawWeights[i] / weightSum);
        }
    }

    void distributeWeights(float[] nodeWeightRatios) {
        if (nodes.isEmpty() || nodeWeightRatios == null || nodeWeightRatios.length != nodes.size()) {
            distributeWeights();
            return;
        }
        float totalMass = (gravityCenter != null) ? gravityCenter.getMass() : 0.0f;
        float ratioSum = 0.0f;
        for (float r : nodeWeightRatios) ratioSum += Math.max(0.0f, r);

        if (ratioSum > 0.0f) {
            for (int i = 0; i < nodes.size(); i++) {
                nodes.get(i).weight = totalMass * (Math.max(0.0f, nodeWeightRatios[i]) / ratioSum);
            }
        } else {
            distributeWeights();
        }
    }

    @Override
    void computeGravityCenter() {
        if (nodes.isEmpty()) {
            refreshInertia(); // was updateTransformMatrix
            return;
        }

        float totalWeight = 0.0f;
        float wx = 0.0f, wy = 0.0f, wz = 0.0f;

        for (GraphNode node : nodes) {
            totalWeight += node.weight;
            wx += node.localPos.getX() * node.weight;
            wy += node.localPos.getY() * node.weight;
            wz += node.localPos.getZ() * node.weight;
        }

        if (totalWeight > 0.0f) {
            Vector3D offset = new Vector3D(wx / totalWeight, wy / totalWeight, wz / totalWeight);

            for (GraphNode node : nodes) {
                node.localPos = node.localPos.sub(offset);
            }
        }
        refreshInertia(); // inertia tensor + transform (was updateTransformMatrix)
    }

    // One point mass per node (positions already centered on the center of mass)
    @Override
    Matrix3 computeInertiaTensor() {
        if (nodes == null || nodes.isEmpty()) return defaultInertiaTensor();
        InertiaAccumulator acc = new InertiaAccumulator();
        for (GraphNode node : nodes) {
            acc.addPointMass(node.weight, node.localPos.getX(), node.localPos.getY(), node.localPos.getZ());
        }
        return acc.toMatrix();
    }

    private float intersectTriangleSegment(Point3D localA, Vector3D dir,
                                           Point3D p0, Point3D p1, Point3D p2) {
        Vector3D v0 = new Vector3D(p0.getX(), p0.getY(), p0.getZ());
        Vector3D v1 = new Vector3D(p1.getX(), p1.getY(), p1.getZ());
        Vector3D v2 = new Vector3D(p2.getX(), p2.getY(), p2.getZ());

        Vector3D edge1 = v1.sub(v0);
        Vector3D edge2 = v2.sub(v0);
        Vector3D h = dir.cross(edge2);
        float det = edge1.dot(h);

        if (Math.abs(det) < 1e-6f) return -1.0f;

        float invDet = 1.0f / det;
        Vector3D orig = new Vector3D(localA.getX(), localA.getY(), localA.getZ());
        Vector3D s = orig.sub(v0);
        float u = invDet * s.dot(h);
        if (u < 0.0f || u > 1.0f) return -1.0f;

        Vector3D q = s.cross(edge1);
        float v = invDet * dir.dot(q);
        if (v < 0.0f || u + v > 1.0f) return -1.0f;

        float t = invDet * edge2.dot(q);
        if (t >= 0.0f && t <= 1.0f) {
            return t;
        }
        return -1.0f;
    }

    @Override
    Point3D interceptLine(Point3D a, Point3D b) {
        updateTransformMatrix();
        Matrix4 transform = getRotationMatrix();
        Point3D localA = transform.transformInverse(a);
        Point3D localB = transform.transformInverse(b);

        Vector3D dir = localB.sub(localA);
        float lenSq = dir.lengthSquared();
        if (lenSq < 1e-6f) return null;

        float bestT = Float.MAX_VALUE;
        boolean hit = false;

        for (GraphFace face : faces) {
            float t = intersectTriangleSegment(
                localA, dir,
                face.a.localPos, face.b.localPos, face.c.localPos
            );
            if (t >= 0.0f && t < bestT) {
                bestT = t;
                hit = true;
            }
        }

        if (faces.isEmpty()) {
            for (GraphNode node : nodes) {
                Vector3D m = localA.sub(node.localPos);
                float bCoef = m.dot(dir);
                float cCoef = m.lengthSquared() - nodeHitRadius * nodeHitRadius;
                if (cCoef > 0.0f && bCoef > 0.0f) continue;

                float disc = bCoef * bCoef - lenSq * cCoef;
                if (disc < 0.0f) continue;

                float t = (-bCoef - (float)Math.sqrt(disc)) / lenSq;
                if (t < 0.0f) t = 0.0f;
                if (t <= 1.0f && t < bestT) {
                    bestT = t;
                    hit = true;
                }
            }
        }

        if (!hit) return null;

        Point3D localHit = localA.add(dir.mult(bestT));
        return transform.transform(localHit);
    }

    @Override
    void draw() {
        updateTransformMatrix();
        float totalMass = (gravityCenter != null && gravityCenter.getMass() > 0.0f)
            ? gravityCenter.getMass() : 1.0f;
        float uniformPct = (!nodes.isEmpty()) ? (1.0f / nodes.size()) : 1.0f;

        pushMatrix();
        applyMatrix(getRotationMatrix().toPMatrix3D());

        // 1. Draw solid translucent triangular windows with per-vertex %TotalWeight gradient
        noStroke();
        beginShape(TRIANGLES);
        for (GraphFace face : faces) {
            fill(weightPercentToColor(face.a.weight / totalMass, uniformPct, 145));
            vertex(face.a.localPos.getX(), face.a.localPos.getY(), face.a.localPos.getZ());

            fill(weightPercentToColor(face.b.weight / totalMass, uniformPct, 145));
            vertex(face.b.localPos.getX(), face.b.localPos.getY(), face.b.localPos.getZ());

            fill(weightPercentToColor(face.c.weight / totalMass, uniformPct, 145));
            vertex(face.c.localPos.getX(), face.c.localPos.getY(), face.c.localPos.getZ());
        }
        endShape();

        // 2. Draw graph wireframe edges
        stroke(225, 240, 255, 190);
        strokeWeight(1.5f);
        for (GraphNode node : nodes) {
            for (GraphNode neighbor : node.neighbors) {
                line(node.localPos.getX(), node.localPos.getY(), node.localPos.getZ(),
                     neighbor.localPos.getX(), neighbor.localPos.getY(), neighbor.localPos.getZ());
            }
        }

        // 3. Draw graph vertices colored & scaled by %TotalWeight
        noStroke();
        for (GraphNode node : nodes) {
            float pct = node.weight / totalMass;
            float weightRatio = pct / uniformPct;
            float visualRadius = nodeHitRadius * 0.42f * constrain((float)Math.sqrt(weightRatio), 0.55f, 2.0f);
            fill(weightPercentToColor(pct, uniformPct, 255));
            pushMatrix();
            translate(node.localPos.getX(), node.localPos.getY(), node.localPos.getZ());
            sphere(visualRadius);
            popMatrix();
        }

        popMatrix();
        super.draw();
    }
}
