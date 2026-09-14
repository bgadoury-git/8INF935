#pragma once
#include "Vector3D.h"

namespace Vector3DTests {

	static bool testInitialization();
	static bool testSetX();
	static bool testSetY();
	static bool testSetZ();
	static bool testGetX();
	static bool testGetY();
	static bool testGetZ();
	static bool testLength();
	static bool testLengthSquared();
	static bool testNormalize();
	static bool testNormalized();
	static bool testZeroNormalization();
	static bool testDot();
	static bool testCross();
	static bool testAngleTo();
	static bool testAngleToWithZeroVector();
	static bool testAssignment();
	static bool testNegation();
	static bool testScalarMultiplication();
	static bool testReverseScalarMultiplication();
	static bool testScalarMultiplicationAssignment();
	static bool testScalarDivision();
	static bool testScalarDivisionByZero();
	static bool testVectorMultiplication();
	static bool testVectorMultiplicationAssignment();
	static bool testAddition();
	static bool testAdditionAssignment();
	static bool testSubtraction();
	static bool testSubtractionAssignment();
	static bool testEquality();
	static bool testInequality();
	static bool testOutput();

	bool testVector3D();
}
