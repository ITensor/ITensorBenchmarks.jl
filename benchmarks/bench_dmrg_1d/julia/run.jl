using ITensors
using DelimitedFiles

function run(; maxdim::Int,
               nsweeps::Int,
               outputlevel::Int)
  N = 100
  sites = siteinds("S=1",N)
  ampo = AutoMPO()
  for j=1:N-1
    ampo .+= "Sz",j,"Sz",j+1
    ampo .+= 0.5,"S+",j,"S-",j+1
    ampo .+= 0.5,"S-",j,"S+",j+1
  end
  H = MPO(ampo,sites)
  psi0 = productMPS(sites, n -> isodd(n) ? "↑" : "↓")
  sweeps = Sweeps(nsweeps)
  maxdims = min.(maxdim, [10, 20, 100, 100, maxdim])
  maxdim!(sweeps, maxdims...)
  cutoff!(sweeps, 1e-14)
  energy, psi = dmrg(H, psi0, sweeps;
                     svd_alg = "divide_and_conquer",
                     outputlevel = outputlevel)
  return energy, psi
end

function main()
  # Warm up step for compilation
  run(maxdim = 200, nsweeps = 1, outputlevel = 0)

  outputlevel = 0
  nsweeps = 5
  maxdims = 20:20:40
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  # Run and time
  for j in 1:N
    maxdim = maxdims[j]
    println("Running 1D Heisenberg model with no QNs and maxdim = $maxdim")
    time = @elapsed energy, psi = run(maxdim = maxdim, nsweeps = nsweeps, outputlevel = outputlevel)
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

