#!/bin/bash

T_sim_list=(0.5 1.0 1.5 2.0 2.5 3.0)
h0_mag_list=(0.0 0.5 1.0 1.5 2.0 2.5 3.0)
kappa_list=(0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0)

mkdir -p outlog
mkdir -p results

for t in "${T_sim_list[@]}"; do
  for h in "${h0_mag_list[@]}"; do
    for k in "${kappa_list[@]}"; do
      qsub -N "Ising_T${t}_h${h}_k${k}" -o "outlog/sim_T${t}_h${h}_k${k}.log" -e "outlog/err_T${t}_h${h}_k${k}.log" -v T_SIM=$t,H0_MAG=$h,KAPPA=$k qsub.sh
    done
  done
done