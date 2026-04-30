#!/bin/bash

# --- 시뮬레이션 파라미터 리스트 ---
T_sim_list=(2.0 2.5 3.0)
h0_mag_list=(1.5)
kappa_list=(0.1)

# 0. 로그 및 최종 결과를 저장할 디렉토리 생성
mkdir -p logs
mkdir -p results

echo "Submitting jobs to the cluster..."

# 1. 중첩 루프를 돌며 모든 파라미터 조합에 대해 개별 작업 제출
for t in "${T_sim_list[@]}"; do
  for h in "${h0_mag_list[@]}"; do
    for k in "${kappa_list[@]}"; do
      
      echo " -> Submitting: T_sim=$t, h0_mag=$h, kappa=$k"
      # -v 옵션으로 변수를 qsub.sh에 전달, -N으로 고유 작업 이름 설정, -o로 개별 로그파일 지정
      qsub -N "Ising_${t}_${h}_${k}" -o "logs/sim_${t}_${h}_${k}.log" -v T_SIM=$t,H0_MAG=$h,KAPPA=$k qsub.sh
      
    done
  done
done

echo "All jobs submitted successfully!"