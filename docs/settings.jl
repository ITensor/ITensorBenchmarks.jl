using Documenter, ITensorsBenchmarks

#DocMeta.setdocmeta!(ITensors, :DocTestSetup, :(using ITensors); recursive=true)

sitename = "ITensorsBenchmarks"

settings = Dict(
  :modules => [ITensorsBenchmarks],
  :pages => [
    "Introduction" => "index.md",
    "TeNPy and ITensor Comparisons" => "tenpy_itensor/index.md",
    #"Getting Started with ITensor" => [
    #  "Installing Julia and ITensor" => "getting_started/Installing.md",
    #  "Running ITensor and Julia Codes" => "getting_started/RunningCodes.md",
    #  "Next Steps" => "getting_started/NextSteps.md",
    #],
  ],
  :format => Documenter.HTML(; assets=["assets/favicon.ico"], prettyurls=false),
  :doctest => true,
  :checkdocs => :none,
)
