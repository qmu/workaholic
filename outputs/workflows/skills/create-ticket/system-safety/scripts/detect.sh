#!/bin/sh -eu
# Detect whether the current repository is a provisioning repository.
# Usage: sh detect.sh
# Output: JSON with is_provisioning, signals, and system_changes_authorized

set -eu

# Accumulate signals as newline-delimited tokens (POSIX sh has no arrays).
# Signal names are simple [a-z_] tokens, so newline-splitting is safe.
signals=""
add_signal() {
  signals="${signals}$1
"
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
repo_name="$(basename "$repo_root")"

# Check repo name for dotfiles
if echo "$repo_name" | grep -qi "dotfiles"; then
  add_signal "repo_name_dotfiles"
fi

# Check for Ansible
if [ -f "$repo_root/ansible.cfg" ] || [ -d "$repo_root/playbooks" ]; then
  add_signal "ansible"
fi

# Check for Vagrant
if [ -f "$repo_root/Vagrantfile" ]; then
  add_signal "vagrant"
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
  add_signal "chezmoi"
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
  add_signal "terraform"
fi

# Check for Pulumi
if [ -f "$repo_root/Pulumi.yaml" ]; then
  add_signal "pulumi"
fi

# Check for Nix
if [ -f "$repo_root/flake.nix" ] || [ -f "$repo_root/configuration.nix" ]; then
  add_signal "nix"
fi

# Check for Brewfile (only if no application code markers)
if [ -f "$repo_root/Brewfile" ]; then
  if [ ! -f "$repo_root/package.json" ] && [ ! -f "$repo_root/Cargo.toml" ] && [ ! -f "$repo_root/go.mod" ]; then
    add_signal "brewfile_standalone"
  fi
fi

# Check for provisioning install scripts (only if no application code markers)
if [ -f "$repo_root/install.sh" ] || [ -f "$repo_root/setup.sh" ]; then
  if [ ! -f "$repo_root/package.json" ] && [ ! -f "$repo_root/Cargo.toml" ] && [ ! -f "$repo_root/go.mod" ] && [ ! -f "$repo_root/pyproject.toml" ]; then
    add_signal "provisioning_script"
  fi
fi

# Determine result
count=$(printf '%s' "$signals" | grep -c . || true)
is_provisioning=false
if [ "$count" -ge 1 ]; then
  is_provisioning=true
fi

system_changes_authorized=false
if [ "$count" -ge 2 ]; then
  system_changes_authorized=true
fi

# Build JSON signals array from the newline-delimited accumulator.
signals_json=$(printf '%s' "$signals" | grep -v '^$' | jq -R . | jq -s -c . 2>/dev/null || echo '[]')

cat <<EOF
{"is_provisioning": $is_provisioning, "signals": $signals_json, "system_changes_authorized": $system_changes_authorized}
EOF
