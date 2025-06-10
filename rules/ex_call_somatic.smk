"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: ...
Output: ...

Author: ...

Temporary working comments:

# Personalized vcf name:
tmp/ms_hek1.1/ms_hek1.1.vcf
tmp/ms_hek1.1/ms_hek1.1.vcf.idx

# Personalized fasta name:

# Duplex bam name: 
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam.bai

"""
# Call variants
vardict-java \
  -G tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
  -f 0 \
  -N test \
  -b tmp/first_read_4somatic.bam \
  -z \
  -c 1 -S 2 -E 3 -g 4 \
  -R "chr1:1000000-1001000" \
  -Q 0 \
  -r 1 \
  -d 1 \
  -q 0 \
  -U \
  -e 0 \
  -X 1 \
> tmp/vardict_output.tsv 

# Add headers to variants.tsv
(echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType"; cat tmp/vardict_output.tsv) > tmp/vardict_output_with_header.tsv
(echo -e "Sample\tChr\tStart\tEnd\tRef\tAlt\tVarType\tReadCount\tRefCount\tAltCount\tStrandBias\tRefBias\tAltBias\tRef/Alt\tVAF\tPCRdupRate\tMQ0\tNM\tAvgReadLen\tPosMean\tPhred\tReads\tAF\tPV\tHP\tConservativeCall\tMQMean\tRefQ\tAltQ\tRefBiasBases\tAltBiasBases\tRegion\tType\tFilter\tCluster"; cat tmp/vardict_output.tsv) > tmp/vardict_output_with_header.tsv

(echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType"; cat tmp/vardict_output.tsv) > tmp/vardict_output_with_header.tsv




#Testprocess
samtools view -Sb tmp/first_read_4somatic.sam > tmp/first_read_4somatic.bam
samtools index tmp/first_read_4somatic.bam
vardict-java   -G tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna   -f 0   -N test   -b tmp/first_read_4somatic.bam   -z   -c 1 -S 2 -E 3 -g 4   -R "chr1:1000000-1001000"   -Q 0   -r 1   -d 1   -q 0   -U   -e 0   -X 1 > tmp/vardict_output.tsv
(echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType"; cat tmp/vardict_output.tsv) > tmp/vardict_output_4somatictest.tsv

#one-liner
samtools view -Sb tmp/first_read_4somatic.sam > tmp/first_read_4somatic.bam && samtools index tmp/first_read_4somatic.bam && vardict-java -G tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna -f 0 -N test -b tmp/first_read_4somatic.bam -z -c 1 -S 2 -E 3 -g 4 -R "chr1:1000000-1001000" -Q 0 -r 1 -d 1 -q 0 -U -e 0 -X 0 -y -T 300 -P 0 -th 6 > tmp/vardict_output.tsv && (echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType" && cat tmp/vardict_output.tsv) > tmp/vardict_output_4somatictest.tsv

samtools view -Sb tmp/first_read_4somatic.sam > tmp/first_read_4somatic.bam && samtools index tmp/first_read_4somatic.bam && vardict-java -G tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna   -f 0 -N test   -b tmp/first_read_4somatic.bam   -z -c 1 -S 2 -E 3 -g 4   -R "chr1:1000000-1001000"   -Q 0 -r 1 -d 1 -q 0 -U -e 0 -X 0 -p > tmp/vardict_output.tsv && (echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType" && cat tmp/vardict_output.tsv) > tmp/vardict_output_4somatictest.tsv



# Full readable code
samtools view -Sb tmp/first_read_4somatic.sam > tmp/first_read_4somatic.bam && \
samtools index tmp/first_read_4somatic.bam && \

vardict-java \
  -G tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
  -f 0 \
  -N test \
  -b tmp/first_read_4somatic.bam \
  -z \
  -c 1 \
  -S 2 \
  -E 3 \
  -g 4 \
  -R "chr1:1000000-1001000" \
  -Q 0 \
  -r 1 \
  -d 1 \
  -q 0 \
  -U \
  -e 0 \
  -X 0 \
  -T 300 \
  -P 0 \
  -th 6 \
  -y > tmp/vardict_output.tsv && \

(
  echo -e "Sample\tGene\tChr\tStart\tEnd\tRef\tAlt\tDepth\tAltDepth\tRefFwdReads\tRefRevReads\tAltFwdReads\tAltRevReads\tGenotype\tAF\tBias\tPMean\tPStd\tQMean\tQStd\tMQ\tSN\tHIAF\tAdjAF\tShift3\tMSI\tMSILEN\tNM\tHiCnt\tHiCov\t5pFlankSeq\t3pFlankSeq\tSeg\tVarType" && \
  cat tmp/vardict_output.tsv
) > tmp/vardict_output_4somatictest.tsv


samtools view -Sb tmp/first_read_4somatic.sam > tmp/first_read_4somatic.bam && \
samtools index tmp/first_read_4somatic.bam && \
bcftools mpileup \
  -f tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
  -r chr1:1000000-1001000 \
  -a AD,DP \
  -Q 0 \
  -q 0 \
  -Ou tmp/first_read_4somatic.bam | \
bcftools call \
  -mv \
  -Ov -o tmp/bcftest.vcf
