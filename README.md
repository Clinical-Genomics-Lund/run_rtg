# run_rtg
Simple script to facilitate evaluation of GIAB using RTG. 

Options:


    --bed       FILE  bed for regions to analyze (will be intersected with GIAB high conf) [/data/bnf/proj/wp4/rtg_roc_analysis/refseq_crev2regions_facit.bed]

    --vcf       FILE  vcf file analyze [REQUIRED]

    --tmpdir    PATH  temp directory [.]

    --rtg       PATH [/data/bnf/sw/rtg-tools-3.10.1/RTG.jar]

    --genomedir PATH  genome directory for RTG [/data/bnf/ref/b37/SDF]

    --plot      BOOLEAN Plot roc curves

    --nonsnp    BOOLEAN extract info on delins

    --reuse     BOOLEAN reuse previous results (in ./results/)

    --compare   BOOLEAN compare results with previous runs

                v1: /data/bnf/vcf/exome/GIAB-12878.bwa.gatk_bp.vep.vcf.gz

                v2: /data/bnf/vcf/exome/GIAB-12878-v2.bwa.gatk_bp.vep.vcf.gz

                v3: /data/bnf/vcf/exome/GIAB-12878-v3.bwa.gatk_bp.vep.vcf.gz


