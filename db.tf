resource "aws_dynamodb_table" "documents" {
  name           = "Documents-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "files" {
  name           = "Files-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

## sample data

resource "aws_dynamodb_table_item" "document1" {
  table_name = aws_dynamodb_table.documents.name
  hash_key   = aws_dynamodb_table.documents.hash_key
  range_key   = aws_dynamodb_table.documents.range_key

  item = <<ITEM
{
  "id": {"S": "doc1"},
  "title": {"S": "Document 1"},
	"text": {"S": "Text for document 1"}
}
ITEM
}

resource "aws_dynamodb_table_item" "document2" {
  table_name = aws_dynamodb_table.documents.name
  hash_key   = aws_dynamodb_table.documents.hash_key
  range_key   = aws_dynamodb_table.documents.range_key

  item = <<ITEM
{
  "id": {"S": "doc2"},
  "title": {"S": "Document 2"},
	"text": {"S": "Text for document 2"}
}
ITEM
}

resource "aws_dynamodb_table_item" "file1" {
  table_name = aws_dynamodb_table.files.name
  hash_key   = aws_dynamodb_table.files.hash_key
  range_key   = aws_dynamodb_table.files.range_key

  item = <<ITEM
{
  "id": {"S": "file1"},
	"name": {"S": "File1"},
	"url": {"S": "example.com/file1"}
}
ITEM
}

