// ==========================================
// Translated Physics Unit Tests
// ==========================================

class Tests {

    void run() {
        testPoint3D();
        testVector3D();
        testPolar();
        testParticle();
        testFriction();
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


    // --- Friction Tests ---
    // Chaque test compare la simulation a un resultat analytique connu.

    // Resultat d'une simulation de bloc sur un plan
    class SlideResult {
        float x;            // position finale selon X
        float vx;           // vitesse finale selon X
        float minVx;        // vitesse minimale rencontree (detecte un recul)
        ContactState state; // etat de contact final
    }

    // Bloc pose sur le plan y = 0 (rayon 1 -> centre a y = 1, ecart = 0).
    // Sans gravite integree : le poids est fourni comme une force externe,
    // comme le ferait un generateur de gravite.
    SlideResult simulateBlock(IntegrationMode mode, float mass, float v0,
                              float pushX, float pushY, float seconds,
                              float mu_s, float mu_k) {
        float dt = PhysicsConstants.FIXED_TIMESTEP;
        Particle block = new Particle(new Point3D(0.0f, 1.0f, 0.0f), new Vector3D(v0, 0.0f, 0.0f),
                                      new Vector3D(), mass, 1.0f, false);
        PlaneSurface plane = new PlaneSurface(new Point3D(0.0f, 0.0f, 0.0f), new Vector3D(0.0f, 1.0f, 0.0f));
        CoulombFrictionGenerator coulomb = new CoulombFrictionGenerator(plane, mu_s, mu_k);

        ForceRegistry registry = new ForceRegistry();
        registry.add(block, new TestConstantForce(new Vector3D(0.0f, -mass * PhysicsConstants.GRAVITY, 0.0f)));
        registry.add(block, new TestConstantForce(new Vector3D(pushX, pushY, 0.0f)));
        registry.add(block, coulomb);

        SlideResult r = new SlideResult();
        r.minVx = v0;
        int steps = Math.round(seconds / dt);
        for (int i = 0; i < steps; i++) {
            registry.updateForces(dt);
            block.integrate(dt, mode);
            block.clearForceAccumulator();
            // Le plan joue le role de la collision : on annule la composante verticale
            block.getPosition().setY(1.0f);
            block.setVelocity(new Vector3D(block.getVelocity().getX(), 0.0f, 0.0f));
            r.minVx = Math.min(r.minVx, block.getVelocity().getX());
        }
        r.x = block.getPosition().getX();
        r.vx = block.getVelocity().getX();
        r.state = coulomb.getState();
        return r;
    }

    boolean testFrictionAllModes(IntegrationMode mode) {
        boolean passed = true;
        String tag = " [" + mode.name() + "]";
        float g = PhysicsConstants.GRAVITY;
        float m = 2.0f;
        float mu_s = 0.6f;
        float mu_k = 0.4f;
        float N = m * g;

        // 1. STATIQUE : poussee sous le seuil mu_s*N (11.77 N) -> aucun mouvement
        SlideResult st = simulateBlock(mode, m, 0.0f, 0.5f * mu_s * N, 0.0f, 2.0f, mu_s, mu_k);
        passed &= expect(Math.abs(st.x) < 1e-3f && Math.abs(st.vx) < 1e-3f, "Coulomb static: block stays at rest below mu_s*N" + tag);
        passed &= expect(st.state == ContactState.Static, "Coulomb static: state is Static" + tag);

        // 2. SEUIL DEPASSE : poussee de 20 N > 11.77 N -> glisse avec a = (F - mu_k*N)/m
        float push = 20.0f;
        float aExpected = (push - mu_k * N) / m;
        SlideResult mv = simulateBlock(mode, m, 0.0f, push, 0.0f, 1.0f, mu_s, mu_k);
        passed &= expect(Math.abs(mv.vx - aExpected * 1.0f) < 0.02f * aExpected, "Coulomb kinetic: acceleration (F - mu_k N)/m" + tag);
        passed &= expect(mv.state == ContactState.Sliding, "Coulomb kinetic: state is Sliding" + tag);

        // 3. FREINAGE : v0 = 5 m/s, a = -mu_k*g, distance = v0^2 / (2 mu_k g)
        float v0 = 5.0f;
        float expectedDistance = (v0 * v0) / (2.0f * mu_k * g);
        SlideResult br = simulateBlock(mode, m, v0, 0.0f, 0.0f, 3.0f, mu_s, mu_k);
        passed &= expect(Math.abs(br.x - expectedDistance) < 0.05f * expectedDistance, "Coulomb braking distance v0^2/(2 mu_k g)" + tag);
        passed &= expect(Math.abs(br.vx) < 1e-3f, "Coulomb braking: block fully stops" + tag);
        passed &= expect(br.minVx >= -1e-4f, "Coulomb braking: velocity never reverses (no jitter)" + tag);
        passed &= expect(br.state == ContactState.Static, "Coulomb braking: ends in Static state" + tag);

        // 4. TIRE VERS LE HAUT : la surface ne retient plus rien -> N = 0 -> pas de friction
        SlideResult up = simulateBlock(mode, m, v0, 0.0f, 100.0f, 0.5f, mu_s, mu_k);
        passed &= expect(Math.abs(up.vx - v0) < 1e-3f, "Coulomb: no friction when pulled off the surface" + tag);

        // 5. TRAINEE : vitesse terminale. F = 10 N, k1 = 1, k2 = 1 -> v + v^2 = 10
        float dt = PhysicsConstants.FIXED_TIMESTEP;
        Particle fall = new Particle(new Point3D(), new Vector3D(), new Vector3D(), 1.0f, 1.0f, false);
        ForceRegistry dragRegistry = new ForceRegistry();
        dragRegistry.add(fall, new TestConstantForce(new Vector3D(10.0f, 0.0f, 0.0f)));
        dragRegistry.add(fall, new DragForceGenerator(1.0f, 1.0f));
        for (int i = 0; i < 60 * 15; i++) {
            dragRegistry.updateForces(dt);
            fall.integrate(dt, mode);
            fall.clearForceAccumulator();
        }
        float terminal = (-1.0f + (float)Math.sqrt(41.0f)) / 2.0f; // racine de v^2 + v - 10 = 0
        passed &= expect(Math.abs(fall.getVelocity().getX() - terminal) < 0.01f * terminal, "Drag terminal velocity (k1 + k2)" + tag);

        return passed;
    }

    void testFriction() {
        boolean passed = true;
        float dt = PhysicsConstants.FIXED_TIMESTEP;

        // --- Trainee : force instantanee ---
        Particle p = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 1.0f, 1.0f, false);
        new DragForceGenerator(0.5f, 0.1f).updateForce(p, dt);
        // f = -(k1 |v| + k2 |v|^2) v^ = -(5 + 10) = -15 selon X
        passed &= expect(p.getForceAccum().equals(new Vector3D(-15.0f, 0.0f, 0.0f)), "Drag force = -(k1|v| + k2|v|^2) v^");

        Particle still = new Particle();
        new DragForceGenerator(1.0f, 1.0f).updateForce(still, dt);
        passed &= expect(still.getForceAccum().length() == 0.0f, "Drag is zero at rest");

        // Garde-fou : une trainee gigantesque ne peut qu'arreter la particule, pas la faire reculer
        Particle fast = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 2.0f, 1.0f, false);
        new DragForceGenerator(1.0e6f, 0.0f).updateForce(fast, dt);
        float maxStop = 2.0f * 10.0f / dt; // m |v| / dt
        passed &= expect(Math.abs(fast.getForceAccum().length() - maxStop) < 1e-2f * maxStop, "Drag is clamped to m|v|/dt");
        fast.integrate(dt, IntegrationMode.Euler);
        passed &= expect(fast.getVelocity().getX() > -1e-3f, "Drag never reverses velocity");

