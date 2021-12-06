using ITensorBenchmarks

# Run all of the benchmarks over the range of BLAS threads blas_num_threads and write the results
# By default, a verbose output is written to a log file
runbenchmarks(write_results = true, blas_num_threads = 1:6:Sys.CPU_THREADS)
