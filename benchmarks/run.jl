using Pkg
Pkg.activate(".")

using LinearAlgebra
using ArgParse

benchmarks = readdir(@__DIR__)
benchmarks = filter!(file -> startswith(file, "bench_"),
                     benchmarks)
benchmarks .= replace.(benchmarks, "bench_" => "")

settings = ArgParseSettings()
@add_arg_table! settings begin
  "--which_version"
    help = "Which version to run."
    arg_type = Union{Nothing, String}
    default = nothing
  "--benchmarks"
    help = "Which benchmarks to run."
    nargs = '+'
    arg_type = String
    default = benchmarks
  "--blas_num_threads"
    help = "Number of BLAS threads."
    arg_type = Int
    default = 1
end

args = parse_args(settings)

blas_num_threads = args["blas_num_threads"]
which_version = args["which_version"]
benchmarks = args["benchmarks"]

print("Using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println()
println("Benchmarking $benchmarks")
println()

seperator = "#"^70

for benchmark in benchmarks
  if isnothing(which_version) || which_version == "julia"
    julia_dir = joinpath(@__DIR__, "bench_$benchmark", "julia")

    println(seperator)
    println("Run Julia benchmark $benchmark in path $julia_dir")

    # Set number of threads for Julia to 1
    BLAS.set_num_threads(blas_num_threads)

    println()
    Pkg.activate(julia_dir)
    println()

    include(joinpath(julia_dir, "run.jl"))

    println()
    Pkg.activate()
    println()
  end

  if isnothing(which_version) || which_version == "c++"
    cpp_dir = joinpath(@__DIR__, "bench_$benchmark", "c++")

    println(seperator)
    println("Run C++ benchmark $benchmark in path $cpp_dir")
    println()

    cp("Makefile", joinpath(cpp_dir, "Makefile"); force = true)
    cd(cpp_dir)
    Base.run(`make`)
    println()
    open("run.sh", "w") do io
      write(io, """#!/bin/bash
                   MKL_NUM_THREADS=$blas_num_threads ./run""")
    end
    chmod("run.sh", 0o777)
    Base.run(`./run.sh`)
    rm("run.sh")
    cd(@__DIR__)
  end
end

