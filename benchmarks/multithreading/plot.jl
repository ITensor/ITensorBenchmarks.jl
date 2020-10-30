using Plots
using DelimitedFiles

include("options.jl")

print("Plotting results using $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println("Plotting results using $omp_num_threads OpenBLAS threads")
println("Maximum DMRG bond dimension is set to $maxdim.")

seperator = "#"^70

times = Float64[]

filename_suffix_maxdim = "_maxdim_$(maxdim)"

N = length(omp_num_threads)
for j in 1:N
  omp_num_thread = omp_num_threads[j]
  println(seperator)
  println("Plot C++ benchmark in path $(@__DIR__) with $omp_num_thread OpenMP threads.")
  println()

  # Printing results
  # TODO: add version number to data file name
  filename_suffix = filename_suffix_maxdim *
                    "_omp_num_threads_$(omp_num_thread)"

  filename = joinpath(@__DIR__, "data",
                      "data" * filename_suffix * ".txt")

  println("Reading results from $filename")
  println()
  time = readdlm(filename)[]
  push!(times, time)
end

title = "DMRG, 2D Hubbard model\n"
title *= "Hybrid real and momentum space\n"
title *= "Nx, Ny = $Nx, $Ny\n"
title *= "U = $U, maxdim = $maxdim"

speedup_ratio = times[1] ./ times

p = plot(omp_num_threads, speedup_ratio;
         title = title,
         legendfontsize = 14,
         xlabel = "n (number of OpenMP threads)",
         ylabel = "Speedup ratio time₁/timeₙ",
         xtickfontsize = 14,
         ytickfontsize = 14,
         xguidefontsize = 14,
         yguidefontsize = 14,
         line = (:solid, 4),
         marker = (:dot, 8),
         legend = :bottomright,
         label = "Actual C++")

# Plot the ideal speedup ratio
max_ratio = Int(round(maximum(speedup_ratio), RoundUp))
plot!(p, 1:max_ratio, 1:max_ratio;
      line = (:solid, 4),
      label = "Ideal")

savefig(p, joinpath(@__DIR__, "plots",
                    "plot" * filename_suffix_maxdim * ".png"))

