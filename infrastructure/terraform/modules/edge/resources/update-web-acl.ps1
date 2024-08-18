param (
    [string]$InputParameter
)

# Split the input parameter using '|' as the separator
$parts = $InputParameter -split '\|'

# Validate the number of parts
if ($parts.Length -ne 4) {
    Write-Error "Error: Invalid input. Expected format: web-acl-name|web-acl-id|web-acl-metric-name|aws-profile"
    exit 1
}

# Assign the parts to variables
$WebAclName = $parts[0]
$WebAclId = $parts[1]
$WebAclMetricName = $parts[2]
$AwsProfile = $parts[3]

# Validate that all necessary parts are provided
if (-not $WebAclName -or -not $WebAclId -or -not $WebAclMetricName -or -not $AwsProfile) {
    Write-Error "Error: Missing parameters after splitting. Ensure the input format is correct."
    exit 1
}

Write-Output "The Web ACL Name is: $WebAclName"
Write-Output "The Web ACL Id is: $WebAclId"
Write-Output "The Web ACL Metric Name is: $WebAclMetricName"
Write-Output "The AWS profile is: $AwsProfile" 

# Retrieve the lock token
$LockToken = aws wafv2 get-web-acl --name $WebAclName --scope CLOUDFRONT --region us-east-1 --id $WebAclId --query LockToken --output text --profile $AwsProfile

Write-Output "The Lock token is: $LockToken"

# Check if lock token retrieval was successful
if (-not $LockToken) {
    Write-Error "Error: Failed to retrieve the lock token."
    exit 1
}

$visibilityConfig = '{\"SampledRequestsEnabled\":true,\"CloudWatchMetricsEnabled\":true,\"MetricName\":\"' + $WebAclMetricName + '\"}'

Write-Output "The visibility configuration is: $visibilityConfig"

# Update the Web ACL
aws wafv2 update-web-acl --name $WebAclName --scope CLOUDFRONT --region us-east-1 --id $WebAclId --lock-token $LockToken --default-action '{\"Allow\": {}}' --visibility-config $visibilityConfig --rules '[]' --profile $AwsProfile;

# Check if the update was successful
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: Failed to update the Web ACL."
    exit 1
}

