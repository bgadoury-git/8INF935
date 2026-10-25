// ==========================================
// Translated Physics Unit Tests
// ==========================================

class Tests {

    void run() {
        testPoint3D();
        testVector3D();
        testPolar();
        testParticle();
        testForceAccumulator();
        testForceGeneratorInterface();
        testForceRegistry();
        testConstantForceGenerator();
        testGravityGenerator();
        testImpulse();
        testExplosion();
    }

    // --- Vector3D Tests ---
    void testVector3D() {
        boolean passed = true;
        
        // Init & Getters
        Vector3D v1 = new Vector3D(1.0f, 2.0f, 3.0f);
        passed &= expect(v1.getX() == 1.0f && v1.getY() == 2.0f && v1.getZ() == 3.0f, "Vector Initialization and Getters");
        
        // Setters
        v1.setX(4.0f); v1.setY(5.0f); v1.setZ(6.0f);
        passed &= expect(v1.getX() == 4.0f && v1.getY() == 5.0f && v1.getZ() == 6.0f, "Vector Setters");

        // Length
        passed &= expect(Math.abs(new Vector3D(0.0f, 3.0f, 4.0f).length() - 5.0f) < 1e-5f, "Vector Length");
        passed &= expect(new Vector3D(0.0f, 3.0f, 4.0f).lengthSquared() == 25.0f, "Vector LengthSquared");

        // Normalize
        Vector3D vToNorm = new Vector3D(0.0f, 3.0f, 4.0f);
        float len = vToNorm.normalize();
        passed &= expect(Math.abs(len - 5.0f) < 1e-5f && Math.abs(vToNorm.getY() - 0.6f) < 1e-5f, "Vector normalize (in-place)");
        
        Vector3D norm = new Vector3D(3.0f, 4.0f, 0.0f).normalized();
        passed &= expect(Math.abs(norm.getX() - 0.6f) < 1e-5f, "Vector normalized (new instance)");

        // Operations
        Vector3D d1 = new Vector3D(1.0f, 2.0f, 3.0f);
        Vector3D d2 = new Vector3D(4.0f, 5.0f, 6.0f);
        
        passed &= expect(d1.dot(d2) == 32.0f, "Vector Dot");
        passed &= expect(d1.cross(d2).equals(new Vector3D(-3.0f, 6.0f, -3.0f)), "Vector Cross");
        
        float angle = (float)new Vector3D(1.0f, 0.0f, 0.0f).angleTo(new Vector3D(0.0f, 1.0f, 0.0f));
        passed &= expect(Math.abs(angle - (float)Math.PI/2.0f) < 1e-5f, "Vector angleTo");
        
        passed &= expect(d1.negate().equals(new Vector3D(-1.0f, -2.0f, -3.0f)), "Vector negate");
        passed &= expect(d1.mult(2.0f).equals(new Vector3D(2.0f, 4.0f, 6.0f)), "Vector mult(scalar)");
        passed &= expect(d1.div(2.0f).equals(new Vector3D(0.5f, 1.0f, 1.5f)), "Vector div(scalar)");
        passed &= expect(d1.mult(d2).equals(new Vector3D(4.0f, 10.0f, 18.0f)), "Vector mult(vector)");
        passed &= expect(d1.add(d2).equals(new Vector3D(5.0f, 7.0f, 9.0f)), "Vector add");
        passed &= expect(d2.sub(d1).equals(new Vector3D(3.0f, 3.0f, 3.0f)), "Vector sub");

        // Equals & Formatting
        passed &= expect(d1.equals(new Vector3D(1.0f, 2.0f, 3.0f)), "Vector equals true");
        passed &= expect(!d1.equals(new Vector3D(1.0f, 2.0f, 4.0f)), "Vector equals false");
        passed &= expect(d1.toString().equals("Vector3D(1.0, 2.0, 3.0)"), "Vector toString format");

        // Error handling
        try {
            d1.div(0.0f);
            passed &= expect(false, "Vector div(0) should throw exception");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Vector div(0) correctly throws exception");
        }
        
        if (passed) println("Vector3D: All tests passed!");
    }

