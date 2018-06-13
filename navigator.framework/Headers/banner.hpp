#pragma once

#include "banner_section.hpp"
#include <experimental/optional>
#include <utility>

namespace navigator {

class Banner final {
public:
    BannerSection primary;
    BannerSection secondary;
    std::experimental::optional<BannerSection> sub;

    Banner(BannerSection primary_,
           BannerSection secondary_,
           std::experimental::optional<BannerSection> sub_)
    : primary(std::move(primary_))
    , secondary(std::move(secondary_))
    , sub(std::move(sub_))
    {}
};

} // namespace navigator
