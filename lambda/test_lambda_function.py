import json
import boto3
import pytest
from moto import mock_aws

from lambda_function import lambda_handler, VALID_PAGES, PROJECT_ID_VALID_PATTERN

@pytest.fixture
def dynamodb_table():
    """Creates a fake in-memory DynamoDB table matching the real one,
    so lambda_handler can run against it with no real AWS calls."""
    with mock_aws():
        client = boto3.resource('dynamodb', region_name='eu-west-2')
        table = client.create_table(
            TableName='cloud-resume-counter',
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST',
        )
        yield table

def call(page_value=None):
    """Helper function to build an event and call the handler, since almost
    every test does this with just a different page value (or none)."""
    event = {} if page_value is None else {'queryStringParameters': {'page': page_value}}
    response = lambda_handler(event, None)
    body = json.loads(response['body'])
    return response, body

# VALIDATION TESTS

# test valid page returns 200 status code
def test_valid_page_returns_200_code(dynamodb_table):
    response, body = call('home')

    assert response['statusCode'] == 200

# test valid project id returns 200 status code
# valid id regex - '^pr-[a-z0-9-]{1,20}$' - string starting 'pr-', then between 1 and 20 characters'
def test_valid_project_id_returns_200_code(dynamodb_table):
    response, body = call('pr-3-tier-arch')

    assert response['statusCode'] == 200

# test to ensure an invalid page name returns a 400 status code and doesn't add anything to the database
def test_invalid_page_returns_400(dynamodb_table):
    response, _ = call('not-a-real-page')

    assert response['statusCode'] == 400

    # check nothing was written to the table
    assert 'Item' not in dynamodb_table.get_item(Key={'id': 'not-a-real-page'})
    assert 'Item' not in dynamodb_table.get_item(Key={'id': 'total'})

# test for missing query parameters returns 400
def test_missing_query_params_returns_400(dynamodb_table):
    response, _ = call() # no queryStringParameters at all

    assert response['statusCode'] == 400

# project ID pattern, tested directly, no AWS involved at all
def test_project_id_pattern_accepts_two_digits():
    assert PROJECT_ID_VALID_PATTERN.match('pr-3-tier-arch') is not None # this pattern is valid

def test_project_id_pattern_rejects_other_patterns():
    assert PROJECT_ID_VALID_PATTERN.match('xpr-3-tier-arch') is None # this pattern is NOT valid
    assert PROJECT_ID_VALID_PATTERN.match('pr-') is None # this pattern is NOT valid
    assert PROJECT_ID_VALID_PATTERN.match('pr-3-tier arch') is None # this pattern is NOT valid
    assert PROJECT_ID_VALID_PATTERN.match('pr-three-tier-architecture') is None # this pattern is NOT valid

# COUNTER TESTS
# when a page is viewed there should be increments to two different counters, an individual page counter, and a total site-wide counter

# this test is to test if a visit to a valid page increments both counters by 1
def test_valid_page_increments_counter(dynamodb_table):
    response, body = call('home')

    assert body['pageViews'] == 1
    assert body['totalViews'] == 1

# this test is to ensure repeated calls to a page increment both counters repeatedly
def test_repeated_calls_accumulate_on_same_page(dynamodb_table):
    call('about')
    call('about')
    response, body = call('about')

    assert body['pageViews'] == 3
    assert body['totalViews'] == 3

# this test is to ensure total increments as expected based on individual page increments
def test_total_increments_independently_across_different_pages(dynamodb_table):
    _, home_body = call('home')
    _, about_body = call('about')

    # each page's own count only reflects its own visits
    assert home_body['pageViews'] == 1
    assert about_body['pageViews'] == 1

    # but the shared total reflects both
    assert about_body['totalViews'] == 2

# this test ensures pages don't share the same individual page counter (they only share a total counter)
def test_different_pages_do_not_share_a_counter(dynamodb_table):
    call('home')
    call('home')
    response, about_body = call('about')

    # 'about' has only been visited once, regardless of how many times 'home' was visited
    assert about_body['pageViews'] == 1
    assert about_body['totalViews'] == 3