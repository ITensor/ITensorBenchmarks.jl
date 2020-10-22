using ITensors
using DelimitedFiles

function run(; maxdim::Int,
               nsweeps::Int = 10,
               outputlevel::Int = 1)
  Nx, Ny = 6, 3
  N = Nx * Ny
  t = 1.0
  U = 8.0
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
  psi0 = productMPS(sites, state)
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [20, 60, 100, 100, 200, 400, 800, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, 0.0)
  noise!(sweeps, 1e-7, 1e-8, 1e-10, 0.0, 1e-11, 0.0)
  energy,psi = dmrg(H, psi0, sweeps;
                    svd_alg = "divide_and_conquer",
                    outputlevel = outputlevel)
  return energy, psi
end

function main()
  # Warm up step for compilation
  run(maxdim = 200, nsweeps = 1, outputlevel = 0)

  maxdims = 200:200:1_000
  nsweeps = 10
  outputlevel = 0
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  # Run and time
  for j in 1:N
    maxdim = maxdims[j]
    println("Running 2D Hubbard model with QNs and maxdim = $maxdim")
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

