// ==========================================
// Matrix3 : matrice 3x3
// ------------------------------------------
// Utilisée pour :
//  - les rotations (matrice d'orientation d'un corps rigide) ;
//  - le tenseur d'inertie (et son inverse) en coordonnées locales et monde.
//
// Convention : stockage ligne par ligne (row-major), vecteurs colonnes (M * v).
//   | m[0] m[1] m[2] |
//   | m[3] m[4] m[5] |
//   | m[6] m[7] m[8] |
// ==========================================

class Matrix3 {
    private float[] m_data = new float[9];

    // Matrice identité par défaut
    public Matrix3() {
        setIdentity();
    }

    public Matrix3(float m00, float m01, float m02,
                   float m10, float m11, float m12,
                   float m20, float m21, float m22) {
        m_data[0] = m00; m_data[1] = m01; m_data[2] = m02;
        m_data[3] = m10; m_data[4] = m11; m_data[5] = m12;
        m_data[6] = m20; m_data[7] = m21; m_data[8] = m22;
    }

    public Matrix3(Matrix3 other) {
        System.arraycopy(other.m_data, 0, m_data, 0, 9);
    }

    // Matrice de rotation correspondant à un quaternion
    public Matrix3(Quaternion q) {
        setOrientation(q);
    }

    // --- Accès aux éléments ---

    float get(int row, int col) {
        checkIndex(row, col);
        return m_data[row * 3 + col];
    }

    void set(int row, int col, float value) {
        checkIndex(row, col);
        m_data[row * 3 + col] = value;
    }

    // Colonne i (pour une matrice de rotation : l'axe local i exprimé dans le monde)
    Vector3D getColumn(int col) {
        checkIndex(0, col);
        return new Vector3D(m_data[col], m_data[3 + col], m_data[6 + col]);
    }

    Vector3D getRow(int row) {
        checkIndex(row, 0);
        return new Vector3D(m_data[row * 3], m_data[row * 3 + 1], m_data[row * 3 + 2]);
    }

    private void checkIndex(int row, int col) {
        if (row < 0 || row > 2 || col < 0 || col > 2) {
            throw new IndexOutOfBoundsException("Matrix3 index out of range: (" + row + ", " + col + ")");
        }
    }

    // --- Initialisations ---

    void setIdentity() {
        setDiagonal(1.0f, 1.0f, 1.0f);
    }

    void setDiagonal(float a, float b, float c) {
        for (int i = 0; i < 9; i++) m_data[i] = 0.0f;
        m_data[0] = a;
        m_data[4] = b;
        m_data[8] = c;
    }

    // Tenseur d'inertie à partir des moments (ix, iy, iz) et des produits d'inertie (ixy, ixz, iyz).
    // Les produits d'inertie apparaissent avec un signe négatif hors de la diagonale.
    void setInertiaTensorCoeffs(float ix, float iy, float iz, float ixy, float ixz, float iyz) {
        m_data[0] = ix;   m_data[1] = -ixy; m_data[2] = -ixz;
        m_data[3] = -ixy; m_data[4] = iy;   m_data[5] = -iyz;
        m_data[6] = -ixz; m_data[7] = -iyz; m_data[8] = iz;
    }

    // Tenseur d'inertie d'une boîte pleine (pavé droit) de masse m et de dimensions
    // complètes (largeur dx, hauteur dy, profondeur dz), centré sur son centre de masse :
    //   Ixx = m/12 (dy² + dz²), Iyy = m/12 (dx² + dz²), Izz = m/12 (dx² + dy²)
    void setCuboidInertiaTensor(float mass, float dx, float dy, float dz) {
        float k = mass / 12.0f;
        setDiagonal(k * (dy * dy + dz * dz),
                    k * (dx * dx + dz * dz),
                    k * (dx * dx + dy * dy));
    }

    // Matrice de rotation à partir d'un quaternion (normalisé au préalable par sécurité)
    void setOrientation(Quaternion quat) {
        Quaternion q = quat.normalized();
        float w = q.getW(), x = q.getX(), y = q.getY(), z = q.getZ();

        m_data[0] = 1.0f - 2.0f * (y * y + z * z);
        m_data[1] = 2.0f * (x * y - w * z);
        m_data[2] = 2.0f * (x * z + w * y);

        m_data[3] = 2.0f * (x * y + w * z);
        m_data[4] = 1.0f - 2.0f * (x * x + z * z);
        m_data[5] = 2.0f * (y * z - w * x);

        m_data[6] = 2.0f * (x * z - w * y);
        m_data[7] = 2.0f * (y * z + w * x);
        m_data[8] = 1.0f - 2.0f * (x * x + y * y);
    }

