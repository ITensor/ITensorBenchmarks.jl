#include "itensor/all.h"
#include <iostream>

using namespace itensor;

int
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  auto outputlevel = args.getInt("OutputLevel", 0);
  int N = args.getInt("N", 100);
  auto nsweeps = args.getInt("NSweeps", 5);
  auto cutoff = args.getReal("Cutoff", 0.0);
  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(10, maxdim),
                    std::min(20, maxdim),
                    std::min(100, maxdim),
                    maxdim;
  sweeps.cutoff() = cutoff;
  auto sites = SpinOne(N, {"ConserveQNs = ", false});
  auto ampo = AutoMPO(sites);
  for(auto j : range1(N-1))
      {
      ampo += 0.5, "S+", j, "S-", j + 1;
      ampo += 0.5, "S-", j, "S+", j + 1;
      ampo +=      "Sz", j, "Sz", j + 1;
      }
  auto H = toMPO(ampo);
  auto state = InitState(sites);
  for(auto j : range1(N))
    state.set(j, (j % 2 == 1 ? "Up" : "Dn"));
  auto psi0 = MPS(state);
  auto silent = true;
  // C++ DMRG is too noisy
  if(outputlevel > 0) silent = false;
  auto [energy, psi] = dmrg(H, psi0, sweeps,
                            {"Quiet = ", true,
                             "Silent = ", silent});
  if(outputlevel > 0) 
    {
    std::cout.precision(16);
    PrintData(nsweeps);
    PrintData(maxLinkDim(psi));
    std::cout << "energy = " << energy << std::endl;
    }
  return maxLinkDim(psi);
  }

