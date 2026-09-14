#pragma once
#include <numbers>

constexpr double rad_to_deg(double radians) noexcept {
    return radians * (180.0 / std::numbers::pi);
}

constexpr double deg_to_rad(double degrees) noexcept {
    return degrees * (std::numbers::pi / 180.0);
}

