#pragma once

namespace navigator {

enum class RouteState {
    invalid,
    initialized,
    tracking,
    complete,
    offRoute
};

} // namespace navigator
