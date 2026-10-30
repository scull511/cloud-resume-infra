import json
import re
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cloud-resume-counter')

VALID_PAGES = {'home', 'about', 'projects', 'blog', 'contact'}
PROJECT_ID_VALID_PATTERN = re.compile(r'^pr-[a-z0-9-]{1,20}$')

def increment_counter(item_id):
    response = table.update_item(
        Key={'id': item_id},
        UpdateExpression='ADD view_count :inc',
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='UPDATED_NEW'
    )
    return int(response['Attributes']['view_count'])

def lambda_handler(event, context):
    # for a page by page counter, to get the page identifier from the request (e.g. ?page=about)
    params = event.get('queryStringParameters') or {}
    page_id = params.get('page', 'unknown')

    if page_id not in VALID_PAGES and not PROJECT_ID_VALID_PATTERN.match(page_id):
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'invalid page'})
        }

    # increment specific page's counter
    page_views = increment_counter(page_id)

    # increment the total counter
    total_views = increment_counter('total')

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'page': page_id,
            'pageViews': page_views,
            'totalViews': total_views
        })
    }