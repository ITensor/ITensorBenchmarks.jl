# ITensorsBenchmarks.jl
Run benchmarks comparing ITensors.jl to C++ ITensor as well as benchmarking block sparse multithreading in C++ ITensor.

## Installation

1. Download the latest version of Julia: https://julialang.org/downloads/
2. Install C++ ITensor with the instructions: http://www.itensor.org/docs.cgi?page=install&vers=cppv3
3. Edit `deps/itensor_dir.mk` to point to the installation location of C++ ITensor.

Benchmarks are located in the benchmarks directory. Benchmarks comparing ITensors.jl to C++ ITensor are located in `benchmarks/julia_vs_c++` and benchmarks of the C++ block sparse multithreading can be found in `benchmarks/multithreading`. See the `README.md` files in those directories for instructions on running those benchmarks.

