#include "itensor/all.h"
#include "sample/src/electronk.h"
#include "sample/src/hubbard.h"
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

  int N = Nx * Ny;

  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(100, maxdim),
                    std::min(200, maxdim),
                    std::min(400, maxdim),
                    std::min(800, maxdim),
                    std::min(2000, maxdim),
                    std::min(10000, maxdim),
                    maxdim;

  sweeps.cutoff() = cutoff;
  sweeps.noise() = 1e-6, 1e-7, 1e-8, 0.0;

  SiteSet sites = ElectronK(N, {"Kmod = ", Ny,
                                "ConserveQNs = ", true,
                                "ConserveK = ", true});
  auto ampo = hubbard_2d_ky(sites, {"Nx = ", Nx,
                                    "Ny = ", Ny,
                                    "U = ", U});

  auto H = toMPO(ampo);

  // Create start state
  auto state = InitState(sites);
  for (auto i : range1(N))
    {
    int x = (i-1)/Ny;
    int y = (i-1)%Ny;

    if(x%2==0)
      {
      if (y%2==0) state.set(i,"Up");
      else        state.set(i,"Dn");
      }
    else
      {
      if (y%2==0) state.set(i,"Dn");
      else        state.set(i,"Up");
      }
    }

  auto psi0 = MPS(state);
  
  psi0.position(1);
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

