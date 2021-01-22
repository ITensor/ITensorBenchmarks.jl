println("This is where we will try to build C++ ITensor")

using GitCommand

cpp_itensor_version = get(ENV, "CPP_ITENSOR_VERSION", nothing)
if isnothing(cpp_itensor_version)
  error("""Environment variable CPP_ITENSOR_VERSION is not set so C++ ITensor will not be built automatically. Set it from within Julia with `ENV["CPP_ITENSOR_VERSION"] = "3.1.6"`, for example. Or start Julia with `CPP_ITENSOR_VERSION="3.1.6" julia` or `export CPP_ITENSOR_VERSION="3.1.6"; julia`. Once you have set the variable CPP_ITENSOR_VERSION, you can try rebuilding with `] build ITensorsBenchmarks` at the Julia command prompt.""")
end

const deps_dir = @__DIR__
const itensor_dir = joinpath(deps_dir, "itensor_v$cpp_itensor_version")
if !isdir(itensor_dir)
  git() do git
    run(`$git clone https://github.com/ITensor/ITensor.git $itensor_dir`)
  end
  cp(joinpath(deps_dir, "options.mk"), joinpath(itensor_dir, "options.mk"))
  cd(itensor_dir)
  git() do git
    run(`$git checkout v$cpp_itensor_version`)
  end
  # XXX: this isn't working right now
  #run(`make -j`)
end
println("Now enter the directory $itensor_dir and type `make` at the command line to build C++ ITensor")

