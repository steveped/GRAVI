rule install_packages:
  input: "workflow/scripts/install_packages.R"
  output: "output/packages.installed"
  conda: "../envs/rmarkdown.yml"
	threads: 1
	log: "workflow/logs/rmarkdown/install_packages.log"
	shell:
	  """
	  Rscript --vanilla {input} {output} &>> {log}
	  """

rule create_site_yaml:
	input:
		config = "config/rmarkdown.yml",
		r = "workflow/scripts/create_site_yaml.R"
	output: os.path.join(rmd_path, "_site.yml")
	params:
		git = git_add,
		interval = random.uniform(0, 1),
		tries = 10
	conda: "../envs/rmarkdown.yml"
	threads: 1
	log: "workflow/logs/rmarkdown/create_site_yaml.log"
	shell:
		"""
		Rscript --vanilla {input.r} {output} &>> {log}
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
			git add {output}
		fi
		"""

rule create_setup_chunk:
	input:
		config = "config/rmarkdown.yml",
		r = "workflow/scripts/create_setup_chunk.R"
	output:
		rmd = "analysis/setup_chunk.Rmd"
	params:
		git = git_add,
		interval = random.uniform(0, 1),
		tries = 10
	conda: "../envs/rmarkdown.yml"
	threads: 1
	log: "workflow/logs/rmarkdown/create_setup_chunk.log"
	shell:
		"""
		Rscript --vanilla {input.r} {output.rmd} &>> {log}
		if [[ {params.git} == "True" ]]; then
			TRIES={params.tries}
			while [[ -f .git/index.lock ]]
			do
				if [[ "$TRIES" == 0 ]]; then
    				echo \
    				  "ERROR: Timeout waiting for removal of git index.lock" &>> {log}
    				exit 1
  				fi
				sleep {params.interval}
				((TRIES--))
			done
			git add {output}
		fi
		"""

rule create_here_file:
	output: here_file
	threads: 1
	shell:
		"""
		touch here_file
		"""

rule compile_annotations_rmd:
  input:
    blacklist = blacklist,
    here = here_file,
    rmd = "workflow/modules/annotation_description.Rmd",
    rds = expand(
      os.path.join(annotation_path, "{file}.rds"),
      file = ['all_gr', 'gene_regions', 'seqinfo', 'trans_models', 'tss']
    ),
    setup = rules.create_setup_chunk.output,
    site_yaml = rules.create_site_yaml.output,
    yaml = expand(
      os.path.join("config", "{file}.yml"),
      file = ['config', 'colours', 'rmarkdown']
    )
  output:
    rmd = "analysis/annotation_description.Rmd",
    rds = os.path.join(annotation_path, "colours.rds"),
    html = "docs/annotation_description.html",
    fig_path = directory(
			os.path.join("docs", "annotation_description_files", "figure-html")
		)
	params:
		git = git_add,
		interval = random.uniform(0, 1),
		tries = 10
	conda: "../envs/rmarkdown.yml"
	threads: 1
	log: "workflow/logs/rmarkdown/build_annotations_rmd.log"
	shell:
	  """
	  cp {input.rmd} {output.rmd}
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
			git add {output}
		fi
	  """

rule compile_site_index:
	input:
		html = HTML_OUT,
        here = here_file,		
		rmd = os.path.join(rmd_path, "index.Rmd"),
		setup = rules.create_setup_chunk.output,
		site_yaml = rules.create_site_yaml.output,
		rulegraph = 'workflow/rules/rulegraph.dot'
	output:
		html = "docs/index.html"
	params:
		git = git_add,
		interval = random.uniform(0, 1),
		tries = 10
	conda: "../envs/rmarkdown.yml"
	threads: 1
	log: "workflow/logs/rmarkdown/build_site_index.log"
	shell:
		"""
		R -e "rmarkdown::render_site('{input.rmd}')" &>> {log}

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
			git add {output}
		fi
		"""

