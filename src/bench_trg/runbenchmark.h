#include "itensor/all.h"
#include "sample/src/trg.h"
#include "sample/src/ising.h"
#include <iostream>

using namespace itensor;

int
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  int nsweeps = args.getInt("NSweeps", 20);
  int outputlevel = args.getInt("OutputLevel", 0);
  auto cutoff = args.getReal("Cutoff", 0.0);

  auto betac = 0.5 * log(sqrt(2) + 1.0);
  auto beta = args.getReal("beta", 1.001 * betac);
  
  // Define an initial Index making up
  // the Ising partition function
  auto s = Index(2);
  
  // Define the indices of the scale-0
  // Boltzmann weight tensor "A"
  auto sh = addTags(s, "horiz");
  auto sv = addTags(s, "vert");
  
  auto A0 = ising(sh, sv, beta);
  auto [A, kappa] = trg(A0, maxdim, nsweeps, cutoff);

  if(outputlevel > 0)
    {
    std::cout.precision(16);
    PrintData(nsweeps);
    PrintData(beta);
    PrintData(maxDim(A));
    std::cout << "kappa = " << kappa << std::endl;
    }
  return maxDim(A);
  }

