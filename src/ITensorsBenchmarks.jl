module ITensorsBenchmarks

using ArgParse
using ITensors
using LinearAlgebra
using DelimitedFiles

export runbenchmarks

# Get a list of the built-in benchmarks
_benchmarks = readdir(joinpath(pkgdir(@__MODULE__), "src"))
_benchmarks = filter!(file -> startswith(file, "bench_"), _benchmarks)
_benchmarks .= replace.(_benchmarks, "bench_" => "")

for benchmark in _benchmarks
  include("bench_$benchmark/runbenchmark.jl")
end

#
# OPTIONS
#

DEFAULT_OPTIONS = Dict{String, Any}()

DEFAULT_OPTIONS["write_results"] = false
DEFAULT_OPTIONS["which_version"] = nothing
DEFAULT_OPTIONS["blocksparse_num_threads"] = 1
DEFAULT_OPTIONS["blas_num_threads"] = 1
DEFAULT_OPTIONS["test"] = false
DEFAULT_OPTIONS["benchmarks"] = _benchmarks
DEFAULT_OPTIONS["julia_itensor_version"] = ITensors.version()
DEFAULT_OPTIONS["cpp_itensor_version"] = v"3.1.6"

DEFAULT_OPTIONS["maxdims"] = Dict{String, StepRange{Int64, Int64}}()
maxdims = DEFAULT_OPTIONS["maxdims"]
maxdims["ctmrg"] = 50:50:400
maxdims["dmrg_1d"] = 200:200:1_000
maxdims["dmrg_1d_qns"] = 200:200:1_000
maxdims["dmrg_2d_conserve_ky"] = 1_000:1_000:5_000
maxdims["dmrg_2d_qns"] = 1_000:1_000:5_000
maxdims["trg"] = 10:10:50

OPTIONS = deepcopy(DEFAULT_OPTIONS)
function reset_options!()
  empty!(OPTIONS)
  for k in keys(OPTIONS)
    OPTIONS[k] = DEFAULT_OPTIONS[k]
  end
end

#
# Files needed from ITensors.jl examples
#

examples_dir = joinpath(pkgdir(ITensors), "examples", "src")
include(joinpath(examples_dir, "2d_classical_ising.jl"))
include(joinpath(examples_dir, "trg.jl"))
include(joinpath(examples_dir, "ctmrg_isotropic.jl"))
include(joinpath(examples_dir, "electronk.jl"))
include(joinpath(examples_dir, "hubbard.jl"))

include("runbenchmarks.jl")

end # module
