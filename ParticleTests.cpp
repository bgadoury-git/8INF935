#include "ParticleTests.h"
#include "TestHelpers.h"
#include <cmath>
#include <iostream>
#include <vector>

namespace ParticleTests {

	static bool testDefaultInitialization() {
		const Particle<double> p;
		if (p.getPosition() != Point3D<double>(0.0, 0.0, 0.0) ||
			p.getVelocity() != Vector3D<double>(0.0, 0.0, 0.0) ||
			p.getMass() != 1.0 ||
			p.getInverseMass() != 1.0 ||
			std::abs(p.getLinearDamping() - 0.999) > 1e-9 ||
			!p.getAffectedByGravity()) {
			std::cerr << "Default initialization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testCustomInitialization() {
		const Point3D<double> pos(1.0, 2.0, 3.0);
		const Vector3D<double> vel(4.0, 5.0, 6.0);
		const Vector3D<double> accel(0.0, 1.0, 0.0);
		const double mass = 2.0;
		const double damping = 0.95;

		const Particle<double> p(pos, vel, accel, mass, damping, false);

		if (p.getPosition() != pos ||
			p.getVelocity() != vel ||
			p.getAcceleration() != accel ||
			p.getMass() != mass ||
			p.getInverseMass() != 0.5 ||
			p.getLinearDamping() != damping ||
			p.getAffectedByGravity()) {
			std::cerr << "Custom initialization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGravityEffect() {
		// When affectedByGravity is true, gravity is subtracted along Y during construction
		const Vector3D<double> initialAccel(1.0, 2.0, 3.0);
		const Particle<double> pWithGravity(Point3D<double>{}, Vector3D<double>{}, initialAccel, 1.0, 0.999, true);
		const Particle<double> pWithoutGravity(Point3D<double>{}, Vector3D<double>{}, initialAccel, 1.0, 0.999, false);

		const double expectedYWithGravity = 2.0 - static_cast<double>(GRAVITY);
		if (std::abs(pWithGravity.getAcceleration().getY() - expectedYWithGravity) > 1e-6 ||
			pWithoutGravity.getAcceleration().getY() != 2.0) {
			std::cerr << "Gravity effect initialization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testZeroMass() {
		// Mass <= 0 implies infinite mass (static particle): inverseMass = 0
		const Particle<double> staticParticle(Point3D<double>{}, Vector3D<double>{}, Vector3D<double>{}, 0.0);
		if (staticParticle.getInverseMass() != 0.0 || staticParticle.getMass() != 0.0) {
			std::cerr << "Zero mass (infinite mass) test failed!" << std::endl;
			return false;
		}

		// Motion integration should be skipped for infinite mass
		Point3D<double> initialPos(10.0, 20.0, 30.0);
		Vector3D<double> initialVel(100.0, 100.0, 100.0);
		Particle<double> p(initialPos, initialVel, Vector3D<double>{}, 0.0, 1.0, false);
		p.applyVerletIntegration(0.1);

		if (p.getPosition() != initialPos) {
			std::cerr << "Zero mass integration immobility test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testParticleCountLifecycle() {
		const int baseCount = Particle<double>::particleCount;

		{
			Particle<double> p1;
			Particle<double> p2;
			if (Particle<double>::particleCount != baseCount + 2) {
				std::cerr << "Particle count allocation test failed!" << std::endl;
				return false;
			}
		}

		if (Particle<double>::particleCount != baseCount) {
			std::cerr << "Particle count destruction test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testCopyAndMoveSemantics() {
		const int baseCount = Particle<double>::particleCount;
		const Point3D<double> pos(1.0, 2.0, 3.0);
		const Vector3D<double> vel(4.0, 5.0, 6.0);

		{
			Particle<double> original(pos, vel, Vector3D<double>{}, 2.0, 0.9, false);
			Particle<double> copyConstructed(original);

			if (copyConstructed.getPosition() != pos ||
				copyConstructed.getVelocity() != vel ||
				Particle<double>::particleCount != baseCount + 2) {
				std::cerr << "Particle copy construction test failed!" << std::endl;
				return false;
			}

			Particle<double> moveConstructed(std::move(original));
			if (moveConstructed.getPosition() != pos ||
				moveConstructed.getVelocity() != vel ||
				Particle<double>::particleCount != baseCount + 3) {
				std::cerr << "Particle move construction test failed!" << std::endl;
				return false;
			}
		}

		if (Particle<double>::particleCount != baseCount) {
			std::cerr << "Particle copy/move cleanup count test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVerletIntegrationLinearMotion() {
		// Zero acceleration, no damping (damping = 1.0), no gravity
		Point3D<double> startPos(0.0, 0.0, 0.0);
		Vector3D<double> velocity(10.0, 0.0, 0.0);
		Particle<double> p(startPos, velocity, Vector3D<double>{}, 1.0, 1.0, false);

		p.applyVerletIntegration(1.0);

		// Position should increment by velocity * dt = 10.0
		if (std::abs(p.getPosition().getX() - 10.0) > 1e-6 ||
			std::abs(p.getVelocity().getX() - 10.0) > 1e-6) {
			std::cerr << "Linear motion Verlet integration test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVerletIntegrationGravity() {
		// Particle falling under gravity starting from rest with damping = 1.0
		Point3D<double> startPos(0.0, 100.0, 0.0);
		Vector3D<double> velocity(0.0, 0.0, 0.0);
		Particle<double> p(startPos, velocity, Vector3D<double>{}, 1.0, 1.0, true);

		constexpr double dt = 0.5;
		p.applyVerletIntegration(dt);

		// expected y = y0 + v0*dt + 0.5 * a * dt^2
		const double expectedY = 100.0 - 0.5 * static_cast<double>(GRAVITY) * dt * dt;
		const double expectedVelY = -static_cast<double>(GRAVITY) * dt;

		if (std::abs(p.getPosition().getY() - expectedY) > 1e-5 ||
			std::abs(p.getVelocity().getY() - expectedVelY) > 1e-5) {
			std::cerr << "Gravity Verlet integration test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVerletIntegrationDamping() {
		// Velocity decay through time-corrected damping: v = v0 * (damping ^ dt)
		Point3D<double> startPos(0.0, 0.0, 0.0);
		Vector3D<double> initialVelocity(100.0, 0.0, 0.0);
		constexpr double damping = 0.8;
		constexpr double dt = 2.0;

		Particle<double> p(startPos, initialVelocity, Vector3D<double>{}, 1.0, damping, false);
		p.applyVerletIntegration(dt);

		const double expectedVelX = 100.0 * std::pow(damping, dt);
		if (std::abs(p.getVelocity().getX() - expectedVelX) > 1e-5) {
			std::cerr << "Damping Verlet integration test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testTrajectoryGeneration() {
		Point3D<double> startPos(0.0, 0.0, 0.0);
		Vector3D<double> initialVelocity(10.0, 20.0, 0.0);
		Particle<double> p(startPos, initialVelocity, Vector3D<double>{}, 1.0, 0.999, false);

		// Request 10 subdivisions for a 2-second trajectory
		const int precision = 10;
		const auto trajectory = p.getTrajectory(precision, 2.0);

		// Path points returned should equal precision + 1
		if (trajectory.size() != static_cast<size_t>(precision + 1)) {
			std::cerr << "Trajectory point count test failed!" << std::endl;
			return false;
		}

		// First point must be the starting position
		if (trajectory.front() != startPos) {
			std::cerr << "Trajectory start point test failed!" << std::endl;
			return false;
		}

		// Points should be progressing forward along X
		if (trajectory.back().getX() <= trajectory.front().getX()) {
			std::cerr << "Trajectory progression test failed!" << std::endl;
			return false;
		}

		// Precision floor guard (<= 4 should default to 4 steps -> 5 points)
		const auto clampedTrajectory = p.getTrajectory(2, 1.0);
		if (clampedTrajectory.size() != 5) {
			std::cerr << "Trajectory precision clamp test failed!" << std::endl;
			return false;
		}

		return true;
	}

	bool testParticle() {
		const std::vector<TestCase> tests = {
			// Construction & Invariants
			{"DefaultInitialization", testDefaultInitialization},
			{"CustomInitialization", testCustomInitialization},
			{"GravityEffect", testGravityEffect},
			{"ZeroMass", testZeroMass},

			// Memory / Lifecycle & Semantics
			{"ParticleCountLifecycle", testParticleCountLifecycle},
			{"CopyAndMoveSemantics", testCopyAndMoveSemantics},

			// Physics Integration
			{"VerletIntegrationLinearMotion", testVerletIntegrationLinearMotion},
			{"VerletIntegrationGravity", testVerletIntegrationGravity},
			{"VerletIntegrationDamping", testVerletIntegrationDamping},

			// Trajectory Prediction
			{"TrajectoryGeneration", testTrajectoryGeneration}
		};

		size_t passed = 0;
		std::vector<std::string_view> failedTests;

		for (const auto& [name, runTest] : tests) {
			if (runTest()) {
				++passed;
			}
			else {
				failedTests.push_back(name);
				std::cerr << "  [FAILED] " << name << '\n';
			}
		}

		if (!failedTests.empty()) {
			std::cerr << "\nParticle: " << failedTests.size() << " of "
				<< tests.size() << " tests failed!\n";
			return false;
		}

		std::cout << "Particle: All " << tests.size() << " tests passed!\n";
		return true;
	}
}