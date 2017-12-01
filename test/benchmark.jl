using UnitFloat

const M = 300
const N = 100000

function bench_mult_ufloat(M::Int, N::Int)
    x = UFloat.(rand(Float32, (N, 1)))
    y = UFloat.(rand(Float32, (N, 1)))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] * y[i]
    end
end

function bench_mult_float32(M::Int, N::Int)
    x = rand(Float32, (N, 1))
    y = rand(Float32, (N, 1))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] * y[i]
    end
end

function bench_mult_float64(M::Int, N::Int)
    x = rand(Float64, (N, 1))
    y = rand(Float64, (N, 1))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] * y[i]
    end
end

function bench_mult_bfloat(M::Int, N::Int)
    x = BigFloat.(rand(Float64, (N, 1)))
    y = BigFloat.(rand(Float64, (N, 1)))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] * y[i]
    end
end

function bench_add_ufloat(M::Int, N::Int)
    x = UFloat.(rand(Float32, (N, 1)))
    y = UFloat.(rand(Float32, (N, 1)))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] + y[i]
    end
end

function bench_add_float32(M::Int, N::Int)
    x = rand(Float32, (N, 1))
    y = rand(Float32, (N, 1))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] + y[i]
    end
end

function bench_add_float64(M::Int, N::Int)
    x = rand(Float64, (N, 1))
    y = rand(Float64, (N, 1))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] + y[i]
    end
end

function bench_add_bfloat(M::Int, N::Int)
    x = BigFloat.(rand(Float64, (N, 1)))
    y = BigFloat.(rand(Float64, (N, 1)))
    @elapsed for _ in 1:M, i in 1:N
        x[i] = x[i] + y[i]
    end
end

println("Results for multiplication ($M runs of $N):")
println(" - UFloat:   $(bench_mult_ufloat(M, N) / M)")
println(" - Float32:  $(bench_mult_float32(M, N) / M)")
println(" - Float64:  $(bench_mult_float64(M, N) / M)")
println(" - BigFloat: $(bench_mult_bfloat(M, N) / M)")

println("Results for addition ($M runs of $N):")
println(" - UFloat:   $(bench_add_ufloat(M, N) / M)")
println(" - Float32:  $(bench_add_float32(M, N) / M)")
println(" - Float64:  $(bench_add_float64(M, N) / M)")
println(" - BigFloat: $(bench_add_bfloat(M, N) / M)")
