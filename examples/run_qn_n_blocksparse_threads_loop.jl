# Run the block sparse benchmarks using the specified number of Julia threads and write the results
# By default, a verbose output is written to a log file
for n in 1:4
  run(`julia -t $n -e 'using ITensorBenchmarks; runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads())'`)
end
