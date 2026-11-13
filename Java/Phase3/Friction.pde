// ==========================================
// Forces de friction
// ==========================================
// Deux phénomènes physiques différents, donc deux générateurs :
//
//  1. ContactFrictionGenerator : friction SÈCHE (loi de Coulomb) entre deux particules en contact.
//       - UN SEUL générateur générique : aucun setup par particule.
//       - Les contacts viennent du système de collisions (resolveCollisionsAndConstraints) :
//         ce fichier ne détecte rien et ne recalcule ni distance ni normale.
//       - Les coefficients viennent de la table PhysicsMaterials (Materials.pde),
//         selon le matériau des DEUX particules en contact.
//       - Comme les forces de collision, la friction est ajoutée à l'accumulateur des particules
//         (elle est donc appliquée à la prochaine intégration).
//
//  2. DragForceGenerator : friction FLUIDE (air, eau). Elle ne dépend pas d'un contact mais
//     de la vitesse : f = -v^ * (k1*|v| + k2*|v|^2). C'est un ForceGenerator classique,
//     enregistré dans le ForceRegistry.

// Seuil. Si la vitesse est inférieure, elle est considérée comme nulle.
final float FRICTION_EPSILON = 1e-6f;

// ==========================================
// 1. FRICTION DE CONTACT (Coulomb)
// ==========================================

// Interface des générateurs qui réagissent à un contact détecté par le système de collisions.
interface ContactGenerator {
    // p1, p2       : les deux particules en contact
    // normal       : normale unitaire du contact, orientée de p1 vers p2
    // normalForce  : intensité (>= 0) de la force normale que le résolveur vient d'ajouter
    // dt           : pas de temps de la simulation
    void applyContact(Particle p1, Particle p2, Vector3D normal, float normalForce, float dt);
}

enum ContactState {
    Airborne, // aucun contact avec friction ce pas
    Static,   // contact, la particule "colle"
    Sliding   // contact, la particule glisse
}

// Loi de Coulomb :
//     N = force normale (ce que le contact retient)
//     statique  : |F_f| <= mu_s * N   (la friction annule exactement le glissement)
//     cinétique : |F_f|  = mu_k * N   (opposée au glissement)
//   avec mu_k <= mu_s, lus dans PhysicsMaterials pour la paire de matériaux.
//
// COMMENT ON CHOISIT statique / cinétique : on calcule la force qui arrêterait le glissement
// EXACTEMENT en un pas, pour deux particules de masses inverses invM1 et invM2 :
//     F_stop = |v_t| / (dt * (invM1 + invM2))       (v_t : vitesse relative tangentielle)
//   - si F_stop <= mu_s * N : le contact "tient" -> friction = F_stop (le glissement s'arrête net)
//   - sinon                 : ça glisse -> friction = mu_k * N, opposée au glissement.
// Dans le 2e cas, mu_k * N <= mu_s * N < F_stop : la friction ne peut jamais inverser le glissement
// (pas de tremblement à basse vitesse).
//
// Bonus : N est plus grande lors d'un rebond que lors d'un contact au repos, donc une balle qui
// rebondit perd aussi de la vitesse horizontale pendant l'impact.
//
// LIMITE : la friction est calculée au moment de la collision, donc elle ne "voit" pas les forces
// que les autres générateurs ajouteront au prochain pas (ressort, poussée...). Un objet posé et
// poussé sous le seuil statique n'est donc pas parfaitement immobile : il avance à très faible
// vitesse (au plus mu_s * g * dt, environ 10 cm/s) au lieu de rester à l'arrêt.
class ContactFrictionGenerator implements ContactGenerator {
    private boolean m_enabled = true;
    private HashMap<Particle, ContactState> m_states = new HashMap<Particle, ContactState>();

    boolean isEnabled() { return m_enabled; }
    void setEnabled(boolean enabled) { m_enabled = enabled; }

    // À appeler au début de chaque pas de résolution des collisions (remet les états à zéro).
    void beginStep() {
        m_states.clear();
    }

    // État de contact d'une particule pendant le dernier pas (pour le HUD).
    ContactState getState(Particle p) {
        ContactState state = m_states.get(p);
        return (state != null) ? state : ContactState.Airborne;
    }

