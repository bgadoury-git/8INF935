import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.IntStream;

// --- State Machine ---
enum GameState {
    Menu, Playing, GameOver
}

GameState currentState = GameState.Menu;
Vector3D currentCamDir = new Vector3D(0.0f, 0.0f, 1.0f);

// --- Gameplay State ---
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Cable> cables = new ArrayList<Cable>();

// --- System Integrations ---
ForceRegistry forceRegistry = new ForceRegistry(); 
GravityGenerator gravityGenerator = new GravityGenerator(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f));

// --- Friction State ---
ArrayList<FrictionGenerator> frictionGenerators = new ArrayList<FrictionGenerator>();
CoulombFrictionGenerator playerGroundFriction;
boolean frictionEnabled = true;

// --- Drawable Forces (Springs) ---
class DrawableForceBinding {
    Particle particle;
    DrawableForceGenerator fg;
    DrawableForceBinding(Particle p, DrawableForceGenerator fg) { this.particle = p; this.fg = fg; }
}
ArrayList<DrawableForceBinding> drawableForces = new ArrayList<DrawableForceBinding>();

void registerDrawable(Particle p, DrawableForceGenerator fg) {
    drawableForces.add(new DrawableForceBinding(p, fg));
}
void unregisterDrawable(Particle p, DrawableForceGenerator fg) {
    drawableForces.removeIf(d -> d.particle == p && d.fg == fg);
}

IntegrationMode currentIntegrationMode = IntegrationMode.PositionVerlet;

float totalTime = 0;
float accumulator = 0;
float customDeltaTime = 0;
float customFPS = 0;
float smoothedDeltaTime = 0.0f;
long lastTimeMs = 0;

final float THRUST_WEIGHT_RATIO = 2.0f;
boolean thrustHeld = false;
final float PUSH_FORCE = 200.0f;
boolean pushForward = false, pushBack = false, pushLeft = false, pushRight = false;
ConstantForceGenerator thrustGenerator;
ConstantForceGenerator pushGenerator;

final float DEBUG_FORCE_SCALE = 0.01f;
boolean showForceDebug = false;
boolean debugKeyDown = false;
final float EXPLOSION_RADIUS = 8.0f;
final float EXPLOSION_IMPULSE = 400.0f;
boolean explosionRequested = false;
boolean explosionKeyDown = false;

Arena arena = new Arena();
Tests testSuite = new Tests();

public void settings() {
    fullScreen(P3D);
}

public void setup() {
    frameRate(10000); 
    lastTimeMs = System.nanoTime();
    testSuite.run();
}

public void draw() {
    actualiseDeltaTime();

    switch (currentState) {
        case Menu: drawMenuScreen(); break;
        case Playing: drawGameplay(); break;
        case GameOver: drawGameOverScreen(); break;
    }
}

// ==========================================
// Lifecycle & State Transitions
// ==========================================

SpaceSphere player;
Earth earth;

void resetGame() {
    particles.clear();
    cables.clear();
    forceRegistry.clear();
    drawableForces.clear();
    
    totalTime = 0;
    currentState = GameState.Playing;
    
    earth = new Earth(new Point3D(0.0f, -6371000.0f, 0.0f)); 
    player = new SpaceSphere(new Point3D(0.0f, 2.0f, 0.0f), new Vector3D(0.0f, 20.0f, 20.0f));
    
    SmallSphere entity1 = new SmallSphere(new Point3D(0.0f, 1.0f, 0.0f), new Vector3D());
    SmallSphere entity2 = new SmallSphere(new Point3D(-1.0f, 1.0f, 2.0f), new Vector3D());
    SmallSphere entity3 = new SmallSphere(new Point3D(0.0f, 1.0f, 2.0f), new Vector3D());
    SmallSphere entity4 = new SmallSphere(new Point3D(1.0f, 1.0f, 2.0f), new Vector3D());
    
    particles.add(earth);
    particles.add(player);
    particles.add(entity1);
    particles.add(entity2);
    particles.add(entity3);
    particles.add(entity4);

    // Initialize an ElasticLink mapping to test the Springs
    new ElasticLink(player, entity1, 15.0f, 4.0f, 8.0f);
    cables.add(new Cable(entity1, entity2, 5));
    cables.add(new Cable(entity1, entity3, 5));
    cables.add(new Cable(entity1, entity4, 5));

    // Register Base Gravity
    for (Particle p : particles) {
        if (p.getAffectedByGravity()) {
            forceRegistry.add(p, gravityGenerator);
        }
    }
    
    // Setup Inputs
    thrustGenerator = new ConstantForceGenerator(new Vector3D(0.0f, THRUST_WEIGHT_RATIO * player.getMass() * PhysicsConstants.GRAVITY, 0.0f));
    thrustGenerator.setActive(false);
    pushGenerator = new ConstantForceGenerator(new Vector3D());
    pushGenerator.setActive(false);
    forceRegistry.add(player, thrustGenerator);
    forceRegistry.add(player, pushGenerator);

    // Setup Friction last
    setupFriction();
}

