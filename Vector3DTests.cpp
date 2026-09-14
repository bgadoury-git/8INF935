#include "Vector3DTests.h"
#include "TestHelpers.h"
#include <sstream>
#include <iostream>
#include <vector>

namespace Vector3DTests {

	static bool testInitialization() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		if (v1.getX() != 1.0 || v1.getY() != 2.0 || v1.getZ() != 3.0) {
			std::cerr << "Initialization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testNormalized() {
		const auto normalized = Vector3D<double>(3.0, 4.0, 0.0).normalized();
		if (std::abs(normalized.getX() - 0.6) > 1e-9 ||
			std::abs(normalized.getY() - 0.8) > 1e-9 || normalized.getZ() != 0.0) {
			std::cerr << "Normalized test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testZeroNormalization() {
		Vector3D<double> vector;
		if (vector.normalize() != 0.0 || vector != Vector3D<double>(0.0, 0.0, 0.0) ||
			vector.normalized() != Vector3D<double>(0.0, 0.0, 0.0)) {
			std::cerr << "Zero normalization test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetX() {
		Vector3D<double> v1;
		v1.setX(1.0);
		if (v1.getX() != 1.0) {
			std::cerr << "setX test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAngleTo() {
		const double angle = Vector3D<double>(1.0, 0.0, 0.0).angleTo(Vector3D<double>(0.0, 1.0, 0.0));
		if (std::abs(angle - std::acos(0.0)) > 1e-12) {
			std::cerr << "Angle test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAngleToWithZeroVector() {
		if (Vector3D<double>().angleTo(Vector3D<double>(1.0, 0.0, 0.0)) != 0.0) {
			std::cerr << "Zero angle test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetY() {
		Vector3D<double> v1;
		v1.setY(2.0);
		if (v1.getY() != 2.0) {
			std::cerr << "setY test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testReverseScalarMultiplication() {
		const Vector3D<double> multiplied = 2.0 * Vector3D<double>(1.0, 2.0, 3.0);
		if (multiplied != Vector3D<double>(2.0, 4.0, 6.0)) {
			std::cerr << "Reverse scalar multiplication test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSetZ() {
		Vector3D<double> v1;
		v1.setZ(3.0);
		if (v1.getZ() != 3.0) {
			std::cerr << "setZ test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testInequality() {
		if (!(Vector3D<double>(1.0, 2.0, 3.0) != Vector3D<double>(3.0, 2.0, 1.0))) {
			std::cerr << "Inequality test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetX() {
		if (Vector3D<double>(1.0, 2.0, 3.0).getX() != 1.0) {
			std::cerr << "getX test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetY() {
		if (Vector3D<double>(1.0, 2.0, 3.0).getY() != 2.0) {
			std::cerr << "getY test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testGetZ() {
		if (Vector3D<double>(1.0, 2.0, 3.0).getZ() != 3.0) {
			std::cerr << "getZ test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testLength() {
		Vector3D<double> v1(2.0, 3.0, 6.0);
		if (v1.length() != 7.0) {
			std::cerr << "Length test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testLengthSquared() {
		Vector3D<double> v1(2.0, 3.0, 6.0);
		if (v1.lengthSquared() != 49.0) {
			std::cerr << "Length squared test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testNormalize() {
		Vector3D<double> v1(3.0, 4.0, 0.0);
		if (v1.normalize() != 5.0 || std::abs(v1.getX() - 0.6) > 1e-9 ||
			std::abs(v1.getY() - 0.8) > 1e-9 || v1.getZ() != 0.0) {
			std::cerr << "Normalize test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testDot() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> v2(4.0, 5.0, 6.0);
		if (v1.dot(v2) != 32.0) {
			std::cerr << "Dot test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testCross() {
		Vector3D<double> cross = Vector3D<double>(1.0, 2.0, 3.0).cross(Vector3D<double>(4.0, 5.0, 6.0));
		if (cross.getX() != -3.0 || cross.getY() != 6.0 || cross.getZ() != -3.0) {
			std::cerr << "Cross test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAssignment() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> v2;
		v2 = v1;
		if (!(v2 == v1)) {
			std::cerr << "Assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testNegation() {
		Vector3D<double> negated = -Vector3D<double>(1.0, 2.0, 3.0);
		if (negated.getX() != -1.0 || negated.getY() != -2.0 || negated.getZ() != -3.0) {
			std::cerr << "Negation test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testScalarMultiplication() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> multiplied = v1 * 2.0f;
		if (!(multiplied == Vector3D<double>(2.0, 4.0, 6.0))) {
			std::cerr << "Scalar multiplication test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testScalarMultiplicationAssignment() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		v1 *= 2.0f;
		if (!(v1 == Vector3D<double>(2.0, 4.0, 6.0))) {
			std::cerr << "Scalar multiplication assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testScalarDivision() {
		Vector3D<double> v1(2.0, 4.0, 6.0);
		Vector3D<double> divided = v1 / 2.0f;
		if (!(divided == Vector3D<double>(1.0, 2.0, 3.0))) {
			std::cerr << "Scalar division test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testScalarDivisionByZero() {
		Vector3D<double> v1(2.0, 4.0, 6.0);
		try {
			Vector3D<double> divided = v1 / 0.0f;
			std::cerr << "Scalar division by zero test failed!" << std::endl;
			return false;
		}
		catch (const std::invalid_argument&) {
			return true; // Expected exception
		}
		catch (...) {
			std::cerr << "Scalar division by zero test failed with unexpected exception!" << std::endl;
			return false;
		}
	}

	static bool testVectorMultiplication() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> v2(4.0, 5.0, 6.0);
		if (!((v1 * v2) == Vector3D<double>(4.0, 10.0, 18.0))) {
			std::cerr << "Vector multiplication test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testVectorMultiplicationAssignment() {
		Vector3D<double> result(1.0, 2.0, 3.0);
		result *= Vector3D<double>(4.0, 5.0, 6.0);
		if (!(result == Vector3D<double>(4.0, 10.0, 18.0))) {
			std::cerr << "Vector multiplication assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAddition() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> v2(4.0, 5.0, 6.0);
		if (!((v1 + v2) == Vector3D<double>(5.0, 7.0, 9.0))) {
			std::cerr << "Addition test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testAdditionAssignment() {
		Vector3D<double> result(1.0, 2.0, 3.0);
		result += Vector3D<double>(4.0, 5.0, 6.0);
		if (!(result == Vector3D<double>(5.0, 7.0, 9.0))) {
			std::cerr << "Addition assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSubtraction() {
		Vector3D<double> v1(1.0, 2.0, 3.0);
		Vector3D<double> v2(4.0, 5.0, 6.0);
		if (!((v2 - v1) == Vector3D<double>(3.0, 3.0, 3.0))) {
			std::cerr << "Subtraction test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testSubtractionAssignment() {
		Vector3D<double> result(4.0, 5.0, 6.0);
		result -= Vector3D<double>(1.0, 2.0, 3.0);
		if (!(result == Vector3D<double>(3.0, 3.0, 3.0))) {
			std::cerr << "Subtraction assignment test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testEquality() {
		if (!(Vector3D<double>(1.0, 2.0, 3.0) == Vector3D<double>(1.0, 2.0, 3.0)) ||
			Vector3D<double>(1.0, 2.0, 3.0) == Vector3D<double>(3.0, 2.0, 1.0)) {
			std::cerr << "Equality test failed!" << std::endl;
			return false;
		}
		return true;
	}

	static bool testOutput() {
		std::ostringstream output;
		output << Vector3D<double>(1.0, 2.0, 3.0);
		if (output.str() != "Vector3D(1, 2, 3)") {
			std::cerr << "Output test failed!" << std::endl;
			return false;
		}
		return true;
	}

	bool testVector3D() {
		const std::vector<TestCase> tests = {
			// Construction & Accessors
			{"Initialization", testInitialization},
			{"SetX", testSetX},
			{"SetY", testSetY},
			{"SetZ", testSetZ},
			{"GetX", testGetX},
			{"GetY", testGetY},
			{"GetZ", testGetZ},

			// Metrics & Normalization
			{"Length", testLength},
			{"LengthSquared", testLengthSquared},
			{"Normalize", testNormalize},
			{"Normalized", testNormalized},
			{"ZeroNormalization", testZeroNormalization},

			// Vector Products & Angles
			{"Dot", testDot},
			{"Cross", testCross},
			{"AngleTo", testAngleTo},
			{"AngleToWithZeroVector", testAngleToWithZeroVector},

			// Operators & Arithmetic
			{"Assignment", testAssignment},
			{"Negation", testNegation},
			{"ScalarMultiplication", testScalarMultiplication},
			{"ReverseScalarMultiplication", testReverseScalarMultiplication},
			{"ScalarMultiplicationAssignment", testScalarMultiplicationAssignment},
			{"VectorMultiplication", testVectorMultiplication},
			{"VectorMultiplicationAssignment", testVectorMultiplicationAssignment},
			{"Addition", testAddition},
			{"AdditionAssignment", testAdditionAssignment},
			{"Subtraction", testSubtraction},
			{"SubtractionAssignment", testSubtractionAssignment},
			{"Equality", testEquality},
			{"Inequality", testInequality},
			{"ScalarDivision", testScalarDivision},
			{"ScalarDivisionByZero", testScalarDivisionByZero},

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
			std::cerr << "\nVector3D: " << failedTests.size() << " of "
				<< tests.size() << " tests failed!\n";
			return false;
		}

		std::cout << "Vector3D: All " << tests.size() << " tests passed!\n";
		return true;
	}
}