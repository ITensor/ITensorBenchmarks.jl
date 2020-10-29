using ArgParse

benchmarks = readdir(@__DIR__)
benchmarks = filter!(file -> startswith(file, "bench_"),
                     benchmarks)
benchmarks .= replace.(benchmarks, "bench_" => "")

# Defaults
maxdims = Dict{String, StepRange{Int64, Int64}}()
maxdims["ctmrg"] = 50:50:400
maxdims["dmrg_1d"] = 200:200:1_000
maxdims["dmrg_1d_qns"] = 200:200:1_000
maxdims["dmrg_2d_conserve_ky"] = 1_000:1_000:5_000
maxdims["dmrg_2d_qns"] = 1_000:1_000:5_000
maxdims["trg"] = 10:10:50

# Testing
maxdims_test = Dict{String, StepRange{Int64, Int64}}()
maxdims_test["ctmrg"] = 50:50:100
maxdims_test["dmrg_1d"] = 50:50:100
maxdims_test["dmrg_1d_qns"] = 200:200:400
maxdims_test["dmrg_2d_conserve_ky"] = 1_000:1_000:2_000
maxdims_test["dmrg_2d_qns"] = 200:200:400
maxdims_test["trg"] = 10:10:20

function ArgParse.parse_item(::Type{Dict{String, StepRange{Int64, Int64}}}, x::AbstractString)
  return Dict{String, StepRange{Int64, Int64}}(eval(Meta.parse(x)))
end

settings = ArgParseSettings()
@add_arg_table! settings begin
  "--blas_num_threads"
    help = "Number of BLAS threads."
    arg_type = Int
    default = 1
  "--omp_num_threads"
    help = "Number of OpenMP threads (for block sparse contractions)."
    arg_type = Int
    default = 1
  "--which_version"
    help = "Which version to run. Options are \"c++\" or \"julia\". If nothing is specified, both are run."
    arg_type = Union{Nothing, String}
    default = nothing
  "--benchmarks"
    help = "Which benchmarks to run. If nothing is specified, all are run."
    nargs = '+'
    arg_type = String
    default = benchmarks
  "--write_results"
    help = "Write the results to file (warning: writing results may overwrite previously saved results)."
    arg_type = Bool
    default = false
  "--test"
    help = "Test the benchmarking with lower bond dimensions."
    arg_type = Bool
    default = false
  "--maxdims"
    help = "Set maxdims."
    arg_type = Dict{String, StepRange{Int64, Int64}}
    default = maxdims
end

args = parse_args(settings)

blas_num_threads = args["blas_num_threads"]
omp_num_threads = args["omp_num_threads"]
which_version = args["which_version"]
benchmarks = args["benchmarks"]
write_results = args["write_results"]
test = args["test"]
maxdims = args["maxdims"]

if test
  maxdims = maxdims_test
end

descriptions = Dict{String, String}()
descriptions["ctmrg"] = "CTMRG, 2D classical Ising model\nN → ∞\nβ = 1.001 βc"
descriptions["dmrg_1d"] = "DMRG, 1D S=1 Heisenberg model\nN = 100\nNo conserved quantities"
descriptions["dmrg_1d_qns"] = "DMRG, 1D S=1 Heisenberg model\nN = 100\nConserve total spin projection symmetry"
descriptions["dmrg_2d_conserve_ky"] = "DMRG, 2D Hubbard model (U = 4)\nNx, Ny = 6, 3\nHybrid real and momentum space"
descriptions["dmrg_2d_qns"] = "DMRG, 2D Hubbard model (U = 4)\nNx, Ny = 6, 3\nReal space, periodic in the y-direction"
descriptions["trg"] = "TRG, 2D classical Ising model\nN → ∞\nβ = 1.001 βc"


