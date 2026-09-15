#pragma once
#pragma once

#include "Processing.h"
#include "PhysicsEngine.h"
#include "GraphicsConstants.h"
#include <cmath>

class Arena {
public:
    static constexpr float Extent = 2560.0f;
    static constexpr float Spacing = 40.0f;
    static constexpr float WallHeight = 1200.0f;
    static constexpr float WallThickness = 10.0f;
    static constexpr float MaxCeilingHeight = 2000.0f;

    static void setupLighting(Processing::PApplet& app) {
        app.background(18, 24, 38);
        app.camera(0.0f, -40.0f, -520.0f,
            0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f);
        app.lights();
        app.ambientLight(70, 80, 110);
        app.directionalLight(220, 220, 220, -0.4f, -0.8f, -0.5f);
    }

    static void draw(Processing::PApplet& app) {
        // --- Floor Base ---
        app.noStroke();
        app.fill(35, 48, 68);
        app.pushMatrix();
        app.translate(0.0f, floorY - 2.0f, 0.0f);
        app.box(Extent * 2.0f, 4.0f, Extent * 2.0f);
        app.popMatrix();

        // --- Floor Grid ---
        app.stroke(90, 110, 140);
        app.strokeWeight(1.0f);
        for (float coord = -Extent; coord <= Extent; coord += Spacing) {
            app.line(coord, floorY, -Extent, coord, floorY, Extent);
            app.line(-Extent, floorY, coord, Extent, floorY, coord);
        }
        app.noStroke();

        // --- Boundary Walls ---
        app.fill(45, 60, 85, 180);
        float wallCenterY = floorY - (WallHeight * 0.5f);

        // North / South (Z offsets)
        app.pushMatrix();
        app.translate(0.0f, wallCenterY, -Extent);
        app.box(Extent * 2.0f, WallHeight, WallThickness);
        app.popMatrix();

        app.pushMatrix();
        app.translate(0.0f, wallCenterY, Extent);
        app.box(Extent * 2.0f, WallHeight, WallThickness);
        app.popMatrix();

        // West / East (X offsets)
        app.pushMatrix();
        app.translate(-Extent, wallCenterY, 0.0f);
        app.box(WallThickness, WallHeight, Extent * 2.0f);
        app.popMatrix();

        app.pushMatrix();
        app.translate(Extent, wallCenterY, 0.0f);
        app.box(WallThickness, WallHeight, Extent * 2.0f);
        app.popMatrix();
    }

    static bool isOutOfBounds(const Point3D<float>& pos) {
        return (pos.getY() <= -floorY) ||
            (pos.getY() >= MaxCeilingHeight) ||
            (std::abs(pos.getX()) >= Extent) ||
            (std::abs(pos.getZ()) >= Extent);
    }
};