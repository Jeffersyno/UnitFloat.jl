using UnitFloat
using Base.Test

N = 1000

# test edge cases for 0.0 and 1.0
@testset "edge_cases" begin

    for T in [Float32, Float64, BigFloat]
        @test zero(T) == T(zero(UFloat))
        @test one(T) == T(one(UFloat))
        @test significand(zero(T)) == significand(zero(UFloat))
        @test significand(one(T)) == significand(one(UFloat))
        @test exponent(one(T)) == exponent(one(UFloat))
        @test exponent(UFloat(1.0e-100)) == exponent(1.0e-100)
        @test_throws DomainError exponent(zero(UFloat))
    end

    @test zero(UFloat(1.2e-3)) == zero(UFloat)
    @test one(UFloat(1.2e-3)) == one(UFloat)
    @test UnitFloat._is_zero(zero(UFloat))
    @test UnitFloat._is_one(one(UFloat))
    @test UnitFloat._is_zero(0.0)
    @test UnitFloat._is_one(1.0)
    @test UnitFloat._is_zero(0.0f0)
    @test UnitFloat._is_one(1.0f0)
    @test typemin(UFloat) == zero(UFloat)
    @test typemax(UFloat) == one(UFloat)
    @test typemin(UFloat(1.2e-3)) == zero(UFloat)
    @test typemax(UFloat(1.2e-3)) == one(UFloat)
    @test isinf(zero(UFloat)) == false
    @test isfinite(zero(UFloat)) == true
    @test signbit(one(UFloat)) == false
    @test bits(zero(UFloat)) == "0000000000000000000000000000000000000000000000000000000000000000"
    @test bits(one(UFloat)) == "1111111111111111111111111111111111111111100000000000000000000000"
    @test bits(UFloat(1.24f-1)) == "1111111111111111111111111111111111" * bits(1.24f-1)[3:end]
                                #   "111101111111011111001110110110"
                                # "00111101111111011111001110110110" == bits(1.24f-1) -> discard sign bit of float and exponent
end

@testset "simple_show" begin
    buf = IOBuffer()
    show(buf, zero(UFloat));       print(buf, ";")
    show(buf, one(UFloat));        print(buf, ";")
    show(buf, UFloat(0.0783));     print(buf, ";")
    show(buf, UFloat(2.2523e-10)); print(buf, ";")
    show(buf, UFloat(1.0e-100));   print(buf, ";")
    show(buf, UFloat(1.0e-101))
    @test split(String(take!(buf)), ";") ==
        ["0.0uf",
         "1.0uf",
         "7.83000uf-2",
         "2.25230uf-10",
         "1.00000uf-100",
         "1.00000uf-101"]
end

# significand and exponent
@testset "significand_exponent" begin
    rng = MersenneTwister(0)

    for order in 0:-1:-126
        f0 = ldexp.(rand(rng, Float32, (N, 1)), order)
        f1 = UFloat.(f0)
        @test exponent.(f0) == exponent.(f1) # care with zero! DomainError
        @test significand.(f0) == significand.(f1)
    end
end

# conversions Float32->UFloat->Float32 must be exact
@testset "conversion_f32_uf_f32" begin
    rng = MersenneTwister(1)

    for order in 0:-1:-126
        f0 = ldexp.(rand(rng, Float32, (N, 1)), order)
        f1 = Float32.(UFloat.(f0))
        @test f0 == f1
    end
end

# conversions from Float64->UFloat->Float64 should affect the significand in
# the same way as a Float64->Float32->Float64 conversion and should leave the
# exponent unchanged
@testset "conversion_f64_uf_f64" begin
    rng = MersenneTwister(2)

    for order in 0:-1:-1022
        f0 = ldexp.(rand(rng, Float64, (N, 1)), order)
        f1 = UFloat.(f0)

        @test exponent.(f0) == exponent.(f1)
        @test Float32.(significand.(f0)) == significand.(f1)
    end
end

# conversion Bool->UFloat->Bool
@testset "conversion_bool_uf_bool" begin
    @test UFloat(true) == one(UFloat)
    @test UFloat(false) == zero(UFloat)
    @test true == Bool(one(UFloat))
    @test false == Bool(zero(UFloat))
end

# multiplication in UFloat must produce same results as multiplication in
# Float32 (considering limited dynamic range of Float32)
@testset "multiplication" begin
    rng = MersenneTwister(3)
    order = 0:-1:-60

    for _ in 1:100
        f0 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f1 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f2 = f0 .* f1
        f3 = Float32.(UFloat.(f0) .* UFloat.(f1))

        @test f2 == f3
    end
end

# edge cases for multiplication
@testset "multiplication_edge" begin
    @test UFloat(0.0) * UFloat(0.234) == zero(UFloat)
    @test UFloat(1.0) * UFloat(0.234) == UFloat(0.234)
    @test UFloat(1.0e-50) * UFloat(0.234) == UFloat(0.234e-50)

    # convergence to zero
    @test begin
        v = UFloat(1e-10)
        for _ in 1:45
            v = v*v
        end
        v == zero(UFloat)
    end
end

# addition for ufloat compared to float32, must be same result in [0,1]
# interval.
@testset "addition" begin
    rng = MersenneTwister(4)
    order = -1:-1:-60

    for _ in 1:100
        f0 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f1 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f2 = f0 .+ f1
        f3 = Float32.(UFloat.(f0) .+ UFloat.(f1))

        @test f2 == f3
    end
end

# edge cases for addition
@testset "addition_edge" begin
    @test UFloat(0.5) + UFloat(0.6) == one(UFloat)
    @test UFloat(1.0) + UFloat(0.00099) == one(UFloat)
    @test UFloat(1.0) + UFloat(1.0) == one(UFloat)
    @test UFloat(0.0) + UFloat(0.0) == zero(UFloat)
    @test UFloat(0.0) + 0.0 == zero(UFloat)
    @test UFloat(0.0) + 0.0f0 == zero(UFloat)
    @test 0.0 + UFloat(0.0) == zero(UFloat)
    @test 0.0f0 + UFloat(0.0) == zero(UFloat)

    # convergence to one
    @test begin
        v = UFloat(1.23e-3)
        for _ in 1:1000
            v += v
        end
        v == one(UFloat)
    end
end

@testset "isless" begin
    rng = MersenneTwister(4)
    order = -1:-1:-60

    for _ in 1:100
        f0 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f1 = ldexp.(rand(rng, Float32, (N, 1)), rand(rng, order))
        f2 = f0 .< f1
        f31 = f0 .< UFloat.(f1)
        f32 = UFloat.(f0) .< f1
        f41 = Float64.(f0) .< UFloat.(f1)
        f42 = UFloat.(f0) .< Float64.(f1)
        f5 = UFloat.(f0) .< UFloat.(f1)

        @test f2 == f31 == f32 == f41 == f42 == f5
    end
end

@testset "isless_edge" begin
    @test !(zero(UFloat) < zero(UFloat))
    @test !(one(UFloat) < one(UFloat))
    @test zero(UFloat) < one(UFloat)
    @test !(one(UFloat) < zero(UFloat))
    @test !(one(UFloat) < UFloat(.33))
    @test zero(UFloat) < UFloat(.33)
end
