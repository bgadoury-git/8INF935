// ==========================================
// Integrator tests (rigid bodies + the translation integrator)
// Every test compares the simulation with a known analytical result.
// ==========================================

class IntegratorTests {
    int m_failures = 0;
    final float DT = PhysicsConstants.FIXED_TIMESTEP;

    void run() {
        m_failures = 0;
        testTranslationModes();
        testSpringAccuracy();
        testModeSwitching();
        testRigidBodyBasics();
        testRigidBodyRotation();
        testAngularMomentumConservation();
        testRegistry();
        testShapeInertia();
        if (m_failures == 0) println("IntegratorTests: All tests passed!");
        else println("IntegratorTests: " + m_failures + " test(s) FAILED");
    }

    // ------------------------------------------------------------------
    // Translation (LinearMotion, through a Particle): the three modes under a constant force
    // ------------------------------------------------------------------
    void testTranslationModes() {
        boolean passed = true;

        // One semi-implicit Euler step: v first, then x with the NEW v
        Particle p = particleAt(0, 1.0f);
        p.addForce(new Vector3D(2.0f, 0, 0));
        p.integrate(0.5f, IntegrationMode.SemiImplicitEuler);
        passed &= expect(near(p.getVelocity().getX(), 1.0f), "SIE: v = a dt");
        passed &= expect(near(p.getPosition().getX(), 0.5f), "SIE: x uses the new velocity (v_{n+1} dt)");
        passed &= expect(p.getForceAccumulator().lengthSquared() == 0.0f, "Accumulator cleared after postForce");
        passed &= expect(p.getLastAcceleration().equals(new Vector3D(2.0f, 0, 0)), "Last acceleration recorded");

        // Constant force for N steps: x(t) = 1/2 a t²
        int n = 60;
        float a = 3.0f;
        float t = n * DT;
        float exact = 0.5f * a * t * t;
        for (IntegrationMode mode : IntegrationMode.values()) {
            Particle q = particleAt(0, 2.0f);
            for (int i = 0; i < n; i++) {
                q.addForce(new Vector3D(a * q.getMass(), 0, 0));
                q.integrate(DT, mode);
            }
            float x = q.getPosition().getX();
            if (mode == IntegrationMode.SemiImplicitEuler) {
                // SIE: x_N = a dt² N(N+1)/2 -> relative error 1/N (first order)
                passed &= expect(near(x, a * DT * DT * n * (n + 1) / 2.0f, 1e-4f), "SIE constant force: x_N = a dt² N(N+1)/2");
            } else {
                // Verlet (position or velocity): exact for a constant acceleration
                passed &= expect(near(x, exact, 1e-4f), "Constant force exact: x = 1/2 a t² [" + mode.name() + "]");
            }
        }

        // Infinite mass: does not move, accumulator still cleared
        Particle wall = new Particle(new Point3D(1, 2, 3), new Vector3D(5, 0, 0), new Vector3D(), 0.0f, 1.0f, false);
        wall.addForce(new Vector3D(100, 100, 100));
        wall.integrate(DT, IntegrationMode.PositionVerlet);
        passed &= expect(wall.getPosition().equals(new Point3D(1, 2, 3)), "Infinite mass does not move");
        passed &= expect(wall.getForceAccumulator().lengthSquared() == 0.0f, "Infinite mass accumulator cleared");

        // Impulse in Position Verlet: the implicit velocity is updated
        Particle v = particleAt(0, 1.0f);
        v.integrate(DT, IntegrationMode.PositionVerlet);
        v.applyImpulse(new Vector3D(3.0f, 0, 0));
        v.integrate(DT, IntegrationMode.PositionVerlet);
        passed &= expect(near(v.getPosition().getX(), 3.0f * DT), "Position Verlet moves with impulse velocity");
        passed &= expect(near(v.getVelocity().getX(), 3.0f), "Position Verlet keeps impulse velocity");

        report(passed, "Integrator (translation modes)");
    }

