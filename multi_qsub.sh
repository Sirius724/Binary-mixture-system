#!/bin/bash

# --- Simulation Parameter Lists ---
T_sim_list=(0.5 1.0 1.5 2.0 2.5 3.0)
h0_mag_list=(0.0 0.5 1.0 1.5 2.0 2.5 3.0)
kappa_list=(0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0)

# Create directories for logs and results
mkdir -p outlog
mkdir -p results

echo "Submitting jobs to the SGE cluster..."

# Loop through all parameter combinations and submit individual jobs
for t in "${T_sim_list[@]}"; do
  for h in "${h0_mag_list[@]}"; do
    for k in "${kappa_list[@]}"; do
      
      echo " -> Submitting: T_sim=$t, h0_mag=$h, kappa=$k"
      # Use qsub to submit the job.
      # 외부 변수 $t, $h, $k 를 qsub.sh 뒤에 차례대로 붙여서 아주 직관적으로 넘깁니다.
      qsub -N "Ising_T${t}_h${h}_k${k}" -o "outlog/sim_T${t}_h${h}_k${k}.log" -e "outlog/err_T${t}_h${h}_k${k}.log" qsub.sh $t $h $k
      
    done
  done
done

echo "All jobs submitted successfully!"