#pragma once

#include "banner_component.hpp"
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace navigator {

class BannerSection final {
public:
    std::string text;
    std::string type;
    std::string modifier;
    uint32_t degrees;
    std::string drivingSide;
    std::vector<BannerComponent> components;

    BannerSection(std::string text_,
                  std::string type_,
                  std::string modifier_,
                  uint32_t degrees_,
                  std::string drivingSide_,
                  std::vector<BannerComponent> components_)
    : text(std::move(text_))
    , type(std::move(type_))
    , modifier(std::move(modifier_))
    , degrees(std::move(degrees_))
    , drivingSide(std::move(drivingSide_))
    , components(std::move(components_))
    {}
};

} // namespace navigator
