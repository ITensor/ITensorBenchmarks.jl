# ITensorsBenchmarks.jl
Run benchmarks comparing ITensors.jl to C++ ITensor for various tensor network algorithms.

## Installation

1. Download the latest version of Julia: https://julialang.org/downloads/
2. Install this package from julia with:
```julia
julia> ]

pkg> add https://github.com/ITensor/ITensorsBenchmarks.jl
```
3. Install C++ ITensor with the instructions: http://www.itensor.org/docs.cgi?page=install&vers=cppv3. Install the desired version into the directory `deps/itensor_v#` where `#` is the version number, for example `3.1.6`.

Then, you can start Julia and run the benchmarks with:
```julia
julia> runbenchmarks() # Run all of the benchmarks, doesn't save results by default
[...]

julia> runbenchmarks(write_results = true) # Run all of the benchmarks, save results into `data` directory
[...]

julia> runbenchmarks(write_results = true, blas_num_threads = 4) # Run all of the benchmarks using 4 BLAS threads
[...]

julia> runbenchmarks(write_results = true, blocksparse_num_threads = 4) # Run all of the benchmarks using 4 threads for block sparse operations
[...]
```
and you can run benchmarks with multiple block sparse threads with:
```julia
$ julia -t 4

julia> runbenchmarks(write_results = true, blocksparse_num_threads = 4, benchmarks = ["dmrg_2d_conserve_ky"], maxdims = Dict("dmrg_2d_conserve_ky" => [10_000])) # Run all of the benchmarks using 4 threads for block sparse operations
[...]
```


