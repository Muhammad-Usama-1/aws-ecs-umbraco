
When you create an aws_iam_policy, that is a managed policy and can be re-used.

When you create a aws_iam_role_policy that's an inline policy

Terraform provides multiple ways to represent a policy in HCL, those are:

HEREDOC syntax
jsonencode function to convert a policy into JSON
file function to load a policy from a JSON file
aws_iam_policy_document data resource

Standalone IAM Policies
