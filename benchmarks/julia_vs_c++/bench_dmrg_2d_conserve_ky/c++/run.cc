#include "itensor/all.h"
#include "sample/src/electronk.h"
#include "sample/src/hubbard.h"
#include "itensor/util/print_macro.h"
#include <chrono>
#include <iostream>
#include <fstream>
using namespace itensor;

std::tuple<float, MPS>
run(Args const& args)
  {
  int maxdim = args.getInt("Maxdim");
  int nsweeps = args.getInt("NSweeps", 10);
  bool silent = args.getBool("Silent", false);

  int Nx = 6;
  int Ny = 3;
  double U = 4.0;
  double t = 1.0;

  int N = Nx * Ny;

  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(100, maxdim),
                    std::min(200, maxdim),
                    std::min(400, maxdim),
                    std::min(800, maxdim),
                    std::min(2000, maxdim),
                    std::min(3000, maxdim),
                    maxdim;

  sweeps.cutoff() = 0.0;
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
                             "Silent = ", silent});
  return std::tuple<Real, MPS>({energy, psi});
  }

int
main()
  {
  int maxdim_first = 1000;
  int maxdim_step = 1000;
  int maxdim_last = 5000;

  int nmaxdims = (maxdim_last - maxdim_first) / maxdim_step + 1;
  auto nsweeps = 10;
  auto silent = true;
  auto maxdims = std::vector<int>(nmaxdims);
  auto times = std::vector<float>(nmaxdims);
  int maxdim = maxdim_first;

  std::cout.precision(16);

  for(auto j : range(nmaxdims))
    {
    auto start = std::chrono::high_resolution_clock::now();
    println("Running 2D Hubbard model with momentum around the cylinder conserved and maxdim = ", maxdim);
    auto [energy, psi] = run({"Maxdim = ", maxdim,
                              "NSweeps = ", nsweeps,
                              "Silent = ", silent});
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

