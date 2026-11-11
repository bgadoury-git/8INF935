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
