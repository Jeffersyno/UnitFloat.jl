module UnitFloat

import Base:
    show, exponent, significand, bits

"""
    UFloat

The 64-bit type storing the *fraction* and the *exponent* of the unit-interval
floating point number.
```
         |-----------------------------------------|----------------------|
         | Exponent (41 bits)                      | Fraction (23 bits)   |
         |-----------------------------------------|----------------------|
bit n°   |63                                     23|22                   0|
```
"""
primitive type UFloat 64 end # TODO can we extend AbstractFloat, like BigFloat?

"""
    _UFloat

Construct a `UFloat` given the exponent and the fraction. The exponent must be
strictly negative and >= `-2^41`. Only the last 23 bits of the given fraction
are used.
"""
function _UFloat(exponent::Int64, fraction::Float32)
    bits = UInt64(reinterpret(UInt32, fraction)) & 0x00000000007fffff # ~UInt(0) >> 41
    bits |= reinterpret(UInt64, exponent) << 23 # we use 2-complement bits
    reinterpret(UFloat, bits)
end

bits(f::UFloat) = bits(reinterpret(UInt64, f))
exponent(f::UFloat) = reinterpret(Int64, f) >> 23
significand(f::UFloat) = begin
    bits = UInt32((reinterpret(UInt64, f) & 0x00000000007fffff)) # zero first 41 bits
    bits |= 0x3f800000 # add zero exponent to Float32
    reinterpret(Float32, bits)
end

end # module
