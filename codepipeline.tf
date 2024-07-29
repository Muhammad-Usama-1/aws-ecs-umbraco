# ==================== Codedeploy ====================
resource "aws_codedeploy_app" "codedeploy_app" {
  name = "${var.project_name}-codedeploy"
  # compute_platform = "ECS" #ECS, Lambda, or Server. Default is Server.
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "${var.project_name}-deployment-group" 
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  ec2_tag_set {
    ec2_tag_filter {
      key   = "filterkey1"
      type  = "KEY_AND_VALUE"
      value = "filtervalue"
    }

    ec2_tag_filter {
      key   = "filterkey2"
      type  = "KEY_AND_VALUE"
      value = "filtervalue"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# ==================== CodeBuild ====================
resource "aws_codebuild_project" "example_codebuild_project" {
  name          = "${var.project_name}-codebuild" 
  #description   = "Codebuild for appexample-dev"
  build_timeout = "30"
  service_role  = aws_iam_role.example_codebuild_project_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
  }
  logs_config {
    cloudwatch_logs {
      group_name  =       "${var.project_name}-log-group"
      stream_name =  "${var.project_name}-log-stream"

    }
  }
  source {
    type = "CODEPIPELINE"
    buildspec = file("./builspec.yaml")
  }
}

# ==================== CodePipeline ====================

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"


  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId     = format("%s/%s", "Muhammad-Usama-1","dockerize-next")
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
    

     configuration = {
        ProjectName = aws_codebuild_project.example_codebuild_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName  = aws_codedeploy_app.codedeploy_app.name
       DeploymentGroupName = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "example" {
  name          = "mygithubconnection2"
  provider_type = "GitHub"
}
