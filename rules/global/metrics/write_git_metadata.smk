# Write git metadata to file for version tracking

rule write_git_metadata:
    output:
        file_path = "logs/global_rules/git_metadata.json"
    log:
        "logs/global_rules/write_git_metadata.log"
    benchmark:
        "logs/global_rules/write_git_metadata.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "write_git_metadata.py")