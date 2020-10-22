1. Download and compile C++ ITensor.
2. Edit `itensor_dir.mk` to point towards the location of C++ ITensor.
3. Run the script with calls like `julia run.jl --blas_num_threads=4` where `4` represents the number of BLAS threads to use. Use `julia run.jl --help` to get a list of all of the options.
