// ==========================================
// Translated Physics Unit Tests
// ==========================================

class Tests {

    void run() {
        testPoint3D();
        testVector3D();
        testParticle();
    }

    // --- Vector3D Tests ---
    void testVector3D() {
        boolean passed = true;
        passed &= expect(new Vector3D(1.0f, 2.0f, 3.0f).getX() == 1.0f, "Vector Initialization");
        
        Vector3D norm = new Vector3D(3.0f, 4.0f, 0.0f).normalized();
        passed &= expect(Math.abs(norm.getX() - 0.6f) < 1e-5f, "Vector Normalized X");
        
        Vector3D v1 = new Vector3D(1.0f, 2.0f, 3.0f);
        Vector3D v2 = new Vector3D(4.0f, 5.0f, 6.0f);
        passed &= expect(v1.dot(v2) == 32.0f, "Vector Dot");
        
        Vector3D cross = v1.cross(v2);
        passed &= expect(cross.getX() == -3.0f && cross.getY() == 6.0f && cross.getZ() == -3.0f, "Vector Cross");
        
        passed &= expect(new Vector3D(2.0f, 3.0f, 6.0f).length() == 7.0f, "Vector Length");
        
        if (passed) println("Vector3D: All tests passed!");
    }

    // --- Point3D Tests ---
    void testPoint3D() {
        boolean passed = true;
        Point3D p = new Point3D(1.0f, 2.0f, 3.0f);
        passed &= expect(p.getX() == 1.0f && p.getY() == 2.0f && p.getZ() == 3.0f, "Point3D Init");
        
        float dist = new Point3D(1.0f, 2.0f, 3.0f).distanceTo(new Point3D(4.0f, 6.0f, 3.0f));
        passed &= expect(Math.abs(dist - 5.0f) < 1e-5f, "Point3D Distance");
        
        Point3D result = new Point3D(1.0f, 2.0f, 3.0f).add(new Vector3D(4.0f, 5.0f, 6.0f));
        passed &= expect(result.equals(new Point3D(5.0f, 7.0f, 9.0f)), "Point Vector Addition");
        
        if (passed) println("Point3D: All tests passed!");
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

    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
        }
        return condition;
    }
}
