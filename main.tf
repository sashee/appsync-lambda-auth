provider "aws" {
}

data "aws_region" "current" {}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_iam_role" "appsync" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "appsync" {
  statement {
    actions = [
      "dynamodb:GetItem",
    ]
    resources = [
			aws_dynamodb_table.documents.arn,
			aws_dynamodb_table.files.arn,
    ]
  }
}

resource "aws_iam_role_policy" "appsync" {
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync.json
}


resource "aws_appsync_graphql_api" "appsync" {
  name                = "appsync_test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_LAMBDA"
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ALL"
  }
	lambda_authorizer_config {
		authorizer_uri = aws_lambda_function.authorizer.arn
	}
}

resource "aws_lambda_permission" "appsync_lambda_authorizer" {
	action        = "lambda:InvokeFunction"
	function_name = aws_lambda_function.authorizer.function_name
	principal     = "appsync.amazonaws.com"
	source_arn    = aws_appsync_graphql_api.appsync.arn
}

data "aws_iam_policy_document" "appsync_push_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "appsync_logs" {
  assume_role_policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
		"Effect": "Allow",
		"Principal": {
			"Service": "appsync.amazonaws.com"
		},
		"Action": "sts:AssumeRole"
		}
	]
}
POLICY
}

resource "aws_iam_role_policy" "appsync_logs" {
  role   = aws_iam_role.appsync_logs.id
  policy = data.aws_iam_policy_document.appsync_push_logs.json
}

resource "aws_cloudwatch_log_group" "appsync_loggroup" {
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.appsync.id}"
  retention_in_days = 14
}

resource "aws_appsync_datasource" "documents" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "documents"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.documents.name
  }
}

resource "aws_appsync_datasource" "files" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "files"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.files.name
  }
}

