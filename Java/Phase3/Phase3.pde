// ==========================================
// Phase 3 : fichier principal du sketch
// ------------------------------------------
// Scene de test visuelle pour RigidBody et interceptLine()
// Game loop with Main Menu, Model Viewer, Game and End Screen
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
class Button {
    String label;
    float  x, y, w, h;
    color  base, hover, textCol;
    float  fontSize = 22;

    Button(String label, float x, float y, float w, float h,
           color base, color hover, color textCol) {
        this.label   = label;
        this.x       = x;  this.y = y;
        this.w       = w;  this.h = h;
        this.base    = base;
        this.hover   = hover;
        this.textCol = textCol;
    }

    Button(String label, float x, float y, float w, float h,
           color base, color hover, color textCol, float fontSize) {
        this(label, x, y, w, h, base, hover, textCol);
        this.fontSize = fontSize;
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
        rect(x, y, w, h, 10);
        fill(textCol);
        textAlign(CENTER, CENTER);
        textSize(fontSize);
        text(label, x + w * 0.5f, y + h * 0.5f);
    }
}

// ── Menu buttons (created in setup) ──────────────────────────────────
Button btnModelViewer, btnGame, btnQuit;        // Main menu
Button btnEndReplay, btnEndMainMenu;            // End screen
Button btnViewerBack;                           // Model Viewer HUD
Button btnGameBack;                             // Game HUD

// ==========================================
//  SETUP
// ==========================================
void setup() {
    fullScreen(P3D);
    size(1024, 768, P3D);

    // Camera defaults
    camX    = width  * 0.5f;
    camY    = height * 0.5f;
    camZ    = (height * 0.5f) / tan(PI / 6.0f);
    targetX = width  * 0.5f;
    targetY = height * 0.5f;
    targetZ = 0.0f;

    // Build buttons (scaled up) ------------------------------------
    float bW = 320, bH = 62;
    float bX = width * 0.5f - bW * 0.5f;
    color bBase  = color(50, 100, 180);
    color bHover = color(80, 140, 230);
    color bText  = color(255);

    // Main menu
    btnModelViewer = new Button("Model Viewer", bX, 260, bW, bH, bBase,            bHover,            bText, 22);
    btnGame        = new Button("Game",         bX, 340, bW, bH, color(40,120,60), color(60,170,80),  bText, 22);
    btnQuit        = new Button("Quit",         bX, 420, bW, bH, color(160,40,40), color(210,60,60),  bText, 22);

    // End screen
    btnEndReplay   = new Button("Replay",            bX, 320, bW, bH, bBase,          bHover,          bText, 22);
    btnEndMainMenu = new Button("Back to Main Menu", bX, 400, bW, bH, color(80,80,80),color(110,110,110),bText, 22);

    // In-scene back buttons (top-right corner)
    btnViewerBack  = new Button("< Main Menu", width - 190, 12, 175, 44, color(60,60,60), color(100,100,100), bText, 18);
    btnGameBack    = new Button("< Main Menu", width - 190, 12, 175, 44, color(60,60,60), color(100,100,100), bText, 18);

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
        case MAIN_MENU:    drawMainMenu();    break;
        case MODEL_VIEWER: drawModelViewer(); break;
        case GAME:         drawGame();        break;
        case END_SCREEN:   drawEndScreen();   break;
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
    keyW = false; keyA = false; keyS = false; keyD = false; keySpace = false; keyShift = false;
    currentScene = Scene.MAIN_MENU;
}

void startModelViewer() {
    initModelViewer();
    lastTimeNs  = System.nanoTime();
    currentScene = Scene.MODEL_VIEWER;
}

void startGame() {
    initGame();
    currentScene = Scene.GAME;
}

void goToEndScreen() {
    keyW = false; keyA = false; keyS = false; keyD = false; keySpace = false; keyShift = false;
    currentScene = Scene.END_SCREEN;
}

