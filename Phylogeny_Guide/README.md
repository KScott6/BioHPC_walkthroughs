# Making Single-Gene, Multi-Gene, and Phylogenomic Trees (for BioHPC)

## Types of Phylogenetic Trees

- A [single-gene tree](/single-gene) is created using one locus (e.g., Beta-tubulin) across multiple organisms or strains.  

- A [multi-gene tree](/multi-gene) uses two or more loci (e.g., Beta-tubulin and TEF1) across multiple organisms or strains.

- A `phylogenomic tree` is a special case of multi-gene trees that use many, many loci (often single-copy orthologs, SCOs) extracted from a set of genomes.  

<br>

## Notes on Creating Trees

- Resolution suffers if all genes are not present for every strain.  

- The final product of different single-gene trees across the same set of strains may conflict, depending on the chosen loci. Different genes are better/worse at resolving taxonomy depending on the taxa in question. 

- ITS (Internal Transcribed Spacer) is the standard go-to for fungal identification/creating trees, but it is by no means perfect. ITS lacks resolution for deeper relationships (e.g., within genera or families) and may give conflicting results between groups. 

- Database sequences labeled as the same region (e.g., “ITS”) may actually differ depending on the primers used. Check your gene alignments to make sure you have the same locus across all strains. 


