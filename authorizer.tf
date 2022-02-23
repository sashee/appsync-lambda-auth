data "external" "build" {
  program = ["bash", "-c", <<EOT
(make node_modules) >&2 && echo "{\"dest\": \".\"}"
EOT
  ]
  working_dir = "${path.module}/authorizer"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/lambda-${random_id.id.hex}.zip"
  source_dir  = "${data.external.build.working_dir}/${data.external.build.result.dest}"
}

resource "aws_lambda_function" "authorizer" {
  function_name = "authorizer-${random_id.id.hex}"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

	environment {
    variables = {
      tokens_table = aws_dynamodb_table.tokens.name
    }
  }

  handler = "index.handler"
  runtime = "nodejs14.x"
  role    = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "authorizer_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_exec_policy" {
	statement {
		actions = [
			"dynamodb:GetItem",
		]
		resources = [
			aws_dynamodb_table.tokens.arn
		]
	}
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

resource "aws_iam_role_policy" "lambda_exec_policy" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}


resource "aws_dynamodb_table" "tokens" {
  name           = "Tokens-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "token1" {
  table_name = aws_dynamodb_table.tokens.name
  hash_key   = aws_dynamodb_table.tokens.hash_key
  range_key   = aws_dynamodb_table.tokens.range_key

  item = <<ITEM
{
  "id": {"S": "token1"},
	"denied_fields": {"SS": ["Document.text"]},
	"documents": {"SS": ["doc1"]},
	"allowed_queries": {"SS": ["document"]}
}
ITEM
}

resource "aws_dynamodb_table_item" "token2" {
  table_name = aws_dynamodb_table.tokens.name
  hash_key   = aws_dynamodb_table.tokens.hash_key
  range_key   = aws_dynamodb_table.tokens.range_key

  item = <<ITEM
{
  "id": {"S": "token2"},
	"denied_fields": {"SS": ["nothing"]},
	"documents": {"SS": ["doc1", "doc2"]},
	"allowed_queries": {"SS": ["document", "file"]}
}
ITEM
}
