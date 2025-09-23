# Making Single-Gene, Multi-Gene, and Phylogenomic Trees (for BioHPC)


## Introduction

### Types of Phylogenetic Trees

- A **single-gene tree** is created using one locus (e.g., Beta-tubulin) across multiple organisms or strains.  

- A **multi-gene tree** uses two or more common loci (e.g., Beta-tubulin and TEF1).

- A **phylogenomic tree** is a special case of multi-gene trees that use many, many loci (often single-copy orthologs, SCOs) found across a set of genomes.  

<br>

### Notes on Creating Trees

- Resolution suffers if all genes are not present for every strain.  

- The final product of different single-gene trees across the same set of strains may conflict, depending on the chosen loci. Different genes are better/worse at resolving taxonomy depending on the taxa in question. 

- ITS (Internal Transcribed Spacer) is the standard go-to for fungal identification/creating trees, but it is by no means perfect. ITS lacks resolution for deeper relationships (e.g., within genera or families) and may give conflicting results between groups. 

- Database sequences labeled as the same region (e.g., “ITS”) may actually differ depending on the primers used. Check your gene alignments to make sure you have the same locus across all strains. 

<br>

---

<br>

## Before You Begin

### Software Requirements

Make note of where you download this software. 

- [IQ-TREE](http://www.iqtree.org/) – Tree creation  
- [Figtree](https://github.com/rambaut/figtree/releases) – Tree visualization  
- Sequence trace viewers (optional): [4Peaks (Mac)](https://nucleobytes.com/4peaks/index.html) or [Chromas (Windows)](http://technelysium.com.au/wp/chromas/)  
- [Mesquite](https://www.mesquiteproject.org/Installation.html) – Alignment GUI  
- [MAFFT](https://mafft.cbrc.jp/alignment/software/) – Alignment  

### Notes on this Walkthrough

For training purposes, this walkthrough focuses on manual sequence acquisition, alignment, and tree construction. However, manual acquisition is slow and prone to human error; for automated NCBI data and metadata retrieval, check out my R script set [aRborist](https://github.com/KScott6/aRborist_walkthrough).

Once you feel like you understand each step of the pipeline, you should try to incorporate command-line gene alignment and trimming software. There are many options available and will definitely speed up your pipeline. I really recommend this. 

Multiple sequence alignment software examples:

- [MAFFT](https://mafft.cbrc.jp/alignment/software/)
- [MUSCLE](https://github.com/rcedgar/muscle)

Alignment trimming software examples:

- [TrimAl](https://vicfero.github.io/trimal/)
- [ClipKit](https://github.com/JLSteenwyk/ClipKIT)

<br>

---

# Section 1: Single-Gene Tree

## Step 1: Acquire Sequences

Let's make a small Fusarium phylogeny - I have provided a set of example *Fusarium* ITS sequences(and *Beauveria* outgroup) I downloaded from NCBI. I will reference these sequences throughout this walkthrough, but you could use your own sequences or get your own set off NCBI. You can can compare your own results (will be output to /my_results) to my own results found in the /results folder. 

Download just the /Phylogeny_Guide/single-gene/ITS_fasta folder and files. 

Then, make a project folder on your local computer. 

```bash
# Define your project directory (edit the path for your system)
project="/Users/$USER/Desktop/Phylogeny_walkthroughs"

# Make a folder for single-gene tree project and the ITS input sequences
mkdir -p $project/single-gene/ITS_fasta

#Make a folder for your results
mkdir -p $project/single-gene/my_results

```

Now copy the files you downloaded into the /single-gene/ITS_fasta you just made in your project folder. 

You could also use your own sequence data:

- **From ab1 files (your own data):**  
  - Optionally, you can trim off the poor-quality basepairs at the very start and end of each sequence (common Sanger artifact). Open the .ab1 files in 4Peaks (Mac) or Chromas (Windows), trim based on quality, and export as `.fasta`. 
  - Save trimmed files in a dedicated folder.  

- **From NCBI:**  
  - Search [NCBI Nucleotide database](https://www.ncbi.nlm.nih.gov/nucleotide/) with these search terms:  
    ```
    Fusarium[ORGN] AND ITS NOT scaffold
    ```  
  - Download fasta files for each organism of interest. 

<br>

Note: If you are using your own data, it's very important to include an *outgroup** in your phylogenetic tree.

An outgroup is a taxon that is known to fall outside the evolutionary group of primary interest (the “ingroup”). Including an outgroup allows the tree to be rooted and helps distinguish ancestral from derived traits. Without an outgroup, a tree is unrooted and only shows relative relatedness.

An outgroup should be closely related enough to share homologous characters with the ingroup (so sequences can be aligned accurately). It should also be distant enough to fall outside the ingroup, but not so distant that the alignment quality degrades.

Your outgroup choice all depends on the scale of your tree. For example, if I wanted to make a phylogeny across the genus *Cordyceps* (Family: Cordycipitaceae), I would include a sequence from a different genus but the same family, such as *Beauveria*. If I wanted to make a phylogeny across the family Cordycipitaceae (Order: Hypocreales), I would include a sequence from a different family in the same order, such as Bionectriaceae. 

<br>

---

## Step 2: Align Sequences

1. First, concatenate all the fasta files into a single multifasta. 

```bash
cat $project/single-gene/ITS_fasta/*.fasta > $project/single-gene/my_results/Fusarium_ITS.fasta
```

This snippet concatenates all the files in the “fastas” folder ending in “.fasta” into a single file called “Fusarium_ITS.fasta”, which can be used in **Mesquite**.  

An important note:  You need to be careful with the naming of your fasta headers. It’s best to have any and all information present in the header without any spaces, as some program truncate the header on the first instance of a whitespace. The sequences from each strain/organism needs to have a unique fasta header.  

The collection of programs we will use in this walkthrough all have slightly different requirements, so it’s best to use a simple but informative naming scheme. 

For instance, instead of: 

> \>NR_111594.1 Beauveria bassiana ARSEF 1564 ITS region; from TYPE material

You can modify this header so it reads: 

> \>Beauveria_bassiana_ARSEF1564_ITS

or 

> \>NR_111594.1_Beauveria_bassiana_ARSEF1564_ITS

or  

> \>Beauveria_bassiana_ITS

It's important that all your samples have unique headers. Even if you have multiple representatives from the same species, they need to be unique. For instance, I have Fusarium_solani, Fusarium_solani.2, and Fusarium_solani.3.

Once you have curated your fasta headers, you can go ahead and start the sequence alignment process.

2. Open Mesquite. Go to File → Open File → select Fusarium_ITS.fasta. 

3. A popup will ask what type of data is contained in the fasta file. Select (DNA/RNA), hit “OK” 

4. The software will automatically create a nexus file (.nex or .nexus) to save your project. Your project is automatically labeled as the title of your multi-fasta file, but you can give it a new name if you want. Save the .nex file.  

5. You will see all of your sequences load onto the screen, with each sequence a different row. The different nucleotides are shown in different colors.

![Raw sequences in Mesquite](/single-gene/images/mesquite1.png)

6. Now it is time to align the sequences. To align all the sequences, go to the top bar and select “Matrix” → “Align multiple sequences” → [choice of alignment software].  I will select “MAFFT” to align my sequences.  

7. It will ask you if you want to run the alignment on a separate thread – say no.  

![MAFFT option in Mesquite](/single-gene/images/mesquite2.png)

8. If you are running any alignment software in Mesquite for the first time, it will ask you to provide the path to the software you downloaded separately. Find and provide the appropriate path name of the software your downloaded.  

9. After you have run MAFFT (<10 seconds) you will see the sequences are now aligned, but full of gaps.

![Aligned sequences in Mesquite](/single-gene/images/mesquite3.png)

You will see that the different sequences have different lengths – it is important that you trim the sequences to be all the exact same length. If you don’t, you are artificially introducing variation between the reads, and tree-making software will interpret this difference as real differences between the strains rather than mistakes made in the file preparation steps. 

Click to highlight the first character column → press and hold SHIFT → click to highlight the last character column up before the sequences completely overlap. 

With the section to trim off highlighted, go to “Matrix” → "Delete selected Chars or Taxa"

![Trimming sequences in Mesquite](/single-gene/images/mesquite4.png)

Do this for the beginning and the end of the aligned sequences. Now your sequences are both aligned and trimmed. 

![Trimmed sequences in Mesquite](/single-gene/images/mesquite5.png)


Side note:  It's not a problem with this test Fusarium dataset, but you may have alignments where some sequences are terribly aligned and don’t seem to make much sense at all – this could be due to the locus getting mis-labeled in NCBI, in which case you need to toss out the sequence. It could also be due to the sequences being the reverse complement of its sister sequences – in which case you need to change the sequence to the reverse complement and (Highlight sequences in question, then go to “Align” → “Reverse Complement”) then re-align all sequences.  

Mesquite allows you to perform manual curation of the sequences. You can move/shift base pairs or groups of base pairs as you please, and any other type of curation/editing you wish to do. 

11. Once you are satisfied with your alignment, export your file. Go to File → Export →  select Fasta (DNA/RNA) → **make sure the boxes ‘include gaps’ and ‘write excluded characters’ are checked** → name your exported file something informative (e.g. Fusarium_ITS_aligned_trimmed.fasta) → then hit export 

Save your nexus file. You can now exit Mesquite.

<br>

You now have a curated and aligned multifasta and are ready to make a single-gene tree.

If you are thinking this all seems very tedious and difficult to replicate - I agree! I recommend checking out terminal-based alignment and trimming software (MAFFT/MUSCLE/trimal/etc). You get the same exact results, it's easy to loop through many files, and it is easy to reproduce your results. 

<br>

---

## Step 3: Create the tree 

**(!)**  When creating your shell commands, do not use Microsoft Word or LibreOffice. Use a plain text editor such as BBedit, Notepad++, or a terminal editor like nano or vim. Word processors can insert hidden characters that cause confusing errors.

When building a phylogenetic tree, two key considerations are:

1. Evolutionary Model Selection

- Different substitution models describe how DNA bases change over time.

- Choosing the correct model is important for realistic trees.

- IQ-TREE can automatically test many models (ModelFinder) and select the best fit.

- Alternative tree-building software: RAxML or ModelTest-NG

2. Bootstrap Support

- Bootstrapping is a method to assess the statistical confidence of each branch in the tree.

- The alignment is resampled (with replacement) many times (e.g., 1000 replicates), and a tree is built for each sample.

- The percentage of times a branch appears across these trees is reported as the bootstrap value (e.g., 100% = branch is always supported, 50% = weak support).

- In practice, bootstrap values above 70% are often considered good support, while lower values indicate more uncertainty.

<br>

The following command builds a tree from 12 Fusarium ITS sequences plus 1 outgroup sequence. It uses:

- ModelFinder to automatically choose the best substitution model.

- 1000 bootstrap replicates to assess branch support.

```bash
cd $project/single-gene/my_results/
iqtree -s Fusarium_ITS_aligned_trimmed.fasta -m MFP+MERGE --prefix fusarium_ITS -b 1000
```

Unless you've configured your profile, you will need to use the absolute path of the software you downloaded (e.g. /Users/$USER/Desktop/Software/iqtree-2.3.5-macOS/bin/iqtree2) instead of just "iqtree".

This analysis will take a little while (~5 minutes), less time if you specified the program to use more threads than its default (1 thread). 


### Explanation of Parameters 

`-s fusarium_aligned.fasta`
Input alignment file. IQ-TREE accepts multiple formats (FASTA, PHYLIP, NEXUS, CLUSTAL, MSF).

`-m MFP+MERGE`
Runs ModelFinder to automatically test a wide range of substitution models and select the best one according to the Bayesian Information Criterion (BIC).

	MFP = ModelFinder Plus

	MERGE = merges similar partitions when applicable for efficiency.

From the IQ-TREE manual: “ModelFinder computes the log-likelihoods of an initial parsimony tree for many different models and the Akaike information criterion (AIC), corrected Akaike information criterion (AICc), and the Bayesian information criterion (BIC). Then ModelFinder chooses the model that minimizes the BIC score.”

`-b 1000`
Performs 1000 bootstrap replicates. Bootstrapping resamples the alignment many times to estimate statistical support for each branch. Higher bootstrap percentages = higher confidence.

`-T 4`
Optionally specify more than the default 1 CPU/thread. More CPUs = faster processing speed.

`--prefix fusarium_ITS`
Sets a prefix for all output files (default would be aln). With this option, results will be named:

	fusarium_ITS.iqtree (summary of model/test/tree)

	fusarium_ITS.treefile (maximum-likelihood tree)

	fusarium_ITS.contree (consensus bootstrap tree)

	fusarium_ITS.log (log file of the run)
	

The tree creation is successful if all the output files are present (.iqtree, .contree, etc) and have contents. 

The two most important tree files are:  

- `.treefile` – Maximum likelihood (ML) tree in NEWICK format, can be visualized with treeviewer software

- `.contree` – The consensus tree in NEWICK format, with branch support values (e.g., from `-b 1000`). 

For this example, these two tree files should be more or less the same. However, we want to move forward with the **consensus tree** (.contree). 

---

## Step 4: View and interpret the tree 

1. Open the FigTree software. Go to “File” → “open” → select your new “.treefile” 

If FigTree doesn’t recognize .contree, you can rename it to .tree.

An unrooted tree will appear on your screen. 

![Unrooted tree in FigTree](/single-gene/images/figtree1.png)

2. You know what the outgroup in this dataset is (*Beauveria bassiana*) and you can manually set it. Click on the branch of the outgroup. Once highlighted, click “Re-Root” and the tree will be rooted on the outgroup.  

![Rooted tree in FigTree](/single-gene/images/figtree2.png)

3. In order to see the bootstrap support values for the tree, check the “Node labels” option and under “Display” select “label” .

![BS support in FigTree](/single-gene/images/figtree3.png)

You can adjust the thickness of the branch lines under “Appearance”. There are many other tree aesthetics options you can play around with in the software, such as tip label and node font size.

---

And you are finished! You have a *Fusarium** phylogeny made from ITS sequences. 

But...this doesn't look like a great tree, does it? Look at the support values - we have many nodes with quite low bootstrap support. ITS by itself, or any one sequence alone, will not typically result in the most informative tree. 

Maybe it would be better if we also included a more conserved gene into our tree-making process, such as translation elongation factor EF-1 alpha (aka TEF aka TEF1). Check out my walkthrough of making a multi-gene phylogeny (partiyioned analysis).








