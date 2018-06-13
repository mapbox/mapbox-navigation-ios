static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBFixLocation;

namespace navigator {
class FixLocation;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct FixLocation {
    using CppType = ::navigator::FixLocation;
    using ObjcType = MBFixLocation * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
