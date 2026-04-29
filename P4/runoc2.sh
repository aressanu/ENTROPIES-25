#!/bin/bash
# =============================================================
#  run_oriconf.sh  —  Entropia S_conf + S_ori
#
#  Edita T_vals i P_vals, després llança amb:
#      sbatch run_oriconf.sh
# =============================================================
#SBATCH -A upc94
#SBATCH -q gp_resc
#SBATCH --job-name=oriconf
#SBATCH --ntasks-per-node=28
#SBATCH --time=00-24:00:00
#SBATCH --output=oriconf_%j.out
#SBATCH --error=oriconf_%j.err
#SBATCH --partition=gpp
#SBATCH --cpus-per-task=4

# =============================================================
#  >>>  EDITA AQUÍ  <<<
T_vals=( $(seq 300 5 306) )    # Temperatures en K
P_vals=( $(seq 1 1000 2) )  # Pressions en bar
# =============================================================

module purge
module load oneapi/2024.2 gromacs/2023
module load miniforge
source activate upc94_env_2

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

OUTDIR=".."   # carpeta mare per Entropy_summary.txt

for P in "${P_vals[@]}"; do
for T in "${T_vals[@]}"; do

TAG="${T}_${P}_2"
echo "====== oriconf  T=${T} K  P=${P} bar ======"

echo -e "22\n19\n9\n13\n14" | srun -n 1 gmx_mpi energy \
    -f run_${TAG}.edr \
    -o ener_${TAG}.xvg


done
done

echo "===== run_oriconf.sh COMPLETAT ====="
