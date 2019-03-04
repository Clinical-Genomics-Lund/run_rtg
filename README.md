# run_rtg
Simple script to facilitate evaluation of GIAB using RTG. 

Options:

run_rtg.pl

    --bed       FILE  bed for regions to analyze (will be intersected with GIAB high conf) [/data/bnf/proj/wp4/rtg_roc_analysis/refseq_crev2regions_facit.bed]

    --vcf       FILE  vcf file analyze [REQUIRED]

    --tmpdir    PATH  temp directory [.]

    --genomedir PATH  genome directory for RTG [/data/bnf/ref/b37/SDF]

    --compare   BOOLEAN compare results with previous runs

    --plot      BOOLEAN Plot roc curves

