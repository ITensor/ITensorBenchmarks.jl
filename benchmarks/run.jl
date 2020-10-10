using LinearAlgebra

blas_num_threads = parse(Int, ARGS[1])

println("Using $blas_num_threads BLAS thread")

benchmarks = ["dmrg_1d"]

println()
println("Benchmarking $benchmarks")

for benchmark in benchmarks
  # Set number of threads for Julia to 1
  BLAS.set_num_threads(blas_num_threads)

  start_dir = pwd()

  julia_dir = joinpath(start_dir, "bench_$benchmark", "julia")
  cpp_dir = joinpath(start_dir, "bench_$benchmark", "c++")

  println()
  println("Run Julia benchmark $benchmark in path $julia_dir")

  Pkg.activate(julia_dir)
  include(joinpath(julia_dir, "run.jl"))
  Pkg.activate()

  println()
  println("Run C++ benchmark $benchmark in path $cpp_dir")

  cp("Makefile", joinpath(cpp_dir, "Makefile"); force = true)
  cd(cpp_dir)
  open("run.sh", "w") do io
    write(io, """#!/bin/bash
                 make
                 MKL_NUM_THREADS=$blas_num_threads ./run""")
  end
  chmod("run.sh", 0o777)
  Base.run(`./run.sh`)
  rm("run.sh")
  rm("Makefile")
  cd(start_dir)
end