void setupFriction() {
    frictionGenerators.clear();
    DragForceGenerator airDrag = new DragForceGenerator(0.1f, 0.02f);
    frictionGenerators.add(airDrag);

    for (Particle p : particles) {
        if (p.getInverseMass() <= 0.0f) continue; 

        forceRegistry.add(p, airDrag);

        CoulombFrictionGenerator groundFriction =
            new CoulombFrictionGenerator(new SphericalSurface(earth), 0.6f, 0.4f);
        frictionGenerators.add(groundFriction);
        
        forceRegistry.add(p, groundFriction); 

        if (p == player) playerGroundFriction = groundFriction;
    }
}

// ==========================================
// Render Functions
// ==========================================

void drawGameplay() {
    float frameTime = min(customDeltaTime, PhysicsConstants.MAX_FRAME_TIME);
    accumulator += frameTime;

    updatePlayerControls();
    
    if (explosionRequested && player != null) {
        Point3D pos = player.getPosition();
        applyExplosion(particles, new Point3D(pos.getX(), 0.0f, pos.getZ()), EXPLOSION_RADIUS, EXPLOSION_IMPULSE);
        explosionRequested = false;
    }

    while (accumulator >= PhysicsConstants.FIXED_TIMESTEP) {
        updateParticles(PhysicsConstants.FIXED_TIMESTEP);
        resolveCollisionsAndConstraints(PhysicsConstants.FIXED_TIMESTEP);
        accumulator -= PhysicsConstants.FIXED_TIMESTEP;
    }

    arena.setupLighting(this);
    
    if (player != null) {
        Point3D pos = player.getPosition();
        Vector3D vel = player.getVelocity();
        Vector3D flatVel = new Vector3D(vel.getX(), 0.0f, vel.getZ());
        
        if (flatVel.lengthSquared() > 0.01f) {
            currentCamDir = flatVel.normalized();
        }
        
        float distanceBehind = 20.0f;
        float heightAbove = 8.0f; 
        
        camera(
            pos.getX() - currentCamDir.getX() * distanceBehind, 
            pos.getY() + heightAbove, 
            pos.getZ() - currentCamDir.getZ() * distanceBehind, 
            pos.getX(), pos.getY(), pos.getZ(),                 
            0.0f, -1.0f, 0.0f                                   
        );
        
        perspective(PI/3.0f, (float)width/height, 0.1f, 10000.0f);
    }

    arena.draw(this); 
    RenderParticles();
    RenderCables();
    
    // Render Springs!
    for (DrawableForceBinding df : drawableForces) {
        df.fg.draw(df.particle);
    }

    if (showForceDebug) RenderForceDebug();
    renderHUD();
}

void updateParticles(float timestep) {
    forceRegistry.updateForces(timestep);
    for (Particle particle : particles) {
       particle.integrate(timestep, currentIntegrationMode);
    }  
}

void RenderCables() {
    for (Cable cable : cables) {
        cable.draw();
    }
}

void RenderParticles() {
    for (Particle particle : particles) {
        particle.draw();
    }
}

