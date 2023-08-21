process MQC_TABLES {
  //  tag "$meta.id"
    label 'process_single'
    
    conda "bioconda::python=3.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9' :
        'quay.io/biocontainers/python:3.9' }"

    input:
    val js_stats_file

    output:
    path out_dir_name, emit: mqc_done
    path "versions.yml", emit: versions

    script:
  //  def prefix = task.ext.prefix ?: "${meta.id}"
 //   out_dir_name = "${prefix}_mqc_tables"
    out_dir_name = "mqc_table"
    """
    mkdir -p ${out_dir_name}
    cd ${out_dir_name}
    echo $js_stats_file | sed 's/\\[//' | sed 's/\\]//' | sed 's/, /\\n/g' > input_stats_file.txt
    create_mqc_output_tables.py -js_file input_stats_file.txt
    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}
