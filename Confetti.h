#include "Processing.h"
#include "Particle.h"

class Confetti : public Particle<float>
{
public:
    inline static const float baseSpeed{ 50.0f };
    inline static const bool defaultGravityState{ false };

    Confetti(const Point3D<float>& pos = {}, const Vector3D<float>& vel = {})
        : Particle(pos, vel, {}, 0.1f, 0.999f, defaultGravityState){
    }

    void draw() const override {
        auto* applet = Processing::PApplet::g_papplet;
        if (!applet) return;

        const Point3D<float> head = getPosition();
            const Vector3D<float> vel = getVelocity();

            // Stretch back along velocity vector (~2 frames of motion)
            constexpr float tailTime = 0.035f;
        Point3D<float> tail(
            head.getX() - vel.getX() * tailTime,
            head.getY() - vel.getY() * tailTime,
            head.getZ() - vel.getZ() * tailTime
        );

        // Single emissive line segment - no transforms, no matrix stack, no tessellation
        applet->stroke(0, 255, 200, 255);
        applet->strokeWeight(2.5f);
        applet->line(
            tail.getX(), -tail.getY(), tail.getZ(),
            head.getX(), -head.getY(), head.getZ()
        );
        applet->noStroke();
    }
};