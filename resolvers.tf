resource "aws_appsync_resolver" "Query_document" {
  api_id      = aws_appsync_graphql_api.appsync.id
	type        = "Query"
	field       = "document"
  data_source = aws_appsync_datasource.documents.name
  request_template = <<EOF
#if(!$util.parseJson($ctx.identity.resolverContext.allowedQueries).contains("document") || !$util.parseJson($ctx.identity.resolverContext.documents).contains($ctx.arguments.id))
	$util.unauthorized()
#end
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key": {
		"id": $util.dynamodb.toDynamoDBJson($ctx.arguments.id)
	},
	"consistentRead" : true
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_resolver" "Query_file" {
  api_id      = aws_appsync_graphql_api.appsync.id
	type        = "Query"
	field       = "file"
  data_source = aws_appsync_datasource.files.name
  request_template = <<EOF
#if(!$util.parseJson($ctx.identity.resolverContext.allowedQueries).contains("file"))
	$util.unauthorized()
#end
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key": {
		"id": $util.dynamodb.toDynamoDBJson($ctx.arguments.id)
	},
	"consistentRead" : true
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}
