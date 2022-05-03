# GRAVI: Gene Regulatory Analysis using Variable IP

This is a `snakemake` workflow for:

1. Performing sample QC
2. calling ChIP peaks
3. performing Differential Binding Analysis
4. identifying TF motifs

At least two IP targets are required as worflows for a single ChIP target are well established.

## Config Setup

### Samples

This workflow requires a tsv file, nominally `samples.tsv` detailing:

1. Each sample
2. Which ChIP target each samples is associated with
3. Which treatment group it is associated with, and
4. Which Input/Control sample it is associated with

Required columns are: `sample`, `target`, `treat` and `input` (all lower case).
At least one additional column containing replicate information should also be included.
A possible structure is as follows:

```
| sample | target | treat | passage | input |
| ------ | ------ | ----- | ------- | ----- |
| sample1 | AR | Veh | 1 | input1 |
| sample2 | AR | E2  | 1 | input1 |
```

It is currently assumed that bam files will be placed in `data/aligned/bam/[target]` where the final directory is the individual ChIP target.
Whilst the root directory can theoretically be changed via `config.yml`, it is not recommended.
Bam files should be named as specified in the `sample` column, with the addition of the `.bam` suffix only.

### Config

The file `config/config.yml` is where users can edit a series of parameters with default values provided.
The example provided should provide a clear guide to the structure.
However, the file can be checked using

```
python scripts/check_yaml.py
```


## Snakemake implementation

The basic workflow is written `snakemake` and can be called using the following steps.

Firstly, setup the required conda environments

```
snakemake \
	--use-conda \
	--conda-prefix '/home/steveped/mambaforge/envs/' \
	--conda-create-envs-only \
	--cores 1
```

Secondly, create and inspect the rulegraph

```
snakemake --rulegraph > workflow/rules/rulegraph.dot
dot -Tpdf workflow/rules/rulegraph.dot > workflow/rules/rulegraph.pdf
```

Finally, the workflow itself can be run using:

```
snakemake \
	-p \
	--use-conda \
	--conda-prefix '/home/steveped/mambaforge/envs/' \
	--notemp \
	--keep-going \
	--cores 16
```

Note that this creates common environments able to be called by other workflows and is dependent on the user.
For me, my global conda environments are stored in `/home/steveped/mambaforge/envs/`.
For other users, this path will need to be modified.