/////////////////////
// Générateurs de forces : interface + registre (chap. 5, section C)
/////////////////////
 
 
interface ParticleForceGenerator {
    void updateForce(Particle particle, float duration);
}

class ParticleForceRegistry {

    class ParticleForceRegistration {
        Particle particle;
        ParticleForceGenerator fg;

        ParticleForceRegistration(Particle particle, ParticleForceGenerator fg) {
            this.particle = particle;
            this.fg = fg;
        }
    }


    
    private ArrayList<ParticleForceRegistration> registre = new ArrayList<ParticleForceRegistration>();

    void add(Particle particle, ParticleForceGenerator fg) {
        registre.add(new ParticleForceRegistration(particle, fg));
    }

    void remove(Particle particle, ParticleForceGenerator fg) {
        Iterator<ParticleForceRegistration> it = registre.iterator();
        while (it.hasNext()) {
            ParticleForceRegistration r = it.next();
            if (r.particle == particle && r.fg == fg) {
                it.remove();
            }
        }
    }
    void clear() {
        registre.clear();
    }

    int size() {
        return registre.size();
    }

    void updateForces(float duration) {
        for (ParticleForceRegistration x : registre) {
            x.fg.updateForce(x.particle, duration);
        }
    }
}

/////////////////////
// Forces actives du jeu
/////////////////////

class ForceBinding {
    Particle particle;
    ParticleForceGenerator fg;

    ForceBinding(Particle particle, ParticleForceGenerator fg) {
        this.particle = particle;
        this.fg = fg;
    }
}

ArrayList<ForceBinding> activeForces = new ArrayList<ForceBinding>();

void registerForce(Particle particle, ParticleForceGenerator fg) {
    activeForces.add(new ForceBinding(particle, fg));
}

void unregisterForce(Particle particle, ParticleForceGenerator fg) {
    Iterator<ForceBinding> it = activeForces.iterator();
    while (it.hasNext()) {
        ForceBinding b = it.next();
        if (b.particle == particle && b.fg == fg) it.remove();
    }
}

void unregisterAllForces(Particle particle) {
    Iterator<ForceBinding> it = activeForces.iterator();
    while (it.hasNext()) {
        if (it.next().particle == particle) it.remove();
    }
}

void clearActiveForces() {
    activeForces.clear();
}

void applyForces(ParticleForceRegistry registry, float duration) {
    for (ForceBinding b : activeForces) {      // 1) ajouter les forces au registre
        registry.add(b.particle, b.fg);
    }
    registry.updateForces(duration);           // 2) updateForces()
    registry.clear();                          // 3) clear()
}

/////////////////////
// Affichage (hors cours, pour visualiser les ressorts)
/////////////////////
interface DrawableForceGenerator {
    void draw(Particle particle);
}

void drawActiveForces() {
    for (ForceBinding b : activeForces) {
        if (b.fg instanceof DrawableForceGenerator) {
            ((DrawableForceGenerator) b.fg).draw(b.particle);
        }
    }
}
