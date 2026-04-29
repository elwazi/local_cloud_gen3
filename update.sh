#!/bin/bash
set -e

# Re-upload user.yaml to S3 and re-apply the ArgoCD Application (Helm values, portal branding).
# Pass --check for a dry run, or --tags argocd / --tags user to scope further.
ansible-playbook -i inventory.yaml gen3.yml --tags user,argocd "$@"
