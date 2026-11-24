// ==========================================
// Phase 3 : fichier principal du sketch
// ------------------------------------------
// Scene de test visuelle pour RigidBody et interceptLine()
// Game loop with Main Menu, Model Viewer, Game (TODO) and End Screen
// ==========================================

// ── Scene state machine ──────────────────────────────────────────────
enum Scene { MAIN_MENU, MODEL_VIEWER, GAME, END_SCREEN }
Scene currentScene = Scene.MAIN_MENU;

// ── Model Viewer state ───────────────────────────────────────────────
ArrayList<RigidBody> bodies;
ArrayList<Point3D> hitDots;

Point3D lastRayStart = null;
Point3D lastRayEnd   = null;
String  lastHitInfo  = "Click anywhere on a shape to shoot a ray.";

boolean autoRotate = true;
GraphBody graphBody;
int currentPatternIndex = 3; // Starts on TREFOIL_KNOT

// fixed-timestep simulation
ForceRegistry    forceRegistry        = new ForceRegistry();
IntegrationMode  currentIntegrationMode = IntegrationMode.VelocityVerlet;
float            timeAccumulator      = 0.0f;
long             lastTimeNs           = 0;
final float      KICK_SPEED           = 80.0f;

// Camera parameters
float camX, camY, camZ;
float targetX, targetY, targetZ;

// ── Button helpers ───────────────────────────────────────────────────
// A lightweight struct-like class for clickable rectangles
class Button {
    String label;
    float  x, y, w, h;
    color  base, hover, textCol;

    Button(String label, float x, float y, float w, float h,
           color base, color hover, color textCol) {
        this.label   = label;
        this.x       = x;  this.y = y;
        this.w       = w;  this.h = h;
        this.base    = base;
        this.hover   = hover;
        this.textCol = textCol;
    }

    boolean isOver() {
        return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
    }

    void draw() {
        noStroke();
        fill(isOver() ? hover : base);
        rect(x, y, w, h, 8);
        fill(textCol);
        textAlign(CENTER, CENTER);
        textSize(18);
        text(label, x + w * 0.5f, y + h * 0.5f);
    }
}

// ── Menu buttons (created in setup) ──────────────────────────────────
Button btnModelViewer, btnGame, btnQuit;        // Main menu
Button btnEndReplay, btnEndMainMenu;            // End screen
Button btnViewerBack;                           // Model Viewer HUD
Button btnGameBack;                             // Game HUD (TODO)

// ==========================================
//  SETUP
// ==========================================
void setup() {
    size(800, 600, P3D);

    // Camera defaults
    camX    = width  * 0.5f;
    camY    = height * 0.5f;
    camZ    = (height * 0.5f) / tan(PI / 6.0f);
    targetX = width  * 0.5f;
    targetY = height * 0.5f;
    targetZ = 0.0f;

    // Build buttons ------------------------------------------------
    float bW = 260, bH = 50;
    float bX = width * 0.5f - bW * 0.5f;
    color bBase  = color(50, 100, 180);
    color bHover = color(80, 140, 230);
    color bText  = color(255);

    // Main menu
    btnModelViewer = new Button("Model Viewer",   bX, 230, bW, bH, bBase,          bHover,          bText);
    btnGame        = new Button("Game  (TODO)",   bX, 300, bW, bH, color(60,60,80),color(80,80,110),bText);
    btnQuit        = new Button("Quit",           bX, 370, bW, bH, color(160,40,40),color(210,60,60),bText);

    // End screen
    btnEndReplay   = new Button("Replay",         bX, 280, bW, bH, bBase,          bHover,          bText);
    btnEndMainMenu = new Button("Back to Main Menu", bX, 350, bW, bH, color(80,80,80),color(110,110,110),bText);

    // In-scene back buttons (top-right corner)
    btnViewerBack  = new Button("< Main Menu", width - 155, 10, 145, 34, color(60,60,60), color(100,100,100), bText);
    btnGameBack    = new Button("< Main Menu", width - 155, 10, 145, 34, color(60,60,60), color(100,100,100), bText);

    // Build Model Viewer scene
    initModelViewer();

    new IntegratorTests().run();
    lastTimeNs = System.nanoTime();
}

// ==========================================
//  DRAW  — dispatches per scene
// ==========================================
void draw() {
    switch (currentScene) {
        case MAIN_MENU:   drawMainMenu();   break;
        case MODEL_VIEWER: drawModelViewer(); break;
        case GAME:        drawGame();       break;
        case END_SCREEN:  drawEndScreen();  break;
    }
}