    // ------------------------------------------------------------------
    // Spring: where the old Velocity Verlet degenerated
    // Oscillator x'' = -ω0² x, ω0 = 2π (period 1 s), x(0) = 1, v(0) = 0, on a rigid body
    // (force at the center of mass) through the registry and integrateStep().
    // ------------------------------------------------------------------
    void testSpringAccuracy() {
        boolean passed = true;
        float k = 4.0f * PI * PI;   // m = 1 -> ω0 = 2π
        int stepsPerPeriod = Math.round(1.0f / DT);
        float[] errorAfterOnePeriod = new float[3];

        for (IntegrationMode mode : IntegrationMode.values()) {
            RigidBody b = makeSphere(new Point3D(1.0f, 0, 0), 1.0f, 0.5f);
            ArrayList<RigidBody> bodies = new ArrayList<RigidBody>();
            bodies.add(b);
            ForceRegistry reg = new ForceRegistry();
            reg.add(b, springToOrigin(k));

            float maxEnergyError = 0.0f;
            for (int i = 0; i < stepsPerPeriod * 10; i++) {
                integrateStep(bodies, reg, DT, mode);
                if (i == stepsPerPeriod - 1) errorAfterOnePeriod[mode.ordinal()] = Math.abs(b.getPosition().getX() - 1.0f);
                float x = b.getPosition().getX();
                float vel = b.getVelocity().getX();
                float energy = 0.5f * vel * vel + 0.5f * k * x * x;
                maxEnergyError = Math.max(maxEnergyError, Math.abs(energy - 0.5f * k) / (0.5f * k));
            }
            // Symplectic: energy oscillates but does not drift (10 periods).
            // (For Verlet, v is the half-step velocity, hence an oscillation of about (ω0 dt)²/2 ≈ 5 %.)
            passed &= expect(maxEnergyError < 0.12f, "Spring: energy bounded over 10 periods [" + mode.name() + "] err=" + maxEnergyError);
        }
        // Both Verlets are second order, SIE first order: after one period they are more accurate
        passed &= expect(errorAfterOnePeriod[IntegrationMode.VelocityVerlet.ordinal()] < errorAfterOnePeriod[IntegrationMode.SemiImplicitEuler.ordinal()],
                         "Spring: Velocity Verlet more accurate than SIE after one period");
        // Reference: the old VV (a_{n+1} = a_n) gave x(T) = 1.18 and an energy x26 after 10 periods
        passed &= expect(errorAfterOnePeriod[IntegrationMode.VelocityVerlet.ordinal()] < 1e-3f,
                         "Spring: Velocity Verlet back at x(0) after one period (real a_{n+1})");

        report(passed, "Integrator (spring accuracy)");
    }

    // ------------------------------------------------------------------
    // Switching mode in mid-flight does not create a jump
    // ------------------------------------------------------------------
    void testModeSwitching() {
        boolean passed = true;
        float a = -PhysicsConstants.GRAVITY;
        IntegrationMode[][] sequences = {
            { IntegrationMode.SemiImplicitEuler, IntegrationMode.PositionVerlet },
            { IntegrationMode.PositionVerlet,    IntegrationMode.VelocityVerlet },
            { IntegrationMode.VelocityVerlet,    IntegrationMode.SemiImplicitEuler },
        };
        for (IntegrationMode[] seq : sequences) {
            RigidBody b = makeSphere(new Point3D(), 1.0f, 0.5f);
            b.setVelocity(new Vector3D(0, 5.0f, 0));
            for (int i = 0; i < 60; i++) {
                IntegrationMode mode = (i < 30) ? seq[0] : seq[1];
                b.addForce(new Vector3D(0, a, 0));
                b.integrate(DT, mode);
            }
            float t = 60 * DT;
            float expectedY = 5.0f * t + 0.5f * a * t * t;
            float expectedV = 5.0f + a * t;
            // Tolerance: first-order error of at most one Euler step (~ a dt t)
            passed &= expect(Math.abs(b.getPosition().getY() - expectedY) < Math.abs(a) * DT * t,
                             "Mode switch keeps trajectory: " + seq[0].name() + " -> " + seq[1].name());
            passed &= expect(Math.abs(b.getVelocity().getY() - expectedV) < Math.abs(a) * DT,
                             "Mode switch keeps velocity: " + seq[0].name() + " -> " + seq[1].name());
        }
        report(passed, "Integrator (mode switching)");
    }

