#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --job-name=blastn_blobtools
#SBATCH --output=blastn_blobtools_%j.out
#SBATCH --error=blastn_blobtools_%j.err

# Project variables
PROJECT_NAME="Pandi1"
ASSEMBLY_FILE="Pandi1_genomic.fasta"

files_dir=/local/workdir/$USER/blobtoolkit_${PROJECT_NAME}/files
blast_dir=/local/workdir/$USER/blobtoolkit_${PROJECT_NAME}/blast

# Add BLAST to path and set database location
export PATH=/programs/ncbi-blast-2.13.0+/bin:$PATH
export BLASTDB=/local/workdir/software/blobtoolkit/nt/

# Make output directory
mkdir -p ${blast_dir}
cd ${blast_dir}

# Run BLASTN
blastn \
  -db nt \
  -query ${files_dir}/${ASSEMBLY_FILE} \
  -outfmt "6 qseqid staxids bitscore std" \
  -max_target_seqs 5 \
  -max_hsps 1 \
  -evalue 1e-25 \
  -num_threads 16 \
  -out ${PROJECT_NAME}.ncbi.blastn.out