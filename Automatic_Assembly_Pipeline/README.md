# Automated Illumina genome assembly pipeline

These pipeline and associated scripts assumes several things:

- You are running this on the Bushley BioHPC server. 
- You only have Illumina data (PE150) data that is composed of one forward and one reverse fastq file, per each of your input genomes.
- Your samples were not contaminated.
- You do not have a massive (>300Mb) genome, or an overly complex genome (e.g. Entomopthorales)

If your data does not meet ALL of these expectations, this is not the pipeline for you. This pipeline is only for the mass production of simple fungal genomes. Try looking over my other genome assembly walkthroughs to see which genome assembly pipeline is right for your data. 

---

## Step 0: Setting up your genome database

First, you need to make a project folder. This project folder will be where all of your analyses will take place. Let's say you want to make a folder called "genome_assembly" in your BioHPC workdir:

All you have to do is copy/paste this (don't change a single thing!): 

```bash
mkdir -p /workdir/$USER/projects/genome_assembly/
```

Then we need to make a folder within your project folder, to store your raw sequence reads. This folder needs to be called "raw_reads".

```bash
mkdir -p /workdir/$USER/projects/genome_assembly/raw_reads
```

All of your raw reads (.fastq, .fastq.gz) should be COPIED to this folder (all raw reads should always be backed up in their original form to storage). 

The software depends on short, informative genome names in order to organize your data.

For each of your samples, make a short, informative, unique prefix, and rename your input raw sequence data with this "ome" prefix. Housekeeping tip:  make sure you record which short name corresponds to which original file name. 

For example, if you had a *Metarhizium robertsii* sample with the strain name "ABC", you can call this sample MetrobABC and rename your input files like this:

MetrobABC_forward.fastq.gz
MetrobABC_reverse.fastq.gz

It doesn't matter if your files are gzipped or not, but the scripts assume that the naming convention of your input files have the ome code before "_forward" or "_reverse". Anything deviating from this pattern will not work.

Then, you need the run the very first of the script in order to create a "progress file" and add your genome names to this file. This file will allow you to easily see where each of your samples are in the genome assembly pipeline. 

If I was adding in my MetrobABC sample, I would run the following command:

```bash
python /workdir/kls345/projects/scripts/step0_addgenomes.py -p /workdir/$USER/projects/genome_assembly/ MetrobABC
```

If I had more samples I wanted to add, I could specify the SAME project directory and provide the new sample names:

```bash
python /workdir/kls345/projects/scripts/step0_addgenomes.py -p /workdir/$USER/projects/genome_assembly/ MetrobDEF BeabasABC
```

This command will automatically create a "progress file" in your specified project directory. 

You can look at what this file looks like by specifying the --list option with the step0 command:

```bash
python /workdir/kls345/projects/scripts/step0_addgenomes.py -p /workdir/$USER/projects/genome_assembly/ --list
```

Or you can just use `head`:

```bash
head /workdir/$USER/projects/genome_assembly/progress.csv
```

The csv progress file will look something like this:

   ome qc_trimming_jobID qc_trimming_datecomplete assembly_jobID assembly_datecomplete
MetrobABC                             
                                 
MetrobDEF         
                                                     
BeabasABC                                        

There will be columns for each stage of the pipeline - both for job ID and the date of completion. 

From now on, if you want to work with these genomes, you need to specify this specific project directory with "-p" in each of your pipeline commands. 

If you want to remove a sample from the progress list, so that it is not automatically considered in any future analyses, you can remove it like this:

```bash
python /workdir/kls345/projects/scripts/step0_addgenomes.py -p /workdir/$USER/projects/genome_assembly/ --remove
```

---

<br>

## Step 1: Quality check and trimming

This step uses [fastp](https://github.com/OpenGene/fastp) to perform read quality checks on your input raw sequence files, then trims/filters this data with default parameters, then performs quality checks on the trimmed sequence files. 

You can automatically set up fastp jobs for ALL of your genomes in your progress file by running the step1 command:

```bash
python /workdir/kls345/projects/scripts/step1_qc_trimming.py -p /workdir/$USER/projects/genome_assembly/
```

This will automatically submit a separate fastp job for ALL of the genomes in your progress file, if they don't already have a jobID recorded. 

If you want to submit a fastp job for only one genome, or a particular set of genomes, you can specify the ome codes after the step1 command:

```bash
python /workdir/kls345/projects/scripts/step1_qc_trimming.py -p /workdir/$USER/projects/genome_assembly/ MetrobABC MetrobDEF
```

If you want to re-run this step (for any or all genomes), you can specify the option --redo in the command and it will remove the old files and re-run the fastp job. Like this:

```bash
python /workdir/kls345/projects/scripts/step1_qc_trimming.py --redo -p /workdir/$USER/projects/genome_assembly/ MetrobABC
```

Once the trimming step is complete, you need to update your progress file to indicate that this step is done. You can do this by running the step1_check command:

```bash
python /workdir/kls345/projects/scripts/step1_check.py -p /workdir/$USER/projects/genome_assembly/
```
This will input the date of trimming completion into your progress file. Note that you need to run this step before moving onto genome assembly. 

So now, when you run the --list command with the step0 command:

```bash
python /workdir/kls345/projects/scripts/step0_addgenomes.py -p /workdir/$USER/projects/genome_assembly/ --list
```

You should see the job IDs and the date of completion for all your samples:

   ome qc_trimming_jobID qc_trimming_datecomplete assembly_jobID assembly_datecomplete
   
Amcle1              1105               2025-09-24        
   
Amroe1              1103               2025-09-24     
      
Amgro1              1104               2025-09-24          


FYI - your samples will not be considered by the following steps unless they are successfully marked as completed in the progress file. 

---
 
<br>

## Step 2: Genome assembly

This step uses [SPAdes](https://github.com/ablab/spades) to assemble your trimmed sequences. 

Just the same as the step1_qc_trimming step, running this command will submit spades jobs for each of the genomes in your progress file that have not already been assembled.

You can automatically set up SPAdes assembly jobs for ALL of your genomes in your progress file by running the step2 command:

```bash
python /workdir/kls345/projects/scripts/step2_assembly.py -p /workdir/$USER/projects/genome_assembly/
```

You can also specify particular ome code(s), as before. 

This step runs spades with the following kmer lengths: 21,33,55,77,99,121

You can check the status of each of your assembly jobs using SLURM commands:

```bash
squeue --me
```

Same as step1, you can redo some or all assemblies with the --redo option in the step2 command. 

When your assemblies have finished, you need to update your progress sheet with the following command:

```bash
python /workdir/kls345/projects/scripts/step2_assembly.py -p /workdir/$USER/projects/genome_assembly/
```

Same as before, when you view the progress sheet with the step0 --list command, you should see the jobIDs and the date of completion for all your samples. 

   ome qc_trimming_jobID qc_trimming_datecomplete assembly_jobID assembly_datecomplete
   
Amcle1              1105               2025-09-24           1109            2025-09-26

Amroe1              1103               2025-09-24           1110            2025-09-26

Amgro1              1104               2025-09-24           1111            2025-09-26









