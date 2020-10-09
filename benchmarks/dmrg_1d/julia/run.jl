using ITensors
using Printf

function main(; nsweeps::Int, maxdim::Int, outputlevel::Int = 1)
  # Use DMRG to solve the spin 1, 1D Heisenberg model on 100 sites
  # For the Heisenberg model in one dimension
  # H = J ∑ᵢ(SᶻᵢSᶻᵢ₊₁ + SˣᵢSˣᵢ₊₁ + SʸᵢSʸᵢ₊₁ )
  #   = J ∑ᵢ[SᶻᵢSᶻᵢ₊₁ + ½(S⁺ᵢS⁻ᵢ₊₁ + S⁻ᵢS⁺ᵢ₊₁)]
  # We'll work in units where J=1

  N = 100

  # Create N spin-one degrees of freedom
  sites = siteinds("S=1",N)
  # Alternatively can make spin-half sites instead
  #sites = siteinds("S=1/2",N)

  # Input operator terms which define a Hamiltonian
  ampo = AutoMPO()
  for j=1:N-1
    ampo += "Sz",j,"Sz",j+1
    ampo += 0.5,"S+",j,"S-",j+1
    ampo += 0.5,"S-",j,"S+",j+1
  end
  # Convert these terms to an MPO tensor network
  H = MPO(ampo,sites)

  # Create an initial random matrix product state
  psi0 = randomMPS(sites,10)

  # Plan to do 5 DMRG sweeps:
  sweeps = Sweeps(nsweeps)
  # Set maximum MPS bond dimensions for each sweep
  maxdim!(sweeps, 10, 20, min(100, maxdim), min(100, maxdim), maxdim)
  # Set maximum truncation error allowed when adapting bond dimensions
  cutoff!(sweeps, 1e-14)

  # Run the DMRG algorithm, returning energy and optimized MPS
  energy, psi = dmrg(H, psi0, sweeps;
                     svd_alg = "divide_and_conquer",
                     outputlevel = outputlevel)
  return energy, psi
end

# Warm up step for compilation
main(nsweeps = 1, maxdim = 200, outputlevel = 0)

maxdims = 20:20:100
N = length(maxdims)
data = zeros(Union{Int, Float64}, N, 2)
# Run and time
for j in 1:N
  maxdim = maxdims[j]
  println("Running 1D Heisenberg model with no QNs and maxdim = $maxdim")
  t = @elapsed energy, psi = main(nsweeps = 5, maxdim = maxdim)
  println()
  data[j, 1] = maxlinkdim(psi)
  data[j, 2] = t
end

println("Writing results to data/data.txt")
mkpath("data")
writedlm("data/data.txt", data)

