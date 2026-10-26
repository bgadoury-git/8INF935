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
Point3D smoothedCamPos = new Point3D(0.0f, 0.0f, 0.0f); 

// --- Gameplay State ---
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Cable> cables = new ArrayList<Cable>();
ArrayList<AnalyticalSlope> analyticalSlopes = new ArrayList<AnalyticalSlope>();

// --- Blob Mechanics State ---
ArrayList<Particle> blobParticles = new ArrayList<Particle>();
ArrayList<Particle> loneParticles = new ArrayList<Particle>();

class BlobConnection {
    Particle parent;
    Particle child;
    ElasticLink link;
    BlobConnection(Particle p, Particle c, ElasticLink l) { 
        this.parent = p; 
        this.child = c; 
        this.link = l; 
    }
}
ArrayList<BlobConnection> activeConnections = new ArrayList<BlobConnection>();

// --- Tuning Constants for Blob ---
final float ATTACH_DISTANCE = 4.0f;
final float DETACH_DISTANCE = 5.5f; 
final float SPRING_K_MAIN = 25.0f;      
final float SPRING_K_SECONDARY = 10.0f; 
final float SPRING_REST = 2.0f;

// --- System Integrations ---
ForceRegistry forceRegistry = new ForceRegistry(); 
GravityGenerator gravityGenerator = new GravityGenerator(new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f));

ContactFrictionGenerator contactFriction = new ContactFrictionGenerator();
DragForceGenerator airDrag = new DragForceGenerator(0.1f, 0.02f);
boolean frictionEnabled = true;
boolean frictionKeyDown = false;
boolean materialKeyDown = false;

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

SpaceSphere player;
Earth earth;

void resetGame() {
    particles.clear();
    cables.clear();
    forceRegistry.clear();
    drawableForces.clear();
    analyticalSlopes.clear(); 
    
    blobParticles.clear();
    loneParticles.clear();
    activeConnections.clear();
    
    totalTime = 0;
    currentState = GameState.Playing;
    
    earth = new Earth(new Point3D(0.0f, -6371000.0f, 0.0f)); 
    
    // --- SETUP ANALYTICAL SLOPES ---
    AnalyticalSlope slope1 = new AnalyticalSlope(new Point3D(-15.0f, 1.0f, 0.0f), 25.0f, 10.0f, 15.0f, Material.WOOD);
    analyticalSlopes.add(slope1);
    
    player = new SpaceSphere(new Point3D(-3.0f, 6.5f, 0.0f), new Vector3D(0.0f, 0.0f, 0.0f));
    player.setMaterial(Material.RUBBER);
    
    particles.add(earth);
    particles.add(player);
    blobParticles.add(player);

    AnalyticalSlope slope2 = new AnalyticalSlope(new Point3D(-15.0f, 1.0f, -15.0f), 25.0f, 10.0f, 10.0f, Material.WOOD);
    analyticalSlopes.add(slope2);
    SmallSphere staticBall = new SmallSphere(new Point3D(-3.0f, 4.5f, -15.0f), new Vector3D(0.0f, 0.0f, 0.0f));
    staticBall.setMaterial(Material.WOOD);
    particles.add(staticBall);
    loneParticles.add(staticBall);

    AnalyticalSlope slope3 = new AnalyticalSlope(new Point3D(-15.0f, 1.0f, 15.0f), 25.0f, 10.0f, 35.0f, Material.WOOD);
    analyticalSlopes.add(slope3);
    SmallSphere rollingBall = new SmallSphere(new Point3D(-3.0f, 14.5f, 15.0f), new Vector3D(0.0f, 0.0f, 0.0f));
    rollingBall.setMaterial(Material.STEEL);
    particles.add(rollingBall);
    loneParticles.add(rollingBall);

    for (int i = 0; i < 120; i++) {
        float angle = random(TWO_PI);
        float dist = random(25.0f, 200.0f);
        float px = cos(angle) * dist;
        float pz = sin(angle) * dist;
        
        Particle scatteredPart;
        if (i % 3 == 0) {
            SpaceSphere ball = new SpaceSphere(new Point3D(px, 1.0f, pz), new Vector3D());
            ball.setMaterial(Material.RUBBER);
            scatteredPart = ball;
        } else if (i % 3 == 1) {
            SmallSphere sm = new SmallSphere(new Point3D(px, 1.0f, pz), new Vector3D());
            sm.setMaterial(Material.WOOD);
            scatteredPart = sm;
        } else {
            SmallSphere sm = new SmallSphere(new Point3D(px, 1.0f, pz), new Vector3D());
            sm.setMaterial(Material.STEEL);
            scatteredPart = sm;
        }
        
        particles.add(scatteredPart);
        loneParticles.add(scatteredPart);
    }

    for (Particle p : particles) {
        if (p.getAffectedByGravity()) {
            forceRegistry.add(p, gravityGenerator);
        }
    }
    
    thrustGenerator = new ConstantForceGenerator(new Vector3D(0.0f, THRUST_WEIGHT_RATIO * player.getMass() * PhysicsConstants.GRAVITY, 0.0f));
    thrustGenerator.setActive(false);
    pushGenerator = new ConstantForceGenerator(new Vector3D());
    pushGenerator.setActive(false);
    forceRegistry.add(player, thrustGenerator);
    forceRegistry.add(player, pushGenerator);

    setupFriction();
}

