# Adapting SomaticCODEC to new use cases

This document outlines suggested approaches for adapting SomaticCODEC to alternative use cases. Our expertise varies across application domains, so this should be treated as a starting point.

Modifying the assay generally falls into three categories:

- Adjusting `config.yaml` → `sci_params` (simplest)
- Modifying pipeline rules (moderate difficulty)
- Modifying library preparation (most difficult)

When making substantive changes to the assay we strongly recommend re-validating its suitability for your use-case before generating scientific data.


## Tumour (human)

- Consider replacing or extending rule `ex_call_somatic_snv` with a cancer-optimised caller (e.g. `Mutect2`). 
- Consider generating a lower depth for the `ms_sample`. By default, the assay requires ≥40× depth in the matched sample. This reduces germline leakage and helps low-VAF somatic variants rise above the noise floor. This level of depth may be unnecessary if detection of low-VAF variants is not required.
- Consider a higher depth for the `ex_sample`. By default, the assay averages ~1× depth across the genome, which limits precision when estimating variant allele frequencies. To achieve higher depth more cost-effectively, consider targeting a smaller subset of the genome.


## Cultured cells (human)

We are currently establishing this capability. A cell culture–optimised profile is expected to be released in the future.

## Other species

- Restriction enzyme cut sites may result in different DNA fragment length distributions across species
  - Verify that DNA fragment sizes are appropriate after fragmentation
  - In an internal pilot, mouse DNA yielded a similar size distribution to human DNA without modification to the protocol
- Human-specific reference resources must be replaced:
  - Reference genome
  - Genome masks
  - Germline variant database
  - Trinucleotide context reference
- Reduced effectiveness of genome masks may result in increased false positive SNV calls

## No matched sample (dependent samples)

- A dependent sample design requires higher `ex_sample` depth. In our use case, it was more cost-effective to use an `ms_sample` for germline variant calling than to increase `ex_sample` depth.
- Using a dependent sample design may increase germline leakage, resulting in more false positive SNV calls. This can reduce sensitivity for low-VAF variants by increasing the effective noise floor.

