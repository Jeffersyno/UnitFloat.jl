# UnitFloat

A 64-bit software floating point number that only covers the unit interval
``[0, 1]``. It has the same precision as a single precision floating point
number (23 actual bits stored, 24 significant bits), but its exponent range is
much larger (41 bits, as opposed to 8 bits in single precision float).

## Quick introduction

```julia
using UnitFloat

a = UFloat(0.98)
b = UFloat(0.12f0)
a * b
a - b
b - a  # DomainError: cannot be represented as a UFloat
```

## Technical details

The *fraction* ``F`` is stored in the same way as in a single precision
floating point number (binary32, IEEE 754-2008):
```math
F = 1 + \sum_{i=1}^{23}{b_{23-i}2^{-i}}
```
with ``b_i`` the ``i``th bit, the 0th bit being the least significant bit,
and the 63rd bit being the most significant bit.

For the *exponent* ``E``, a bias of ``2^{41}`` is used as `UnitFloat` only
represents numbers between 0 and 1.

No *sign* bit is stored, because all numbers in ``[0, 1]`` are positive.

In conclusion, the decimal value of the float can be computed with the
following formula:
```math
\left( 1 + \frac{F}{2^{41}} \right) \times 2^{E - 2^{41}}
```
with ``F`` and ``E`` the fraction and the exponent respectively.

```
         |-----------------------------------------|----------------------|
         | Exponent (41 bits)                      | Fraction (23 bits)   |
         |-----------------------------------------|----------------------|
bit n°   |63                                     23|22                   0|
```

## What problems does it solve?

Repeatedly multiplying numbers between ``[0, 1]`` causes loss of precision after
a while. `UnitFloat` postpones this issue of loss of precision by its ability
to represent numbers much closer to zero than a regular `Float32` or even a
`Float64`.

More specifically:
```julia
nextfloat(0.0f0)       == 1.0f-45
nextfloat(0.0)         == 5.0e-324
nextfloat(UFloat(0.0)) == "???" // TODO complete and check
```

The smallest number greater than zero that can be expressed as a `UnitFloat`
is:
```math
1.0 \times 2.0^{-\left(2^{41}-1 \right)} \approx 3.08 \times 10^{-661971961084}
```


## Performance

### Numeric performance

`TODO demo`


### Throughput

`TODO addition, multiplication vs float32, float64 and BigFloat`
