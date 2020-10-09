pwd

cd dmrg_1d/julia
pwd
MKL_NUM_THREADS=1 julia --project=. run.jl

cd ../c++
pwd
make
MKL_NUM_THREADS=1 ./run

# back to benchmarks directory
cd ..
pwd

