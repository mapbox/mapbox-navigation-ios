#include "route_state.hpp"
#include <mapbox/bindgen/objc/Marshal+Private.h>

#import "MBRouteState.h"

namespace mapbox {
namespace bindgen {

struct RouteState : public Enum<MBRouteState, ::navigator::RouteState> {};

} // namespace bindgen
} // namespace mapbox
