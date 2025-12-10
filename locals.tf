/* Local values derived from variables */

locals {
  /**
   * Prefix used for naming resources.  Combines project name and
   * environment to avoid collisions across environments.
   */
  name_prefix = "${var.project_name}-${var.environment}"

  /**
   * Derive an ECS cluster name if one is not supplied via tfvars.  The
   * ternary operator falls back to a default pattern if the variable is
   * unset or empty.  This avoids having to set a value in every
   * environment explicitly.
   */
  ecs_cluster_name = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${local.name_prefix}-cluster"
}
