#!/bin/bash

echo "Loading required modules..."
# Load modules required for compilation (adjust names if necessary)
module load cuda
module load mpi/openmpi-gnu

echo "Compiling the CUDA/MPI code..."
make clean
make
echo "Compilation finished."