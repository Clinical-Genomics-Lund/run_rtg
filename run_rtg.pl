#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use File::Spec;
use File::Path qw(make_path);
use File::Basename;
use lib dirname (__FILE__);
#use Time::localtime;
use Getopt::Long;
use Time::Piece;
use POSIX qw(strftime);

my $date = localtime->strftime('%d%m%Y');

our %opt;
GetOptions( \%opt, 'bed=s', 'vcf=s', 'tmpdir=s', 'genomedir=s', 'rtg=s','compare', 'plot', 'nonsnp','reuse');

if(!$opt{'vcf'} || $opt{'help'}){
    print "$0\n\n";
    print "    --bed       FILE  bed for regions to analyze (will be intersected with GIAB high conf) [/data/bnf/proj/wp4/rtg_roc_analysis/refseq_crev2regions_facit.bed]\n\n";
    print "    --vcf       FILE  vcf file analyze [REQUIRED]\n\n";
    print "    --tmpdir    PATH  temp directory [.]\n\n";
    print "    --rtg       PATH [/data/bnf/sw/rtg-tools-3.10.1/RTG.jar]\n\n";
    print "    --genomedir PATH  genome directory for RTG [/data/bnf/ref/b37/SDF]\n\n";
    print "    --plot      BOOLEAN Plot roc curves \n\n";
    print "    --nonsnp    BOOLEAN extract info on delins \n\n";
    print "    --reuse     BOOLEAN reuse previous results (in ./results/) \n\n";
    print "    --compare   BOOLEAN compare results with previous runs \n\n";
    print "                v1: /data/bnf/vcf/exome/GIAB-12878.bwa.gatk_bp.vep.vcf.gz\n\n";
    print "                v2: /data/bnf/vcf/exome/GIAB-12878-v2.bwa.gatk_bp.vep.vcf.gz\n\n";
    print "                v3: /data/bnf/vcf/exome/GIAB-12878-v3.bwa.gatk_bp.vep.vcf.gz\n\n";
    
    exit(0);
}


die("RTG not found at /data/bnf/sw/rtg-tools-3.6.2/RTG.jar :/") unless -e "/data/bnf/sw/rtg-tools-3.6.2/RTG.jar";


#
# Constants
#

my $GIAB_BED   = "/data/bnf/ref/gib/HG001_NA12878/HG001_GRCh37_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_nosomaticdel.merge.bed";
my $GIAB_CALLS = "/data/bnf/ref/gib/HG001_NA12878/HG001_GRCh37_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz";

my %reference_vcfs = (
    "v1"  => "/data/bnf/vcf/exome/GIAB-12878.bwa.gatk_bp.vep.vcf.gz",
    "v2" => "/data/bnf/vcf/exome/GIAB-12878-v2.bwa.gatk_bp.vep.vcf.gz",
    "v3"  => "/data/bnf/vcf/exome/GIAB-12878-v3.bwa.gatk_bp.vep.vcf.gz",
    );

#
# Read command line arguments
#
my $bed = $opt{'bed'} || "/data/bnf/proj/wp4/rtg_roc_analysis/refseq_crev2regions_facit.bed";
my $vcf = $opt{'vcf'};
my $rtg = $opt{'rtg'} || "/data/bnf/sw/rtg-tools-3.10.1/RTG.jar";
my $genome_dir = $opt{'genome_dir'} || "/data/bnf/ref/b37/SDF";
my $tmpdir = $opt{tmpdir} || "./tmpdir";

print_run("mkdir -p $tmpdir") unless -e "$tmpdir";

# If vcf is not bgzipped, do it in the temp folder
unless( $vcf =~ /\.gz$/ ) {
    print_run("cp $vcf $tmpdir");
    print_run("bgzip -\@10 $tmpdir/$vcf");
    print_run("tabix $tmpdir/$vcf.gz");
    $vcf = "$tmpdir/$vcf.gz";
}


# Intersect bed
print_run("bedtools intersect -a $bed -b $GIAB_BED > $tmpdir/$date.intersect.bed");
print("Size of bed to use for analysis: ");system("bed_size.pl $tmpdir/$date.intersect.bed");


# run RTG
if(!$opt{'reuse'}){
print("Running RTG...\n");
print_run("rm -rf results/");
print_run("java -jar $rtg vcfeval -b $GIAB_CALLS -c $vcf -o results --bed-regions $tmpdir/$date.intersect.bed -t $genome_dir");
}

my $roc_files = "";
my $roc_non_snp_files = "";


if($opt{'compare'}){
   
    for my $ref_vcf (keys %reference_vcfs) {
	print_run("java -jar $rtg vcfeval -b $GIAB_CALLS -c $reference_vcfs{$ref_vcf} -o $tmpdir/results_${ref_vcf} --bed-regions $tmpdir/$date.intersect.bed -t $genome_dir");
	$roc_files .= $roc_files." $tmpdir/results_${ref_vcf}/snp_roc.tsv.gz";
	$roc_non_snp_files .= $roc_non_snp_files." $tmpdir/results_${ref_vcf}/non_snp_roc.tsv.gz";
    }

}

if($opt{'plot'}){
    print("Plotting ROC to roc_curve.png\n");
    system("rm roc_curve.png") if -e "roc_curve.png";
    print_run("java -jar $rtg rocplot --png=roc_curve.png results/snp_roc.tsv.gz $roc_files");
}

if($opt{'nonsnp'}){

    open(IN, "zcat results/non_snp_roc.tsv.gz |") or die "gunzip : $!";
    my @non_snp_roc = <IN>;
    
    my $best_f_score=0;
    my $best_row=0;


    my $i=0;
    
    foreach(@non_snp_roc){
	my @fields = split;
	next if $fields[0] =~ /^\#/;
	if ($fields[7] > $best_f_score){
	    $best_row=$_;
	    $best_f_score = $fields[7];
	}
    }

    print "Best f-score for non_snps:\n";
    print $non_snp_roc[6].$best_row;
    print "For full results see results/non_snp_roc.tsv.gz \n\n";

}
    




sub print_run{
    my $command = shift;
    my $result_file=shift || "";
    if(! -s $result_file){
	system("$command");
    }
    return 0;
}


