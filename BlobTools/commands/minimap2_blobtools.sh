#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=40G
#SBATCH --partition=regular
#SBATCH --job-name=minimap2_blobtools
#SBATCH --output=minimap2_blobtools_%j.out
#SBATCH --error=minimap2_blobtools_%j.err

# Project variables
PROJECT_NAME="Pandi1"
ASSEMBLY_FILE="Pandi1_genomic.fasta"
READS_FILE="Pandi1.fastq"

blob_dir=/local/workdir/$USER/blobtoolkit_${PROJECT_NAME}
files_dir=${blob_dir}/files
map_dir=${blob_dir}/map

# Add minimap2 and samtools to path
export PATH=/programs/minimap2-2.28:$PATH
export PATH=/programs/samtools-1.20/bin:$PATH

# Make output directory
mkdir -p ${map_dir}
cd ${map_dir}

# Run minimap2 (example for PacBio HiFi reads)
minimap2 \
  -ax map-hifi \
  -t 40 \
  ${files_dir}/${ASSEMBLY_FILE} \
  ${files_dir}/${READS_FILE} \
  > ${PROJECT_NAME}.sam

# Convert SAM to sorted BAM
samtools sort \
  --threads 16 \
  -O BAM \
  -o ${PROJECT_NAME}.bam \
  ${PROJECT_NAME}.sam