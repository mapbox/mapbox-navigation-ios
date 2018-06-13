#pragma once

#include <string>
#include <utility>

namespace navigator {

class VoiceInstruction final {
public:
    std::string ssmlAnnouncement;
    std::string announcement;

    VoiceInstruction(std::string ssmlAnnouncement_,
                     std::string announcement_)
    : ssmlAnnouncement(std::move(ssmlAnnouncement_))
    , announcement(std::move(announcement_))
    {}
};

} // namespace navigator
