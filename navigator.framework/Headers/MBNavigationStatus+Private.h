static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBNavigationStatus;

namespace navigator {
class NavigationStatus;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct NavigationStatus {
    using CppType = ::navigator::NavigationStatus;
    using ObjcType = MBNavigationStatus * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
