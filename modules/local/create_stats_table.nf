process QCSTATS_TABLE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::python=3.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9' :
        'quay.io/biocontainers/python:3.9' }"

    input:
    tuple val(meta), path(pt_stats_file)

    output:
    path "*.stats.out.js"

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mk_js_QC_summary.py -PTstats $pt_stats_file > ${prefix}.stats.out.js 
    """

}