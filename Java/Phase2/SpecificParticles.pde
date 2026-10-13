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
