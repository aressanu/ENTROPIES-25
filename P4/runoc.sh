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
T_vals=( $(seq 330 5 336) )    # Temperatures en K
P_vals=( $(seq 4000 1000 4001) )  # Pressions en bar
# =============================================================

module purge
module load oneapi/2024.2 gromacs/2023
module load miniforge
source activate upc94_env_2

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

OUTDIR=".."   # carpeta mare per Entropy_summary.txt

for P in "${P_vals[@]}"; do
for T in "${T_vals[@]}"; do

TAG="${T}_${P}"
echo "====== oriconf  T=${T} K  P=${P} bar ======"

MDP_LOCAL="NPT_oriconf_${TAG}.mdp"
cp NPT.mdp "$MDP_LOCAL"
sed -i "s/^ref_t[[:space:]]*=.*/ref_t                    = ${T}/" "$MDP_LOCAL"
sed -i "s/^ref_p[[:space:]]*=.*/ref_p                    = ${P}/" "$MDP_LOCAL"

srun -n 1 gmx_mpi grompp \
    -f "$MDP_LOCAL" \
    -c confout_${T}.gro \
    -p topol.top \
    -o run_${TAG}.tpr \
    -maxwarn 1

srun -n 28 gmx_mpi mdrun \
    -deffnm run_${TAG} \
    -v

echo -e "22\n19\n9\n13\n14" | srun -n 1 gmx_mpi energy \
    -f run_${TAG}.edr \
    -o ener_${TAG}.xvg

# ============ ORI ============
echo -e "0\n" | srun -n 1 gmx_mpi trjconv \
    -f run_${TAG}.trr \
    -s run_${TAG}.tpr \
    -o steps_.pdb \
    -pbc whole -sep \
    -dt 5 \
    -e 5000

if [[ ! -f "trd.con" ]]; then
    echo "ERROR: No existeix trd.con"; exit 1
fi
./traductor trd.con

ANG_ORI="ang_ori_${TAG}.dat"
cp angula.con angula_ori_${TAG}.con
sed -i "s|^ang_.*\.dat|${ANG_ORI}|" "angula_ori_${TAG}.con"
./angula "angula_ori_${TAG}.con"
rm -f steps_*.pdb
rm -f "angula_ori_${TAG}.con"

# ============ CONF ============
echo -e "0\n" | srun -n 1 gmx_mpi trjconv \
    -f run_${TAG}.trr \
    -s run_${TAG}.tpr \
    -o steps_.pdb \
    -pbc whole -sep \
    -dt 10

./traductor trd.con

ANG_CONF="ang_conf_${TAG}.dat"
cp angula.con angula_conf_${TAG}.con
sed -i "s|^ang_.*\.dat|${ANG_CONF}|" "angula_conf_${TAG}.con"
./angula "angula_conf_${TAG}.con"
rm -f steps_*.pdb
rm -f "angula_conf_${TAG}.con"

# ============ ENTROPIA ============
if [[ -f "$ANG_ORI" && -f "$ANG_CONF" ]]; then
    python3 entropyoriconf.py "$ANG_ORI" "$ANG_CONF" "$T" "$P" "$OUTDIR"
else
    echo "ERROR: Falten fitxers ang_ori o ang_conf"; exit 1
fi

rm -f "$MDP_LOCAL" *.cfg*
# Descomenta per estalviar espai:
# rm -f run_${TAG}.trr

echo "T=${T} P=${P} completat"
echo ""

done
done

echo "===== run_oriconf.sh COMPLETAT ====="
