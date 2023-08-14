process QCSTATS_TABLE {
    tag "$meta.id"
    label 'process_single'

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