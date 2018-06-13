static_assert(__has_feature(objc_arc), "ARC must be enabled for this file");

@class MBVoiceInstruction;

namespace navigator {
class VoiceInstruction;
} // namespace navigator

namespace mapbox {
namespace bindgen {

struct VoiceInstruction {
    using CppType = ::navigator::VoiceInstruction;
    using ObjcType = MBVoiceInstruction * _Nonnull;

    static ObjcType toObjc(const CppType&);
    static CppType toCpp(ObjcType);
};

} // namespace bindgen
} // namespace mapbox
