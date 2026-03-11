#!/bin/bash
# Detect whether the current repository is a provisioning repository.
# Usage: bash detect.sh
# Output: JSON with is_provisioning, signals, and system_changes_authorized

set -euo pipefail

signals=()

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
repo_name="$(basename "$repo_root")"

# Check repo name for dotfiles
if echo "$repo_name" | grep -qi "dotfiles"; then
  signals+=("repo_name_dotfiles")
fi

# Check for Ansible
if [ -f "$repo_root/ansible.cfg" ] || [ -d "$repo_root/playbooks" ]; then
  signals+=("ansible")
fi

# Check for Vagrant
if [ -f "$repo_root/Vagrantfile" ]; then
  signals+=("vagrant")
fi

# Check for Chezmoi
chezmoi_found=false
for f in "$repo_root"/.chezmoi*; do
  if [ -e "$f" ]; then
    chezmoi_found=true
    break
  fi
done
if [ "$chezmoi_found" = true ]; then
  signals+=("chezmoi")
fi

# Check for Terraform
tf_found=false
for f in "$repo_root"/*.tf; do
  if [ -e "$f" ]; then
    tf_found=true
    break
  fi
done
if [ "$tf_found" = true ]; then
  signals+=("terraform")
fi

# Check for Pulumi
if [ -f "$repo_root/Pulumi.yaml" ]; then
  signals+=("pulumi")
fi

# Check for Nix
if [ -f "$repo_root/flake.nix" ] || [ -f "$repo_root/configuration.nix" ]; then
  signals+=("nix")
fi

# Check for Brewfile (only if no application code markers)
if [ -f "$repo_root/Brewfile" ]; then
  if [ ! -f "$repo_root/package.json" ] && [ ! -f "$repo_root/Cargo.toml" ] && [ ! -f "$repo_root/go.mod" ]; then
    signals+=("brewfile_standalone")
  fi
fi

# Check for provisioning install scripts (only if no application code markers)
if [ -f "$repo_root/install.sh" ] || [ -f "$repo_root/setup.sh" ]; then
  if [ ! -f "$repo_root/package.json" ] && [ ! -f "$repo_root/Cargo.toml" ] && [ ! -f "$repo_root/go.mod" ] && [ ! -f "$repo_root/pyproject.toml" ]; then
    signals+=("provisioning_script")
  fi
fi

# Determine result
count=${#signals[@]}
is_provisioning=false
if [ "$count" -ge 1 ]; then
  is_provisioning=true
fi

system_changes_authorized=false
if [ "$count" -ge 2 ]; then
  system_changes_authorized=true
fi

# Build JSON signals array
signals_json="[]"
if [ "$count" -gt 0 ]; then
  signals_json="["
  for i in "${!signals[@]}"; do
    if [ "$i" -gt 0 ]; then
      signals_json+=","
    fi
    signals_json+="\"${signals[$i]}\""
  done
  signals_json+="]"
fi

cat <<EOF
{"is_provisioning": $is_provisioning, "signals": $signals_json, "system_changes_authorized": $system_changes_authorized}
EOF
