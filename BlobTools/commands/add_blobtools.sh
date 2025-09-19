#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=40G
#SBATCH --partition=regular
#SBATCH --job-name=blobtools_add
#SBATCH --output=blobtools_add_%j.out
#SBATCH --error=blobtools_add_%j.err

# Project variables
PROJECT_NAME="Pandi1"

blob_dir=/local/workdir/$USER/blobtoolkit_${PROJECT_NAME}
blast_dir=${blob_dir}/blast
map_dir=${blob_dir}/map

# Activate BlobTools environment
source /programs/miniconda3/bin/activate btk_env
export BTK_ROOT=/programs/blobtoolkit-2.6.3

# Run blobtools add
$BTK_ROOT/blobtools2/blobtools add \
    --hits ${blast_dir}/${PROJECT_NAME}.ncbi.blastn.out \
    --cov ${map_dir}/${PROJECT_NAME}.bam \
    --threads 16 \
    --taxrule bestsumorder \
    --taxdump /local/workdir/software/blobtoolkit/taxdump/ \
    ${blob_dir}
