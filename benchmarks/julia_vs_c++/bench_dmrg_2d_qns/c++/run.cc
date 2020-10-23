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
  int nsweeps = args.getInt("NSweeps", 10);
  bool silent = args.getBool("Silent", false);

  auto Nx = 6,
       Ny = 3;
  auto N = Nx * Ny;
  auto sites = Electron(N, {"ConserveQNs = ", true});
  auto t = 1.0;
  auto U = 8.0;
  auto ampo = AutoMPO(sites);
  auto lattice = squareLattice(Nx, Ny, {"YPeriodic=",true});
  for(auto j : lattice)
    {
    ampo += -t, "Cdagup", j.s1, "Cup", j.s2;
    ampo += -t, "Cdagup", j.s2, "Cup", j.s1;
    ampo += -t, "Cdagdn", j.s1, "Cdn", j.s2;
    ampo += -t, "Cdagdn", j.s2, "Cdn", j.s1;
    }
  for(auto j : range1(N))
    ampo += U, "Nupdn", j;
  auto H = toMPO(ampo);
  auto state = InitState(sites);
  for(auto j : range1(N))
    state.set(j, (j % 2 == 1 ? "Up" : "Dn"));
  auto psi0 = MPS(state);
  auto sweeps = Sweeps(nsweeps);
  sweeps.maxdim() = std::min(20, maxdim),
                    std::min(60, maxdim),
                    std::min(100, maxdim),
                    std::min(100, maxdim),
                    std::min(200, maxdim),
                    std::min(400, maxdim),
                    std::min(800, maxdim),
                    maxdim;
  sweeps.noise() = 1E-7, 1E-8, 1E-10, 0, 1E-11, 0;
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

