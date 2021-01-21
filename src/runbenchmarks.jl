
runbenchmark(::Val{B}; kwargs...) where {B} =
  error("Benchmark $B not found")

function runbenchmarks(; write_results = OPTIONS["write_results"],
                         test = OPTIONS["test"],
                         blas_num_threads = OPTIONS["blas_num_threads"],
                         blocksparse_num_threads = OPTIONS["blocksparse_num_threads"],
                         maxdims = OPTIONS["maxdims"],
                         which_version = OPTIONS["which_version"],
                         benchmarks = OPTIONS["benchmarks"],
                         cpp_itensor_version = OPTIONS["cpp_itensor_version"],
                         julia_itensor_version = OPTIONS["julia_itensor_version"])
  if blocksparse_num_threads == 1
    ITensors.disable_threaded_blocksparse()
  elseif blocksparse_num_threads ≠ Threads.nthreads()
    error("Trying to benchmark with $blocksparse_num_threads number of threads for block sparse operations, but Julia was started with $(Threads.nthreads()) threads. Start Julia with `N` threads using `JULIA_NUM_THREADS=N julia`, `julia --threads=N`, or `julia -t N`.")
  end

  if blocksparse_num_threads > 1 && blas_num_threads > 1
    error("Trying to benchmark with $blocksparse_num_threads number of threads for block sparse operations and $blas_num_threads BLAS threads. This leads to conflicting ")
  end

  if julia_itensor_version ≠ ITensors.version()
    error("Attempting to benchmark with ITensors.jl v$julia_version, but the current version is v$(ITensors.version()). You should fix the ITensors.jl version by running `] add ITensors@0.1.32` at the Julia command prompt.")
  end

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

  println()
  println("Using Julia v$(VERSION)")

  println()
  println("Using ITensors.jl v$julia_itensor_version")

  println()
  println("Using C++ ITensor v$cpp_itensor_version")

  println()
  println("Julia is using BLAS vendor $(BLAS.vendor()). Please double check this is the same as the one you compile C++ ITensor against.")
  print("Using $blas_num_threads BLAS thread")
  blas_num_threads > 1 ? println("s") : println()
  BLAS.set_num_threads(blas_num_threads)

  # Disable Strided threads
  ITensors.Strided.disable_threads()

  println()
  println("Benchmarking $benchmarks")
  println()

  println("Bond dimensions set to:")
  display(maxdims)
  println()

  for benchmark in benchmarks
    println("Running benchmark $benchmark for bond dimensions $(maxdims[benchmark])")
    println()
    valbenchmark = Val(Symbol(benchmark))
    src_dir = joinpath(pkgdir(@__MODULE__), "src")
    data_dir = joinpath(pkgdir(@__MODULE__), "data")
    benchmark_dir = joinpath(src_dir, "bench_$benchmark")
    writepath = "bench_$benchmark"
    writepath = joinpath(writepath, "blas_num_threads_$(blas_num_threads)")
    writepath = joinpath(writepath, "blocksparse_num_threads_$(blocksparse_num_threads)")
    maxdims_benchmark = maxdims[benchmark]
    if test
      println("XXX TESTING: only running the first two sets of benchmarks")
      maxdims_benchmark = maxdims_benchmark[1:min(length(maxdims_benchmark), 2)]
      println("Test maxdims:")
      display(maxdims_benchmark)
      println()
    end
    for maxdim in maxdims_benchmark
      println("Benchmark located in path $benchmark_dir")
      println()
      println("Maximum bond dimension set to $maxdim.")
      println()
      println("BLAS number of threads set to $blas_num_threads.")
      println()
      println("Block sparse number of threads set to $blocksparse_num_threads.")
      println()
      if isnothing(which_version) || which_version == "julia"
        println(seperator)
        println("Run Julia benchmark $benchmark.")
        println()

        # Trigger compilation
        runbenchmark(valbenchmark; maxdim = 10, nsweeps = 2,
                     outputlevel = 0)

        time = @elapsed maxdim_ = runbenchmark(valbenchmark;
                                               maxdim = maxdim,
                                               outputlevel = outputlevel)

        println()
        println("Maximum dimension = $maxdim_")
        println("Total runtime = $time seconds")
        println()

        if write_results
          # XXX: how to include as a function of number of threads
          filepath = joinpath(data_dir, "julia")
          filepath = joinpath(filepath, "v$julia_itensor_version")
          filepath = joinpath(filepath, writepath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          println("Writing results to $filepath")
          println()
          mkpath(dirname(filepath))
          writedlm(filepath, time)
        end
      end
      if isnothing(which_version) || which_version == "c++"
        println(seperator)
        println("Run C++ benchmark $benchmark.")
        println()

        # Create the file itensor_dir.mk that has the directory where
        # the version of C++ ITensor lives
        cpp_itensor_dir = joinpath(pkgdir(@__MODULE__), "deps", "itensor_v$cpp_itensor_version")
        if !isdir(cpp_itensor_dir)
          error("Attempting to use ITensor v$cpp_itensor_version. This should be located in directory $cpp_itensor_dir. Download and compile C++ ITensor v$cpp_itensor_version using the direction in http://www.itensor.org/docs.cgi?page=install&vers=cppv3 (and check out the version with `git checkout v$cpp_itensor_version before building).")
        end
        open(joinpath(src_dir, "itensor_dir.mk"), "w") do io
          write(io, "LIBRARY_DIR=$cpp_itensor_dir")
        end
        # Generate the C++ function we will compile
        open(joinpath(src_dir, "runbenchmark.cc"), "w") do io
          cpp_file =
          """#include "$(joinpath("bench_$benchmark", "runbenchmark.h"))"
          int
          main(int argc, char *argv[])
            {
            auto maxdim = std::stoi(argv[1]);
            auto outputlevel = 0;
            if(argc > 2)
              outputlevel = std::stoi(argv[2]);
            auto maxdim_ = run({"Maxdim = ", maxdim,
                                "OutputLevel = ", outputlevel});
            return 0;
            }
          """
          write(io, cpp_file)
        end
        # Trigger rebuild
        println("Compile the benchmark")
        Base.run(`make --directory=$src_dir`)
        println()
        rm(joinpath(src_dir, "runbenchmark.cc"))
        runbenchmark_exec = joinpath(src_dir, "runbenchmark")
        open(joinpath(src_dir, "runbenchmark.sh"), "w") do io
          write(io, """#!/bin/bash
                       MKL_NUM_THREADS=$blas_num_threads OPENBLAS_NUM_THREADS=$blas_num_threads OMP_NUM_THREADS=$blocksparse_num_threads $runbenchmark_exec $maxdim $outputlevel""")
        end
        chmod(joinpath(src_dir, "runbenchmark.sh"), 0o777)
        time = @elapsed Base.run(`$(joinpath(src_dir, "runbenchmark.sh"))`)
        rm(joinpath(src_dir, "runbenchmark.sh"))

        println()
        println("Maximum dimension = $maxdim")
        println("Total runtime = $time seconds")
        println()

        if write_results
          # TODO: add version number to data file name
          filepath = joinpath(data_dir, "c++")
          filepath = joinpath(filepath, "v$cpp_itensor_version")
          filepath = joinpath(filepath, writepath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          println("Writing results to $filepath")
          println()
          mkpath(dirname(filepath))
          writedlm(filepath, time)
        end
      end
    end
  end
end

