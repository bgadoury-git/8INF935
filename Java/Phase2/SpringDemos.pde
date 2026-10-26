ArrayList<Particle> springDemoParticles = new ArrayList<Particle>();

class SpringDemoStation {
    String label;
    Point3D anchor;
    boolean hasPost;

    SpringDemoStation(String label, Point3D anchor, boolean hasPost) {
        this.label = label;
        this.anchor = anchor;
        this.hasPost = hasPost;
    }
}
ArrayList<SpringDemoStation> springDemoStations = new ArrayList<SpringDemoStation>();

final float DEMO_Z = 12.0f;
final float DEMO_X0 = 14.0f;
final float DEMO_SPACING = 5.0f;
final float DEMO_ANCHOR_Y = 11.0f;

final float DEMO_WATER_HEIGHT = 2.5f;
final float DEMO_WATER_SIZE = 3.5f;
float demoWaterX;

class SpringDemoSphere extends Particle {
    float radius = 0.5f;

    SpringDemoSphere(Point3D pos) {
        super(pos, new Vector3D(), new Vector3D(), 5.0f, 1.0f, true);
        setMaterial(Material.STEEL);
    }

    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(255, 200, 40);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

boolean isSpringDemoParticle(Particle p) {
    return springDemoParticles.contains(p);
}

SpringDemoSphere addDemoSphere(float x, float y, float z) {
    SpringDemoSphere s = new SpringDemoSphere(new Point3D(x, y, z));
    particles.add(s);
    springDemoParticles.add(s);
    return s;
}

void addDemoForce(Particle p, ForceGenerator fg) {
    forceRegistry.add(p, fg);
    if (fg instanceof DrawableForceGenerator) {
        registerDrawable(p, (DrawableForceGenerator) fg);
    }
}

void setupSpringDemos() {
    springDemoParticles.clear();
    springDemoStations.clear();

    float x = DEMO_X0;

    Point3D a1 = new Point3D(x, DEMO_ANCHOR_Y, DEMO_Z);
    SpringDemoSphere s1 = addDemoSphere(x, DEMO_ANCHOR_Y - 1.5f, DEMO_Z);
    addDemoForce(s1, new ParticleAnchoredSpring(a1, 60.0f, 3.0f));
    springDemoStations.add(new SpringDemoStation("1. Ressort ancré", a1, true));

    x += DEMO_SPACING;
    Point3D a2 = new Point3D(x, DEMO_ANCHOR_Y, DEMO_Z);
    SpringDemoSphere s2a = addDemoSphere(x, DEMO_ANCHOR_Y - 2.5f, DEMO_Z);
    SpringDemoSphere s2b = addDemoSphere(x, DEMO_ANCHOR_Y - 4.0f, DEMO_Z);
    addDemoForce(s2a, new ParticleAnchoredSpring(a2, 120.0f, 2.0f));
    ParticleSpring onA = new ParticleSpring(s2b, 60.0f, 2.0f);
    ParticleSpring onB = new ParticleSpring(s2a, 60.0f, 2.0f);
    onB.visible = false;
    addDemoForce(s2a, onA);
    addDemoForce(s2b, onB);
    springDemoStations.add(new SpringDemoStation("2. Ressort 2 particules", a2, true));

    x += DEMO_SPACING;
    Point3D a3 = new Point3D(x, DEMO_ANCHOR_Y, DEMO_Z);
    SpringDemoSphere s3 = addDemoSphere(x, DEMO_ANCHOR_Y - 0.6f, DEMO_Z);
    addDemoForce(s3, new ParticleAnchoredBungee(a3, 60.0f, 4.0f));
    springDemoStations.add(new SpringDemoStation("3. Élastique ancré", a3, true));

    x += DEMO_SPACING;
    Point3D a4 = new Point3D(x, DEMO_ANCHOR_Y, DEMO_Z);
    SpringDemoSphere s4a = addDemoSphere(x, DEMO_ANCHOR_Y - 2.0f, DEMO_Z);
    SpringDemoSphere s4b = addDemoSphere(x, DEMO_ANCHOR_Y - 3.2f, DEMO_Z);
    addDemoForce(s4a, new ParticleAnchoredSpring(a4, 150.0f, 2.0f));
    ParticleBungee bOnA = new ParticleBungee(s4b, 50.0f, 3.0f);
    ParticleBungee bOnB = new ParticleBungee(s4a, 50.0f, 3.0f);
    bOnA.visible = false;
    addDemoForce(s4a, bOnA);
    addDemoForce(s4b, bOnB);
    springDemoStations.add(new SpringDemoStation("4. Élastique 2 particules", a4, true));

    x += DEMO_SPACING;
    demoWaterX = x;
    SpringDemoSphere s5 = addDemoSphere(x, DEMO_WATER_HEIGHT + 5.0f, DEMO_Z);
    s5.setLinearDamping(0.3f);
    addDemoForce(s5, new ParticleBuoyancy(0.5f, 0.008f, DEMO_WATER_HEIGHT));
    springDemoStations.add(new SpringDemoStation("5. Flottabilité",
        new Point3D(x, DEMO_WATER_HEIGHT + 2.0f, DEMO_Z), false));

    x += DEMO_SPACING;
    Point3D a6 = new Point3D(x, DEMO_ANCHOR_Y - 2.0f, DEMO_Z);
    SpringDemoSphere s6 = addDemoSphere(x, DEMO_ANCHOR_Y - 6.0f, DEMO_Z);
    addDemoForce(s6, new ParticleStiffSpring(a6, 6000.0f, 104.0f));
    springDemoStations.add(new SpringDemoStation("6. Ressort rigide", a6, true));
}

float[][] demoLabelScreen = new float[0][];

void drawSpringDemos() {
    noStroke();
    for (SpringDemoStation st : springDemoStations) {
        if (!st.hasPost) continue;
        float px = st.anchor.getX();
        float pz = st.anchor.getZ() - 1.2f;
        float top = st.anchor.getY() + 0.4f;

        fill(110, 85, 60);
        pushMatrix();
        translate(px, top / 2.0f, pz);
        box(0.3f, top, 0.3f);
        popMatrix();

        pushMatrix();
        translate(px, top, pz + 0.6f);
        box(0.3f, 0.3f, 1.5f);
        popMatrix();
    }

    pushMatrix();
    translate(demoWaterX, DEMO_WATER_HEIGHT / 2.0f, DEMO_Z);
    fill(40, 120, 220, 90);
    box(DEMO_WATER_SIZE, DEMO_WATER_HEIGHT, DEMO_WATER_SIZE);
    popMatrix();

    demoLabelScreen = new float[springDemoStations.size()][];
    for (int i = 0; i < springDemoStations.size(); i++) {
        SpringDemoStation st = springDemoStations.get(i);
        Point3D p = new Point3D(st.anchor.getX(), st.anchor.getY() + 1.2f, st.anchor.getZ());
        if (!isInFrontOfCamera(p) || player == null) continue;
        if (p.distanceTo(player.getPosition()) > 45.0f) continue;
        demoLabelScreen[i] = new float[] { screenX(p.getX(), p.getY(), p.getZ()),
                                           screenY(p.getX(), p.getY(), p.getZ()) };
    }
}

boolean isInFrontOfCamera(Point3D p) {
    if (smoothedCamPos == null || smoothedCamTarget == null) return false;
    Vector3D view = smoothedCamTarget.sub(smoothedCamPos);
    Vector3D toPoint = p.sub(smoothedCamPos);
    return view.dot(toPoint) > 0.0f;
}

void renderSpringDemoLabels() {
    textAlign(CENTER, BOTTOM);
    textSize(16);
    for (int i = 0; i < demoLabelScreen.length && i < springDemoStations.size(); i++) {
        if (demoLabelScreen[i] == null) continue;
        String label = springDemoStations.get(i).label;
        float sx = demoLabelScreen[i][0];
        float sy = demoLabelScreen[i][1];
        float w = textWidth(label) + 14.0f;
        noStroke();
        fill(0, 0, 0, 140);
        rect(sx - w / 2.0f, sy - 24.0f, w, 24.0f, 6.0f);
        fill(255, 220, 90);
        text(label, sx, sy - 3.0f);
    }
}
