#!/bin/bash -l
#PBS -l select=64:system=sunspot
#PBS -l place=scatter
#PBS -l walltime=0:30:00
#PBS -q workq
#PBS -A Aurora_deployment


#####################################################################
# These are my own personal directories,
# you will need to change these.
#####################################################################
OUTPUT_DIR=/home/cadams/CosmicTagger/output-xpu-hvd-determ/
WORKDIR=/home/cadams/CosmicTagger/
cd ${WORKDIR}

NNODES=`wc -l < $PBS_NODEFILE`
NRANKS_PER_NODE=12
let NRANKS=${NNODES}*${NRANKS_PER_NODE}

#####################################################################
# APPLICATION Variables that make a performance difference for tf:
#####################################################################

# For most models, channels last is more performance on TF:
DATA_FORMAT="channels_last"
# DATA_FORMAT="channels_first"

# Precision for CT can be float32, bfloat16, or mixed (fp16).
PRECISION="float32"
# PRECISION="bfloat16"
# PRECISION="mixed"

# Adjust the local batch size:
LOCAL_BATCH_SIZE=8
let GLOBAL_BATCH_SIZE=${LOCAL_BATCH_SIZE}*${NRANKS}

# NOTE: batch size 8 works ok, batch size 16 core dumps, haven't explored
# much in between.  reduced precision should improve memory usage.

#####################################################################
# FRAMEWORK Variables that make a performance difference for tf:
#####################################################################

# Toggle tf32 on (or don't):
# ITEX_FP32_MATH_MODE=TF32
unset ITEX_FP32_MATH_MODE

# For cosmic tagger, this improves performance:
# (for reference, the default is "setenv ITEX_LAYOUT_OPT \"1\" ")
unset ITEX_LAYOUT_OPT

# This is a fix for running over 16 nodes:
export FI_CXI_DEFAULT_CQ_SIZE=131072
export FI_CXI_OVFLOW_BUF_SIZE=8388608
export FI_CXI_CQ_FILL_PERCENT=20

#####################################################################
# End of perf-adjustment section
#####################################################################


#####################################################################
# Environment set up, using the latest frameworks drop
#####################################################################

# module load frameworks/2023-01-31-experimental
# module load intel_compute_runtime/release/agama-devel-549
# module load frameworks/2022.12.30.001
module load frameworks/.2023.05.15.001
source /home/cadams/frameworks-2023-05-15-extension/bin/activate
module list

# source /home/cadams/frameworks-2023-01-31-extension/bin/activate
export NUMEXPR_MAX_THREADS=1


#####################################################################
# End of environment setup section
#####################################################################

#####################################################################
# JOB LAUNCH
# Note that this example targets a SINGLE TILE
#####################################################################


# This string is an identified to store log files:
run_id=sunspot-a21-tf-singltile-df${DATA_FORMAT}-p${PRECISION}-mb${LOCAL_BATCH_SIZE}-FP32-lr10x


#####################################################################
# Launch the script
# This section is to outline what the command is doing
#
# python bin/exec.py \						# Script entry point
# --config-name a21 \						# Aurora acceptance model
# framework=tensorflow \					# TF is default, but explicitly setting it
# output_dir=${OUTPUT_DIR}/${run_id} \		# Direct the output to this folder
# run.id=${run_id} \						# Pass the unique runID
# run.compute_mode=XPU \					# Explicitly set XPU as the target accelerator
# run.distributed=False \					# SINGLE-TILE: disable all collectives
# data.data_format=${DATA_FORMAT} \			# Set data format per user spec
# run.precision=${PRECISION} \				# Set precision per user spec
# run.minibatch_size=${LOCAL_BATCH_SIZE} \	# Set minibatch size per user spec
# run.iterations=250						# Run for 250 iterations.
#####################################################################

# ZE_AFFINITY_MASK=0.0,0.1,1.0,1.1,2.0,2.1,3.0,3.1,4.0,4.1,5.0,5.1
# ZE_AFFINITY_MASK=0.0
# CPU_AFFINITY=0:10:20:30:40:50:52:62:72:82:92:102

# CPU_AFFINITY=52
# --cpu-bind=verbose,list:${CPU_AFFINITY} \

ulimit -c 0


mpiexec -n ${NRANKS} -ppn ${NRANKS_PER_NODE} \
--depth=8 --cpu-bind=verbose,depth \
python bin/exec.py \
--config-name a21 \
framework=tensorflow \
output_dir=${OUTPUT_DIR}/${run_id} \
data=real \
data.data_directory=/lus/gila/projects/Aurora_deployment/cadams/cosmic_tagger/ \
run.id=${run_id} \
run.compute_mode=XPU \
run.distributed=True \
data.data_format=${DATA_FORMAT} \
mode.optimizer.learning_rate=0.003 \
run.precision=${PRECISION} \
run.minibatch_size=${GLOBAL_BATCH_SIZE} \
run.iterations=5000
