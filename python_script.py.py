import boto3
import time
import paramiko

ec2_client = boto3.client('ec2')
cloudwatch_client = boto3.client('cloudwatch')

# Create an EC2 instance
response = ec2_client.run_instances(
    ImageId='ami-0aa2b7722dc1b5612', #write the ami-id for your instance
    InstanceType='t2.micro', #write the instance type
    MinCount=1, #min number of instance
    MaxCount=1 #max number of instance
)

instance_id = response['Instances'][0]['InstanceId']
print(f"EC2 instance created..... Instance ID: {instance_id}")

# Wait for the instance to be running
ec2_client.get_waiter('instance_running').wait(InstanceIds=[instance_id])

# Create a CloudWatch alarm
alarm_name = 'HighCPUAlarm'
cloudwatch_client.put_metric_alarm(
    AlarmName=alarm_name,
    ComparisonOperator='GreaterThanOrEqualToThreshold',
    EvaluationPeriods=5,
    MetricName='CPUUtilization',
    Namespace='AWS/EC2',
    Period=60,
    Statistic='Average',
    Threshold=80.0,
    ActionsEnabled=True,
    AlarmDescription='Alarm triggered when CPU exceeds 80% for five consecutive minutes',
    Dimensions=[
        {
            'Name': 'InstanceId',
            'Value': instance_id
        },
    ],
    AlarmActions=[
        'arn:aws:sns:us-east-1:123456789012:MyTopic'  # Replace with your SNS topic ARN
    ]
)

print(f"CloudWatch alarm '{alarm_name}' created.....")

# Wait for the alarm to be active
cloudwatch_client.get_waiter('alarm_exists').wait(AlarmNames=[alarm_name])
print(f"CloudWatch alarm '{alarm_name}' is active.")

# Additional code for hosting the website on the EC2 instance goes here...

# SSH connection details
hostname = 'PUBLIC-EC2-INSTANCE-ID' #EC2 instance public IP address
username = 'EC2-INSTANCE-USERNAME' #give EC2 username
private_key_path = 'PRIVATE-KEY-FILE-PATH' #give path to your private key
website_files_path = 'WEBSITE-FILES-DIRECTORY-PATH'
remote_website_path = '/var/www/html'

# Create an SSH client
ssh_client = paramiko.SSHClient()
ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    # Connect to the EC2 instance
    ssh_client.connect(hostname, username=username, key_filename=private_key_path)
    print('Connected to EC2 instance via SSH.....')

    # Create a SFTP client
    sftp_client = ssh_client.open_sftp()
    print('SFTP session opened.....')

    # Copy website files to the EC2 instance
    sftp_client.put(website_files_path, f"{remote_website_path}/", recursive=True)
    print('Website files copied to EC2 instance.....')

finally:
    # Close the SFTP and SSH connections
    if sftp_client:
        sftp_client.close()
        print('SFTP session closed.....')
    if ssh_client:
        ssh_client.close()
        print('SSH connection closed.....')

