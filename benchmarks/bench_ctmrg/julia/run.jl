using ITensors
examples_dir = joinpath(dirname(pathof(ITensors)),
                        "..", "examples", "src")
# Alternatively, use:
# joinpath(dirname(Base.find_package(@__MODULE__, "ITensors")),
#          "..", "examples", "src")
include(joinpath(examples_dir, "ctmrg_isotropic.jl"))
include(joinpath(examples_dir, "2d_classical_ising.jl"))

function run(; maxdim::Int,
               nsweeps::Int)
  # Make Ising model MPO
  β = 1.001 * βc
  d = 2
  s = Index(d, "site")
  sl = addtags(s, "left")
  sr = addtags(s, "right")
  su = addtags(s, "up")
  sd = addtags(s, "down")

  T = ising_mpo((sl, sr), (su, sd), β)

  χ0 = 1
  l = Index(χ0, "link")
  ll = addtags(l, "left")
  lu = addtags(l, "up")
  ld = addtags(l, "down")

  # Initial CTM
  Clu = ITensor(lu, ll)
  Clu[1,1] = 1.0

  # Initial HRTM
  Al = ITensor(lu, ld, sl)
  Al[lu(1), ld(1), sl(1)] = 1.0
  Al[lu(1), ld(1), sl(2)] = 0.0

  Clu, Al = ctmrg(T, Clu, Al;
                  χmax = maxdim, nsteps = nsweeps)

  # Normalize corner matrix
  trC⁴ = Clu *
         mapprime(Clu, 0 => 1; tags = "up") *
         mapprime(Clu, 0 => 1) *
         mapprime(Clu, 0 => 1; tags = "left")
  Clu = Clu / scalar(trC⁴) ^ (1/4)

  # Normalize MPS tensor
  trA² = Clu *
         mapprime(Clu, 0 => 1; tags = "up") *
         Al *
         mapprime(Al, 0 => 1; tags = "link") *
         mapprime(replacetags(mapprime(Clu, 0, 1, "up"), "up", "down"), 0, 1, "left")*
         replacetags(mapprime(Clu, 0, 1, "left"), "up", "down")
  Al = Al/sqrt(scalar(trA²))

  ## Get environment tensors for a single site measurement
  Ar = mapprime(replacetags(Al,"left","right","site"),0,1,"link")
  Au = replacetags(replacetags(replacetags(Al,"left","up","site"),
                                              "down","left","link"),
                                              "up","right","link")
  Ad  = mapprime(replacetags(Au,"up","down","site"),0,1,"link")
  Cld = mapprime(replacetags(Clu,"up","down"),0,1,"left")
  Cru = mapprime(replacetags(Clu,"left","right"),0,1,"up")
  Crd = replacetags(mapprime(Cru,0,1,"right"),"up","down")

  ## Calculate partition function per site
  κ = scalar(Clu * Al * Cld * Au * T * Ad * Cru * Ar * Crd)

  ## Calculate magnetization
  #Tsz = ising_mpo((sl,sr),(su,sd),β;sz=true)
  #m = scalar(Clu*Al*Cld*Au*Tsz*Ad*Cru*Ar*Crd)/κ
  # abs(m), ising_magnetization(β)

  return κ, exp(-β*ising_free_energy(β)), Clu
end

function main()
  run(; maxdim = 5, nsweeps = 2)
  maxdims = 20:20:40
  nsweeps = 500
  for maxdim_ in maxdims
    time = @elapsed κ, κ_exact, Clu = run(; maxdim = maxdim_,
                                            nsweeps = nsweeps)
    @show maxdim(Clu), time, κ, abs(κ - κ_exact)
  end
end

main()

