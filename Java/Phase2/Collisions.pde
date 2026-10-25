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

void resolveCollisionsAndConstraints(float dt) {
    contactFriction.beginStep();

    // 1. O(N^2) COLLISION LOOP
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

            // Detect collision (interpenetration)
            if (dist < sumRadii && dist > 0.00001) {
                Vector3D n = new Vector3D((float)(dx / dist), (float)(dy / dist), (float)(dz / dist));
                float d = (float)(sumRadii - dist); 
                
                float invM1 = p1.getInverseMass();
                float invM2 = p2.getInverseMass();
                float totalInvMass = invM1 + invM2;

                // A. SEPARATE OBJECTS (Move Silently prevents Verlet jitter)
                if (totalInvMass > 0.0f) {
                    float shiftP1 = d * (invM1 / totalInvMass);
                    float shiftP2 = d * (invM2 / totalInvMass);
                    p1.moveSilently(n.mult(-shiftP1));
                    p2.moveSilently(n.mult(shiftP2));
                }

                // B. CALCULATE RELATIVE VELOCITY
                Vector3D vRel = p1.getVelocity().sub(p2.getVelocity());
                float vRelDotN = vRel.dot(n);
                
                if (vRelDotN < 0) continue; 
                
                MaterialInteraction interaction = PhysicsMaterials.get(p1.getMaterial(), p2.getMaterial());
                
                float e = interaction.restitution;
                
                // C. CONTACT AU REPOS
                float gravityVelocity = PhysicsConstants.GRAVITY * dt;
                // NOTE (friction) : tolérance de 1 %. Au repos, vRelDotN vaut g*dt à l'arrondi flottant près :
                // sans tolérance, le test échoue un pas sur deux, la balle reçoit un petit rebond (e > 0) et
                // la force normale alterne entre un pas fort et un pas faible. La friction statique
                // (mu_s * N) est alors trop faible un pas sur deux et la balle s'échappe.
                if (Math.abs(vRelDotN) <= gravityVelocity * 1.01f) {
                    e = 0.0f; // Force perfectly inelastic collision (no bounce)
                }
                
                // D. APPLY FORCES TO ACCUMULATOR
                float normalForce = 0.0f;
                if (totalInvMass > 0.0f) {
                    float k = ((e + 1.0f) * vRelDotN) / totalInvMass;
                    Vector3D collisionForce = n.mult(k).div(dt);
                    normalForce = k / dt;
                    p1.addForce(collisionForce.negate());
                    p2.addForce(collisionForce);
                }
                
                // E. FRICTION (Coulomb) : réutilise la normale et la force normale déjà calculées.
                // Les coefficients sont lus dans PhysicsMaterials par le générateur.
                contactFriction.applyContact(p1, p2, n, normalForce, dt);
            }
        }
    }

    // 2. CABLE CONSTRAINTS
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
}
