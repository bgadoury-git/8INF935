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
