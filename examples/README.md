using ITensorBenchmarks

# Run all of the benchmarks with a single thread and write the results
# By default, a verbose output is written to a log file
runbenchmarks(write_results = true)

# Same run, with a verbose output written to the Julia REPL
runbenchmarks(stdout; write_results = true)

# Run all of the benchmarks with 4 BLAS threads and write the results
runbenchmarks(write_results = true, blas_num_threads = 4)

# Run all of the benchmarks with BLAS threads ranging over all available threads and write the results
runbenchmarks(write_results = true, blas_num_threads = 1:Sys.CPU_THREADS)

runbenchmarks(write_results = true, test = 1, blas_num_threads = 1:Sys.CPU_THREADS)

runbenchmarks(write_results = true, test = 1:2, blas_num_threads = 1:Sys.CPU_THREADS)

