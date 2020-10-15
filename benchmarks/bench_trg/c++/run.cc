#include "sample/src/trg.h"
#include "sample/src/ising.h"
#include "itensor/util/print_macro.h"
#include <chrono>
#include <iostream>
#include <fstream>

std::tuple<Real, ITensor>
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  int nsweeps = args.getInt("NSweeps");

  Real betac = 0.5 * log(sqrt(2) + 1.0);
  Real beta = 1.001 * betac;
  int topscale = nsweeps;
  
  auto dim0 = 2;
  
  // Define an initial Index making up
  // the Ising partition function
  auto s = Index(dim0);
  
  // Define the indices of the scale-0
  // Boltzmann weight tensor "A"
  auto sh = addTags(s, "horiz");
  auto sv = addTags(s, "vert");
  
  auto A0 = ising(sh, sv, beta);
  auto [A, z] = trg(A0, maxdim, topscale);

  return std::tuple<Real, ITensor>({z, A});
  }

int
main()
  {
  int maxdim_first = 20;
  int maxdim_step = 20;
  int maxdim_last = 40;

  int nmaxdims = (maxdim_last - maxdim_first) / maxdim_step + 1;
  auto nsweeps = 20;
  auto maxdims = std::vector<int>(nmaxdims);
  auto times = std::vector<float>(nmaxdims);
  int maxdim = maxdim_first;

  std::cout.precision(16);

  for(auto j : range(nmaxdims))
    {
    auto start = std::chrono::high_resolution_clock::now();
    println("Running TRG on 2D classical Ising model and maxdim = ", maxdim);
    auto [kappa, T] = run({"Maxdim = ", maxdim,
                           "NSweeps = ", nsweeps});
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    auto time = elapsed.count();
    maxdims[j] = maxDim(T);
    times[j] = time;
    println("nsweeps = ", nsweeps);
    println("maxdim(T) = ", maxDim(T));
    println("kappa = ", kappa);
    println("time = ", time);
    println();
    maxdim += maxdim_step;
    }

  // Write results to file
  println("Writing results to data.txt");
  std::ofstream myfile;
  myfile.open("data.txt");
  for(auto j : range(nmaxdims))
    myfile << maxdims[j] << " " << times[j] << "\n";
  myfile.close();

  return 0;
  }

