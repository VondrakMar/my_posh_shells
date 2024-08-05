import sys
from ase import Atoms
from ase.calculators.aims import Aims
from ase.io import read
mols = read(f"{sys.argv[1]}", format="extxyz")

aims_kwargs = {
    'xc': 'pbe',
    'relativistic': ("atomic_zora", "scalar"),
    'compute_forces': True,
    'k_grid': [3,3,3],
#    'charge': 1,
#    'fixed_spin_moment': 1,
    'override_illconditioning': True,
}

calc = Aims(command="srun -N 4 -n 288 /u/mvondrak/software/fhi-aims.231212_1/build/aims.231212_1.scalapack.mpi.x",
            species_dir="/u/mvondrak/software/fhi-aims.231212_1/species_defaults/defaults_2020/intermediate/",
            **aims_kwargs)
mols.calc = calc
mols.get_potential_energy()
