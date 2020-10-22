using ITensors
using DelimitedFiles

examples_dir = joinpath(dirname(pathof(ITensors)),
                        "..", "examples", "src")

include(joinpath(examples_dir, "electronk.jl"))
include(joinpath(examples_dir, "hubbard.jl"))

function run(; maxdim::Int,
               nsweeps::Int = 10,
               outputlevel::Int = 1,
               Nx = 6,
               Ny = 3,
               U = 4.0,
               t = 1.0,
               conserve_ky = true)
  N = Nx * Ny

  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [100, 200, 400, 800, 2000, 3000, maxdim])
  maxdim!(sweeps, maxdims...) 
  cutoff!(sweeps, 0.0)
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

  psi0 = randomMPS(sites, state, 10)

  energy, psi = dmrg(H, psi0, sweeps; outputlevel = outputlevel)
  return energy, psi
end

function main()
  # Warm up step for compilation
  run(maxdim = 200, nsweeps = 1, outputlevel = 0)

  maxdims = 1000:1000:5000
  nsweeps = 10
  outputlevel = 0
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  # Run and time
  for j in 1:N
    maxdim = maxdims[j]
    println("Running 2D Hubbard model with momentum around the cylinder conserved and maxdim = $maxdim")
    time = @elapsed energy, psi = run(maxdim = maxdim,
                                      nsweeps = nsweeps,
                                      outputlevel = outputlevel)
    @show nsweeps
    @show maxlinkdim(psi)
    @show flux(psi)
    @show energy
    @show time
    println()
    data[j, 1] = maxlinkdim(psi)
    data[j, 2] = time
  end

  filename = joinpath(@__DIR__, "data.txt")
  println("Writing results to $filename")
  mkpath(dirname(filename))
  writedlm(filename, data)
end

main()

