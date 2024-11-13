import json
import base64
import boto3
import random
import os

def handler(event, context):
    # Set up AWS clients for Bedrock and S3
    bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")
    s3_client = boto3.client("s3", region_name="eu-west-1")

    # Define the model ID and S3 bucket name, and candidate number
    model_id = "amazon.titan-image-generator-v1"
    bucket_name = os.environ.get("S3_BUCKET_NAME")
    candidate_number = os.environ.get("CANDIDATE_NUMBER")
    
    #This is a test to test my workflow!
    
    # Prompt json body.
    try:
        request_body = json.loads(event["body"])
        prompt = request_body["prompt"]
    except (KeyError, json.JSONDecodeError) as e:
        return {"statusCode": 400, "body": json.dumps({"error": "Invalid request format"})}


    seed = random.randint(0, 2147483647)
    s3_image_path = f"{candidate_number}/generated_images/titan_{seed}.png"

    native_request = {
        "taskType": "TEXT_IMAGE",
        "textToImageParams": {"text": prompt},
        "imageGenerationConfig": {
            "numberOfImages": 1,
            "quality": "standard",
            "cfgScale": 8.0,
            "height": 1024,
            "width": 1024,
            "seed": seed,
        }
    }


    response = bedrock_client.invoke_model(modelId=model_id, body=json.dumps(native_request))
    model_response = json.loads(response["body"].read())

    
    # Extract and decode the Base64 image data
    base64_image_data = model_response["images"][0]
    image_data = base64.b64decode(base64_image_data)

    # Upload the decoded image data to S3
    s3_client.put_object(Bucket=bucket_name, Key=s3_image_path, Body=image_data)

    # 
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Image generated successfully",
            "image_uri": f"s3://{bucket_name}/{s3_image_path}"
        })
    }
