# ITensorsBenchmarks.jl
Run benchmarks comparing ITensors.jl to C++ ITensor for various tensor network algorithms.

## Installation

1. Download the latest version of Julia: https://julialang.org/downloads/
2. Install this package with Julia package manager with:
```julia
$ julia

julia> ]

pkg> add https://github.com/ITensor/ITensorsBenchmarks.jl
```
3. Install C++ ITensor with the instructions: http://www.itensor.org/docs.cgi?page=install&vers=cppv3. Install the desired version into the directory `deps/itensor_v#` where `#` is the version number, for example `3.1.6` (or use a custom location, which you will need to specify in the options when running the benchmarks).

Then, you can start Julia and run the benchmarks with:
```julia
julia> using ITensorsBenchmarks

julia> runbenchmarks(write_results = true) # Run all of the benchmarks, save results into `data` directory
[...]

julia> runbenchmarks(write_results = true, blas_num_threads = 4) # Run all of the benchmarks using 4 BLAS threads
[...]

julia> runbenchmarks(write_results = true, blas_num_threads = 1:4) # Run all of the benchmarks using 1,2,3, and 4 BLAS threads
[...]
```
You can run benchmarks with multiple block sparse threads with:
```julia
$ julia -t 4

julia> runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = 4)
[...]
```
To loop over different numbers of block sparse threads, currently this can only be done by launching multiple Julia processes that are started with different numbers of threads. This can be done from within Julia as follows:
```julia
julia> for n in 1:Sys.CPU_THREADS # 1:6 if your system has 6 available threads
         run(`julia -t $n -e 'using ITensorsBenchmarks; runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads())'`)
       end
[...]
```
or you can use a shell script to do the same thing.

## TODO

 - Make a version of `plotbenchmarks` the plots with respect to number of threads and also shows speedups as a function of number of threads.

