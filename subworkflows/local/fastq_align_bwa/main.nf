//
// Alignment with BWA
//

include { BWA_MEM                 } from '../../../modules/nf-core/bwa/mem/main'

workflow FASTQ_ALIGN_BWA {
    take:
    ch_reads        // channel (mandatory): [ val(meta), [ path(reads) ] ]
    ch_index        // channel (mandatory): [ val(meta2), path(index) ]
    val_sort_bam    // boolean (mandatory): true or false
    ch_fasta        // channel (optional) : [ path(fasta) ]

    main:
    ch_versions = Channel.empty()

    //
    // Map reads with BWA
    //

    BWA_MEM ( ch_reads, ch_index, val_sort_bam )
    ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())

    emit:
    bam_orig = BWA_MEM.out.bam                      // channel: [ val(meta), path(bam) ]
    versions = ch_versions                          // channel: [ path(versions.yml) ]
}
