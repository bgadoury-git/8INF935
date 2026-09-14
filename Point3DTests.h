#pragma once
#include "Point3D.h"

namespace Point3DTests {
	static bool testInitialization();
	static bool testSetX();
	static bool testSetY();
	static bool testSetZ();
	static bool testGetX();
	static bool testGetY();
	static bool testGetZ();
	static bool testDistanceTo();
	static bool testDistanceSquaredTo();
	static bool testAssignment();
	static bool testEquality();
	static bool testVectorAddition();
	static bool testVectorSubtraction();
	static bool testPointSubtraction();
	static bool testOutput();
	bool testPoint3D();
}
