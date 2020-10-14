using Pkg
Pkg.activate(".")

using ITensors
using DelimitedFiles
examples_dir = joinpath(dirname(pathof(ITensors)),
                        "..", "examples", "src")
# Alternatively, use:
# joinpath(dirname(Base.find_package(@__MODULE__, "ITensors")),
#          "..", "examples", "src")
include(joinpath(examples_dir, "ctmrg_isotropic.jl"))
include(joinpath(examples_dir, "2d_classical_ising.jl"))

function run(; maxdim::Int,
               nsweeps::Int)
  # Make Ising model MPO
  β = 1.001 * βc
  d = 2
  s = Index(d, "Site")
  sₕ = addtags(s, "horiz")
  sᵥ = addtags(s, "vert")

  T = ising_mpo(sₕ, sᵥ, β)

  χ0 = 1
  l = Index(χ0, "Link")
  lₕ = addtags(l, "horiz")
  lᵥ = addtags(l, "vert")

  # Initial CTM
  Cₗᵤ = ITensor(lᵥ, lₕ)
  Cₗᵤ[1, 1] = 1.0

  # Initial HRTM
  Aₗ = ITensor(lᵥ, lᵥ', sₕ)
  Aₗ[lᵥ => 1, lᵥ' => 1, sₕ => 1] = 1.0
  Aₗ[lᵥ => 1, lᵥ' => 1, sₕ => 2] = 0.0

  Cₗᵤ, Aₗ = ctmrg(T, Cₗᵤ, Aₗ; χmax = maxdim, nsteps = nsweeps)

  lᵥ = commonind(Cₗᵤ, Aₗ)
  lₕ = noncommoninds(Cₗᵤ, Aₗ)[1]

  Aᵤ = replaceinds(Aₗ, lᵥ => lₕ, lᵥ' => lₕ', sₕ => sᵥ)

  ACₗ = Aₗ * Cₗᵤ * dag(Cₗᵤ')

  ACTₗ = prime(ACₗ * dag(Aᵤ') * T * Aᵤ, -1)

  κ = (ACTₗ * dag(ACₗ))[]

  return κ, exp(-β * ising_free_energy(β)), Cₗᵤ
end

function main()
  run(; maxdim = 5, nsweeps = 2)
  maxdims = 20:20:40
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  nsweeps = 500
  for j in 1:N
    maxdim_ = maxdims[j]
    println("Running CTMRG on 2D classical Ising model and maxdim = $maxdim_")
    time = @elapsed κ, κ_exact, Cₗᵤ = run(; maxdim = maxdim_,
                                            nsweeps = nsweeps)
    @show nsweeps
    @show maxdim(Cₗᵤ)
    @show κ
    @show abs(κ - κ_exact)
    @show time
    println()
    data[j, 1] = maxdim(Cₗᵤ)
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

