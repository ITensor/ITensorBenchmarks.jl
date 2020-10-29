using Plots
using DelimitedFiles

include("options.jl")

println()
print("Plotting results for $blas_num_threads BLAS thread")
blas_num_threads > 1 ? println("s") : println()

println()
println("Plotting results for $benchmarks")
println()

println("Plotting results for dimensions set to:")
display(maxdims)
println()

seperator = "#"^70

outputlevel = 1

for benchmark in benchmarks
  println("Plotting benchmark $benchmark for bond dimensions $(maxdims[benchmark])")
  println()

  #N = length(maxdims[benchmark])
  times_julia = Float64[]
  times_cpp = Float64[]

  for maxdim in maxdims[benchmark]
    if isnothing(which_version) || which_version == "julia"
      julia_dir = joinpath(@__DIR__, "bench_$benchmark", "julia")
      filename = "data_blas_num_threads_$(blas_num_threads)"
      filename *= "_maxdim_$(maxdim).txt"
      filepath = joinpath(julia_dir, "data", filename)
      time = readdlm(filepath)[]
      push!(times_julia, time)
    end
    if isnothing(which_version) || which_version == "c++"
      cpp_dir = joinpath(@__DIR__, "bench_$benchmark", "c++")
      filename = "data_blas_num_threads_$(blas_num_threads)"
      filename *= "_maxdim_$(maxdim).txt"
      filepath = joinpath(cpp_dir, "data", filename)
      time = readdlm(filepath)[]
      push!(times_cpp, time)
    end
  end
  p = plot(maxdims[benchmark], times_julia;
           title = descriptions[benchmark],
           legendfontsize = 14,
           xlabel = "Maximum bond dimension",
           ylabel = "Computation time (seconds)",
           xtickfontsize = 14,
           ytickfontsize = 14,
           xguidefontsize = 14,
           yguidefontsize = 14,
           line = (:solid, 4),
           marker = (:dot, 8),
           legend = :topleft,
           label = "Julia")
  plot!(p, maxdims[benchmark], times_cpp;
        line = (:solid, 4),
        marker = (:dot, 8),
        label = "C++")
  filename = "plot_blas_num_threads_$(blas_num_threads)"
  filename *= "_$benchmark.png"
  savefig(p, joinpath("plots", filename))
end

