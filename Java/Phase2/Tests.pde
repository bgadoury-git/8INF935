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
        testFriction();
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
        
        Vector3D v1 = new Vector3D(1.0f, 2.0f, 3.0f);
        passed &= expect(v1.getX() == 1.0f && v1.getY() == 2.0f && v1.getZ() == 3.0f, "Vector Initialization and Getters");
        
        v1.setX(4.0f); v1.setY(5.0f); v1.setZ(6.0f);
        passed &= expect(v1.getX() == 4.0f && v1.getY() == 5.0f && v1.getZ() == 6.0f, "Vector Setters");

        passed &= expect(Math.abs(new Vector3D(0.0f, 3.0f, 4.0f).length() - 5.0f) < 1e-5f, "Vector Length");
        passed &= expect(new Vector3D(0.0f, 3.0f, 4.0f).lengthSquared() == 25.0f, "Vector LengthSquared");

        Vector3D vToNorm = new Vector3D(0.0f, 3.0f, 4.0f);
        float len = vToNorm.normalize();
        passed &= expect(Math.abs(len - 5.0f) < 1e-5f && Math.abs(vToNorm.getY() - 0.6f) < 1e-5f, "Vector normalize (in-place)");
        
        Vector3D norm = new Vector3D(3.0f, 4.0f, 0.0f).normalized();
        passed &= expect(Math.abs(norm.getX() - 0.6f) < 1e-5f, "Vector normalized (new instance)");

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

        passed &= expect(d1.equals(new Vector3D(1.0f, 2.0f, 3.0f)), "Vector equals true");
        passed &= expect(!d1.equals(new Vector3D(1.0f, 2.0f, 4.0f)), "Vector equals false");
        passed &= expect(d1.toString().equals("Vector3D(1.0, 2.0, 3.0)"), "Vector toString format");

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
        
        Point3D p1 = new Point3D(1.0f, 2.0f, 3.0f);
        passed &= expect(p1.getX() == 1.0f && p1.getY() == 2.0f && p1.getZ() == 3.0f, "Point3D Init and Getters");
        
        p1.setX(4.0f); p1.setY(5.0f); p1.setZ(6.0f);
        passed &= expect(p1.getX() == 4.0f && p1.getY() == 5.0f && p1.getZ() == 6.0f, "Point3D Setters");

        Point3D pA = new Point3D(0.0f, 0.0f, 0.0f);
        Point3D pB = new Point3D(0.0f, 3.0f, 4.0f);
        passed &= expect(Math.abs(pA.distanceTo(pB) - 5.0f) < 1e-5f, "Point3D distanceTo");
        passed &= expect(pA.distanceSquaredTo(pB) == 25.0f, "Point3D distanceSquaredTo");

        passed &= expect(pA.add(new Vector3D(1.0f, 2.0f, 3.0f)).equals(new Point3D(1.0f, 2.0f, 3.0f)), "Point3D add(Vector)");
        passed &= expect(pB.sub(new Vector3D(0.0f, 3.0f, 4.0f)).equals(new Point3D(0.0f, 0.0f, 0.0f)), "Point3D sub(Vector)");
        passed &= expect(pB.sub(pA).equals(new Vector3D(0.0f, 3.0f, 4.0f)), "Point3D sub(Point)");

        passed &= expect(pB.equals(new Point3D(0.0f, 3.0f, 4.0f)), "Point3D equals true");
        passed &= expect(!pB.equals(new Point3D(0.0f, 3.0f, 5.0f)), "Point3D equals false");
        passed &= expect(pB.toString().equals("Point3D(0.0, 3.0, 4.0)"), "Point3D toString format");

        if (passed) println("Point3D: All tests passed!");
    }

    // --- Polar Tests ---
    void testPolar() {
        boolean passed = true;
        float pi = (float)Math.PI;

        Vector3D v = new Vector3D(new Polar(10.0f, 0.0f, 0.0f));
        passed &= expect(v.equals(new Vector3D(0.0f, 0.0f, 10.0f)), "Polar Constructor (+Z Forward)");

        v.setPolar(5.0f, pi / 2.0f, 0.0f);
        passed &= expect(v.equals(new Vector3D(5.0f, 0.0f, 0.0f)), "Polar setPolar (+X Right)");

        Vector3D vUp = new Vector3D(0.0f, 4.0f, 0.0f);
        Polar pUp = vUp.getPolar();
        passed &= expect(MathHelpers.equalComponents(pUp.radius, 4.0f) && 
                         MathHelpers.equalComponents(pUp.elevation, pi / 2.0f), "Polar getPolar (+Y Up)");

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
        passed &= expect(Math.abs(grav.getAcceleration().getY() - 2.0f) < 1e-5f, "Gravity flag does not alter constant acceleration");
        passed &= expect(grav.getAffectedByGravity(), "Gravity flag stored");
        
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

        int initialForces = forceRegistry.size();
        Particle la = springTestParticle(0, 0, 0);
        Particle lb = springTestParticle(10, 0, 0);
        ElasticLink link = new ElasticLink(la, lb, 10.0f, 2.0f, 4.0f);
        passed &= expect(forceRegistry.size() == initialForces + 2, "Elastic link: one force per particle");
        
        ArrayList<Particle> savedParticles = new ArrayList<Particle>(particles);
        particles.clear(); 
        particles.add(la);
        particles.add(lb);
        resolveCollisionsAndConstraints(1.0f / 60.0f);
        particles.clear();
        particles.addAll(savedParticles);
        
        passed &= expect(near(link.length(), 4.0f), "Elastic link behaves like a cable beyond its limit");
        link.breakLink();
        passed &= expect(forceRegistry.size() == initialForces && !cables.contains(link.cable), "Elastic link can be broken");

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
        float w0 = (float)Math.sqrt(k / mass);                 
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

        Particle stiff = new Particle(new Point3D(1, 0, 0), new Vector3D(), new Vector3D(), mass, 1.0f, false);
        float cStiff = 0.5f * 2.0f * (float)Math.sqrt(mass * k);
        new ParticleStiffSpring(new Point3D(0, 0, 0), k, cStiff).updateForce(stiff, dt);
        float expectedStiff = dampedHarmonicPosition(new Vector3D(1, 0, 0), new Vector3D(), k, cStiff, mass, dt).getX();
        float accelX = stiff.getForceAccumulator().getX() * stiff.getInverseMass();
        passed &= expect(near(1.0f + accelX * dt * dt, expectedStiff), "Stiff spring follows damped harmonic motion");

        Particle mPart = springTestParticle(0, 0, 0);
        Particle nPart = springTestParticle(4, 0, 0);
        ParticleSpring sm = new ParticleSpring(nPart, 10.0f, 2.0f);
        ParticleSpring sn = new ParticleSpring(mPart, 10.0f, 2.0f);
        
        ForceRegistry testReg = new ForceRegistry();
        testReg.add(mPart, sm);
        testReg.add(nPart, sn);
        
        passed &= expect(testReg.size() == 2, "Two-way spring simulation: one force per particle");
        testReg.updateForces(dt);
        
        passed &= expect(near(mPart.getForceAccumulator().getX(), 20.0f) && near(nPart.getForceAccumulator().getX(), -20.0f),
                         "Two-way spring: equal and opposite forces");
        mPart.integrate(dt, IntegrationMode.Euler);
        passed &= expect(mPart.getForceAccumulator().lengthSquared() == 0.0f, "Accumulator cleared after integration");
        passed &= expect(mPart.getVelocity().getX() > 0.0f, "Spring force changes velocity");

        if (passed) println("Springs: All tests passed!");
    }


    // --- Friction Tests ---
    // Chaque test compare la simulation à un résultat analytique connu.
    // Les coefficients attendus sont lus dans PhysicsMaterials : les tests suivent la table.

    void testFriction() {
        boolean passed = true;
        passed &= testContactFrictionGenerator();
        passed &= testDragGenerator();
        for (IntegrationMode mode : IntegrationMode.values()) {
            passed &= testFrictionWithCollisions(mode);
        }
        if (passed) println("Friction: All tests passed!");
    }

    // Sol immobile (masse infinie) et bloc, pour tester le générateur sans le résolveur.
    // Normale du contact : de p1 (sol) vers p2 (bloc), donc vers le haut.
    Particle makeGround(Material material) {
        Particle ground = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        ground.setMaterial(material);
        return ground;
    }

    Particle makeBlock(float mass, Vector3D velocity, Material material) {
        Particle block = new Particle(new Point3D(0.0f, 1.0f, 0.0f), velocity, new Vector3D(), mass, 1.0f, false);
        block.setMaterial(material);
        return block;
    }

    boolean testContactFrictionGenerator() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;
        float g = PhysicsConstants.GRAVITY;
        float m = 2.0f;
        float normalForce = m * g; // contact au repos : le poids
        Vector3D up = new Vector3D(0.0f, 1.0f, 0.0f);

        MaterialInteraction steelEarth = PhysicsMaterials.get(Material.STEEL, Material.EARTH);
        float mu_s = steelEarth.staticFriction;
        float mu_k = steelEarth.kineticFriction;

        // 1. STATIQUE : F_stop = m*v_t/dt = 0.5 * mu_s * N  <=  mu_s * N -> la force arrête le bloc net
        ContactFrictionGenerator gen = new ContactFrictionGenerator();
        Particle ground = makeGround(Material.EARTH);
        Particle block = makeBlock(m, new Vector3D(0.5f * mu_s * g * dt, 0.0f, 0.0f), Material.STEEL);
        gen.applyContact(ground, block, up, normalForce, dt);
        passed &= expect(Math.abs(block.getForceAccumulator().getX() + 0.5f * mu_s * normalForce) < 1e-3f, "Contact friction static: force = m*v_t/dt, opposite to sliding");
        passed &= expect(gen.getState(block) == ContactState.Static, "Contact friction static: state is Static");
        block.integrate(dt, IntegrationMode.Euler);
        passed &= expect(Math.abs(block.getVelocity().getX()) < 1e-4f, "Contact friction static: slow block is stopped by the force");

        // 2. CINÉTIQUE : v_t = 5 m/s -> force = mu_k * N ; aucune composante normale
        gen = new ContactFrictionGenerator();
        ground = makeGround(Material.EARTH);
        block = makeBlock(m, new Vector3D(5.0f, -1.0f, 0.0f), Material.STEEL);
        gen.applyContact(ground, block, up, normalForce, dt);
        passed &= expect(Math.abs(block.getForceAccumulator().getX() + mu_k * normalForce) < 1e-3f, "Contact friction kinetic: force = mu_k * N");
        passed &= expect(Math.abs(block.getForceAccumulator().getY()) < 1e-6f, "Contact friction: no normal component");
        passed &= expect(gen.getState(block) == ContactState.Sliding, "Contact friction kinetic: state is Sliding");

        // 3. LA TABLE EST UTILISÉE : un bloc de caoutchouc freine plus qu'un bloc d'acier
        MaterialInteraction rubberEarth = PhysicsMaterials.get(Material.RUBBER, Material.EARTH);
        gen = new ContactFrictionGenerator();
        ground = makeGround(Material.EARTH);
        Particle rubber = makeBlock(m, new Vector3D(5.0f, 0.0f, 0.0f), Material.RUBBER);
        gen.applyContact(ground, rubber, up, normalForce, dt);
        passed &= expect(Math.abs(rubber.getForceAccumulator().getX() + rubberEarth.kineticFriction * normalForce) < 1e-3f, "Contact friction uses the material table (RUBBER/EARTH)");
        passed &= expect(rubber.getForceAccumulator().getX() < block.getForceAccumulator().getX(), "Contact friction: rubber brakes more than steel");

        // 4. SYMÉTRIE : l'ordre (p1, p2) ne change pas le résultat
        gen = new ContactFrictionGenerator();
        ground = makeGround(Material.EARTH);
        block = makeBlock(m, new Vector3D(5.0f, 0.0f, 0.0f), Material.STEEL);
        gen.applyContact(block, ground, up.negate(), normalForce, dt);
        passed &= expect(Math.abs(block.getForceAccumulator().getX() + mu_k * normalForce) < 1e-3f, "Contact friction is symmetric in (p1, p2)");

        // 5. PAS DE FORCE NORMALE : aucune friction
        gen = new ContactFrictionGenerator();
        ground = makeGround(Material.EARTH);
        block = makeBlock(m, new Vector3D(5.0f, 0.0f, 0.0f), Material.STEEL);
        gen.applyContact(ground, block, up, 0.0f, dt);
        passed &= expect(block.getForceAccumulator().length() == 0.0f, "Contact friction: none without normal force");

        // 6. DÉSACTIVÉ (touche [C])
        gen = new ContactFrictionGenerator();
        gen.setEnabled(false);
        ground = makeGround(Material.EARTH);
        block = makeBlock(m, new Vector3D(5.0f, 0.0f, 0.0f), Material.STEEL);
        gen.applyContact(ground, block, up, normalForce, dt);
        passed &= expect(block.getForceAccumulator().length() == 0.0f, "Contact friction: disabled adds nothing");

        // 7. DEUX MASSES MOBILES : forces égales et opposées, et un contact assez pressé les fait
        //    glisser ensemble (statique) avec conservation de la quantité de mouvement tangentielle
        gen = new ContactFrictionGenerator();
        Particle a = makeBlock(1.0f, new Vector3D(3.0f, 0.0f, 0.0f), Material.STEEL);
        Particle b = makeBlock(3.0f, new Vector3D(0.0f, 0.0f, 0.0f), Material.STEEL);
        float momentumBefore = a.getMass() * a.getVelocity().getX() + b.getMass() * b.getVelocity().getX();
        gen.applyContact(a, b, up, 1000.0f, dt);
        passed &= expect(a.getForceAccumulator().add(b.getForceAccumulator()).length() < 1e-3f, "Contact friction: equal and opposite forces on both particles");
        a.integrate(dt, IntegrationMode.Euler);
        b.integrate(dt, IntegrationMode.Euler);
        float momentumAfter = a.getMass() * a.getVelocity().getX() + b.getMass() * b.getVelocity().getX();
        passed &= expect(Math.abs(momentumAfter - momentumBefore) < 1e-3f, "Contact friction conserves tangential momentum");
        passed &= expect(Math.abs(a.getVelocity().getX() - b.getVelocity().getX()) < 1e-3f, "Contact friction: two particles stick together");

        // 8. JAMAIS D'INVERSION : même avec une force normale gigantesque (mu*N >> F_stop)
        gen = new ContactFrictionGenerator();
        ground = makeGround(Material.EARTH);
        block = makeBlock(m, new Vector3D(0.05f, 0.0f, 0.0f), Material.RUBBER);
        gen.applyContact(ground, block, up, 1.0e6f, dt);
        block.integrate(dt, IntegrationMode.Euler);
        passed &= expect(Math.abs(block.getVelocity().getX()) < 1e-4f, "Contact friction never reverses the sliding");

        return passed;
    }

    boolean testDragGenerator() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        // Force instantanée : f = -(k1 |v| + k2 |v|^2) v^ = -(5 + 10) = -15 selon X
        Particle p = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 1.0f, 1.0f, false);
        new DragForceGenerator(0.5f, 0.1f).updateForce(p, dt);
        passed &= expect(p.getForceAccumulator().equals(new Vector3D(-15.0f, 0.0f, 0.0f)), "Drag force = -(k1|v| + k2|v|^2) v^");

        Particle still = new Particle();
        new DragForceGenerator(1.0f, 1.0f).updateForce(still, dt);
        passed &= expect(still.getForceAccumulator().length() == 0.0f, "Drag is zero at rest");

        // Garde-fou : une traînée gigantesque arrête la particule, elle ne la fait pas reculer
        Particle fast = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 2.0f, 1.0f, false);
        new DragForceGenerator(1.0e6f, 0.0f).updateForce(fast, dt);
        float maxStop = 2.0f * 10.0f / dt; // m |v| / dt
        passed &= expect(Math.abs(fast.getForceAccumulator().length() - maxStop) < 1e-2f * maxStop, "Drag is clamped to m|v|/dt");
        fast.integrate(dt, IntegrationMode.Euler);
        passed &= expect(fast.getVelocity().getX() > -1e-3f, "Drag never reverses velocity");

        // Masse infinie : ignorée
        Particle wall = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 0.0f, 1.0f, false);
        new DragForceGenerator(1.0f, 1.0f).updateForce(wall, dt);
        passed &= expect(wall.getForceAccumulator().length() == 0.0f, "Drag ignores infinite-mass particles");

        // Désactivé (touche [C])
        Particle off = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 1.0f, 1.0f, false);
        DragForceGenerator disabled = new DragForceGenerator(1.0f, 1.0f);
        disabled.setEnabled(false);
        disabled.updateForce(off, dt);
        passed &= expect(off.getForceAccumulator().length() == 0.0f, "Drag: disabled adds no force");

        // Vitesse terminale avec les 3 intégrateurs : F = 10 N, k1 = 1, k2 = 1 -> v + v^2 = 10
        float terminal = (-1.0f + (float)Math.sqrt(41.0f)) / 2.0f;
        for (IntegrationMode mode : IntegrationMode.values()) {
            Particle fall = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
            ForceRegistry registry = new ForceRegistry();
            registry.add(fall, new ConstantForceGenerator(new Vector3D(10.0f, 0.0f, 0.0f)));
            registry.add(fall, new DragForceGenerator(1.0f, 1.0f));
            for (int i = 0; i < 60 * 15; i++) {
                registry.updateForces(dt);
                fall.integrate(dt, mode);
            }
            passed &= expect(Math.abs(fall.getVelocity().getX() - terminal) < 0.01f * terminal, "Drag terminal velocity (k1 + k2) [" + mode.name() + "]");
        }
        return passed;
    }

    // Résultat d'une simulation de glissement
    class SlideResult {
        float z;            // déplacement selon Z pendant la simulation (après la mise au repos)
        float vz;           // vitesse finale selon Z
        float minVz;        // vitesse minimale rencontrée (détecte un recul)
        ContactState state; // état de contact final de la balle
    }

    // Balle posée sur la vraie Terre, avec le VRAI résolveur de collisions (resolveCollisionsAndConstraints),
    // la vraie gravité (GravityGenerator) et, si demandé, une poussée (ConstantForceGenerator).
    // Même boucle que le jeu : générateurs -> intégration -> collisions.
    // Si la balle part du repos (v0 = 0), on la laisse d'abord se poser 0.5 s : dans le jeu, une force
    // latérale s'applique à un objet déjà en contact, pas à un objet posé "pile" sur la surface.
    SlideResult simulateSlide(IntegrationMode mode, Material material, float v0, float push, float seconds) {
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        // On met la scène du jeu de côté le temps du test
        ArrayList<Particle> savedParticles = new ArrayList<Particle>(particles);
        ArrayList<Cable> savedCables = new ArrayList<Cable>(cables);
        particles.clear();
        cables.clear();

        Earth ground = new Earth(new Point3D(0.0f, -6371000.0f, 0.0f));
        RedSphere ball = new RedSphere(new Point3D(0.0f, 1.0f, 0.0f), new Vector3D(0.0f, 0.0f, v0));
        ball.setMaterial(material);
        particles.add(ground);
        particles.add(ball);

        ForceRegistry registry = new ForceRegistry();
        registry.add(ball, new GravityGenerator(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f)));
        ConstantForceGenerator pusher = new ConstantForceGenerator(new Vector3D(0.0f, 0.0f, push));
        pusher.setActive(false);
        registry.add(ball, pusher);

        if (v0 == 0.0f) {
            for (int i = 0; i < 30; i++) {
                registry.updateForces(dt);
                ball.integrate(dt, mode);
                resolveCollisionsAndConstraints(dt);
            }
        }
        float startZ = ball.getPosition().getZ();
        pusher.setActive(push != 0.0f);

        SlideResult r = new SlideResult();
        r.minVz = v0;
        int steps = Math.round(seconds / dt);
        for (int i = 0; i < steps; i++) {
            registry.updateForces(dt);
            ball.integrate(dt, mode);
            resolveCollisionsAndConstraints(dt);
            r.minVz = Math.min(r.minVz, ball.getVelocity().getZ());
        }
        r.z = ball.getPosition().getZ() - startZ;
        r.vz = ball.getVelocity().getZ();
        r.state = contactFriction.getState(ball);

        // On remet la scène du jeu
        particles.clear();
        cables.clear();
        particles.addAll(savedParticles);
        cables.addAll(savedCables);
        return r;
    }

    boolean testFrictionWithCollisions(IntegrationMode mode) {
        boolean passed = true;
        String tag = " [" + mode.name() + "]";
        float g = PhysicsConstants.GRAVITY;
        float m = new RedSphere(new Point3D(), new Vector3D()).getMass();
        boolean wasEnabled = contactFriction.isEnabled();
        contactFriction.setEnabled(true);

        MaterialInteraction steelEarth = PhysicsMaterials.get(Material.STEEL, Material.EARTH);
        float mu_s = steelEarth.staticFriction;
        float mu_k = steelEarth.kineticFriction;

        // 1. FREINAGE : v0 = 5 m/s, a = -mu_k*g, distance = v0^2 / (2 mu_k g)
        float v0 = 5.0f;
        float expectedDistance = (v0 * v0) / (2.0f * mu_k * g);
        SlideResult br = simulateSlide(mode, Material.STEEL, v0, 0.0f, 4.0f);
        passed &= expect(Math.abs(br.z - expectedDistance) < 0.05f * expectedDistance, "Collisions + friction: braking distance v0^2/(2 mu_k g)" + tag);
        passed &= expect(Math.abs(br.vz) < 1e-3f, "Collisions + friction: ball fully stops" + tag);
        passed &= expect(br.minVz >= -1e-4f, "Collisions + friction: velocity never reverses" + tag);

        // 2. LA TABLE : un caoutchouc (mu_k plus élevé) s'arrête plus court qu'un acier
        SlideResult rubber = simulateSlide(mode, Material.RUBBER, v0, 0.0f, 4.0f);
        passed &= expect(rubber.z < br.z, "Collisions + friction: rubber stops shorter than steel" + tag);

        // 3. SANS FRICTION : la balle ne ralentit pas (le générateur est bien ce qui freine)
        contactFriction.setEnabled(false);
        SlideResult free = simulateSlide(mode, Material.STEEL, v0, 0.0f, 2.0f);
        passed &= expect(free.vz > 0.95f * v0, "Collisions without friction: ball keeps its speed" + tag);
        contactFriction.setEnabled(true);

        // 4. POUSSÉE SOUS LE SEUIL STATIQUE (90 % de mu_s*m*g) : la balle ne doit pas partir.
        //    Elle avance très lentement (la friction ne voit pas la poussée du pas suivant, voir
        //    ContactFrictionGenerator), mais sa vitesse reste faible et son déplacement limité.
        float holdPush = 0.9f * mu_s * m * g;
        SlideResult hold = simulateSlide(mode, Material.STEEL, 0.0f, holdPush, 2.0f);
        passed &= expect(Math.abs(hold.vz) < 0.15f && Math.abs(hold.z) < 0.5f, "Collisions + friction: static friction holds at 90% of mu_s*m*g" + tag);

        // 5. POUSSÉE AU-DESSUS : a = (F - mu_k*m*g)/m
        float strongPush = 2.0f * mu_s * m * g;
        float aExpected = (strongPush - mu_k * m * g) / m;
        SlideResult go = simulateSlide(mode, Material.STEEL, 0.0f, strongPush, 1.0f);
        passed &= expect(Math.abs(go.vz - aExpected) < 0.03f * aExpected, "Collisions + friction: acceleration (F - mu_k m g)/m" + tag);
        passed &= expect(go.state == ContactState.Sliding, "Collisions + friction: state is Sliding" + tag);

        contactFriction.setEnabled(wasEnabled);
        return passed;
    }

    // --- Force Accumulator and Generator Tests ---
    void testForceAccumulator() {
        boolean passed = true;

        Particle pA = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, false);
        pA.addForce(new Vector3D(0.0f, 10.0f, 0.0f));
        pA.addForce(new Vector3D(4.0f, 0.0f, -2.0f));
        passed &= expect(pA.getTotalAcceleration().equals(new Vector3D(2.0f, 5.0f, -1.0f)), "Force superposition");

        pA.integrate(0.1f, IntegrationMode.Euler);
        passed &= expect(pA.getPosition().equals(new Point3D(0.0f, 0.0f, 0.0f)), "Euler position uses old velocity");
        passed &= expect(pA.getVelocity().equals(new Vector3D(0.2f, 0.5f, -0.1f)), "Euler velocity from net force");
        passed &= expect(pA.getTotalAcceleration().equals(new Vector3D()), "Accumulator cleared after integrate");

        pA.integrate(0.1f, IntegrationMode.Euler);
        passed &= expect(pA.getPosition().equals(new Point3D(0.02f, 0.05f, -0.01f)), "No force: position advances");
        passed &= expect(pA.getVelocity().equals(new Vector3D(0.2f, 0.5f, -0.1f)), "No force: velocity unchanged");

        Particle pD = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Vector3D g = new Vector3D(0.0f, 10.0f, 0.0f);
        pD.addForce(g);
        pD.addForce(g);
        passed &= expect(pD.getTotalAcceleration().equals(new Vector3D(0.0f, 20.0f, 0.0f)), "Same force added twice");
        passed &= expect(g.equals(new Vector3D(0.0f, 10.0f, 0.0f)), "addForce does not modify its argument");

        Particle pE = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        pE.addForce(new Vector3D(100.0f, 100.0f, 100.0f));
        pE.integrate(0.1f, IntegrationMode.PositionVerlet);
        passed &= expect(pE.getPosition().equals(new Point3D(0.0f, 0.0f, 0.0f)), "Infinite mass does not move");
        pE.setInverseMass(1.0f);
        passed &= expect(pE.getTotalAcceleration().equals(new Vector3D()), "Infinite mass accumulator cleared");

        Particle pF = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, true);
        new GravityGenerator(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f)).updateForce(pF, 0.1f);
        pF.addForce(new Vector3D(0.0f, 39.24f, 0.0f));
        passed &= expect(pF.getTotalAcceleration().equals(new Vector3D(0.0f, 9.81f, 0.0f)), "Gravity force plus thrust");

        Particle pG = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        pG.addForce(new Vector3D(2.0f, 0.0f, 0.0f));
        pG.integrate(0.5f, IntegrationMode.VelocityVerlet);
        passed &= expect(MathHelpers.equalComponents(pG.getPosition().getX(), 0.25f), "Velocity Verlet drift uses force");
        passed &= expect(MathHelpers.equalComponents(pG.getVelocity().getX(), 1.0f), "Velocity Verlet kick uses force");

        if (passed) println("Force Accumulator: All tests passed!");
    }
    
    void testForceGeneratorInterface() {
        boolean passed = true;
        
        ForceGenerator upward = new ForceGenerator() {
            @Override
            public void updateForce(Particle particle, float deltaTime) {
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

        reg.add(p1, up5);
        reg.add(p1, right3);
        reg.add(p2, up5);
        reg.add(p1, up5);
        passed &= expect(reg.size() == 3, "Registry ignores duplicate pair");

        reg.updateForces(dt);
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D(3.0f, 5.0f, 0.0f)), "Registry applies all generators to p1");
        passed &= expect(p2.getTotalAcceleration().equals(new Vector3D(0.0f, 5.0f, 0.0f)), "Shared generator serves p2");

        p1.clearAccumulator(); p2.clearAccumulator();
        reg.remove(p1, up5);
        reg.updateForces(dt);
        passed &= expect(reg.size() == 2, "Remove one pair");
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D(3.0f, 0.0f, 0.0f)), "Removed generator no longer applies");

        p1.clearAccumulator(); p2.clearAccumulator();
        reg.add(p1, up5);
        reg.removeParticle(p1);
        reg.updateForces(dt);
        passed &= expect(reg.size() == 1, "Remove all registrations of a particle");
        passed &= expect(p1.getTotalAcceleration().equals(new Vector3D()), "Removed particle receives no force");
        passed &= expect(p2.getTotalAcceleration().equals(new Vector3D(0.0f, 5.0f, 0.0f)), "Other particle unaffected");

        reg.clear();
        passed &= expect(reg.size() == 0, "Clear registry");

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

        Particle light = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        Particle heavy = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 5.0f, 1.0f, false);
        wind.updateForce(light, dt);
        wind.updateForce(heavy, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(10.0f, 0.0f, 0.0f)), "Constant force on 1 kg");
        passed &= expect(heavy.getTotalAcceleration().equals(new Vector3D(2.0f, 0.0f, 0.0f)), "Constant force on 5 kg is weaker");

        light.clearAccumulator();
        wind.setActive(false);
        wind.updateForce(light, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D()), "Inactive generator applies no force");

        Vector3D f = new Vector3D(0.0f, 0.0f, 3.0f);
        wind.setForce(f);
        f.setZ(100.0f);
        wind.setActive(true);
        wind.updateForce(light, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(0.0f, 0.0f, 3.0f)), "setForce copies the vector");

        wind.getForce().setX(999.0f);
        passed &= expect(wind.getForce().equals(new Vector3D(0.0f, 0.0f, 3.0f)), "getForce returns a copy");

        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        wind.updateForce(fixed, dt);
        fixed.setInverseMass(1.0f);
        passed &= expect(fixed.getTotalAcceleration().equals(new Vector3D()), "Constant force skips infinite mass");

        if (passed) println("ConstantForceGenerator: All tests passed!");
    }
    
    void testGravityGenerator() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        Vector3D src = new Vector3D(0.0f, -9.81f, 0.0f);
        GravityGenerator gravity = new GravityGenerator(src);
        Particle light = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 2.0f, 1.0f, true);
        Particle heavy = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 5.0f, 1.0f, true);
        gravity.updateForce(light, dt);
        gravity.updateForce(heavy, dt);
        passed &= expect(light.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity on 2 kg gives g");
        passed &= expect(heavy.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity on 5 kg gives g");

        src.setY(-100.0f);
        Particle p = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, true);
        gravity.updateForce(p, dt);
        passed &= expect(p.getTotalAcceleration().equals(new Vector3D(0.0f, -9.81f, 0.0f)), "Gravity vector defensively copied");

        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, true);
        gravity.updateForce(fixed, dt);
        fixed.setInverseMass(1.0f);
        passed &= expect(fixed.getTotalAcceleration().equals(new Vector3D()), "Gravity skips infinite mass");

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

        Particle fixed = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        fixed.applyImpulse(new Vector3D(100.0f, 0.0f, 0.0f));
        passed &= expect(fixed.getVelocity().equals(new Vector3D()), "Impulse ignored for infinite mass");

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
    
    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
        }
        return condition;
    }
}
