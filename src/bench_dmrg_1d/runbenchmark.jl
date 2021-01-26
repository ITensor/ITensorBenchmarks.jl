
maxdims["dmrg_1d"] = 200:200:1_000
descriptions["dmrg_1d"] = "DMRG, 1D S=1 Heisenberg model\nN = 100, 5 sweeps\nNo conserved quantities"

function runbenchmark(::Val{:dmrg_1d};
                      maxdim::Int, nsweeps::Int = 5,
                      outputlevel::Int = 0,
                      conserve_qns::Bool = false,
                      N::Int = 100, cutoff::Real = 0.0)
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [10, 20, 100, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, cutoff)
  sites = siteinds("S=1", N; conserve_qns = conserve_qns)
  ampo = AutoMPO()
  for j in 1:N-1
    ampo .+= 0.5, "S+", j, "S-", j + 1
    ampo .+= 0.5, "S-", j, "S+", j + 1
    ampo .+=      "Sz", j, "Sz", j + 1
  end
  H = MPO(ampo,sites)
  psi0 = productMPS(sites, n -> isodd(n) ? "↑" : "↓")
  energy, ψ = dmrg(H, psi0, sweeps;
                   outputlevel = outputlevel)
  if outputlevel > 0
    @show nsweeps
    @show N
    @show cutoff
    @show energy
    @show flux(ψ)
  end
  return maxlinkdim(ψ)
end

