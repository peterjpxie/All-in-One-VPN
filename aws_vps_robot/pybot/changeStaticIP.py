import boto3

client = boto3.client('lightsail')
response = client.get_static_ips()
print(response)