    // ------------------------------------------------------------------
    // Rigid body: construction, derived data, forces and impulses
    // ------------------------------------------------------------------
    void testRigidBodyBasics() {
        boolean passed = true;

        // Example from the notes (ch. 8): q = 1/2 (1,1,1,1), ω = (0, π, 0), Δt = 2
        Quaternion q = new Quaternion(0.5f, 0.5f, 0.5f, 0.5f);
        q.addScaledVector(new Vector3D(0, PI, 0), 2.0f);
        passed &= expect(q.equals(new Quaternion((1 - PI) / 2, (1 + PI) / 2, (1 + PI) / 2, (1 - PI) / 2)),
                         "Notes ch.8 example: q' = 1/2 (1-π, 1+π, 1+π, 1-π) (ω multiplied on the left)");

        RigidBody box = makeBox(new Point3D(1, 2, 3), 6.0f, 2.0f, 1.0f, 0.5f);
        box.setRotationQuaternion(new Quaternion(new Vector3D(0, 0, 1), HALF_PI));

        // Consistent derived data
        passed &= expect(box.getRotationMatrix().getPosition().equals(box.getPosition()), "Derived: transform position = body position");
        passed &= expect(box.localDirectionToWorld(new Vector3D(1, 0, 0)).equals(new Vector3D(0, 1, 0)), "Derived: local X -> world Y after 90deg around Z");
        box.setAngularMomentum(new Vector3D(0.3f, -0.2f, 0.5f));
        passed &= expect(box.getAngularVelocity().equals(box.getInverseInertiaTensorWorld().transform(box.getAngularMomentum())),
                         "Derived: ω = I^-1_world L");

        // Force at the center of mass: no torque
        RigidBody c = makeSphere(new Point3D(), 2.0f, 0.5f);
        c.addForceAtPoint(new Vector3D(0, 0, 10), new Point3D());
        passed &= expect(c.getTorqueAccumulator().lengthSquared() == 0.0f, "Force at center of mass: no torque");

        // τ = r × F
        c.addForceAtPoint(new Vector3D(0, 0, 10), new Point3D(1, 0, 0));
        passed &= expect(c.getTorqueAccumulator().equals(new Vector3D(1, 0, 0).cross(new Vector3D(0, 0, 10))), "Force at point: τ = r × F");

        // Body point: follows the orientation (local X = world Y after 90deg around Z)
        RigidBody d = makeSphere(new Point3D(), 2.0f, 0.5f);
        d.setRotationQuaternion(new Quaternion(new Vector3D(0, 0, 1), HALF_PI));
        d.addForceAtBodyPoint(new Vector3D(1, 0, 0), new Point3D(1, 0, 0));   // world point (0,1,0)
        passed &= expect(d.getTorqueAccumulator().equals(new Vector3D(0, 0, -1)), "Force at body point uses current orientation");

        // Couple (ch. 9): ΣF = 0 but τ ≠ 0 -> rotation without translation
        RigidBody e = makeSphere(new Point3D(), 2.0f, 0.5f);
        for (int i = 0; i < 60; i++) {
            e.addForceAtPoint(new Vector3D(0, 1, 0), new Point3D(1, 0, 0));
            e.addForceAtPoint(new Vector3D(0, -1, 0), new Point3D(-1, 0, 0));
            e.integrate(DT, IntegrationMode.SemiImplicitEuler);
        }
        passed &= expect(e.getVelocity().lengthSquared() == 0.0f && e.getPosition().equals(new Point3D()), "Couple: no linear motion");
        passed &= expect(e.getAngularMomentum().equals(new Vector3D(0, 0, 2.0f)), "Couple: L = Στ t");

        // Impulse at a point: Δv = J/m, ΔL = r × J
        RigidBody f = makeSphere(new Point3D(), 2.0f, 0.5f);
        f.applyImpulseAtPoint(new Vector3D(0, 4, 0), new Point3D(0.5f, 0, 0));
        passed &= expect(f.getVelocity().equals(new Vector3D(0, 2, 0)), "Impulse at point: Δv = J / m");
        passed &= expect(f.getAngularMomentum().equals(new Vector3D(0, 0, 2)), "Impulse at point: ΔL = r × J");
        passed &= expect(f.getAngularVelocity().equals(new Vector3D(0, 0, 2 / (0.4f * 2.0f * 0.25f))), "Impulse at point: ω updated immediately");

        // Infinite mass
        RigidBody fixed = new RigidBody(new Point3D(1, 1, 1), new Quaternion(), 0.0f, new Matrix3());
        fixed.addForceAtPoint(new Vector3D(5, 5, 5), new Point3D(3, 0, 0));
        fixed.integrate(DT, IntegrationMode.VelocityVerlet);
        passed &= expect(fixed.getPosition().equals(new Point3D(1, 1, 1)) && fixed.getRotationQuaternion().equals(new Quaternion()),
                         "Infinite mass rigid body does not move or rotate");
        passed &= expect(fixed.getTorqueAccumulator().lengthSquared() == 0.0f, "Infinite mass rigid body accumulators cleared");

        report(passed, "Integrator (rigid body basics)");
    }

