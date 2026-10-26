ArrayList<Particle> springFeatureParticles = new ArrayList<Particle>();

final float TRAMPOLINE_X = 17.0f;
final float TRAMPOLINE_Z = 6.0f;
final float TRAMPOLINE_SIZE = 6.0f;
final float TRAMPOLINE_HEIGHT = 2.6f;
final float TRAMPOLINE_K = 600.0f;

final float PLATFORM_X = 24.5f;
final float PLATFORM_Z = 6.0f;
final float PLATFORM_SIZE = 6.0f;
final float PLATFORM_HEIGHT = 7.0f;
final float PLATFORM_OMEGA = 25.0f;

final float POOL_X = 32.0f;
final float POOL_Z = 16.0f;
final float POOL_SIZE = 10.0f;
final float POOL_WATER_HEIGHT = 2.5f;
final float POOL_DENSITY = 4.0f;
final float POOL_DRAG = 1.5f;

final float HOOK_X = 22.0f;
final float HOOK_Y = 13.0f;
final float HOOK_Z = 20.0f;
final float HOOK_RANGE = 8.0f;
final float GRAPPLE_K = 80.0f;
final float GRAPPLE_REST = 7.0f;

TrampolineGenerator trampoline;
StablePlatformGenerator stablePlatform;
SpringFeatureSphere hookBall;
ParticleBungee grappleOnPlayer;
ParticleBungee grappleOnHook;
boolean grappleAttached = false;
int lastGrappleToggleMs = -1000;

class SpringFeatureSphere extends Particle {
    float radius;
    int r, g, b;

    SpringFeatureSphere(Point3D pos, float radius, float mass, int r, int g, int b) {
        super(pos, new Vector3D(), new Vector3D(), mass, 1.0f, true);
        this.radius = radius;
        this.r = r;
        this.g = g;
        this.b = b;
        setMaterial(Material.STEEL);
    }

    @Override
    float getRadius() { return radius; }

    @Override
    void draw() {
        pushMatrix();
        translate(getPosition().getX(), getPosition().getY(), getPosition().getZ());
        fill(r, g, b);
        noStroke();
        sphereDetail(16);
        sphere(radius);
        popMatrix();
    }
}

boolean isSpringFeatureParticle(Particle p) {
    return springFeatureParticles.contains(p);
}

boolean insideSquare(Point3D pos, float cx, float cz, float size) {
    float half = size / 2.0f;
    return Math.abs(pos.getX() - cx) <= half && Math.abs(pos.getZ() - cz) <= half;
}

abstract class SurfaceSpringGenerator implements ForceGenerator {
    float cx, cz, size, surfaceY;
    float maxDepth = 2.5f;
    HashMap<Particle, Boolean> engaged = new HashMap<Particle, Boolean>();
    float currentDip = 0.0f;

    SurfaceSpringGenerator(float cx, float cz, float size, float surfaceY) {
        this.cx = cx;
        this.cz = cz;
        this.size = size;
        this.surfaceY = surfaceY;
    }

    float compressionOf(Particle p) {
        Point3D pos = p.getPosition();
        if (!insideSquare(pos, cx, cz, size)) {
            engaged.put(p, false);
            return 0.0f;
        }
        float bottom = pos.getY() - p.getRadius();
        if (bottom >= surfaceY) {
            engaged.put(p, true);
            return 0.0f;
        }
        Boolean e = engaged.get(p);
        if (e == null || !e) return 0.0f;
        float compression = surfaceY - bottom;
        if (compression > maxDepth) {
            engaged.put(p, false);
            return 0.0f;
        }
        currentDip = Math.max(currentDip, compression);
        return compression;
    }

    void beginFrame() {
        currentDip *= 0.8f;
    }
}

class TrampolineGenerator extends SurfaceSpringGenerator {
    float k;

    TrampolineGenerator(float cx, float cz, float size, float surfaceY, float k) {
        super(cx, cz, size, surfaceY);
        this.k = k;
    }

