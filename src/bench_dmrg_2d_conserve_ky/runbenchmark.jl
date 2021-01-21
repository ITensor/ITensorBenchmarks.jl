
function runbenchmark(::Val{:dmrg_2d_conserve_ky};
                      maxdim::Int, nsweeps::Int = 10,
                      outputlevel::Int = 0, conserve_ky::Bool = true,
                      cutoff::Float64 = 0.0, Nx::Int = 8, Ny::Int = 4,
                      U::Float64 = 4.0, t::Float64 = 1.0)
  N = Nx * Ny
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [100, 200, 400, 800, 2000, 10_000, maxdim])
  maxdim!(sweeps, maxdims...) 
  cutoff!(sweeps, cutoff) 
  noise!(sweeps, 1e-6, 1e-7, 1e-8, 0.0)
  sites = siteinds("ElecK", N;
                   conserve_qns = true,
                   conserve_ky = conserve_ky,
                   modulus_ky = Ny)
  ampo = hubbard(Nx = Nx, Ny = Ny, t = t, U = U, ky = true) 
  H = MPO(ampo, sites)
  # Create start state
  state = Vector{String}(undef, N)
  for i in 1:N
    x = (i - 1) ÷ Ny
    y = (i - 1) % Ny
    if x % 2 == 0
      if y % 2 == 0
        state[i] = "Up"
      else
        state[i] = "Dn"
      end
    else
      if y % 2 == 0
        state[i] = "Dn"
      else
        state[i] = "Up"
      end
    end
  end
  ψ0 = productMPS(sites, state)
  energy, ψ = dmrg(H, ψ0, sweeps; outputlevel = outputlevel)
  if outputlevel > 0
    @show nsweeps
    @show cutoff
    @show energy
    @show flux(ψ)
  end
  return maxlinkdim(ψ)
end