// ==========================================
//  MOUSE PRESSED — dispatches per scene
// ==========================================
void mousePressed() {
    switch (currentScene) {
        case MAIN_MENU:    handleMainMenuClick();    break;
        case MODEL_VIEWER: handleModelViewerClick(); break;
        case GAME:         handleGameClick();        break;
        case END_SCREEN:   handleEndScreenClick();   break;
    }
}

// ==========================================
//  KEY PRESSED — only relevant in scenes
// ==========================================
void keyPressed() {
    if (currentScene == Scene.MODEL_VIEWER) {
        handleModelViewerKey();
    }
    // ESC always goes back to main menu (instead of closing the sketch)
    if (keyCode == ESC) {
        key = 0; // suppress Processing's default quit-on-ESC
        goToMainMenu();
    }
}

// ==========================================
//  SCENE TRANSITIONS
// ==========================================
void goToMainMenu() {
    currentScene = Scene.MAIN_MENU;
}

void startModelViewer() {
    // Re-init so physics are fresh each visit
    initModelViewer();
    lastTimeNs  = System.nanoTime();
    currentScene = Scene.MODEL_VIEWER;
}

void startGame() {
    // TODO: initialise game state here
    currentScene = Scene.GAME;
}

void goToEndScreen() {
    currentScene = Scene.END_SCREEN;
}

// ==========================================
//  MAIN MENU
// ==========================================
void drawMainMenu() {
    background(20, 20, 35);
    camera();
    noLights();

    // Title
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(42);
    text("Phase 3", width * 0.5f, 110);
    textSize(18);
    fill(160);
    text("RigidBody Physics Engine", width * 0.5f, 162);

    // Separator
    stroke(80);
    strokeWeight(1);
    line(width * 0.25f, 195, width * 0.75f, 195);
    noStroke();

    // Buttons
    btnModelViewer.draw();
    btnGame.draw();
    btnQuit.draw();

    // Footer
    textSize(12);
    fill(80);
    textAlign(CENTER, BOTTOM);
    text("8INF935 — Simulation physique", width * 0.5f, height - 10);
}

void handleMainMenuClick() {
    if (btnModelViewer.isOver()) {
        startModelViewer();
    } else if (btnGame.isOver()) {
        // Game is TODO — do nothing (button is visually dimmed)
    } else if (btnQuit.isOver()) {
        exit();
    }
}

// ==========================================
//  MODEL VIEWER
// ==========================================
void initModelViewer() {
    bodies  = new ArrayList<RigidBody>();
    hitDots = new ArrayList<Point3D>();

    lastRayStart = null;
    lastRayEnd   = null;
    lastHitInfo  = "Click anywhere on a shape to shoot a ray.";
    autoRotate   = true;
    currentPatternIndex = 3;
    forceRegistry       = new ForceRegistry();
    timeAccumulator     = 0.0f;

    float cx = width  * 0.5f;
    float cy = height * 0.5f;

    // 1. TriangleBody
    TriangleBody triangle = new TriangleBody(
        new Point3D(cx - 240, cy - 90, 0),
        new Quaternion(new Vector3D(0, 1, 0), 0.3f),
        15.0f,
        0.0f, -45.0f, 0.0f,
        -45.0f, 35.0f, 0.0f,
        45.0f, 35.0f, 0.0f,
        4.0f, 1.0f, 1.0f
    );
    bodies.add(triangle);

    // 2. SquareBody
    SquareBody boxBody = new SquareBody(
        new Point3D(cx + 220, cy - 90, 0),
        new Quaternion(new Vector3D(1, 1, 0), 0.5f),
        20.0f,
        75.0f, 55.0f, 55.0f,
        new Vector3D(0.7f, 0.0f, 0.0f)
    );
    bodies.add(boxBody);

    // 3. cylenderBody
    cylenderBody cylinder = new cylenderBody(
        new Point3D(cx - 220, cy + 120, 0),
        new Quaternion(new Vector3D(1, 0, 0.3f), 0.4f),
        25.0f,
        32.0f, 85.0f,
        1.0f, 6.0f, 2.0f
    );
    bodies.add(cylinder);

    // 4. GraphBody
    GraphShapePattern[] patterns = GraphShapePattern.values();
    graphBody = new GraphBody(
        new Point3D(cx + 210, cy + 120, 0),
        new Quaternion(new Vector3D(0, 1, 0), 0.2f),
        30.0f,
        24,
        patterns[currentPatternIndex],
        45.0f,
        0.12f,
        new Vector3D(0.0f, 1.2f, 0.0f)
    );
    graphBody.nodeHitRadius = 8.0f;
    bodies.add(graphBody);

    for (RigidBody body : bodies) {
        body.setLinearDamping(0.1f);
        body.setAngularDamping(0.9f);
    }
}

