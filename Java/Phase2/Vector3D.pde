class Vector3D {
    private float m_x, m_y, m_z;

    public Vector3D() { m_x = 0; m_y = 0; m_z = 0; }
    
    public Vector3D(float x, float y, float z) {
        m_x = x; m_y = y; m_z = z;
    }

    public Vector3D(Polar polar) {
        setPolar(polar);
    }

    void setX(float x) { m_x = x; }
    void setY(float y) { m_y = y; }
    void setZ(float z) { m_z = z; }

    void setPolar(Polar polar) {
        float[] coords = new float[3];
        MathHelpers.polarToCartesian(polar, coords);
        m_x = coords[0];
        m_y = coords[1];
        m_z = coords[2];
    }

    void setPolar(float radius, float azimuth, float elevation) {
        setPolar(new Polar(radius, azimuth, elevation));
    }

    float getX() { return m_x; }
    float getY() { return m_y; }
    float getZ() { return m_z; }

    Polar getPolar() {
        return MathHelpers.cartesianToPolar(m_x, m_y, m_z);
    }

    float length() {
        return (float)Math.sqrt(m_x * m_x + m_y * m_y + m_z * m_z);
    }

    float lengthSquared() {
        return m_x * m_x + m_y * m_y + m_z * m_z;
    }

    float normalize() {
        float len = length();
        if (len > 0.0f) {
            m_x /= len;
            m_y /= len;
            m_z /= len;
        }
        return len;
    }

    Vector3D normalized() {
        float len = length();
        if (len > 0.0f) {
            return new Vector3D(m_x / len, m_y / len, m_z / len);
        }
        return new Vector3D(0, 0, 0);
    }

    float dot(Vector3D other) {
        return m_x * other.m_x + m_y * other.m_y + m_z * other.m_z;
    }

    Vector3D cross(Vector3D other) {
        return new Vector3D(
            m_y * other.m_z - m_z * other.m_y,
            m_z * other.m_x - m_x * other.m_z,
            m_x * other.m_y - m_y * other.m_x
        );
    }

    double angleTo(Vector3D other) {
        float denominator = length() * other.length();
        if (denominator == 0.0f) {
            return 0.0;
        }
        float cosine = constrain(dot(other) / denominator, -1.0f, 1.0f);
        return Math.acos(cosine);
    }

    Vector3D negate() {
        return new Vector3D(-m_x, -m_y, -m_z);
    }

    Vector3D mult(float scalar) {
        return new Vector3D(m_x * scalar, m_y * scalar, m_z * scalar);
    }

    Vector3D div(float scalar) {
        if (scalar == 0.0f) {
            throw new IllegalArgumentException("Division by zero in Vector3D div");    
        }
        return new Vector3D(m_x / scalar, m_y / scalar, m_z / scalar);
    }

    Vector3D mult(Vector3D other) {
        return new Vector3D(m_x * other.m_x, m_y * other.m_y, m_z * other.m_z);
    }

    Vector3D add(Vector3D other) {
        return new Vector3D(m_x + other.m_x, m_y + other.m_y, m_z + other.m_z);
    }

    Vector3D sub(Vector3D other) {
        return new Vector3D(m_x - other.m_x, m_y - other.m_y, m_z - other.m_z);
    }

    boolean equals(Vector3D other) {
        return MathHelpers.equalComponents(m_x, other.m_x) &&
               MathHelpers.equalComponents(m_y, other.m_y) &&
               MathHelpers.equalComponents(m_z, other.m_z);
    }

    public String toString() {
        return "Vector3D(" + m_x + ", " + m_y + ", " + m_z + ")";
    }
}
