// ==========================================
// Translated Physics Unit Tests
// ==========================================

class Tests {

    void run() {
        testPoint3D();
        testVector3D();
        testPolar();
        testParticle();
        testSprings(); 
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
        float expectedYWithGravity = 2.0f - PhysicsConstants.GRAVITY;
        passed &= expect(Math.abs(grav.getAcceleration().getY() - expectedYWithGravity) < 1e-5f, "Particle Gravity");
        
        Particle noMass = new Particle(new Point3D(10,20,30), new Vector3D(100,100,100), new Vector3D(), 0.0f, 1.0f, false);
        noMass.applyVerletIntegration(0.1f);
        passed &= expect(noMass.getPosition().equals(new Point3D(10,20,30)), "Particle Zero Mass (Infinite Mass)");
        
        if (passed) println("Particle: All tests passed!");
    }

  // --- Spring Tests ---
    boolean near(float a, float b) { return Math.abs(a - b) < 1e-3f; }

    Particle springTestParticle(float x, float y, float z) {
        return new Particle(new Point3D(x, y, z), new Vector3D(), new Vector3D(), 2.0f, 1.0f, false);
    }

    void testSprings() {
        boolean passed = true;

        Particle a = springTestParticle(0, 0, 0);
        Particle b = springTestParticle(3, 0, 0);
        ParticleSpring s = new ParticleSpring(b, 10.0f, 2.0f);
        s.updateForce(a, 0.016f);
        passed &= expect(near(a.getForceAccumulator().getX(), 10.0f), "Spring stretched pulls toward other end");
        a.clearAccumulator();

        b.setPosition(new Point3D(1, 0, 0));
        s.updateForce(a, 0.016f);
        passed &= expect(near(a.getForceAccumulator().getX(), -10.0f), "Spring compressed pushes away");
        a.clearAccumulator();

        s.elasticLimit = 4.0f;
        b.setPosition(new Point3D(4, 0, 0));
        s.updateForce(a, 0.016f);
        passed &= expect(near(a.getForceAccumulator().getX(), 20.0f), "Spring active up to elastic limit");
        a.clearAccumulator();
        b.setPosition(new Point3D(10, 0, 0));
        s.updateForce(a, 0.016f);
        passed &= expect(s.isBeyondElasticLimit(a), "Spring detects elastic limit");
        passed &= expect(a.getForceAccumulator().lengthSquared() == 0.0f, "Beyond elastic limit: no spring force (cable)");
        a.clearAccumulator();

        ArrayList<ForceBinding> savedForces = new ArrayList<ForceBinding>(activeForces);
        activeForces.clear();
        Particle la = springTestParticle(0, 0, 0);
        Particle lb = springTestParticle(10, 0, 0);
        ElasticLink link = new ElasticLink(la, lb, 10.0f, 2.0f, 4.0f);
        passed &= expect(activeForces.size() == 2, "Elastic link: one force per particle");
        ArrayList<Particle> savedParticles = new ArrayList<Particle>(particles);
        particles.clear(); // on isole le test des particules du jeu
        resolveCollisionsAndConstraints(1.0f / 60.0f);
        particles.addAll(savedParticles);
        passed &= expect(near(link.length(), 4.0f), "Elastic link behaves like a cable beyond its limit");
        link.breakLink();
        passed &= expect(activeForces.size() == 0 && !cables.contains(link.cable), "Elastic link can be broken");

        Particle e = springTestParticle(0, -5, 0);
        new ParticleAnchoredSpring(new Point3D(0, 0, 0), 4.0f, 3.0f).updateForce(e, 0.016f);
        passed &= expect(near(e.getForceAccumulator().getY(), 8.0f), "Anchored spring pulls toward anchor");

        Particle f = springTestParticle(0, 0, 0);
        Particle g = springTestParticle(1, 0, 0);
        ParticleBungee bungee = new ParticleBungee(g, 10.0f, 2.0f);
        bungee.updateForce(f, 0.016f);
        passed &= expect(f.getForceAccumulator().lengthSquared() == 0.0f, "Bungee slack gives no force");
        g.setPosition(new Point3D(5, 0, 0));
        bungee.updateForce(f, 0.016f);
        passed &= expect(near(f.getForceAccumulator().getX(), 30.0f), "Bungee taut pulls");

        Particle h = springTestParticle(0, 1, 0);
        new ParticleAnchoredBungee(new Point3D(0, 0, 0), 10.0f, 2.0f).updateForce(h, 0.016f);
        passed &= expect(h.getForceAccumulator().lengthSquared() == 0.0f, "Anchored bungee slack gives no force");

        ParticleBuoyancy buoy = new ParticleBuoyancy(0.5f, 0.001f, 0.0f);
        Particle above = springTestParticle(0, 2, 0);
        Particle half = springTestParticle(0, 0, 0);
        Particle under = springTestParticle(0, -2, 0);
        buoy.updateForce(above, 0.016f);
        buoy.updateForce(half, 0.016f);
        buoy.updateForce(under, 0.016f);
        float full = 1000.0f * 0.001f * PhysicsConstants.GRAVITY;
        passed &= expect(above.getForceAccumulator().lengthSquared() == 0.0f, "Buoyancy out of water");
        passed &= expect(near(half.getForceAccumulator().getY(), full * 0.5f), "Buoyancy half submerged");
        passed &= expect(near(under.getForceAccumulator().getY(), full), "Buoyancy fully submerged");

        float dt = 1.0f / 60.0f;
        float k = 800.0f, mass = 2.0f;
        float w0 = (float)Math.sqrt(k / mass);                   // ω0 = 20 rad/s
        Vector3D xs = dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, 0.0f, mass, 0.1f);
        passed &= expect(near(xs.getX(), (float)Math.cos(w0 * 0.1f)), "Undamped SHM: x(t) = A cos(w0 t)");
        float zeta = 0.5f, c = zeta * 2.0f * (float)Math.sqrt(mass * k);
        float wd = w0 * (float)Math.sqrt(1 - zeta * zeta);
        float expectedUnder = (float)((Math.cos(wd * 0.1) + (zeta * w0 / wd) * Math.sin(wd * 0.1)) * Math.exp(-zeta * w0 * 0.1));
        xs = dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, c, mass, 0.1f);
        passed &= expect(near(xs.getX(), expectedUnder), "Underdamped SHM formula");
        c = 2.0f * (float)Math.sqrt(mass * k);
        xs = dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, c, mass, 0.1f);
        passed &= expect(near(xs.getX(), (float)((1 + w0 * 0.1) * Math.exp(-w0 * 0.1))), "Critically damped SHM formula");
        passed &= expect(dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, 3 * c, mass, 0.1f) == null, "Overdamped not handled");

        // Ressort rigide : après un pas de Verlet, la particule est à x(dt)
        Particle stiff = new Particle(new Point3D(1, 0, 0), new Vector3D(), new Vector3D(), mass, 1.0f, false);
        float cStiff = 0.5f * 2.0f * (float)Math.sqrt(mass * k);
        new ParticleStiffSpring(new Point3D(0, 0, 0), k, cStiff).updateForce(stiff, dt);
        float expectedStiff = dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, cStiff, mass, dt).getX();
        float accelX = stiff.getForceAccumulator().getX() * stiff.getInverseMass();
        passed &= expect(near(1.0f + accelX * dt * dt, expectedStiff), "Stiff spring follows damped harmonic motion");

        Particle m = springTestParticle(0, 0, 0);
        Particle n = springTestParticle(4, 0, 0);
        connectWithSpring(m, n, 10.0f, 2.0f);
        passed &= expect(activeForces.size() == 2, "connectWithSpring: one force per particle");
        ParticleForceRegistry reg = new ParticleForceRegistry();
        applyForces(reg, dt);
        passed &= expect(reg.size() == 0, "Registry cleared each frame");
        passed &= expect(near(m.getForceAccumulator().getX(), 20.0f) && near(n.getForceAccumulator().getX(), -20.0f),
                         "Two-way spring: equal and opposite forces");
        m.integrate(dt, IntegrationMode.Euler);
        passed &= expect(m.getForceAccumulator().lengthSquared() == 0.0f, "Accumulator cleared after integration");
        passed &= expect(m.getVelocity().getX() > 0.0f, "Spring force changes velocity");
        activeForces.clear();
        activeForces.addAll(savedForces);

        if (passed) println("Springs: All tests passed!");
    }

    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
        }
        return condition;
    }
}