void drawModelViewer() {
    // Fixed-timestep physics
    long now = System.nanoTime();
    float frameTime = min((now - lastTimeNs) / 1.0e9f, PhysicsConstants.MAX_FRAME_TIME);
    lastTimeNs = now;
    timeAccumulator += frameTime;
    while (timeAccumulator >= PhysicsConstants.FIXED_TIMESTEP) {
        integrateStep(bodies, forceRegistry, PhysicsConstants.FIXED_TIMESTEP, currentIntegrationMode);
        timeAccumulator -= PhysicsConstants.FIXED_TIMESTEP;
    }

    background(30);
    lights();
    camera(camX, camY, camZ, targetX, targetY, targetZ, 0, 1, 0);

    if (autoRotate) {
        Quaternion dq = new Quaternion(new Vector3D(0.3f, 1.0f, 0.2f), 0.01f);
        for (RigidBody body : bodies) {
            body.setRotationQuaternion(dq.mult(body.getRotationQuaternion()));
        }
    }

    for (RigidBody body : bodies) { body.draw(); }

    if (lastRayStart != null && lastRayEnd != null) {
        stroke(255, 230, 80, 180);
        strokeWeight(2);
        line(lastRayStart.getX(), lastRayStart.getY(), lastRayStart.getZ(),
             lastRayEnd.getX(),   lastRayEnd.getY(),   lastRayEnd.getZ());
    }

    noStroke();
    fill(50, 255, 100);
    sphereDetail(16);
    for (Point3D hit : hitDots) {
        pushMatrix();
        translate(hit.getX(), hit.getY(), hit.getZ());
        sphere(5.0f);
        popMatrix();
    }

    drawModelViewerHUD();
}

void handleModelViewerClick() {
    // Back button (2D — test before 3D ray)
    if (btnViewerBack.isOver()) {
        goToMainMenu();
        return;
    }
    if (mouseButton == LEFT) {
        shootRayFromMouse(mouseX, mouseY);
    }
}

void handleModelViewerKey() {
    if (key == ' ') {
        autoRotate = !autoRotate;
    } else if (key == 'r' || key == 'R') {
        hitDots.clear();
        lastRayStart = null;
        lastRayEnd   = null;
        lastHitInfo  = "Cleared hit markers.";
    } else if (key == 'i' || key == 'I') {
        currentIntegrationMode = nextIntegrationMode(currentIntegrationMode);
    } else if (key == 'g' || key == 'G') {
        GraphShapePattern[] patterns = GraphShapePattern.values();
        currentPatternIndex = (currentPatternIndex + 1) % patterns.length;
        int randomNodes = int(random(10, 37));
        graphBody.jitterRatio = random(0.12f, 0.35f);
        Vector3D randomSkew = new Vector3D(
            random(-1.8f, 1.8f), random(-1.8f, 1.8f), random(-1.8f, 1.8f)
        );
        graphBody.generateShape(randomNodes, patterns[currentPatternIndex], randomSkew);
        lastHitInfo = "GraphBody: " + patterns[currentPatternIndex]
            + " | Nodes: " + randomNodes
            + " | Skew: (" + nf(randomSkew.getX(), 1, 1) + ", "
            + nf(randomSkew.getY(), 1, 1) + ", "
            + nf(randomSkew.getZ(), 1, 1) + ")";
    }
}

