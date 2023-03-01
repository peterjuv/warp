version 1.0

workflow ReblockGVCF {

  File gvcf
  File ref_fasta
  
  Int small_disk
  Int medium_disk
  Int huge_disk

  String sub_strip_path = "^.*/"
  String sub_strip_gvcf = ".g.vcf.gz" + "$"
  String sub_sub = sub(sub(gvcf, sub_strip_path, ""), sub_strip_gvcf, "")

  call Reblock {
      input:
        gvcf = gvcf,
        gvcf_index = gvcf + ".tbi",
        ref_fasta = ref_fasta,
        output_vcf_filename = sub_sub + ".rbl.g.vcf.gz",
        disk_size = medium_disk
    }
  output {
    Reblock.output_vcf
    Reblock.output_vcf_index
  }
}

task Reblock {

  input {
    File gvcf
    File gvcf_index
    File ref_fasta
    String output_vcf_filename
    Int disk_size
    String gatk_docker = "us.gcr.io/broad-gatk/gatk:4.3.0.0"
  }

  command <<<
    gatk --java-options "-Xms3g -Xmx3g" \
      ReblockGVCF \
      -R ~{ref_fasta}
      -V ~{gvcf} \
      -drop-low-quals \
      -do-qual-approx \
      -rgq-threshold 10 \
      --floor-blocks -GQB 10 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 -GQB 70 -GQB 80 -GQB 90 -GQB 99 \
      -O ~{output_vcf_filename}
  >>>

  runtime {
    memory: "3 GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: 3
    docker: gatk_docker
  }

  output {
    File output_vcf = "~{output_vcf_filename}"
    File output_vcf_index = "~{output_vcf_filename}.tbi"
  }
} 