    @Override
    public void updateForce(Particle particle, float dt) {
        if (!particle.hasFiniteMass()) return;
        float compression = compressionOf(particle);
        if (compression <= 0.0f) return;
        float restLength = maxDepth;
        Point3D pos = particle.getPosition();
        Point3D anchorBelow = new Point3D(pos.getX(), surfaceY + particle.getRadius() - restLength, pos.getZ());
        particle.addForce(computeSpringForce(particle, anchorBelow, k, restLength, false));
    }
}

class StablePlatformGenerator extends SurfaceSpringGenerator {
    float omega;

    StablePlatformGenerator(float cx, float cz, float size, float surfaceY, float omega) {
        super(cx, cz, size, surfaceY);
        this.omega = omega;
    }

    @Override
    public void updateForce(Particle particle, float dt) {
        if (!particle.hasFiniteMass() || dt <= 0.0f) return;
        float compression = compressionOf(particle);
        if (compression <= 0.0f) return;

        float m = particle.getMass();
        float k = m * omega * omega;
        float c = 2.0f * (float)Math.sqrt(m * k);

        Vector3D x0 = new Vector3D(0.0f, -compression, 0.0f);
        Vector3D v0 = new Vector3D(0.0f, particle.getVelocity().getY(), 0.0f);
        Vector3D target = dampedHarmonicPosition(x0, v0, k, c, m, dt);
        if (target == null) return;

        float accelY = (target.getY() - x0.getY()) / (dt * dt) - v0.getY() / dt;
        particle.addForce(new Vector3D(0.0f, accelY * m, 0.0f));
    }
}

class PoolBuoyancy implements ForceGenerator {
    ParticleBuoyancy buoyancy;

    PoolBuoyancy(Particle p) {
        float r = p.getRadius();
        float volume = (4.0f / 3.0f) * PI * r * r * r;
        buoyancy = new ParticleBuoyancy(r, volume, POOL_WATER_HEIGHT, POOL_DENSITY);
    }

    @Override
    public void updateForce(Particle particle, float dt) {
        if (!particle.hasFiniteMass()) return;
        if (!insideSquare(particle.getPosition(), POOL_X, POOL_Z, POOL_SIZE)) return;
        float ratio = buoyancy.submergedRatio(particle.getPosition().getY());
        if (ratio <= 0.0f) return;
        buoyancy.updateForce(particle, dt);
        particle.addForce(particle.getVelocity().mult(-POOL_DRAG * particle.getMass() * ratio));
    }
}

void addFeatureForce(Particle p, ForceGenerator fg) {
    forceRegistry.add(p, fg);
    if (fg instanceof DrawableForceGenerator) {
        registerDrawable(p, (DrawableForceGenerator) fg);
    }
}

void setupSpringFeatures() {
    springFeatureParticles.clear();
    grappleAttached = false;
    grappleOnPlayer = null;
    grappleOnHook = null;

    trampoline = new TrampolineGenerator(TRAMPOLINE_X, TRAMPOLINE_Z, TRAMPOLINE_SIZE, TRAMPOLINE_HEIGHT, TRAMPOLINE_K);
    stablePlatform = new StablePlatformGenerator(PLATFORM_X, PLATFORM_Z, PLATFORM_SIZE, PLATFORM_HEIGHT, PLATFORM_OMEGA);

    float topY = PLATFORM_HEIGHT + 0.6f;
    Particle[] platformRewards = {
        new CyanSphere(new Point3D(PLATFORM_X - 1.5f, topY, PLATFORM_Z - 1.5f), new Vector3D()),
        new CyanSphere(new Point3D(PLATFORM_X + 1.5f, topY, PLATFORM_Z - 1.5f), new Vector3D()),
        new CyanSphere(new Point3D(PLATFORM_X, topY, PLATFORM_Z + 1.5f), new Vector3D())
    };
    for (Particle reward : platformRewards) {
        particles.add(reward);
        loneParticles.add(reward);
    }

    hookBall = new SpringFeatureSphere(new Point3D(HOOK_X, HOOK_Y, HOOK_Z), 0.5f, 10.0f, 200, 200, 210);
    particles.add(hookBall);
    springFeatureParticles.add(hookBall);
    ParticleStiffSpring hookSpring = new ParticleStiffSpring(new Point3D(HOOK_X, HOOK_Y, HOOK_Z), 8000.0f, 226.0f);
    hookSpring.visible = false;
    forceRegistry.add(hookBall, hookSpring);

    for (Particle p : particles) {
        if (!p.hasFiniteMass() || isSpringFeatureParticle(p)) continue;
        forceRegistry.add(p, trampoline);
        forceRegistry.add(p, stablePlatform);
        forceRegistry.add(p, new PoolBuoyancy(p));
    }
}

