AWS Tagging Strategy
This document outlines our AWS tagging strategy for resources managed by Terraform.
Purpose of Tagging

Resource Organization: Easily identify and group related resources
Cost Allocation: Track and analyze costs by environment, team, or project
Automation: Enable automated tasks and policies based on tags
Resource Lifecycle: Identify resources for maintenance, backup, and retirement
Compliance: Maintain compliance with organizational policies
Ownership: Identify who is responsible for each resource

Mandatory Tags
These tags are applied to all resources:
Tag NameDescriptionExample ValuesNameResource namedev-health-event-formatterEnvironmentDeployment environmentdev, staging, prodServiceService/application nameaws-health-notificationsManagedByTool managing the resourceterraformTerraformRepoSource repositorygithub.com/your-org/aws-health-notificationsTerraformWorkflowCI/CD workflow managing the resourcegithub-actionsOwnerTeam or person responsibleplatform-teamCostCenterBusiness unit for billingplatform-engineeringProjectProject namehealth-monitoringCreatedBySpecific module/script that created the resourceterraform-aws-health-notification
Resource-Specific Tags
These additional tags are applied to specific resource types:
Lambda Functions
Tag NameDescriptionExample ValuesFunctionFunction purposeevent-formattingRuntimeLambda runtimenodejs16.x
SNS Topics
Tag NameDescriptionExample ValuesServiceService typenotifications
IAM Roles
Tag NameDescriptionExample ValuesRoleRole purposelambda-execution
Optional Tags
These tags are optional but recommended for appropriate resources:
Tag NameDescriptionExample ValuesCriticalityBusiness impact if resource failshigh, medium, lowBackupBackup requirementstrue, falseComplianceCompliance requirementshipaa, sox, pci, noneApplicationSpecific application using resourceaws-health-notifications
Tagging Implementation
We implement tags in three ways:

Provider-Level Default Tags: Applied to all resources via the AWS provider
terraformprovider "aws" {
default_tags {
tags = {
Environment = "dev"
ManagedBy = "terraform"
}
}
}

Common Tags Local Variable: Defines standard tags for modules
terraformlocals {
common_tags = {
Service = "aws-health-notifications"
Owner = "platform-team"
Environment = var.environment
}
}

Resource-Specific Tags: Added to individual resources
terraformresource "aws_lambda_function" "example" {

# resource configuration...

tags = merge(
local.common_tags,
{
Name = "example-function"
Function = "data-processing"
}
)
}

Tag Validation and Enforcement

All infrastructure changes are validated via CI/CD
Required tags are enforced via organizational policies
Tag compliance is monitored via AWS Config
Tag auditing reports are generated quarterly

Best Practices

Use consistent naming conventions
Keep tag values concise
Use lowercase for tag keys
Use specific, descriptive values
Avoid personally identifiable information in tags
Review and update tags regularly
Document tag meanings and valid values
