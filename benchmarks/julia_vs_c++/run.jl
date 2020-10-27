using Pkg
Pkg.activate(".")

using ITensors
using LinearAlgebra
using DelimitedFiles

include("options.jl")

println()
print("Using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println()
println("Benchmarking $benchmarks")
println()

println("Bond dimensions set to:")
display(maxdims)
println()

warning_seperator = "X"^70

println()
println(warning_seperator)
if write_results
  println("XXX WARNING: benchmark results are set to be written to disk, may overwrite previous results")
else
  println("XXX WARNING: benchmark results are not set to be written to disk.")
end
println(warning_seperator)
println()

seperator = "#"^70

outputlevel = 1

for benchmark in benchmarks
  println("Running benchmark $benchmark for bond dimensions $(maxdims[benchmark])")
  println()
  for maxdim in maxdims[benchmark]
    if isnothing(which_version) || which_version == "julia"
      julia_dir = joinpath(@__DIR__, "bench_$benchmark", "julia")

      println(seperator)
      println("Run Julia benchmark $benchmark.")
      println()
      println("Benchmark located in path $julia_dir")
      println()
      println("Maximum bond dimension set to $maxdim.")
      println()

      BLAS.set_num_threads(blas_num_threads)

      include(joinpath(julia_dir, "run.jl"))

      # Trigger compilation
      run(maxdim = 10, nsweeps = 2, outputlevel = 0)

      time = @elapsed maxdim_ = run(maxdim = maxdim,
                                    outputlevel = outputlevel)

      println()
      println("Maximum dimension = $maxdim_")
      println("Total runtime = $time seconds")
      println()

      if write_results
        # TODO: add version number to data file name
        # v = Pkg.dependencies()[Base.UUID("9136182c-28ba-11e9-034c-db9fb085ebd5")].version
        # "$(v.major).$(v.minor).$(v.patch)"
      
        filename = "data_blas_num_threads_$(blas_num_threads)"
        filename *= "_maxdim_$(maxdim_).txt"
        filepath = joinpath(julia_dir, "data", filename)
        println("Writing results to $filepath")
        println()
        mkpath(dirname(filepath))
        writedlm(filepath, time)
      end
    end
    if isnothing(which_version) || which_version == "c++"
      cpp_dir = joinpath(@__DIR__, "bench_$benchmark", "c++")

      println(seperator)
      println("Run C++ benchmark $benchmark.")
      println()
      println("Benchmark located in path $cpp_dir")
      println()
      println("Maximum bond dimension set to $maxdim.")
      println()

      open("run.h", "w") do io
        write(io, "#include \"$(joinpath(cpp_dir, "run.h"))\"")
      end
      # Trigger rebuild
      touch("run.cc")
      println("Compile the benchmark")
      Base.run(`make`)
      println()
      rm("run.h")
      open("run.sh", "w") do io
        write(io, """#!/bin/bash
                     export MKL_NUM_THREADS=$blas_num_threads
                     export OPENBLAS_NUM_THREADS=$blas_num_threads
                     export OMP_NUM_THREADS=$omp_num_threads
                     ./run $maxdim $outputlevel""")
      end
      chmod("run.sh", 0o777)
      time = @elapsed Base.run(`./run.sh`)
      rm("run.sh")

      println()
      println("Maximum dimension = $maxdim")
      println("Total runtime = $time seconds")
      println()

      if write_results
        # TODO: add version number to data file name

        filename = "data_blas_num_threads_$(blas_num_threads)"
        filename *= "_maxdim_$(maxdim).txt"
        filepath = joinpath(cpp_dir, "data", filename)
        println("Writing results to $filepath")
        println()
        mkpath(dirname(filepath))
        writedlm(filepath, time)
      end
    end
  end
end

