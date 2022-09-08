variable "env" {
  description = "Depolyment environment"
  default     = "dev"
}

variable "github_branch" {
  description = "Repository branch to connect to"
  default     = "master"
}

variable "github_owner" {
  description = "GitHub repository owner"
  default     = "priyashukla1411"
}
variable "github_repo" {
  description = "GitHub repository name"
  default     = "https://github.com/priyashukla1411/react-native.git"
}

variable "github_token" {
  description = "This is github authentication token"
  default = "**************"
  type = string
}

###############
variable "artifacts_bucket_name" {
  description = "S3 Bucket for storing artifacts"
  default     = "artifacts-bucket-devops-rectnative1"
}
resource "aws_s3_bucket" "artifacts_bucket_name" {
  bucket = "artifacts-bucket-devops-rectnative1"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
##########################################################################################
# code build:-

data "template_file" "buildspec" {
  template = "buildspec.yml"
  
}

resource "aws_codebuild_project" "node_build" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "node_build"
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild_role99888.arn
  tags = {
    Environment = var.env
  }

  artifacts {
   
    type                   = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    type  = "GITHUB"
    location = "https://github.com/priyashukla1411/react-native.git"
    git_clone_depth = 1
  }
 
}

resource "aws_iam_role" "codebuild_role99888" {
  name = "reactnative"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "nodepolicytest10"
  role = aws_iam_role.codebuild_role99888.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${var.artifacts_bucket_name}/*"
            ],
            "Action": [
                "*"
            ]
        },
        {
          "Effect": "Allow",
          "Resource": [
            "*"
          ],
          "Action": [
            "*"
          ]
        }
    ]
}
EOF
}


# # pipeline :-

resource "aws_codepipeline" "node_pipeline11" {
  name     = "node_pipeline11"
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = {
    Environment = var.env
  }

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      # input_artifacts  = []
      output_artifacts = ["SourceArtifact"]

      configuration = {
        Owner      = "priyashukla1411"
        Repo       = "react-native"  
        Branch     = "master"
        OAuthToken = "**************"
 
      }
    }
  }
  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            {
              name  = "environment"
              type  = "PLAINTEXT"
              value = var.env
            },
          ]
        )
        "ProjectName" = "node_build"
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name = "Build"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = var.artifacts_bucket_name
        "Extract"    = "true"
      }
      input_artifacts = [
        "BuildArtifact",
      ]
      name             = "Deploy"
   
      owner            = "AWS"
      provider         = "S3"

      version          = "1"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "noderoletest1111"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy11" {
  name = "nodepolicytest11"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "*"
      ],
      "Resource": [
        "*" 
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
