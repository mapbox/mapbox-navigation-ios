#pragma once

#include "banner.hpp"
#include "route_state.hpp"
#include "voice_instruction.hpp"
#include <cstdint>
#include <experimental/optional>
#include <string>
#include <utility>

namespace navigator {

class NavigationStatus final {
public:
    RouteState routeState;
    float lat;
    float lon;
    float bearing;
    uint32_t routeIndex;
    uint32_t legIndex;
    float remainingLegDistance;
    uint32_t remainingLegDuration;
    uint32_t stepIndex;
    float remainingStepDistance;
    uint32_t remainingStepDuration;
    std::experimental::optional<VoiceInstruction> voiceInstruction;
    std::experimental::optional<Banner> bannerInstruction;
    std::string stateMessage;

    NavigationStatus(RouteState routeState_,
                     float lat_,
                     float lon_,
                     float bearing_,
                     uint32_t routeIndex_,
                     uint32_t legIndex_,
                     float remainingLegDistance_,
                     uint32_t remainingLegDuration_,
                     uint32_t stepIndex_,
                     float remainingStepDistance_,
                     uint32_t remainingStepDuration_,
                     std::experimental::optional<VoiceInstruction> voiceInstruction_,
                     std::experimental::optional<Banner> bannerInstruction_,
                     std::string stateMessage_)
    : routeState(std::move(routeState_))
    , lat(std::move(lat_))
    , lon(std::move(lon_))
    , bearing(std::move(bearing_))
    , routeIndex(std::move(routeIndex_))
    , legIndex(std::move(legIndex_))
    , remainingLegDistance(std::move(remainingLegDistance_))
    , remainingLegDuration(std::move(remainingLegDuration_))
    , stepIndex(std::move(stepIndex_))
    , remainingStepDistance(std::move(remainingStepDistance_))
    , remainingStepDuration(std::move(remainingStepDuration_))
    , voiceInstruction(std::move(voiceInstruction_))
    , bannerInstruction(std::move(bannerInstruction_))
    , stateMessage(std::move(stateMessage_))
    {}
};

} // namespace navigator
