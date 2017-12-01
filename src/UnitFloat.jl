__precompile__()

module UnitFloat

import Base:
    +,
    *,
    bits,
    convert,
    exponent,
    one,
    show,
    signbit,
    significand,
    typemax,
    typemin,
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
bit no   |63                                     23|22                   0|
```
"""
primitive type UFloat 64 end # TODO can we extend AbstractFloat, like BigFloat?

"""
    _UFloat

Construct a `UFloat` given the exponent and the fraction. The exponent must be
strictly negative and >= `-2^41`. Only the last 23 bits of the given fraction
are used.
"""
@inline function _UFloat(exponent::Int64, fraction::Float32)
    bits = UInt64(reinterpret(UInt32, fraction)) & 0x00000000007fffff # ~UInt(0) >> 41
    bits |= ~reinterpret(UInt64, -exponent) << 23
    reinterpret(UFloat, bits)
end

@inline is_zero(u::UFloat)   = u == zero(UFloat)
@inline is_one(u::UFloat)    = u == one(UFloat)

@inline zero(::Type{UFloat}) = reinterpret(UFloat, 0x0000000000000000)
@inline one(::Type{UFloat})  = reinterpret(UFloat, 0xffffffffff800000)
zero(::UFloat) = zero(UFloat)
one(::UFloat) = one(UFloat)
typemin(::UFloat) = zero(UFloat)
typemax(::UFloat) = one(UFloat)

bits(u::UFloat) = bits(reinterpret(UInt64, u))
signbit(u::UFloat) = false

@inline function _exponent_unsafe(u::UFloat)
    # gives incorrect results for zero(UFloat) and one(UFloat)
    -reinterpret(Int64, ~reinterpret(UInt64, u) >> 23)
end

function exponent(u::UFloat)
    is_zero(u) && throw(DomainError())
    _exponent_unsafe(u)
end

@inline function _significand_unsafe(u::UFloat)
    # incorrect for zero(UFloat) and one(UFloat)
    bits = UInt32((reinterpret(UInt64, u) & 0x00000000007fffff)) # zero first 41 bits
    bits |= 0x3f800000 # add zero exponent to Float32
    reinterpret(Float32, bits)
end

function significand(u::UFloat)
    is_zero(u) && return 0.0f0
    is_one(u) && return 1.0f0
    _significand_unsafe(u)
end

function convert(::Type{UFloat}, f::F) where {F<:AbstractFloat}
    f < zero(F) && throw(InexactError())
    f == zero(F) && return zero(UFloat)
    f == one(F) && return one(UFloat) # one special case because exponent==0
    exp, frac = exponent(f), significand(f)
    exp >= 0 && throw(InexactError())
    _UFloat(exp, Float32(frac))
end

function convert(::Type{F}, u::UFloat) where {F<:AbstractFloat}
    is_zero(u) && return zero(F)
    is_one(u) && return one(F)
    frac = _significand_unsafe(u)
    exp = _exponent_unsafe(u)
    ldexp(F(frac), exp)
end

###############################################################################


function *(a::UFloat, b::UFloat)::UFloat
    sa = _significand_unsafe(a)
    sb = _significand_unsafe(b)
    ea = _exponent_unsafe(a)
    eb = _exponent_unsafe(b)

    sn = sa * sb
    en = ea + eb + exponent(sn) # cannot be <= 1<<41

    en > -2199023255552 ? _UFloat(en, sn) : zero(UFloat)
end

function +(a::UFloat, b::UFloat)::UFloat
    sa = _significand_unsafe(a)
    sb = _significand_unsafe(b)
    ea = _exponent_unsafe(a)
    eb = _exponent_unsafe(b)

    ed = ea - eb

    sn = sb + ldexp(sa, ed)
    en = eb + exponent(sn)

    if en == 0
        sn = 0.0f0
    end

    _UFloat(en, sn)
end


###############################################################################

function show(io::IO, u::UFloat)
    if is_zero(u)
        print(io, "0.0uf")
    elseif is_one(u)
        print(io, "1.0uf")
    else
        # represent the number as a×10^b, with b int
        e2 = exponent(u)
        e10 = e2 * log10(2.0)
        e10i = round(e10)
        e10r = e10 - e10i
        s = Float32(significand(u) * exp10(e10r))
        while round(s, 5) >= 10.0f0
            s /= 10.0f0; e10i += 1
        end
        while round(s, 5) < 1.0f0
            s *= 10.0f0; e10i -= 1
        end
        @printf(io, "%.5fuf%d", s, e10i)
    end
end

end # module
