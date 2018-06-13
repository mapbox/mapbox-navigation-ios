#pragma once

#include <cstdint>
#include <string>
#include <utility>

namespace navigator {

class BannerComponent final {
public:
    std::string text;
    std::string type;
    std::string abbr;
    uint32_t abbrPriority;
    std::string imageBaseurl;

    BannerComponent(std::string text_,
                    std::string type_,
                    std::string abbr_,
                    uint32_t abbrPriority_,
                    std::string imageBaseurl_)
    : text(std::move(text_))
    , type(std::move(type_))
    , abbr(std::move(abbr_))
    , abbrPriority(std::move(abbrPriority_))
    , imageBaseurl(std::move(imageBaseurl_))
    {}
};

} // namespace navigator