void drawModelViewerHUD() {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();

    fill(240);
    textSize(13);
    textAlign(LEFT, TOP);
    text("Controls: [Left Click] Shoot Ray   [SPACE] Pause/Rotate   [G] Cycle Graph   [R] Clear   [ESC] Menu", 15, 15);
    text("Status: " + lastHitInfo + "   |   Total Hits: " + hitDots.size(), 15, 35);
    text("[I] Integrator: " + currentIntegrationMode.name() + "   |   A hit gives an impulse at the hit point", 15, 55);

    textAlign(CENTER, TOP);
    fill(180);
    text("TriangleBody (Uneven)",         width * 0.5f - 240, height * 0.5f - 165);
    text("SquareBody (Biased)",           width * 0.5f + 220, height * 0.5f - 165);
    text("cylenderBody (Bottom-Heavy)",   width * 0.5f - 220, height * 0.5f + 195);
    text("GraphBody (" + graphBody.shapePattern + ", n=" + graphBody.nodeCount + ")",
         width * 0.5f + 210, height * 0.5f + 195);

    // Weight gradient legend
    textAlign(LEFT, CENTER);
    fill(220);
    text("%TotalWeight:", 15, height - 22);
    int barX = 115, barY = height - 28, barW = 150, barH = 12;
    for (int i = 0; i < barW; i++) {
        float t = (float)i / barW;
        int c = (t < 0.5f)
            ? lerpColor(color(45, 135, 255), color(60, 225, 130), t * 2.0f)
            : lerpColor(color(60, 225, 130), color(255, 65, 50), (t - 0.5f) * 2.0f);
        stroke(c);
        line(barX + i, barY, barX + i, barY + barH);
    }
    noStroke();
    fill(180);
    text("Low          Avg          High    |    Yellow/Magenta Crosshair = Center of Mass",
         barX + barW + 10, height - 22);

    // Back button
    btnViewerBack.draw();

    hint(ENABLE_DEPTH_TEST);
}

// ── Ray shooter (unchanged logic) ────────────────────────────────────
void shootRayFromMouse(float mx, float my) {
    Point3D rayOrigin = new Point3D(camX, camY, camZ);

    float fov    = PI / 3.0f;
    float aspect = (float)width / (float)height;
    float ndcX   = (2.0f * mx / width)  - 1.0f;
    float ndcY   = (2.0f * my / height) - 1.0f;

    float halfH = camZ * tan(fov * 0.5f);
    float halfW = halfH * aspect;

    Point3D planePoint = new Point3D(
        targetX + ndcX * halfW,
        targetY + ndcY * halfH,
        0.0f
    );

    Vector3D dir    = planePoint.sub(rayOrigin).normalized();
    Point3D  rayEnd = rayOrigin.add(dir.mult(camZ * 2.0f));

    lastRayStart = rayOrigin;
    lastRayEnd   = rayEnd;

    Point3D  closestHit = null;
    RigidBody hitBody   = null;
    float    bestDistSq = Float.MAX_VALUE;

    for (RigidBody body : bodies) {
        Point3D hit = body.interceptLine(rayOrigin, rayEnd);
        if (hit != null) {
            float dSq = rayOrigin.distanceSquaredTo(hit);
            if (dSq < bestDistSq) {
                bestDistSq  = dSq;
                closestHit  = hit;
                hitBody     = body;
            }
        }
    }

    if (closestHit != null) {
        hitDots.add(closestHit);
        hitBody.applyImpulseAtPoint(dir.mult(hitBody.getMass() * KICK_SPEED), closestHit);
        lastHitInfo = "HIT " + hitBody.getClass().getSimpleName() + " at ("
            + nf(closestHit.getX(), 1, 1) + ", "
            + nf(closestHit.getY(), 1, 1) + ", "
            + nf(closestHit.getZ(), 1, 1) + ")";
    } else {
        lastHitInfo = "MISS (no intersection)";
    }
}

// ==========================================
//  GAME  (TODO placeholder)
// ==========================================
void drawGame() {
    background(15, 20, 15);
    camera();
    noLights();

    fill(255);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("Game", width * 0.5f, height * 0.5f - 60);

    textSize(20);
    fill(140);
    text("Coming soon…", width * 0.5f, height * 0.5f);

    textSize(14);
    fill(90);
    text("Press [ESC] or use the button to return to the main menu.", width * 0.5f, height * 0.5f + 50);

    // Back button (top-right)
    btnGameBack.draw();
}

void handleGameClick() {
    if (btnGameBack.isOver()) {
        goToMainMenu();
    }
    // TODO: add game input handling here
}

// ==========================================
//  END SCREEN
// ==========================================
void drawEndScreen() {
    background(20, 10, 10);
    camera();
    noLights();

    // Title
    fill(255, 80, 80);
    textAlign(CENTER, CENTER);
    textSize(48);
    text("Game Over", width * 0.5f, 140);

    textSize(16);
    fill(180);
    text("Thanks for playing!", width * 0.5f, 210);

    // Buttons
    btnEndReplay.draw();
    btnEndMainMenu.draw();

    textSize(12);
    fill(70);
    textAlign(CENTER, BOTTOM);
    text("[ESC] returns to Main Menu", width * 0.5f, height - 10);
}

void handleEndScreenClick() {
    if (btnEndReplay.isOver()) {
        startGame();          // restart game
    } else if (btnEndMainMenu.isOver()) {
        goToMainMenu();
    }
}
