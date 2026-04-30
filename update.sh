#!/bin/bash
set -e

# Re-upload user.yaml to S3 and re-apply the ArgoCD Application (Helm values, portal branding).
# Pass --check for a dry run, or --tags argocd / --tags user to scope further.
has_tags=false
for arg in "$@"; do
  case "$arg" in
    --tags|--tags=*|-t) has_tags=true; break ;;
  esac
done

if [ "$has_tags" = true ]; then
  ansible-playbook -i inventory.yaml gen3.yml "$@"
else
  ansible-playbook -i inventory.yaml gen3.yml --tags user,argocd "$@"
fi