boolean playerInGrappleRange() {
    if (player == null) return false;
    float dx = player.getPosition().getX() - HOOK_X;
    float dz = player.getPosition().getZ() - HOOK_Z;
    return dx * dx + dz * dz <= HOOK_RANGE * HOOK_RANGE;
}

void toggleGrapple() {
    if (player == null || hookBall == null) return;
    if (millis() - lastGrappleToggleMs < 250) return;
    lastGrappleToggleMs = millis();

    if (grappleAttached) {
        forceRegistry.remove(player, grappleOnPlayer);
        forceRegistry.remove(hookBall, grappleOnHook);
        unregisterDrawable(player, grappleOnPlayer);
        grappleAttached = false;
        return;
    }
    if (!playerInGrappleRange()) return;

    grappleOnPlayer = new ParticleBungee(hookBall, GRAPPLE_K, GRAPPLE_REST);
    grappleOnHook = new ParticleBungee(player, GRAPPLE_K, GRAPPLE_REST);
    grappleOnHook.visible = false;
    forceRegistry.add(player, grappleOnPlayer);
    forceRegistry.add(hookBall, grappleOnHook);
    registerDrawable(player, grappleOnPlayer);
    grappleAttached = true;
}

void drawPost(float x, float z, float height) {
    pushMatrix();
    translate(x, height / 2.0f, z);
    box(0.3f, height, 0.3f);
    popMatrix();
}

void drawSpringFeatures() {
    noStroke();

    float half = TRAMPOLINE_SIZE / 2.0f;
    float matY = TRAMPOLINE_HEIGHT - trampoline.currentDip;
    fill(70, 70, 80);
    for (int sx = -1; sx <= 1; sx += 2) {
        for (int sz = -1; sz <= 1; sz += 2) {
            drawPost(TRAMPOLINE_X + sx * (half + 0.4f), TRAMPOLINE_Z + sz * (half + 0.4f), TRAMPOLINE_HEIGHT);
            Point3D corner = new Point3D(TRAMPOLINE_X + sx * (half + 0.4f), TRAMPOLINE_HEIGHT, TRAMPOLINE_Z + sz * (half + 0.4f));
            Point3D matCorner = new Point3D(TRAMPOLINE_X + sx * half, matY, TRAMPOLINE_Z + sz * half);
            drawSpringCoil(corner, matCorner, 0.6f, 1.6f);
        }
    }
    noStroke();
    fill(30, 160, 230);
    pushMatrix();
    translate(TRAMPOLINE_X, matY - 0.05f, TRAMPOLINE_Z);
    box(TRAMPOLINE_SIZE, 0.1f, TRAMPOLINE_SIZE);
    popMatrix();
    trampoline.beginFrame();

    float pHalf = PLATFORM_SIZE / 2.0f;
    float platY = PLATFORM_HEIGHT - stablePlatform.currentDip;
    fill(110, 85, 60);
    for (int sx = -1; sx <= 1; sx += 2) {
        for (int sz = -1; sz <= 1; sz += 2) {
            drawPost(PLATFORM_X + sx * (pHalf - 0.3f), PLATFORM_Z + sz * (pHalf - 0.3f), PLATFORM_HEIGHT - 0.6f);
        }
    }
    fill(150, 150, 160);
    pushMatrix();
    translate(PLATFORM_X, platY - 0.3f, PLATFORM_Z);
    box(PLATFORM_SIZE, 0.6f, PLATFORM_SIZE);
    popMatrix();
    stablePlatform.beginFrame();

    fill(110, 85, 60);
    drawPost(HOOK_X, HOOK_Z - 1.2f, HOOK_Y + 0.4f);
    pushMatrix();
    translate(HOOK_X, HOOK_Y + 0.4f, HOOK_Z - 0.6f);
    box(0.3f, 0.3f, 1.5f);
    popMatrix();
    fill(255, 255, 255, 40);
    pushMatrix();
    translate(HOOK_X, 0.05f, HOOK_Z);
    rotateX(HALF_PI);
    ellipse(0, 0, HOOK_RANGE * 2.0f, HOOK_RANGE * 2.0f);
    popMatrix();

    fill(40, 120, 220, 90);
    pushMatrix();
    translate(POOL_X, POOL_WATER_HEIGHT / 2.0f, POOL_Z);
    box(POOL_SIZE, POOL_WATER_HEIGHT, POOL_SIZE);
    popMatrix();

    computeFeatureLabels();
}

