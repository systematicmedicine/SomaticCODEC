"""
--- het_hom_ration.sh ---

Calculate the Het/hom ratio from a filtered vcf (the indended use case is for germline vcf)

Input: {ms_sample}_ms_filter_pass_variants.vcf.gz
Output: txt file containing "het_count" "hom_count" "ratio"

Author: Ben Barry
"""
input_vcf="$1"
output_txt="$2"

bcftools query -f '[%GT\n]' "$input_vcf" \
    | sort | uniq -c \
    | awk '
    {
        if ($2 == "0/1" || $2 == "1/0" || $2 == "1/2") het += $1;
        else if ($2 == "1/1") hom += $1;
    }
    END {
        print "Heterozygous_count", "Homozygous_count", "Het/Hom_Ratio";
        het += 0; hom += 0;
        print het, hom, (hom > 0 ? het / hom : "NA");
    }
' OFS="\t" > "$output_txt"