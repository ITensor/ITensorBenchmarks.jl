using ITensors

examples_dir = joinpath(ITensors.examples_dir(), "src")
include(joinpath(examples_dir, "trg.jl"))
include(joinpath(examples_dir, "2d_classical_ising.jl"))

function run(; maxdim::Int,
               nsweeps::Int = 20,
               outputlevel::Int = 0,
               cutoff::Float64 = 0.0,
               β::Float64 = 1.001 * βc)
  # Make Ising model MPO
  s = Index(2)
  sₕ = addtags(s, "horiz")
  sᵥ = addtags(s, "vert")
  T = ising_mpo(sₕ, sᵥ, β)
  κ, T = trg(T; χmax = maxdim, cutoff = cutoff, nsteps = nsweeps)
  if outputlevel > 0
    @show nsweeps
    @show cutoff
    @show κ, exp(-β * ising_free_energy(β))
  end
  return ITensors.maxdim(T)
end

