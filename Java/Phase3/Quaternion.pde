// ==========================================
// Quaternion : q = w + x*i + y*j + z*k
// ------------------------------------------
// Représente l'orientation d'un corps rigide.
// Un quaternion unitaire q = (cos(θ/2), sin(θ/2) * axe) code une rotation
// d'angle θ autour d'un axe normalisé. Avantages par rapport aux angles d'Euler :
// pas de blocage de cardan (gimbal lock), composition simple, intégration facile.
// ==========================================

class Quaternion {
    private float m_w, m_x, m_y, m_z;

    // Quaternion identité (aucune rotation)
    public Quaternion() {
        m_w = 1; m_x = 0; m_y = 0; m_z = 0;
    }

    public Quaternion(float w, float x, float y, float z) {
        m_w = w; m_x = x; m_y = y; m_z = z;
    }

    public Quaternion(Quaternion other) {
        m_w = other.m_w; m_x = other.m_x; m_y = other.m_y; m_z = other.m_z;
    }

    // Rotation d'angle "angle" (radians) autour de "axis" (normalisé automatiquement)
    public Quaternion(Vector3D axis, float angle) {
        setFromAxisAngle(axis, angle);
    }

    // --- Accesseurs ---

    float getW() { return m_w; }
    float getX() { return m_x; }
    float getY() { return m_y; }
    float getZ() { return m_z; }

    void setW(float w) { m_w = w; }
    void setX(float x) { m_x = x; }
    void setY(float y) { m_y = y; }
    void setZ(float z) { m_z = z; }

    void set(float w, float x, float y, float z) {
        m_w = w; m_x = x; m_y = y; m_z = z;
    }

    void setFromAxisAngle(Vector3D axis, float angle) {
        Vector3D n = axis.normalized();
        if (n.lengthSquared() == 0.0f) {
            throw new IllegalArgumentException("Quaternion axis-angle: axis must not be the zero vector");
        }
        float half = angle * 0.5f;
        float s = (float)Math.sin(half);
        m_w = (float)Math.cos(half);
        m_x = n.getX() * s;
        m_y = n.getY() * s;
        m_z = n.getZ() * s;
    }

    // --- Norme ---

    float lengthSquared() {
        return m_w * m_w + m_x * m_x + m_y * m_y + m_z * m_z;
    }

    float length() {
        return (float)Math.sqrt(lengthSquared());
    }

    // Normalise en place et retourne l'ancienne norme.
    // Un quaternion nul devient l'identité (évite une orientation invalide).
    float normalize() {
        float len = length();
        if (len > 0.0f) {
            m_w /= len; m_x /= len; m_y /= len; m_z /= len;
        } else {
            m_w = 1; m_x = 0; m_y = 0; m_z = 0;
        }
        return len;
    }

    Quaternion normalized() {
        Quaternion q = new Quaternion(this);
        q.normalize();
        return q;
    }

    // --- Opérations ---

    float dot(Quaternion other) {
        return m_w * other.m_w + m_x * other.m_x + m_y * other.m_y + m_z * other.m_z;
    }

    // Conjugué : (w, -x, -y, -z). Pour un quaternion unitaire, c'est aussi l'inverse.
    Quaternion conjugate() {
        return new Quaternion(m_w, -m_x, -m_y, -m_z);
    }

    // Inverse : conjugué / |q|²
    Quaternion inverse() {
        float lenSq = lengthSquared();
        if (lenSq == 0.0f) {
            throw new IllegalArgumentException("Quaternion inverse: zero quaternion cannot be inverted");
        }
        return new Quaternion(m_w / lenSq, -m_x / lenSq, -m_y / lenSq, -m_z / lenSq);
    }

    Quaternion negate() {
        return new Quaternion(-m_w, -m_x, -m_y, -m_z);
    }

    Quaternion add(Quaternion other) {
        return new Quaternion(m_w + other.m_w, m_x + other.m_x, m_y + other.m_y, m_z + other.m_z);
    }

    Quaternion mult(float scalar) {
        return new Quaternion(m_w * scalar, m_x * scalar, m_y * scalar, m_z * scalar);
    }

    // Produit de Hamilton : this * other (non commutatif).
    // Compose les rotations : appliquer "other" d'abord, puis "this".
    Quaternion mult(Quaternion other) {
        float w1 = m_w, x1 = m_x, y1 = m_y, z1 = m_z;
        float w2 = other.m_w, x2 = other.m_x, y2 = other.m_y, z2 = other.m_z;
        return new Quaternion(
            w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
            w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
            w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
            w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2
        );
    }

