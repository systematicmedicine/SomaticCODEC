# Write git metadata to file for version tracking

rule write_git_metadata:
    output:
        json = "logs/global_rules/git_metadata.json"
    log:
        "logs/global_rules/write_git_metadata.log"
    benchmark:
        "logs/global_rules/write_git_metadata.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Write git metadata
        write_git_metadata.py \
            --json {output.json} \
            --log {log} 2>> {log}
        """