        // Masse infinie : ignoree
        Particle wall = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 0.0f, 1.0f, false);
        new DragForceGenerator(1.0f, 1.0f).updateForce(wall, dt);
        passed &= expect(wall.getForceAccum().length() == 0.0f, "Drag ignores infinite-mass particles");

        // --- Desactivation (touche [F]) ---
        Particle off = new Particle(new Point3D(), new Vector3D(10.0f, 0.0f, 0.0f), new Vector3D(), 1.0f, 1.0f, false);
        DragForceGenerator disabled = new DragForceGenerator(1.0f, 1.0f);
        disabled.setEnabled(false);
        disabled.updateForce(off, dt);
        passed &= expect(off.getForceAccum().length() == 0.0f, "Disabled generator adds no force");

        // --- Coulomb : particule en l'air (ecart > tolerance) ---
        Particle air = new Particle(new Point3D(0.0f, 5.0f, 0.0f), new Vector3D(5.0f, 0.0f, 0.0f), new Vector3D(), 1.0f, 1.0f, false);
        air.addForce(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f));
        CoulombFrictionGenerator airCoulomb = new CoulombFrictionGenerator(
            new PlaneSurface(new Point3D(), new Vector3D(0.0f, 1.0f, 0.0f)), 0.6f, 0.4f);
        airCoulomb.updateForce(air, dt);
        passed &= expect(airCoulomb.getState() == ContactState.Airborne, "Coulomb: Airborne when not touching");
        passed &= expect(Math.abs(air.getForceAccum().getX()) < 1e-6f, "Coulomb: no friction when Airborne");

        // mu_k est plafonne a mu_s
        passed &= expect(new CoulombFrictionGenerator(null, 0.3f, 0.9f).getKineticCoeff() <= 0.3f, "Coulomb: mu_k clamped to mu_s");

        // --- Coulomb + trainee : meme resultat avec les 3 integrateurs ---
        for (IntegrationMode mode : IntegrationMode.values()) {
            passed &= testFrictionAllModes(mode);
        }

        if (passed) println("Friction: All tests passed!");
    }

    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
        }
        return condition;
    }
}

// Generateur de test : applique une force constante (equivalent d'une poussee ou du poids).
// Prefixe "Test" pour ne pas entrer en conflit avec le vrai generateur de forces constantes.
class TestConstantForce implements ForceGenerator {
    private Vector3D m_force;

    public TestConstantForce(Vector3D force) {
        m_force = force;
    }

    public void updateForce(Particle p, float dt) {
        p.addForce(m_force);
    }
}