// ==========================================
//  MAIN MENU
// ==========================================
void drawMainMenu() {
    background(20, 20, 35);
    camera();
    noLights();

    // Dynamically center scaled buttons
    float bW = 320, bH = 62;
    float bX = width * 0.5f - bW * 0.5f;
    float startY = height * 0.42f;
    btnModelViewer.setBounds(bX, startY, bW, bH);
    btnGame.setBounds(bX, startY + 82, bW, bH);
    btnQuit.setBounds(bX, startY + 164, bW, bH);

    // Title
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(56);
    text("Phase 3", width * 0.5f, height * 0.18f);
    textSize(24);
    fill(170);
    text("RigidBody Physics Engine", width * 0.5f, height * 0.18f + 62);

    // Separator
    stroke(80);
    strokeWeight(1.5f);
    line(width * 0.22f, height * 0.18f + 105, width * 0.78f, height * 0.18f + 105);
    noStroke();

    // Buttons
    btnModelViewer.draw();
    btnGame.draw();
    btnQuit.draw();

    // Footer
    textSize(16);
    fill(100);
    textAlign(CENTER, BOTTOM);
    text("8INF935 — Simulation physique", width * 0.5f, height - 18);
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

    // Proportional spacing & uniform scale relative to 1024x768 baseline
    float offX = width  * 0.23f;
    float offY = height * 0.16f;
    float s    = min(width / 1024.0f, height / 768.0f);

    // 1. TriangleBody (top-left)
    TriangleBody triangle = new TriangleBody(
        new Point3D(cx - offX, cy - offY, 0),
        new Quaternion(new Vector3D(0, 1, 0), 0.3f),
        15.0f,
        0.0f, -45.0f * s, 0.0f,
        -45.0f * s, 35.0f * s, 0.0f,
        45.0f * s, 35.0f * s, 0.0f,
        4.0f, 1.0f, 1.0f
    );
    bodies.add(triangle);

    // 2. SquareBody (top-right)
    SquareBody boxBody = new SquareBody(
        new Point3D(cx + offX, cy - offY, 0),
        new Quaternion(new Vector3D(1, 1, 0), 0.5f),
        20.0f,
        75.0f * s, 55.0f * s, 55.0f * s,
        new Vector3D(0.7f, 0.0f, 0.0f)
    );
    bodies.add(boxBody);

    // 3. cylenderBody (bottom-left)
    cylenderBody cylinder = new cylenderBody(
        new Point3D(cx - offX, cy + offY, 0),
        new Quaternion(new Vector3D(1, 0, 0.3f), 0.4f),
        25.0f,
        32.0f * s, 85.0f * s,
        1.0f, 6.0f, 2.0f
    );
    bodies.add(cylinder);

    // 4. GraphBody (bottom-right)
    GraphShapePattern[] patterns = GraphShapePattern.values();
    graphBody = new GraphBody(
        new Point3D(cx + offX, cy + offY, 0),
        new Quaternion(new Vector3D(0, 1, 0), 0.2f),
        30.0f,
        24,
        patterns[currentPatternIndex],
        45.0f * s,
        0.12f,
        new Vector3D(0.0f, 1.2f, 0.0f)
    );
    graphBody.nodeHitRadius = 8.0f * s;
    bodies.add(graphBody);

    for (RigidBody body : bodies) {
        body.setLinearDamping(0.1f);
        body.setAngularDamping(0.9f);
    }
}

void drawModelViewer() {
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

    float uiScale = max(1.0f, height / 768.0f);
    float s       = min(width / 1024.0f, height / 768.0f);
    float offX    = width  * 0.23f;
    float offY    = height * 0.16f;
    float pad     = 20.0f * uiScale;

    fill(240);
    textSize(16 * uiScale);
    textAlign(LEFT, TOP);
    text("Controls: [Left Click] Shoot Ray   [SPACE] Pause/Rotate   [G] Cycle Graph   [R] Clear   [ESC] Menu",
         pad, pad);
    text("Status: " + lastHitInfo + "   |   Total Hits: " + hitDots.size(),
         pad, pad + 26 * uiScale);
    text("[I] Integrator: " + currentIntegrationMode.name() + "   |   A hit gives an impulse at the hit point",
         pad, pad + 52 * uiScale);

    // Shape labels anchored directly above/below each scaled body
    textAlign(CENTER, TOP);
    textSize(16 * uiScale);
    fill(200);
    text("TriangleBody (Uneven)",
         width * 0.5f - offX, height * 0.5f - offY - 95 * s);
    text("SquareBody (Biased)",
         width * 0.5f + offX, height * 0.5f - offY - 95 * s);
    text("cylenderBody (Bottom-Heavy)",
         width * 0.5f - offX, height * 0.5f + offY + 95 * s);
    text("GraphBody (" + graphBody.shapePattern + ", n=" + graphBody.nodeCount + ")",
         width * 0.5f + offX, height * 0.5f + offY + 95 * s);

    // Weight gradient legend (bottom-left)
    float legendY = height - 30 * uiScale;
    textAlign(LEFT, CENTER);
    textSize(16 * uiScale);
    fill(220);
    text("%TotalWeight:", pad, legendY);

    int barX = int(pad + 125 * uiScale);
    int barY = int(legendY - 8 * uiScale);
    int barW = int(180 * uiScale);
    int barH = int(16 * uiScale);
    for (int i = 0; i < barW; i++) {
        float t = (float)i / barW;
        int c = (t < 0.5f)
            ? lerpColor(color(45, 135, 255), color(60, 225, 130), t * 2.0f)
            : lerpColor(color(60, 225, 130), color(255, 65, 50), (t - 0.5f) * 2.0f);
        stroke(c);
        line(barX + i, barY, barX + i, barY + barH);
    }
    noStroke();
    fill(190);
    text("Low          Avg          High    |    Yellow/Magenta Crosshair = Center of Mass",
         barX + barW + 14 * uiScale, legendY);

    // Scaled Back button (top-right)
    float btnW = 180 * uiScale;
    float btnH = 46 * uiScale;
    btnViewerBack.fontSize = 18 * uiScale;
    btnViewerBack.setBounds(width - btnW - pad, pad, btnW, btnH);
    btnViewerBack.draw();

    hint(ENABLE_DEPTH_TEST);
}

