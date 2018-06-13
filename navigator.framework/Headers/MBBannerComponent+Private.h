static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBBannerComponent;

namespace navigator {
class BannerComponent;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct BannerComponent {
    using CppType = ::navigator::BannerComponent;
    using ObjcType = MBBannerComponent * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