    // ------------------------------------------------------------------
    // Rigid body: rotation
    // ------------------------------------------------------------------
    void testRigidBodyRotation() {
        boolean passed = true;

        // Constant ω (sphere, τ = 0): each step turns by 2 atan(|ω| dt / 2) (linear update + normalization)
        float omega = 1.0f;
        int n = 60;
        float expectedAngle = n * 2.0f * (float)Math.atan(omega * DT / 2.0f);
        for (IntegrationMode mode : IntegrationMode.values()) {
            RigidBody s = makeSphere(new Point3D(), 2.0f, 0.5f);
            s.setAngularVelocity(new Vector3D(0, omega, 0));
            for (int i = 0; i < n; i++) s.integrate(DT, mode);
            Quaternion expected = new Quaternion(new Vector3D(0, 1, 0), expectedAngle);
            passed &= expect(s.getRotationQuaternion().sameRotation(expected), "Constant ω: angle = N · 2 atan(|ω|dt/2) [" + mode.name() + "]");
            passed &= expect(near(expectedAngle, omega * n * DT, 1e-3f), "Constant ω: linear update ≈ exact rotation at low speed");
        }

        // Constant torque on a sphere: exact L(t)
        float tau = 0.6f;
        for (IntegrationMode mode : IntegrationMode.values()) {
            RigidBody s = makeSphere(new Point3D(), 2.0f, 0.5f);
            for (int i = 0; i < n; i++) {
                s.addTorque(new Vector3D(tau, 0, 0));
                s.integrate(DT, mode);
            }
            float t = n * DT;
            // Position Verlet: L lives at the half step (first step = half-kick), so L = τ (t - dt/2)
            float expectedL = (mode == IntegrationMode.PositionVerlet) ? tau * (t - DT / 2.0f) : tau * t;
            passed &= expect(near(s.getAngularMomentum().getX(), expectedL), "Constant torque: L = τ t [" + mode.name() + "]");
            float inertia = 0.4f * 2.0f * 0.25f;
            passed &= expect(near(s.getAngularVelocity().getX(), expectedL / inertia), "Constant torque: ω = L / I [" + mode.name() + "]");
        }

        // |q| stays 1 after many steps
        RigidBody spinner = makeBox(new Point3D(), 1.0f, 1.0f, 2.0f, 3.0f);
        spinner.setAngularVelocity(new Vector3D(3, 7, -2));
        for (int i = 0; i < 10000; i++) spinner.integrate(DT, IntegrationMode.SemiImplicitEuler);
        passed &= expect(near(spinner.getRotationQuaternion().length(), 1.0f), "|q| = 1 after 10000 steps");

        report(passed, "Integrator (rigid body rotation)");
    }

    // ------------------------------------------------------------------
    // Conservation of angular momentum + gyroscopic effect
    // Non-symmetric box spun around its INTERMEDIATE axis (Iyy) with a small perturbation:
    // without torque, L is constant, but the box flips regularly (Dzhanibekov effect): its local
    // Y axis goes from L's side to the opposite side. Storing ω instead of L would give an
    // eternal rotation around the same axis.
    // Energy: with ω evaluated at the midpoint (driftOrientation) it stays almost constant;
    // with ω(q_n) it was multiplied by ~8 in 10 s.
    // ------------------------------------------------------------------
    void testAngularMomentumConservation() {
        boolean passed = true;
        for (IntegrationMode mode : IntegrationMode.values()) {
            RigidBody b = makeBox(new Point3D(), 1.0f, 3.0f, 1.0f, 0.4f); //  Ixx < Iyy < Izz
            b.setAngularVelocity(new Vector3D(0.02f, 4.0f, 0.0f));
            Vector3D L0 = b.getAngularMomentum();
            float e0 = b.getRotationalKineticEnergy();

            boolean flipped = false;
            float maxEnergyError = 0.0f;
            for (int i = 0; i < 3600; i++) {   // 60 s
                b.integrate(DT, mode);
                Vector3D localY = b.localDirectionToWorld(new Vector3D(0, 1, 0));
                if (localY.dot(L0) < 0.0f) flipped = true;
                maxEnergyError = Math.max(maxEnergyError, Math.abs(b.getRotationalKineticEnergy() - e0) / e0);
            }
            passed &= expect(b.getAngularMomentum().equals(L0), "τ = 0: L exactly conserved [" + mode.name() + "]");
            passed &= expect(flipped, "τ = 0: box flips around its intermediate axis (Dzhanibekov) [" + mode.name() + "]");
            passed &= expect(maxEnergyError < 0.01f, "τ = 0: rotational energy conserved within 1 % over 60 s [" + mode.name() + "] err=" + maxEnergyError);
        }
        report(passed, "Integrator (angular momentum)");
    }

