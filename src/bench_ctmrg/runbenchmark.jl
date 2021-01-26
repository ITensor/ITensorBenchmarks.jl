
maxdims["ctmrg"] = 50:50:500
descriptions["ctmrg"] = "CTMRG, 2D classical Ising model\nN → ∞, 800 iterations\nβ = 1.001 βc"

function runbenchmark(::Val{:ctmrg};
                      maxdim::Int,
                      nsweeps::Int = 800,
                      outputlevel::Int = 1,
                      β::Float64 = 1.001 * βc)
  # Make Ising model MPO
  s = Index(2, "Site")
  sₕ = addtags(s, "horiz")
  sᵥ = addtags(s, "vert")

  T = ising_mpo(sₕ, sᵥ, β)

  χ0 = 1
  l = Index(χ0, "Link")
  lₕ = addtags(l, "horiz")
  lᵥ = addtags(l, "vert")

  # Initial CTM
  Cₗᵤ = ITensor(lᵥ, lₕ)
  Cₗᵤ[1, 1] = 1.0

  # Initial HRTM
  Aₗ = ITensor(lᵥ, lᵥ', sₕ)
  Aₗ[lᵥ => 1, lᵥ' => 1, sₕ => 1] = 1.0

  Cₗᵤ, Aₗ = ctmrg(T, Cₗᵤ, Aₗ;
                  χmax = maxdim,
                  cutoff = 0.0,
                  nsteps = nsweeps)

  lᵥ = commonind(Cₗᵤ, Aₗ)
  lₕ = noncommoninds(Cₗᵤ, Aₗ)[1]

  Aᵤ = replaceinds(Aₗ, lᵥ => lₕ, lᵥ' => lₕ', sₕ => sᵥ)

  ACₗ = Aₗ * Cₗᵤ * dag(Cₗᵤ')

  ACTₗ = prime(ACₗ * dag(Aᵤ') * T * Aᵤ, -1)
  κ = (ACTₗ * dag(ACₗ))[]

  Tsz = ising_mpo(sₕ, sᵥ, β; sz = true)
  ACTszₗ = prime(ACₗ * dag(Aᵤ') * Tsz * Aᵤ, -1)
  m = (ACTszₗ * dag(ACₗ))[] / κ

  if outputlevel > 0
    @show nsweeps
    @show β
    @show κ, exp(-β * ising_free_energy(β))
    @show m, ising_magnetization(β)
  end

  return ITensors.maxdim(Cₗᵤ)
end

