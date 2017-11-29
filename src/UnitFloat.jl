module UnitFloat

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

end # module
