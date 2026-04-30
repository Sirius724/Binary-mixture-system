#!/bin/bash

T_sim_list=(2.0 2.5 3.0)
h0_mag_list=(1.5)
kappa_list=(0.1)

mkdir -p logs
mkdir -p results

for t in "${T_sim_list[@]}"; do
  for h in "${h0_mag_list[@]}"; do
    for k in "${kappa_list[@]}"; do
      qsub -N "Ising_${t}_${h}_${k}" -o "logs/sim_${t}_${h}_${k}.log" -e "logs/err_${t}_${h}_${k}.log" -v T_SIM=$t,H0_MAG=$h,KAPPA=$k qsub.sh
    done
  done
done