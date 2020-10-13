using Pkg
Pkg.activate(".")

using ITensors
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
  l = addtags(s, "left")
  r = addtags(s, "right")
  u = addtags(s, "up")
  d = addtags(s, "down")
  T = ising_mpo((l, r), (u, d), β)

  χmax = maxdim
  nsteps = nsweeps
  κ, T, (l,r), (u,d) = trg(T, (l, r), (u, d);
                           χmax = χmax,
                           nsteps = nsteps)

  return κ, exp(-β*ising_free_energy(β)), T
end

function main()
  run(; maxdim = 3, nsweeps = 2)
  maxdims = 20:20:40
  nsweeps = 20
  for maxdim_ in maxdims
    time = @elapsed κ, κ_exact, T = run(; maxdim = maxdim_,
                                          nsweeps = nsweeps)
    @show maxdim(T), time, κ, abs(κ - κ_exact)
  end
end

main()

