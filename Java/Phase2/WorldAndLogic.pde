class Arena {
    void setupLighting(processing.core.PApplet app) {
        app.background(130, 190, 232); 
        // Default static camera (if player null) needs matching inverted Up
        app.camera(0.0f, 40.0f, -520.0f,
                   0.0f, 0.0f, 0.0f,
                   0.0f, -1.0f, 0.0f); 
        app.lights();
        app.ambientLight(130, 135, 140);
        app.directionalLight(255, 250, 232, -0.35f, -0.75f, -0.4f);
    }

    void draw(processing.core.PApplet app) {
        if (player == null || earth == null) return;

        Point3D pPos = player.getPosition();
        Point3D ePos = earth.getPosition();
        Vector3D relPos = pPos.sub(ePos);
        
        Vector3D normal = relPos.normalized();
        // Since Earth is at -Y, the vector pointing away from it (Up) is +Y
        Vector3D defaultUp = new Vector3D(0.0f, 1.0f, 0.0f); 
        
        Vector3D axis = defaultUp.cross(normal);
        float angle = (float)defaultUp.angleTo(normal);
        
        if (axis.lengthSquared() < 1e-6f) {
            axis = new Vector3D(1.0f, 0.0f, 0.0f);
        } else {
            axis.normalize();
        }
        
        // Calculate exact point on the surface
        Vector3D surfaceOffset = normal.mult(earth.radius);
        Point3D surfacePoint = ePos.add(surfaceOffset);

        app.pushMatrix();
        
        app.translate(surfacePoint.getX(), surfacePoint.getY(), surfacePoint.getZ());
        app.rotate(angle, axis.getX(), axis.getY(), axis.getZ());
        
        float gridSpacing = 50.0f;
        float viewDistance = 2000.0f;
        
        float shiftX = pPos.getX() % gridSpacing;
        float shiftZ = pPos.getZ() % gridSpacing;
        
        app.noStroke();
        
        // Draw base slightly lower (-Y) so its top surface sits exactly at 0.0
        app.fill(60, 160, 90);
        app.pushMatrix();
        app.translate(0.0f, -0.5f, 0.0f); 
        app.box(viewDistance * 2.0f, 1.0f, viewDistance * 2.0f); 
        app.popMatrix();
        
        // Draw 3D grid lines slightly higher (+Y) to sit on top of the base
        app.fill(25, 75, 40);
        float lineWidth = 0.4f; 
        float lineHeight = 0.05f; 
        float lineY = lineHeight / 2.0f; 
        
        for (float x = -viewDistance; x <= viewDistance; x += gridSpacing) {
            float lx = x - shiftX;
            app.pushMatrix();
            app.translate(lx, lineY, 0.0f);
            app.box(lineWidth, lineHeight, viewDistance * 2.0f);
            app.popMatrix();
        }
        
        for (float z = -viewDistance; z <= viewDistance; z += gridSpacing) {
            float lz = z - shiftZ;
            app.pushMatrix();
            app.translate(0.0f, lineY, lz);
            app.box(viewDistance * 2.0f, lineHeight, lineWidth);
            app.popMatrix();
        }
        
        app.popMatrix();
    }
}
