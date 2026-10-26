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

// Player core sphere
class RedSphere extends Particle {
    float radius = 1.2f;

    public RedSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 15.0f, 1.0f, true);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(255, 40, 40);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

// Collectible sphere variant 1
class CyanSphere extends Particle {
    float radius = 0.6f;

    public CyanSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 3.0f, 1.0f, true);
        setMaterial(Material.RUBBER);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(50, 255, 180);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

// Collectible sphere variant 2
class PurpleSphere extends Particle {
    float radius = 0.7f;

    public PurpleSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 12.0f, 1.0f, true);
        setMaterial(Material.STEEL);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(160, 50, 220);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

// Collectible sphere variant 3
class BlueSphere extends Particle {
    float radius = 0.5f;

    public BlueSphere(Point3D pos, Vector3D vel) {
        super(pos, vel, new Vector3D(), 5.0f, 1.0f, true);
    }
    
    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(0, 150, 200);
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
