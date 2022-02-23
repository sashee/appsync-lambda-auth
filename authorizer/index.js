import { DynamoDBClient, GetItemCommand } from "@aws-sdk/client-dynamodb";

export const handler = async (event) => {
	const {tokens_table} = process.env;
	const token = event.authorizationToken;

	const client = new DynamoDBClient();
	const item = await client.send(new GetItemCommand({
		TableName: tokens_table,
		Key: {id: {S: token}},
	}));
	if (!item.Item) {
		return {
			isAuthorized: false,
			ttlOverride: 0,
		};
	}else {
		return {
			isAuthorized: true,
			deniedFields: item.Item.denied_fields.SS,
			resolverContext: {
				allowedQueries: JSON.stringify(item.Item.allowed_queries.SS),
				documents: JSON.stringify(item.Item.documents.SS),
			},
			ttlOverride: 0,
		};
	}

};
