# workshop-web-security-at-edge
Web security at edge demonstration

## Context

In this demo we will show how we can use AWS Web Application Firewall (WAF) and CloudFront to protect a web site hosted:
* In an S3 bucket

![Alt text](/images/Website-S3-Architecture.png?raw=true "Website-S3-Architecture")

* In an EC2 instance behind an Internet-facing Application Load Balancer

![Alt text](/images/Website-ALB-Architecture.png?raw=true "Website-ALB-Architecture")

To perform steps required for this demo, you'll need to:
- Have access to an AWS account
- Enough permissions to create or modify
	- A CloudFront distribution
	- An AWS WAF Web ACL
	- An S3 bucket
	- A VPC with at least 1 public subnet and 1 private subnet
	- Security groups
	- An SSH key pair
	- An EC2 instance connect endpoint
	- An S3 Gateway endpoint
	- A NAT Gateway
	- An elastic IP
	- An EC2 instance
	- A target group
	- An Internet-facing Application Load Balancer
	- An IAM role for EC2 with s3 sync permissions
- Access to AWS CloudShell or to a Linux server (EC2, Cloud9, etc..) with Internet access (to perform curl requests when testing rate limiting later on in the lab)

## I - Initialize infrastructure

Check the subfolder "infrastructure" to retrieve the CloudFormation template to start this workshop:

- infrastructure/
	- web-security-at-edge-demo-us-east-1.yaml
	- web-security-at-edge-demo.yaml

### 1 - Install workshop CloudFormation resources

If you're performing the demo in us-east-1 region run "web-security-at-edge-demo-us-east-1.yaml", you'll get the complete setup.

If you're performing the demo in other regions run "web-security-at-edge-demo.yaml". You'll have to manually create an empty global WebACL afterwards.

So go to CloudFormation
- Click on "Create stack"
- Prepare template: Choose an existing template
- Template source: Upload a template file
- Upload your file, then click on "Next"
- Stack-name: workshop-edge-security
click on "Next"
click on "Next"
Scroll down and click on the checkbox "I acknowledge that AWS CloudFormation might create IAM resources."
click on "Submit"

![Alt text](/images/CloudFormation-Create-Stack.png?raw=true "CloudFormation-Create-Stack")

It should take around 10 minutes to provision all resources.

If you used web-security-at-edge-demo.yaml, go to step 2. Otherwise go directly to part II.

### 2 - Create an empty Global WebACL (Optional)

Go to WAF (Web Application Firewall console)
Click on "Create web ACL"
Web ACL details:
- Resource type: choose Amazon CloudFront distributions
- Name: WorkshopWebACL
- Click on "Next"
- Click on "Next"
- Click on "Next"
- Click on "Next"
- Click on "Create web ACL"

![Alt text](/images/WAF-Create-WebACL.png?raw=true "WAF-Create-WebACL")

## II - Test the application

Open your AWS Console
- Go to CloudFormation
- Choose your stack
- Go to Output tab

![Alt text](/images/23-CloudFormation-Outputs-Tab.png?raw=true "CloudFormation-Outputs-Tab")

### 1 -  S3 static website

- Copy the link for WorkshopS3WebsiteURL
- Paste it in a browser (use private mode)

### 2 - ALB static website

- Copy the link for WorkshopLoadBalancerDNSName
- Paste it in a browser (use private mode)

![Alt text](/images/17-S3-Static-Website-Hosting.png?raw=true "Web default page")

## III - Distribute website content through CloudFront

### 1 - Create a CloudFront distribution with our S3 bucket as origin

Go to CloudFront console
Click on "Create distribution"

Origin:
- Origin domain: choose your S3 bucket "Website" endpoint
- Name: s3-web-security-demo
- Origin access: Public

- Add custom header
	+ Header name: Referer
	+ Value: CLOUDFRONT-DISTRIBUTION-SECRET-VALUE

![Alt text](/images/CloudFront-Create-Distribution.png?raw=true "CloudFront-Create-Distribution")

Default cache behavior:
- Viewer protocol policy: Redirect HTTP to HTTPS
- Allowed HTTP methods: GET, HEAD
- Cache key and origin requests: Cache policy and origin request policy (recommended)
- Cache policy: CachingOptimized (Recommended for S3)

Web Application Firewall (WAF): Enable security protections
- Choose Use existing WAF configuration
- Select WorkshopWebACL

Settings:
- Default root object: index.html

Scroll down, and click on "Create distribution"

