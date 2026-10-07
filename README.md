# eBench
The working depository for a standard simulated ancient environmental DNA dataset (eBench).

eBench workflow overview:
![image](https://github.com/YCWangLab/aeDNA_gauge/blob/main/aeDNA%20gauge%20workflow%20overview.png)

Our simulated datasets comprehensively incorporate the inherent characteristics of both ancient DNA (aDNA) and environmental DNA (eDNA) to the greatest extent possible. Therefore, they consist of computationally simulated reads from 600 randomly selected metagenomes of different trophic level species with varying levels of damage simulating deamination, fragmentation, and divergence, where the taxa and their abundances are known. 
First, considering that environmental samples are complex mixtures of organisms, with microbial DNA sequences making up the majority, we randomly downloaded full genome assemblies from NCBI RefSeq: 350 bacteria, 100 archaea, 50 fungi, 50 plants, 15 vertebrate mammals, 15 other vertebrates, and 20 invertebrates. Subsequently, considering the significant difference in the number of nuclear and organelle DNA copies in animal and plant cells, we used the most extensively studied species—Homo sapiens for animals and Arabidopsis thaliana for plants—as representatives to calculate the ratio of nuclear DNA to organelle DNA sequences in the simulated database. In a human cell, there are 2 copies of the nuclear genome and approximately 500 copies of the mitochondrial genome. The downloaded human nuclear genome contains 3,117,275,501 base pairs, and the mitochondrial genome contains 16,569 base pairs. From this, we calculated the ratio of nuclear DNA base pairs to mitochondrial DNA base pairs in a human cell to be 75:1. For simplicity, the ratio of nuclear DNA sequences to mitochondrial DNA sequences for animals in the simulated database was set to 100:1.
Similarly, in a plant cell, there are on average about 100 copies of the mitochondrial genome and 10,000 copies of the chloroplast genome. Based on the base pair counts of the Arabidopsis nuclear and organelle genomes, we calculated that the ratio of nuclear DNA sequences to chloroplast DNA sequences to mitochondrial DNA sequences in the simulated plant database should be 50:50:1.


We simulated modern, young, old, and deep time periods, corresponding to the nowadays, approximately 1,000 BP (before present), 10,000 BP, and 40,000 BP, respectively. To simulate aDNA fragmentation and damage, we utilized three previously published samples of the ancient archaeological specimens to obtain the reads length and deamination profiles used as input parameters for the simulation. The Yana_young (766 BP), Yana_old (31,630 BP), and femur fragment (~430,000 BP) individuals were selected as representatives for the young, old, and deep time periods respectively (see Table 1). For the modern simulated database, the sequence lengths were set between 302–305 bp, with no deamination.

![image](https://github.com/YCWangLab/aeDNA_gauge/blob/main/Table%201%20Metagenomic%20backgrounds%20used%20for%20simulated%20data%20sets.png)

Fragmentation and damage previously published samples of the ancient archaeological specimens to obtain the reads length and deamination profiles used as input parameters for the simulation:

![image](https://github.com/YCWangLab/aeDNA_gauge/blob/main/Fragmentation%20and%20damage%20previously%20published%20samples%20of%20the%20ancient%20archaeological%20specimens%20to%20obtain%20the%20reads%20length%20and%20deamination%20profiles%20used%20as%20input%20parameters%20for%20the%20simulation.png)


Mutation rates differ across species and DNA sources; in general, microbial and organelle genomes tend to be shorter with higher mutation rates, whereas animal and plant nuclear genomes have lower mutation rates. Based on current published studies, we set different mutation rates for microbial, plant, animal, and organelle genomes across different time periods, as detailed in Table 2.

![image](https://github.com/YCWangLab/aeDNA_gauge/blob/main/Table%202%20The%20mutation%20rates%20of%20genomes%20at%20different%20age.png)



We obtained 3 community from different time periods, resulting in a total of 12 datasets. The datasets were created using the following workflow (Figure 1). First, fragments from the different nuclear and organell genomes were produced uing FragSim module from Gargammel (Renaud et al., 2017).  Randomly selected 10 to 10,000 sequence fragments from each nuclear genome, along with the corresponding number of organelle sequence fragments, were combined to form a community. The abundance of each taxa in a metagenomic sample was set randomly with same abundance in each community (same -seed parameters in gargammel). Next, we simulated divergence by applying mutation- simulator (Kuhl et al., 2021) to add the appropriate mutation rates to genomes from different time periods based on the parameters in Table 2. Afterward, deamination damage of the reads for each time period were generated using DeamSim module from Gargammel. Finally, we combined the subsets into one FASTQ file as the simulated dataset. The simulated reads carry a unique identifier in their header with the information of the accession of the genome it originated from, the fragment length, mutation and the deamination damage. 
The simulated dataset is available at https://figshare.com/account/items/27020329/edit.
