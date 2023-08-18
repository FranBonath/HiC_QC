/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowHicqc.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta, params.bwa_index]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
if (params.bwa_index) {ch_bwa_index = file(params.bwa_index)} else {'BWA index not specified!'}
if (params.fasta) {ch_fasta = file(params.fasta)} else {exit 1, 'fasta file not specified!'}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { QCSTATS_TABLE               } from '../modules/local/create_stats_table'
include { MQC_TABLES                  } from '../modules/local/create_mqc_tables'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { SAMTOOLS_FAIDX              } from '../modules/nf-core/samtools/faidx/main'
include { PAIRTOOLS_PARSE             } from '../modules/nf-core/pairtools/parse/main'
include { PAIRTOOLS_SORT              } from '../modules/nf-core/pairtools/sort/main' 
include { PAIRTOOLS_DEDUP             } from '../modules/nf-core/pairtools/dedup/main'
include { BWA_MEM                     } from '../modules/nf-core/bwa/mem/main'
include { BWA_INDEX                   } from '../modules/nf-core/bwa/index/main'
include { FASTQ_ALIGN_BWA             } from '../subworkflows/local/fastq_align_bwa/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow HICQC {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Retrieve indexes or run BWA_INDEX
    //
    
    Channel 
        .fromPath(ch_fasta)
        .map { it -> ["[:]", [it]]}
        .collect()
        .set { fasta_ch }
    
    if ( params.bwa_index ){
        Channel
            .fromPath(ch_bwa_index)
            .map { it -> ["[:]", it] }
            .collect()
            .set { bwa_index_ch }
    }
    else {
        BWA_INDEX (
            fasta_ch //    tuple val(meta), path(fasta)
        )
        bwa_index_ch = BWA_INDEX.out.index.collect()
    }

    //
    // MODULE: Run SAMTOOLS_FAIDX
    //

    Channel 
        .fromPath("./params.outdir/")
        .map { it -> ["fai", [it]] }
        .set { fai_ch }

    SAMTOOLS_FAIDX (
        fasta_ch,
        fai_ch
    )

    //
    // MODULE: Run FASTQ_ALIGN_BWA
    //

    ch_genome_bam        = Channel.empty()
    FASTQ_ALIGN_BWA (
        INPUT_CHECK.out.reads,        // channel (mandatory): [ val(meta), [ path(reads) ] ]
        bwa_index_ch,   // channel (mandatory): [ val(meta2), path(index) ]
        true,    // boolean (mandatory): true or false
        fasta_ch        // channel (optional) : [ path(fasta) ]
    )

    //
    // MODULE: Run Pairtools/parse
    //

    PAIRTOOLS_PARSE (
        FASTQ_ALIGN_BWA.out.bam_orig,        //tuple val(meta), path(bam)
        SAMTOOLS_FAIDX.out.fai.collect()            //path chromsizes
    )

    //
    // MODULE: Run Pairtools/sort
    //

    PAIRTOOLS_SORT (
        PAIRTOOLS_PARSE.out.pairsam
    )

    //
    // MODULE: Run Pairtools/dedup
    //

    PAIRTOOLS_DEDUP (
        PAIRTOOLS_SORT.out.sorted
    )

    //
    // MODULE: Run QCSTATS_TABLE
    //

    QCSTATS_TABLE (
        PAIRTOOLS_DEDUP.out.stat
    )
    ch_versions = ch_versions.mix(QCSTATS_TABLE.out.versions)

    //
    // MODULE: Run MQC_TABLES
    //

    ch_mqc_tables = Channel.empty()
    ch_mqc_tables = QCSTATS_TABLE.out.qctable

    MQC_TABLES (
        ch_mqc_tables
    )

    ch_versions = ch_versions.mix(MQC_TABLES.out.versions)

    MQC_TABLES.out.mqc_done.collect().view()

    //
    // MODULE: Run FastQC
    //
    
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowHicqc.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowHicqc.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    //ch_multiqc_files = ch_multiqc_files.mix(QCSTATS_TABLE.out.qctable.collect())
    ch_multiqc_files = ch_multiqc_files.mix(MQC_TABLES.out.mqc_done.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
