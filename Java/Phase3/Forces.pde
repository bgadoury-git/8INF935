// Generate and register Forces
// Phase 3: the registry now works on rigid bodies (Particle -> RigidBody).
// A rigid body's translation forces end up in its gravityCenter particle (RigidBody.addForce).


interface ForceGenerator 
{
    void updateForce(RigidBody body, float deltaTime);
}

class ForceRegistration
{
    final RigidBody body;
    final ForceGenerator generator;
    
    ForceRegistration(RigidBody body, ForceGenerator generator)
    {
        this.body = body;
        this.generator = generator;
    }
}

class ForceRegistry
{
    private final ArrayList<ForceRegistration> m_registrations = new ArrayList<ForceRegistration>();
    
    void add(RigidBody body, ForceGenerator generator)
    {
        if(body == null || generator == null)
        {
            throw new IllegalArgumentException("ForceRegistry.add: body and generator must not be null");
        }
        if (contains(body, generator)) return;
        
        m_registrations.add(new ForceRegistration(body, generator));
    }
    
    boolean contains(RigidBody body, ForceGenerator generator)
    {
        for (ForceRegistration registration : m_registrations)
        {
            if(registration.body == body && registration.generator == generator) return true;
        }
        return false;
    }
    
    void remove(RigidBody body, ForceGenerator generator)
    {
        for (int i = m_registrations.size() - 1; i >= 0; i--)
        {
            ForceRegistration registration = m_registrations.get(i);
            if (registration.body == body && registration.generator == generator)
            {
                m_registrations.remove(i);
            }
        }
    }
    
    void removeBody(RigidBody body) 
    {
        for (int i = m_registrations.size() - 1; i >= 0; i--) 
        {
            if (m_registrations.get(i).body == body) 
            {
                m_registrations.remove(i);
            }
        }
    }

    void clear() 
    {
        m_registrations.clear();
    }
    
    int size() 
    {
        return m_registrations.size();
    }
    
    void updateForces(float dt) 
    {
        for (ForceRegistration r : m_registrations) 
        {
            r.generator.updateForce(r.body, dt);
        }
    }
    
    
    
    
    
    
    
}
