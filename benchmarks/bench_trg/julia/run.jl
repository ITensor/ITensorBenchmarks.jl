using Pkg
Pkg.activate(".")

using ITensors
using DelimitedFiles
examples_dir = joinpath(dirname(pathof(ITensors)),
                        "..", "examples", "src")
# Alternatively, use:
# joinpath(dirname(Base.find_package(@__MODULE__, "ITensors")),
#          "..", "examples", "src")
include(joinpath(examples_dir, "trg.jl"))
include(joinpath(examples_dir, "2d_classical_ising.jl"))

function run(; maxdim::Int,
               nsweeps::Int)
  # Make Ising model MPO
  β = 1.001 * βc
  d = 2
  s = Index(d)
  sₕ = addtags(s, "horiz")
  sᵥ = addtags(s, "vert")
  T = ising_mpo(sₕ, sᵥ, β)

  χmax = maxdim
  nsteps = nsweeps
  κ, T = trg(T; χmax = χmax, nsteps = nsteps)

  return κ, exp(-β * ising_free_energy(β)), T
end

function main()
  run(; maxdim = 3, nsweeps = 2)
  maxdims = 20:20:40
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  nsweeps = 20
  for j in 1:N
    maxdim_ = maxdims[j]
    println("Running TRG on 2D classical Ising model and maxdim = $maxdim_")
    time = @elapsed κ, κ_exact, T = run(; maxdim = maxdim_,
                                          nsweeps = nsweeps)
    @show nsweeps
    @show maxdim(T)
    @show κ
    @show abs(κ - κ_exact)
    @show time
    println()
    data[j, 1] = maxdim(T)
    data[j, 2] = time
  end

  # TODO: add version number to date file name
  # v = Pkg.dependencies()[Base.UUID("9136182c-28ba-11e9-034c-db9fb085ebd5")].version
  # "$(v.major).$(v.minor).$(v.patch)"
  filename = joinpath(@__DIR__, "data.txt")
  println("Writing results to $filename")
  mkpath(dirname(filename))
  writedlm(filename, data)
end

main()

