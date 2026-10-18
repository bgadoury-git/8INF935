class Ball extends Particle {
    public static final float baseSpeed = 150.0f;
    public static final boolean defaultGravityState = true;

    public Ball(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 1.0f, 0.999f, defaultGravityState);
    }

    @Override
    void draw() {
        //draw whatever
    }
}

class Earth extends Particle {
    public final float radius = 6371000.0f; // 6,371 km radius

    public Earth(Point3D pos) {
        // mass = 0.0f (results in inverseMass = 0), damping = 1.0f, gravity = false[cite: 3]
        super(pos, new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        setInverseMass(0.0f); // Explicitly ensure it remains immovable[cite: 3]
    }

    @Override
    void draw() {
        // No localized rendering. 
        // The visual representation is handled by the Arena class to bypass floating-point scale limits.
    }
}

class SpaceSphere extends Particle {
    float radius = 1.0f;

    public SpaceSphere(Point3D pos, Vector3D vel) {
        // mass = 20.0f, damping = 1.0f, gravity = false
        super(pos, vel, new Vector3D(), 20.0f, 1.0f, true);
    }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        
        fill(255, 50, 50);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        
        popMatrix();
    }
}