// ── Ray shooter ──────────────────────────────────────────────────────
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
final int   TOTAL_BODIES = 5;        // triangle, box, cylinder, graph A, graph B
final float GAME_KICK    = 100.0f;   // impulse magnitude on hit
final float GAME_GRAVITY = 180.0f;   // px/s² downward

// Dynamic arena sizing functions that scale with window size (adjusted for larger HUD)
float getGroundY() {
    return height - 70.0f;
}

float getSkyY() {
    return 145.0f;
}

float getCeilingY() {
    return 95.0f;
}

float getArenaHalfWidth() {
    return min(width * 0.36f, width * 0.5f - 250.0f);
}

float getArenaHalfDepth() {
    return getArenaHalfWidth();
}

// ── Game state ────────────────────────────────────────────────────────
ArrayList<RigidBody> gameBodies;
ForceRegistry        gameRegistry;
GravityGenerator     gameGravity;

int     gameBodyIndex  = 0;
boolean gameBodyAlive  = false;
float   gameTimeAccum  = 0.0f;
long    gameLastTimeNs = 0;

// Time and spin tracking
float   gameTotalTime    = 0.0f;
float   gameCurBodyTime  = 0.0f;
float[] gameBodyTime     = new float[TOTAL_BODIES];
float[] gamePeakOmega    = new float[TOTAL_BODIES];
float   gameCurPeakOmega = 0.0f;
float   gameSpinScore    = 0.0f;
float   gameTimeScore    = 0.0f;
float   gameFinalScore   = 0.0f;

// Impact point pinned to body local coordinates + trail
Point3D            gameLastHitLocal = null;
ArrayList<Point3D> impactTrail      = new ArrayList<Point3D>();
String             gameHitInfo      = "Shoot the edge of the object to make it spin!";

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

// WASD + 3D movement keys
boolean keyW     = false;
boolean keyA     = false;
boolean keyS     = false;
boolean keyD     = false;
boolean keySpace = false;
boolean keyShift = false;

// Body labels for HUD
String[] bodyLabels = { "Triangle", "Box", "Cylinder", "Graph A", "Graph B" };

// Convert a world-space point on the body into its local-space coordinates
// Uses the body's model-to-world matrix basis vectors (inverse rotation = transpose)
Point3D worldToLocal(RigidBody body, Point3D worldPt) {
    Matrix4 m = body.getRotationMatrix();
    Point3D originWorld = m.transform(new Point3D(0, 0, 0));
    Point3D xAxisWorld  = m.transform(new Point3D(1, 0, 0));
    Point3D yAxisWorld  = m.transform(new Point3D(0, 1, 0));
    Point3D zAxisWorld  = m.transform(new Point3D(0, 0, 1));

    Vector3D rel = worldPt.sub(originWorld);
    Vector3D ax  = xAxisWorld.sub(originWorld);
    Vector3D ay  = yAxisWorld.sub(originWorld);
    Vector3D az  = zAxisWorld.sub(originWorld);

    return new Point3D(rel.dot(ax), rel.dot(ay), rel.dot(az));
}

// Convert a local-space point on the body back into world-space coordinates
Point3D localToWorld(RigidBody body, Point3D localPt) {
    return body.getRotationMatrix().transform(localPt);
}

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
    gameTotalTime    = 0.0f;
    gameCurBodyTime  = 0.0f;
    gameFinalScore   = 0.0f;
    gameSpinScore    = 0.0f;
    gameTimeScore    = 0.0f;
    gameCurPeakOmega = 0.0f;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        gamePeakOmega[i] = 0.0f;
        gameBodyTime[i]  = 0.0f;
    }

    keyW = false; keyA = false; keyS = false; keyD = false; keySpace = false; keyShift = false;

    gameLastHitLocal = null;
    impactTrail.clear();
    comTrail.clear();
    vertexTrail.clear();
    curFurthestLocal = null;
    gameHitInfo      = "Shoot the edge of the object to make it spin!";

    setupGameCamera();
    gameLastTimeNs = System.nanoTime();
    spawnNextGameBody();
}

void computeFinalScore() {
    float totalSpin = 0.0f;
    float totalTime = 0.0f;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        totalSpin += gamePeakOmega[i];
        totalTime += gameBodyTime[i];
    }
    gameSpinScore  = totalSpin * 20.0f;
    gameTimeScore  = totalTime * 50.0f;
    gameFinalScore = gameSpinScore + gameTimeScore;
}

