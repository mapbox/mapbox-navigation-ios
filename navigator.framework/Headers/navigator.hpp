#pragma once

#include "fix_location.hpp"
#include "navigation_status.hpp"
#include <memory>
#include <string>

namespace navigator {

class NavigatorImpl;

class Navigator {
public:
    Navigator();
    ~Navigator();

    NavigationStatus setDirections(const std::string& directions);
    NavigationStatus onLocationChanged(const FixLocation& fixLocation);

private:
    std::unique_ptr<NavigatorImpl> impl;
};

} // namespace navigator
