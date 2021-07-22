include("settings.jl")

makedocs(; sitename=sitename, settings...)

deploydocs(; repo="github.com/ITensor/ITensorsBenchmarks.jl.git", devbranch="main", push_preview=true)
