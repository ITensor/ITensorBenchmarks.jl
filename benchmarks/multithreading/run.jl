using Pkg
Pkg.activate(".")

using DelimitedFiles

print("Using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println("Using $omp_num_threads OpenBLAS threads")
println("Maximum DMRG bond dimension is set to $maxdim.")

seperator = "#"^70

Base.run(`make`)

N = length(omp_num_threads)
for j in 1:N
  omp_num_thread = omp_num_threads[j]
  println(seperator)
  println("Run C++ benchmark in path $(@__DIR__) with $omp_num_thread OpenMP threads.")
  println()

  open("run.sh", "w") do io
    write(io, """#!/bin/bash
                 MKL_NUM_THREADS=$blas_num_threads OMP_NUM_THREADS=$omp_num_thread ./run $maxdim""")
  end
  chmod("run.sh", 0o777)
  time = @elapsed Base.run(`./run.sh`)
  rm("run.sh")
  @show time
  println()

  # Printing results
  # TODO: add version number to data file name
  filename = joinpath(@__DIR__, "data", "data_maxdim_$(maxdim)_omp_num_threads_$(omp_num_thread).txt")
  println("Writing results to $filename")
  mkpath(dirname(filename))
  writedlm(filename, time)
end

