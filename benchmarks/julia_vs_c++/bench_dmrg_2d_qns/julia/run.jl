using ITensors

function run(; maxdim::Int,
               nsweeps::Int = 10,
               outputlevel::Int = 0,
               cutoff::Float64 = 0.0,
               Nx::Int = 6,
               Ny::Int = 3,
               U::Float64 = 4.0,
               t::Float64 = 1.0)
  N = Nx * Ny
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [100, 200, 400, 800, 2000, 3000, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, cutoff)
  noise!(sweeps, 1e-6, 1e-7, 1e-8, 0.0)
  sites = siteinds("Electron", N; conserve_qns = true)
  lattice = square_lattice(Nx, Ny; yperiodic = true)
  ampo = AutoMPO()
  for b in lattice
    ampo .+= -t, "Cdagup", b.s1, "Cup", b.s2
    ampo .+= -t, "Cdagup", b.s2, "Cup", b.s1
    ampo .+= -t, "Cdagdn", b.s1, "Cdn", b.s2
    ampo .+= -t, "Cdagdn", b.s2, "Cdn", b.s1
  end
  for n in 1:N
    ampo .+= U, "Nupdn", n
  end
  H = MPO(ampo,sites)
  state = [isodd(n) ? "↑" : "↓" for n in 1:N]
  ψ0 = productMPS(sites, state)
  energy, ψ = dmrg(H, ψ0, sweeps;
                   svd_alg = "divide_and_conquer",
                   outputlevel = outputlevel)
  if outputlevel > 0
    @show nsweeps
    @show cutoff
    @show energy
    @show flux(ψ)
  end
  return maxlinkdim(ψ)
end

