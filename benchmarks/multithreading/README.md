Run on the command line with:
```
$ julia run.jl --omp_num_threads=1:24 --maxdim=10_000
```
to run the benchmark with `1,2,...,24` OpenMP threads.

Plot the results with:
```
$ julia plot.jl --omp_num_threads=1:24 --maxdim=10_000
```
to plot the benchmark with `1,2,...,24` OpenMP threads.