    public void applyContact(Particle p1, Particle p2, Vector3D n, float normalForce, float dt) {
        if (!m_enabled) return;
        if (normalForce <= 0.0f) return; // rien ne presse les particules l'une sur l'autre

        float invM1 = p1.getInverseMass();
        float invM2 = p2.getInverseMass();
        float totalInvMass = invM1 + invM2;
        if (totalInvMass <= 0.0f) return; // deux masses infinies : rien ne peut bouger

        // 1. Coefficients de la table, selon les matériaux des deux particules
        MaterialInteraction material = PhysicsMaterials.get(p1.getMaterial(), p2.getMaterial());
        float staticCoeff = material.staticFriction;
        float kineticCoeff = Math.min(material.kineticFriction, staticCoeff); // mu_k <= mu_s

        // 2. Vitesse relative tangentielle : v_t = v_rel - (v_rel . n) n
        Vector3D vRel = p1.getVelocity().sub(p2.getVelocity());
        Vector3D vTangent = vRel.sub(n.mult(vRel.dot(n)));
        float slideSpeed = vTangent.length();
        if (slideSpeed < FRICTION_EPSILON) {
            recordState(p1, p2, ContactState.Static);
            return;
        }
        // Direction dans laquelle p1 glisse par rapport à p2
        Vector3D t = vTangent.mult(1.0f / slideSpeed);

        // 3. Statique ou cinétique ?
        float stopForce = slideSpeed / (dt * totalInvMass);
        float maxStaticForce = staticCoeff * normalForce;
        float frictionForce;
        if (stopForce <= maxStaticForce) {
            frictionForce = stopForce;
            recordState(p1, p2, ContactState.Static);
        } else {
            frictionForce = kineticCoeff * normalForce;
            recordState(p1, p2, ContactState.Sliding);
        }

        // 4. Application à l'accumulateur (même convention de signes que la force normale du résolveur)
        Vector3D friction = t.mult(frictionForce);
        p1.addForce(friction.negate());
        p2.addForce(friction);
    }

    // Une particule peut avoir plusieurs contacts : "Sliding" l'emporte sur "Static".
    private void recordState(Particle p1, Particle p2, ContactState state) {
        if (p1.getInverseMass() > 0.0f) mergeState(p1, state);
        if (p2.getInverseMass() > 0.0f) mergeState(p2, state);
    }

    private void mergeState(Particle p, ContactState state) {
        if (m_states.get(p) != ContactState.Sliding) {
            m_states.put(p, state);
        }
    }
}

// ==========================================
// 2. FRICTION FLUIDE (traînée / drag)
// ==========================================
// Modèle à deux coefficients (Millington) :
//     f_drag = -v^ * ( k1 * |v|  +  k2 * |v|^2 )
//   - k1 : terme linéaire    (écoulement laminaire, faibles vitesses)
//   - k2 : terme quadratique (écoulement turbulent, hautes vitesses)
//   - v^ : direction de la vitesse (donc la force s'y oppose toujours)
class DragForceGenerator implements ForceGenerator {
    private float m_k1;
    private float m_k2;
    private boolean m_enabled = true;

    public DragForceGenerator(float k1, float k2) {
        m_k1 = k1;
        m_k2 = k2;
    }

    float getK1() { return m_k1; }
    float getK2() { return m_k2; }
    boolean isEnabled() { return m_enabled; }
    void setEnabled(boolean enabled) { m_enabled = enabled; }

    @Override
    public void updateForce(Particle p, float dt) {
        if (!m_enabled) return;
        if (p.getInverseMass() <= 0.0f) return; // masse infinie : ne bouge pas

        Vector3D v = p.getVelocity();
        float speed = v.length();
        if (speed < FRICTION_EPSILON) return; // pas de direction définie à l'arrêt

        float dragMagnitude = m_k1 * speed + m_k2 * speed * speed;

        // GARDE-FOU DE STABILITÉ :
        // Avec une intégration explicite, une traînée trop forte pourrait inverser la vitesse
        // en un seul pas. La friction ne peut que freiner, jamais propulser.
        // La force maximale qui arrête exactement la particule en un pas est F_max = m * |v| / dt
        float maxMagnitude = p.getMass() * speed / dt;
        dragMagnitude = Math.min(dragMagnitude, maxMagnitude);

        // f = -v^ * magnitude = v * (-magnitude / |v|)
        p.addForce(v.mult(-dragMagnitude / speed));
    }
}
