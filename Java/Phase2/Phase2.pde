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
ArrayList<Particle> particles = new ArrayList<Particle>();

IntegrationMode currentIntegrationMode = IntegrationMode.PositionVerlet;

float totalTime = 0;
float accumulator = 0;

// --- Timing ---
float customDeltaTime = 0;
float customFPS = 0;
float smoothedDeltaTime = 0.0f;
long lastTimeMs = 0;

// Utility instances
Arena arena = new Arena();
Tests testSuite = new Tests();

public void settings() {
    //size(GraphicsConstants.ScreenWidth, GraphicsConstants.ScreenHeight, P3D); 
    fullScreen(P3D);
}

public void setup() {
    frameRate(10000); // Uncap frame rate
    lastTimeMs = System.nanoTime();
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

SpaceSphere player;
Earth earth;

void resetGame() {
    particles.clear();
    totalTime = 0;
    currentState = GameState.Playing;
    
    // Position Earth massively BELOW the origin (-Y direction)
    earth = new Earth(new Point3D(0.0f, -6371000.0f, 0.0f)); 
    
    // Position Bot at origin
    player = new SpaceSphere(
        new Point3D(0.0f, 100.0f, 0.0f), 
        new Vector3D(0.0f, 0.0f, 50.0f)
    );
    
    particles.add(earth);
    particles.add(player);
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
    text("There will be text", width / 2.0f, height / 2.0f - 10.0f);

    fill(50, 255, 140);
    textSize(24);
    text("Press [SPACE] or [ENTER] to Start", width / 2.0f, height / 2.0f + 120.0f);
}

void drawGameplay() {
    // 1. RUN PHYSICS FIRST
    float frameTime = min(customDeltaTime, PhysicsConstants.MAX_FRAME_TIME);
    accumulator += frameTime;

    while (accumulator >= PhysicsConstants.FIXED_TIMESTEP) {
        updateParticles(PhysicsConstants.FIXED_TIMESTEP);
        accumulator -= PhysicsConstants.FIXED_TIMESTEP;
    }

    // 2. SETUP LIGHTING AND CAMERA
    arena.setupLighting(this);
    
    if (player != null) {
        Point3D pos = player.getPosition();
        Vector3D vel = player.getVelocity();
        
        Vector3D dir = vel.normalized();
        if (dir.length() == 0.0f) {
            dir = new Vector3D(0.0f, 0.0f, 1.0f); 
        }
        
        // Position camera 10m behind and 4m ABOVE (+Y) the sphere
        float distanceBehind = 10.0f;
        float heightAbove = 4.0f; // Positive Y is now visually Up
        
        camera(
            pos.getX() - dir.getX() * distanceBehind, 
            pos.getY() + heightAbove, 
            pos.getZ() - dir.getZ() * distanceBehind, // Eye Position
            pos.getX(), pos.getY(), pos.getZ(),       // Target Position
            0.0f, -1.0f, 0.0f                         // Up Vector is now flipped!
        );
        
        perspective(PI/3.0f, (float)width/height, 0.1f, 10000.0f);
    }

    // 3. RENDER EVERYTHING
    arena.draw(this); 
    RenderParticles();
    renderHUD();
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
}

public void mouseWheel(MouseEvent event) {
    if (currentState != GameState.Playing) return;
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


void updateParticles(float timestep) {
    for (Particle particle : particles) {
       particle.integrate(timestep, currentIntegrationMode);
    }  
}

void RenderParticles() {
    for (Particle particle : particles) {
        particle.draw();
    }
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
}

// Compact performance readout (small text) and the list of active key
// bindings, both stacked along the right edge of the screen.
void renderSidePanel() {
    int totalCount = particles.size();

    String[] statLines = {
        "FPS: " + Math.round(customFPS) + "   ms/frame: " + Math.round(smoothedDeltaTime * 1000.0f),
        "Particle instances: " + formatWithCommas(totalCount),
    };


    String[] controlLines = {
        "Integration [I]: " + currentIntegrationMode.name(),
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
