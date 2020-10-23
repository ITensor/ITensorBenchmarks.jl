#include "sample/src/ctmrg.h"
#include "sample/src/ising.h"
#include "itensor/util/print_macro.h"
#include <chrono>
#include <iostream>
#include <fstream>

std::tuple<Real, Real, ITensor>
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  int nsweeps = args.getInt("NSweeps");

  Real betac = 0.5 * log(sqrt(2) + 1.0);
  Real beta = 1.001 * betac;
  
  auto dim0 = 2;
  
  // Define an initial Index making up
  // the Ising partition function
  auto s = Index(dim0, "Site");
  
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

  Real cutoff = 0.0;
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

  return std::tuple<Real, Real, ITensor>({kappa, m, Clu});
  }

int
main(int argc, char *argv[])
  {
  auto blas_num_threads = 1;
  if(argc > 1)
    blas_num_threads = std::stoi(argv[1]);

  int maxdim_first = 50;
  int maxdim_step = 50;
  int maxdim_last = 400;

  int nmaxdims = (maxdim_last - maxdim_first) / maxdim_step + 1;
  auto nsweeps = 800;
  int maxdim = maxdim_first;

  std::cout.precision(16);

  for(auto j : range(nmaxdims))
    {
    auto start = std::chrono::high_resolution_clock::now();
    println("Running CTMRG on 2D classical Ising model and maxdim = ", maxdim);
    auto [kappa, m, T] = run({"Maxdim = ", maxdim,
                              "NSweeps = ", nsweeps});
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    auto time = elapsed.count();
    println("nsweeps = ", nsweeps);
    println("maxdim(T) = ", maxDim(T));
    println("kappa = ", kappa);
    println("m = ", m);
    println("time = ", time);
    println();
    maxdim += maxdim_step;

    // Write results to file
    string filename = "data/data_blas_num_threads_" + std::to_string(blas_num_threads);
    filename += "_maxdim_" + std::to_string(maxDim(T)) + ".txt";
    println("Writing results to ", filename);
    println();
    std::ofstream myfile;
    myfile.open(filename);
    myfile << time << "\n";
    myfile.close();
    }

  return 0;
  }

