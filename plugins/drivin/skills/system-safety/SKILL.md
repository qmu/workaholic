---
name: system-safety
description: Prevent agents from modifying system-wide configuration in regular projects.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
---

# System Safety

Prevents agents from modifying system-wide configuration (shell profiles, global packages, system services, etc.) unless the repository is specifically a provisioning repository.

## 1. Authorization Model

Repositories fall into two categories:

- **Provisioning repository**: A repository whose purpose is to configure a server, laptop, or environment (dotfiles, Ansible playbooks, Terraform, Nix configs, etc.). System-wide changes ARE authorized.
- **Regular project**: An application, library, plugin, or service. System-wide changes are NOT authorized.

If uncertain, treat as a regular project. False negatives (failing to detect a provisioning repo) are less harmful than false positives (allowing system changes in a regular project).

## 2. Provisioning Detection

Run the detection script at the start of implementation:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/system-safety/sh/detect.sh
```

The script checks for provisioning indicators and outputs JSON:

```json
{
  "is_provisioning": false,
  "signals": [],
  "system_changes_authorized": false
}
```

### 2-1. Provisioning Signals

The script checks for these indicators:

| Signal | Check |
|--------|-------|
| Repo name contains "dotfiles" | Directory name of repo root |
| Ansible configuration | `ansible.cfg` or `playbooks/` at root |
| Vagrant configuration | `Vagrantfile` at root |
| Chezmoi configuration | `.chezmoi*` files at root |
| Terraform configuration | `*.tf` files at root |
| Pulumi configuration | `Pulumi.yaml` at root |
| Nix configuration | `flake.nix` or `configuration.nix` at root |
| Brewfile | `Brewfile` at root with no `package.json`/`Cargo.toml`/`go.mod` |
| Provisioning install script | `install.sh` or `setup.sh` at root with no application code |

Two or more signals confirm a provisioning repository. A single signal sets `is_provisioning: true` but the agent should verify with the user if the operation is significant.

## 3. Prohibited Operations

In regular projects, the following operations are **NEVER** allowed:

| Operation | Example | Risk |
|-----------|---------|------|
| Global package installs | `npm install -g`, `pip install` (without virtualenv), `gem install` (without bundler) | Modifies global package state |
| Shell profile edits | Writing to `~/.bashrc`, `~/.zshrc`, `~/.profile`, `~/.bash_profile` | Alters user shell environment |
| System config edits | Writing to `/etc/*` | Alters system-wide configuration |
| System service management | `systemctl enable/start/stop`, `launchctl load` | Changes running services |
| Environment variable exports in profiles | Appending `export` lines to shell profiles | Persistent environment changes |
| Global tool configuration | Writing to `~/.gitconfig`, `~/.npmrc`, `~/.config/*` (outside project) | Alters global tool behavior |
| Privilege escalation | `sudo` commands | May modify system state |

### 3-1. Safe Alternatives

| Prohibited | Safe Alternative |
|-----------|-----------------|
| `npm install -g <pkg>` | `npx <pkg>` or add to project `devDependencies` |
| `pip install <pkg>` | `pip install <pkg>` inside a virtualenv or `uv pip install` |
| Editing `~/.bashrc` | Use project-local `.env` or `.envrc` files |
| `sudo apt install` | Document the dependency in README or check if already available |
| `systemctl start` | Use `docker compose up` or project-local service management |
| Writing to `~/.gitconfig` | Use project-local `.gitconfig` or `git -c` flags |

## 4. Enforcement

This is a textual constraint enforced through agent instructions. Agents must:

1. Run the detection script before any implementation that may touch system configuration
2. If `system_changes_authorized` is `false`, refuse any operation from the prohibited list
3. If an implementation step requires a prohibited operation, propose a safe alternative instead
4. If no safe alternative exists, report the blocker to the user rather than proceeding
