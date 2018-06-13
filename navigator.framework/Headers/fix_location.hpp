#pragma once

#include <cstdint>
#include <experimental/optional>
#include <string>
#include <utility>

namespace navigator {

class FixLocation final {
public:
    float lat;
    float lon;
    std::experimental::optional<uint64_t> time;
    std::experimental::optional<float> speed;
    std::experimental::optional<float> bearing;
    std::experimental::optional<float> altitude;
    std::experimental::optional<float> accuracyHorizontal;
    std::experimental::optional<std::string> provider;

    FixLocation(float lat_,
                float lon_,
                std::experimental::optional<uint64_t> time_,
                std::experimental::optional<float> speed_,
                std::experimental::optional<float> bearing_,
                std::experimental::optional<float> altitude_,
                std::experimental::optional<float> accuracyHorizontal_,
                std::experimental::optional<std::string> provider_)
    : lat(std::move(lat_))
    , lon(std::move(lon_))
    , time(std::move(time_))
    , speed(std::move(speed_))
    , bearing(std::move(bearing_))
    , altitude(std::move(altitude_))
    , accuracyHorizontal(std::move(accuracyHorizontal_))
    , provider(std::move(provider_))
    {}
};

} // namespace navigator