    // ------------------------------------------------------------------
    // Registry + two-half loop with rigid bodies
    // ------------------------------------------------------------------
    void testRegistry() {
        boolean passed = true;
        int n = 60;
        float t = n * DT;
        float g = PhysicsConstants.GRAVITY;
        for (IntegrationMode mode : IntegrationMode.values()) {
            RigidBody b = makeBox(new Point3D(0, 10, 0), 2.0f, 1.0f, 2.0f, 3.0f);
            b.setAngularVelocity(new Vector3D(0, 1, 0));
            ArrayList<RigidBody> bodies = new ArrayList<RigidBody>();
            bodies.add(b);
            ForceRegistry reg = new ForceRegistry();
            reg.add(b, new GravityGenerator(new Vector3D(0, -g, 0)));
            Vector3D L0 = b.getAngularMomentum();

            for (int i = 0; i < n; i++) integrateStep(bodies, reg, DT, mode);

            // SIE: y_N = y0 - g dt² N(N+1)/2 ; both Verlets: exact y0 - 1/2 g t²
            float expectedY = (mode == IntegrationMode.SemiImplicitEuler)
                ? 10.0f - g * DT * DT * n * (n + 1) / 2.0f
                : 10.0f - 0.5f * g * t * t;
            passed &= expect(near(b.getPosition().getY(), expectedY, 1e-4f), "Gravity: rigid body free fall [" + mode.name() + "]");
            passed &= expect(b.getAngularMomentum().equals(L0), "Gravity at center of mass: no torque [" + mode.name() + "]");
        }

        // Force at a body point through a generator: the force follows the rotation
        RigidBody s = makeSphere(new Point3D(), 2.0f, 0.5f);
        ArrayList<RigidBody> bodies = new ArrayList<RigidBody>();
        bodies.add(s);
        ForceRegistry reg = new ForceRegistry();
        reg.add(s, new ForceGenerator() {
            public void updateForce(RigidBody body, float dt) {
                body.addForceAtBodyPoint(new Vector3D(0, 1, 0), new Point3D(1, 0, 0));
            }
        });
        integrateStep(bodies, reg, DT, IntegrationMode.SemiImplicitEuler);
        passed &= expect(s.getLastAngularAcceleration().getZ() > 0.0f, "Body-point force generator creates torque");
        passed &= expect(reg.size() == 1, "Registry stores rigid bodies");
        reg.removeBody(s);
        passed &= expect(reg.size() == 0, "Registry removeBody");

        report(passed, "Integrator (registry)");
    }

