using ITensorsBenchmarks

# Run all of the block sparse benchmarks using all of the available Julia threads and write the results
# By default, a verbose output is written to a log file
runbenchmarks(write_results = true, blocksparse_num_threads = Threads.nthreads())
