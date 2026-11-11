// ==========================================
// Matrix4 : matrice 4x4 (coordonnées homogènes)
// ------------------------------------------
// Utilisée comme matrice de transformation d'un corps rigide :
// rotation (bloc 3x3 en haut à gauche) + translation (dernière colonne).
//
//   | r00 r01 r02 tx |
//   | r10 r11 r12 ty |
//   | r20 r21 r22 tz |
//   |  0   0   0   1 |
//
// Convention : stockage ligne par ligne (row-major), vecteurs colonnes (M * v),
// identique à PMatrix3D de Processing.
// Point3D  -> w = 1 (la translation s'applique)
// Vector3D -> w = 0 (seule la rotation s'applique)
// ==========================================

class Matrix4 {
    private float[] m_data = new float[16];

    // Matrice identité par défaut
    public Matrix4() {
        setIdentity();
    }

    public Matrix4(float m00, float m01, float m02, float m03,
                   float m10, float m11, float m12, float m13,
                   float m20, float m21, float m22, float m23,
                   float m30, float m31, float m32, float m33) {
        m_data[0]  = m00; m_data[1]  = m01; m_data[2]  = m02; m_data[3]  = m03;
        m_data[4]  = m10; m_data[5]  = m11; m_data[6]  = m12; m_data[7]  = m13;
        m_data[8]  = m20; m_data[9]  = m21; m_data[10] = m22; m_data[11] = m23;
        m_data[12] = m30; m_data[13] = m31; m_data[14] = m32; m_data[15] = m33;
    }

    public Matrix4(Matrix4 other) {
        System.arraycopy(other.m_data, 0, m_data, 0, 16);
    }

    // Matrice de transformation d'un corps : orientation + position
    public Matrix4(Quaternion orientation, Point3D position) {
        setOrientationAndPosition(orientation, position);
    }

    // --- Accès aux éléments ---

    float get(int row, int col) {
        checkIndex(row, col);
        return m_data[row * 4 + col];
    }

    void set(int row, int col, float value) {
        checkIndex(row, col);
        m_data[row * 4 + col] = value;
    }

    private void checkIndex(int row, int col) {
        if (row < 0 || row > 3 || col < 0 || col > 3) {
            throw new IndexOutOfBoundsException("Matrix4 index out of range: (" + row + ", " + col + ")");
        }
    }

    // Colonne i (trois premières composantes) :
    //  i = 0, 1, 2 -> axes X, Y, Z locaux du corps exprimés dans le monde
    //  i = 3       -> translation (position du centre de masse)
    // Pratique pour dessiner les axes du corps et rendre la rotation visible.
    Vector3D getAxis(int col) {
        checkIndex(0, col);
        return new Vector3D(m_data[col], m_data[4 + col], m_data[8 + col]);
    }

    Point3D getPosition() {
        return new Point3D(m_data[3], m_data[7], m_data[11]);
    }

    // Bloc de rotation 3x3
    Matrix3 getRotation() {
        return new Matrix3(
            m_data[0], m_data[1], m_data[2],
            m_data[4], m_data[5], m_data[6],
            m_data[8], m_data[9], m_data[10]
        );
    }

    // --- Initialisations ---

    void setIdentity() {
        for (int i = 0; i < 16; i++) m_data[i] = 0.0f;
        m_data[0] = 1.0f;
        m_data[5] = 1.0f;
        m_data[10] = 1.0f;
        m_data[15] = 1.0f;
    }

    // Construit la matrice de transformation d'un corps rigide
    void setOrientationAndPosition(Quaternion orientation, Point3D position) {
        Matrix3 r = new Matrix3(orientation);
        m_data[0]  = r.get(0, 0); m_data[1]  = r.get(0, 1); m_data[2]  = r.get(0, 2); m_data[3]  = position.getX();
        m_data[4]  = r.get(1, 0); m_data[5]  = r.get(1, 1); m_data[6]  = r.get(1, 2); m_data[7]  = position.getY();
        m_data[8]  = r.get(2, 0); m_data[9]  = r.get(2, 1); m_data[10] = r.get(2, 2); m_data[11] = position.getZ();
        m_data[12] = 0.0f;        m_data[13] = 0.0f;        m_data[14] = 0.0f;        m_data[15] = 1.0f;
    }

