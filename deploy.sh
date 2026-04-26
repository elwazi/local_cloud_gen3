#!/bin/bash
set -e

mkdir -p logs

echo "Running common.yml..."
ansible-playbook -i inventory.yaml common.yml

echo "Running database.yml, storage.yml, load_balancer.yml, rancher.yml in parallel..."
ansible-playbook -i inventory.yaml database.yml      > logs/database.log      2>&1 & pid_db=$!
ansible-playbook -i inventory.yaml storage.yml       > logs/storage.log       2>&1 & pid_storage=$!
ansible-playbook -i inventory.yaml load_balancer.yml > logs/load_balancer.log 2>&1 & pid_lb=$!
ansible-playbook -i inventory.yaml rancher.yml       > logs/rancher.log       2>&1 & pid_rancher=$!

fail=0
wait $pid_db      || { echo "database.yml failed — see logs/database.log";           fail=1; }
wait $pid_storage || { echo "storage.yml failed — see logs/storage.log";             fail=1; }
wait $pid_lb      || { echo "load_balancer.yml failed — see logs/load_balancer.log"; fail=1; }
wait $pid_rancher || { echo "rancher.yml failed — see logs/rancher.log";             fail=1; }
[[ $fail -eq 0 ]] || exit 1

echo "Parallel playbooks complete."

echo "Running argocd.yml..."
ansible-playbook -i inventory.yaml argocd.yml

echo "Running gen3.yml..."
ansible-playbook -i inventory.yaml gen3.yml

echo "Deploy complete."
