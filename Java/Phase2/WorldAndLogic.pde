// ==========================================
// Arena, TargetGoal, AimSolvers & Factory
// ==========================================

class Arena {
    final float Extent = 2560.0f;
    final float Spacing = 40.0f;
    final float WallHeight = 1200.0f;
    final float WallThickness = 10.0f;
    final float MaxCeilingHeight = 2000.0f;

    // Depth (Z) at which the grassy plain ends and the water begins.
    // The cannon sits on the plain side (Z < ShoreZ), the boats float
    // on the water side (Z >= ShoreZ), matching TargetGoal's spawn range.
    final float ShoreZ = 150.0f;

    void setupLighting(processing.core.PApplet app) {
        app.background(130, 190, 232); // open sky
        app.camera(0.0f, -40.0f, -520.0f,
                   0.0f, 0.0f, 0.0f,
                   0.0f, 1.0f, 0.0f);
        app.lights();
        app.ambientLight(130, 135, 140);
        app.directionalLight(255, 250, 232, -0.35f, -0.75f, -0.4f);
    }

    void draw(processing.core.PApplet app) {
        float floorTopY = GraphicsConstants.floorY - 2.0f;

        // --- Plain (grass), from the back wall up to the shoreline ---
        float plainDepth = ShoreZ - (-Extent);
        app.noStroke();
        app.fill(70, 120, 60);
        app.pushMatrix();
        app.translate(0.0f, floorTopY, -Extent + plainDepth * 0.5f);
        app.box(Extent * 2.0f, 4.0f, plainDepth);
        app.popMatrix();

        // --- Water, from the shoreline to the far wall ---
        float waterDepth = Extent - ShoreZ;
        app.fill(40, 95, 165, 235);
        app.pushMatrix();
        app.translate(0.0f, floorTopY, ShoreZ + waterDepth * 0.5f);
        app.box(Extent * 2.0f, 4.0f, waterDepth);
        app.popMatrix();

        // --- Shoreline strip ---
        app.fill(210, 195, 150);
        app.pushMatrix();
        app.translate(0.0f, floorTopY - 0.5f, ShoreZ);
        app.box(Extent * 2.0f, 3.0f, 26.0f);
        app.popMatrix();

        // --- Grass Grid (plain only) ---
        app.stroke(95, 150, 90, 160);
        app.strokeWeight(1.0f);
        for (float coord = -Extent; coord <= Extent; coord += Spacing) {
            app.line(coord, GraphicsConstants.floorY, -Extent, coord, GraphicsConstants.floorY, ShoreZ);
        }
        for (float coord = -Extent; coord <= ShoreZ; coord += Spacing) {
            app.line(-Extent, GraphicsConstants.floorY, coord, Extent, GraphicsConstants.floorY, coord);
        }

        // --- Water ripples (water side only) ---
        app.stroke(170, 220, 240, 140);
        for (float coord = ShoreZ + Spacing; coord <= Extent; coord += Spacing * 2.0f) {
            app.line(-Extent, GraphicsConstants.floorY, coord, Extent, GraphicsConstants.floorY, coord);
        }
        app.noStroke();

        // --- Boundary Walls (distant hills / haze) ---
        app.fill(75, 110, 95, 160);
        float wallCenterY = GraphicsConstants.floorY - (WallHeight * 0.5f);

        app.pushMatrix(); app.translate(0.0f, wallCenterY, -Extent); app.box(Extent * 2.0f, WallHeight, WallThickness); app.popMatrix();
        app.pushMatrix(); app.translate(0.0f, wallCenterY, Extent); app.box(Extent * 2.0f, WallHeight, WallThickness); app.popMatrix();
        app.pushMatrix(); app.translate(-Extent, wallCenterY, 0.0f); app.box(WallThickness, WallHeight, Extent * 2.0f); app.popMatrix();
        app.pushMatrix(); app.translate(Extent, wallCenterY, 0.0f); app.box(WallThickness, WallHeight, Extent * 2.0f); app.popMatrix();
    }

    boolean isOutOfBounds(Point3D pos) {
        return (pos.getY() <= -GraphicsConstants.floorY) ||
               (pos.getY() >= MaxCeilingHeight) ||
               (Math.abs(pos.getX()) >= Extent) ||
               (Math.abs(pos.getZ()) >= Extent);
    }
}
