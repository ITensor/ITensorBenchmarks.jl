
function plotbenchmarks(; write_results = OPTIONS["write_results"],
                          test = OPTIONS["test"],
                          blas_num_threads = OPTIONS["blas_num_threads"],
                          blocksparse_num_threads = OPTIONS["blocksparse_num_threads"],
                          maxdims = OPTIONS["maxdims"],
                          cpp_or_julia = OPTIONS["cpp_or_julia"],
                          descriptions = OPTIONS["descriptions"],
                          benchmarks = OPTIONS["benchmarks"],
                          cpp_itensor_version = OPTIONS["cpp_itensor_version"],
                          cpp_itensor_dir = OPTIONS["cpp_itensor_dir"],
                          julia_itensor_version = OPTIONS["julia_itensor_version"])
  println(stdout, "Plotting benchmarks with the following options:")
  @show write_results
  @show test
  @show blas_num_threads
  @show blocksparse_num_threads
  print(stdout, "maxdims = ")
  show(stdout, MIME("text/plain"), maxdims)
  println(stdout)
  @show cpp_or_julia
  @show benchmarks
  @show cpp_itensor_version
  @show julia_itensor_version
  println(stdout)

  data_dir = joinpath(pkgdir(@__MODULE__), "data")

  for benchmark in benchmarks
    println("Plotting benchmark $benchmark for bond dimensions $(maxdims[benchmark])")
    println()

    maxdims_benchmark = maxdims[benchmark]
    if test ≠ false
      maxdims_benchmark = maxdims_benchmark[test]
    end

    p = plot(; title = descriptions[benchmark],
             legend = :topleft,
             legendfontsize = 12,
             xlabel = "Maximum bond dimension",
             ylabel = "Computation time (seconds)",
             xtickfontsize = 14,
             ytickfontsize = 14,
             xguidefontsize = 14,
             yguidefontsize = 14)

    markers = [:circle, :rect, :star5, :diamond, :hexagon, :cross, :xcross, :utriangle, :dtriangle, :rtriangle, :ltriangle, :pentagon, :heptagon, :octagon, :star4, :star6, :star7, :star8, :vline, :hline, :+, :x]
    marker_ind = 1
    for blas_num_thread in blas_num_threads,
        blocksparse_num_thread in blocksparse_num_threads
      marker, marker_ind = iterate(markers, marker_ind)

      times_julia = Float64[]
      times_cpp = Float64[]

      for maxdim in maxdims_benchmark

        # Read the data
        datapath = "bench_$benchmark"
        datapath = joinpath(datapath, "blas_num_threads_$(blas_num_thread)")
        datapath = joinpath(datapath, "blocksparse_num_threads_$(blocksparse_num_thread)")
        if isnothing(cpp_or_julia) || cpp_or_julia == "julia"
          filepath = joinpath(data_dir, "julia")
          filepath = joinpath(filepath, "v$julia_itensor_version")
          filepath = joinpath(filepath, datapath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          time = readdlm(filepath)[]
          push!(times_julia, time)
        end
        if isnothing(cpp_or_julia) || cpp_or_julia == "c++"
          filepath = joinpath(data_dir, "c++")
          filepath = joinpath(filepath, "v$cpp_itensor_version")
          filepath = joinpath(filepath, datapath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          time = readdlm(filepath)[]
          push!(times_cpp, time)
        end
      end

      label_details = ""
      if length(blas_num_threads) > 1
        label_details *= ", $blas_num_thread BLAS threads"
      end
      if length(blocksparse_num_threads) > 1
        label_details *= ", $blocksparse_num_thread block sparse threads"
      end

      if isnothing(cpp_or_julia) || cpp_or_julia == "julia"
        plot!(p, maxdims_benchmark, times_julia;
              line = (:solid, 4),
              marker = (marker, 8),
              color = :blue,
              label = "Julia ITensor" * label_details)
      end
      if isnothing(cpp_or_julia) || cpp_or_julia == "c++"
        plot!(p, maxdims_benchmark, times_cpp;
              line = (:dash, 4),
              marker = (marker, 8),
              color = :red,
              label = "C++ ITensor" * label_details)
      end
    end
    filename = "plot_benchmark_$(benchmark)_maxdims_$(maxdims_benchmark)_blas_num_threads_$(blas_num_threads)_blocksparse_num_threads_$(blocksparse_num_threads).png"
    filepath = joinpath(pkgdir(@__MODULE__), "plots", filename)
    println(stdout, "Saving plot to $filepath")
    savefig(p, joinpath(pkgdir(@__MODULE__), "plots", filename))
  end
  return nothing
end
