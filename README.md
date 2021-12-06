# ITensorBenchmarks.jl
Run benchmarks comparing ITensors.jl to C++ ITensor for various tensor network algorithms.

| **Documentation**                                                               |
|:-------------------------------------------------------------------------------:|
| [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://itensor.github.io/ITensorBenchmarks.jl/dev/) |

## Installation

1. Download the latest version of Julia: https://julialang.org/downloads/
2. Install this package with the Julia package manager and check out for development:
```julia
$ julia

julia> ]

pkg> dev https://github.com/ITensor/ITensorBenchmarks.jl
```
3. Install C++ ITensor with the instructions: http://www.itensor.org/docs.cgi?page=install&vers=cppv3. Install the desired version into the directory `~/.julia/dev/ITensorBenchmarks/deps/itensor_v#` where `#` is the version number, for example `3.1.6` (or use a custom location, which you will need to specify in the options when running the benchmarks). You can use the file in `~/.julia/dev/ITensorBenchmarks/deps/options.mk.sample` for your `options.mk`, which is the file that specifies the options for installing C++ ITensor. This `options.mk.sample` specifies the options for installing ITensor with Intel MKL. Here is an example:
```
$ git clone https://github.com/ITensor/ITensor ~/.julia/dev/ITensorBenchmarks/deps/itensor_v3.1.6

$ cd ~/.julia/dev/ITensorBenchmarks/deps/itensor_v3.1.6

$ git clone v3.1.6

$ cp ../options.mk.sample ./options.mk

$ make -j
```
`make -j` compiles the C++ ITensor library (the `-j` option specifies that the compilation will be done in parallel to speed up the compilation time, if possible).

## Run benchmarks with BLAS multithreading

Here are commands to run all of the benchmark options:
```julia
# All benchmarks single threaded
runbenchmarks(write_results = true)

# splitblocks single threaded (splitblocks enables a more sparse representation of the MPO, currently only available in Julia)
runbenchmarks(write_results = true, cpp_or_julia = "julia", benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], splitblocks = true)

# All benchmarks with multiple BLAS threads
runbenchmarks(write_results = true, blas_num_threads = [4, 8])

# splitblocks with multiple BLAS threads
runbenchmarks(write_results = true, cpp_or_julia = "julia", benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blas_num_threads = [4, 8], splitblocks = true)

```

## Run benchmarks with block sparse multithreading

You can run benchmarks with multiple block sparse threads by starting Julia with multiple threads:
```julia
$ julia -t 4

julia> runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads())
[...]
```
To loop over different numbers of block sparse threads, currently this can only be done by launching multiple Julia processes that are started with different numbers of threads. This can be done from within Julia by launching different Julia processes as follows:
```julia
# Run all QN benchmarks with multiple block sparse threads
for n in [4, 8] run(`julia -t $n -e 'using ITensorBenchmarks; runbenchmarks(write_results = true, benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads())'`) end

# Run Julia QN benchmarks with multiple block sparse threads and splitblocks
for n in [4, 8] run(`julia -t $n -e 'using ITensorBenchmarks; runbenchmarks(write_results = true, cpp_or_julia = "julia", benchmarks = ["dmrg_1d_qns", "dmrg_2d_qns", "dmrg_2d_conserve_ky"], blocksparse_num_threads = Threads.nthreads(), splitblocks = true)'`) end
```
or you can use a shell script to do the same thing.

Here is an example for running benchmarks in the background from the command line (for example it is helpful running them on a remote computer over ssh, if you want the benchmarks to continue running after you log off):
```
$ nohup julia -e 'using ITensorBenchmarks; runbenchmarks(write_results = true, blas_num_threads = [4, 8])' > log_$(date "+%Y.%m.%d-%H.%M.%S").txt 2> err_$(date "+%Y.%m.%d-%H.%M.%S").txt &
```

Here are commands to plot all available benchmarks:
```julia
plotbenchmarks(blas_num_threads = [1, 4, 8])

plotbenchmarks(benchmarks = ["dmrg_1d_qns", "dmrg_2d_conserve_ky", "dmrg_2d_qns"], blas_num_threads = [1, 4, 8], splitblocks = true)

plotbenchmarks(benchmarks = ["dmrg_1d_qns", "dmrg_2d_conserve_ky", "dmrg_2d_qns"], blocksparse_num_threads = [1, 4, 8])

plotbenchmarks(benchmarks = ["dmrg_1d_qns", "dmrg_2d_conserve_ky", "dmrg_2d_qns"], blocksparse_num_threads = [1, 4, 8], splitblocks = true)
```

# TODO

 - Make a version of `plotbenchmarks` that plots with respect to number of threads and also shows speedups as a function of number of threads.

## If there is time

 - Run all QN benchmarks with `blocksparse_num_threads = 12`.
 - Run all benchmarks with `blas_num_threads = 12`.

