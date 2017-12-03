# UnitFloat.jl

A 64-bit floating point number implementation for the unit interval. A
`UnitFloat` has the same precision as a 32-bit single precision floating point
number but has a much larger dynamic range.

The 64 bits are divided as follows:

+   The first 41 bits store the *exponent*. The bias is `1<<42 - 1`. This means
    that only negative exponents can be used (including 0).
+   The last 23 bits are used for the *fraction* or *significand*. Just like
    single precision floats, there are 24 significant bits. The first bit is
    taken to be one and is not stored. This means that the *fraction* is a
    number in the interval `[1, 2)`.

There is no sign bit, as only the unit interval is covered.

## Initial use-case

When assigning probabilities to possible solutions in a large search space
(e.g. paths in a Markov chain graph), the probabilities quickly become very
small. To resolve the issue where very small probabilities become zero,
sometimes the logartihm of the probabilities is used. When working with
logarithms of probabilities, it becomes hard to perform additions. `UnitFloat`
attempts to resolve this issue.
