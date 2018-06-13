static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBBannerSection;

namespace navigator {
class BannerSection;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct BannerSection {
    using CppType = ::navigator::BannerSection;
    using ObjcType = MBBannerSection * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
