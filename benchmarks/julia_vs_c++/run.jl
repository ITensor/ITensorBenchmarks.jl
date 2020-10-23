using Pkg
Pkg.activate(".")

using ITensors
using LinearAlgebra
using ArgParse
using DelimitedFiles

benchmarks = readdir(@__DIR__)
benchmarks = filter!(file -> startswith(file, "bench_"),
                     benchmarks)
benchmarks .= replace.(benchmarks, "bench_" => "")

settings = ArgParseSettings()
@add_arg_table! settings begin
  "--blas_num_threads"
    help = "Number of BLAS threads."
    arg_type = Int
    default = 1
  "--omp_num_threads"
    help = "Number of OpenMP threads (for block sparse contractions)."
    arg_type = Int
    default = 1
  "--which_version"
    help = "Which version to run. Options are \"c++\" or \"julia\". If nothing is specified, both are run."
    arg_type = Union{Nothing, String}
    default = nothing
  "--benchmarks"
    help = "Which benchmarks to run. If nothing is specified, all are run."
    nargs = '+'
    arg_type = String
    default = benchmarks
end

args = parse_args(settings)

blas_num_threads = args["blas_num_threads"]
omp_num_threads = args["omp_num_threads"]
which_version = args["which_version"]
benchmarks = args["benchmarks"]

println()
print("Using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println()
println("Benchmarking $benchmarks")
println()

maxdims = Dict{String, StepRange{Int64, Int64}}()

# Defaults
maxdims["ctmrg"] = 50:50:400
maxdims["dmrg_1d"] = 50:50:350
maxdims["dmrg_1d_qns"] = 200:200:1_000
maxdims["dmrg_2d_conserve_ky"] = 1_000:1_000:5_000
maxdims["dmrg_2d_qns"] = 200:200:1_000
maxdims["trg"] = 10:10:50

# Testing
maxdims["ctmrg"] = 50:50:100
maxdims["dmrg_1d"] = 50:50:100
maxdims["dmrg_1d_qns"] = 200:200:400
maxdims["dmrg_2d_conserve_ky"] = 1_000:1_000:2_000
maxdims["dmrg_2d_qns"] = 200:200:400
maxdims["trg"] = 10:10:20

println("Running for bond dimensions $maxdims")

seperator = "#"^70

outputlevel = 1

for benchmark in benchmarks
  println("Running benchmark $benchmark for bond dimensions $(maxdims[benchmark])")
  for maxdim in maxdims[benchmark]
    if isnothing(which_version) || which_version == "julia"
      julia_dir = joinpath(@__DIR__, "bench_$benchmark", "julia")

      println(seperator)
      println("Run Julia benchmark $benchmark.")
      println()
      println("Benchmark located in path $julia_dir")
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
    if isnothing(which_version) || which_version == "c++"
      cpp_dir = joinpath(@__DIR__, "bench_$benchmark", "c++")

      println(seperator)
      println("Run C++ benchmark $benchmark.")
      println()
      println("Benchmark located in path $cpp_dir")
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

