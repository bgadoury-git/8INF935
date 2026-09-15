#pragma once
#include "Vector3D.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <iostream>
#include <type_traits>

template <std::floating_point T = double>
class Point3D
{
private:
	T m_x{};
	T m_y{};
	T m_z{};

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

public:
	Point3D(T x = {}, T y = {}, T z = {})
		: m_x(x), m_y(y), m_z(z) {
	}

	void setX(T x) { m_x = x; }
	void setY(T y) { m_y = y; }
	void setZ(T z) { m_z = z; }

	T getX() const { return m_x; }
	T getY() const { return m_y; }
	T getZ() const { return m_z; }

	T distanceTo(const Point3D& other) const {
		const T dx = static_cast<T>(m_x) - other.m_x;
		const T dy = static_cast<T>(m_y) - other.m_y;
		const T dz = static_cast<T>(m_z) - other.m_z;
		return std::sqrt(dx * dx + dy * dy + dz * dz);
	}

	T distanceSquaredTo(const Point3D& other) const {
		const T dx = m_x - other.m_x;
		const T dy = m_y - other.m_y;
		const T dz = m_z - other.m_z;
		return dx * dx + dy * dy + dz * dz;
	}

	Point3D& operator=(const Point3D& other) {
		if (this != &other) {
			m_x = other.m_x;
			m_y = other.m_y;
			m_z = other.m_z;
		}
		return *this;
	}

	bool operator==(const Point3D& other) const {
		return equalComponents(m_x, other.m_x) &&
			equalComponents(m_y, other.m_y) &&
			equalComponents(m_z, other.m_z);
	}

	bool operator!=(const Point3D& other) const {
		return !(*this == other);
	}

	friend std::ostream& operator<<(std::ostream& out, const Point3D& point) {
		out << "Point3D(" << point.m_x << ", " << point.m_y << ", " << point.m_z << ")";
		return out;
	}

	Point3D operator+(const Vector3D<T>& v) const {
		return Point3D(m_x + v.getX(), m_y + v.getY(), m_z + v.getZ());
	}

	Point3D operator-(const Vector3D<T>& v) const {
		return Point3D(m_x - v.getX(), m_y - v.getY(), m_z - v.getZ());
	}

	Vector3D<T> operator-(const Point3D& other) const {
		return Vector3D<T>(m_x - other.m_x, m_y - other.m_y, m_z - other.m_z);
	}
};

