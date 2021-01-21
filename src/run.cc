#include "run.h"

int
main(int argc, char *argv[])
  {
  auto maxdim = std::stoi(argv[1]);
  auto outputlevel = 0;
  if(argc > 2)
    outputlevel = std::stoi(argv[2]);
  auto maxdim_ = run({"Maxdim = ", maxdim,
                      "OutputLevel = ", outputlevel});
  return 0;
  }