String[] featureLabelText = new String[0];
float[][] featureLabelScreen = new float[0][];

void computeFeatureLabels() {
    String grappleText = grappleAttached ? "Grappin : [H] lâcher"
                       : (playerInGrappleRange() ? "Grappin : [H] s'accrocher" : "Grappin élastique");
    String[] texts = { "Trampoline", "Plateforme stable", "Bassin", grappleText };
    Point3D[] spots = {
        new Point3D(TRAMPOLINE_X, TRAMPOLINE_HEIGHT + 1.5f, TRAMPOLINE_Z),
        new Point3D(PLATFORM_X, PLATFORM_HEIGHT + 2.0f, PLATFORM_Z),
        new Point3D(POOL_X, POOL_WATER_HEIGHT + 1.5f, POOL_Z),
        new Point3D(HOOK_X, HOOK_Y + 1.5f, HOOK_Z)
    };
    featureLabelText = texts;
    featureLabelScreen = new float[texts.length][];
    for (int i = 0; i < texts.length; i++) {
        Point3D p = spots[i];
        if (player == null || !isInFrontOfCamera(p)) continue;
        if (p.distanceTo(player.getPosition()) > 45.0f) continue;
        featureLabelScreen[i] = new float[] { screenX(p.getX(), p.getY(), p.getZ()),
                                              screenY(p.getX(), p.getY(), p.getZ()) };
    }
}

boolean isInFrontOfCamera(Point3D p) {
    if (smoothedCamPos == null || smoothedCamTarget == null) return false;
    Vector3D view = smoothedCamTarget.sub(smoothedCamPos);
    Vector3D toPoint = p.sub(smoothedCamPos);
    return view.dot(toPoint) > 0.0f;
}

void renderSpringFeatureLabels() {
    textAlign(CENTER, BOTTOM);
    textSize(16);
    for (int i = 0; i < featureLabelScreen.length && i < featureLabelText.length; i++) {
        if (featureLabelScreen[i] == null) continue;
        String label = featureLabelText[i];
        float sx = featureLabelScreen[i][0];
        float sy = featureLabelScreen[i][1];
        float w = textWidth(label) + 14.0f;
        noStroke();
        fill(0, 0, 0, 140);
        rect(sx - w / 2.0f, sy - 24.0f, w, 24.0f, 6.0f);
        fill(255, 220, 90);
        text(label, sx, sy - 3.0f);
    }
}
