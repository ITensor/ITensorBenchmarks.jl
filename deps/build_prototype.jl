using GitCommand

cpp_itensor_version = get(ENV, "CPP_ITENSOR_VERSION", nothing)
if isnothing(cpp_itensor_version)
  error("""Environment variable CPP_ITENSOR_VERSION is not set so C++ ITensor will not be built automatically. Set it from within Julia with `ENV["CPP_ITENSOR_VERSION"] = "3.1.6"`, for example. Or start Julia with `CPP_ITENSOR_VERSION="3.1.6" julia` or `export CPP_ITENSOR_VERSION="3.1.6"; julia`. Once you have set the variable CPP_ITENSOR_VERSION, you can try rebuilding with `] build ITensorBenchmarks` at the Julia command prompt.""")
end

const deps_dir = @__DIR__
const cpp_itensor_dir = joinpath(deps_dir, "itensor_v$cpp_itensor_version")
if !isfile(joinpath(cpp_itensor_dir, "itensor", "core.h")) 
  println("Cloning C++ ITensor and checking out the desired version v$cpp_itensor_version.")
  git() do git
    run(`$git clone https://github.com/ITensor/ITensor.git $cpp_itensor_dir`)
  end
  git() do git
    run(`$git -C $cpp_itensor_dir checkout v$cpp_itensor_version`)
  end
  println("Finished cloning C++ ITensor, next we will try to build it.")
end
if !isfile(joinpath(cpp_itensor_dir, "lib", "libitensor.a"))
  options = joinpath(cpp_itensor_dir, "options.mk")
  if !isfile(options)
    options_sample = joinpath(deps_dir, "options.mk.sample")
    println("Need options.mk to build C++ ITensor.")
    println("First we are copying the file $options_sample to $options.")
    cp(options_sample, options)
  end
  println("Edit $options (for example with `edit(\"$options\")` at the Julia command line) to point to the proper location of your BLAS installation. You can use the instructions at http://www.itensor.org/docs.cgi?page=install&vers=cppv3.")
  println("Building C++ ITensor, this may take some time. Running command `make --directory=$cpp_itensor_dir`")
  cd(cpp_itensor_dir)
  run(`make --directory=$cpp_itensor_dir`)
end

