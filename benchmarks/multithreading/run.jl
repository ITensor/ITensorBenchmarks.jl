using Pkg
Pkg.activate(".")

using ArgParse
using DelimitedFiles

function ArgParse.parse_item(T::Type{<: Union{Int, AbstractRange}}, x::AbstractString)
  r = eval(Meta.parse(x))
  @assert r isa T
  return r
end

settings = ArgParseSettings()
@add_arg_table! settings begin
  "--blas_num_threads"
    help = "Number of BLAS threads."
    arg_type = Int
    default = 1
  "--omp_num_threads"
    help = "Number of OpenMP threads (for block sparse contractions)."
    arg_type = Union{Int, AbstractRange}
    default = 1
end

args = parse_args(settings)

blas_num_threads = args["blas_num_threads"]
omp_num_threads = args["omp_num_threads"]

@show omp_num_threads

print("Using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println("Using $omp_num_threads OpenBLAS threads")

seperator = "#"^70

Base.run(`make`)

N = length(omp_num_threads)
data = zeros(Union{Int, Float64}, N, 2)
for j in 1:N
  omp_num_thread = omp_num_threads[j]
  println(seperator)
  println("Run C++ benchmark in path $(@__DIR__) with $omp_num_thread OpenMP threads.")
  println()

  open("run.sh", "w") do io
    write(io, """#!/bin/bash
                 MKL_NUM_THREADS=$blas_num_threads OMP_NUM_THREADS=$omp_num_thread ./run""")
  end
  chmod("run.sh", 0o777)
  time = @elapsed Base.run(`./run.sh`)
  data[j, 1] = omp_num_thread
  data[j, 2] = time
  rm("run.sh")
  @show time
  println()
end

# TODO: add version number to date file name
filename = joinpath(@__DIR__, "data.txt")
println("Writing results to $filename")
mkpath(dirname(filename))
writedlm(filename, data)