    // --- Opérations ---

    Matrix3 add(Matrix3 other) {
        Matrix3 result = new Matrix3();
        for (int i = 0; i < 9; i++) result.m_data[i] = m_data[i] + other.m_data[i];
        return result;
    }

    Matrix3 sub(Matrix3 other) {
        Matrix3 result = new Matrix3();
        for (int i = 0; i < 9; i++) result.m_data[i] = m_data[i] - other.m_data[i];
        return result;
    }

    Matrix3 mult(float scalar) {
        Matrix3 result = new Matrix3();
        for (int i = 0; i < 9; i++) result.m_data[i] = m_data[i] * scalar;
        return result;
    }

    // Produit matriciel : this * other
    Matrix3 mult(Matrix3 other) {
        Matrix3 result = new Matrix3();
        for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
                float sum = 0.0f;
                for (int k = 0; k < 3; k++) {
                    sum += m_data[row * 3 + k] * other.m_data[k * 3 + col];
                }
                result.m_data[row * 3 + col] = sum;
            }
        }
        return result;
    }

    // Produit matrice-vecteur : M * v
    Vector3D transform(Vector3D v) {
        float x = v.getX(), y = v.getY(), z = v.getZ();
        return new Vector3D(
            m_data[0] * x + m_data[1] * y + m_data[2] * z,
            m_data[3] * x + m_data[4] * y + m_data[5] * z,
            m_data[6] * x + m_data[7] * y + m_data[8] * z
        );
    }

    // Produit par la transposée : M^T * v
    // Pour une matrice de rotation, M^T = M^-1 : passage du repère monde au repère local.
    Vector3D transformTranspose(Vector3D v) {
        float x = v.getX(), y = v.getY(), z = v.getZ();
        return new Vector3D(
            m_data[0] * x + m_data[3] * y + m_data[6] * z,
            m_data[1] * x + m_data[4] * y + m_data[7] * z,
            m_data[2] * x + m_data[5] * y + m_data[8] * z
        );
    }

    Matrix3 transpose() {
        return new Matrix3(
            m_data[0], m_data[3], m_data[6],
            m_data[1], m_data[4], m_data[7],
            m_data[2], m_data[5], m_data[8]
        );
    }

    // Déterminant (règle de Sarrus / développement selon la première ligne)
    float determinant() {
        return m_data[0] * (m_data[4] * m_data[8] - m_data[5] * m_data[7])
             - m_data[1] * (m_data[3] * m_data[8] - m_data[5] * m_data[6])
             + m_data[2] * (m_data[3] * m_data[7] - m_data[4] * m_data[6]);
    }

    // Inverse par la comatrice : M^-1 = (1 / det) * adj(M)
    Matrix3 inverse() {
        float det = determinant();
        if (Math.abs(det) < 1e-12f) {
            throw new IllegalArgumentException("Matrix3 is singular (determinant = 0), cannot invert");
        }
        float invDet = 1.0f / det;
        return new Matrix3(
            (m_data[4] * m_data[8] - m_data[5] * m_data[7]) * invDet,
            (m_data[2] * m_data[7] - m_data[1] * m_data[8]) * invDet,
            (m_data[1] * m_data[5] - m_data[2] * m_data[4]) * invDet,

            (m_data[5] * m_data[6] - m_data[3] * m_data[8]) * invDet,
            (m_data[0] * m_data[8] - m_data[2] * m_data[6]) * invDet,
            (m_data[2] * m_data[3] - m_data[0] * m_data[5]) * invDet,

            (m_data[3] * m_data[7] - m_data[4] * m_data[6]) * invDet,
            (m_data[1] * m_data[6] - m_data[0] * m_data[7]) * invDet,
            (m_data[0] * m_data[4] - m_data[1] * m_data[3]) * invDet
        );
    }

    // Changement de base par une matrice de rotation R : R * M * R^T
    // Sert à exprimer le tenseur d'inertie (inverse) local dans le repère monde :
    //   I^-1_monde = R * I^-1_local * R^T
    Matrix3 changeBasis(Matrix3 rotation) {
        return rotation.mult(this).mult(rotation.transpose());
    }

    boolean equals(Matrix3 other) {
        for (int i = 0; i < 9; i++) {
            if (!MathHelpers.equalComponents(m_data[i], other.m_data[i])) return false;
        }
        return true;
    }

    public String toString() {
        return "Matrix3(["
            + m_data[0] + ", " + m_data[1] + ", " + m_data[2] + "], ["
            + m_data[3] + ", " + m_data[4] + ", " + m_data[5] + "], ["
            + m_data[6] + ", " + m_data[7] + ", " + m_data[8] + "])";
    }
}
