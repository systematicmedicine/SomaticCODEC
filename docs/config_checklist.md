# config_checklist.md

Manually check config files for the following:

* `config.yaml`
    * Downloaded from GitHub, correct branch.
    * Run name has been set
    * Change any scientific parameters that are different from default
* `ex_lanes.csv`
    * ex_lane IDs are correct
    * fastq1 and fast2 paths are mapped to R1 and R2 files
* `ex_samples.csv`
    * ex_sample IDs are correct
    * ex_lane IDs are correctly mapped to ex_lanes.csv entries
    * ex_adapter IDs appear once only between `ex_samples.csv` and `ex_technical_controls.csv`
    * ms_sample IDs are correctly mapped to ms_samples.csv entries
    * Donor IDs are correct
* `ex_technical_controls.csv`
    * ex_technical_control IDs are correct
    * ex_lane IDs are correctly mapped to ex_lanes.csv entries
    * ex_adapter IDs appear once only between `ex_samples.csv` and `ex_technical_controls.csv`
* `ex_adapters.csv`
    * ex_adapter IDs are correct
    * Adapter sequences are valid
* `ms_samples.csv`
    * ms_sample IDs are correct
    * fastq1 and fast2 paths are mapped to R1 and R2 files
    * Donor IDs are correct
* `download_list.csv`
    * Contains all files required by `config.yaml`, `ex_lanes.csv`, and `ms_samples.csv`
    * R1 and R2 files are listed for fastq.gz files
    * Source directory paths are correct
    * Destination directory paths are correct
    * Expected md5sums are correct