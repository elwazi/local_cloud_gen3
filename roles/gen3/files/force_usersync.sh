#!/bin/bash
set -e
job="usersync-manual-$(date +%s)"
kubectl create job -n gen3 "$job" --from=cronjob/usersync
echo "Created job $job — follow logs with:"
echo "  kubectl logs -n gen3 -l job-name=$job -c awshelper --follow"
