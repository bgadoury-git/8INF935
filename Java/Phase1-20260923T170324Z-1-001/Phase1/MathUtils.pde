// ==========================================
// Point3D, Vector3D, and MathHelpers
// ==========================================

static class Polar {
    public float radius;
    public float azimuth;
    public float elevation;

    public Polar() {
        this.radius = 0;
        this.azimuth = 0;
        this.elevation = 0;
    }

    public Polar(float radius, float azimuth, float elevation) {
        this.radius = radius;
        this.azimuth = azimuth;
        this.elevation = elevation;
    }
}

static class MathHelpers {
    static boolean equalComponents(float left, float right, float toleranceMultiplier) {
        float difference = Math.abs(left - right);
        float scale = Math.max(1.0f, Math.max(Math.abs(left), Math.abs(right)));
        return difference <= 1e-5f * scale * toleranceMultiplier;
    }

    static boolean equalComponents(float left, float right) {
        return equalComponents(left, right, 1.0f);
    }

    // Standalone Polar -> Cartesian conversion for left-handed systems (+X right, +Y up, +Z forward)
    static void polarToCartesian(Polar polar, float[] outCartesian) {
        float cosElevation = (float)Math.cos(polar.elevation);
        float y = polar.radius * (float)Math.sin(polar.elevation);
        float x = polar.radius * cosElevation * (float)Math.sin(polar.azimuth);
        float z = polar.radius * cosElevation * (float)Math.cos(polar.azimuth);

        // Clean up tiny architectural floating-point residuals (Java's float epsilon is ~1.19e-7)
        float threshold = 1.1920929e-7f * Math.max(1.0f, Math.abs(polar.radius)) * 10.0f;
        
        outCartesian[0] = (Math.abs(x) <= threshold) ? 0.0f : x;
        outCartesian[1] = (Math.abs(y) <= threshold) ? 0.0f : y;
        outCartesian[2] = (Math.abs(z) <= threshold) ? 0.0f : z;
    }

    // Standalone Cartesian -> Polar conversion for left-handed systems
    static Polar cartesianToPolar(float x, float y, float z) {
        float len = (float)Math.sqrt(x * x + y * y + z * z);
        if (len == 0.0f) {
            return new Polar(0.0f, 0.0f, 0.0f);
        }
        float clampedY = Math.max(-1.0f, Math.min(1.0f, y / len));
        float elevation = (float)Math.asin(clampedY);
        float azimuth = (float)Math.atan2(x, z);
        return new Polar(len, azimuth, elevation);
    }
}

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

class Point3D {
    private float m_x, m_y, m_z;

    public Point3D() { m_x = 0; m_y = 0; m_z = 0; }

    public Point3D(float x, float y, float z) {
        m_x = x; m_y = y; m_z = z;
    }

    public Point3D(Polar polar) {
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

    float distanceTo(Point3D other) {
        float dx = m_x - other.m_x;
        float dy = m_y - other.m_y;
        float dz = m_z - other.m_z;
        return (float)Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    float distanceSquaredTo(Point3D other) {
        float dx = m_x - other.m_x;
        float dy = m_y - other.m_y;
        float dz = m_z - other.m_z;
        return dx * dx + dy * dy + dz * dz;
    }

    boolean equals(Point3D other) {
        return MathHelpers.equalComponents(m_x, other.m_x) &&
               MathHelpers.equalComponents(m_y, other.m_y) &&
               MathHelpers.equalComponents(m_z, other.m_z);
    }

    public String toString() {
        return "Point3D(" + m_x + ", " + m_y + ", " + m_z + ")";
    }

    Point3D add(Vector3D v) {
        return new Point3D(m_x + v.getX(), m_y + v.getY(), m_z + v.getZ());
    }

    Point3D sub(Vector3D v) {
        return new Point3D(m_x - v.getX(), m_y - v.getY(), m_z - v.getZ());
    }

    Vector3D sub(Point3D other) {
        return new Vector3D(m_x - other.m_x, m_y - other.m_y, m_z - other.m_z);
    }
}
