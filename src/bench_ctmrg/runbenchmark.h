#include "sample/src/ctmrg.h"
#include "sample/src/ising.h"
#include <iostream>

int
run(Args const& args)
  {
  auto maxdim = args.getInt("Maxdim");
  auto outputlevel = args.getInt("OutputLevel", 0);
  auto nsweeps = args.getInt("NSweeps", 800);
  auto cutoff = args.getReal("Cutoff", 0.0);
  auto betac = 0.5 * log(sqrt(2) + 1.0);
  auto beta = args.getReal("beta", 1.001 * betac);
  
  // Define an initial Index making up
  // the Ising partition function
  auto s = Index(2, "Site");
  
  // Define the indices of the scale-0
  // Boltzmann weight tensor "A"
  auto sh = addTags(s, "horiz");
  auto sv = addTags(s, "vert");
  
  auto T = ising(sh, sv, beta);

  auto l = Index(1, "Link");
  auto lh = addTags(l, "horiz");
  auto lv = addTags(l, "vert");
  auto Clu0 = ITensor(lv, lh);
  Clu0.set(1, 1, 1.0);
  auto Al0 = ITensor(lv, prime(lv), sh);
  Al0.set(lv = 1, prime(lv) = 1, sh = 1, 1.0);
  auto [Clu, Al] = ctmrg(T, Clu0, Al0,
                         maxdim, nsweeps, cutoff);

  lv = commonIndex(Clu, Al);
  lh = uniqueIndex(Clu, Al);

  auto Au = replaceInds(Al, {lv, prime(lv), sh},
                            {lh, prime(lh), sv});

  auto ACl = Al * Clu * dag(prime(Clu));

  auto ACTl = prime(ACl * dag(prime(Au)) * T * Au, -1);
  auto kappa = elt(ACTl * dag(ACl));

  auto Tsz = ising(sh, sv, beta, true);
  auto ACTszl = prime(ACl * dag(prime(Au)) * Tsz * Au, -1);
  auto m = elt(ACTszl * dag(ACl)) / kappa;

  if(outputlevel > 0)
    {
    std::cout.precision(16);
    PrintData(nsweeps);
    std::cout << "beta = " << beta << std::endl;
    std::cout << "cutoff = " << cutoff << std::endl;
    std::cout << "kappa = " << kappa << std::endl;
    std::cout << "m = " << m << std::endl;
    PrintData(maxDim(Clu));
    }

  return maxDim(Clu);
  }

