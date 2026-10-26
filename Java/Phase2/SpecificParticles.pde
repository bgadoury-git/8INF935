class Earth extends Particle {
    public final float radius = 6371000.0f; 

    public Earth(Point3D pos) {
        super(pos, new Vector3D(), new Vector3D(), 0.0f, 1.0f, false);
        setInverseMass(0.0f); 
        setMaterial(Material.EARTH);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {}
}

class SpaceSphere extends Particle {
    float radius = 1.0f;

    public SpaceSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 20.0f, 1.0f, true);
    }
    
    @Override
    float getRadius() { return radius; }

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

class SmallSphere extends Particle {
    float radius = 0.5f;

    public SmallSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 20.0f, 1.0f, true);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(0, 50, 50);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

class AnalyticalSlope {
    Point3D startPos;
    float length;
    float width;
    float angleDeg;
    float thickness = 0.5f;
    Material material;
    
    Vector3D normal;

    public AnalyticalSlope(Point3D startPos, float length, float width, float angleDeg, Material material) {
        this.startPos = startPos;
        this.length = length;
        this.width = width;
        this.angleDeg = angleDeg;
        this.material = material;

        float rad = radians(angleDeg);
        float sinA = sin(rad);
        float cosA = cos(rad);

        // Normal points perpendicular to the slope surface
        this.normal = new Vector3D(-sinA, cosA, 0.0f).normalized();
    }

    void draw(processing.core.PApplet app) {
        app.pushMatrix();
        app.translate(startPos.getX(), startPos.getY(), startPos.getZ());
        app.rotateZ(radians(angleDeg));
        app.translate(length / 2.0f, -thickness / 2.0f, 0.0f);
        
        app.noStroke();
        app.fill(120, 110, 100); 
        app.box(length, thickness, width); 
        app.popMatrix();
    }
}
