#!/bin/sh
#$ -S /bin/sh
#$ -cwd
#$ -V
#$ -q gpu.q
#$ -l gpu=1
#$ -pe mpi 1

# 실행 시 뒤에 붙여준 외부 변수(인자) 3개를 순서대로 받습니다.
# (단, main.sh처럼 -v로 환경변수가 이미 넘어왔다면 그 값을 유지하도록 방어 코드 추가)
T_SIM=${T_SIM:-$1}
H0_MAG=${H0_MAG:-$2}
KAPPA=${KAPPA:-$3}

echo "=========================================================="
echo "Job ID: ${JOB_ID}"
echo "Started on: $(date)"
echo "Running on host: $(hostname)"
echo "Assigned GPU: $SGE_HGR_gpu"
echo "=========================================================="

# --- Just-In-Time Compilation on the Compute Node ---
echo "Loading modules for compilation..."
# 계산 노드에 설치된 모듈을 로드합니다.
module load cuda
module load mpi/openmpi-gnu

echo "Compiling the code on $(hostname)..."
# Makefile을 사용하여 코드를 컴파일합니다.
make clean > /dev/null 2>&1
make
if [ $? -ne 0 ]; then
    echo "Compilation failed. Aborting job."
    exit 1
fi
echo "Compilation successful."
echo "=========================================================="

echo "Running with parameters: T_sim=${T_SIM}, h0_mag=${H0_MAG}, kappa=${KAPPA}"
# SGE_HGR_gpu 변수가 비어있지 않은 경우에만 덮어쓰기 (빈 문자열이면 기존 설정 유지)
if [ -n "$SGE_HGR_gpu" ]; then
    export CUDA_VISIBLE_DEVICES=$SGE_HGR_gpu
fi
echo "Currently visible GPUs (CUDA_VISIBLE_DEVICES): $CUDA_VISIBLE_DEVICES"

# Execute the MPI program. It will run on 1 core as requested by qsub.sh
mpirun -np 1 ./1D_CaseA ${T_SIM} ${H0_MAG} ${KAPPA}
echo "Job finished on: $(date)"
echo "=========================================================="