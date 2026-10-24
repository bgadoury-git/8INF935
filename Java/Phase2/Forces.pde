// Generate and register Forces


interface ForceGenerator 
{
    void updateForce(Particle particle, float deltaTime);
}

class ForceRegistration
{
    final Particle particle;
    final ForceGenerator generator;
    
    ForceRegistration(Particle particle, ForceGenerator generator)
    {
        this.particle = particle;
        this.generator = generator;
    }
}

class ForceRegistry
{
    private final ArrayList<ForceRegistration> m_registrations = new ArrayList<ForceRegistration>();
    
    void add(Particle particle, ForceGenerator generator)
    {
        if(particle == null || generator == null)
        {
            throw new IllegalArgumentException("ForceRegistry.add: particle and generator must not be null");
        }
        if (contains(particle, generator)) return;
        
        m_registrations.add(new ForceRegistration(particle, generator));
    }
    
    boolean contains(Particle particle, ForceGenerator generator)
    {
        for (ForceRegistration registration : m_registrations)
        {
            if(registration.particle == particle && registration.generator == generator) return true;
        }
        return false;
    }
    
    void remove(Particle particle, ForceGenerator generator)
    {
        for (int i = m_registrations.size() - 1; i >= 0; i--)
        {
            ForceRegistration registration = m_registrations.get(i);
            if (registration.particle == particle && registration.generator == generator)
            {
                m_registrations.remove(i);
            }
        }
    }
    
    void removeParticle(Particle particle) 
    {
        for (int i = m_registrations.size() - 1; i >= 0; i--) 
        {
            if (m_registrations.get(i).particle == particle) 
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
            r.generator.updateForce(r.particle, dt);
        }
    }
    
    
    
    
    
    
    
}
