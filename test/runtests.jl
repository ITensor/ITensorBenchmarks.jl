using ITensorsBenchmarks

@testset "runbenchmarks" begin
  runbenchmarks(stdout; benchmarks = ["trg", "ctmrg", "dmrg_1d"], test = 1:2, blas_num_threads = 1:2)
end

