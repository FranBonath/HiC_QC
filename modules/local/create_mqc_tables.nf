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
    path out_dir_name, emit: mqc_done
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    out_dir_name = "${prefix}_mqc_tables"
    """
    mkdir -p ${out_dir_name}
    cd ${out_dir_name}
    create_mqc_output_tables.py -js_file ../$js_stats_file
    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}