    // ------------------------------------------------------------------
    // Inertia tensors of the shapes (TriangleBody, SquareBody, cylenderBody)
    // computed from their mass distribution
    // ------------------------------------------------------------------
    void testShapeInertia() {
        boolean passed = true;

        // Box with equal masses at the 8 corners: Ixx = m (b² + c²), etc., no products of inertia
        SquareBody box = new SquareBody(new Point3D(), new Quaternion(), 8.0f, 2.0f, 4.0f, 6.0f);
        Matrix3 ib = box.getInertiaTensorLocal();
        passed &= expect(ib.equals(new Matrix3(8 * (4 + 9), 0, 0, 0, 8 * (1 + 9), 0, 0, 0, 8 * (1 + 4))),
                         "SquareBody uniform corners: I = m diag(b²+c², a²+c², a²+b²)");

        // Heavier corners on +X: the center of mass moves. All corners are at x = ±a, so
        // Σ m x² = M a² does not depend on the weights and, around the center of mass,
        // Iyy = Iyy(uniform) - M x_cm² (parallel axis theorem)
        SquareBody biased = new SquareBody(new Point3D(), new Quaternion(), 20.0f, 75.0f, 55.0f, 55.0f, new Vector3D(0.7f, 0, 0));
        Matrix3 ibi = biased.getInertiaTensorLocal();
        passed &= expect(ibi.equals(ibi.transpose()), "SquareBody biased: inertia tensor is symmetric");
        Matrix3 iUniform = new SquareBody(new Point3D(), new Quaternion(), 20.0f, 75.0f, 55.0f, 55.0f).getInertiaTensorLocal();
        float xcm = -biased.getGeometricCenter().getX();   // center of mass in the geometric frame
        passed &= expect(near(ibi.get(1, 1), iUniform.get(1, 1) - 20.0f * xcm * xcm, 1e-4f),
                         "SquareBody biased: Iyy = Iyy(uniform) - M x_cm² (parallel axis theorem)");

        // Flat triangle (z = 0): perpendicular axis theorem Izz = Ixx + Iyy
        TriangleBody tri = new TriangleBody(new Point3D(), new Quaternion(), 15.0f,
                                            0, -45, 0,  -45, 35, 0,  45, 35, 0,  4, 1, 1);
        Matrix3 it = tri.getInertiaTensorLocal();
        passed &= expect(near(it.get(2, 2), it.get(0, 0) + it.get(1, 1), 1e-4f), "TriangleBody (planar): Izz = Ixx + Iyy");

        // Cylinder, equal weights (1/3 of the mass per piece): Iyy = (1/2 + 1/2 + 1) (m/3) r² = 2/3 m r²
        float m = 9.0f, r = 2.0f, h = 6.0f;
        cylenderBody cyl = new cylenderBody(new Point3D(), new Quaternion(), m, r, h, 1, 1, 1);
        Matrix3 ic = cyl.getInertiaTensorLocal();
        passed &= expect(near(ic.get(1, 1), (2.0f / 3.0f) * m * r * r, 1e-4f), "cylenderBody: Iyy = 2/3 m r² (caps + tube)");
        // Ixx = 2 * (1/4 (m/3) r² + (m/3)(h/2)²) + (1/2 (m/3) r² + (m/3) h²/12)
        float third = m / 3.0f;
        float expectedIxx = 2 * (0.25f * third * r * r + third * (h / 2) * (h / 2)) + 0.5f * third * r * r + third * h * h / 12.0f;
        passed &= expect(near(ic.get(0, 0), expectedIxx, 1e-4f), "cylenderBody: Ixx with parallel axis theorem");

        // The shape's tensor is the one used by the integrator: L = I ω
        box.setAngularVelocity(new Vector3D(1, 2, 3));
        passed &= expect(box.getAngularMomentum().equals(ib.transform(new Vector3D(1, 2, 3))), "Shape inertia is used by the integrator (L = I ω)");

        report(passed, "Integrator (shape inertia)");
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    Particle particleAt(float x, float mass) {
        return new Particle(new Point3D(x, 0, 0), new Vector3D(), new Vector3D(), mass, 1.0f, false);
    }

    ForceGenerator springToOrigin(final float k) {
        return new ForceGenerator() {
            public void updateForce(RigidBody body, float dt) {
                Point3D p = body.getPosition();
                body.addForce(new Vector3D(-k * p.getX(), -k * p.getY(), -k * p.getZ()));
            }
        };
    }

    // Solid sphere: I = 2/5 m r² (same value on the 3 axes)
    RigidBody makeSphere(Point3D pos, float mass, float radius) {
        Matrix3 inertia = new Matrix3();
        float i = 0.4f * mass * radius * radius;
        inertia.setDiagonal(i, i, i);
        RigidBody b = new RigidBody(pos, new Quaternion(), mass, inertia);
        b.setLinearDamping(1.0f);   // GravityCenter default damping is already 1, made explicit
        return b;
    }

    RigidBody makeBox(Point3D pos, float mass, float dx, float dy, float dz) {
        Matrix3 inertia = new Matrix3();
        inertia.setCuboidInertiaTensor(mass, dx, dy, dz);
        RigidBody b = new RigidBody(pos, new Quaternion(), mass, inertia);
        b.setLinearDamping(1.0f);
        return b;
    }

    boolean near(float a, float b) { return Math.abs(a - b) < 1e-3f; }
    boolean near(float a, float b, float relTol) { return Math.abs(a - b) <= relTol * Math.max(1.0f, Math.abs(b)); }

    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
            m_failures++;
        }
        return condition;
    }

    void report(boolean passed, String suite) {
        if (passed) println(suite + ": All tests passed!");
    }
}
