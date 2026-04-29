#!/bin/bash
# =============================================================
#  run_vib.sh  —  Entropia vibracional S_vib
#
#  Edita T_vals i P_vals, després llança amb:
#      sbatch run_vib.sh
# =============================================================
#SBATCH -A upc94
#SBATCH -q gp_resc
#SBATCH --job-name=svib
#SBATCH --ntasks-per-node=28
#SBATCH --time=00-24:00:00
#SBATCH --output=svib_%j.out
#SBATCH --error=svib_%j.err
#SBATCH --partition=gpp
#SBATCH --cpus-per-task=4

# =============================================================
#  >>>  EDITA AQUÍ  <<<
T_vals=( $(seq 330 5 331) )
P_vals=( $(seq 4000 1000 4001) )
nsteps_vals=(40000 50000 60000 70000 80000)   # nsteps per fer la mitjana
# =============================================================

module purge
module load oneapi/2024.2 gromacs/2023
module load miniforge
source activate upc94_env_2

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

OUTDIR="."   # carpeta mare → S_vib.txt anirà allà

for P in "${P_vals[@]}"; do
for T in "${T_vals[@]}"; do

    TAG="${T}_${P}"
    echo "====== svib  T=${T} K  P=${P} bar ======"
    S_vals=()

    for nsteps in "${nsteps_vals[@]}"; do
        echo "--- nsteps=${nsteps} ---"

        MDP_LOCAL="NPT_v_${TAG}_${nsteps}.mdp"
        cp NPT_v.mdp "$MDP_LOCAL"
        sed -i "s/^ref_t[[:space:]]*=.*/ref_t                    = ${T}/" "$MDP_LOCAL"
        sed -i "s/^ref_p[[:space:]]*=.*/ref_p                    = ${P}/" "$MDP_LOCAL"
        sed -i "s/^nsteps[[:space:]]*=.*/nsteps                   = ${nsteps}/" "$MDP_LOCAL"

        TPR="run_vib_${TAG}_${nsteps}.tpr"
        TRR="run_vib_${TAG}_${nsteps}.trr"

        srun -n 1 gmx_mpi check -f run_vib_330_4000_40000.trr

        rm -f run_${T}_${nsteps}.trr_offsets.npz

        if [[ -f "$TRR" && -f "$TPR" ]]; then
            S=$(python3 entropyvibtrr.py "$T" "$nsteps" "$TRR" "$TPR")
            echo "T=${T} P=${P} nsteps=${nsteps} S_vib=${S}"
            S_vals+=("$S")
        else
            echo "ERROR: Falten fitxers per T=${T} P=${P} nsteps=${nsteps}"
        fi

        #rm -f "$TRR" "$MDP_LOCAL"
    done
    python3 entropyvibmitjana.py "$T" "$P" "$OUTDIR" "${S_vals[@]}"

    echo "T=${T} P=${P} completat"
    echo ""

done
done

#rm run_vib* confout_vib*

echo "===== run_vib.sh COMPLETAT ====="
