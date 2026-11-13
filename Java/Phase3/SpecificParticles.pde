// GravityCenter
class GravityCenter extends Particle {
    float radius = 1.2f;

    public GravityCenter(Point3D pos, Vector3D vel) {
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
