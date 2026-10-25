// Deux modeles : 
//
//  1. DragForceGenerator : friction FLUIDE (air, eau). Depend de la vitesse.
//                          f = -v^ * (k1*|v| + k2*|v|^2)
//
//  2. CoulombFrictionGenerator : friction SECHE entre la particule et une surface.
//                                Depend de la force normale N (pas de la vitesse).
//                                   - statique : |F_f| <= mu_s * N  (l'objet "colle")
//                                   - cinetique: |F_f| =  mu_k * N  (l'objet glisse)
//
// Les deux sont des ForceGenerator : ils ajoutent simplement leur force a
// l'accumulateur de la particule. Ils ne touchent pas a la position ou a la vitesse.

// Seuil. Si la vitesse est inferieure, elle est consideree comme nulle.
final float FRICTION_EPSILON = 1e-6f;

// Epaisseur (en m) de la "peau de contact" : si l'ecart entre la particule et la
// surface est inferieur a cette valeur, on considere qu'ils se touchent.
final float FRICTION_CONTACT_TOLERANCE = 0.1f;

// Permet d'activer / desactiver un generateur (touche [F])
abstract class FrictionGenerator implements ForceGenerator {
    private boolean m_enabled = true;

    boolean isEnabled() { return m_enabled; }
    void setEnabled(boolean enabled) { m_enabled = enabled; }

    @Override
    public void updateForce(Particle p, float dt) {
        if (!m_enabled) return;
        if (p.getInverseMass() <= 0.0f) return;
        applyFriction(p, dt);
    }

    protected abstract void applyFriction(Particle p, float dt);
}

// 1. FRICTION FLUIDE (trainee / drag)
// Millington :
//     f_drag = -v^ * ( k1 * |v|  +  k2 * |v|^2 )
class DragForceGenerator extends FrictionGenerator {
    private float m_k1;
    private float m_k2;

    public DragForceGenerator(float k1, float k2) {
        m_k1 = k1;
        m_k2 = k2;
    }

    float getK1() { return m_k1; }
    float getK2() { return m_k2; }

    @Override
    protected void applyFriction(Particle p, float dt) {
        Vector3D v = p.getVelocity();
        float speed = v.length();
        if (speed < FRICTION_EPSILON) return; 

        float dragMagnitude = m_k1 * speed + m_k2 * speed * speed;

        float maxMagnitude = p.getMass() * speed / dt;
        dragMagnitude = Math.min(dragMagnitude, maxMagnitude);

        p.addForce(v.mult(-dragMagnitude / speed));
    }
}

// Surfaces de contact (pour la friction de Coulomb)
interface ContactSurface {
    // Retourne la normale UNITAIRE de la surface (orientee vers la particule)
    // si la particule est en contact (ecart <= tolerance), sinon null.
    Vector3D getContactNormal(Particle p, float tolerance);
}

// Surface spherique
class SphericalSurface implements ContactSurface {
    private Particle m_body;

    public SphericalSurface(Particle body) {
        m_body = body;
    }

    @Override
    public Vector3D getContactNormal(Particle p, float tolerance) {
        double dx = (double)p.getPosition().getX() - (double)m_body.getPosition().getX();
        double dy = (double)p.getPosition().getY() - (double)m_body.getPosition().getY();
        double dz = (double)p.getPosition().getZ() - (double)m_body.getPosition().getZ();
        double dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (dist < 1e-9) return null;

        double gap = dist - (double)m_body.getRadius() - (double)p.getRadius();
        if (gap > (double)tolerance) return null;

        return new Vector3D((float)(dx / dist), (float)(dy / dist), (float)(dz / dist));
    }
}

// Surface plane infinie
class PlaneSurface implements ContactSurface {
    private Point3D m_point;
    private Vector3D m_normal;

    public PlaneSurface(Point3D point, Vector3D normal) {
        m_point = point;
        m_normal = normal.normalized();
    }

    @Override
    public Vector3D getContactNormal(Particle p, float tolerance) {
        float gap = p.getPosition().sub(m_point).dot(m_normal) - p.getRadius();
        if (gap > tolerance) return null;
        return m_normal;
    }
}

// 2. FRICTION DE COULOMB (statique + cinetique)
enum ContactState {
    Airborne, // pas de contact : aucune friction seche
    Static,   // contact, la particule "colle"
    Sliding   // contact, la particule glisse
}

class CoulombFrictionGenerator extends FrictionGenerator {
    private ContactSurface m_surface;
    private float m_staticCoeff;   // mu_s
    private float m_kineticCoeff;  // mu_k
    private float m_contactTolerance = FRICTION_CONTACT_TOLERANCE;
    private ContactState m_state = ContactState.Airborne;

    public CoulombFrictionGenerator(ContactSurface surface, float staticCoeff, float kineticCoeff) {
        m_surface = surface;
        m_staticCoeff = staticCoeff;
        m_kineticCoeff = Math.min(kineticCoeff, staticCoeff);
    }

    ContactState getState() { return m_state; }
    float getStaticCoeff() { return m_staticCoeff; }
    float getKineticCoeff() { return m_kineticCoeff; }
    void setContactTolerance(float tolerance) { m_contactTolerance = tolerance; }

    @Override
    protected void applyFriction(Particle p, float dt) {
        // 1. Y a-t-il contact ?
        Vector3D n = m_surface.getContactNormal(p, m_contactTolerance);
        if (n == null) {
            m_state = ContactState.Airborne;
            return;
        }

        // 2. Force normale N : la partie de la force appliquee qui PRESSE la particule contre la surface.
        Vector3D applied = p.getAppliedForce();
        float appliedAlongNormal = applied.dot(n);
        float normalForce = Math.max(0.0f, -appliedAlongNormal);
        if (normalForce <= 0.0f) {
            // La particule est tiree/poussee hors de la surface : rien ne la
            // retient, donc pas de friction.
            m_state = ContactState.Airborne;
            return;
        }

        // 3. Decomposition tangentielle
        Vector3D v = p.getVelocity();
        Vector3D velocityTangent = v.sub(n.mult(v.dot(n)));
        Vector3D appliedTangent = applied.sub(n.mult(appliedAlongNormal));

        // 4. Force qui arreterait la particule exactement sur ce pas
        Vector3D stopForce = velocityTangent.mult(p.getMass() / dt).add(appliedTangent);
        float stopMagnitude = stopForce.length();
        float maxStatic = m_staticCoeff * normalForce;

        if (stopMagnitude <= maxStatic) {
            // --- FRICTION STATIQUE : la surface tient la particule ---
            m_state = ContactState.Static;
            p.addForce(stopForce.negate());
        } else {
            // --- FRICTION CINETIQUE : la particule glisse ---
            m_state = ContactState.Sliding;

            // La friction s'oppose au glissement.
            Vector3D slideDirection = (velocityTangent.length() > 1e-4f)
                ? velocityTangent.normalized()
                : appliedTangent.normalized();

            p.addForce(slideDirection.mult(-m_kineticCoeff * normalForce));
        }
    }
}
