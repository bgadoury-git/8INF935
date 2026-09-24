#pragma once
#include <numbers>
#include <cmath>
#include <algorithm>
#include <limits>

constexpr double rad_to_deg(double radians) noexcept {
    return radians * (180.0 / std::numbers::pi);
}

constexpr double deg_to_rad(double degrees) noexcept {
    return degrees * (std::numbers::pi / 180.0);
}

template <std::floating_point T = double>
static bool equalComponents(T left, T right) {
	if constexpr (std::is_floating_point_v<T>) {
		const T difference = std::abs(left - right);
		const T scale = std::max({ static_cast<T>(1), std::abs(left), std::abs(right) });
		return difference <= std::numeric_limits<T>::epsilon() * scale;
	}
	else {
		return left == right;
	}
}

template <std::floating_point T = double>
struct Polar {
	T radius{ };
	T azimuth{ };   // Yaw: angle in XZ plane from +Z towards +X (in radians)
	T elevation{ }; // Pitch: angle from XZ plane towards +Y (in radians)
};

// Standalone Polar -> Cartesian conversion for left-handed systems (+X right, +Y up, +Z forward)
template <std::floating_point T = double>
inline void polarToCartesian(const Polar<T>& polar, T& outX, T& outY, T& outZ) {
	const T cosElevation = std::cos(polar.elevation);
	T y = polar.radius * std::sin(polar.elevation);
	T x = polar.radius * cosElevation * std::sin(polar.azimuth);
	T z = polar.radius * cosElevation * std::cos(polar.azimuth);

	// Clean up tiny architectural floating-point residuals near zero (e.g., cos(pi/2))
	const T threshold = std::numeric_limits<T>::epsilon() * std::max(T{ 1 }, std::abs(polar.radius)) * static_cast<T>(10);

	outY = (std::abs(y) <= threshold) ? T{} : y;
	outX = (std::abs(x) <= threshold) ? T{} : x;
	outZ = (std::abs(z) <= threshold) ? T{} : z;
}

// Standalone Cartesian -> Polar conversion for left-handed systems
template <std::floating_point T = double>
inline Polar<T> cartesianToPolar(T x, T y, T z) {
	const T len = std::sqrt(x * x + y * y + z * z);
	if (len == static_cast<T>(0)) {
		return Polar<T>{ {}, {}, {} };
	}
	const T elevation = std::asin(std::clamp(y / len, static_cast<T>(-1), static_cast<T>(1)));
	const T azimuth = std::atan2(x, z);
	return Polar<T>{ len, azimuth, elevation };
}
