process MQC_TABLES {
    tag "$meta.id"
    label 'process_single'
    
    conda "bioconda::python=3.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9' :
        'quay.io/biocontainers/python:3.9' }"

    input:
    tuple val(meta), path(js_stats_file)

    output:
    tuple val(meta), path(mqc_tables), emit: mqc_done
 //   path "mqc_tables", emit: mqc_tables // path to directory with MultiQC tables
  //  path "versions.yml", emit: versions

    script:
    println(js_stats_file)
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    pwd
    mkdir -p mqc_tables
    cd mqc_tables
    create_mqc_output_tables.py -js_file ../$js_stats_file
    pwd

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}
