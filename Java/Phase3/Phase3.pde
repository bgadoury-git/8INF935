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

    void setBounds(float x, float y, float w, float h) {
        this.x = x;  this.y = y;
        this.w = w;  this.h = h;
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
    btnModelViewer = new Button("Model Viewer", bX, 230, bW, bH, bBase,            bHover,            bText);
    btnGame        = new Button("Game",         bX, 300, bW, bH, color(40,120,60), color(60,170,80),  bText);
    btnQuit        = new Button("Quit",         bX, 370, bW, bH, color(160,40,40), color(210,60,60),  bText);

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
//  MOUSE DRAGGED — right click camera drag in game
// ==========================================
void mouseDragged() {
    if (currentScene == Scene.GAME) {
        handleGameMouseDragged();
    }
}

// ==========================================
//  KEY PRESSED — only relevant in scenes
// ==========================================
void keyPressed() {
    if (currentScene == Scene.MODEL_VIEWER) {
        handleModelViewerKey();
    }
    if (currentScene == Scene.GAME) {
        handleGameKey();
    }
    // ESC always goes back to main menu (instead of closing the sketch)
    if (keyCode == ESC) {
        key = 0; // suppress Processing's default quit-on-ESC
        goToMainMenu();
    }
}

// ==========================================
//  KEY RELEASED — smooth continuous WASD movement
// ==========================================
void keyReleased() {
    if (currentScene == Scene.GAME) {
        handleGameKeyReleased();
    }
}

// ==========================================
//  SCENE TRANSITIONS
// ==========================================
void goToMainMenu() {
    keyW = false; keyA = false; keyS = false; keyD = false;
    currentScene = Scene.MAIN_MENU;
}

void startModelViewer() {
    // Re-init so physics are fresh each visit
    initModelViewer();
    lastTimeNs  = System.nanoTime();
    currentScene = Scene.MODEL_VIEWER;
}

void startGame() {
    initGame();
    currentScene = Scene.GAME;
}

void goToEndScreen() {
    keyW = false; keyA = false; keyS = false; keyD = false;
    currentScene = Scene.END_SCREEN;
}

// ==========================================
//  MAIN MENU
// ==========================================
void drawMainMenu() {
    background(20, 20, 35);
    camera();
    noLights();

    // Dynamically center buttons according to current window size
    float bW = 260, bH = 50;
    float bX = width * 0.5f - bW * 0.5f;
    float startY = height * 0.40f;
    btnModelViewer.setBounds(bX, startY, bW, bH);
    btnGame.setBounds(bX, startY + 70, bW, bH);
    btnQuit.setBounds(bX, startY + 140, bW, bH);

    // Title
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(42);
    text("Phase 3", width * 0.5f, height * 0.20f);
    textSize(18);
    fill(160);
    text("RigidBody Physics Engine", width * 0.5f, height * 0.20f + 50);

    // Separator
    stroke(80);
    strokeWeight(1);
    line(width * 0.25f, height * 0.20f + 85, width * 0.75f, height * 0.20f + 85);
    noStroke();

    // Buttons
    btnModelViewer.draw();
    btnGame.draw();
    btnQuit.draw();

    // Footer
    textSize(12);
    fill(80);
    textAlign(CENTER, BOTTOM);
    text("8INF935 — Simulation physique", width * 0.5f, height - 15);
}

void handleMainMenuClick() {
    if (btnModelViewer.isOver()) {
        startModelViewer();
    } else if (btnGame.isOver()) {
        startGame();
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
    camX    = width  * 0.5f;
    camY    = height * 0.5f;
    camZ    = (height * 0.5f) / tan(PI / 6.0f);
    targetX = camX;
    targetY = camY;
    targetZ = 0.0f;
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
    btnViewerBack.setBounds(width - 155, 12, 145, 34);
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
//  GAME  — Spin Challenge
// ==========================================
// Objects fall one at a time from above.  The player shoots them off-centre
// to make them spin.  The score for each body is its peak angular-velocity
// magnitude (rad-ish/s in physics-pixel units) while it was in play.
// Final score = sum of the 5 peak angular velocities.

final int   TOTAL_BODIES = 5;        // triangle, box, cylinder, graph A, graph B
final float GAME_KICK    = 100.0f;   // impulse magnitude on hit
final float GAME_GRAVITY = 180.0f;   // px/s² downward

// Dynamic arena sizing functions that scale with window size
float getGroundY() {
    return height - 60.0f;
}

float getSkyY() {
    return 100.0f;
}

float getArenaHalfWidth() {
    return min(width * 0.38f, width * 0.5f - 210.0f);
}

// ── Game state ────────────────────────────────────────────────────────
ArrayList<RigidBody> gameBodies;
ForceRegistry        gameRegistry;
GravityGenerator     gameGravity;

int     gameBodyIndex  = 0;      // 0-4, which body is live
boolean gameBodyAlive  = false;
float   gameTimeAccum  = 0.0f;
long    gameLastTimeNs = 0;

// Per-body peak angular speed and accumulated final score
float[] gamePeakOmega  = new float[TOTAL_BODIES];  // rad/s peak per body
float   gameFinalScore = 0.0f;                      // sum shown on end screen

// Live tracking for the current body
float   gameCurPeakOmega = 0.0f;

// Ray feedback & impact markings (only keep last impact point)
Point3D gameRayStart = null;
Point3D gameRayEnd   = null;
Point3D gameLastHit  = null;
String  gameHitInfo  = "Shoot the edge of the object to make it spin!";

// Trail tracking for Center of Mass and Furthest Vertex
ArrayList<Point3D> comTrail    = new ArrayList<Point3D>();
ArrayList<Point3D> vertexTrail = new ArrayList<Point3D>();
Point3D curFurthestLocal       = null;

// ── Single 3D camera with depth perspective & player controls ──
float gameCamDist;
float gameCX, gameCY, gameCZ;
float gameTgtX, gameTgtY, gameTgtZ;
float gameYaw   = 0.42f;
float gamePitch = 0.28f;

// WASD player movement keys
boolean keyW = false;
boolean keyA = false;
boolean keyS = false;
boolean keyD = false;

// Body labels for HUD
String[] bodyLabels = { "Triangle", "Box", "Cylinder", "Graph A", "Graph B" };

// Helper to determine the local vertex furthest away from the center of mass
Point3D getFurthestLocalVertex(RigidBody body) {
    if (body instanceof TriangleBody) {
        TriangleBody t = (TriangleBody) body;
        Point3D[] pts = {
            new Point3D(t.x1, t.y1, t.z1),
            new Point3D(t.x2, t.y2, t.z2),
            new Point3D(t.x3, t.y3, t.z3)
        };
        return findFurthestFromOrigin(pts);
    } else if (body instanceof SquareBody) {
        SquareBody s = (SquareBody) body;
        float hx = s.width * 0.5f, hy = s.height * 0.5f, hz = s.depth * 0.5f;
        Point3D[] pts = new Point3D[8];
        for (int i = 0; i < 8; i++) {
            float cx = s.geometricCenter.getX() + (((i & 1) == 0) ? -hx : hx);
            float cy = s.geometricCenter.getY() + (((i & 2) == 0) ? -hy : hy);
            float cz = s.geometricCenter.getZ() + (((i & 4) == 0) ? -hz : hz);
            pts[i] = new Point3D(cx, cy, cz);
        }
        return findFurthestFromOrigin(pts);
    } else if (body instanceof cylenderBody) {
        cylenderBody c = (cylenderBody) body;
        float halfH = c.height * 0.5f;
        float yc = c.geometricCenter.getY();
        float dTopSq = c.radius * c.radius + (yc + halfH) * (yc + halfH);
        float dBotSq = c.radius * c.radius + (yc - halfH) * (yc - halfH);
        if (dTopSq >= dBotSq) {
            return new Point3D(c.radius, yc + halfH, 0);
        } else {
            return new Point3D(c.radius, yc - halfH, 0);
        }
    } else if (body instanceof GraphBody) {
        GraphBody g = (GraphBody) body;
        if (g.nodes == null || g.nodes.isEmpty()) return new Point3D(0, 0, 0);
        Point3D best = g.nodes.get(0).localPos;
        float maxDSq = best.distanceSquaredTo(new Point3D(0, 0, 0));
        for (GraphNode node : g.nodes) {
            float dSq = node.localPos.distanceSquaredTo(new Point3D(0, 0, 0));
            if (dSq > maxDSq) {
                maxDSq = dSq;
                best = node.localPos;
            }
        }
        return best;
    }
    return new Point3D(0, 0, 0);
}

Point3D findFurthestFromOrigin(Point3D[] pts) {
    Point3D origin = new Point3D(0, 0, 0);
    Point3D best = pts[0];
    float maxDSq = best.distanceSquaredTo(origin);
    for (int i = 1; i < pts.length; i++) {
        float dSq = pts[i].distanceSquaredTo(origin);
        if (dSq > maxDSq) {
            maxDSq = dSq;
            best = pts[i];
        }
    }
    return best;
}

// ─────────────────────────────────────────────────────────────────────
void initGame() {
    gameBodies   = new ArrayList<RigidBody>();
    gameRegistry = new ForceRegistry();
    gameGravity  = new GravityGenerator(new Vector3D(0, GAME_GRAVITY, 0));

    gameBodyIndex    = 0;
    gameBodyAlive    = false;
    gameTimeAccum    = 0.0f;
    gameFinalScore   = 0.0f;
    gameCurPeakOmega = 0.0f;
    for (int i = 0; i < TOTAL_BODIES; i++) gamePeakOmega[i] = 0.0f;

    keyW = false; keyA = false; keyS = false; keyD = false;

    gameRayStart     = null;
    gameRayEnd       = null;
    gameLastHit      = null;
    comTrail.clear();
    vertexTrail.clear();
    curFurthestLocal = null;
    gameHitInfo      = "Shoot the edge of the object to make it spin!";

    setupGameCamera();
    gameLastTimeNs = System.nanoTime();
    spawnNextGameBody();
}

// Proper 3D camera: positioned at an angle looking at the arena center
void setupGameCamera() {
    float camDist = (height * 0.5f) / tan(PI / 6.0f);
    gameCamDist   = camDist * 1.05f;

    float spawnCenterX = width  * 0.5f;
    float spawnCenterY = height * 0.52f;
    float spawnCenterZ = 0.0f;

    // Default angle: yaw ~20 deg, pitch ~16 deg looking down
    gameYaw   = 0.35f;
    gamePitch = 0.28f;
    float cosP = cos(gamePitch);

    Vector3D forward = new Vector3D(
        sin(gameYaw) * cosP,
        sin(gamePitch),
        -cos(gameYaw) * cosP
    ).normalized();

    gameCX = spawnCenterX - forward.getX() * gameCamDist;
    gameCY = spawnCenterY - forward.getY() * gameCamDist;
    gameCZ = spawnCenterZ - forward.getZ() * gameCamDist;

    gameTgtX = gameCX + forward.getX() * 500.0f;
    gameTgtY = gameCY + forward.getY() * 500.0f;
    gameTgtZ = gameCZ + forward.getZ() * 500.0f;
}

// ── Body factory ──────────────────────────────────────────────────────
void spawnNextGameBody() {
    if (gameBodyIndex >= TOTAL_BODIES) return;

    float cx = width  * 0.5f;
    float cy = getSkyY();               // spawn at the top of the scaled arena

    Quaternion q = new Quaternion(
        new Vector3D(random(-1,1), random(-1,1), random(-1,1)).normalized(),
        random(TWO_PI));

    RigidBody body = null;
    switch (gameBodyIndex) {
        case 0:
            body = new TriangleBody(new Point3D(cx, cy, 0), q, 15.0f,
                0.0f,-45.0f,0.0f, -45.0f,35.0f,0.0f, 45.0f,35.0f,0.0f,
                4.0f,1.0f,1.0f);
            break;
        case 1:
            body = new SquareBody(new Point3D(cx, cy, 0), q, 20.0f,
                75.0f,55.0f,55.0f, new Vector3D(0.7f,0.0f,0.0f));
            break;
        case 2:
            body = new cylenderBody(new Point3D(cx, cy, 0), q, 25.0f,
                32.0f,85.0f, 1.0f,6.0f,2.0f);
            break;
        default: {
            GraphShapePattern[] pats = GraphShapePattern.values();
            GraphShapePattern pat = pats[int(random(pats.length))];
            int nodes = int(random(10, 25));
            Vector3D skew = new Vector3D(random(-1.5f,1.5f),random(-1.5f,1.5f),random(-1.5f,1.5f));
            body = new GraphBody(new Point3D(cx, cy, 0), q, 30.0f,
                nodes, pat, 45.0f, 0.15f, skew);
            ((GraphBody)body).nodeHitRadius = 10.0f;
            break;
        }
    }

    // Low linear damping so the body keeps falling; moderate angular damping
    // so hard-won spin decays slowly and the peak stays meaningful.
    body.setLinearDamping(0.02f);
    body.setAngularDamping(0.97f);

    gameBodies.clear();
    gameRegistry.clear();
    gameBodies.add(body);
    gameRegistry.add(body, gameGravity);
    gameBodyAlive    = true;
    gameTimeAccum    = 0.0f;
    gameCurPeakOmega = 0.0f;
    gameLastHit      = null;
    gameRayStart     = null;
    gameRayEnd       = null;

    // Reset trails and track the furthest local vertex
    comTrail.clear();
    vertexTrail.clear();
    curFurthestLocal = getFurthestLocalVertex(body);
}

// ─────────────────────────────────────────────────────────────────────
void drawGame() {
    // ── Physics tick ────────────────────────────────────────────────
    long now = System.nanoTime();
    float frameTime = min((now - gameLastTimeNs) / 1.0e9f, PhysicsConstants.MAX_FRAME_TIME);
    gameLastTimeNs = now;

    if (gameBodyAlive && !gameBodies.isEmpty()) {
        gameTimeAccum += frameTime;

        while (gameTimeAccum >= PhysicsConstants.FIXED_TIMESTEP) {
            integrateStep(gameBodies, gameRegistry,
                          PhysicsConstants.FIXED_TIMESTEP, IntegrationMode.VelocityVerlet);
            gameTimeAccum -= PhysicsConstants.FIXED_TIMESTEP;
        }

        RigidBody active = gameBodies.get(0);

        // Track peak angular speed for this body
        float omega = active.getAngularVelocity().length();
        if (omega > gameCurPeakOmega) gameCurPeakOmega = omega;

        // Record 3D path of Center of Mass and Furthest Vertex
        Point3D comWorld = active.getPosition();
        Point3D vtxWorld = (curFurthestLocal != null)
            ? active.getRotationMatrix().transform(curFurthestLocal) : comWorld;

        if (comTrail.isEmpty() || comWorld.distanceSquaredTo(comTrail.get(comTrail.size() - 1)) > 4.0f) {
            comTrail.add(new Point3D(comWorld.getX(), comWorld.getY(), comWorld.getZ()));
        }
        if (vertexTrail.isEmpty() || vtxWorld.distanceSquaredTo(vertexTrail.get(vertexTrail.size() - 1)) > 4.0f) {
            vertexTrail.add(new Point3D(vtxWorld.getX(), vtxWorld.getY(), vtxWorld.getZ()));
        }

        // Ground detection → record peak, advance to next body
        if (active.getPosition().getY() > getGroundY()) {
            gamePeakOmega[gameBodyIndex] = gameCurPeakOmega;
            gameBodyAlive = false;
            gameBodyIndex++;

            if (gameBodyIndex >= TOTAL_BODIES) {
                // Compute final score
                gameFinalScore = 0;
                for (float v : gamePeakOmega) gameFinalScore += v;
                gameBodies.clear();
                gameRegistry.clear();
                goToEndScreen();
                return;
            }
            spawnNextGameBody();
        }
    }

    // ── Update Camera & Player Movement ─────────────────────────────
    float moveSpeed = 480.0f * frameTime;
    Vector3D moveFwd   = new Vector3D(sin(gameYaw), 0, -cos(gameYaw)).normalized();
    Vector3D moveRight = new Vector3D(cos(gameYaw), 0,  sin(gameYaw)).normalized();

    if (keyW) { gameCX += moveFwd.getX()   * moveSpeed; gameCZ += moveFwd.getZ()   * moveSpeed; }
    if (keyS) { gameCX -= moveFwd.getX()   * moveSpeed; gameCZ -= moveFwd.getZ()   * moveSpeed; }
    if (keyA) { gameCX -= moveRight.getX() * moveSpeed; gameCZ -= moveRight.getZ() * moveSpeed; }
    if (keyD) { gameCX += moveRight.getX() * moveSpeed; gameCZ += moveRight.getZ() * moveSpeed; }

    float cosP = cos(gamePitch);
    Vector3D forward = new Vector3D(
        sin(gameYaw) * cosP,
        sin(gamePitch),
        -cos(gameYaw) * cosP
    ).normalized();

    gameTgtX = gameCX + forward.getX() * 500.0f;
    gameTgtY = gameCY + forward.getY() * 500.0f;
    gameTgtZ = gameCZ + forward.getZ() * 500.0f;

    // ── Render ──────────────────────────────────────────────────────
    background(10, 15, 25);
    lights();
    camera(gameCX, gameCY, gameCZ, gameTgtX, gameTgtY, gameTgtZ, 0, 1, 0);

    drawGameArena();

    for (RigidBody b : gameBodies) b.draw();

    // 1. Center of Mass trail (Cyan)
    if (comTrail.size() > 1) {
        noFill();
        stroke(0, 230, 255, 230);
        strokeWeight(2.5f);
        beginShape();
        for (Point3D p : comTrail) {
            vertex(p.getX(), p.getY(), p.getZ());
        }
        endShape();
    }

    // 2. Furthest Vertex trail (Magenta / Pink)
    if (vertexTrail.size() > 1) {
        noFill();
        stroke(255, 60, 180, 230);
        strokeWeight(2.0f);
        beginShape();
        for (Point3D p : vertexTrail) {
            vertex(p.getX(), p.getY(), p.getZ());
        }
        endShape();
    }

    // 3. Highlight current tracked furthest vertex on the active body
    if (curFurthestLocal != null && !gameBodies.isEmpty()) {
        Point3D curVtx = gameBodies.get(0).getRotationMatrix().transform(curFurthestLocal);
        pushMatrix();
        translate(curVtx.getX(), curVtx.getY(), curVtx.getZ());
        noStroke();
        fill(255, 60, 180);
        sphere(4.0f);
        popMatrix();
    }

    // 4. Trace projectile ray
    if (gameRayStart != null && gameRayEnd != null) {
        stroke(255, 230, 80, 200);
        strokeWeight(2.5f);
        line(gameRayStart.getX(), gameRayStart.getY(), gameRayStart.getZ(),
             gameRayEnd.getX(),   gameRayEnd.getY(),   gameRayEnd.getZ());
    }

    // 5. Mark ONLY the last impact point
    if (gameLastHit != null) {
        pushMatrix();
        translate(gameLastHit.getX(), gameLastHit.getY(), gameLastHit.getZ());
        noStroke();
        fill(50, 255, 100, 230);
        sphereDetail(16);
        sphere(6.5f);

        noFill();
        stroke(255, 230, 80, 240);
        strokeWeight(2.0f);
        ellipse(0, 0, 18.0f, 18.0f);
        popMatrix();
    }

    drawGameHUD();
}

// Proper 3D arena: 3D floor platform on the XZ plane with grid depth cues
void drawGameArena() {
    float cx    = width  * 0.5f;
    float gndY  = getGroundY();          // ground Y in world
    float skyY  = getSkyY();             // spawn line Y
    float hw    = getArenaHalfWidth();   // half-width along X
    float halfD = hw * 0.75f;            // half-depth along Z

    // 3D floor platform (semi-transparent)
    noStroke();
    fill(20, 45, 30, 170);
    beginShape();
    vertex(cx - hw, gndY, -halfD);
    vertex(cx + hw, gndY, -halfD);
    vertex(cx + hw, gndY,  halfD);
    vertex(cx - hw, gndY,  halfD);
    endShape(CLOSE);

    // 3D grid lines on the ground for depth perception
    stroke(45, 95, 60, 140);
    strokeWeight(1);
    for (float x = cx - hw; x <= cx + hw + 1; x += hw * 0.25f) {
        line(x, gndY, -halfD, x, gndY, halfD);
    }
    for (float z = -halfD; z <= halfD + 1; z += halfD * 0.33f) {
        line(cx - hw, gndY, z, cx + hw, gndY, z);
    }

    // Glowing ground perimeter border
    stroke(80, 215, 90, 230);
    strokeWeight(2.5f);
    noFill();
    beginShape();
    vertex(cx - hw, gndY, -halfD);
    vertex(cx + hw, gndY, -halfD);
    vertex(cx + hw, gndY,  halfD);
    vertex(cx - hw, gndY,  halfD);
    endShape(CLOSE);

    // 4 vertical corner guide pillars
    stroke(50, 120, 70, 90);
    strokeWeight(1);
    line(cx - hw, skyY, -halfD,  cx - hw, gndY, -halfD);
    line(cx + hw, skyY, -halfD,  cx + hw, gndY, -halfD);
    line(cx + hw, skyY,  halfD,  cx + hw, gndY,  halfD);
    line(cx - hw, skyY,  halfD,  cx - hw, gndY,  halfD);

    // Spawn ceiling dashed border
    stroke(80, 140, 220, 110);
    strokeWeight(1);
    for (float x = cx - hw; x < cx + hw; x += 30) {
        line(x, skyY, 0, min(x + 15, cx + hw), skyY, 0);
    }
}

// ── HUD ───────────────────────────────────────────────────────────────
void drawGameHUD() {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();

    // ── Top bar ──────────────────────────────────────────────────
    noStroke();
    fill(0, 0, 0, 170);
    rect(0, 0, width, 88);

    // Body label & index
    fill(255);
    textSize(14);
    textAlign(LEFT, TOP);
    text("Body " + (gameBodyIndex + 1) + " / " + TOTAL_BODIES
       + "  —  " + (gameBodyIndex < TOTAL_BODIES ? bodyLabels[gameBodyIndex] : "Done"),
       15, 10);

    // Current peak omega (live)
    textAlign(CENTER, TOP);
    textSize(20);
    fill(255, 220, 80);
    float liveOmega = gameBodyAlive && !gameBodies.isEmpty()
        ? gameBodies.get(0).getAngularVelocity().length() : 0;
    text("ω " + nf(liveOmega, 1, 1) + "  |  peak " + nf(gameCurPeakOmega, 1, 1),
         width * 0.5f, 8);

    // Hit feedback
    textSize(13);
    fill(160);
    text(gameHitInfo, width * 0.5f, 36);

    // Controls hint & trail legend
    textSize(12);
    fill(130);
    textAlign(LEFT, TOP);
    text("[WASD] Move   [Right Click Drag] Look   [Left Click] Shoot   [C] Reset View   [ESC] Menu", 15, 52);
    text("[Cyan] Path: Center of Mass   [Magenta] Path: Furthest Vertex", 15, 68);

    // ── Score sidebar (right) ─────────────────────────────────────
    float sbX = width - 175;
    float sbY = 98;
    float sbW = 160;
    float sbH = TOTAL_BODIES * 36 + 36;
    noStroke();
    fill(0, 0, 0, 150);
    rect(sbX - 8, sbY - 8, sbW + 16, sbH + 16, 6);

    textAlign(LEFT, TOP);
    textSize(12);
    fill(180);
    text("PEAK SPIN  (ω/body)", sbX, sbY);

    float runningSum = 0;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        float v = (i < gameBodyIndex) ? gamePeakOmega[i]
                : (i == gameBodyIndex) ? gameCurPeakOmega : 0;
        runningSum += (i < gameBodyIndex) ? gamePeakOmega[i] : 0;

        textSize(13);
        if (i < gameBodyIndex) {
            fill(120, 220, 120);     // done
        } else if (i == gameBodyIndex) {
            fill(255, 220, 60);      // current
        } else {
            fill(80, 80, 100);       // upcoming
        }
        textAlign(LEFT, TOP);
        text(bodyLabels[i], sbX, sbY + 24 + i * 34);
        textAlign(RIGHT, TOP);
        text(nf(v, 1, 1), sbX + sbW, sbY + 24 + i * 34);
    }

    // Running total
    float totalSoFar = 0;
    for (int i = 0; i < gameBodyIndex; i++) totalSoFar += gamePeakOmega[i];
    totalSoFar += gameCurPeakOmega;
    noStroke();
    fill(60, 60, 60, 180);
    rect(sbX - 8, sbY + 24 + TOTAL_BODIES*34, sbW + 16, 28, 4);
    fill(255, 200, 50);
    textSize(14);
    textAlign(LEFT, TOP);
    text("TOTAL", sbX, sbY + 28 + TOTAL_BODIES*34);
    textAlign(RIGHT, TOP);
    text(nf(totalSoFar, 1, 1), sbX + sbW, sbY + 28 + TOTAL_BODIES*34);

    // ── Progress pips (bottom centre) ────────────────────────────
    int pipR = 8, pipSpacing = 28;
    int pipX = width/2 - (TOTAL_BODIES * pipSpacing)/2 + pipR;
    int pipY = height - 20;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        noStroke();
        if (i < gameBodyIndex)       fill(80, 160, 80);
        else if (i == gameBodyIndex) fill(255, 200, 50);
        else                         fill(50, 70, 120);
        ellipse(pipX + i * pipSpacing, pipY, pipR*2, pipR*2);
    }

    btnGameBack.setBounds(width - 155, 12, 145, 34);
    btnGameBack.draw();
    hint(ENABLE_DEPTH_TEST);
}

// ── Input ─────────────────────────────────────────────────────────────
void handleGameClick() {
    if (btnGameBack.isOver()) { goToMainMenu(); return; }
    if (mouseButton == LEFT && gameBodyAlive && !gameBodies.isEmpty()) {
        gameShootRay(mouseX, mouseY);
    }
}

void handleGameKey() {
    if (key == 'w' || key == 'W') keyW = true;
    if (key == 'a' || key == 'A') keyA = true;
    if (key == 's' || key == 'S') keyS = true;
    if (key == 'd' || key == 'D') keyD = true;
    if (key == 'c' || key == 'C') setupGameCamera();
}

void handleGameKeyReleased() {
    if (key == 'w' || key == 'W') keyW = false;
    if (key == 'a' || key == 'A') keyA = false;
    if (key == 's' || key == 'S') keyS = false;
    if (key == 'd' || key == 'D') keyD = false;
}

void handleGameMouseDragged() {
    if (mouseButton == RIGHT) {
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        float sensitivity = 0.005f;
        gameYaw   += dx * sensitivity;
        gamePitch += dy * sensitivity;
        gamePitch = constrain(gamePitch, -1.35f, 1.35f);
    }
}

// Shoot a ray from the 3D camera and apply an impulse at the hit point.
// Hitting off-centre generates torque → spin.
void gameShootRay(float mx, float my) {
    Point3D rayOrigin = new Point3D(gameCX, gameCY, gameCZ);

    // Camera coordinate frame basis vectors
    Vector3D forward = new Vector3D(gameTgtX - gameCX, gameTgtY - gameCY, gameTgtZ - gameCZ).normalized();
    Vector3D worldUp = new Vector3D(0, 1, 0);
    Vector3D right   = forward.cross(worldUp).normalized();
    Vector3D camUp   = right.cross(forward).normalized();

    float fov    = PI / 3.0f;
    float aspect = (float)width / (float)height;
    float ndcX   = (2.0f * mx / width)  - 1.0f;
    float ndcY   = (2.0f * my / height) - 1.0f;

    float halfH  = tan(fov * 0.5f);
    float halfW  = halfH * aspect;

    Vector3D dir = forward.add(right.mult(ndcX * halfW)).add(camUp.mult(ndcY * halfH)).normalized();
    Point3D  rayEnd = rayOrigin.add(dir.mult(gameCamDist * 3.0f));

    gameRayStart = rayOrigin;
    gameRayEnd   = rayEnd;

    // Find closest hit
    Point3D   closestHit = null;
    RigidBody hitBody    = null;
    float     bestDistSq = Float.MAX_VALUE;

    for (RigidBody body : gameBodies) {
        Point3D hit = body.interceptLine(rayOrigin, rayEnd);
        if (hit != null) {
            float dSq = rayOrigin.distanceSquaredTo(hit);
            if (dSq < bestDistSq) {
                bestDistSq = dSq;
                closestHit = hit;
                hitBody    = body;
            }
        }
    }

    if (closestHit != null) {
        gameLastHit = closestHit;
        // Apply impulse at hit point → off-centre = torque → spin!
        hitBody.applyImpulseAtPoint(dir.mult(hitBody.getMass() * GAME_KICK), closestHit);
        gameHitInfo = "HIT " + hitBody.getClass().getSimpleName()
            + "  ω → " + nf(hitBody.getAngularVelocity().length(), 1, 1);
    } else {
        gameHitInfo = "MISS — aim at the edge for maximum spin";
    }
}

// ==========================================
//  END SCREEN
// ==========================================
void drawEndScreen() {
    background(18, 12, 28);
    camera();
    noLights();

    // Title
    textAlign(CENTER, CENTER);
    textSize(48);
    fill(255, 80, 180);
    text("Round Complete!", width * 0.5f, height * 0.16f);

    // Per-body breakdown
    float colX = width * 0.5f - 110;
    float tableStartY = height * 0.28f;
    textSize(15);
    fill(200);
    textAlign(LEFT, CENTER);
    text("Body", colX, tableStartY);
    textAlign(RIGHT, CENTER);
    text("Peak ω", colX + 220, tableStartY);

    stroke(80);
    strokeWeight(1);
    line(colX - 10, tableStartY + 15, colX + 235, tableStartY + 15);
    noStroke();

    for (int i = 0; i < TOTAL_BODIES; i++) {
        float rowY = tableStartY + 35 + i * 32;
        textSize(14);
        fill(160, 220, 160);
        textAlign(LEFT, CENTER);
        text(bodyLabels[i], colX, rowY);
        textAlign(RIGHT, CENTER);
        text(nf(gamePeakOmega[i], 1, 2), colX + 220, rowY);
    }

    // Divider
    float dividerY = tableStartY + 35 + TOTAL_BODIES * 32 + 5;
    stroke(80);
    line(colX - 10, dividerY, colX + 235, dividerY);
    noStroke();

    // Total score
    float scoreY = dividerY + 30;
    textSize(26);
    fill(255, 220, 80);
    textAlign(LEFT, CENTER);
    text("Total Score", colX, scoreY);
    textAlign(RIGHT, CENTER);
    text(nf(gameFinalScore, 1, 2), colX + 220, scoreY);

    textSize(13);
    fill(110);
    textAlign(CENTER, CENTER);
    text("(sum of peak angular velocities)", width * 0.5f, scoreY + 28);

    // Dynamically center buttons
    float bW = 240, bH = 46;
    float bX = width * 0.5f - bW * 0.5f;
    float btnStartY = scoreY + 58;
    btnEndReplay.setBounds(bX, btnStartY, bW, bH);
    btnEndMainMenu.setBounds(bX, btnStartY + 56, bW, bH);
    btnEndReplay.draw();
    btnEndMainMenu.draw();

    textSize(12);
    fill(60);
    textAlign(CENTER, BOTTOM);
    text("[ESC] returns to Main Menu", width * 0.5f, height - 12);
}

void handleEndScreenClick() {
    if (btnEndReplay.isOver())   startGame();
    else if (btnEndMainMenu.isOver()) goToMainMenu();
}
