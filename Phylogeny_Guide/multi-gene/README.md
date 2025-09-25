# Section 2: Multi-Gene Tree

This section builds off my walkthrough on how to make [single-gene trees](../single-gene/README.md). 

## Why Use Multiple Genes?  

When we build a tree with a single locus, we are really making a **gene tree** — the evolutionary history of that one region.

Making a tree with the information from multiple gene let's us create a **species tree**, which better reflects the true evolutionary history of the organisms in your dataset.  

Each gene carries its own signal, but also its own biases and noise. By combining information from multiple independent loci, we: 

- Increase the number of informative sites when assessing for phylogenetic signal.
- Reduce the impact of errors or unusual evolutionary histories in any one gene.  
- Improve resolution and bootstrap support across deeper branches.  

In practice, multi-gene trees are more stable and reliable than single-gene trees, especially when studying relationships above the species level.  

<br>

---

## Step 1: Acquire sequences and set up the project folder

In this example, we will construct a small phylogeny for several *Metarhizium* species held in the USDA Agricultural Research Service's Collection of Entomopathogenic Fungal Cultures (ARSEF). From NCBI, I have collected ITS and TEF1 sequences for nine *Metarhizium* species, along with one *Beauveria* species to serve as the outgroup.  

For convenience, I have already aligned and trimmed both datasets (provided as `aligned.fasta` files), so we can proceed directly to the tree-building steps. If you would like to practice the alignment and trimming process yourself, the raw unaligned sequences are also available in the `/input_fasta/raw_seq` folder.  

As in the single-gene walkthrough, begin by creating a project directory on your local computer and moving the aligned and trimmed fasta files into it:  

```bash
# Define your project directory (edit the path for your system)
project="/Users/$USER/Desktop/Phylogeny_walkthroughs"

# Create a folder for the input fasta files
mkdir -p $project/multi-gene/input_fastas

# Create a folder for your results
mkdir -p $project/multi-gene/my_results
```

<br>

---

## Step 2: Acquire sequence files for multiple loci

If you're not using my test dataset, you can either use sequences that you have generated yourself or retrieve them from public databases such as NCBI. 

If you are downloading from NCBI, it is **essential that sequences for the different loci come from the same strain**. For example, you cannot combine an ITS sequence from Fusarium solani strain “A” with an RPB2 sequence from strain “B” and treat them as though they belong to the same organism.

Whenever possible, try to use sequences obtained using the same primer set across all samples for a given locus. This ensures you are comparing homologous regions and reduces the amount of manual adjustment required during alignment. Differences in primer choice will become very obvious once you reach the alignment stage.

Finally, be cautious: public databases sometimes contain mislabeled genes or partial regions that do not match your target locus. Most of these issues will surface during alignment, but expect repeated editing (adding, removing, or correcting sequences) before arriving at a clean dataset.

<br>

---

## Step 3: Align the sequences for each locus separately  

This step is essentially the same as in the single-gene walkthrough. Each gene must be separately aligned and trimmed.  

**Important:** Each multifasta must contain the same set of strains, in the same order.  
This ensures that concatenated alignments later on will match up correctly. **This is really important.**

If you're working through this pipeline with the raw data I provided, you’ll notice I had to truncate some of the ARSEF *Metarhizium* sequences quite a bit to get them all the same length. I also had to drop or replace several strains because one of their loci did not resolve well. Both issues are common when working with public data, especially when combining sequences from multiple sources.  

<br>

---

## Step 4: Prepare the input files for the multi-gene tree analysis 

