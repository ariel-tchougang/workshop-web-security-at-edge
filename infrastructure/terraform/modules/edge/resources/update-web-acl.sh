#!/bin/bash

# Check if the input parameter is provided
if [ -z "$1" ]; then
    echo "Error: Missing input parameter. Expected format: web-acl-name|web-acl-id|web-acl-metric-name|aws-profile"
    exit 1
fi

# Split the input parameter using '|' as the separator
IFS='|' read -r WebAclName WebAclId WebAclMetricName AwsProfile <<< "$1"

# Validate that all necessary parts are provided
if [ -z "$WebAclName" ] || [ -z "$WebAclId" ] || [ -z "$WebAclMetricName" ] || [ -z "$AwsProfile" ]; then
    echo "Error: Missing parameters after splitting. Ensure the input format is correct."
    exit 1
fi

echo "The Web ACL Name is: $WebAclName"
echo "The Web ACL Id is: $WebAclId"
echo "The Web ACL Metric Name is: $WebAclMetricName"
echo "The AWS profile is: $AwsProfile"

# Retrieve the lock token
LockToken=$(aws wafv2 get-web-acl --name "$WebAclName" --scope CLOUDFRONT --region us-east-1 --id "$WebAclId" --query LockToken --output text --profile "$AwsProfile")

echo "The Lock token is: $LockToken"

# Check if lock token retrieval was successful
if [ -z "$LockToken" ]; then
    echo "Error: Failed to retrieve the lock token."
    exit 1
fi

# Create the JSON string for --visibility-config
visibilityConfig='{"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "'"$WebAclMetricName"'"}'

# Update the Web ACL
aws wafv2 update-web-acl --name "$WebAclName" --scope CLOUDFRONT --region us-east-1 --id "$WebAclId" --lock-token "$LockToken" --default-action '{"Allow": {}}' --visibility-config "$visibilityConfig" --rules '[]' --profile "$AwsProfile"

# Check if the update was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to update the Web ACL."
    exit 1
fi
