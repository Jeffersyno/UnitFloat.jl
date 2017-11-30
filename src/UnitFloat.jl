module UnitFloat

import Base:
    bits,
    convert,
    exponent,
    one,
    show,
    signbit,
    significand,
    zero

export UFloat

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

zero(::Type{UFloat}) = reinterpret(UFloat, zero(UInt64))
one(::Type{UFloat}) = reinterpret(UFloat, ~zero(UInt64))
zero(::UFloat) = zero(UFloat)
one(::UFloat) = one(UFloat)

bits(f::UFloat) = bits(reinterpret(UInt64, f))
signbit(f::UFloat) = false

"""
    exponent(UFloat) -> Int

Get the exponent of the normalized UFloat.
"""
function exponent(f::UFloat)
    f == zero(UFloat) && throw(DomainError())
    f == one(UFloat) && return 0
    reinterpret(Int64, f) >> 23
end

"""
    significand(UFloat) -> Float32

Return the fraction bits of the `UFloat` as a Float32. If not zero, a number
between `[1,2)` is returned. Else, zero is returned.
"""
function significand(f::UFloat)
    f == zero(UFloat) && return 0.0f0
    f == one(UFloat) && return 1.0f0
    bits = UInt32((reinterpret(UInt64, f) & 0x00000000007fffff)) # zero first 41 bits
    bits |= 0x3f800000 # add zero exponent to Float32
    reinterpret(Float32, bits)
end

"""
    convert(UFloat, AbstractFloat) -> UFloat

Convert any floating point number into a `UFloat`.
"""
function convert(::Type{UFloat}, f::F) where {F<:AbstractFloat}
    f < zero(F) && throw(InexactError())
    f == zero(F) && return zero(UFloat)
    f == one(F) && return one(UFloat) # one special case because exponent==0
    exp, frac = exponent(f), significand(f)
    exp >= 0 && throw(InexactError())
    _UFloat(exp, Float32(frac))
end

"""
    convert(AbstractFloat, UFloat) -> AbstractFloat

Convert a `UFloat` into another `AbstractFloat`.
"""
function convert(::Type{F}, f::UFloat) where {F<:AbstractFloat}
    f == zero(UFloat) && return zero(F)
    frac = significand(f)
    exp = exponent(f)
    ldexp(F(frac), exp)
end

end # module