While the distribution is being deployed, copy the distribution domain name, and paste in a notepad to be used later.

### 2 - Create a CloudFront distribution with our WorkshopLoadBalancer as origin

Go back to CloudFront console
Click on "Create distribution"

Origin:
- Origin domain: choose your WorkshopLoadBalancer DNS name
- Protocol: HTTP only
- Name: web-security-demo-alb

- Add custom header
	+ Header name: x-cloudfront-secret
	+ Value: CLOUDFRONT-DISTRIBUTION-SECRET-VALUE

![Alt text](/images/CloudFront-Create-Distribution-ALB.png?raw=true "CloudFront-Create-Distribution")

Default cache behavior:
- Viewer protocol policy: Redirect HTTP to HTTPS
- Allowed HTTP methods: GET, HEAD
- Cache key and origin requests: Cache policy and origin request policy (recommended)
- Cache policy: UseoriginCacheControlHeaders (Recommended for Elastic Load Balancing)
- Origin request policy: All viewers (Recommended for Elastic Load Balancing)

Web Application Firewall (WAF): Enable security protections
- Choose Use existing WAF configuration
- Select WorkshopWebACL

Settings:
- Default root object: index.html

Scroll down, and click on "Create distribution"

While the distribution is being deployed, copy the distribution domain name, and paste in a notepad to be used later.

### 3 - Test access from CloudFront (Assuming both distributions are deployed)

Paste S3 distribution domain name in a browser (private mode) and verify you have access the website content.

Paste ALB distribution domain name in a browser (private mode) and verify you have access the website content.

![Alt text](/images/17-S3-Static-Website-Hosting.png?raw=true "Web default page")


## IV - Block direct access from S3 website endpoint and WorkshopLoadBalancer DNS name

### 1 - Block direct access from S3 website

- Go to S3 Console, and choose your bucket
- Go to tab "Permissions" and edit the bucket policy (replace the placeholders with appropriate data) if not done automatically by CloudFront

```JSON
{
  "Version":"2012-10-17",
  "Id":"HTTP GET requests from specific referer",
  "Statement":[
    {
      "Sid":"AllowGetFromSpecificReferer",
      "Effect":"Allow",
      "Principal":"*",
      "Action":["s3:GetObject","s3:GetObjectVersion"],
      "Resource":"arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*",
      "Condition":{
        "StringLike":{"aws:Referer":["CLOUDFRONT-DISTRIBUTION-SECRET-VALUE"]}
      }
    }
  ]
}
```

- Copy the provided S3 website URL and paste it in a browser (use private mode)
- Assert you get a 403 Forbidden - Access Denied message

![Alt text](/images/S3-Website-Access-Denied.png?raw=true "S3-Website-Access-Denied")

- Paste S3 distribution domain name in a browser (private mode)
Assert you have access the website content.

### 2 - Block direct access from WorkshopLoadBalancer DNS name

Go to EC2 console
- On the left menu, under "Load Balancing", choose "Load balancers"
- Click on WorkshopLoadBalancer
- Go to tab Listeners and rules
- Click on text "HTTP:80"
- On tab "Listener rules" click on "Default", then choose Actions/Edit rule

Listener details:
- Routing actions: Return fixed response
- Response code: 403
- content type: text/html
- Response body: paste the following

```html
<html>
<head><title>403 Forbidden</title></head>
<body>
	<h1>403 Forbidden</h1>
	<ul>
		<li>Code: AccessDenied</li>
		<li>Message: Access Denied</li>
	</ul>
	<hr/>
</body>
</html>
```

Click on "Save changes"

Click on Add rule

Name and tags: AllowAccessFromCloudFront
Click on Add condition
- Rule condition types: HTTP header
- HTTP header name: x-cloudfront-secret
- HTTP header value: CLOUDFRONT-DISTRIBUTION-SECRET-VALUE

Click on "confirm"

Click on "Next"
Actions:
- Routing actions: Forward to target groups
- Target group: WorkshopTargetGroup

Click on "Next"

Priority: 1

Click on "Next"
Click on "Create"

Go back to WorkshopLoadBalancer

Copy the provided DNS name and paste it in a browser (use private mode)

Assert you get a 403 Forbidden - Access Denied message

![Alt text](/images/ALB-Website-Access-Denied.png?raw=true "ALB-Website-Access-Denied")

Paste ALB distribution domain name in a browser (private mode)

Assert you have access the website content.