    // --- Opérations ---

    // Produit matriciel : this * other
    Matrix4 mult(Matrix4 other) {
        Matrix4 result = new Matrix4();
        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 4; col++) {
                float sum = 0.0f;
                for (int k = 0; k < 4; k++) {
                    sum += m_data[row * 4 + k] * other.m_data[k * 4 + col];
                }
                result.m_data[row * 4 + col] = sum;
            }
        }
        return result;
    }

    Matrix4 mult(float scalar) {
        Matrix4 result = new Matrix4();
        for (int i = 0; i < 16; i++) result.m_data[i] = m_data[i] * scalar;
        return result;
    }

    // Transforme un point (w = 1) : rotation + translation.
    // Si la matrice n'est pas affine (w' != 1), on divise par w'.
    Point3D transform(Point3D p) {
        float x = p.getX(), y = p.getY(), z = p.getZ();
        float rx = m_data[0]  * x + m_data[1]  * y + m_data[2]  * z + m_data[3];
        float ry = m_data[4]  * x + m_data[5]  * y + m_data[6]  * z + m_data[7];
        float rz = m_data[8]  * x + m_data[9]  * y + m_data[10] * z + m_data[11];
        float rw = m_data[12] * x + m_data[13] * y + m_data[14] * z + m_data[15];
        if (rw == 0.0f) {
            throw new IllegalArgumentException("Matrix4 transform: homogeneous w = 0, point at infinity");
        }
        if (rw != 1.0f) {
            return new Point3D(rx / rw, ry / rw, rz / rw);
        }
        return new Point3D(rx, ry, rz);
    }

    // Transforme une direction (w = 0) : rotation seulement, pas de translation
    Vector3D transformDirection(Vector3D v) {
        float x = v.getX(), y = v.getY(), z = v.getZ();
        return new Vector3D(
            m_data[0] * x + m_data[1] * y + m_data[2]  * z,
            m_data[4] * x + m_data[5] * y + m_data[6]  * z,
            m_data[8] * x + m_data[9] * y + m_data[10] * z
        );
    }

    // Transformation inverse d'un point : monde -> local.
    // Suppose une transformation rigide (rotation + translation) : p_local = R^T * (p - t).
    // Utile pour exprimer un point d'application de force dans le repère du corps.
    Point3D transformInverse(Point3D p) {
        float x = p.getX() - m_data[3];
        float y = p.getY() - m_data[7];
        float z = p.getZ() - m_data[11];
        return new Point3D(
            m_data[0] * x + m_data[4] * y + m_data[8]  * z,
            m_data[1] * x + m_data[5] * y + m_data[9]  * z,
            m_data[2] * x + m_data[6] * y + m_data[10] * z
        );
    }

    // Transformation inverse d'une direction : monde -> local (R^T * v).
    // Suppose une transformation rigide (bloc 3x3 orthonormé).
    Vector3D transformInverseDirection(Vector3D v) {
        float x = v.getX(), y = v.getY(), z = v.getZ();
        return new Vector3D(
            m_data[0] * x + m_data[4] * y + m_data[8]  * z,
            m_data[1] * x + m_data[5] * y + m_data[9]  * z,
            m_data[2] * x + m_data[6] * y + m_data[10] * z
        );
    }

    Matrix4 transpose() {
        Matrix4 result = new Matrix4();
        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 4; col++) {
                result.m_data[col * 4 + row] = m_data[row * 4 + col];
            }
        }
        return result;
    }

    // Déterminant 4x4 (développement par mineurs 2x2)
    float determinant() {
        float[] m = m_data;
        float s0 = m[0] * m[5] - m[4] * m[1];
        float s1 = m[0] * m[6] - m[4] * m[2];
        float s2 = m[0] * m[7] - m[4] * m[3];
        float s3 = m[1] * m[6] - m[5] * m[2];
        float s4 = m[1] * m[7] - m[5] * m[3];
        float s5 = m[2] * m[7] - m[6] * m[3];

        float c5 = m[10] * m[15] - m[14] * m[11];
        float c4 = m[9]  * m[15] - m[13] * m[11];
        float c3 = m[9]  * m[14] - m[13] * m[10];
        float c2 = m[8]  * m[15] - m[12] * m[11];
        float c1 = m[8]  * m[14] - m[12] * m[10];
        float c0 = m[8]  * m[13] - m[12] * m[9];

        return s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
    }

    // Inverse générale 4x4 par la comatrice (mêmes mineurs 2x2 que le déterminant)
    Matrix4 inverse() {
        float[] m = m_data;
        float s0 = m[0] * m[5] - m[4] * m[1];
        float s1 = m[0] * m[6] - m[4] * m[2];
        float s2 = m[0] * m[7] - m[4] * m[3];
        float s3 = m[1] * m[6] - m[5] * m[2];
        float s4 = m[1] * m[7] - m[5] * m[3];
        float s5 = m[2] * m[7] - m[6] * m[3];

        float c5 = m[10] * m[15] - m[14] * m[11];
        float c4 = m[9]  * m[15] - m[13] * m[11];
        float c3 = m[9]  * m[14] - m[13] * m[10];
        float c2 = m[8]  * m[15] - m[12] * m[11];
        float c1 = m[8]  * m[14] - m[12] * m[10];
        float c0 = m[8]  * m[13] - m[12] * m[9];

        float det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
        if (Math.abs(det) < 1e-12f) {
            throw new IllegalArgumentException("Matrix4 is singular (determinant = 0), cannot invert");
        }
        float inv = 1.0f / det;

        return new Matrix4(
            ( m[5]  * c5 - m[6]  * c4 + m[7]  * c3) * inv,
            (-m[1]  * c5 + m[2]  * c4 - m[3]  * c3) * inv,
            ( m[13] * s5 - m[14] * s4 + m[15] * s3) * inv,
            (-m[9]  * s5 + m[10] * s4 - m[11] * s3) * inv,

            (-m[4]  * c5 + m[6]  * c2 - m[7]  * c1) * inv,
            ( m[0]  * c5 - m[2]  * c2 + m[3]  * c1) * inv,
            (-m[12] * s5 + m[14] * s2 - m[15] * s1) * inv,
            ( m[8]  * s5 - m[10] * s2 + m[11] * s1) * inv,

            ( m[4]  * c4 - m[5]  * c2 + m[7]  * c0) * inv,
            (-m[0]  * c4 + m[1]  * c2 - m[3]  * c0) * inv,
            ( m[12] * s4 - m[13] * s2 + m[15] * s0) * inv,
            (-m[8]  * s4 + m[9]  * s2 - m[11] * s0) * inv,

            (-m[4]  * c3 + m[5]  * c1 - m[6]  * c0) * inv,
            ( m[0]  * c3 - m[1]  * c1 + m[2]  * c0) * inv,
            (-m[12] * s3 + m[13] * s1 - m[14] * s0) * inv,
            ( m[8]  * s3 - m[9]  * s1 + m[10] * s0) * inv
        );
    }

    // Conversion vers la matrice de Processing, pour le rendu :
    //   pushMatrix(); applyMatrix(corps.getTransform().toPMatrix3D()); box(...); popMatrix();
    PMatrix3D toPMatrix3D() {
        return new PMatrix3D(
            m_data[0],  m_data[1],  m_data[2],  m_data[3],
            m_data[4],  m_data[5],  m_data[6],  m_data[7],
            m_data[8],  m_data[9],  m_data[10], m_data[11],
            m_data[12], m_data[13], m_data[14], m_data[15]
        );
    }

    boolean equals(Matrix4 other) {
        for (int i = 0; i < 16; i++) {
            if (!MathHelpers.equalComponents(m_data[i], other.m_data[i])) return false;
        }
        return true;
    }

    public String toString() {
        String s = "Matrix4(";
        for (int row = 0; row < 4; row++) {
            s += "[" + m_data[row * 4] + ", " + m_data[row * 4 + 1] + ", "
               + m_data[row * 4 + 2] + ", " + m_data[row * 4 + 3] + "]";
            if (row < 3) s += ", ";
        }
        return s + ")";
    }
}
