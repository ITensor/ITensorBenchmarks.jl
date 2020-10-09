using ITensors
using DelimitedFiles

function run(; maxdim::Int, nsweeps::Int = 5, outputlevel::Int = 1)
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
  maxdim!(sweeps, 10, 20, min(100, maxdim), min(100, maxdim), maxdim)
  cutoff!(sweeps, 1e-14)
  energy, psi = dmrg(H, psi0, sweeps;
                     svd_alg = "divide_and_conquer",
                     outputlevel = outputlevel)
  return energy, psi
end

function main()
  # Warm up step for compilation
  run(maxdim = 200, nsweeps = 1, outputlevel = 0)

  maxdims = 20:20:200
  N = length(maxdims)
  data = zeros(Union{Int, Float64}, N, 2)
  # Run and time
  for j in 1:N
    maxdim = maxdims[j]
    println("Running 1D Heisenberg model with no QNs and maxdim = $maxdim")
    t = @elapsed energy, psi = run(maxdim = maxdim)
    println()
    data[j, 1] = maxlinkdim(psi)
    data[j, 2] = t
  end

  filename = joinpath(@__DIR__, "data.txt")
  println("Writing results to $filename")
  mkpath(dirname(filename))
  writedlm(filename, data)
end

main()

