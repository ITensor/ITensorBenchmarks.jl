#include "itensor/all.h"
#include <iostream>

using namespace itensor;

int
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  auto outputlevel = args.getInt("OutputLevel", 0);
  int Nx = args.getInt("Nx", 8);
  int Ny = args.getInt("Ny", 4);
  auto U = args.getReal("U", 4.0);
  auto t = args.getReal("t", 1.0);
  int nsweeps = args.getInt("NSweeps", 10);
  auto cutoff = args.getReal("Cutoff", 0.0);

  auto N = Nx * Ny;
  auto sites = Electron(N, {"ConserveQNs = ", true});
  auto ampo = AutoMPO(sites);
  auto lattice = squareLattice(Nx, Ny, {"YPeriodic=",true});
  for(auto j : lattice)
    {
    ampo += -t, "Cdagup", j.s1, "Cup", j.s2;
    ampo += -t, "Cdagup", j.s2, "Cup", j.s1;
    ampo += -t, "Cdagdn", j.s1, "Cdn", j.s2;
    ampo += -t, "Cdagdn", j.s2, "Cdn", j.s1;
    }
  for(auto j : range1(N))
    ampo += U, "Nupdn", j;
  auto H = toMPO(ampo);
  auto state = InitState(sites);
  for(auto j : range1(N))
    state.set(j, (j % 2 == 1 ? "Up" : "Dn"));
  auto psi0 = MPS(state);
  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(100, maxdim),
                    std::min(200, maxdim),
                    std::min(400, maxdim),
                    std::min(800, maxdim),
                    std::min(2000, maxdim),
                    std::min(3000, maxdim),
                    maxdim;
  sweeps.noise() = 1E-6, 1E-7, 1E-8, 0;
  sweeps.cutoff() = 0.0;
  auto silent = true;
  if(outputlevel > 0) silent = false;
  auto [energy, psi] = dmrg(H, psi0, sweeps,
                            {"Quiet = ", true,
                             "Silent = ", silent});
  if(outputlevel > 0)
    {
    std::cout.precision(16);
    PrintData(nsweeps);
    PrintData(Nx);
    PrintData(Ny);
    PrintData(U);
    PrintData(t);
    PrintData(cutoff);
    PrintData(maxLinkDim(psi));
    PrintData(totalQN(psi));
    std::cout << "energy = " << energy << std::endl;
    }
  return maxLinkDim(psi);
  }

