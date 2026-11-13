// ==========================================
// Phase 3 : fichier principal du sketch
// ------------------------------------------
// Scene de test visuelle pour RigidBody et interceptLine()
// ==========================================

ArrayList<RigidBody> bodies;
ArrayList<Point3D> hitDots;

Point3D lastRayStart = null;
Point3D lastRayEnd = null;
String lastHitInfo = "Click anywhere on a shape to shoot a ray.";

boolean autoRotate = true;
GraphBody graphBody;
int currentPatternIndex = 3; // Starts on TREFOIL_KNOT

// Camera parameters (Processing default perspective)
float camX, camY, camZ;
float targetX, targetY, targetZ;

void setup() {
    size(800, 600, P3D);
    // new MathTests().run();

    camX = width * 0.5f;
    camY = height * 0.5f;
    camZ = (height * 0.5f) / tan(PI / 6.0f);
    targetX = width * 0.5f;
    targetY = height * 0.5f;
    targetZ = 0.0f;

    bodies = new ArrayList<RigidBody>();
    hitDots = new ArrayList<Point3D>();

    float cx = width * 0.5f;
    float cy = height * 0.5f;

    // 1. TriangleBody (uneven vertex weights: top vertex is heavier)
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

    // 2. SquareBody (rectangular box with +X mass bias)
    SquareBody boxBody = new SquareBody(
        new Point3D(cx + 220, cy - 90, 0),
        new Quaternion(new Vector3D(1, 1, 0), 0.5f),
        20.0f,
        75.0f, 55.0f, 55.0f,
        new Vector3D(0.7f, 0.0f, 0.0f)
    );
    bodies.add(boxBody);

    // 3. cylenderBody (bottom-heavy cylinder)
    cylenderBody cylinder = new cylenderBody(
        new Point3D(cx - 220, cy + 120, 0),
        new Quaternion(new Vector3D(1, 0, 0.3f), 0.4f),
        25.0f,
        32.0f, 85.0f,
        1.0f, 6.0f, 2.0f
    );
    bodies.add(cylinder);

    // 4. GraphBody (24-node Trefoil Knot with downward weight skew)
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
}

void draw() {
    background(30);
    lights();

    // Explicit camera setup so raycasting matches projection
    camera(camX, camY, camZ, targetX, targetY, targetZ, 0, 1, 0);

    // Optional slow rotation to inspect 3D geometry & uneven centers of gravity
    if (autoRotate) {
        Quaternion dq = new Quaternion(new Vector3D(0.3f, 1.0f, 0.2f), 0.01f);
        for (RigidBody body : bodies) {
            body.setRotationQuaternion(dq.mult(body.getRotationQuaternion()));
        }
    }

    // Draw all RigidBodies
    for (RigidBody body : bodies) {
        body.draw();
    }

    // Draw the last shot ray line
    if (lastRayStart != null && lastRayEnd != null) {
        stroke(255, 230, 80, 180);
        strokeWeight(2);
        line(
            lastRayStart.getX(), lastRayStart.getY(), lastRayStart.getZ(),
            lastRayEnd.getX(), lastRayEnd.getY(), lastRayEnd.getZ()
        );
    }

    // Draw visible dots at every recorded hit location
    noStroke();
    fill(50, 255, 100);
    sphereDetail(16);
    for (Point3D hit : hitDots) {
        pushMatrix();
        translate(hit.getX(), hit.getY(), hit.getZ());
        sphere(5.0f);
        popMatrix();
    }

    // Draw 2D HUD overlay
    drawHUD();
}

void mousePressed() {
    if (mouseButton == LEFT) {
        shootRayFromMouse(mouseX, mouseY);
    }
}

void keyPressed() {
    if (key == ' ') {
        autoRotate = !autoRotate;
    } else if (key == 'r' || key == 'R') {
        hitDots.clear();
        lastRayStart = null;
        lastRayEnd = null;
        lastHitInfo = "Cleared hit markers.";
    } else if (key == 'g' || key == 'G') {
        GraphShapePattern[] patterns = GraphShapePattern.values();
        currentPatternIndex = (currentPatternIndex + 1) % patterns.length;
        graphBody.generateShape(24, patterns[currentPatternIndex], new Vector3D(0.0f, 1.2f, 0.0f));
        lastHitInfo = "GraphBody pattern: " + patterns[currentPatternIndex];
    }
}

// Computes a 3D line segment from the camera through (mx, my) and tests interceptLine()
void shootRayFromMouse(float mx, float my) {
    Point3D rayOrigin = new Point3D(camX, camY, camZ);

    // Unproject screen pixel onto the plane z = 0 using Processing's default 60-deg vertical FOV
    float fov = PI / 3.0f;
    float aspect = (float)width / (float)height;
    float ndcX = (2.0f * mx / width) - 1.0f;
    float ndcY = (2.0f * my / height) - 1.0f;

    float halfH = camZ * tan(fov * 0.5f);
    float halfW = halfH * aspect;

    Point3D planePoint = new Point3D(
        targetX + ndcX * halfW,
        targetY + ndcY * halfH,
        0.0f
    );

    // Extend ray past z = 0 so it passes completely through all objects
    Vector3D dir = planePoint.sub(rayOrigin).normalized();
    Point3D rayEnd = rayOrigin.add(dir.mult(camZ * 2.0f));

    lastRayStart = rayOrigin;
    lastRayEnd = rayEnd;

    // Find the closest hit among all RigidBodies
    Point3D closestHit = null;
    RigidBody hitBody = null;
    float bestDistSq = Float.MAX_VALUE;

    for (RigidBody body : bodies) {
        Point3D hit = body.interceptLine(rayOrigin, rayEnd);
        if (hit != null) {
            float dSq = rayOrigin.distanceSquaredTo(hit);
            if (dSq < bestDistSq) {
                bestDistSq = dSq;
                closestHit = hit;
                hitBody = body;
            }
        }
    }

    if (closestHit != null) {
        hitDots.add(closestHit);
        lastHitInfo = "HIT " + hitBody.getClass().getSimpleName() + " at ("
            + nf(closestHit.getX(), 1, 1) + ", "
            + nf(closestHit.getY(), 1, 1) + ", "
            + nf(closestHit.getZ(), 1, 1) + ")";
    } else {
        lastHitInfo = "MISS (no intersection)";
    }
}

void drawHUD() {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();

    fill(240);
    textSize(13);
    textAlign(LEFT, TOP);
    text("Controls: [Left Click] Shoot Ray   [SPACE] Pause/Rotate   [G] Cycle Graph Shape   [R] Clear Dots", 15, 15);
    text("Status: " + lastHitInfo + "   |   Total Hits: " + hitDots.size(), 15, 35);

    textAlign(CENTER, TOP);
    fill(180);
    text("TriangleBody (Uneven)", width * 0.5f - 240, height * 0.5f - 165);
    text("SquareBody (Biased)", width * 0.5f + 220, height * 0.5f - 165);
    text("cylenderBody (Bottom-Heavy)", width * 0.5f - 220, height * 0.5f + 195);
    text("GraphBody (" + graphBody.shapePattern + ")", width * 0.5f + 210, height * 0.5f + 195);

    hint(ENABLE_DEPTH_TEST);
}
