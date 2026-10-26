// ==========================================
// Collision Detection and Constraints
// ==========================================

class Cable {
    Particle p1;
    Particle p2;
    float maxLength;
    boolean visible;

    public Cable(Particle p1, Particle p2, float maxLength) {
        this.p1 = p1;
        this.p2 = p2;
        this.maxLength = maxLength;
    }
    
    void draw() {
        if (!visible || p1 == null || p2 == null) return;
        Point3D pos1 = p1.getPosition();
        Point3D pos2 = p2.getPosition();
        
        // Render the cable as a distinct visible 3D line
        stroke(220, 200, 50); // Gold/Yellow wire color
        strokeWeight(4.0f);   // Thickness of the cable
        line(pos1.getX(), pos1.getY(), pos1.getZ(), 
             pos2.getX(), pos2.getY(), pos2.getZ());
        noStroke(); // Reset stroke so it doesn't affect other shapes
    }
}

class Rod {
    Particle p1;
    Particle p2;
    float fixedLength;
    boolean visible;

    public Rod(Particle p1, Particle p2, float fixedLength) {
        this.p1 = p1;
        this.p2 = p2;
        this.fixedLength = fixedLength;
        this.visible = true;
    }
    
    void draw() {
        if (!visible || p1 == null || p2 == null) return;
        Point3D pos1 = p1.getPosition();
        Point3D pos2 = p2.getPosition();
        
        // Render the rigid rod as a distinct thick silver bar
        stroke(180, 180, 200); 
        strokeWeight(6.0f);   
        line(pos1.getX(), pos1.getY(), pos1.getZ(), pos2.getX(), pos2.getY(), pos2.getZ());
        noStroke(); 
    }
}


class AnalyticalSlope {
    Point3D startPos;
    float length;
    float width;
    float angleDeg;
    float thickness = 0.5f;
    Material material;
    
    Vector3D normal;

    public AnalyticalSlope(Point3D startPos, float length, float width, float angleDeg, Material material) {
        this.startPos = startPos;
        this.length = length;
        this.width = width;
        this.angleDeg = angleDeg;
        this.material = material;

        float rad = radians(angleDeg);
        float sinA = sin(rad);
        float cosA = cos(rad);

        this.normal = new Vector3D(-sinA, cosA, 0.0f).normalized();
    }

    void draw(processing.core.PApplet app) {
        app.pushMatrix();
        app.translate(startPos.getX(), startPos.getY(), startPos.getZ());
        app.rotateZ(radians(angleDeg));
        app.translate(length / 2.0f, -thickness / 2.0f, 0.0f);
        
        app.noStroke();
        app.fill(120, 110, 100); 
        app.box(length, thickness, width); 
        app.popMatrix();
    }
}

// Analytical slope collision resolver
void resolveSlopeCollisions(AnalyticalSlope slope, float dt) {
    float halfWidth = slope.width / 2.0f;
    float rad = radians(slope.angleDeg);
    float cosA = cos(rad);
    float sinA = sin(rad);

    for (Particle p : particles) {
        if (p.getInverseMass() <= 0.0f) continue; // Skip static objects

        Point3D pPos = p.getPosition();
        float r = p.getRadius();

        // Local coordinate transformation
        float localX = (pPos.getX() - slope.startPos.getX()) * cosA + (pPos.getY() - slope.startPos.getY()) * sinA;
        float localY = -(pPos.getX() - slope.startPos.getX()) * sinA + (pPos.getY() - slope.startPos.getY()) * cosA;
        float localZ = pPos.getZ() - slope.startPos.getZ();

        // Check if within bounds of the slope
        if (localX >= 0.0f && localX <= slope.length && localZ >= -halfWidth && localZ <= halfWidth) {
            float penetration = r - localY;

            if (penetration > 0.0f) {
                Vector3D n = slope.normal;
                p.moveSilently(n.mult(penetration));

                Vector3D v = p.getVelocity();
                float vDotN = v.dot(n);

                if (vDotN < 0.0f) {
                    MaterialInteraction interaction = PhysicsMaterials.get(p.getMaterial(), slope.material);
                    float e = interaction.restitution;

                    float gravityVelocity = PhysicsConstants.GRAVITY * dt;
                    if (Math.abs(vDotN) <= gravityVelocity * 1.01f) {
                        e = 0.0f; 
                    }

                    float k = (-(e + 1.0f) * vDotN) / p.getInverseMass();
                    Vector3D collisionForce = n.mult(k).div(dt);
                    p.addForce(collisionForce);

                    float normalForce = k / dt;
                    applySlopeFriction(p, n, normalForce, dt, slope.material);
                }
            }
        }
    }
}

