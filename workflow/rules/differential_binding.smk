rule differential_binding:
	input:
		annotations = ALL_RDS,
		aln = lambda wildcards: expand(
			os.path.join(bam_path, "{{target}}", "{sample}.{suffix}"),
			sample = df['sample'][
				(df['target'] == wildcards.target) &
				(
					(df['treat'] == wildcards.ref) |
					(df['treat'] == wildcards.treat)
				)
			],
			suffix = ['bam', 'bam.bai']
		),
		merged_macs2 = lambda wildcards: expand(
			os.path.join(
				macs2_path, "{{target}}", "{pre}_merged_callpeak.log"
			),
			pre = [wildcards.ref, wildcards.treat]
		),
		merged_bw = lambda wildcards: expand(
			os.path.join(
				bw_path, "{{target}}", "{pre}_merged_treat_pileup.bw"
			),
			pre = [wildcards.ref, wildcards.treat]
		),
		peaks = expand(
			os.path.join("output", "{target}", "consensus_peaks.bed"),
			target = targets
		),
		indiv_bw = lambda wildcards: expand(
			os.path.join(
				bw_path, "{{target}}", "{sample}_treat_pileup.bw"
			),
			sample = df['sample'][
				(df['target'] == wildcards.target) &
				(
					(df['treat'] == wildcards.ref) |
					(df['treat'] == wildcards.treat)
				)
			]
		),
		samples = os.path.join("output", "{target}", "qc_samples.tsv"),
		pkgs = rules.install_packages.output,
		r = "workflow/scripts/create_differential_binding.R",
		setup = rules.create_setup_chunk.output,
		site_yaml = rules.create_site_yaml.output,
		yml = expand(
			os.path.join("config", "{file}.yml"),
			file = ['config', 'params']
		),
		db_mod = os.path.join(
			"workflow", "modules", "differential_binding.Rmd"
		),
		rnaseq_mod = os.path.join(
			"workflow", "modules", "rnaseq_differential_binding.Rmd"
		)
	output:
		rmd = os.path.join(
			rmd_path, "{target}_{ref}_{treat}_differential_binding.Rmd"
		),
		html = "docs/{target}_{ref}_{treat}_differential_binding.html",
		fig_path = directory(
			os.path.join(
				"docs", "{target}_{ref}_{treat}_differential_binding_files",
				"figure-html"
			)
		),
		renv = expand(
			os.path.join(
				"output", "envs",
				"{{target}}_{{ref}}_{{treat}}_differential_binding.RData"
			)
		),
		outs = expand(
			os.path.join("output", "{{target}}", "{{ref}}_{{treat}}_{file}"),
			file = ['differential_binding.rds', 'down.bed', 'up.bed']
		),
		csv = expand(
		  os.path.join("output", "{{target}}", "{{target}}_{{ref}}_{{treat}}_{file}"),
		  file = ['differential_binding.csv.gz', 'DE_genes.csv']
		),
		win = os.path.join(
			"output", "{target}", "{ref}_{treat}_filtered_windows.rds"
		)
	params:
		git = git_add,
		interval = random.uniform(0, 1),
		tries = 10
	conda: "../envs/rmarkdown.yml"
	threads:
		lambda wildcards: len(df[
			(df['target'] == wildcards.target) &
			((df['treat'] == wildcards.ref) | (df['treat'] == wildcards.treat))
			])
	log:
		"workflow/logs/differential_binding/{target}_{ref}_{treat}_differential_binding.log"
	shell:
		"""
		## Create the generic markdown header
		Rscript --vanilla \
			{input.r} \
			{wildcards.target} \
			{wildcards.ref} \
			{wildcards.treat} \
			{threads} \
			{output.rmd} &>> {log}

		## Add the remainder of the module as literal text
		cat {input.db_mod} >> {output.rmd}

		R -e "rmarkdown::render_site('{output.rmd}')" &>> {log}

		if [[ {params.git} == "True" ]]; then
			TRIES={params.tries}
			while [[ -f .git/index.lock ]]
			do
				if [[ "$TRIES" == 0 ]]; then
					echo "ERROR: Timeout while waiting for removal of git index.lock" &>> {log}
					exit 1
				fi
				sleep {params.interval}
				((TRIES--))
			done
			git add {output.rmd}
			git add {output.html}
			git add {output.fig_path}
			git add {output.outs}
			git add {output.csv}
		fi
		"""
