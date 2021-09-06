"""Benchmark of the Spin-1 Heisenberg chain."""

import numpy as np

from tenpy.networks.mps import MPS
from tenpy.models.spins import SpinChain
from tenpy.algorithms import dmrg
from tenpy.tools import optimization
import time
import argparse


def benchmark_DMRG(max_chi=200, use_Sz=False):
    print("use_Sz = ", use_Sz)
    # S = 1 Heisenberg chain
    model_params = {
        # https://tenpy.readthedocs.io/en/latest/reference/tenpy.models.spins.SpinModel.html#cfg-config-SpinModel
        'L': 100,
        'S': 1,
        'Jx': 1, 'Jy': 1, 'Jz': 1,
        'hz': 0.,
        'bc_MPS':'finite',
        'conserve': 'Sz' if use_Sz else None,
    }
    M = SpinChain(model_params)
    psi = MPS.from_lat_product_state(M.lat, [['up'], ['down']])  # start from Neel state
    dmrg_params = {
        # https://tenpy.readthedocs.io/en/latest/reference/tenpy.algorithms.dmrg.TwoSiteDMRGEngine.html#cfg-config-TwoSiteDMRGEngine
        'trunc_params': {
            'chi_max': None,  # set by chi_list below
            'svd_min': 1.e-14,  # discard any singular values smaller than this
        },
        'chi_list': {
            # ramp-up the bond dimension with (sweep: max_chi) pairs
            0: 10,
            1: 20,
            2: 100,
            3: max_chi,  # after the 3rd sweep, use the full bond dimension
            # alternatively, directly set the `chi_max`.
        },
        'N_sweeps_check': 1,
        'min_sweeps': 5, 'max_sweeps': 5,  # explicitly fix the number of sweeps
        'mixer': None,  # no subspace expansion
        'diag_method': 'lanczos',
        'lanczos_params': {
            # https://tenpy.readthedocs.io/en/latest/reference/tenpy.linalg.lanczos.LanczosGroundState.html#cfg-config-Lanczos
            'N_max': 3,  # fix the number of Lanczos iterations: the number of `matvec` calls
            'N_min': 3,
            'N_cache': 20,  # keep the states during Lanczos in memory
            'reortho': False,
        },
    }
    optimization.set_level(3)   # disables a few consistency checks
    eng = dmrg.TwoSiteDMRGEngine(psi, M, dmrg_params)
    t0_proc = time.process_time()
    t0_wall = time.time()
    eng.run()
    proc_time = time.process_time() - t0_proc
    wall_time = time.time() - t0_wall
    print("process time: {0:.1f}s, wallclock time: {1:.1f}s".format(proc_time, wall_time))
    return proc_time, wall_time


if __name__ == "__main__":
    import sys
    if len(sys.argv) == 1:
        print('call as: \n', sys.argv[0] + ' MAX_CHI [cons_Sz]')
        exit(1)
    benchmark_DMRG(max_chi=int(sys.argv[1]), use_Sz=('cons_Sz' in sys.argv[2:]))