void RenderForceDebug() {
    for (Particle p : particles) {
        if (p.getInverseMass() <= 0.0f) continue;
        Vector3D netForce = p.getLastAcceleration().mult(p.getMass());
        if (netForce.lengthSquared() < 1e-6f) continue;
        Point3D from = p.getPosition();
        Point3D tip = from.add(netForce.mult(DEBUG_FORCE_SCALE));

        stroke(255, 0, 255);
        strokeWeight(3.0f);
        line(from.getX(), from.getY(), from.getZ(), tip.getX(), tip.getY(), tip.getZ());
        noStroke();

        pushMatrix();
        translate(tip.getX(), tip.getY(), tip.getZ());
        fill(255, 0, 255);
        sphereDetail(8);
        sphere(0.12f);
        popMatrix();
    }
}

// ==========================================
// Input Handling & Timing (Unchanged logic)
// ==========================================

public void mousePressed() { if (currentState != GameState.Playing) return; }
public void mouseWheel(MouseEvent event) { if (currentState != GameState.Playing) return; }
public void keyPressed() {
    if (currentState == GameState.Menu) {
        if (key == ' ' || keyCode == ENTER) resetGame();
        return;
    }
    if (currentState == GameState.GameOver) {
        if (key == 'r' || key == 'R') resetGame();
        else if (key == ' ' || keyCode == ENTER) currentState = GameState.Menu;
        return;
    }
    if (currentState == GameState.Playing) {
        char k = Character.toLowerCase(key);
        if (k == 't') thrustHeld = true;
        if (k == 'w') pushForward = true;
        if (k == 's') pushBack = true;
        if (k == 'a') pushLeft = true;
        if (k == 'd') pushRight = true;
        if (k == 'f' && !debugKeyDown) {
            debugKeyDown = true;
            showForceDebug = !showForceDebug;
        }
        if (k == 'e' && !explosionKeyDown) {
            explosionKeyDown = true;
            explosionRequested = true;
        }
    }
}

public void keyReleased() {
    char k = Character.toLowerCase(key);
    if (k == 't') thrustHeld = false;
    if (k == 'w') pushForward = false;
    if (k == 's') pushBack = false;
    if (k == 'a') pushLeft = false;
    if (k == 'd') pushRight = false;
    if (k == 'f') debugKeyDown = false;
    if (k == 'e') explosionKeyDown = false;
}

void updatePlayerControls() {
    if (thrustGenerator == null || pushGenerator == null) return;

    thrustGenerator.setActive(thrustHeld);

    Vector3D forward = new Vector3D(currentCamDir.getX(), 0.0f, currentCamDir.getZ()).normalized();
    Vector3D right = new Vector3D(0.0f, 1.0f, 0.0f).cross(forward);

    Vector3D dir = new Vector3D();
    if (pushForward) dir = dir.add(forward);
    if (pushBack)    dir = dir.sub(forward);
    if (pushRight)   dir = dir.add(right);
    if (pushLeft)    dir = dir.sub(right);

    if (dir.lengthSquared() < 1e-6f) {
        pushGenerator.setActive(false);
        return;
    }
    
    pushGenerator.setForce(dir.normalized().mult(PUSH_FORCE));
    pushGenerator.setActive(true);
}

void actualiseDeltaTime() {
    long currentTime = System.nanoTime();
    float elapsedMs = (currentTime - lastTimeMs) / 1000000.0f;
    lastTimeMs = currentTime;
    customDeltaTime = elapsedMs / 1000.0f;
    if (currentState == GameState.Playing) totalTime += customDeltaTime;

    final float smoothingAlpha = 0.08f;
    if (smoothedDeltaTime == 0.0f) {
        smoothedDeltaTime = customDeltaTime;
    } else {
        smoothedDeltaTime = smoothingAlpha * customDeltaTime + (1.0f - smoothingAlpha) * smoothedDeltaTime;
    }
    customFPS = (smoothedDeltaTime > 0.0f) ? (1.0f / smoothedDeltaTime) : 0.0f;
}

