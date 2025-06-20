# bcftools query for het/homo ratio
bcftools query -f '[%GT\n]' tmp/data/processed/Sample01_hardFilter_passed.vcf.gz \
    | sort | uniq -c\
    | awk ' 
    {
        if ($2 == "0/1" || $2 == "1/0" ||$2 == "1/2") het+=$1;
        else if ($2 == "1/1") hom+=$1
    }
    END {
        print "Heterozygous_count\tHeterozygous_count\tratio";
        het+=0; hom+=0;
        print het, hom, (hom+0 > 0 ? (het+0)/(hom+0) : 0);
    }
 '   OFS="\t" > tmp/metrics/genotype_summary.txt 
