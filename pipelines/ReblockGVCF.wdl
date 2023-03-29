version 1.0

workflow ReblockGVCF {

  input {
    String sample_name
    File gvcf
    File ref_fasta    
    File ref_fasta_index
    File ref_dict
  }

  # String sub_strip_path = "^.*/"
  # String sub_strip_gvcf = ".g.vcf.gz" + "$"
  # String sub_sub = sub(sub(gvcf, sub_strip_path, ""), sub_strip_gvcf, "")

  call Reblock {
    input:
      sample_name = sample_name,
      gvcf = gvcf,
      gvcf_index = gvcf + ".tbi",
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      ref_dict = ref_dict,
      # output_vcf_filename = sub_sub + ".rb.g.vcf.gz",
      output_vcf_filename = sample_name + ".rb.g.vcf.gz",
  }
  
  output {
    File output_vcf = Reblock.output_vcf
    File output_vcf_index = Reblock.output_vcf_index
  }
}

## Params refs:
##  https://gatk.broadinstitute.org/hc/en-us/articles/9570412154139-ReblockGVCF
##  https://github.com/broadinstitute/warp/blob/a40aeb39b220431f225751ac954c7e0dac8369c8/tasks/broad/GermlineVariantDiscovery.wdl#L197
##  https://github.com/broadinstitute/warp/blob/a40aeb39b220431f225751ac954c7e0dac8369c8/pipelines/broad/dna_seq/germline/variant_calling/VariantCalling.wdl#L154
## Params:
##  -do-qual-approx: min Gnarly & GermlineVariantDiscovery (used)
##  --drop-low-quals: min Gnarly, but not in GermlineVariantDiscovery (NOT used)
##  -rgq-threshold 10: min Gnarly, but not in GermlineVariantDiscovery (NOT used) 
##  --floor-blocks -GQB 20 -GQB 30 -GQB 40: as in GermlineVariantDiscovery (used)
##  --floor-blocks -GQB 10 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 -GQB 70 -GQB 80 -GQB 90 -GQB 99 (as used by WUSTL)

task Reblock {

  input {
    String sample_name
    File gvcf
    File gvcf_index
    File ref_fasta
    File ref_fasta_index
    File ref_dict
    String output_vcf_filename
    String gatk_docker = "us.gcr.io/broad-gatk/gatk:4.3.0.0"
    Int additional_disk = 20
    String? annotations_to_keep_command
    Float? tree_score_cutoff
  }

  Int disk_size = ceil((size(gvcf, "GiB")) * 4) + additional_disk

  command {
    set -e 

    gatk --java-options "-Xms3000m -Xmx3000m" \
      ReblockGVCF \
      -R ~{ref_fasta} \
      -V ~{gvcf} \
      -do-qual-approx \
      --floor-blocks -GQB 20 -GQB 30 -GQB 40 \
      ~{annotations_to_keep_command} \
      ~{"--tree-score-threshold-to-no-call " + tree_score_cutoff} \
      -O ~{output_vcf_filename}
  }

  runtime {
    memory: "3750 MiB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    docker: gatk_docker
  }

  output {
    File output_vcf = "~{output_vcf_filename}"
    File output_vcf_index = "~{output_vcf_filename}.tbi"
  }
} 
