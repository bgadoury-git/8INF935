#pragma once
#include "Particle.h"

namespace ParticleTests {
	static bool testDefaultInitialization();
	static bool testCustomInitialization();
	static bool testGravityEffect();
	static bool testZeroMass();
	static bool testParticleCountLifecycle();
	static bool testCopyAndMoveSemantics();
	static bool testVerletIntegrationLinearMotion();
	static bool testVerletIntegrationGravity();
	static bool testVerletIntegrationDamping();
	static bool testTrajectoryGeneration();
	bool testParticle();
}