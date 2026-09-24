#pragma once
#include "MathHelpers.h"
#include <cmath>
#include <iostream>

template <std::floating_point T = double>
class Vector3D
{
private:
	T m_x{ };
	T m_y{ };
	T m_z{ };

public:
	Vector3D(T x = {}, T y = {}, T z = {})
		: m_x(x), m_y(y), m_z(z) {
	}

	explicit Vector3D(const Polar<T>& polar) {
		setPolar(polar);
	}

	void setX(T x) { m_x = x; }
	void setY(T y) { m_y = y; }
	void setZ(T z) { m_z = z; }

	void setPolar(const Polar<T>& polar) {
		polarToCartesian(polar, m_x, m_y, m_z);
	}

	void setPolar(T radius, T azimuth, T elevation) {
		setPolar(Polar<T>{ radius, azimuth, elevation });
	}

	T getX() const { return m_x; }
	T getY() const { return m_y; }
	T getZ() const { return m_z; }

	Polar<T> getPolar() const {
		return cartesianToPolar(m_x, m_y, m_z);
	}

	T length() const {
		return std::sqrt(m_x * m_x + m_y * m_y + m_z * m_z);
	}

	T lengthSquared() const {
		return m_x * m_x + m_y * m_y + m_z * m_z;
	}

	T normalize() {
		const T len = length();
		if (len > static_cast<T>(0)) {
			m_x /= len;
			m_y /= len;
			m_z /= len;
		}
		return len;
	}

	Vector3D<T> normalized() const {
		const T len = length();
		if (len > static_cast<T>(0)) {
			return Vector3D<T>(m_x / len, m_y / len, m_z / len);
		}
		return Vector3D<T>{};
	}

	T dot(const Vector3D& other) const {
		return m_x * other.m_x + m_y * other.m_y + m_z * other.m_z;
	}

	Vector3D cross(const Vector3D& other) const {
		return Vector3D(
			m_y * other.m_z - m_z * other.m_y,
			m_z * other.m_x - m_x * other.m_z,
			m_x * other.m_y - m_y * other.m_x
		);
	}

	double angleTo(const Vector3D& other) const {
		const double denominator = length() * other.length();
		if (denominator == 0.0) {
			return 0.0;
		}
		const double cosine = std::clamp(
			static_cast<double>(dot(other)) / denominator, -1.0, 1.0);
		return std::acos(cosine);
	}

	Vector3D& operator=(const Vector3D& other) {
		if (this != &other) {
			m_x = other.m_x;
			m_y = other.m_y;
			m_z = other.m_z;
		}
		return *this;
	}

	Vector3D operator-() const {
		return Vector3D(-m_x, -m_y, -m_z);
	}

	Vector3D operator*(T scalar) const {
		return Vector3D(m_x * scalar, m_y * scalar, m_z * scalar);
	}

	friend Vector3D operator*(T scalar, const Vector3D& vector) {
		return vector * scalar;
	}

	Vector3D operator/(T scalar) const {
		if (scalar == T{}) {
			throw std::invalid_argument("Division by zero in Vector3D operator/");
		}
		return Vector3D(m_x / scalar, m_y / scalar, m_z / scalar);
	}

	Vector3D& operator*=(T scalar) {
		m_x *= scalar;
		m_y *= scalar;
		m_z *= scalar;
		return *this;
	}

	Vector3D operator*(const Vector3D& other) const {
		return Vector3D(m_x * other.m_x, m_y * other.m_y, m_z * other.m_z);
	}

	Vector3D& operator*=(const Vector3D& other) {
		m_x *= other.m_x;
		m_y *= other.m_y;
		m_z *= other.m_z;
		return *this;
	}

	Vector3D operator+(const Vector3D& other) const {
		return Vector3D(m_x + other.m_x, m_y + other.m_y, m_z + other.m_z);
	}

	Vector3D& operator+=(const Vector3D& other) {
		m_x += other.m_x;
		m_y += other.m_y;
		m_z += other.m_z;
		return *this;
	}

	Vector3D operator-(const Vector3D& other) const {
		return Vector3D(m_x - other.m_x, m_y - other.m_y, m_z - other.m_z);
	}

	Vector3D& operator-=(const Vector3D& other) {
		m_x -= other.m_x;
		m_y -= other.m_y;
		m_z -= other.m_z;
		return *this;
	}

	bool operator==(const Vector3D& other) const {
		return equalComponents(m_x, other.m_x) &&
			equalComponents(m_y, other.m_y) &&
			equalComponents(m_z, other.m_z);
	}

	bool operator!=(const Vector3D& other) const {
		return !(*this == other);
	}

	friend std::ostream& operator<< (std::ostream& out, const Vector3D& v) {
		out << "Vector3D(" << v.m_x << ", " << v.m_y << ", " << v.m_z << ")";
		return out;
	}
};