Making a multi-gene tree is also called a “complex” or “partitioned” analysis. Read more about this analysis in the [IQ-TREE manual](http://www.iqtree.org/doc/Complex-Models).

For each strain/organism, you need to concatenate their **aligned and trimmed** sequences together, creating a single continuous DNA sequence for each strain/organism. I will refer to this file as the supermatrix.

Right now you have two multifastas. They should look like this: 

Multifasta file 1:

> \>Strain_1_ITS \
ATGCATGG \
\>Strain2_ITS \
ATGCAATG \
\>Strain3_ITS \
ATGCAAGG

Multifasta file 2:

> \>Strain_1_TEF1 \
TTGAGAAA \
\>Strain2_TEF1 \
TTGAGAAT \
\>Strain3_TEF1 \
TTGAGAAT

When you have completed the concatenation, the resulting supermatrix file should look like this: 

> \>Strain_1 \
ATGCATGGTTGAGAAA \
\>Strain2 \
ATGCAATGTTGAGAAT \
\>Strain3 \
ATGCAAGGTTGAGAAT

You can perform this concatenation step with sequence editing software, such as PhyKit.

Or you can use these bash commands here, but only if your headers are exactly the same between the fasta files. 

```bash
cd $project/multi-gene/input_fastas
mkdir -p $project/multi-gene/intermediate_files

ITS="ARSEF_Metarhizium_ITS_aligned.fasta"
TEF1="ARSEF_Metarhizium_TEF1_aligned.fasta"
OUT="../intermediate_files/ARSEF_Metarhizium_ITS_TEF1_supermatrix.fasta"

# Convert FASTA -> TSV: key \t seq
awk '/^>/ {hdr=$0; getline seq; gsub(/ /,"",seq); print hdr "\t" seq}' $ITS > tmp1.tsv
awk '/^>/ {hdr=$0; getline seq; gsub(/ /,"",seq); print hdr "\t" seq}' $TEF1 > tmp2.tsv

# Join on header and concatenate
join -t $'\t' -1 1 -2 1 \
  <(sort -t $'\t' -k1,1 tmp1.tsv) \
  <(sort -t $'\t' -k1,1 tmp2.tsv) \
| awk -F'\t' '{print $1 "\n" $2 $3}' > "$OUT"

# remove temp files
rm -f tmp1.tsv tmp2.tsv
```

You will need to know the length of each of your input sequences. You can check the sequence length of your input sequences by running these commands.

```bash
echo "ITS lengths:"
awk '!/^>/ {print length($0)}' ARSEF_Metarhizium_ITS_aligned.fasta | sort -nu

echo "TEF1 lengths:"
awk '!/^>/ {print length($0)}' ARSEF_Metarhizium_TEF1_aligned.fasta | sort -nu
```


Just like in the single-gene tree analysis, we need to figure what what substitution models and evolutionary rates are appropriate for each gene during the tree creation step. We can do this by calculating the Bayesian Information Criterion (BIC) for each evolutionary model applied to our dataset.

Then, we need to specify our selected "best" models to the tree-creation software, along with the “partitions” or sections of the concatenated sequence the model is applied to. This information is stored in a “partition” file (in nexus format; .nex).

Here is how you use iqtree2's modelfinder option to find the best evolutionary models for each of the datasets:

```{bash, eval = FALSE}
iqtree2 -s ARSEF_Metarhizium_ITS_aligned.fasta -m MFP+MERGE -b 1000 

iqtree2 -s ARSEF_Metarhizium_TEF1_aligned.fasta -m MFP+MERGE -b 1000 
```

Note: there are several options you can modify at this step: 

`-m MFP+MERGE` to perform PartitionFinder followed by tree reconstruction 

`-rcluster #` :   to reduce computations by only examining the top #% partitioning schemes using the relaxed clustering algorithm  

`-b #` : Number of bootstrap replicates to run on your analysis. 1000 is the recommended minimum. 

After running the model finding step, open the .iqtree file for each analysis to find the best-fit model for your data: 

> ModelFinder \
---------------- \
BEst-fit model according to BIC: TNe+G4 

The selected model information is also available in the .log file:

> Best-fit model: TNe+G4 according to BIC

Now that you have the correct model information for each locus/partition, you need to actually create the partition file.  

<br> 

Partition file (.nex) example:  

>#nexus \
begin sets; \
charset part1 = 1-8; \
charset part2 = 9-15; \
charpartition mine = TNe+G4:part1, GTR+I+G:part2; \
end;

Be careful with ranges. If ITS length is 25, it’s 1–25; if TEF1 is 20, it’s 26–45, etc. The sum of partition lengths must equal the concatenated sequence length for every sequence in the file. Partition math mistakes are the most common source of IQ-TREE errors in partitioned analyses.

You can check your partition and supermatrix files against the example files I have provided in /intermediate_files.

<br> 

---

### Step 5: Make the multi-gene tree with a partitioned analysis

Now that you have the partition file (.nex) and the supermatrix (.fasta), it's time to run the partitioned analysis in IQ-TREE. 

For analyses with many loci and/or many strains/organisms, this analysis may take a long time on your local computer. If you’re having issues with computer memory or run time, you should try to run these analyses on a supercomputer instead.  

If your run is successful, this will be the output on your terminal: 

>Analysis results written to: \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IQ-TREE report:                ARSEF_Metarhizium_ITS_TEF1.iqtree \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Maximum-likelihood tree:       ARSEF_Metarhizium_ITS_TEF1.treefile \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Likelihood distances:          ARSEF_Metarhizium_ITS_TEF1.mldist \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Screen log file:               ARSEF_Metarhizium_ITS_TEF1.log \
\
Total CPU time for bootstrap: 442.980 seconds. \
Total wall-clock time for bootstrap: 447.261 seconds. \
\
Non-parametric bootstrap results written to: \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Bootstrap trees:          ARSEF_Metarhizium_ITS_TEF1.boottrees \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Consensus tree:           ARSEF_Metarhizium_ITS_TEF1.contree \


Your final tree with bootstrap support values is the .contree file. Open this file in FigTree to see your final multigene tree. You should see something like this:

![ARSEF multigene tree](/images/Metarhizium_ITS_TEF1_multigene_tree.png)


And there you have it - you have a species tree made from evidence from multiple loci. 

This was only two loci and just a handful of samples - quite a tiny analysis! Even so, by now you must be tired of manually aligning, trimming, and concatenating your sequences. I'll encourage you again to check out terminal-based software (MAFFT/trimal/etc).

The last section in this collection of walkthrough is making a phylogenomic tree. This involves finding orthologous genes in a collection of genome assemblies, then running a partitioned analysis on those genes. 

<br>

---

## Common errors in IQ-TREE partitioned analysis: 
 

>ERROR:  Sequence ARSEF_2133_Metarhizium_flavoridae contains too many characters (1450)

This error message means that the specified partition breaks do not add up to the total number of bases for one or more concatenated sequences. You should go back and double check both your math and the length of each of your partitions. 

Another source of this error is that you have samples that do not have the same number of characters in their final concatenated sequence – are you sure you concatenated the *trimmed and aligned** sequences? 

<br>

>Partition file is not in NEXUS format, assuming RAxML-style partition file...

There’s something wrong with your partition (.nex) file. Double check the format and try again, the semicolons are essential. Does the file start with ‘#nexus’? If it still doesn’t work, download a .nex tutorial file and modify that.

<br>

> 24.98% 1 sequence failed composition chi2 test (p-value<5%; df=3)

Once of your sequences was very different from the rest- maybe your outgroup? It might be best to choose a more similar outgroup. It could also be from a very low quality sequence, or a sequence that was mislabed as the incorrect region and not properly filtered out at the alignment step. The tree creation will still run even if this error is shown and the stain in question will be included; it’s not absolutely necessary to change anything if you get this error. 

<br>

>ERROR: Too large site ID

This means that the range you provided in the partition file (charset# = #-#) is too large for the concatenated sequences you provided. Check your math and try again. 

Check out this [IQ-TREE complex partitioning tutorial](http://www.iqtree.org/workshop/molevol2022), which covers automatically selecting models for many genes at once, identifying the gene most contributing to phylogenic signal, and other fun things.

In addition to making multi-gene trees using just DNA sequence data like we did here, you can also make “mixture” trees where you incorporate both amino acid and DNA sequence data into the same tree. Check out the [Partitioned analysis with mixed data](http://www.iqtree.org/doc/Complex-Models) section of the IQ-TREE complex models guide to learn more.