    // --- Point3D Tests ---
    void testPoint3D() {
        boolean passed = true;
        
        // Init & Getters
        Point3D p1 = new Point3D(1.0f, 2.0f, 3.0f);
        passed &= expect(p1.getX() == 1.0f && p1.getY() == 2.0f && p1.getZ() == 3.0f, "Point3D Init and Getters");
        
        // Setters
        p1.setX(4.0f); p1.setY(5.0f); p1.setZ(6.0f);
        passed &= expect(p1.getX() == 4.0f && p1.getY() == 5.0f && p1.getZ() == 6.0f, "Point3D Setters");

        // Distance
        Point3D pA = new Point3D(0.0f, 0.0f, 0.0f);
        Point3D pB = new Point3D(0.0f, 3.0f, 4.0f);
        passed &= expect(Math.abs(pA.distanceTo(pB) - 5.0f) < 1e-5f, "Point3D distanceTo");
        passed &= expect(pA.distanceSquaredTo(pB) == 25.0f, "Point3D distanceSquaredTo");

        // Operations
        passed &= expect(pA.add(new Vector3D(1.0f, 2.0f, 3.0f)).equals(new Point3D(1.0f, 2.0f, 3.0f)), "Point3D add(Vector)");
        passed &= expect(pB.sub(new Vector3D(0.0f, 3.0f, 4.0f)).equals(new Point3D(0.0f, 0.0f, 0.0f)), "Point3D sub(Vector)");
        passed &= expect(pB.sub(pA).equals(new Vector3D(0.0f, 3.0f, 4.0f)), "Point3D sub(Point)");

        // Equals & Formatting
        passed &= expect(pB.equals(new Point3D(0.0f, 3.0f, 4.0f)), "Point3D equals true");
        passed &= expect(!pB.equals(new Point3D(0.0f, 3.0f, 5.0f)), "Point3D equals false");
        passed &= expect(pB.toString().equals("Point3D(0.0, 3.0, 4.0)"), "Point3D toString format");

        if (passed) println("Point3D: All tests passed!");
    }

    // --- Polar Tests (MathHelpers + Integration) ---
    void testPolar() {
        boolean passed = true;
        float pi = (float)Math.PI;

        // Vector3D Polar -> Cartesian
        Vector3D v = new Vector3D(new Polar(10.0f, 0.0f, 0.0f));
        passed &= expect(v.equals(new Vector3D(0.0f, 0.0f, 10.0f)), "Polar Constructor (+Z Forward)");

        v.setPolar(5.0f, pi / 2.0f, 0.0f);
        passed &= expect(v.equals(new Vector3D(5.0f, 0.0f, 0.0f)), "Polar setPolar (+X Right)");

        // Cartesian -> Polar
        Vector3D vUp = new Vector3D(0.0f, 4.0f, 0.0f);
        Polar pUp = vUp.getPolar();
        passed &= expect(MathHelpers.equalComponents(pUp.radius, 4.0f) && 
                         MathHelpers.equalComponents(pUp.elevation, pi / 2.0f), "Polar getPolar (+Y Up)");

        // Round-trip conversion (Point3D)
        float origRadius = 7.5f;
        float origAzimuth = 0.785398f;  
        float origElevation = 0.523599f;
        Point3D pt = new Point3D(new Polar(origRadius, origAzimuth, origElevation));
        Polar pRound = pt.getPolar();
        
        passed &= expect(MathHelpers.equalComponents(pRound.radius, origRadius) &&
                         MathHelpers.equalComponents(pRound.azimuth, origAzimuth) &&
                         MathHelpers.equalComponents(pRound.elevation, origElevation), "Polar Round-Trip (Point3D)");

        if (passed) println("Polar Transitions: All tests passed!");
    }

