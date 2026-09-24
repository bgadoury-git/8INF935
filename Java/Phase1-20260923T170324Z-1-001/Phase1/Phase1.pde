import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.IntStream;

// --- State Machine ---
enum GameState {
    Menu, Playing, GameOver
}

GameState currentState = GameState.Menu;

// --- Gameplay State ---
final int neededGoal = 10;  
ArrayList<Particle> particles = new ArrayList<Particle>();

// Contiguous Swap-and-Pop Pool
final int MAX_CONFETTI_POOL = 2000000;
Confetti[] Confettis = new Confetti[MAX_CONFETTI_POOL];
int activeConfetti = 0;
float confettiSpawnAccumulator = 0.0f;
int confettiRecycleCursor = 0;

AimMode currentAimMode = AimMode.TurretSpherical;
SelectedProjectile currentProjectile = SelectedProjectile.Bullet;
boolean showTrajectories = false;

TargetGoal goal = new TargetGoal(120.0f);
float totalTime = 0;
int confettiSpawnAmount = 0;
float accumulator = 0;
boolean solidColor = true;

boolean useVBO = true;
boolean cullConfettis = true;

// --- Timing ---
float customDeltaTime = 0;
float customFPS = 0;
float smoothedDeltaTime = 0.0f;
long lastTimeMs = 0;

// Utility instances
Arena arena = new Arena();
Cannon cannon = new Cannon();
AimSolvers aimSolvers = new AimSolvers();
ProjectileFactory projectileFactory = new ProjectileFactory();
Tests testSuite = new Tests();

public void settings() {
    fullScreen(P3D);
}

public void setup() {
    frameRate(10000); // Uncap frame rate
    lastTimeMs = System.nanoTime();
    
    // Pre-allocate the massive confetti pool once to avoid GC pauses
    for (int i = 0; i < MAX_CONFETTI_POOL; i++) {
        Confettis[i] = new Confetti();
    }
    
    // Run tests on startup
    testSuite.run();
}

public void draw() {
    actualiseDeltaTime();

    switch (currentState) {
        case Menu:
            drawMenuScreen();
            break;
        case Playing:
            drawGameplay();
            break;
        case GameOver:
            drawGameOverScreen();
            break;
    }
}

// ==========================================
// Lifecycle & State Transitions
// ==========================================

void resetGame() {
    particles.clear();
    clearConfetti();
    goal.resetValues();
    totalTime = 0;
    currentState = GameState.Playing;
}

void clearConfetti() {
    activeConfetti = 0;
    confettiSpawnAccumulator = 0.0f;
    confettiRecycleCursor = 0;
}

// ==========================================
// Render Functions
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
    text("Mouse Click: Fire Projectile", width / 2.0f, height / 2.0f - 10.0f);
    text("Mouse Wheel: Cycle Ammo Type", width / 2.0f, height / 2.0f + 20.0f);
    text("[M]: Toggle Aim Mode | [T]: Display All Trajectories", width / 2.0f, height / 2.0f + 50.0f);

    fill(50, 255, 140);
    textSize(24);
    text("Press [SPACE] or [ENTER] to Start", width / 2.0f, height / 2.0f + 120.0f);
}

