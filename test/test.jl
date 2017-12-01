# > julia -L test/test.jl

using UnitFloat

a = UFloat(.24)
b = UFloat(.12)

v = UFloat.(rand((10000, 1)))
w = UFloat.(rand((10000, 1)))
