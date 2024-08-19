#!/bin/bash -xe
exec > /var/log/user-data.log 2>&1
set -o xtrace

# Install required packages
echo "Install httpd"
yum update -y
yum install -y httpd unzip wget

# Displaying Terraform-substituted variables
echo "GITHUB_SOURCE_URL: ${GITHUB_SOURCE_URL}"
echo "WORKSHOP_S3_BUCKET_NAME: ${WORKSHOP_S3_BUCKET_NAME}"
echo "TARGET_GROUP_ARN: ${TARGET_GROUP_ARN}"

# Fetch the project sources from GitHub
wget -O /tmp/temp.zip "${GITHUB_SOURCE_URL}"

# Unzip the content of temp.zip into /tmp/git-source
unzip /tmp/temp.zip -d /tmp/git-source

# Start and enable the Apache service
echo "Start and enable the Apache service"
systemctl start httpd
systemctl enable httpd
groupadd www
usermod -a -G www ec2-user
chown -R root:www /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} +
find /var/www -type f -exec chmod 0664 {} +

# Move the contents of the extracted directory to /var/www/html
EXTRACTED_DIR=$(find /tmp/git-source -mindepth 1 -maxdepth 1 -type d)
mv $EXTRACTED_DIR/web/* /var/www/html/
cd /var/www/html/

# Upload /var/www/html content to WorkshopS3Bucket
aws s3 sync /var/www/html s3://${WORKSHOP_S3_BUCKET_NAME} --delete

# Clean up
rm -rf /tmp/temp.zip /tmp/git-source

# Fetch instance ID using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

# Register the instance with the target group
aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=$INSTANCE_ID
