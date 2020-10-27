Run the benchmarks with the `run.jl` Julia script.

To run all of the benchmarks on a single thread, use:

```
$ julia run.jl
```

To specify a number of BLAS threads, use:

```
$ julia run.jl --blas_num_threads=4
```

To run only the Julia benchmarks, use:

```
$ julia run.jl --which_version=julia
```

Use `julia run.jl --help` to get a list of all of the options.

