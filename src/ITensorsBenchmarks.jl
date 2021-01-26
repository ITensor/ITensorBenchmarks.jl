module ITensorsBenchmarks

ENV["GKSwstype"]="100"

using Dates
using DelimitedFiles
using ITensors
using LinearAlgebra
using Plots
using Random
using Suppressor

export runbenchmarks,
       plotbenchmarks

#
# OPTIONS
#

const DEFAULT_OPTIONS = Dict{String, Any}()

# A range of maximum dimensions for each benchmark
DEFAULT_OPTIONS["maxdims"] = Dict{String, StepRange{Int64, Int64}}()
const maxdims = DEFAULT_OPTIONS["maxdims"]

# Descriptions of each benchmark
DEFAULT_OPTIONS["descriptions"] = Dict{String, String}()
const descriptions = DEFAULT_OPTIONS["descriptions"]

# Get a list of the built-in benchmarks
_benchmarks = readdir(joinpath(pkgdir(@__MODULE__), "src"))
_benchmarks = filter!(file -> startswith(file, "bench_"), _benchmarks)
_benchmarks .= replace.(_benchmarks, "bench_" => "")

for benchmark in _benchmarks
  include("bench_$benchmark/runbenchmark.jl")
end

DEFAULT_OPTIONS["write_results"] = false
DEFAULT_OPTIONS["cpp_or_julia"] = nothing
DEFAULT_OPTIONS["blocksparse_num_threads"] = 1
DEFAULT_OPTIONS["blas_num_threads"] = 1
DEFAULT_OPTIONS["test"] = false
DEFAULT_OPTIONS["benchmarks"] = _benchmarks
DEFAULT_OPTIONS["julia_itensor_version"] = ITensors.version()
DEFAULT_OPTIONS["cpp_itensor_version"] = v"3.1.6"
DEFAULT_OPTIONS["cpp_itensor_dir"] = joinpath(pkgdir(@__MODULE__), "deps", "itensor_v$(DEFAULT_OPTIONS["cpp_itensor_version"])")

const OPTIONS = deepcopy(DEFAULT_OPTIONS)
function reset_options!()
  empty!(OPTIONS)
  OPTIONS_COPY = deepcopy(DEFAULT_OPTIONS)
  for k in keys(OPTIONS)
    OPTIONS[k] = OPTIONS_COPY[k]
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
include("plotbenchmarks.jl")

end # module
