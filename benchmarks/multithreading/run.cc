#include <itensor/all.h>
#include "sample/src/electronk.h"
#include "sample/src/hubbard.h"

using namespace itensor;

int
main(int argc, char *argv[])
  {
  auto maxdim = 10000;
  if(argc > 1)
    maxdim = std::stoi(argv[1]);

  int Nx = 8;
  int Ny = 4;
  double U = 4.0;

  double t = 1.0;

  int N = Nx * Ny;

  auto sweeps = Sweeps(10);
  sweeps.maxdim() = std::min(100, maxdim),
                    std::min(200, maxdim),
                    std::min(400, maxdim),
                    std::min(800, maxdim),
                    std::min(2000, maxdim),
                    std::min(10000, maxdim),
                    maxdim;

  sweeps.cutoff() = 0;
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
  auto [energy, psi] = dmrg(H, psi0, sweeps,
                            {"Quiet = ", true,
                             "Silent = ", false});
  PrintData(maxLinkDim(psi));
  PrintData(energy);

  return 0;
  }
