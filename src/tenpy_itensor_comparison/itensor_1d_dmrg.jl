using ITensors

function run(; maxdim::Int,
               nsweeps::Int = 5,
               outputlevel::Int = 0,
               conserve_qns::Bool = false,
               use_sparse_mpo::Bool = false,
               N::Int = 100)
  sites = siteinds("S=1", N; conserve_qns = conserve_qns)
  ampo = AutoMPO()
  for j in 1:N-1
    ampo .+= 0.5, "S+", j, "S-", j+1
    ampo .+= 0.5, "S-", j, "S+", j+1
    ampo .+=      "Sz", j, "Sz", j+1
  end
  HD = MPO(ampo,sites)
  if use_sparse_mpo
    println("Splitting blocks of H (= making MPO sparse)")
    H = splitblocks(linkinds, HD)
  else
    println("Using dense MPO")
    H = HD
  end
  psi0 = productMPS(sites, n -> isodd(n) ? "↑" : "↓")
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [10, 20, 100, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, 0.0)
  t = @elapsed begin
  energy, ψ = dmrg(H, psi0, sweeps;
                   outputlevel = outputlevel)
  end
  println(t)
  return
end

