import flask
from flask import request
import os
from bot import ObjectDetectionBot
import boto3
from botocore.exceptions import ClientError
from loguru import logger
import json


app = flask.Flask(__name__)


# TODO load TELEGRAM_TOKEN value from Secret Manager
region = os.environ['REGION']
def get_secret():

    secret_name = "ghazal1_TELEGRAM_TOKEN"


    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']
    secret_dict = json.loads(secret)
    telegram_token = secret_dict['TELEGRAM_TOKEN']
    return telegram_token


TELEGRAM_APP_URL = os.environ['TELEGRAM_APP_URL']
TELEGRAM_TOKEN = get_secret()






@app.route('/', methods=['GET'])
def index():
    return 'Ok'


@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'

dynamodb = boto3.resource('dynamodb', region_name=region)
dynamodb_table_name = os.environ['DYNAMODB_TABLE_NAME']

@app.route(f'/results', methods=['POST'])
def results():
    prediction_id = request.args.get('prediction_id')
    logger.error(f'h:{prediction_id}')

    # TODO use the prediction_id to retrieve results from DynamoDB and send to the end-user
    try:
        table = dynamodb.Table(dynamodb_table_name)
        response = table.get_item(Key={'prediction_id': prediction_id})
        if 'Item' in response:
            item = response['Item']
            chat_id = item['chat_id']
            labels = item['labels']
            text_results = "Prediction Results:\n"
            detected_items = [label['class'] for label in labels]
            text_results += "\n".join(detected_items)
            bot.send_text(chat_id, text_results)
            return 'Ok'
        else:
            return 'Prediction ID not found', 404
    except Exception as e:
        return f'Error retrieving results from DynamoDB: {e}', 500


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = ObjectDetectionBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)
    ssl_context = ('my_cert.pem', 'my_key.key')
    app.run(host='0.0.0.0', port=8443, ssl_context=ssl_context)
