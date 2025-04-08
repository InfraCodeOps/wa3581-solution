# Lab 8: Refactoring Analysis - Summary Notes

This document summarizes the key anti-patterns identified in the example Terraform configuration provided in Lab 8 and outlines common refactoring approaches based on the best practices discussed throughout the course. Use this to compare against your own analysis and discussion.

## Identified Issues & Anti-Patterns

Here are some of the major problems found in the example code:

1.  **Lack of Modularity:**
    *   Resources (`aws_instance`, `aws_security_group`) are defined directly in the root module.
    *   This makes reuse impossible and leads to duplication if similar setups are needed elsewhere.
    *   Configuration logic (like instance type selection) is mixed directly with resource definitions.

2.  **Monolithic State / Poor Environment Separation:**
    *   Using `terraform.workspace` extensively within resource names and conditional logic implies a single configuration managing multiple environments (dev, prod) within a single state file.
    *   This increases the blast radius (a mistake in dev applied to the wrong workspace could affect prod state), makes refactoring harder, and causes state file bloat.
    *   HCP Workspaces offer far superior isolation for state, variables, permissions, and run history.

3.  **Inadequate Security Practices:**
    *   **Credentials:** Potential for hardcoded AWS credentials in the provider block (commented out, but indicates a risk).
    *   **Security Groups:** HTTP ingress open to `0.0.0.0/0` (too permissive). SSH ingress relies on a hardcoded or externally managed IP (`YOUR_HOME_IP/32`) which is brittle and hard to manage securely across a team.
    *   **Provisioner Secrets:** `remote-exec` implies SSH access, but key management is not shown, posing a significant security risk.
    *   **Encryption:** No mention of KMS encryption for potential EBS volumes or other sensitive aspects.
    *   **Least Privilege:** The example doesn't demonstrate consideration for least-privilege IAM roles for Terraform itself.

4.  **Lack of Testing:**
    *   No automated tests (`terraform test`) exist to verify the module's logic (if it were a module) or the deployment's outcome.
    *   Reliance on manual verification after `apply`.

5.  **Manual / Unreliable Workflow:**
    *   Implied manual switching between CLI workspaces (`dev`, `prod`) is error-prone.
    *   No CI/CD pipeline means no automated checks (lint, validate, test, scan) before applying changes.
    *   Changes likely applied directly via `terraform apply` without review or traceability offered by a GitOps PR workflow.

6.  **Brittle Configuration / Provisioning:**
    *   Using `remote-exec` provisioners for configuration (installing nginx) is often unreliable, hard to test, and couples infrastructure provisioning tightly with configuration management. Alternatives like User Data scripts, dedicated config management tools (Ansible, Chef, Puppet), or pre-baked AMIs (using Packer) are generally preferred.
    *   Hardcoded AMI ID makes updates difficult.
    *   Reliance on the default VPC/subnet makes the deployment less explicit and potentially puts instances in undesirable network segments.

7.  **Poor Configuration Management:**
    *   Managing environment differences (like instance type) via `terraform.workspace` conditional logic within the main code adds complexity. Using separate input variables managed per environment (e.g., via HCP Workspace variables) is cleaner.

## Proposed Refactoring Steps

A good refactoring approach would incorporate principles from the course:

1.  **Modularize:**
    *   Create a dedicated `web-server` module (`modules/web-server/`) containing the `aws_instance` and `aws_security_group` resources.
    *   Define clear module inputs: `ami_id`, `instance_type`, `subnet_id`, `allowed_ssh_cidr`, `tags`, etc.
    *   Define clear module outputs: `instance_id`, `public_ip`, `private_ip`, `security_group_id`.

2.  **Implement Proper Environment Separation:**
    *   Create separate HCP Terraform Workspaces (e.g., `web-server-dev`, `web-server-prod`).
    *   Create corresponding directories (`env/dev/`, `env/prod/`) containing simple `main.tf` files that call the `web-server` module.
    *   Configure each workspace to point to its respective directory (`env/dev/`, `env/prod/`).
    *   Store environment-specific configurations (like `instance_type`, `allowed_ssh_cidr`, tags) as Terraform Variables within each HCP Workspace.

3.  **Adopt GitOps Workflow:**
    *   Configure HCP Workspaces for VCS integration (connected to the Git repo containing the environment configurations).
    *   Use `Manual Apply` for the `prod` workspace, `Auto Apply` (optional) for `dev`.
    *   Enforce changes via Pull Requests, enabling automated plans and reviews before merging/applying.

4.  **Enhance Security:**
    *   **Credentials:** Remove any hardcoded credentials. Rely on secure methods like HCP Environment Variables or standard AWS credential chains.
    *   **Security Group:** Parameterize the `allowed_ssh_cidr` via a module input variable, managed per environment in HCP. Restrict HTTP source CIDRs if possible.
    *   **Secrets:** Use HCP Sensitive Variables for any secrets needed (e.g., hypothetical database passwords, API keys).
    *   **Configuration:** Replace `remote-exec` with EC2 User Data or consider building custom AMIs with Packer. Manage SSH keys securely outside of Terraform state if direct SSH is needed post-provisioning.
    *   **Static Analysis:** Implement Checkov/tfsec scanning in a CI pipeline.

5.  **Implement Automated Testing:**
    *   Write `terraform test` files for the `web-server` module, covering different input scenarios (e.g., different instance types, enabling/disabling specific features if added).
    *   Test validation rules for inputs like `allowed_ssh_cidr`.

6.  **Set up CI/CD:**
    *   Create a GitHub Actions (or similar) pipeline for the *module* repository/directory (if separated) that runs `fmt`, `validate`, `terraform test`, and `checkov`.
    *   Ensure CI checks pass on Pull Requests before allowing merges.

## Benefits of Refactoring

*   **Maintainability:** Smaller, focused modules and configurations are easier to understand and modify.
*   **Reusability:** The `web-server` module can be used elsewhere.
*   **Scalability:** Managing environments via separate workspaces scales better than monolithic configurations.
*   **Reliability:** Automated testing and GitOps workflows drastically reduce errors from manual processes.
*   **Security:** Proactive scanning, proper secrets management, and least-privilege configurations reduce risk.
*   **Collaboration:** PR reviews, isolated state, and clear ownership (implied by structure) improve teamwork.

By applying these advanced practices, the initially flawed configuration transforms into a robust, scalable, and secure system aligned with modern Infrastructure as Code principles.