    // --- Particle Tests ---
    void testParticle() {
        boolean passed = true;
        Particle p = new Particle();
        passed &= expect(p.getPosition().equals(new Point3D(0,0,0)), "Particle Default Init");
        
        Particle grav = new Particle(new Point3D(), new Vector3D(), new Vector3D(1.0f, 2.0f, 3.0f), 1.0f, 0.999f, true);
        //float expectedYWithGravity = 2.0f - PhysicsConstants.GRAVITY;
        //passed &= expect(Math.abs(grav.getAcceleration().getY() - expectedYWithGravity) < 1e-5f, "Particle Gravity");
        // Gravity now comes from GravityGenerator: the constructor only stores the flag, constant acceleration is untouched
        passed &= expect(Math.abs(grav.getAcceleration().getY() - 2.0f) < 1e-5f, "Gravity flag does not alter constant acceleration");
        passed &= expect(grav.getAffectedByGravity(), "Gravity flag stored");

        
        Particle noMass = new Particle(new Point3D(10,20,30), new Vector3D(100,100,100), new Vector3D(), 0.0f, 1.0f, false);
        noMass.applyVerletIntegration(0.1f);
        passed &= expect(noMass.getPosition().equals(new Point3D(10,20,30)), "Particle Zero Mass (Infinite Mass)");
        
        if (passed) println("Particle: All tests passed!");
    }

    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
        }
        return condition;
    }
    
    
    void testForceAccumulator() {
        boolean passed = true;

        // Superposition (mass 2)
        Particle pA = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, false);
        pA.addForce(new Vector3D(0.0f, 10.0f, 0.0f));
        pA.addForce(new Vector3D(4.0f, 0.0f, -2.0f));
        passed &= expect(pA.getTotalAcceleration().equals(new Vector3D(2.0f, 5.0f, -1.0f)), "Force superposition");

        // Cleared after integrate (explicit Euler moves with old velocity)
        pA.integrate(0.1f, IntegrationMode.Euler);
        passed &= expect(pA.getPosition().equals(new Point3D(0.0f, 0.0f, 0.0f)), "Euler position uses old velocity");
        passed &= expect(pA.getVelocity().equals(new Vector3D(0.2f, 0.5f, -0.1f)), "Euler velocity from net force");
        passed &= expect(pA.getTotalAcceleration().equals(new Vector3D()), "Accumulator cleared after integrate");

        // No force: no further acceleration
        pA.integrate(0.1f, IntegrationMode.Euler);
        passed &= expect(pA.getPosition().equals(new Point3D(0.02f, 0.05f, -0.01f)), "No force: position advances");
        passed &= expect(pA.getVelocity().equals(new Vector3D(0.2f, 0.5f, -0.1f)), "No force: velocity unchanged");

        // Aliasing: same vector twice, argument untouched
        Particle pD = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Vector3D g = new Vector3D(0.0f, 10.0f, 0.0f);
        pD.addForce(g);
        pD.addForce(g);
        passed &= expect(pD.getTotalAcceleration().equals(new Vector3D(0.0f, 20.0f, 0.0f)), "Same force added twice");
        passed &= expect(g.equals(new Vector3D(0.0f, 10.0f, 0.0f)), "addForce does not modify its argument");

        // Infinite mass stays still, accumulator still cleared
        Particle pE = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        pE.addForce(new Vector3D(100.0f, 100.0f, 100.0f));
        pE.integrate(0.1f, IntegrationMode.PositionVerlet);
        passed &= expect(pE.getPosition().equals(new Point3D(0.0f, 0.0f, 0.0f)), "Infinite mass does not move");
        pE.setInverseMass(1.0f);
        passed &= expect(pE.getTotalAcceleration().equals(new Vector3D()), "Infinite mass accumulator cleared");

        // Constant acceleration plus force (twice the weight, upward)
        // Gravity generator plus thrust (twice the weight, upward)
        Particle pF = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, true);
        new GravityGenerator(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f)).updateForce(pF, 0.1f);
        pF.addForce(new Vector3D(0.0f, 39.24f, 0.0f));
        passed &= expect(pF.getTotalAcceleration().equals(new Vector3D(0.0f, 9.81f, 0.0f)), "Gravity force plus thrust");

        // Velocity Verlet drift and kick both use the force
        Particle pG = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        pG.addForce(new Vector3D(2.0f, 0.0f, 0.0f));
        pG.integrate(0.5f, IntegrationMode.VelocityVerlet);
        passed &= expect(MathHelpers.equalComponents(pG.getPosition().getX(), 0.25f), "Velocity Verlet drift uses force");
        passed &= expect(MathHelpers.equalComponents(pG.getVelocity().getX(), 1.0f), "Velocity Verlet kick uses force");

        if (passed) println("Force Accumulator: All tests passed!");
    }
    
    void testForceGeneratorInterface() 
    {
        boolean passed = true;
        
        ForceGenerator upward = new ForceGenerator()
        {
            @Override
            public void updateForce(Particle particle, float deltaTime)
            {
                particle.addForce(new Vector3D(0.0f, 5.0f, 0.0f));
            }
        };
        
        Particle particle = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        upward.updateForce(particle, PhysicsConstants.FIXED_TIMESTEP);
        upward.updateForce(particle, PhysicsConstants.FIXED_TIMESTEP);
        passed &= expect(particle.getTotalAcceleration().equals(new Vector3D(0.0f, 10.0f, 0.0f)), "Generator applies force through interface");
        if(passed) println("ForceGenerator: All tests passed!");
    }
    
    void testForceRegistry() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        // Two test generators: 5 N up, 3 N right
        ForceGenerator up5 = new ForceGenerator() {
            @Override
            public void updateForce(Particle particle, float dt) {
                particle.addForce(new Vector3D(0.0f, 5.0f, 0.0f));
            }
        };
        ForceGenerator right3 = new ForceGenerator() {
            @Override
            public void updateForce(Particle particle, float dt) {
                particle.addForce(new Vector3D(3.0f, 0.0f, 0.0f));
            }
        };

        Particle p1 = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle p2 = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        ForceRegistry reg = new ForceRegistry();

        // Register: two forces on p1 (adjacent, to test reverse removal), p2 shares up5; duplicate ignored
        reg.add(p1, up5);
        reg.add(p1, right3);
        reg.add(p2, up5);
        reg.add(p1, up5);
        passed &= expect(reg.size() == 3, "Registry ignores duplicate pair");

        // Run: p1 = (3,5,0), p2 = (0,5,0)
        reg.updateForces(dt);
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D(3.0f, 5.0f, 0.0f)), "Registry applies all generators to p1");
        passed &= expect(p2.getTotalAcceleration().equals(new Vector3D(0.0f, 5.0f, 0.0f)), "Shared generator serves p2");

        // Remove one pair: p1 keeps only the rightward force
        p1.clearAccumulator(); p2.clearAccumulator();
        reg.remove(p1, up5);
        reg.updateForces(dt);
        passed &= expect(reg.size() == 2, "Remove one pair");
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D(3.0f, 0.0f, 0.0f)), "Removed generator no longer applies");

        // Remove particle: p1 gets nothing, p2 unaffected
        p1.clearAccumulator(); p2.clearAccumulator();
        reg.add(p1, up5);
        reg.removeParticle(p1);
        reg.updateForces(dt);
        passed &= expect(reg.size() == 1, "Remove all registrations of a particle");
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D()), "Removed particle receives no force");
        passed &= expect(p2.getTotalAcceleration().equals(new Vector3D(0.0f, 5.0f, 0.0f)), "Other particle unaffected");

        // Clear
        reg.clear();
        passed &= expect(reg.size() == 0, "Clear registry");

        // null fails fast
        try {
            reg.add(null, up5);
            passed &= expect(false, "Registry add(null) should throw");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Registry add(null) throws");
        }

        if (passed) println("ForceRegistry: All tests passed!");
    }
    
    void testConstantForceGenerator() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;
        ConstantForceGenerator wind = new ConstantForceGenerator(new Vector3D(10.0f, 0.0f, 0.0f));

        // Same force: 1 kg gets 10, 5 kg gets 2
        Particle light = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle heavy = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 5.0f, 1.0f, false);
        wind.updateForce(light, dt);
        wind.updateForce(heavy, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(10.0f, 0.0f, 0.0f)), "Constant force on 1 kg");
        passed &= expect(heavy.getTotalAcceleration().equals(new Vector3D(2.0f, 0.0f, 0.0f)), "Constant force on 5 kg is weaker");

        // Inactive applies nothing
        light.clearAccumulator();
        wind.setActive(false);
        wind.updateForce(light, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D()), "Inactive generator applies no force");

        // setForce copies values
        Vector3D f = new Vector3D(0.0f, 0.0f, 3.0f);
        wind.setForce(f);
        f.setZ(100.0f);
        wind.setActive(true);
        wind.updateForce(light, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(0.0f, 0.0f, 3.0f)), "setForce copies the vector");

        // getForce returns a copy; internal force unchanged after applying
        wind.getForce().setX(999.0f);
        passed &= expect(wind.getForce().equals(new Vector3D(0.0f, 0.0f, 3.0f)), "getForce returns a copy");

        // Infinite mass receives no force
        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        wind.updateForce(fixed, dt);
        fixed.setInverseMass(1.0f);
        passed &= expect(fixed.getTotalAcceleration().equals(new Vector3D()), "Constant force skips infinite mass");

        if (passed) println("ConstantForceGenerator: All tests passed!");
    }
    
    void testGravityGenerator() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        // Mass-independent: 2 kg and 5 kg get the same acceleration
        Vector3D src = new Vector3D(0.0f, -9.81f, 0.0f);
        GravityGenerator gravity = new GravityGenerator(src);
        Particle light = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, true);
        Particle heavy = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 5.0f, 1.0f, true);
        gravity.updateForce(light, dt);
        gravity.updateForce(heavy, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity on 2 kg gives g");
        passed &= expect(heavy.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity on 5 kg gives g");

        // Defensive copy: changing the source vector has no effect
        src.setY(-100.0f);
        Particle p = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, true);
        gravity.updateForce(p, dt);
        passed &= expect(p.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity vector defensively copied");

        // Infinite mass receives no force
        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, true);
        gravity.updateForce(fixed, dt);
        fixed.setInverseMass(1.0f);
        passed &= expect(fixed.getTotalAcceleration().equals(new Vector3D()), "Gravity skips infinite mass");

        // Last acceleration survives integration while the accumulator is cleared
        Particle q = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, true);
        gravity.updateForce(q, dt);
        q.addForce(new Vector3D(4.0f, 0.0f, 0.0f));
        q.integrate(dt, IntegrationMode.Euler);
        passed &= expect(q.getLastAcceleration().equals(new Vector3D(2.0f, -9.81f, 0.0f)), "Last acceleration recorded before clearing");
        passed &= expect(q.getTotalAcceleration().equals(new Vector3D()), "Accumulator cleared after recording");

        if (passed) println("GravityGenerator: All tests passed!");
    }
    
    void testImpulse() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        Particle p = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, false);
        p.applyImpulse(new Vector3D(4.0f, 0.0f, -2.0f));
        passed &= expect(p.getVelocity().equals(new Vector3D(2.0f, 0.0f, -1.0f)), "Impulse changes velocity by J/m");
        passed &= expect(p.getTotalAcceleration().equals(new Vector3D()), "Impulse bypasses the accumulator");

        // Infinite mass unaffected
        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        fixed.applyImpulse(new Vector3D(100.0f, 0.0f, 0.0f));
        passed &= expect(fixed.getVelocity().equals(new Vector3D()), "Impulse ignored for infinite mass");

        // Position Verlet: impulse must survive the next integration
        Particle v = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        v.integrate(dt, IntegrationMode.PositionVerlet);
        v.applyImpulse(new Vector3D(3.0f, 0.0f, 0.0f));
        v.integrate(dt, IntegrationMode.PositionVerlet);
        passed &= expect(MathHelpers.equalComponents(v.getPosition().getX(), 3.0f * dt), "Position Verlet moves with impulse velocity");
        passed &= expect(MathHelpers.equalComponents(v.getVelocity().getX(), 3.0f), "Position Verlet keeps impulse velocity");

        if (passed) println("Impulse: All tests passed!");
    }
    
    void testExplosion() {
        boolean passed = true;
        ArrayList<Particle> targets = new ArrayList<Particle>();

        Particle near     = new Particle(new Point3D(2.0f, 0.0f, 0.0f), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle far      = new Particle(new Point3D(5.0f, 0.0f, 0.0f), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle centered = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle fixed    = new Particle(new Point3D(1.0f, 0.0f, 0.0f), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        targets.add(near);
        targets.add(far);
        targets.add(centered);
        targets.add(fixed);

        applyExplosion(targets, new Point3D(), 4.0f, 10.0f);

        passed &= expect(near.getVelocity().equals(new Vector3D(5.0f, 0.0f, 0.0f)), "Explosion radial impulse with falloff");
        passed &= expect(far.getVelocity().equals(new Vector3D()), "Explosion ignores particles outside radius");
        passed &= expect(centered.getVelocity().equals(new Vector3D(0.0f, 10.0f, 0.0f)), "Explosion at exact center pushes up");
        passed &= expect(fixed.getVelocity().equals(new Vector3D()), "Explosion ignores infinite mass");

        if (passed) println("Explosion: All tests passed!");
    }
}
