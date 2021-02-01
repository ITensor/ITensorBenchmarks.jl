# ITensorsBenchmarks.jl
Run benchmarks comparing ITensors.jl to C++ ITensor for various tensor network algorithms.

## Installation

1. Download the latest version of Julia: https://julialang.org/downloads/
2. Install this package with the Julia package manager and check out for development:
```julia
$ julia

julia> ]

pkg> add https://github.com/ITensor/ITensorsBenchmarks.jl

pkg> dev ITensorsBenchmarks
```
3. Install C++ ITensor with the instructions: http://www.itensor.org/docs.cgi?page=install&vers=cppv3. Install the desired version into the directory `~/.julia/dev/ITensorsBenchmarks/deps/itensor_v#` where `#` is the version number, for example `3.1.6` (or use a custom location, which you will need to specify in the options when running the benchmarks). You can use the file in `~/.julia/dev/ITensorsBenchmarks/deps/options.mk.sample` to for your `options.mk` to install ITensor with Intel MKL. Here is an example:
```
$ git clone https://github.com/ITensor/ITensor ~/.julia/dev/ITensorsBenchmarks/deps/itensor_v3.1.6

$ cd ~/.julia/dev/ITensorsBenchmarks/deps/itensor_v3.1.6

$ git clone v3.1.6

$ cp ../options.mk.sample .

$ make -j
```

Then, you can start Julia and run the benchmarks with:
```julia
julia> using ITensorsBenchmarks

julia> runbenchmarks(write_results = true) # Run all of the benchmarks, save results into `data` directory
[...]

julia> runbenchmarks(write_results = true, blas_num_threads = 4) # Run all of the benchmarks using 4 BLAS threads
[...]

julia> runbenchmarks(write_results = true, blas_num_threads = [1, 4, 8]) # Run all of the benchmarks using 1, 4, and 8 BLAS threads
[...]
```
You can run benchmarks with multiple block sparse threads with:
```julia
$ julia -t 4

julia> runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = 4)
[...]

julia> runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = [1, 8, 16, 24])
[...]
```
To loop over different numbers of block sparse threads, currently this can only be done by launching multiple Julia processes that are started with different numbers of threads. This can be done from within Julia as follows:
```julia
julia> for n in 4:4:Sys.CPU_THREADS
         run(`julia -t $n -e 'using ITensorsBenchmarks; runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads())'`)
       end
[...]
```
or you can use a shell script to do the same thing.

Here is an example for running benchmarks in the background:
```
$ nohup julia -e 'using ITensorsBenchmarks; runbenchmarks(write_results = true, blas_num_threads = [1, 4, 8])' > log_$(date "+%Y.%m.%d-%H.%M.%S").txt 2> err_$(date "+%Y.%m.%d-%H.%M.%S").txt &
```

Here are some commands to plot the benchmarks:
```julia
plotbenchmarks(blas_num_threads = [1, 8])
plotbenchmarks(benchmarks = ["ctmrg", "dmrg_1d", "dmrg_1d_qns", "dmrg_2d_conserve_ky"], blas_num_threads = [1, 8])
plotbenchmarks(benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = [1, 8, 16])
```

# TODO

 - Make a version of `plotbenchmarks` that plots with respect to number of threads and also shows speedups as a function of number of threads.

## To benchmark

 - Run `benchmarks = ["dmrg_2d_conserve_ky"]` with `maxdims = 6000:1000:10000` for `blocksparse_num_threads = [4, 8]`.
 - Rerun `benchmarks = ["dmrg_2d_conserve_ky"]` with `maxdims = 5000` and `blas_num_threads = 8` (the results look pretty far off, but maybe it is just detrimental to use too many threads at some point).
 - Run `benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"]` with `splitblocks = true` and `[1, 4, 8]` blocksparse threads (complete for `["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"]` with `blocksparse_num_threads = 1`, `"dmrg_1d_qns"` with `blocksparse_num_threads = 4`.).
 - Run `benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"]` with `splitblocks = true` and `[1, 4, 8]` BLAS threads.

## If there is time

 - Run all benchmarks with `blas_num_threads = 12`, `blocksparse_num_threads = 12`.