void drawGameplay() {
    arena.setupLighting(this);
    arena.draw(this);
    cannon.draw(this);
    goal.draw(this);

    spawnConfettis(confettiSpawnAmount * customDeltaTime);

    // Clamp frame time to handle hitches/breakpoints
    float frameTime = min(customDeltaTime, PhysicsConstants.MAX_FRAME_TIME);

    accumulator += frameTime;

    while (accumulator >= PhysicsConstants.FIXED_TIMESTEP) {
        updateParticles(PhysicsConstants.FIXED_TIMESTEP);
        accumulator -= PhysicsConstants.FIXED_TIMESTEP;
    }

    RenderParticles();
    renderAimPreview();
    renderHUD();

    // Game over trigger check
    if (goal.getScore() == neededGoal) {
        particles.clear();
        currentState = GameState.GameOver;
    }
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

// ==========================================
// Input Handling
// ==========================================

public void mousePressed() {
    if (currentState != GameState.Playing) return;

    Vector3D velocity = computeCurrentAimVelocity();
    particles.add(
        projectileFactory.create(currentProjectile, new Point3D(0.0f, -150.0f, 0.0f), velocity)
    );
}

public void mouseWheel(MouseEvent event) {
    if (currentState != GameState.Playing) return;
    
    int delta = event.getCount();
    int optionCount = SelectedProjectile.values().length;
    int step = (delta > 0) ? 1 : -1;
    int nextIndex = (currentProjectile.ordinal() + step) % optionCount;
    if (nextIndex < 0) {
        nextIndex += optionCount;
    }
    currentProjectile = SelectedProjectile.values()[nextIndex];
}

public void keyPressed() {
    if (currentState == GameState.Menu) {
        if (key == ' ' || keyCode == ENTER) {
            resetGame();
        }
        return;
    }

    if (currentState == GameState.GameOver) {
        if (key == 'r' || key == 'R') {
            resetGame();
        } else if (key == ' ' || keyCode == ENTER) {
            currentState = GameState.Menu;
        }
        return;
    }

    if (currentState == GameState.Playing) {
        if (key == 'm' || key == 'M') {
            currentAimMode = (currentAimMode == AimMode.RayGroundTarget)
                ? AimMode.TurretSpherical
                : AimMode.RayGroundTarget;
        }
        if (key == 't' || key == 'T') {
            showTrajectories = !showTrajectories;
        }
        if (key == 'g' || key == 'G') {
            currentState = GameState.GameOver;
        }
        if (key == 'w' || key == 'W')
            confettiSpawnAmount += 10000;
        if ((key == 's' || key == 'S') && confettiSpawnAmount > 0)
            confettiSpawnAmount -= 10000;
        if (key == 'c' || key == 'C') {
            solidColor = !solidColor;
        }
        if (key == 'v' || key == 'V') {
            useVBO = !useVBO;
        }
        if (key == 'b' || key == 'B') {
            cullConfettis = !cullConfettis;
        }
    }
}

void actualiseDeltaTime() {
    long currentTime = System.nanoTime();
    float elapsedMs = (currentTime - lastTimeMs) / 1000000.0f;
    lastTimeMs = currentTime;

    customDeltaTime = elapsedMs / 1000.0f;

    if (currentState == GameState.Playing)
        totalTime += customDeltaTime;

    final float smoothingAlpha = 0.08f;
    if (smoothedDeltaTime == 0.0f) {
        smoothedDeltaTime = customDeltaTime;
    } else {
        smoothedDeltaTime = smoothingAlpha * customDeltaTime + (1.0f - smoothingAlpha) * smoothedDeltaTime;
    }

    customFPS = (smoothedDeltaTime > 0.0f) ? (1.0f / smoothedDeltaTime) : 0.0f;
}

void reset2DContext() {
    camera();
    noLights();
    noStroke();
}

Vector3D computeCurrentAimVelocity() {
    float muzzleSpeed = projectileFactory.getBaseSpeed(currentProjectile);

    if (currentAimMode == AimMode.RayGroundTarget) {
        return aimSolvers.getAimGroundTarget(
            (float)mouseX, (float)mouseY,
            (float)width, (float)height,
            muzzleSpeed
        );
    }
    return aimSolvers.getAimTurret(
        (float)mouseX, (float)mouseY,
        (float)width, (float)height,
        muzzleSpeed
    );
}

void killConfetti(int index) {
    if (activeConfetti <= 0 || index >= activeConfetti) return;
    
    Confetti temp = Confettis[index];
    Confettis[index] = Confettis[activeConfetti - 1];
    Confettis[activeConfetti - 1] = temp;
    
    --activeConfetti;
}

void updateParticles(float timestep) {
    // 1. Dynamic player projectiles
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext()) {
        Particle particle = it.next();
        particle.applyVerletIntegration(timestep);

        Point3D pos = particle.getPosition();

        if (goal.checkHit(pos) || arena.isOutOfBounds(pos)) {
            it.remove();
        }
    }

    // 2. Parallel Confetti Verlet Integration (OpenMP equivalent)
    int count = activeConfetti;
    IntStream.range(0, count).parallel().forEach(i -> {
        Confettis[i].applyVerletIntegration(timestep);
    });

    // 3. Sequential Culling pass
    if (cullConfettis) {
        for (int i = 0; i < activeConfetti;) {
            Point3D pos = Confettis[i].getPosition();
            if (pos.getY() < -GraphicsConstants.floorY) {
                killConfetti(i);
            } else {
                ++i;
            }
        }
    }
}

class RGBColor {
    int r, g, b;
    RGBColor(int r, int g, int b) { this.r = r; this.g = g; this.b = b; }
}

