#!/bin/sh
#$ -S /bin/sh
#$ -cwd
#$ -V
#$ -q all.q

#$ -l gpu=1
#$ -pe mpi 20

# 실행 시 뒤에 붙여준 외부 변수(인자) 3개를 순서대로 받습니다.
T_SIM=$1
H0_MAG=$2
KAPPA=$3

echo "=========================================================="
echo "Job ID: ${JOB_ID}"
echo "Started on: $(date)"
echo "Running on host: $(hostname)"
echo "Running with parameters: T_sim=${T_SIM}, h0_mag=${H0_MAG}, kappa=${KAPPA}"
echo "Assigned GPU: $SGE_HGR_gpu"
echo "=========================================================="

# Set the visible CUDA device to the one assigned by SGE
export CUDA_VISIBLE_DEVICES=$SGE_HGR_gpu

# Execute the MPI program. It will run on 20 cores as requested by multi_qsub.sh
mpirun -np 20 ./1D_CaseA ${T_SIM} ${H0_MAG} ${KAPPA}
echo "Job finished on: $(date)"
echo "=========================================================="