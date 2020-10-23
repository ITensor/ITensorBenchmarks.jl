#include "itensor/all.h"
#include "itensor/util/print_macro.h"
#include <chrono>
#include <iostream>
#include <fstream>
using namespace itensor;

std::tuple<float, MPS>
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  int nsweeps = args.getInt("NSweeps");
  bool silent = args.getBool("Silent");

  int N = 100;
  auto sites = SpinOne(N, {"ConserveQNs = ", true});
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
  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(10, maxdim),
                    std::min(20, maxdim),
                    std::min(100, maxdim),
                    std::min(100, maxdim),
                    maxdim;
  sweeps.cutoff() = 0.0;
  auto [energy, psi] = dmrg(H, psi0, sweeps,
                            {"Quiet = ", true,
                             "Silent = ", silent,
                             "SVDMethod = ", "gesdd"});
  return std::tuple<float, MPS>({energy, psi});
  }

int 
main()
  {
  int maxdim_first = 200;
  int maxdim_step = 200;
  int maxdim_last = 1000;

  int nmaxdims = (maxdim_last - maxdim_first) / maxdim_step + 1;
  auto nsweeps = 5;
  auto silent = true;
  auto maxdims = std::vector<int>(nmaxdims);
  auto times = std::vector<float>(nmaxdims);
  int maxdim = maxdim_first;

  std::cout.precision(16);

  for(auto j : range(nmaxdims))
    {
    auto start = std::chrono::high_resolution_clock::now();
    println("Running 1D Heisenberg model with QNs and maxdim = ", maxdim);
    auto [energy, psi] = run({"Maxdim = ", maxdim, "NSweeps = ", nsweeps, "Silent = ", silent});
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    auto time = elapsed.count();
    maxdims[j] = maxLinkDim(psi);
    times[j] = time;
    println("nsweeps = ", nsweeps);
    println("maxlinkdim(psi) = ", maxLinkDim(psi));
    println("flux(psi) = ", totalQN(psi));
    println("energy = ", energy);
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

