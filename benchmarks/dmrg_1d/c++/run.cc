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
  int nsweeps = args.getInt("NSweeps", 5);
  bool silent = args.getBool("Silent", false);

  int N = 100;
  auto sites = SpinOne(N, {"ConserveQNs = ", false});
  auto ampo = AutoMPO(sites);
  for(auto j : range1(N-1))
      {
      ampo += 0.5,"S+",j,"S-",j+1;
      ampo += 0.5,"S-",j,"S+",j+1;
      ampo +=     "Sz",j,"Sz",j+1;
      }
  auto H = toMPO(ampo);
  auto state = InitState(sites);
  for(auto i : range1(N))
      {
      if(i%2 == 1) state.set(i,"Up");
      else         state.set(i,"Dn");
      }
  auto psi0 = MPS(state);
  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = 10, 20, std::min(100, maxdim), std::min(100, maxdim), maxdim;
  sweeps.cutoff() = 1E-14;
  auto [energy, psi] = dmrg(H, psi0, sweeps,
                            {"Quiet = ", true,
                             "Silent = ", silent,
                             "SVDMethod = ", "gesdd"});
  return std::tuple<float, MPS>({energy, psi});
  }

int 
main()
  {
  int maxdim_first = 20;
  int maxdim_step = 20;
  int maxdim_last = 200;

  int nmaxdims = (maxdim_last - maxdim_first) / maxdim_step + 1;
  auto maxdims = std::vector<int>(nmaxdims);
  auto times = std::vector<float>(nmaxdims);
  int maxdim = maxdim_first;

  for(auto j : range(nmaxdims))
    {
    auto start = std::chrono::high_resolution_clock::now();
    auto [energy, psi] = run({"Maxdim = ", maxdim, "Silent = ", true});
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    auto time = elapsed.count();
    maxdims[j] = maxLinkDim(psi);
    times[j] = time;
    println()
    println("maxdim = ", maxLinkDim(psi));
    println("Time = ", time);
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

