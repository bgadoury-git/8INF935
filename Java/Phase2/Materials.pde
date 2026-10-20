enum Material {
    STEEL, WOOD, RUBBER, EARTH
}

// Holds all combined coefficients for a specific pair of materials
static class MaterialInteraction {
    float restitution;
    float staticFriction;
    float kineticFriction;

    MaterialInteraction(float restitution, float staticFriction, float kineticFriction) {
        this.restitution = restitution;
        this.staticFriction = staticFriction;
        this.kineticFriction = kineticFriction;
    }
}

static class PhysicsMaterials {
    private static final int MAT_COUNT = Material.values().length;
    private static final MaterialInteraction[][] table = new MaterialInteraction[MAT_COUNT][MAT_COUNT];

    // Static block to initialize the table when the program starts
    static {
        // Fallback default for everything
        for (int i = 0; i < MAT_COUNT; i++) {
            for (int j = 0; j < MAT_COUNT; j++) {
                table[i][j] = new MaterialInteraction(0.5f, 0.5f, 0.4f);
            }
        }

        // --- SELF INTERACTIONS ---
        // set(Material 1, Material 2, Restitution, Static Friction, Kinetic Friction)
        set(Material.STEEL,  Material.STEEL,  0.6f, 0.74f, 0.57f);
        set(Material.WOOD,   Material.WOOD,   0.4f, 0.50f, 0.30f);
        set(Material.RUBBER, Material.RUBBER, 0.9f, 1.15f, 0.90f); // Rubber on rubber grips heavily
        set(Material.EARTH,  Material.EARTH,  0.1f, 0.80f, 0.60f); // Dirt on dirt is dead and rough

        // --- CROSS INTERACTIONS ---
        // Steel mixed
        set(Material.STEEL,  Material.WOOD,   0.5f, 0.60f, 0.40f);
        set(Material.STEEL,  Material.RUBBER, 0.8f, 0.90f, 0.70f);
        set(Material.STEEL,  Material.EARTH,  0.2f, 0.60f, 0.40f);
        
        // Wood mixed
        set(Material.WOOD,   Material.RUBBER, 0.7f, 0.80f, 0.60f);
        set(Material.WOOD,   Material.EARTH,  0.15f, 0.70f, 0.50f);
        
        // Rubber mixed
        set(Material.RUBBER, Material.EARTH,  0.5f, 0.80f, 0.60f);
    }

    // Helper to assign the same interaction object symmetrically
    private static void set(Material m1, Material m2, float e, float sf, float kf) {
        MaterialInteraction interaction = new MaterialInteraction(e, sf, kf);
        table[m1.ordinal()][m2.ordinal()] = interaction;
        table[m2.ordinal()][m1.ordinal()] = interaction; 
    }

    // The single O(1) lookup method
    static MaterialInteraction get(Material m1, Material m2) {
        return table[m1.ordinal()][m2.ordinal()];
    }
}