void RenderParticles() {
    final float tailTime = 0.035f;
    final int count = activeConfetti;

    final RGBColor[] palette = {
        new RGBColor(255, 70, 70),   // Red
        new RGBColor(70, 255, 120),  // Green
        new RGBColor(70, 160, 255),  // Blue
        new RGBColor(255, 220, 50),  // Yellow
        new RGBColor(255, 120, 220), // Magenta
        new RGBColor(50, 255, 255)   // Cyan
    };

    strokeWeight(2.5f);
    noFill();

    if (!useVBO) {
        if (solidColor) {
            stroke(255, 70, 70, 255);
            beginShape(LINES);
            for (int i = 0; i < count; ++i) {
                Confetti c = Confettis[i];
                Point3D head = c.getPosition();
                Vector3D vel = c.getVelocity();

                vertex(head.getX() - vel.getX() * tailTime,
                      -(head.getY() - vel.getY() * tailTime),
                       head.getZ() - vel.getZ() * tailTime);
                vertex(head.getX(), -head.getY(), head.getZ());
            }
            endShape();
        } else {
            // SINGLE-PASS BINNING
            ArrayList<Float>[] colorBuffers = new ArrayList[6];
            for (int p = 0; p < 6; ++p) colorBuffers[p] = new ArrayList<Float>();

            for (int i = 0; i < count; ++i) {
                Confetti c = Confettis[i];
                int p = c.colorIndex;
                if (p < 0 || p >= 6) p = 0;

                Point3D head = c.getPosition();
                Vector3D vel = c.getVelocity();

                colorBuffers[p].add(head.getX() - vel.getX() * tailTime);
                colorBuffers[p].add(-(head.getY() - vel.getY() * tailTime));
                colorBuffers[p].add(head.getZ() - vel.getZ() * tailTime);
                colorBuffers[p].add(head.getX());
                colorBuffers[p].add(-head.getY());
                colorBuffers[p].add(head.getZ());
            }

            for (int p = 0; p < 6; ++p) {
                if (colorBuffers[p].isEmpty()) continue;

                stroke(palette[p].r, palette[p].g, palette[p].b, 255);
                beginShape(LINES);
                for (int j = 0; j < colorBuffers[p].size(); j += 6) {
                    vertex(colorBuffers[p].get(j), colorBuffers[p].get(j+1), colorBuffers[p].get(j+2));
                    vertex(colorBuffers[p].get(j+3), colorBuffers[p].get(j+4), colorBuffers[p].get(j+5));
                }
                endShape();
            }
        }
        noStroke();
    } else {
        // Optimized processing equivalent of VBO using direct batched beginShape
        if (solidColor) {
            stroke(255, 70, 70, 255);
            noFill();
            beginShape(LINES);
            for (int i = 0; i < count; ++i) {
                Confetti c = Confettis[i];
                Point3D head = c.getPosition();
                Vector3D vel = c.getVelocity();

                vertex(head.getX() - vel.getX() * tailTime,
                      -(head.getY() - vel.getY() * tailTime),
                       head.getZ() - vel.getZ() * tailTime);
                vertex(head.getX(), -head.getY(), head.getZ());
            }
            endShape();
        } else {
            beginShape(LINES);
            for (int i = 0; i < count; ++i) {
                Confetti c = Confettis[i];
                int p = c.colorIndex;
                if (p < 0 || p >= 6) p = 0;

                Point3D head = c.getPosition();
                Vector3D vel = c.getVelocity();

                stroke(palette[p].r, palette[p].g, palette[p].b, 255);
                vertex(head.getX() - vel.getX() * tailTime,
                      -(head.getY() - vel.getY() * tailTime),
                       head.getZ() - vel.getZ() * tailTime);
                vertex(head.getX(), -head.getY(), head.getZ());
            }
            endShape();
        }
    }
    
    for (Particle particle : particles) {
        particle.draw();
        if (showTrajectories) {
            renderParticleTrace(particle);
        }
    }
}

void renderParticleTrace(Particle particle) {
    ArrayList<Point3D> trajectory = particle.getTrajectory(20, 10.0f);

    stroke(255, 255, 0, 150);
    strokeWeight(2.0f);
    for (int i = 0; i + 1 < trajectory.size(); ++i) {
        Point3D p1 = trajectory.get(i);
        Point3D p2 = trajectory.get(i + 1);
        line(p1.getX(), -p1.getY(), p1.getZ(), p2.getX(), -p2.getY(), p2.getZ());
    }
    noStroke();
}