void setupGameCamera() {
    float cx   = width  * 0.5f;
    float hd   = getArenaHalfDepth();
    float gndY = getGroundY();

    gameCamDist = hd * 1.5f;

    gameYaw   = 0.0f;
    gamePitch = -0.12f;

    float pad = 40.0f;
    gameCX = cx;
    gameCY = gndY - 120.0f;
    gameCZ = hd - pad - 20.0f;

    float cosP = cos(gamePitch);
    Vector3D forward = new Vector3D(
        sin(gameYaw) * cosP,
        sin(gamePitch),
        -cos(gameYaw) * cosP
    ).normalized();

    gameTgtX = gameCX + forward.getX() * 500.0f;
    gameTgtY = gameCY + forward.getY() * 500.0f;
    gameTgtZ = gameCZ + forward.getZ() * 500.0f;
}

// ── Body factory ──────────────────────────────────────────────────────
void spawnNextGameBody() {
    if (gameBodyIndex >= TOTAL_BODIES) return;

    gameCurPeakOmega = 0.0f;
    gameCurBodyTime  = 0.0f;
    comTrail.clear();
    vertexTrail.clear();
    impactTrail.clear();

    float cx = width  * 0.5f;
    float cy = getSkyY();

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

    body.setLinearDamping(0.02f);
    body.setAngularDamping(0.97f);

    gameBodies.clear();
    gameRegistry.clear();
    gameBodies.add(body);
    gameRegistry.add(body, gameGravity);
    gameBodyAlive    = true;
    gameTimeAccum    = 0.0f;
    gameCurPeakOmega = 0.0f;
    gameLastHitLocal = null;

    comTrail.clear();
    vertexTrail.clear();
    impactTrail.clear();
    curFurthestLocal = getFurthestLocalVertex(body);
}

