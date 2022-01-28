# this file sets up the CI pipeline to build and deploy the blog

data aws_caller_identity current {}

resource aws_codestarconnections_connection "github" {
  name = "GitRepositoryConnection"
  provider_type = "GitHub"
}

resource aws_codebuild_project "blogBuild" {
  name = "shearn89-blog-branch"
  service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/codebuild-shearn89-blog-service-role"
  badge_enabled = true
  source_version = "main"

  source {
    type = "GITHUB"
    location = "https://github.com/shearn89/shearn89.github.com"
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
  }

  artifacts {
    type = "S3"
    location = "shearn89-artifacts"
    name = "shearn89-blog-branch"
    packaging = "ZIP"
  }

  environment {
    type = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "SERVICE_ROLE"
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/hugo:latest"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/codebuild"
      stream_name = "shearn89-blog-build"
    }
  }
}

# Use CodeBuild here as the S3 deployment doesn't do a `sync`, so deleted files are still in the site.
resource aws_codebuild_project "blogDeploy" {
  name = "BlogDeployS3"
  service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/codebuild-shearn89-blog-service-role"

  source {
    type = "CODEPIPELINE"
    buildspec = file("../deployspec.yml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "CODEBUILD"
    image = "aws/codebuild/standard:5.0"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/codebuild"
      stream_name = "shearn89-blog-deploy"
    }
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "shearn89-blog"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSCodePipelineServiceRole-eu-west-1-shearn89-blog"
  artifact_store {
    location = "codepipeline-eu-west-1-356498201105"
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      category = "Source"
      name     = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"
      output_artifacts = ["SourceArtifact"]
      namespace = "SourceVariables"
      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "shearn89/shearn89.github.com"
        BranchName = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }
  stage {
    name = "Build"
    action {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version = "1"
      namespace = "BuildVariables"
      configuration = {
        ProjectName = aws_codebuild_project.blogBuild.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Build"
      name = "DeployS3"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["BuildArtifact"]
      version = "1"
      configuration = {
        ProjectName = "BlogDeployS3"
        EnvironmentVariables = jsonencode([
          {
            name = "S3_BUCKET"
            value = "shearn89-blog"
            type = "PLAINTEXT"
          }
        ])
      }
    }
  }
}