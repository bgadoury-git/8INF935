// ==========================================
// !!! FICHIER PROVISOIRE (SQUELETTE) !!!
// ==========================================
// Ce fichier contient le STRICT MINIMUM necessaire pour que les generateurs
// de friction (Friction.pde) puissent fonctionner et etre testes.
//
// La vraie interface ForceGenerator et le vrai registre sont la responsabilite
// de la tache "Forces generiques + accumulateur". Quand cette tache sera
// fusionnee :
//   1. Supprimer CE fichier.
//   2. Verifier que l'interface ForceGenerator expose bien
//          void updateForce(Particle p, float dt);
//      (sinon, adapter la methode dans Friction.pde, c'est la seule ligne a changer).
//   3. Conserver la notion de "passe tardive" (voir ForceModifier ci-dessous) :
//      la friction de Coulomb DOIT etre calculee apres toutes les autres forces.

// Contrat de tout generateur de force : ajouter sa contribution a l'accumulateur.
interface ForceGenerator {
    void updateForce(Particle p, float dt);
}

// Marqueur : "ce generateur lit les forces deja accumulees".
// Le registre l'execute dans une 2e passe, apres tous les autres generateurs.
interface ForceModifier extends ForceGenerator {
}

// Associe une particule a un generateur.
class ForceRegistration {
    Particle particle;
    ForceGenerator generator;

    ForceRegistration(Particle particle, ForceGenerator generator) {
        this.particle = particle;
        this.generator = generator;
    }
}

class ForceRegistry {
    private ArrayList<ForceRegistration> m_registrations = new ArrayList<ForceRegistration>();

    void add(Particle particle, ForceGenerator generator) {
        m_registrations.add(new ForceRegistration(particle, generator));
    }

    void clear() {
        m_registrations.clear();
    }

    // Remplit les accumulateurs de toutes les particules enregistrees.
    void updateForces(float dt) {
        // Passe 1 : forces independantes des autres forces (gravite, trainee, ressorts...)
        for (ForceRegistration r : m_registrations) {
            if (!(r.generator instanceof ForceModifier)) {
                r.generator.updateForce(r.particle, dt);
            }
        }
        // Passe 2 : forces qui dependent du total deja accumule (friction de Coulomb)
        for (ForceRegistration r : m_registrations) {
            if (r.generator instanceof ForceModifier) {
                r.generator.updateForce(r.particle, dt);
            }
        }
    }
}
