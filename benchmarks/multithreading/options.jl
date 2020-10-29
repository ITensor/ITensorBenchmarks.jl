using ArgParse

function ArgParse.parse_item(T::Type{<: Union{Int, AbstractRange}},
                             x::AbstractString)
  r = eval(Meta.parse(x))
  @assert r isa T
  return r
end

settings = ArgParseSettings()
@add_arg_table! settings begin
  "--blas_num_threads"
    help = "Number of BLAS threads."
    arg_type = Int
    default = 1
  "--omp_num_threads"
    help = "Number of OpenMP threads (for block sparse contractions)."
    arg_type = Union{Int, AbstractRange}
    default = 1
  "--maxdim"
    help = "Maximum DMRG bond dimension."
    arg_type = Int
    default = 10_000
  "--U"
    help = "Interaction strength of the Hubbard model."
    arg_type = Float64
    default = 4.0
  "--Nx"
    help = "Number of sites in the x-direction (along the cylinder)."
    arg_type = Int
    default = 8
  "--Ny"
    help = "Number of sites in the y-direction (around the cylinder)."
    arg_type = Int
    default = 4
end

args = parse_args(settings)

blas_num_threads = args["blas_num_threads"]
omp_num_threads = args["omp_num_threads"]
maxdim = args["maxdim"]
U = args["U"]
Nx = args["Nx"]
Ny = args["Ny"]

