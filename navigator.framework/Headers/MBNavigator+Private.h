#include <memory>

static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBNavigator;

namespace navigator {
class Navigator;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct Navigator {
    using CppType = std::shared_ptr<::navigator::Navigator>;
    using ObjcType = MBNavigator * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