void setupFriction() {
    for (Particle p : particles) {
        if (p.getInverseMass() > 0.0f) {
            forceRegistry.add(p, airDrag);
        }
    }
}

void toggleFriction() {
    frictionEnabled = !frictionEnabled;
    contactFriction.setEnabled(frictionEnabled);
    airDrag.setEnabled(frictionEnabled);
}

void cyclePlayerMaterial() {
    if (player == null) return;
    Material[] all = Material.values();
    player.setMaterial(all[(player.getMaterial().ordinal() + 1) % all.length]);
}

boolean areConnected(Particle p1, Particle p2) {
    if (p1 == p2) return true;
    for (BlobConnection conn : activeConnections) {
        if ((conn.parent == p1 && conn.child == p2) || (conn.parent == p2 && conn.child == p1)) {
            return true;
        }
    }
    return false;
}

int getConnectionCount(Particle p) {
    int count = 0;
    for (BlobConnection conn : activeConnections) {
        if (conn.parent == p || conn.child == p) {
            count++;
        }
    }
    return count;
}

void updateBlobLogic() {
    for (int i = activeConnections.size() - 1; i >= 0; i--) {
        BlobConnection conn = activeConnections.get(i);
        if (conn.link.length() > DETACH_DISTANCE) {
            conn.link.breakLink();
            activeConnections.remove(i);
            
            boolean stillConnected = false;
            for (BlobConnection otherConn : activeConnections) {
                if (otherConn.parent == conn.child || otherConn.child == conn.child) {
                    stillConnected = true;
                    break;
                }
            }
            
            if (!stillConnected && conn.child != player) {
                blobParticles.remove(conn.child);
                if (!loneParticles.contains(conn.child)) {
                    loneParticles.add(conn.child);
                }
            }
        }
    }

    boolean attachmentFound = true;
    while (attachmentFound) {
        attachmentFound = false;
        
        for (int i = loneParticles.size() - 1; i >= 0; i--) {
            Particle lone = loneParticles.get(i);
            
            float distToPlayer = (float) lone.getPosition().distanceTo(player.getPosition());
            if (distToPlayer < ATTACH_DISTANCE && !areConnected(lone, player)) {
                ElasticLink newLink = new ElasticLink(player, lone, SPRING_K_MAIN, SPRING_REST, DETACH_DISTANCE);
                activeConnections.add(new BlobConnection(player, lone, newLink));
                
                loneParticles.remove(i);
                if (!blobParticles.contains(lone)) {
                    blobParticles.add(lone);
                }
                attachmentFound = true;
                break;
            }
            
            if (getConnectionCount(lone) >= 3) continue; 
            
            Particle nearestBlobNode = null;
            float minDst = Float.MAX_VALUE;
            
            for (Particle blobP : blobParticles) {
                if (blobP == player) continue; 
                if (areConnected(lone, blobP)) continue;
                if (getConnectionCount(blobP) >= 3) continue; 
                
                float dist = (float) lone.getPosition().distanceTo(blobP.getPosition());
                if (dist < minDst) {
                    minDst = dist;
                    nearestBlobNode = blobP;
                }
            }
            
            if (nearestBlobNode != null && minDst < ATTACH_DISTANCE) {
                ElasticLink newLink = new ElasticLink(nearestBlobNode, lone, SPRING_K_SECONDARY, SPRING_REST, DETACH_DISTANCE);
                activeConnections.add(new BlobConnection(nearestBlobNode, lone, newLink));
                
                loneParticles.remove(i);
                if (!blobParticles.contains(lone)) {
                    blobParticles.add(lone);
                }
                attachmentFound = true;
                break; 
            }
        }
        
        if (attachmentFound) continue;

        for (int i = 0; i < blobParticles.size(); i++) {
            Particle p1 = blobParticles.get(i);
            if (p1 != player && getConnectionCount(p1) >= 3) continue;
            
            for (int j = i + 1; j < blobParticles.size(); j++) {
                Particle p2 = blobParticles.get(j);
                if (p2 != player && getConnectionCount(p2) >= 3) continue;
                
                if (areConnected(p1, p2)) continue;
                
                float dist = (float) p1.getPosition().distanceTo(p2.getPosition());
                if (dist < ATTACH_DISTANCE * 0.85f) {
                    float springK = (p1 == player || p2 == player) ? SPRING_K_MAIN : SPRING_K_SECONDARY;
                    
                    ElasticLink newLink = new ElasticLink(p1, p2, springK, SPRING_REST, DETACH_DISTANCE);
                    activeConnections.add(new BlobConnection(p1, p2, newLink));
                    attachmentFound = true;
                    break;
                }
            }
            if (attachmentFound) break;
        }
    }
}

