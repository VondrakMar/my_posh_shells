input_file=$1
shift

# Initialize parsing flags to false
parse_energy=false
parse_hirshfeld=false
parse_forces=false
parse_dip=false
# Loop through the remaining arguments to set flags
for arg in "$@"
do
  case $arg in
    energy)
      parse_energy=true
      ;;
    hirshfeld)
      parse_hirshfeld=true
      ;;
    forces)
      parse_forces=true
      ;;
    dipole)
      parse_dip=true
      ;;
    *)
      echo "Unknown argument: $arg"
      ;;  
  esac
done

if [ "$parse_energy" = true ]; then
    grep "FINAL SINGLE POINT ENERGY" orca.out | awk '{print $5}' > energy
fi

# Extract Hirshfeld charges from aims.out and append to the hirshfeld file if flag is set
if [ "$parse_hirshfeld" = true ]; then
    awk '/ATOM     CHARGE      SPIN/,/^$/' orca.out | grep -v 'ATOM' | grep -v 'TOTAL' | awk 'NF > 0 {print $3}' > hirshfeld 
fi

if [ "$parse_forces" = true ]; then
    awk '/CARTESIAN GRADIENT/{flag=1;getline;getline; next} /Difference to translation invariance:/{flag=0} flag' orca.out | awk '{print $4" "$5" "$6}'> forces
fi

if [ "$parse_dip" = true ]; then
    grep "Total Dipole Moment" orca.out | awk '{print $5" " $6" " $7}' > dip 
fi


python -c "
from ase.io import read, write
import numpy as np
from ase.units import Hartree,Bohr

# Read molecular structure from xyz file
mols = read('$input_file', format='xyz')
parse_hirshfeld = False
parse_dip = False
parse_forces=False
parse_energy=False

if '$parse_hirshfeld' == 'true':
    parse_hirshfeld = True
if '$parse_dip' == 'true':
    parse_dip = True
if '$parse_forces' == 'true':
    parse_forces = True
if '$parse_energy' == 'true':
    parse_energy = True

# Load data from the respective files if they exist
if parse_hirshfeld:
    hirshfeld_data = np.loadtxt('hirshfeld')
    mols.arrays['orca_hirshfeld'] = hirshfeld_data

if parse_dip:
    # this is now at a.u., has to change
    orca_dip = np.loadtxt('dip')
    mols.info['orca_dipole'] = orca_dip 

if parse_forces:
    forces_data = np.loadtxt('forces')
    mols.arrays['orca_forces'] = forces_data*(Hartree/Bohr)

if parse_energy:
    energy_data = np.loadtxt('energy')
    mols.info['orca_energy'] = energy_data*Hartree

# Write the updated molecule to a new xyz file
write('loaded_file.xyz', mols)
"