// ─────────────────────────────────────────────────────────────────────
void drawGame() {
    long now = System.nanoTime();
    float frameTime = min((now - gameLastTimeNs) / 1.0e9f, PhysicsConstants.MAX_FRAME_TIME);
    gameLastTimeNs = now;

    if (gameBodyAlive && !gameBodies.isEmpty()) {
        gameTimeAccum   += frameTime;
        gameTotalTime   += frameTime;
        gameCurBodyTime += frameTime;

        while (gameTimeAccum >= PhysicsConstants.FIXED_TIMESTEP) {
            integrateStep(gameBodies, gameRegistry,
                          PhysicsConstants.FIXED_TIMESTEP, IntegrationMode.VelocityVerlet);
            gameTimeAccum -= PhysicsConstants.FIXED_TIMESTEP;
        }

        RigidBody active = gameBodies.get(0);

        float omega = active.getAngularVelocity().length();
        if (omega > gameCurPeakOmega) gameCurPeakOmega = omega;

        // 1. Record 3D path of Center of Mass (Cyan)
        Point3D comWorld = active.getPosition();
        if (comTrail.isEmpty() || comWorld.distanceSquaredTo(comTrail.get(comTrail.size() - 1)) > 4.0f) {
            comTrail.add(new Point3D(comWorld.getX(), comWorld.getY(), comWorld.getZ()));
        }

        // 2. Record 3D path of Furthest Vertex (Pink / Magenta)
        Point3D vtxWorld = (curFurthestLocal != null)
            ? localToWorld(active, curFurthestLocal) : comWorld;
        if (vertexTrail.isEmpty() || vtxWorld.distanceSquaredTo(vertexTrail.get(vertexTrail.size() - 1)) > 4.0f) {
            vertexTrail.add(new Point3D(vtxWorld.getX(), vtxWorld.getY(), vtxWorld.getZ()));
        }

        // 3. Record 3D path of the pinned Impact Point (Green)
        if (gameLastHitLocal != null) {
            Point3D impactWorld = localToWorld(active, gameLastHitLocal);
            if (impactTrail.isEmpty() || impactWorld.distanceSquaredTo(impactTrail.get(impactTrail.size() - 1)) > 4.0f) {
                impactTrail.add(new Point3D(impactWorld.getX(), impactWorld.getY(), impactWorld.getZ()));
            }
        }

        // Detection: any face of the arena destroys the body
        Point3D pos = active.getPosition();
        float cx    = width * 0.5f;
        float hw    = getArenaHalfWidth();
        float hd    = getArenaHalfDepth();
        float gndY  = getGroundY();
        float ceilY = getCeilingY();

        boolean destroyed = false;
        String faceHit = "";

        if (pos.getY() >= gndY) {
            destroyed = true;
            faceHit = "Floor Impact!";
        } else if (pos.getY() <= ceilY) {
            destroyed = true;
            faceHit = "Ceiling Impact!";
        } else if (pos.getX() <= cx - hw) {
            destroyed = true;
            faceHit = "Left Wall Impact!";
        } else if (pos.getX() >= cx + hw) {
            destroyed = true;
            faceHit = "Right Wall Impact!";
        } else if (pos.getZ() <= -hd) {
            destroyed = true;
            faceHit = "Back Wall Impact!";
        } else if (pos.getZ() >= hd) {
            destroyed = true;
            faceHit = "Front Wall Impact!";
        }

        if (destroyed) {
            gamePeakOmega[gameBodyIndex] = gameCurPeakOmega;
            gameBodyTime[gameBodyIndex]  = gameCurBodyTime;
            gameHitInfo = active.getClass().getSimpleName() + " destroyed: " + faceHit;
            gameBodyAlive = false;
            gameBodyIndex++;

            if (gameBodyIndex >= TOTAL_BODIES) {
                computeFinalScore();
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

    float cosP = cos(gamePitch);
    Vector3D forward = new Vector3D(
        sin(gameYaw) * cosP,
        sin(gamePitch),
        -cos(gameYaw) * cosP
    ).normalized();
    Vector3D moveRight = new Vector3D(cos(gameYaw), 0,  sin(gameYaw)).normalized();

    if (keyW) {
        gameCX += forward.getX() * moveSpeed;
        gameCY += forward.getY() * moveSpeed;
        gameCZ += forward.getZ() * moveSpeed;
    }
    if (keyS) {
        gameCX -= forward.getX() * moveSpeed;
        gameCY -= forward.getY() * moveSpeed;
        gameCZ -= forward.getZ() * moveSpeed;
    }
    if (keyA) {
        gameCX -= moveRight.getX() * moveSpeed;
        gameCZ -= moveRight.getZ() * moveSpeed;
    }
    if (keyD) {
        gameCX += moveRight.getX() * moveSpeed;
        gameCZ += moveRight.getZ() * moveSpeed;
    }
    if (keySpace) gameCY -= moveSpeed;
    if (keyShift) gameCY += moveSpeed;

    float pad   = 30.0f;
    float cx    = width * 0.5f;
    float hw    = getArenaHalfWidth();
    float hd    = getArenaHalfDepth();
    float gndY  = getGroundY();
    float ceilY = getCeilingY();

    gameCX = constrain(gameCX, cx - hw + pad, cx + hw - pad);
    gameCY = constrain(gameCY, ceilY + pad,   gndY - pad);
    gameCZ = constrain(gameCZ, -hd + pad,      hd - pad);

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

    // 3. Impact Point trail (Green)
    if (impactTrail.size() > 1) {
        noFill();
        stroke(50, 255, 100, 230);
        strokeWeight(2.5f);
        beginShape();
        for (Point3D p : impactTrail) {
            vertex(p.getX(), p.getY(), p.getZ());
        }
        endShape();
    }

    // 4. Highlight current tracked furthest vertex on the active body
    if (curFurthestLocal != null && !gameBodies.isEmpty()) {
        Point3D curVtx = localToWorld(gameBodies.get(0), curFurthestLocal);
        pushMatrix();
        translate(curVtx.getX(), curVtx.getY(), curVtx.getZ());
        noStroke();
        fill(255, 60, 180);
        sphere(4.5f);
        popMatrix();
    }

    // 5. Mark the impact point pinned directly onto the moving/rotating body
    if (gameLastHitLocal != null && !gameBodies.isEmpty()) {
        Point3D currentHitWorld = localToWorld(gameBodies.get(0), gameLastHitLocal);
        pushMatrix();
        translate(currentHitWorld.getX(), currentHitWorld.getY(), currentHitWorld.getZ());
        noStroke();
        fill(50, 255, 100, 240);
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

// Proper 3D arena
void drawGameArena() {
    float cx    = width  * 0.5f;
    float gndY  = getGroundY();
    float ceilY = getCeilingY();
    float skyY  = getSkyY();
    float hw    = getArenaHalfWidth();
    float hd    = getArenaHalfDepth();

    float minX = cx - hw, maxX = cx + hw;
    float minZ = -hd,     maxZ = hd;

    // 1. Floor Platform
    noStroke();
    fill(12, 35, 45, 170);
    beginShape();
    vertex(minX, gndY, minZ);
    vertex(maxX, gndY, minZ);
    vertex(maxX, gndY, maxZ);
    vertex(minX, gndY, maxZ);
    endShape(CLOSE);

    stroke(0, 220, 160, 130);
    strokeWeight(1);
    for (float x = minX; x <= maxX + 1; x += hw * 0.25f) {
        line(x, gndY, minZ, x, gndY, maxZ);
    }
    for (float z = minZ; z <= maxZ + 1; z += hd * 0.25f) {
        line(minX, gndY, z, maxX, gndY, z);
    }

    // 2. Ceiling Platform
    noStroke();
    fill(15, 25, 45, 120);
    beginShape();
    vertex(minX, ceilY, minZ);
    vertex(maxX, ceilY, minZ);
    vertex(maxX, ceilY, maxZ);
    vertex(minX, ceilY, maxZ);
    endShape(CLOSE);

    stroke(70, 130, 240, 100);
    strokeWeight(1);
    for (float x = minX; x <= maxX + 1; x += hw * 0.25f) {
        line(x, ceilY, minZ, x, ceilY, maxZ);
    }
    for (float z = minZ; z <= maxZ + 1; z += hd * 0.25f) {
        line(minX, ceilY, z, maxX, ceilY, z);
    }

    // 3. Back Wall
    noStroke();
    fill(10, 32, 60, 110);
    beginShape();
    vertex(minX, ceilY, minZ);
    vertex(maxX, ceilY, minZ);
    vertex(maxX, gndY,  minZ);
    vertex(minX, gndY,  minZ);
    endShape(CLOSE);

    stroke(0, 180, 255, 110);
    strokeWeight(1);
    for (float x = minX; x <= maxX + 1; x += hw * 0.25f) {
        line(x, ceilY, minZ, x, gndY, minZ);
    }
    for (float y = ceilY; y <= gndY + 1; y += (gndY - ceilY) * 0.25f) {
        line(minX, y, minZ, maxX, y, minZ);
    }

    // 4. Left Wall
    noStroke();
    fill(10, 28, 55, 100);
    beginShape();
    vertex(minX, ceilY, minZ);
    vertex(minX, ceilY, maxZ);
    vertex(minX, gndY,  maxZ);
    vertex(minX, gndY,  minZ);
    endShape(CLOSE);

    stroke(0, 180, 255, 100);
    strokeWeight(1);
    for (float z = minZ; z <= maxZ + 1; z += hd * 0.25f) {
        line(minX, ceilY, z, minX, gndY, z);
    }
    for (float y = ceilY; y <= gndY + 1; y += (gndY - ceilY) * 0.25f) {
        line(minX, y, minZ, minX, y, maxZ);
    }

    // 5. Right Wall
    noStroke();
    fill(10, 28, 55, 100);
    beginShape();
    vertex(maxX, ceilY, minZ);
    vertex(maxX, ceilY, maxZ);
    vertex(maxX, gndY,  maxZ);
    vertex(maxX, gndY,  minZ);
    endShape(CLOSE);

    stroke(0, 180, 255, 100);
    strokeWeight(1);
    for (float z = minZ; z <= maxZ + 1; z += hd * 0.25f) {
        line(maxX, ceilY, z, maxX, gndY, z);
    }
    for (float y = ceilY; y <= gndY + 1; y += (gndY - ceilY) * 0.25f) {
        line(maxX, y, minZ, maxX, y, maxZ);
    }

    // 6. Front Wall
    noStroke();
    fill(10, 25, 48, 85);
    beginShape();
    vertex(minX, ceilY, maxZ);
    vertex(maxX, ceilY, maxZ);
    vertex(maxX, gndY,  maxZ);
    vertex(minX, gndY,  maxZ);
    endShape(CLOSE);

    stroke(0, 170, 240, 85);
    strokeWeight(1);
    for (float x = minX; x <= maxX + 1; x += hw * 0.25f) {
        line(x, ceilY, maxZ, x, gndY, maxZ);
    }
    for (float y = ceilY; y <= gndY + 1; y += (gndY - ceilY) * 0.25f) {
        line(minX, y, maxZ, maxX, y, maxZ);
    }

    // 7. Glowing 3D Bounding Box Edges & Pillars
    stroke(0, 255, 200, 220);
    strokeWeight(2.5f);
    line(minX, ceilY, minZ, minX, gndY, minZ);
    line(maxX, ceilY, minZ, maxX, gndY, minZ);
    line(maxX, ceilY, maxZ, maxX, gndY, maxZ);
    line(minX, ceilY, maxZ, minX, gndY, maxZ);

    stroke(0, 255, 180, 240);
    strokeWeight(2.5f);
    line(minX, gndY, minZ, maxX, gndY, minZ);
    line(maxX, gndY, minZ, maxX, gndY, maxZ);
    line(maxX, gndY, maxZ, minX, gndY, maxZ);
    line(minX, gndY, maxZ, minX, gndY, minZ);

    stroke(80, 180, 255, 200);
    strokeWeight(2.0f);
    line(minX, ceilY, minZ, maxX, ceilY, minZ);
    line(maxX, ceilY, minZ, maxX, ceilY, maxZ);
    line(maxX, ceilY, maxZ, minX, ceilY, maxZ);
    line(minX, ceilY, maxZ, minX, ceilY, minZ);

    // Spawn plane dashed guide
    stroke(100, 180, 255, 120);
    strokeWeight(1);
    for (float x = minX; x < maxX; x += 30) {
        line(x, skyY, 0, min(x + 15, maxX), skyY, 0);
    }
}

// ── HUD (Scaled Up) ───────────────────────────────────────────────────
void drawGameHUD() {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();

    // ── Top bar ──────────────────────────────────────────────────
    noStroke();
    fill(0, 0, 0, 185);
    rect(0, 0, width, 114);

    // Body label & index
    fill(255);
    textSize(19);
    textAlign(LEFT, TOP);
    text("Body " + (gameBodyIndex + 1) + " / " + TOTAL_BODIES
       + "  —  " + (gameBodyIndex < TOTAL_BODIES ? bodyLabels[gameBodyIndex] : "Done"),
       18, 12);
    fill(140, 220, 255);
    textSize(16);
    text("Alive: " + nf(gameCurBodyTime, 1, 1) + "s", 18, 38);

    // Current peak omega (live)
    textAlign(CENTER, TOP);
    textSize(26);
    fill(255, 220, 80);
    float liveOmega = gameBodyAlive && !gameBodies.isEmpty()
        ? gameBodies.get(0).getAngularVelocity().length() : 0;
    text("ω " + nf(liveOmega, 1, 1) + "  |  peak " + nf(gameCurPeakOmega, 1, 1),
         width * 0.5f, 10);

    // Hit feedback
    textSize(16);
    fill(190);
    text(gameHitInfo, width * 0.5f, 44);

    // Live total time & live score on the top right
    float curTotalSpin = 0;
    for (int i = 0; i < gameBodyIndex; i++) curTotalSpin += gamePeakOmega[i];
    curTotalSpin += gameCurPeakOmega;
    float curTotalScore = curTotalSpin * gameTotalTime;

    textAlign(RIGHT, TOP);
    textSize(17);
    fill(180, 210, 255);
    text("Total Time: " + nf(gameTotalTime, 1, 1) + "s", width - 210, 12);
    textSize(20);
    fill(255, 220, 80);
    text("Score: " + int(curTotalScore), width - 210, 36);

    // Controls hint & trail legend
    textSize(15);
    fill(160);
    textAlign(LEFT, TOP);
    text("[W/S] Move   [A/D] Strafe   [Space/Shift] Elevate   [Right Drag] Look   [Left Click] Shoot", 18, 68);
    text("[Cyan] Center of Mass   [Magenta] Furthest Vertex   [Green] Impact Point   [C] Reset View   [ESC] Menu", 18, 88);

    // ── Score sidebar (right, scaled up) ─────────────────────────
    float sbW = 225;
    float sbX = width - sbW - 18;
    float sbY = 128;
    float rowH = 38;
    float sbH = TOTAL_BODIES * rowH + 86;
    noStroke();
    fill(0, 0, 0, 175);
    rect(sbX - 10, sbY - 10, sbW + 20, sbH + 20, 8);

    textAlign(LEFT, TOP);
    textSize(14);
    fill(190);
    text("ROUND STATS", sbX, sbY);
    textAlign(RIGHT, TOP);
    text("Time | Peak ω", sbX + sbW, sbY);

    for (int i = 0; i < TOTAL_BODIES; i++) {
        float v = (i < gameBodyIndex) ? gamePeakOmega[i]
                : (i == gameBodyIndex) ? gameCurPeakOmega : 0;
        float t = (i < gameBodyIndex) ? gameBodyTime[i]
                : (i == gameBodyIndex) ? gameCurBodyTime : 0;

        textSize(16);
        if (i < gameBodyIndex) {
            fill(120, 220, 120);
        } else if (i == gameBodyIndex) {
            fill(255, 220, 60);
        } else {
            fill(95, 95, 115);
        }
        textAlign(LEFT, TOP);
        text(bodyLabels[i], sbX, sbY + 26 + i * rowH);
        textAlign(RIGHT, TOP);
        text(nf(t, 1, 1) + "s  " + nf(v, 1, 1), sbX + sbW, sbY + 26 + i * rowH);
    }

    // Running summary
    float sumBoxY = sbY + 26 + TOTAL_BODIES * rowH;
    noStroke();
    fill(45, 55, 75, 210);
    rect(sbX - 8, sumBoxY, sbW + 16, 56, 6);
    fill(180, 220, 255);
    textSize(14);
    textAlign(LEFT, TOP);
    text("Time: " + nf(gameTotalTime, 1, 1) + "s   Spin: " + nf(curTotalSpin, 1, 1), sbX, sumBoxY + 6);
    fill(255, 215, 60);
    textSize(18);
    text("SCORE: " + int(curTotalScore), sbX, sumBoxY + 27);

    // ── Progress pips (bottom centre, scaled up) ─────────────────
    int pipR = 11, pipSpacing = 36;
    int pipX = width/2 - (TOTAL_BODIES * pipSpacing)/2 + pipR;
    int pipY = height - 26;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        noStroke();
        if (i < gameBodyIndex)       fill(80, 180, 80);
        else if (i == gameBodyIndex) fill(255, 200, 50);
        else                         fill(55, 75, 130);
        ellipse(pipX + i * pipSpacing, pipY, pipR*2, pipR*2);
    }

    btnGameBack.setBounds(width - 190, 14, 175, 44);
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
    if (key == ' ') keySpace = true;
    if (keyCode == SHIFT) keyShift = true;
    if (key == 'c' || key == 'C') setupGameCamera();
}

void handleGameKeyReleased() {
    if (key == 'w' || key == 'W') keyW = false;
    if (key == 'a' || key == 'A') keyA = false;
    if (key == 's' || key == 'S') keyS = false;
    if (key == 'd' || key == 'D') keyD = false;
    if (key == ' ') keySpace = false;
    if (keyCode == SHIFT) keyShift = false;
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

// Shoot an invisible ray from the 3D camera and apply an impulse at the hit point.
void gameShootRay(float mx, float my) {
    Point3D rayOrigin = new Point3D(gameCX, gameCY, gameCZ);

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
        // Pin impact point to the body's local frame and reset its trail
        gameLastHitLocal = worldToLocal(hitBody, closestHit);
        impactTrail.clear();
        impactTrail.add(new Point3D(closestHit.getX(), closestHit.getY(), closestHit.getZ()));

        // Apply impulse at hit point → off-centre = torque → spin!
        hitBody.applyImpulseAtPoint(dir.mult(hitBody.getMass() * GAME_KICK), closestHit);
        gameHitInfo = "HIT " + hitBody.getClass().getSimpleName()
            + "  ω → " + nf(hitBody.getAngularVelocity().length(), 1, 1);
    } else {
        gameHitInfo = "MISS — aim at the edge for maximum spin";
    }
}

// ==========================================
//  END SCREEN (Scaled Up)
// ==========================================
void drawEndScreen() {
    background(18, 12, 28);
    camera();
    noLights();

    // Title
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255, 80, 180);
    text("Round Complete!", width * 0.5f, height * 0.11f);

    // Per-body breakdown
    float tableW = 480;
    float colX = width * 0.5f - tableW * 0.5f;
    float tableStartY = height * 0.21f;
    textSize(18);
    fill(210);
    textAlign(LEFT, CENTER);
    text("Body", colX, tableStartY);
    textAlign(CENTER, CENTER);
    text("Time Survived", colX + 170, tableStartY);
    text("Peak ω", colX + 320, tableStartY);
    textAlign(RIGHT, CENTER);
    text("Points", colX + tableW, tableStartY);

    stroke(90);
    strokeWeight(1.5f);
    line(colX - 12, tableStartY + 18, colX + tableW + 12, tableStartY + 18);
    noStroke();

    float totalSpin = 0.0f;
    float totalTime = 0.0f;
    for (int i = 0; i < TOTAL_BODIES; i++) {
        totalSpin += gamePeakOmega[i];
        totalTime += gameBodyTime[i];
        float rowY = tableStartY + 44 + i * 36;
        int bodyPoints = int(gameBodyTime[i] * 50.0f + gamePeakOmega[i] * 20.0f);

        textSize(17);
        fill(160, 220, 160);
        textAlign(LEFT, CENTER);
        text(bodyLabels[i], colX, rowY);
        textAlign(CENTER, CENTER);
        text(nf(gameBodyTime[i], 1, 2) + " s", colX + 170, rowY);
        text(nf(gamePeakOmega[i], 1, 2) + " rad/s", colX + 320, rowY);
        textAlign(RIGHT, CENTER);
        fill(255, 220, 80);
        text("+" + bodyPoints, colX + tableW, rowY);
    }

    // Divider
    float dividerY = tableStartY + 44 + TOTAL_BODIES * 36 + 12;
    stroke(90);
    line(colX - 12, dividerY, colX + tableW + 12, dividerY);
    noStroke();

    // Summary lines
    float summaryY = dividerY + 26;
    textSize(18);
    fill(180, 220, 255);
    textAlign(LEFT, CENTER);
    text("Total Time:", colX, summaryY);
    textAlign(RIGHT, CENTER);
    text(nf(totalTime, 1, 2) + " s  (+" + int(gameTimeScore) + " pts)", colX + tableW, summaryY);

    textSize(18);
    fill(180, 255, 200);
    textAlign(LEFT, CENTER);
    text("Total Peak Spin:", colX, summaryY + 30);
    textAlign(RIGHT, CENTER);
    text(nf(totalSpin, 1, 2) + " rad/s  (+" + int(gameSpinScore) + " pts)", colX + tableW, summaryY + 30);

    // Total final score
    float scoreY = summaryY + 80;
    textSize(34);
    fill(255, 220, 80);
    textAlign(LEFT, CENTER);
    text("FINAL SCORE", colX, scoreY);
    textAlign(RIGHT, CENTER);
    text(int(gameFinalScore), colX + tableW, scoreY);

    textSize(15);
    fill(150);
    textAlign(CENTER, CENTER);
    text("(Final Score = Total Spin × Total Time)", width * 0.5f, scoreY + 34);

    // Dynamically center scaled buttons
    float bW = 300, bH = 56;
    float bX = width * 0.5f - bW * 0.5f;
    float btnStartY = scoreY + 64;
    btnEndReplay.setBounds(bX, btnStartY, bW, bH);
    btnEndMainMenu.setBounds(bX, btnStartY + 68, bW, bH);
    btnEndReplay.draw();
    btnEndMainMenu.draw();

    textSize(15);
    fill(90);
    textAlign(CENTER, BOTTOM);
    text("[ESC] returns to Main Menu", width * 0.5f, height - 16);
}

void handleEndScreenClick() {
    if (btnEndReplay.isOver())        startGame();
    else if (btnEndMainMenu.isOver()) goToMainMenu();
}
