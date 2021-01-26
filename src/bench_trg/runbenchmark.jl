
maxdims["trg"] = 10:10:50
descriptions["trg"] = "TRG, 2D classical Ising model\nN → ∞, 20 iterations\nβ = 1.001 βc"

function runbenchmark(::Val{:trg};
                      maxdim::Int, nsweeps::Int = 20,
                      outputlevel::Int = 0, cutoff::Float64 = 0.0,
                      β::Float64 = 1.001 * βc, splitblocks::Bool = false)
  if splitblocks
    println("Benchmark trg doesn't support splitblocks $splitblocks.")
    return nothing
  end
  # Make Ising model MPO
  s = Index(2)
  sₕ = addtags(s, "horiz")
  sᵥ = addtags(s, "vert")
  T = ising_mpo(sₕ, sᵥ, β)
  κ, T = trg(T; χmax = maxdim, cutoff = cutoff, nsteps = nsweeps)
  if outputlevel > 0
    @show nsweeps
    @show β
    @show cutoff
    @show κ, exp(-β * ising_free_energy(β))
  end
  return ITensors.maxdim(T)
end

