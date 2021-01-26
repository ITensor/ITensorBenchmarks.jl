
maxdims["dmrg_1d_qns"] = 200:200:1_000
descriptions["dmrg_1d_qns"] = "DMRG, 1D S=1 Heisenberg model\nN = 100, 5 sweeps\nConserve total spin projection symmetry"

function runbenchmark(::Val{:dmrg_1d_qns};
                      maxdim::Int, nsweeps::Int = 5,
                      outputlevel::Int = 0,
                      conserve_qns::Bool = true,
                      N::Int = 100, splitblocks::Bool = false)
  if !conserve_qns && splitblocks
    println("In benchmark dmrg_1d_qns, conserve_qns is $conserve_qns, cannot use with splitblocks $splitblocks.")
    return nothing
  end
  sites = siteinds("S=1", N; conserve_qns = conserve_qns)
  ampo = AutoMPO()
  for j in 1:N-1
    ampo .+= 0.5, "S+", j, "S-", j + 1
    ampo .+= 0.5, "S-", j, "S+", j + 1
    ampo .+=      "Sz", j, "Sz", j + 1
  end
  H = MPO(ampo,sites)
  if splitblocks
    H = ITensors.splitblocks(linkinds, H)
  end
  psi0 = productMPS(sites, n -> isodd(n) ? "↑" : "↓")
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [10, 20, 100, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, 0.0)
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

