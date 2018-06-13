static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBBanner;

namespace navigator {
class Banner;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct Banner {
    using CppType = ::navigator::Banner;
    using ObjcType = MBBanner * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
