# Collates all benchmarks into a single CSV

rule collate_benchmarks:
    input:
        git_metadata = "logs/global_rules/git_metadata.json",
        timeline_plot = "logs/global_rules/run_timeline.pdf"
    output:
        file_path = "logs/global_rules/combined_benchmarks.csv"
    log:
        "logs/global_rules/collate_benchmarks.log"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "collate_benchmarks.py")