#pragma once
#include "Point3DTests.h"
#include "Vector3DTests.h"
#include "ParticleTests.h"
class Test
{
public:
	static void run() {
		Point3DTests::testPoint3D();
		Vector3DTests::testVector3D();
		ParticleTests::testParticle();
	};
};