// Camera smoothing state variables
Point3D smoothedCamTarget = null;

void drawGameplay() {
    float frameTime = min(customDeltaTime, PhysicsConstants.MAX_FRAME_TIME);
    accumulator += frameTime;

    updatePlayerControls();
    updateBlobLogic();
    
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
    hint(ENABLE_DEPTH_TEST); // Ensure 3D depth calculations are active for the world
    
    if (player != null) {
        Point3D pos = player.getPosition();
        Vector3D vel = player.getVelocity();
        Vector3D flatVel = new Vector3D(vel.getX(), 0.0f, vel.getZ());
        
        if (flatVel.lengthSquared() > 0.01f) {
            currentCamDir = currentCamDir.mult(0.95f).add(flatVel.normalized().mult(0.05f)).normalized();
        }
        
        if (totalTime < 2.5f) {
            currentCamDir = new Vector3D(0.0f, 0.0f, 1.0f);
        }

        float distanceBehind = 26.0f;
        float heightAbove = 10.0f; 
        
        Point3D targetCamPos = new Point3D(
            pos.getX() - currentCamDir.getX() * distanceBehind, 
            pos.getY() + heightAbove, 
            pos.getZ() - currentCamDir.getZ() * distanceBehind
        );
        
        Point3D targetCamLookAt = new Point3D(pos.getX(), pos.getY() + 1.0f, pos.getZ());

        if (smoothedCamPos == null) {
            smoothedCamPos = targetCamPos;
            smoothedCamTarget = targetCamLookAt;
        } else {
            float camLerp = 0.08f; 
            smoothedCamPos = new Point3D(
                smoothedCamPos.getX() + (targetCamPos.getX() - smoothedCamPos.getX()) * camLerp,
                smoothedCamPos.getY() + (targetCamPos.getY() - smoothedCamPos.getY()) * camLerp,
                smoothedCamPos.getZ() + (targetCamPos.getZ() - smoothedCamPos.getZ()) * camLerp
            );
            smoothedCamTarget = new Point3D(
                smoothedCamTarget.getX() + (targetCamLookAt.getX() - smoothedCamTarget.getX()) * 0.15f,
                smoothedCamTarget.getY() + (targetCamLookAt.getY() - smoothedCamTarget.getY()) * 0.15f,
                smoothedCamTarget.getZ() + (targetCamLookAt.getZ() - smoothedCamTarget.getZ()) * 0.15f
            );
        }
        
        camera(
            smoothedCamPos.getX(), smoothedCamPos.getY(), smoothedCamPos.getZ(), 
            smoothedCamTarget.getX(), smoothedCamTarget.getY(), smoothedCamTarget.getZ(),                 
            0.0f, -1.0f, 0.0f                                   
        );
        
        perspective(PI/3.0f, (float)width/height, 0.1f, 10000.0f);
    }

    arena.draw(this); 
    RenderParticles();
    RenderCables();
    RenderSlopes();
    
    for (DrawableForceBinding df : drawableForces) {
        df.fg.draw(df.particle);
    }

    if (showForceDebug) RenderForceDebug();
    
    renderHUD(); // Automatically calls reset2DContext() which disables depth test for clean overlay rendering
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

void RenderSlopes() {
    for (AnalyticalSlope slope : analyticalSlopes) {
        slope.draw(this);
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
        if (key == ' ') {
            // Give the player core (and attached blob) a small upward jump impulse
            if (player != null) {
                player.applyImpulse(new Vector3D(0.0f, 250.0f, 0.0f));
            }
        }
        if (k == 'f' && !debugKeyDown) {
            debugKeyDown = true;
            showForceDebug = !showForceDebug;
        }
        if (k == 'e' && !explosionKeyDown) {
            explosionKeyDown = true;
            explosionRequested = true;
        }
        if (k == 'c' && !frictionKeyDown) {
            frictionKeyDown = true;
            toggleFriction();
        }
        if (k == 'm' && !materialKeyDown) {
            materialKeyDown = true;
            cyclePlayerMaterial();
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
    if (k == 'c') frictionKeyDown = false;
    if (k == 'm') materialKeyDown = false;
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

void reset2DContext() { 
    hint(DISABLE_DEPTH_TEST); // Disables depth buffer clipping for 2D UI elements
    camera(); 
    noLights(); 
    noStroke(); 
}
String formatWithCommas(int value) { return String.format("%,d", value); }
void renderHUD() { reset2DContext(); renderScoreHUD(); renderSidePanel(); }

void renderScoreHUD() {
    float cx = width / 2.0f;
    float cy = height * 0.1f;

    noStroke();
    fill(0, 0, 0, 120);
    rectMode(CENTER);
    rect(cx, cy, 280.0f, 120.0f, 14.0f);
    rectMode(CORNER);
    
    textAlign(CENTER, CENTER);
    fill(255, 210, 60);
    textSize(20);
    text("BLOB SIZE", cx, cy - 34.0f);
    
    textSize(54);
    fill(70, 255, 120);
    text(blobParticles.size(), cx, cy + 10.0f);
}

void renderSidePanel() {
    int totalCount = particles.size();
    float playerHeight = (player != null) ? player.getPosition().getY() : 0.0f;
    String[] statLines = {
        "FPS: " + Math.round(customFPS) + "   ms/frame: " + Math.round(smoothedDeltaTime * 1000.0f),
        "Particle instances: " + formatWithCommas(totalCount),
        "Blob count: " + formatWithCommas(blobParticles.size()),
        "Force registrations: " + forceRegistry.size(),
        "Player contact: " + (player != null ? contactFriction.getState(player).name() : "-"),
        "Player material: " + (player != null ? player.getMaterial().name() : "-"),
    };

String[] controlLines = {
        "Integration [I]: " + currentIntegrationMode.name(),
        "Thrust [T]: " + ((thrustGenerator != null && thrustGenerator.isActive()) ? "ON" : "OFF"),
        "Push [WASD] | Jump [SPACE]",
        "Debug arrow [F]",
        "Explosion [E]",
        "Friction [C]: " + (frictionEnabled ? "ON" : "OFF"),
        "Player material [M]",
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
