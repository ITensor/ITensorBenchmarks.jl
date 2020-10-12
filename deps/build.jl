
run(`git clone https://github.com/ITensor/ITensor.git itensor`)
run(`git checkout v3.1.4`)
cp("options.mk", "itensor/options.mk")
cd("itensor")
run(`make`)

