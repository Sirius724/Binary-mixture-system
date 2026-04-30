#!/bin/sh
#$ -S /bin/sh
#$ -cwd
#$ -V
#$ -q all.q
#$ -pe mpi 1

mpirun -np 1 ./1D_CaseA ${T_SIM} ${H0_MAG} ${KAPPA}