    // Fait tourner un vecteur : v' = q * (0, v) * q^-1
    Vector3D rotate(Vector3D v) {
        Quaternion p = new Quaternion(0.0f, v.getX(), v.getY(), v.getZ());
        Quaternion r = this.mult(p).mult(this.inverse());
        return new Vector3D(r.m_x, r.m_y, r.m_z);
    }

    // Intégration de l'orientation (en place) à partir de la vitesse angulaire ω (repère monde) :
    //   q <- q + (dt / 2) * (0, ω) * q
    // Le résultat n'est plus exactement unitaire : penser à appeler normalize() ensuite.
    void addScaledVector(Vector3D omega, float dt) {
        Quaternion w = new Quaternion(0.0f, omega.getX() * dt, omega.getY() * dt, omega.getZ() * dt);
        Quaternion dq = w.mult(this);
        m_w += dq.m_w * 0.5f;
        m_x += dq.m_x * 0.5f;
        m_y += dq.m_y * 0.5f;
        m_z += dq.m_z * 0.5f;
    }

    // --- Conversions ---

    // Angle de rotation θ dans [0, 2π]
    float getRotationAngle() {
        Quaternion q = normalized();
        float w = Math.max(-1.0f, Math.min(1.0f, q.m_w));
        return 2.0f * (float)Math.acos(w);
    }

    // Axe de rotation normalisé (axe X par défaut si la rotation est nulle)
    Vector3D getRotationAxis() {
        Quaternion q = normalized();
        float s = (float)Math.sqrt(Math.max(0.0f, 1.0f - q.m_w * q.m_w));
        if (s < 1e-6f) {
            return new Vector3D(1.0f, 0.0f, 0.0f);
        }
        return new Vector3D(q.m_x / s, q.m_y / s, q.m_z / s);
    }

    Matrix3 toMatrix3() {
        return new Matrix3(this);
    }

    // Matrice 4x4 de rotation pure (sans translation)
    Matrix4 toMatrix4() {
        return new Matrix4(this, new Point3D());
    }

    // ------------------------------------------------------------------
    // BONUS — NON DEMANDÉ DANS LES CONSIGNES DE LA PHASE 3.
    // Ajouté comme piste de « dépassement des attentes » (ex. caméra fluide,
    // animation d'orientation). Peut être supprimé sans rien casser :
    // aucune autre méthode n'en dépend (seuls les tests "Quaternion slerp"
    // dans MathTests.pde l'utilisent, à retirer aussi dans ce cas).
    //
    // Interpolation sphérique (slerp) entre this (t = 0) et target (t = 1),
    // à vitesse angulaire constante, par le chemin le plus court.
    // ------------------------------------------------------------------
    Quaternion slerp(Quaternion target, float t) {
        Quaternion a = normalized();
        Quaternion b = target.normalized();
        float cosTheta = a.dot(b);

        // q et -q représentent la même rotation : on prend le chemin le plus court
        if (cosTheta < 0.0f) {
            b = b.negate();
            cosTheta = -cosTheta;
        }

        // Quaternions presque identiques : interpolation linéaire puis normalisation
        if (cosTheta > 0.9995f) {
            return a.add(b.add(a.negate()).mult(t)).normalized();
        }

        float theta = (float)Math.acos(cosTheta);
        float sinTheta = (float)Math.sin(theta);
        float wa = (float)Math.sin((1.0f - t) * theta) / sinTheta;
        float wb = (float)Math.sin(t * theta) / sinTheta;
        return a.mult(wa).add(b.mult(wb));
    }

    // --- Comparaisons ---

    // Égalité composante par composante
    boolean equals(Quaternion other) {
        return MathHelpers.equalComponents(m_w, other.m_w) &&
               MathHelpers.equalComponents(m_x, other.m_x) &&
               MathHelpers.equalComponents(m_y, other.m_y) &&
               MathHelpers.equalComponents(m_z, other.m_z);
    }

    // Même rotation : q et -q représentent la même orientation
    boolean sameRotation(Quaternion other) {
        Quaternion a = normalized();
        Quaternion b = other.normalized();
        return a.equals(b) || a.equals(b.negate());
    }

    public String toString() {
        return "Quaternion(" + m_w + ", " + m_x + ", " + m_y + ", " + m_z + ")";
    }
}
