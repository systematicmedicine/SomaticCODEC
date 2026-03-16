"""
Writes git metadata to file for version tracking
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule write_git_metadata:
    output:
        json = L.GIT_METADATA
    log:
        L.WRITE_GIT_METADATA
    benchmark:
        B.WRITE_GIT_METADATA
    threads:
        1
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
