#pragma once

#include <functional>
#include <string_view>

struct TestCase {
	std::string_view name;
	std::function<bool()> test;
};