void applySlopeFriction(Particle p, Vector3D n, float normalForce, float dt, Material slopeMat) {
    if (normalForce <= 0.0f) return;

    MaterialInteraction material = PhysicsMaterials.get(p.getMaterial(), slopeMat);
    float staticCoeff = material.staticFriction;
    float kineticCoeff = Math.min(material.kineticFriction, staticCoeff);

    Vector3D v = p.getVelocity();
    Vector3D vTangent = v.sub(n.mult(v.dot(n)));
    float slideSpeed = vTangent.length();

    if (slideSpeed < 1e-6f) return;

    Vector3D t = vTangent.mult(1.0f / slideSpeed);
    float stopSpeedForce = slideSpeed / (dt * p.getInverseMass());
    float maxStaticForce = staticCoeff * normalForce;
    
    float frictionForce = (stopSpeedForce <= maxStaticForce) ? stopSpeedForce : kineticCoeff * normalForce;
    p.addForce(t.mult(-frictionForce));
}

void resolveCollisionsAndConstraints(float dt) {
    contactFriction.beginStep();

    // 1. O(N^2) PARTICLE COLLISION LOOP
    for (int i = 0; i < particles.size(); i++) {
        for (int j = i + 1; j < particles.size(); j++) {
            Particle p1 = particles.get(i);
            Particle p2 = particles.get(j);

            float r1 = p1.getRadius();
            float r2 = p2.getRadius();
            
            double dx = (double)p2.getPosition().getX() - (double)p1.getPosition().getX();
            double dy = (double)p2.getPosition().getY() - (double)p1.getPosition().getY();
            double dz = (double)p2.getPosition().getZ() - (double)p1.getPosition().getZ();
            
            double distSq = dx * dx + dy * dy + dz * dz;
            double dist = Math.sqrt(distSq);
            double sumRadii = (double)r1 + (double)r2;

            if (dist < sumRadii && dist > 0.00001) {
                Vector3D n = new Vector3D((float)(dx / dist), (float)(dy / dist), (float)(dz / dist));
                float d = (float)(sumRadii - dist); 
                
                float invM1 = p1.getInverseMass();
                float invM2 = p2.getInverseMass();
                float totalInvMass = invM1 + invM2;

                if (totalInvMass > 0.0f) {
                    float shiftP1 = d * (invM1 / totalInvMass);
                    float shiftP2 = d * (invM2 / totalInvMass);
                    p1.moveSilently(n.mult(-shiftP1));
                    p2.moveSilently(n.mult(shiftP2));
                }

                Vector3D vRel = p1.getVelocity().sub(p2.getVelocity());
                float vRelDotN = vRel.dot(n);
                
                if (vRelDotN < 0) continue; 
                
                MaterialInteraction interaction = PhysicsMaterials.get(p1.getMaterial(), p2.getMaterial());
                float e = interaction.restitution;
                
                float gravityVelocity = PhysicsConstants.GRAVITY * dt;
                if (Math.abs(vRelDotN) <= gravityVelocity * 1.01f) {
                    e = 0.0f; 
                }
                
                float normalForce = 0.0f;
                if (totalInvMass > 0.0f) {
                    float k = ((e + 1.0f) * vRelDotN) / totalInvMass;
                    Vector3D collisionForce = n.mult(k).div(dt);
                    normalForce = k / dt;
                    p1.addForce(collisionForce.negate());
                    p2.addForce(collisionForce);
                }
                
                contactFriction.applyContact(p1, p2, n, normalForce, dt);
            }
        }
    }

    // 2. ANALYTICAL SLOPE COLLISIONS
    for (AnalyticalSlope slope : analyticalSlopes) {
        resolveSlopeCollisions(slope, dt);
    }

    // 3. CABLE CONSTRAINTS
    for (Cable cable : cables) {
        Particle p1 = cable.p1;
        Particle p2 = cable.p2;
        
        double dx = (double)p2.getPosition().getX() - (double)p1.getPosition().getX();
        double dy = (double)p2.getPosition().getY() - (double)p1.getPosition().getY();
        double dz = (double)p2.getPosition().getZ() - (double)p1.getPosition().getZ();
        
        double dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        
        if (dist > (double)cable.maxLength && dist > 0.00001) {
            Vector3D n = new Vector3D((float)(dx / dist), (float)(dy / dist), (float)(dz / dist));
            float d = (float)(dist - cable.maxLength); 
            
            float invM1 = p1.getInverseMass();
            float invM2 = p2.getInverseMass();
            float totalInvMass = invM1 + invM2;

            if (totalInvMass > 0.0f) {
                float shiftP1 = d * (invM1 / totalInvMass);
                float shiftP2 = d * (invM2 / totalInvMass);
                p1.moveSilently(n.mult(shiftP1));
                p2.moveSilently(n.mult(-shiftP2));
            }

            Vector3D vRel = p1.getVelocity().sub(p2.getVelocity());
            float vRelDotN = vRel.dot(n);
            
            if (vRelDotN > 0) continue;

            if (totalInvMass > 0.0f) {
                float k = ((0.0f + 1.0f) * vRelDotN) / totalInvMass;
                Vector3D constraintForce = n.mult(k).div(dt);
                p1.addForce(constraintForce.negate());
                p2.addForce(constraintForce);
            }
        }
    }
    
    // 4. ROD CONSTRAINTS (Tige - rigid fixed length)
    for (Rod rod : rods) {
        Particle p1 = rod.p1;
        Particle p2 = rod.p2;
        
        double dx = (double)p2.getPosition().getX() - (double)p1.getPosition().getX();
        double dy = (double)p2.getPosition().getY() - (double)p1.getPosition().getY();
        double dz = (double)p2.getPosition().getZ() - (double)p1.getPosition().getZ();
        
        double distSq = dx * dx + dy * dy + dz * dz;
        double dist = Math.sqrt(distSq);
        
        // Only resolve if the distance deviates from the fixed length
        if (Math.abs(dist - rod.fixedLength) > 0.00001 && dist > 0.00001) {
            Vector3D n = new Vector3D((float)(dx / dist), (float)(dy / dist), (float)(dz / dist));
            float d = (float)(dist - rod.fixedLength); 
            
            float invM1 = p1.getInverseMass();
            float invM2 = p2.getInverseMass();
            float totalInvMass = invM1 + invM2;

            // Positional Correction: separate or pull together based inversely on their masses[cite: 14]
            if (totalInvMass > 0.0f) {
                float shiftP1 = d * (invM1 / totalInvMass);
                float shiftP2 = d * (invM2 / totalInvMass);
                p1.moveSilently(n.mult(shiftP1));
                p2.moveSilently(n.mult(-shiftP2));
            }

            // Velocity Correction: essentially a resting contact that completely cancels relative velocity (e=0)[cite: 16]
            Vector3D vRel = p1.getVelocity().sub(p2.getVelocity());
            float vRelDotN = vRel.dot(n);
            
            if (totalInvMass > 0.0f) {
                float k = (1.0f * vRelDotN) / totalInvMass;
                Vector3D constraintForce = n.mult(k).div(dt);
                p1.addForce(constraintForce.negate());
                p2.addForce(constraintForce);
            }
        }
    }
}
