module httparsed.intrinsics;

version(LDC)
{
    public import core.simd;
    public import ldc.intrinsics;
    import ldc.gccbuiltins_x86;

    enum LDC_with_SSE42 = __traits(targetHasFeature, "sse4.2");

    // These specify the type of data that we're comparing.
    enum _SIDD_UBYTE_OPS            = 0x00;
    enum _SIDD_UWORD_OPS            = 0x01;
    enum _SIDD_SBYTE_OPS            = 0x02;
    enum _SIDD_SWORD_OPS            = 0x03;

    // These specify the type of comparison operation.
    enum _SIDD_CMP_EQUAL_ANY        = 0x00;
    enum _SIDD_CMP_RANGES           = 0x04;
    enum _SIDD_CMP_EQUAL_EACH       = 0x08;
    enum _SIDD_CMP_EQUAL_ORDERED    = 0x0c;

    // These are used in _mm_cmpXstri() to specify the return.
    enum _SIDD_LEAST_SIGNIFICANT    = 0x00;
    enum _SIDD_MOST_SIGNIFICANT     = 0x40;

    // These macros are used in _mm_cmpXstri() to specify the return.
    enum _SIDD_BIT_MASK             = 0x00;
    enum _SIDD_UNIT_MASK            = 0x40;

    // some definition aliases to commonly used names
    alias __m128i = int4;

    // some used methods aliases
    alias _expect = llvm_expect;
    alias _mm_loadu_si128 = loadUnaligned!__m128i;
    alias _mm_cmpestri = __builtin_ia32_pcmpestri128;
}
else
{
    enum LDC_with_SSE42 = false;

    T _expect(T)(T val, T expected_val) if (__traits(isIntegral, T))
    {
        pragma(inline, true);
        return val;
    }
}

pragma(msg, "SSE: ", LDC_with_SSE42);
