Run the benchmarks with the `run.jl` Julia script.

To run all of the benchmarks on a single thread, use:
```
$ julia run.jl --write_results=true
```

To specify a number of BLAS threads, use:
```
$ julia run.jl --write_results=true --blas_num_threads=4
```

To run only the Julia benchmarks, use:
```
$ julia run.jl --write_results=true --which_version=julia
```
Use `julia run.jl --help` to get a list of all of the options.

To plot the results, use:
```
$ julia plot.jl --blas_num_threads=4
```

Run the benchmarks detached in the background:
```
$ nohup julia run.jl --write_results=true --blas_num_threads=4 --benchmarks=dmrg_1d > log.txt 2> err.txt &
```
