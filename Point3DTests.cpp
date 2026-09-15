#include "Point3DTests.h"
#include "TestHelpers.h"
#include <cmath>
#include <sstream>
#include <iostream>
#include <vector>

namespace Point3DTests {

	static bool testInitialization() {
		const Point3D<double> point(1.0, 2.0, 3.0);
		if (point.getX() != 1.0 || point.getY() != 2.0 || point.getZ() != 3.0) {
			std::cerr << "Initialization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetX() {
		Point3D<double> point;
		point.setX(1.0);
		if (point.getX() != 1.0) {
			std::cerr << "setX test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetY() {
		Point3D<double> point;
		point.setY(2.0);
		if (point.getY() != 2.0) {
			std::cerr << "setY test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetZ() {
		Point3D<double> point;
		point.setZ(3.0);
		if (point.getZ() != 3.0) {
			std::cerr << "setZ test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetX() {
		if (Point3D<double>(1.0, 2.0, 3.0).getX() != 1.0) {
			std::cerr << "getX test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetY() {
		if (Point3D<double>(1.0, 2.0, 3.0).getY() != 2.0) {
			std::cerr << "getY test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetZ() {
		if (Point3D<double>(1.0, 2.0, 3.0).getZ() != 3.0) {
			std::cerr << "getZ test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testDistanceTo() {
		const double distance = Point3D<double>(1.0, 2.0, 3.0).distanceTo(Point3D<double>(4.0, 6.0, 3.0));
		if (std::abs(distance - 5.0) > 1e-12) {
			std::cerr << "Distance test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testDistanceSquaredTo() {
		if (Point3D<float>(1.0f, 2.0f, 3.0f).distanceSquaredTo(Point3D<float>(4.0f, 6.0f, 3.0f)) != 25.0f) {
			std::cerr << "Distance squared test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAssignment() {
		Point3D<double> point;
		point = Point3D<double>(1.0, 2.0, 3.0);
		if (!(point == Point3D<double>(1.0, 2.0, 3.0))) {
			std::cerr << "Assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testEquality() {
		if (!(Point3D<double>(1.0, 2.0, 3.0) == Point3D<double>(1.0, 2.0, 3.0)) ||
			Point3D<double>(1.0, 2.0, 3.0) == Point3D<double>(3.0, 2.0, 1.0) ||
			!(Point3D<double>(1.0, 2.0, 3.0) != Point3D<double>(3.0, 2.0, 1.0))) {
			std::cerr << "Equality test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVectorAddition() {
		const auto result = Point3D<double>(1.0, 2.0, 3.0) + Vector3D<double>(4.0, 5.0, 6.0);
		if (!(result == Point3D<double>(5.0, 7.0, 9.0))) {
			std::cerr << "Vector addition test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVectorSubtraction() {
		const auto result = Point3D<double>(5.0, 7.0, 9.0) - Vector3D<double>(4.0, 5.0, 6.0);
		if (!(result == Point3D<double>(1.0, 2.0, 3.0))) {
			std::cerr << "Vector subtraction test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testPointSubtraction() {
		const auto result = Point3D<double>(4.0, 6.0, 8.0) - Point3D<double>(1.0, 2.0, 3.0);
		if (!(result == Vector3D<double>(3.0, 4.0, 5.0))) {
			std::cerr << "Point subtraction test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testOutput() {
		std::ostringstream output;
		output << Point3D<double>(1.0, 2.0, 3.0);
		if (output.str() != "Point3D(1, 2, 3)") {
			std::cerr << "Output test failed!" << std::endl;
			return false;
		}
		return true;
	}

	bool testPoint3D() {
		const std::vector<TestCase> tests = {
			// Construction & Accessors
			{"Initialization", testInitialization},
			{"SetX", testSetX},
			{"SetY", testSetY},
			{"SetZ", testSetZ},
			{"GetX", testGetX},
			{"GetY", testGetY},
			{"GetZ", testGetZ},

			// Metrics
			{"DistanceTo", testDistanceTo},
			{"DistanceSquaredTo", testDistanceSquaredTo},

			// Assignment & Comparisons
			{"Assignment", testAssignment},
			{"Equality", testEquality},

			// Arithmetic (Vector / Point interactions)
			{"VectorAddition", testVectorAddition},
			{"VectorSubtraction", testVectorSubtraction},
			{"PointSubtraction", testPointSubtraction},

			// I/O
			{"Output", testOutput}
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
			std::cerr << "\nPoint3D: " << failedTests.size() << " of "
				<< tests.size() << " tests failed!\n";
			return false;
		}

		std::cout << "Point3D: All " << tests.size() << " tests passed!\n";
		return true;
	}
}