void renderAimPreview() {
    Point3D origin = new Point3D(0.0f, -150.0f, 0.0f);
    Vector3D gravity = new Vector3D(0.0f, -PhysicsConstants.GRAVITY, 0.0f);
    Vector3D aimVelocity = computeCurrentAimVelocity();
    Vector3D acceleration = new Vector3D(0,0,0);

    if (projectileFactory.getDefaultGravityState(currentProjectile))
        acceleration = acceleration.add(gravity);

    ArrayList<Point3D> aimTrajectory = aimSolvers.predictAimTrajectory(origin, aimVelocity, acceleration, 0.999f, 35, 30.0f);

    stroke(0, 255, 128, 180);
    strokeWeight(2.0f);
    noFill();

    beginShape();
    for (Point3D pt : aimTrajectory) {
        vertex(pt.getX(), -pt.getY(), pt.getZ());
    }
    endShape();

    noStroke();
}

String formatWithCommas(int value) {
    return String.format("%,d", value);
}

void renderHUD() {
    reset2DContext();

    renderScoreHUD();
    renderSidePanel();
}

// Big, centered score readout sitting near the cannon (which renders
// close to screen-center since the fixed camera always looks straight at it).
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
    text(goal.getScore() + " / " + neededGoal, cx, cy + 16.0f);
}

// Compact performance readout (small text) and the list of active key
// bindings, both stacked along the right edge of the screen.
void renderSidePanel() {
    int totalCount = particles.size() + MAX_CONFETTI_POOL;

    String[] statLines = {
        "FPS: " + Math.round(customFPS) + "   ms/frame: " + Math.round(smoothedDeltaTime * 1000.0f),
        "Particle instances: " + formatWithCommas(totalCount),
        "Active confettis: " + formatWithCommas(activeConfetti)
    };

    String modeText = (currentAimMode == AimMode.RayGroundTarget)
        ? "Ground Target Plane (Raycast)"
        : "Turret (Pitch/Yaw Spherical)";
    String projectileText = projectileFactory.getDisplayName(currentProjectile);

    String[] controlLines = {
        "Aim Mode [M]: " + modeText,
        "Projectile [Scroll]: " + projectileText,
        "Trajectories [T]: " + (showTrajectories ? "ON" : "OFF"),
        "Confetti rate [W/S]: " + formatWithCommas(confettiSpawnAmount) + "/s",
        "Confetti uniform [C]: " + (solidColor ? "ON" : "OFF"),
        "Multi-color variant [V]: " + (useVBO ? "ON" : "OFF"),
        "Cull at floor [B]: " + (cullConfettis ? "ON" : "OFF"),
        "End screen [G]"
    };

    float statLineHeight = 16.0f;
    float sectionGap = 18.0f;
    float controlLineHeight = 24.0f;
    float panelHeight = 20.0f
        + statLines.length * statLineHeight
        + sectionGap
        + controlLines.length * controlLineHeight
        + 14.0f;

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
    textSize(13);
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

void spawnConfettis(float quantity) {
    confettiSpawnAccumulator += quantity;
    int toSpawn = (int)confettiSpawnAccumulator;
    confettiSpawnAccumulator -= toSpawn;

    if (toSpawn <= 0) return;

    for (int i = 0; i < toSpawn; ++i) {
        float vx = (float)ThreadLocalRandom.current().nextDouble(-75.0, 75.0);
        float vy = (float)ThreadLocalRandom.current().nextDouble(200.0, 250.0);
        float vz = (float)ThreadLocalRandom.current().nextDouble(-75.0, 75.0);
        
        int targetIndex = 0;

        if (activeConfetti < MAX_CONFETTI_POOL) {
            targetIndex = activeConfetti;
            ++activeConfetti;
        } else {
            targetIndex = confettiRecycleCursor;
            confettiRecycleCursor = (confettiRecycleCursor + 1) % MAX_CONFETTI_POOL;
        }

        // ZERO-ALLOCATION FIX: Grab the existing pre-allocated objects and mutate them
        Point3D pos = Confettis[targetIndex].getPosition();
        pos.setX(0.0f);
        pos.setY(-GraphicsConstants.floorY);
        pos.setZ(600.0f);
        
        Vector3D vel = Confettis[targetIndex].getVelocity();
        vel.setX(vx);
        vel.setY(vy);
        vel.setZ(vz);
    }
}
