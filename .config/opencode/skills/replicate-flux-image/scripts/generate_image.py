#!/usr/bin/env python3
import argparse
import os
import sys
import time
import json
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path


def parse_arguments():
    parser = argparse.ArgumentParser(description='Generate image using Replicate Flux API')
    parser.add_argument('prompt', help='Text prompt for image generation')
    parser.add_argument('--aspect_ratio', choices=['1:1','16:9','3:2','2:3','4:5','5:4','9:16','3:4','4:3'], 
                       default='1:1', help='Aspect ratio of the generated image')
    parser.add_argument('--output', default='./generated-image.webp', 
                       help='Output file path for the generated image')
    parser.add_argument('--timeout', type=int, default=300,
                       help='Timeout in seconds for image generation (minimum 10)')
    return parser.parse_args()


def get_api_token():
    token = os.environ.get('REPLICATE_API_TOKEN')
    if not token:
        print('Error: REPLICATE_API_TOKEN environment variable is required', file=sys.stderr)
        sys.exit(1)
    return token


def create_request_headers(token):
    return {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }


def start_prediction(headers, prompt, aspect_ratio):
    url = 'https://api.replicate.com/v1/models/black-forest-labs/flux-2-max/predictions'
    
    payload = {
        'input': {
            'prompt': prompt,
            'aspect_ratio': aspect_ratio,
            'resolution': '4 MP',
            'output_format': 'webp',
            'output_quality': 100,
            'safety_tolerance': 5
        }
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        handle_http_error(e)
        sys.exit(1)


def get_prediction_status(headers, prediction_id):
    url = f'https://api.replicate.com/v1/predictions/{prediction_id}'
    req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        handle_http_error(e)
        sys.exit(1)


def handle_http_error(error):
    if error.code == 401:
        print('Error: Invalid Replicate API token. Please check your REPLICATE_API_TOKEN.', file=sys.stderr)
    elif error.code == 402:
        print('Error: Insufficient credits or billing issue with your Replicate account.', file=sys.stderr)
    elif error.code == 422:
        try:
            error_data = json.loads(error.read().decode('utf-8'))
            detail = error_data.get('detail', 'Validation error')
            print(f'Error: Invalid request - {detail}', file=sys.stderr)
        except:
            print('Error: Invalid request parameters', file=sys.stderr)
    elif error.code == 429:
        print('Error: Rate limit exceeded. Please try again later.', file=sys.stderr)
    else:
        print(f'Error: HTTP {error.code} - {error.reason}', file=sys.stderr)


def poll_prediction(headers, prediction_id, timeout):
    start_time = time.monotonic()
    
    while time.monotonic() - start_time < timeout:
        prediction = get_prediction_status(headers, prediction_id)
        status = prediction.get('status')
        
        if status in ['succeeded', 'failed', 'canceled']:
            return prediction
        
        time.sleep(2)
    
    print(f'Error: Image generation timed out after {timeout} seconds', file=sys.stderr)
    sys.exit(1)


def download_image(headers, image_url, output_path):
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    req = urllib.request.Request(image_url, headers=headers)
    
    try:
        with urllib.request.urlopen(req) as response:
            with open(output_path, 'wb') as f:
                f.write(response.read())
        
        file_size = output_path.stat().st_size
        return output_path.absolute(), file_size
    except urllib.error.HTTPError as e:
        print(f'Error downloading image: HTTP {e.code} - {e.reason}', file=sys.stderr)
        sys.exit(1)


def main():
    args = parse_arguments()
    
    if not args.prompt.strip():
        print('Error: Prompt cannot be empty or whitespace', file=sys.stderr)
        sys.exit(1)
    
    if args.timeout < 10:
        print('Error: Timeout must be at least 10 seconds', file=sys.stderr)
        sys.exit(1)
    
    token = get_api_token()
    headers = create_request_headers(token)
    
    prediction = start_prediction(headers, args.prompt, args.aspect_ratio)
    prediction_id = prediction.get('id')
    
    if not prediction_id:
        print('Error: Invalid response from Replicate API', file=sys.stderr)
        sys.exit(1)
    
    final_prediction = poll_prediction(headers, prediction_id, args.timeout)
    
    if final_prediction.get('status') != 'succeeded':
        error_detail = final_prediction.get('error', 'Unknown error')
        print(f'Error: Image generation failed - {error_detail}', file=sys.stderr)
        sys.exit(1)
    
    output = final_prediction.get('output')
    
    if isinstance(output, str):
        image_url = output
    elif isinstance(output, list) and output:
        image_url = output[0]
    else:
        print('Error: No image URL in response', file=sys.stderr)
        sys.exit(1)
    abs_path, file_size = download_image(headers, image_url, args.output)
    
    print(f'{abs_path}')
    print(f'{file_size}')


if __name__ == '__main__':
    main()