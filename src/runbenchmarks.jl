
runbenchmark(::Val{B}; kwargs...) where {B} =
  error("Benchmark $B not found")

# If you call runbenchmarks(stdout; kwargs...) it outputs to the console
function runbenchmarks(io; write_results = OPTIONS["write_results"],
                           test = OPTIONS["test"],
                           blas_num_threads = OPTIONS["blas_num_threads"],
                           blocksparse_num_threads = OPTIONS["blocksparse_num_threads"],
                           maxdims = OPTIONS["maxdims"],
                           cpp_or_julia = OPTIONS["cpp_or_julia"],
                           benchmarks = OPTIONS["benchmarks"],
                           cpp_itensor_version = OPTIONS["cpp_itensor_version"],
                           cpp_itensor_dir = OPTIONS["cpp_itensor_dir"],
                           julia_itensor_version = OPTIONS["julia_itensor_version"],
                           splitblocks = OPTIONS["splitblocks"])
  println(stdout, "Running benchmark with the following options:")
  if io == stdout
    println(stdout, "io = stdout")
  else
    @show io
  end
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
  @show splitblocks
  println(stdout)

  if julia_itensor_version ≠ ITensors.version()
    error("Attempting to benchmark with ITensors.jl v$julia_version, but the current version is v$(ITensors.version()). You should fix the ITensors.jl version by running `] add ITensors@$julia_version` at the Julia command prompt.")
  end

  warning_seperator = "X"^70

  println(io)
  println(stdout)
  println(io, warning_seperator)
  println(stdout, warning_seperator)
  if write_results
    println(io, "XXX WARNING: benchmark results are set to be written to disk, may overwrite previous results")
    println(stdout, "XXX WARNING: benchmark results are set to be written to disk, may overwrite previous results")
  else
    println(io, "XXX WARNING: benchmark results are not set to be written to disk.")
    println(stdout, "XXX WARNING: benchmark results are not set to be written to disk.")
  end
  println(io, warning_seperator)
  println(stdout, warning_seperator)
  println(io)
  println(stdout)

  seperator = "#"^70

  outputlevel = 1

  println(io)
  println(io, "Using Julia v$(VERSION)")

  println(io)
  println(io, "Using ITensors.jl v$julia_itensor_version")

  println(io)
  println(io, "Using C++ ITensor v$cpp_itensor_version")

  println(io)
  println(io, "Julia is using BLAS vendor $(BLAS.vendor()). Please double check this is the same as the one you compile C++ ITensor against.")
  println(io, "Using $blas_num_threads BLAS threads")

  # Disable Strided threads
  ITensors.Strided.disable_threads()

  println(io)
  println(io, "Benchmarking $benchmarks")
  println(io)

  println(io, "Bond dimensions set to:")
  show(io, MIME("text/plain"), maxdims)
  println(io)
  println(io)

  for benchmark in benchmarks
    println(io, "X"^70)
    println(io, "X"^70)
    println(io)
    maxdims_benchmark = maxdims[benchmark]
    if test ≠ false
      println(io, "XXX TESTING: only running the benchmarks for the specified set of bond dimensions maxdims[$test] = $(maxdims_benchmark[test]).")
      maxdims_benchmark = maxdims_benchmark[test]
      println(io)
    end
    st = "Running benchmark $benchmark for bond dimensions $maxdims_benchmark, BLAS threads $blas_num_threads, and block sparse threads $blocksparse_num_threads"
    io ≠ stdout && println(stdout, "\n" * st)
    println(io, st)
    println(io)
    # Print the more detailed description of the benchmark
    println(io, descriptions[benchmark])
    println(io)
    valbenchmark = Val(Symbol(benchmark))
    src_dir = joinpath(pkgdir(@__MODULE__), "src")
    data_dir = joinpath(pkgdir(@__MODULE__), "data")
    benchmark_dir = joinpath(src_dir, "bench_$benchmark")
    for maxdim in maxdims_benchmark,
        blas_num_thread in blas_num_threads,
        blocksparse_num_thread in blocksparse_num_threads

      # Path within data/ directory to write results
      writepath = "bench_$benchmark"
      writepath = joinpath(writepath, "blas_num_threads_$(blas_num_thread)")
      writepath = joinpath(writepath, "blocksparse_num_threads_$(blocksparse_num_thread)")
      if splitblocks
        writepath = joinpath(writepath, "splitblocks_$(splitblocks)")
      end

      # Check consistency of threads that are set
      if blocksparse_num_thread == 1
        ITensors.disable_threaded_blocksparse()
      elseif blocksparse_num_thread ≠ Threads.nthreads()
        error("Trying to benchmark with $blocksparse_num_thread number of threads for block sparse operations, but Julia was started with $(Threads.nthreads()) threads. Start Julia with $blocksparse_num_thread threads using `JULIA_NUM_THREADS=$blocksparse_num_thread julia`, `julia --threads=$blocksparse_num_thread`, or `julia -t $blocksparse_num_thread`.")
      else
        ITensors.enable_threaded_blocksparse()
      end

      if blocksparse_num_thread > 1 && blas_num_thread > 1
        error("Trying to benchmark with $blocksparse_num_thread number of threads for block sparse operations and $blas_num_thread BLAS threads. These two types of multithreading conflict with each other, and therefore is not recommended to use.")
      end
      BLAS.set_num_threads(blas_num_thread)

      st = "Maximum bond dimension set to $maxdim, BLAS threads set to $blas_num_thread, block sparse threads set to $blocksparse_num_thread, and splitblocks is set to $splitblocks."
      println(io, "Benchmark located in path $benchmark_dir")
      println(io)
      io ≠ stdout && println(stdout, " " * st)
      println(io, st)
      println(io)
      if isnothing(cpp_or_julia) || cpp_or_julia == "julia"
        st = "Run Julia benchmark $benchmark for bond dimension $maxdim, $blas_num_thread BLAS threads, $blocksparse_num_thread block sparse threads, and splitblocks $splitblocks."
        println(io, seperator)
        io ≠ stdout && println(stdout, " "^2 * st)
        println(io, st)
        println(io)

        # Trigger compilation
        comp_time = runbenchmark(valbenchmark; maxdim = 10, nsweeps = 2,
                                 outputlevel = 0, splitblocks = splitblocks)
        if isnothing(comp_time)
          println(io, "Moving on to the next benchmark.")
          println(stdout, "Moving on to the next benchmark.")
          continue
        end

        local time
        local maxdim_
        output = @capture_out begin
          time = @elapsed maxdim_ = runbenchmark(valbenchmark; maxdim = maxdim, outputlevel = outputlevel, splitblocks = splitblocks)
        end
        println(io, output)

        println(io)
        println(io, "Maximum dimension = $maxdim_")
        st = "Total runtime = $time seconds"
        io ≠ stdout && println(stdout, " "^3 * st)
        println(io, st)
        println(io)

        if write_results
          filepath = joinpath(data_dir, "julia")
          filepath = joinpath(filepath, "v$julia_itensor_version")
          filepath = joinpath(filepath, writepath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          println(io, "Writing results to $filepath")
          println(io)
          mkpath(dirname(filepath))
          writedlm(filepath, time)
        end
      end
      if !splitblocks && (isnothing(cpp_or_julia) || cpp_or_julia == "c++")
        st = "Run C++ benchmark $benchmark for bond dimension $maxdim, $blas_num_thread BLAS threads, $blocksparse_num_thread block sparse threads, and splitblocks $splitblocks."
        println(io, seperator)
        io ≠ stdout && println(stdout, " "^2 * st)
        println(io, st)
        println(io)

        # Create the file itensor_dir.mk that has the directory where
        # the version of C++ ITensor lives
        if !isfile(joinpath(cpp_itensor_dir, "itensor", "core.h"))
          error("Attempting to use ITensor v$cpp_itensor_version. The installation location is currently set to the directory $cpp_itensor_dir. If you have C++ ITensor v$cpp_itensor_version installed already, you can point to the location by setting `cpp_itensor_dir` to the full path of the installation. Otherwise, download and compile C++ ITensor v$cpp_itensor_version using the direction in http://www.itensor.org/docs.cgi?page=install&vers=cppv3 (and check out the version with `git checkout v$cpp_itensor_version before building).")
        end

        # Make a random directory to store tempororary build files
        rand_dir = joinpath(src_dir, ".tmp_" * randstring(16))
        mkdir(rand_dir)

        open(joinpath(rand_dir, "itensor_dir.mk"), "w") do io
          write(io, "LIBRARY_DIR=$cpp_itensor_dir")
        end
        # Generate the C++ function we will compile
        open(joinpath(rand_dir, "runbenchmark.cc"), "w") do io
          cpp_file =
          """
          #include "$(joinpath(src_dir, "bench_$benchmark", "runbenchmark.h"))"
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
        println(io, "Compile the C++ benchmark in temporary directory $rand_dir")
        cp(joinpath(src_dir, "Makefile"), joinpath(rand_dir, "Makefile"))
        output = @capture_out begin
          run(`make --directory=$rand_dir`)
        end
        println(io, output)
        println(io)
        rm(joinpath(rand_dir, "runbenchmark.cc"))
        runbenchmark_exec = joinpath(rand_dir, "runbenchmark")
        open(joinpath(rand_dir, "runbenchmark.sh"), "w") do io
          write(io, """
                    #!/bin/bash
                    MKL_NUM_THREADS=$blas_num_thread OPENBLAS_NUM_THREADS=$blas_num_thread OMP_NUM_THREADS=$blocksparse_num_thread $runbenchmark_exec $maxdim $outputlevel
                    """)
        end
        chmod(joinpath(rand_dir, "runbenchmark.sh"), 0o777)
        local time
        println(io, "Run the C++ benchmark")
        output = @capture_out begin
          time = @elapsed run(`$(joinpath(rand_dir, "runbenchmark.sh"))`)
        end
        println(io, output)

        # Clean up the build files
        println(io, "Cleaning up temporary directory $rand_dir used for building C++ benchmark")
        rm(joinpath(rand_dir, "runbenchmark.sh"))
        rm(joinpath(rand_dir, "runbenchmark"))
        rm(joinpath(rand_dir, "runbenchmark.o"))
        rm(joinpath(rand_dir, "itensor_dir.mk"))
        rm(joinpath(rand_dir, "Makefile"))
        rm(rand_dir)

        println(io)
        println(io, "Maximum dimension = $maxdim")
        st = "Total runtime = $time seconds"
        io ≠ stdout && println(stdout, " "^3 * st)
        println(io, st)
        println(io)

        if write_results
          # TODO: add version number to data file name
          filepath = joinpath(data_dir, "c++")
          filepath = joinpath(filepath, "v$cpp_itensor_version")
          filepath = joinpath(filepath, writepath)
          filepath = joinpath(filepath, "maxdim_$(maxdim).txt")
          println(io, "Writing results to $filepath")
          println(io)
          mkpath(dirname(filepath))
          writedlm(filepath, time)
        end
      end
    end
  end
  return nothing
end

function logfile_name(rootdir, benchmarks, blas_num_threads,
                      blocksparse_num_threads, splitblocks)
  logfile = rootdir
  logfile = joinpath(logfile, "logs")
  logfile = joinpath(logfile, "$(now())")
  logfile *= "_benchmark_$(benchmarks)"
  logfile *= "_blas_num_threads_$(blas_num_threads)"
  logfile *= "_blocksparse_num_threads_$(blocksparse_num_threads)"
  if splitblocks
    logfile *= "_splitblocks_$(splitblocks)"
  end
  logfile *= ".log"
  return logfile
end

# This version outputs to a file
function runbenchmarks(; blas_num_threads = OPTIONS["blas_num_threads"],
                         blocksparse_num_threads = OPTIONS["blocksparse_num_threads"],
                         benchmarks = OPTIONS["benchmarks"],
                         splitblocks = OPTIONS["splitblocks"],
                         logfile = logfile_name(pkgdir(@__MODULE__), benchmarks, blas_num_threads, blocksparse_num_threads, splitblocks),
                         kwargs...)
  println(stdout, "Saving information about the benchmark run to the file $logfile")
  println(stdout)
  open(logfile, "w") do io
    runbenchmarks(io; blas_num_threads = blas_num_threads,
                      blocksparse_num_threads = blocksparse_num_threads,
                      benchmarks = benchmarks,
                      splitblocks = splitblocks, kwargs...)
  end # open
  return nothing
end

