//////////////////////
// Ressorts (generateurs de forces)
//////////////////////
// Calcul commun : force de Hooke
/////////////////////
Vector3D computeSpringForce(Particle particle, Point3D otherEnd,
                            float springConstant, float restLength, boolean tensionOnly) {
    Vector3D d = particle.getPosition().sub(otherEnd);
    float length = d.length();
    if (length < 1e-6f) return new Vector3D(); // direction indéfinie

    if (tensionOnly && length <= restLength) return new Vector3D();

    Vector3D dir = d.mult(1.0f / length);
    float magnitude = springConstant * (length - restLength);
    return dir.mult(-magnitude);
}
//////////////////////
// 1. Ressort classique
//////////////////////
class ParticleSpring implements ParticleForceGenerator, DrawableForceGenerator {
    Particle other;
    float springConstant;
    float restLength;
    
    float elasticLimit = 0.0f;
    boolean visible = true;

    ParticleSpring(Particle other, float springConstant, float restLength) {
        this.other = other;
        this.springConstant = springConstant;
        this.restLength = restLength;
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass()) return;
        if (isBeyondElasticLimit(particle)) return;
        particle.addForce(computeSpringForce(particle, other.getPosition(),
                                             springConstant, restLength, false));
    }

    float currentLength(Particle particle) {
        return particle.getPosition().distanceTo(other.getPosition());
    }

    boolean isBeyondElasticLimit(Particle particle) {
        return elasticLimit > 0.0f && currentLength(particle) > elasticLimit;
    }

    public void draw(Particle particle) {
        if (!visible) return;
        float limit = (elasticLimit > 0.0f) ? elasticLimit : restLength * 2.0f;
        drawSpringCoil(particle.getPosition(), other.getPosition(), restLength, limit);
    }
}

//////////////////////
// 2. Ressort ancré (point fixe)
//////////////////////
class ParticleAnchoredSpring implements ParticleForceGenerator, DrawableForceGenerator {
    Point3D anchor;
    float springConstant;
    float restLength;
    boolean visible = true;

    ParticleAnchoredSpring(Point3D anchor, float springConstant, float restLength) {
        this.anchor = anchor;
        this.springConstant = springConstant;
        this.restLength = restLength;
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass()) return;
        particle.addForce(computeSpringForce(particle, anchor, springConstant, restLength, false));
    }

    public void draw(Particle particle) {
        if (!visible) return;
        drawSpringCoil(particle.getPosition(), anchor, restLength, restLength * 2.0f);
        drawAnchor(anchor);
    }
}

//////////////////////
// 3. Élastique (bungee) entre deux particules
//////////////////////
class ParticleBungee implements ParticleForceGenerator, DrawableForceGenerator {
    Particle other;
    float springConstant;
    float restLength;
    boolean visible = true;

    ParticleBungee(Particle other, float springConstant, float restLength) {
        this.other = other;
        this.springConstant = springConstant;
        this.restLength = restLength;
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass()) return;
        particle.addForce(computeSpringForce(particle, other.getPosition(), springConstant, restLength, true));
    }

    public void draw(Particle particle) {
        if (!visible) return;
        drawBungeeLine(particle.getPosition(), other.getPosition(), restLength);
    }
}
//////////////////////
// 4. Élastique ancré
////////////////////
class ParticleAnchoredBungee implements ParticleForceGenerator, DrawableForceGenerator {
    Point3D anchor;
    float springConstant;
    float restLength;
    boolean visible = true;

    ParticleAnchoredBungee(Point3D anchor, float springConstant, float restLength) {
        this.anchor = anchor;
        this.springConstant = springConstant;
        this.restLength = restLength;
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass()) return;
        particle.addForce(computeSpringForce(particle, anchor, springConstant, restLength, true));
    }

    public void draw(Particle particle) {
        if (!visible) return;
        drawBungeeLine(particle.getPosition(), anchor, restLength);
        drawAnchor(anchor);
    }
}
//////////////////////
// 5. Flottabilité
//////////////////////


class ParticleBuoyancy implements ParticleForceGenerator {
    float maxDepth;
    float volume;
    float waterHeight;
    float liquidDensity;

    ParticleBuoyancy(float maxDepth, float volume, float waterHeight) {
        this(maxDepth, volume, waterHeight, 1000.0f); // eau : 1000 kg/m³
    }

    ParticleBuoyancy(float maxDepth, float volume, float waterHeight, float liquidDensity) {
        this.maxDepth = maxDepth;
        this.volume = volume;
        this.waterHeight = waterHeight;
        this.liquidDensity = liquidDensity;
    }

    float submergedRatio(float y) {
        if (y >= waterHeight + maxDepth) return 0.0f;
        if (y <= waterHeight - maxDepth) return 1.0f;
        return (waterHeight + maxDepth - y) / (2.0f * maxDepth);
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass()) return;
        float ratio = submergedRatio(particle.getPosition().getY());
        if (ratio <= 0.0f) return;
        float force = liquidDensity * volume * PhysicsConstants.GRAVITY * ratio;
        particle.addForce(new Vector3D(0.0f, force, 0.0f));
    }
}

//////////////////////
// 6. Ressort rigide (mouvement harmonique amorti, chap 5)
//////////////////////
class ParticleStiffSpring implements ParticleForceGenerator, DrawableForceGenerator {
    Point3D anchor;
    float springConstant;
    float damping;
    boolean visible = true;

    ParticleStiffSpring(Point3D anchor, float springConstant, float damping) {
        this.anchor = anchor;
        this.springConstant = springConstant;
        this.damping = damping;
    }

