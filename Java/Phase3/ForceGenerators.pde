// Concrete Force Generators

class GravityGenerator implements ForceGenerator {
    private final Vector3D m_gravity;

    GravityGenerator(Vector3D gravity) {
        // Defensive copy: later changes to the caller's vector cannot affect this generator
        m_gravity = new Vector3D(gravity.getX(), gravity.getY(), gravity.getZ());
    }

    @Override
    public void updateForce(Particle particle, float dt) {
        // Infinite mass receives no force
        if (particle.getInverseMass() <= 0.0f) return;
        // Force = acceleration × mass; integration divides by mass to recover g
        particle.addForce(m_gravity.mult(particle.getMass()));
    }
}

class ConstantForceGenerator implements ForceGenerator
{
    private final Vector3D m_force = new Vector3D();
    private boolean m_active = true;

    ConstantForceGenerator(Vector3D force) {
        setForce(force);
    }

    void setForce(Vector3D force) {
        m_force.setX(force.getX());
        m_force.setY(force.getY());
        m_force.setZ(force.getZ());
    }

    Vector3D getForce() {
        return new Vector3D(m_force.getX(), m_force.getY(), m_force.getZ());
    }

    void setActive(boolean active) { m_active = active; }
    boolean isActive() { return m_active; }

    @Override
    public void updateForce(Particle particle, float dt) {
        // no force when inactive or for infinite mass
        if (!m_active || particle.getInverseMass() <= 0.0f) return;
        // addForce only reads values, so passing the internal vector is safe
        particle.addForce(m_force);
    }
}


void applyExplosion(ArrayList<Particle> targets, Point3D center, float radius, float maxImpulse) {
    for (Particle p : targets) {
        if (p.getInverseMass() <= 0.0f) continue;

        Vector3D offset = p.getPosition().sub(center);
        float dist = offset.length();
        if (dist >= radius) continue;
        
        Vector3D dir = (dist > 1e-4f) ? offset.div(dist) : new Vector3D(0.0f, 1.0f, 0.0f);
        float strength = maxImpulse * (1.0f - dist / radius);
        p.applyImpulse(dir.mult(strength));
    }
}