// ==========================================
// Rendering HUD and Menus
// ==========================================

void drawMenuScreen() {
    reset2DContext();
    background(20, 24, 35);
    textAlign(CENTER, CENTER);
    fill(0, 220, 255);
    textSize(42);
    text("PROJECTILE SIMULATOR", width / 2.0f, height / 2.0f - 80.0f);
    fill(220);
    textSize(20);
    text("There will be text", width / 2.0f, height / 2.0f - 10.0f);
    fill(50, 255, 140);
    textSize(24);
    text("Press [SPACE] or [ENTER] to Start", width / 2.0f, height / 2.0f + 120.0f);
}

void drawGameOverScreen() {
    reset2DContext();
    background(15, 15, 20);
    textAlign(CENTER, CENTER);
    fill(70, 255, 70);
    textSize(48);
    text("GOAL REACHED", width / 2.0f, height / 2.0f - 60.0f);
    fill(230);
    textSize(24);
    String str = String.format("%.2f", totalTime);
    text("Final Time: " + str + " s", width / 2.0f, height / 2.0f);
    fill(100, 200, 255);
    textSize(20);
    text("Press [R] to Play Again", width / 2.0f, height / 2.0f + 60.0f);
    text("Press [SPACE] or [ESC] for Menu", width / 2.0f, height / 2.0f + 90.0f);
}

void reset2DContext() { camera(); noLights(); noStroke(); }
String formatWithCommas(int value) { return String.format("%,d", value); }
void renderHUD() { reset2DContext(); renderScoreHUD(); renderSidePanel(); }

void renderScoreHUD() {
    float cx = width / 2.0f;
    float cy = height * 0.36f;
    noStroke();
    fill(0, 0, 0, 120);
    rectMode(CENTER);
    rect(cx, cy, 280.0f, 120.0f, 14.0f);
    rectMode(CORNER);
    textAlign(CENTER, CENTER);
    fill(255, 210, 60);
    textSize(20);
    text("SCORE", cx, cy - 34.0f);
    textSize(54);
}

void renderSidePanel() {
    int totalCount = particles.size();
    float playerHeight = (player != null) ? player.getPosition().getY() : 0.0f;
    String[] statLines = {
        "FPS: " + Math.round(customFPS) + "   ms/frame: " + Math.round(smoothedDeltaTime * 1000.0f),
        "Particle instances: " + formatWithCommas(totalCount),
        "Player height: " + String.format("%.2f", playerHeight) + " m",
        "Force registrations: " + forceRegistry.size(),
    };

    String[] controlLines = {
        "Integration [I]: " + currentIntegrationMode.name(),
        "Thrust [T]: " + ((thrustGenerator != null && thrustGenerator.isActive()) ? "ON" : "OFF"),
        "Push [WASD]: " + ((pushGenerator != null && pushGenerator.isActive()) ? "ON" : "OFF"),
        "Debug arrow [F]",
        "Explosion [E]",
        "End screen [G]"
    };

    float statLineHeight = 16.0f;
    float sectionGap = 18.0f;
    float controlLineHeight = 24.0f;
    float panelHeight = 20.0f + statLines.length * statLineHeight + sectionGap + controlLines.length * controlLineHeight + 14.0f;
    float rightEdge = width - 20.0f;
    float leftEdge = rightEdge - 380.0f;
    float top = 16.0f;

    noStroke();
    fill(0, 0, 0, 110);
    rectMode(CORNERS);
    rect(leftEdge, top, rightEdge, top + panelHeight, 10.0f);
    rectMode(CORNER);
    textAlign(RIGHT, TOP);
    float y = top + 12.0f;

    fill(190, 200, 210, 230);
    textSize(21);
    for (String line : statLines) {
        text(line, rightEdge - 14.0f, y);
        y += statLineHeight;
    }
    y += sectionGap;
    fill(235);
    textSize(16);
    for (String line : controlLines) {
        text(line, rightEdge - 14.0f, y);
        y += controlLineHeight;
    }
}
