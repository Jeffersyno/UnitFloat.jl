__precompile__()

module UnitFloat

import Base:
    +,
    -,
    *,
    bits,
    convert,
    exponent,
    isfinite,
    isinf,
    isless,
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

@inline _is_zero(x)   = x == zero(typeof(x))
@inline _is_one(x)    = x == one(typeof(x))

@inline zero(::Type{UFloat}) = reinterpret(UFloat, 0x0000000000000000)
@inline one(::Type{UFloat})  = reinterpret(UFloat, 0xffffffffff800000)
zero(::UFloat) = zero(UFloat)
one(::UFloat) = one(UFloat)
typemin(::Type{UFloat}) = zero(UFloat)
typemax(::Type{UFloat}) = one(UFloat)
typemin(::UFloat) = zero(UFloat)
typemax(::UFloat) = one(UFloat)
isinf(::UFloat) = false
isfinite(::UFloat) = true

bits(u::UFloat) = bits(reinterpret(UInt64, u))
signbit(u::UFloat) = false

@inline function _exponent_unsafe(u::UFloat)
    # gives incorrect results for zero(UFloat) and one(UFloat)
    -reinterpret(Int64, ~reinterpret(UInt64, u) >> 23)
end
@inline function _exponent_unsafe(f::Float32) 
    Int64((reinterpret(UInt32, f) & 0x7f800000) >> 23) - 127
end
@inline function _exponent_unsafe(f::Float64)
    Int64((reinterpret(UInt64, f) & 0x7ff0000000000000) >> 52) - 1023
end

function exponent(u::UFloat)
    _is_zero(u) && throw(DomainError())
    _exponent_unsafe(u)
end

@inline function _significand_unsafe(u::UFloat)
    # incorrect for zero(UFloat) and one(UFloat)
    bits = UInt32((reinterpret(UInt64, u) & 0x00000000007fffff)) # zero first 41 bits
    bits |= 0x3f800000 # add zero exponent to Float32
    reinterpret(Float32, bits)
end
@inline function _significand_unsafe(f::Float32)
    reinterpret(Float32, (reinterpret(UInt32, f) & 0x007fffff) | 0x3f800000)
end
@inline function _significand_unsafe(f::Float64)
    _significand_unsafe(Float32(f))
end

function significand(u::UFloat)
    _is_zero(u) && return 0.0f0
    _is_one(u) && return 1.0f0
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
    _is_zero(u) && return zero(F)
    _is_one(u) && return one(F)
    frac = _significand_unsafe(u)
    exp = _exponent_unsafe(u)
    ldexp(F(frac), exp)
end

convert(::Type{UFloat}, b::Bool) = b ? one(UFloat) : zero(UFloat)
convert(::Type{Bool}, u::UFloat) = u == one(UFloat)

###############################################################################


function _multiply(a, b)::UFloat
    sa = _significand_unsafe(a)
    sb = _significand_unsafe(b)
    ea = _exponent_unsafe(a)
    eb = _exponent_unsafe(b)

    sn = sa * sb
    en = ea + eb + _exponent_unsafe(sn) # cannot be <= 1<<41

    en > -2199023255552 ? _UFloat(en, sn) : zero(UFloat)
end

@inline function _add(a, b)::UFloat
    _is_zero(a) && return UFloat(b)
    _is_zero(b) && return UFloat(a)

    sa = _significand_unsafe(a)
    sb = _significand_unsafe(b)
    ea = _exponent_unsafe(a)
    eb = _exponent_unsafe(b)

    ed = ea - eb

    sn = sb + ldexp(sa, ed)
    en = eb + _exponent_unsafe(sn)

    en >= 0 ? one(UFloat) : _UFloat(en, sn)
end

+(a::UFloat, b::UFloat) = _add(a, b)
*(a::UFloat, b::UFloat) = _multiply(a, b)
for T in [Float32, Float64], (op, fn) in [(:+, :_add), (:*, :_multiply)]
    @eval begin
        ($op)(a::UFloat, b::$T) = ($fn)(a, b)
        ($op)(a::$T, b::UFloat) = ($fn)(a, b)
    end
end


###############################################################################

@inline function _isless(a, b)::Bool
    a == one(typeof(a)) && return false
    b == one(typeof(b)) && return true # assumed a ≠ 1.0
    b == zero(typeof(b)) && return false
    a == zero(typeof(a)) && return true # assumed b ≠ 0.0

    ea = _exponent_unsafe(a)
    eb = _exponent_unsafe(b)

    ea < eb && return true
    ea > eb && return false

    # ea == eb
    sa = _significand_unsafe(a)
    sb = _significand_unsafe(b)

    sa < sb
end

isless(a::UFloat, b::UFloat) = _isless(a, b)

begin
    local T = [UFloat, Float32, Float64]
    for T1 in T, T2 in T
        if T1 != T2
            @eval begin
                isless(a::$T1, b::$T2) = _isless(a, b)
            end
        end
    end
end

###############################################################################

function show(io::IO, u::UFloat)
    if _is_zero(u)
        print(io, "0.0uf")
    elseif _is_one(u)
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