    public void updateForce(Particle particle, float duration) {
        if (!particle.hasFiniteMass() || duration <= 0.0f) return;

        float m = particle.getMass();
        Vector3D x0 = particle.getPosition().sub(anchor);
        Vector3D v0 = particle.getVelocity();

        Vector3D target = dampedHarmonicPosition(x0, v0, springConstant, damping, m, duration);
        if (target == null) return;

        Vector3D accel = target.sub(x0).mult(1.0f / (duration * duration))
                               .sub(v0.mult(1.0f / duration));

        particle.addForce(accel.mult(m));
    }

    public void draw(Particle particle) {
        if (!visible) return;
        drawSpringCoil(particle.getPosition(), anchor, 0.0f, 1.0f);
        drawAnchor(anchor);
    }
}


Vector3D dampedHarmonicPosition(Vector3D x0, Vector3D v0, float k, float c, float m, float t) {
    float omega0 = (float)Math.sqrt(k / m);
    float zeta = c / (2.0f * (float)Math.sqrt(m * k));

    if (Math.abs(zeta - 1.0f) < 1e-4f) {
        Vector3D k1 = x0;
        Vector3D k2 = x0.mult(omega0).add(v0);
        return k1.add(k2.mult(t)).mult((float)Math.exp(-omega0 * t));
    }
    if (zeta < 1.0f) {
        float omegaD = omega0 * (float)Math.sqrt(1.0f - zeta * zeta);
        Vector3D k1 = x0;
        Vector3D k2 = x0.mult(zeta * omega0).add(v0).mult(1.0f / omegaD);
        return k1.mult((float)Math.cos(omegaD * t))
                 .add(k2.mult((float)Math.sin(omegaD * t)))
                 .mult((float)Math.exp(-zeta * omega0 * t));
    }
    return null;
}

//////////////////////
// Lien du blob : ressort classique + câble
//////////////////////// 
class ElasticLink {
    Particle a, b;
    ParticleSpring springOnA; 
    ParticleSpring springOnB;
    Cable cable;
    boolean broken = false;

    ElasticLink(Particle a, Particle b, float springConstant, float restLength, float elasticLimit) {
        this.a = a;
        this.b = b;

        springOnA = new ParticleSpring(b, springConstant, restLength);
        springOnB = new ParticleSpring(a, springConstant, restLength);
        springOnA.elasticLimit = elasticLimit;
        springOnB.elasticLimit = elasticLimit;
        springOnB.visible = false;

        registerForce(a, springOnA);
        registerForce(b, springOnB);

        cable = new Cable(a, b, elasticLimit);
        cable.visible = false; 
        cables.add(cable);
    }

    float length() { return a.getPosition().distanceTo(b.getPosition()); }

    boolean isTaut() { return length() >= cable.maxLength - 1e-3f; }

    boolean involves(Particle p) { return p == a || p == b; }

    void breakLink() {
        if (broken) return;
        unregisterForce(a, springOnA);
        unregisterForce(b, springOnB);
        cables.remove(cable);
        broken = true;
    }
}

ParticleSpring[] connectWithSpring(Particle a, Particle b, float springConstant, float restLength) {
    ParticleSpring onA = new ParticleSpring(b, springConstant, restLength);
    ParticleSpring onB = new ParticleSpring(a, springConstant, restLength);
    onB.visible = false;
    registerForce(a, onA);
    registerForce(b, onB);
    return new ParticleSpring[] { onA, onB };
}

/////////////////////
// Rendu des ressorts
/////////////////////

void drawSpringCoil(Point3D from, Point3D to, float restLength, float limitLength) {
    Vector3D axis = to.sub(from);
    float length = axis.length();
    if (length < 1e-4f) return;
    Vector3D dir = axis.mult(1.0f / length);

    Vector3D helper = (Math.abs(dir.getY()) < 0.9f) ? new Vector3D(0, 1, 0) : new Vector3D(1, 0, 0);
    Vector3D u = dir.cross(helper).normalized();
    Vector3D w = dir.cross(u);

    float range = Math.max(limitLength - restLength, 1e-4f);
    float stretch = constrain((length - restLength) / range, 0.0f, 1.0f);
    int r = (int)(60 + 195 * stretch);
    int g = (int)(220 - 170 * stretch);

    float coilRadius = 0.18f;
    int turns = 8;
    int segments = turns * 8;

    stroke(r, g, 70);
    strokeWeight(2.0f);
    noFill();
    beginShape();
    for (int i = 0; i <= segments; i++) {
        float t = (float)i / segments;
        float rad = (t < 0.08f || t > 0.92f) ? 0.0f : coilRadius;
        float angle = t * turns * TWO_PI;
        Vector3D offset = u.mult(rad * (float)Math.cos(angle)).add(w.mult(rad * (float)Math.sin(angle)));
        Point3D pt = from.add(axis.mult(t)).add(offset);
        vertex(pt.getX(), pt.getY(), pt.getZ());
    }
    endShape();
    noStroke();
}

void drawBungeeLine(Point3D from, Point3D to, float restLength) {
    boolean taut = from.distanceTo(to) > restLength;
    if (taut) {
        stroke(230, 120, 40);
        strokeWeight(3.0f);
    } else {
        stroke(230, 180, 140, 140);
        strokeWeight(1.5f);
    }
    line(from.getX(), from.getY(), from.getZ(), to.getX(), to.getY(), to.getZ());
    noStroke();
}

void drawAnchor(Point3D anchor) {
    pushMatrix();
    translate(anchor.getX(), anchor.getY(), anchor.getZ());
    noStroke();
    fill(90);
    box(0.4f);
    popMatrix();
}
