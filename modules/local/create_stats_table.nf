process PT_STATS_TABLE {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(pt_stats_file)

    output:
    path "*.stats.out.txt"

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mk_js_QC_summary.py -PTstats $pt_stats_file > ${prefix}.stats.out.js 
    """

}