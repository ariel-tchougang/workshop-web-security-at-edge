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

### 1 - With CloudFormation

Check the subfolder "infrastructure/cloudformation" to retrieve the CloudFormation template to start this workshop:

- infrastructure/cloudformation/
	- web-security-at-edge-demo-us-east-1.yaml
	- web-security-at-edge-demo.yaml

#### a - Install workshop CloudFormation resources

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

#### b - Create an empty Global WebACL (Optional)

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

### 2 - With Terraform

Check the subfolder "infrastructure/cloudformation"
- It's assumed Terraform is installed on you plaform
- These scripts were written using Terraform 1.9.3

#### a - Initialize Terraform

```HCL
terraform init
```

#### b - Execution variables
- region: AWS deployment region
- vpc_cidr: Workshop VPC CIDR
- aws_local_profile: aws profile with permissions necessary for this workshop. You can set it in your ~/.aws/config & ~/.aws/credentials files.
- exec_platform: operating system from which you'll be running the workshop. Values are:
    - linux
    - windows
    - macos

#### - c Install workshop resources

```HCL
terraform apply -auto-approve -var="region=YOUR_AWS_REGION" -var="vpc_cidr=YOUR_VPC_CIDR" -var="aws_local_profile=YOUR_LOCAL_AWS_PROFILE" -var="exec_platform=YOUR_OPERATING_SYSTEM"
```

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

![Alt text](/images/block-public-access.webp?raw=true "block-public-access")

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
- Assert you have access the website content.

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

## V - Now let's take a look at some vulnerabilities

### 1 - Cross-Site Scripting (XSS)

![Alt text](/images/attacks-xss-02.webp?raw=true "attacks-xss")

#### Definition

Cross-Site Scripting (XSS) is a type of security vulnerability typically found in web applications. 

It allows attackers to inject malicious scripts into content from otherwise trusted websites.

These scripts can then execute in the user's browser, potentially leading to the compromise of user data, session hijacking, and more.

#### Demo  <a name="demo-xss"></a>

- Go to your CloudFront S3 distribution (or ALB)
- Copy your distribution domain name
- Paste it in a browser (private mode)
- Choose XSS Attacks
- Type: 
```
<script>alert("XSS Attack Demo!!")</script>
```
- Click on Search button

Assert the code is executed (a modal window should pop up)

#### Mitigation strategies

To prevent XSS attacks, you should:
- Sanitize Input: Remove or encode potentially dangerous characters from user input.
- Use Content Security Policy (CSP): Define approved sources for content that browsers should enforce.
- Validate and Encode Output: Ensure that any user input included in the HTML output is properly encoded.

#### Implement a solution with AWS WAF WebACL

##### Using AWS managed rules / Core rule set

It Contains rules that are generally applicable to web applications, providing protection against exploitation of a wide range of vulnerabilities, such as XSS.

Go to WAF (Web Application Firewall console)
- Click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab Rules
- Click on "Add rules / Add managed rule groups"
    - Expand "AWS managed rule groups"
    - Scroll down to "Free rule groups"
    - Enable "Core rule set". 
    - Scroll down and click on "Add rules"
    - Scroll down and click on "Next"
    - Click on "Next"
    - Click on "Next"
    - Review and click on "Save"

##### Using custom rules

Go to WAF (Web Application Firewall console)
On the left menu click on Rule groups
- Click on "Create Rule group"
- Name Workshop-BlockXSS-Group
- Region: Global (CloudFront)
- Click on "Add rule"
    - Name: BlockXSSOnHeaders
    - Type: Regular rule
    - If a request: matches the statement
    - Inspect: All headers
    - Headers match scope: Values
    - Content to inspect: All headers
    - Match type: Contain XSS injection attacks
    - Text transformation: None
    - Oversize handling: Match - Treat web request as matching the rule statement
    - Action: Block
    - Click on "Add rule"
- Click on "Add rule"
    - Name: BlockXSSOnQueryParams
    - Type: Regular rule
    - If a request: matches the statement
    - Inspect: All query parameters
    - Match type: Contain XSS injection attacks
    - Text transformation: URL decode
    - Action: Block
    - Click on "Add rule"
- Click on "Next"
- Click on "Next"
- Click on "Create Rule group"

On the left menu click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab "Rules"
- Click on "Add my own rules and rule groups"
    - Rule type: Choose Rule group
    - Name: Workshop-BlockXSS-Ruleset
    - Rule group: Workshop-BlockXSS-Group
    - Click on "Add rule"
    - Choose Workshop-BlockXSS-Ruleset
    - Click on "Move up"
    - Click on "Save"

#### Test the solution

- Replay the steps from the [Demo](#demo-xss) paragraph

Assert the XSS attempts are intercepted and blocked by CloudFront through WAF

### 2 - SQL injection

![Alt text](/images/attacks-sqli.webp?raw=true "attacks-sqli")

#### Definition

SQL Injection is a type of security vulnerability that occurs when an attacker can manipulate an SQL query by injecting malicious SQL code into input fields.

This can result in unauthorized access to the database, allowing attackers to retrieve, modify, or delete data. 

SQL Injection exploits the improper handling of input data and insufficient input validation.

#### Demo  <a name="demo-sqli"></a>

Go back to your web app home page
- Choose SQL Injection Attacks
- Type: 
```
Username: admin
Password: adminpass
```
- Click on Login button

Assert access is granted

- Type: 
```
Username: admin
Password: badpassword
```
- Click on Login button

Assert access is denied
- Type: 
```
Username: admin
Password: anything' OR '1=1
```
- Click on Login button

Assert access is granted
- Type: 
```
Username: admin' --
Password: anything
```
- Click on Login button

Assert access is granted

#### Mitigations strategies

- Use Prepared Statements: Ensure queries use parameterized inputs.
- Sanitize Input: Validate and sanitize all user inputs.
- Least Privilege: Use database accounts with the least privilege necessary.
- Stored Procedures: Use stored procedures to abstract and encapsulate database access.
- Error Handling: Avoid displaying detailed error messages that reveal SQL structure.

#### Implement a solution with AWS WAF WebACL

##### Using AWS managed rules / SQL database
Go to WAF (Web Application Firewall console)
- Click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab Rules
- Click on "Add rules / Add managed rule groups"
    - Expand "AWS managed rule groups"
    - Scroll down to "Free rule groups"
    - Enable "SQL database". 
    - Scroll down and click on "Add rules"
    - Scroll down and click on "Next"
    - Click on "Next"
    - Click on "Next"
    - Review and click on "Save"

##### Using custom rules

On the left menu click on Rule groups
- Click on "Create Rule group"
- Name Workshop-BlockSQLI-Group
- Region: Global (CloudFront)
- Click on "Add rule"
    - Name: BlockSQLIOnHeaders
    - Type: Regular rule
    - If a request: matches at least one of the statement (OR)
    - Statement 1
        - Inspect: All headers
        - Headers match scope: Values
        - Content to inspect: All headers
        - Match type: Contain SQL injection attacks
        - Text transformation: None
        - Oversize handling: Match - Treat web request as matching the rule statement
    - Statement 2
        - Inspect: All headers
        - Headers match scope: Values
        - Content to inspect: All headers
        - Match type: Contains string
        - String to match: --
        - Text transformation: None
        - Oversize handling: Match - Treat web request as matching the rule statement
    - Action: Block
    - Click on "Add rule"
- Click on "Add rule"
    - Name: BlockSQLIOnQueryParams
    - Type: Regular rule
    - If a request: matches at least one of the statement (OR)
    - Statement 1
        - Inspect: All query parameters
        - Match type: Contain SQL injection attacks
        - Text transformation: URL decode
    - Statement 2
        - Inspect: All query parameters
        - Match type: Contains string
        - String to match: --
        - Text transformation: URL decode
    - Action: Block
    - Click on "Add rule"
- Click on "Next"
- Click on "Next"
- Click on "Create Rule group"

On the left menu click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab "Rules"
- Click on "Add my own rules and rule groups"
    - Rule type: Choose Rule group
    - Name: Workshop-BlockSQLI-Ruleset
    - Rule group: Workshop-BlockSQLI-Group
    - Click on "Add rule"
    - Choose Workshop-BlockSQLI-Ruleset
    - Click on "Move up" until it's on top
    - Click on "Save"

#### Test the solution

- Replay the steps from the [Demo](#demo-sqli) paragraph

Assert the SQL injection attempts are intercepted and blocked by CloudFront through WAF

### 3 - Header Injection Attack

![Alt text](/images/attacks-header-injection.webp?raw=true "attacks-header-injection")

#### Definition

This occurs when an attacker includes malicious data in HTTP headers, aiming to manipulate the server's response headers. 

If the server does not properly handle or sanitize headers, this can lead to various exploits like HTTP response splitting, cache poisoning, or cross-site scripting (XSS).

The potential consequences of header injection can range from:
- disrupting legitimate user sessions
- hijacking user sessions, 
- redirecting users to malicious sites, 
- or injecting executable scripts.

#### Demo <a name="demo-header-attacks"></a>

XSS and SQL injection attacks through headers are blocked by the rules added previously.

Go back to your web app home page
- Choose Header Attacks
- Type: 
```
Header Name: x-htmli-attack
Header Value: <h1>Change text size!</h1>
```
- Click on Send button

Assert Header Value text is displayed in html h1 format: <h1> Change text size!</h1>

#### Mitigations strategies

- Sanitize and Validate Headers: Ensure that any custom headers received are validated and sanitized to remove any malicious content.
- Input Validation: Apply strict validation rules for headers, only allowing expected values and formats.
- Content Security Policy (CSP): Implement CSP to mitigate potential XSS attacks stemming from header manipulation.

#### Implement a solution with AWS WAF WebACL

##### Using custom rules

Return to WAF (Web Application Firewall console)

On the left menu click on Rule groups
- Click on "Create Rule group"
- Name Workshop-BlockCustomHeaders-Group
- Region: Global (CloudFront)
- Click on "Add rule"
    - Name: BlockCustomHeaders
    - Type: Regular rule
    - If a request: matches the statement
    - Inspect: All headers
    - Headers match scope: Keys
    - Content to inspect: All headers
    - Match type: Contains string
    - String to match: attack
    - Text transformation: None
    - Oversize handling: Match - Treat web request as matching the rule statement
    - Action: Block
    - Click on "Add rule"
- Click on "Next"
- Click on "Next"
- Click on "Create Rule group"

On the left menu click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab "Rules"
- Click on "Add my own rules and rule groups"
    - Rule type: Choose Rule group
    - Name: Workshop-BlockCustomHeaders-Ruleset
    - Rule group: Workshop-BlockCustomHeaders-Group
    - Click on "Add rule"
    - Choose Workshop-BlockCustomHeaders-Ruleset
    - Click on "Move up" until it reaches the top
    - Click on "Save"

#### Test the solution

- Replay the steps from the [Demo](#demo-header-attacks) paragraph

Assert custom headers containing the word "attack" are intercepted and blocked by CloudFront through WAF.

### 4 - HTML code injection

![Alt text](/images/attacks-htmli.webp?raw=true "attacks-htmli")

#### Definition

HTML code injection occurs when an attacker is able to insert malicious HTML content into a web page, which can be executed by the browser of anyone viewing the page.

This type of vulnerability is often the result of failing to properly sanitize user input. 

HTML injection can lead to various attacks, including:
- cross-site scripting (XSS), 
- manipulation of page content, 
- and more.

#### Demo <a name="demo-htmli"></a>

XSS and SQL injection attacks through headers are blocked by the rules added previously.

Go back to your web app home page
- Choose HTML Injection Attacks
- Type in "Search" field: 
```
<html><body><h1>HTML code injection!</h1></body></html>
```
- Click on Search button

Assert the following html content is displayed: displayed in h1 format: <h1> HTML code injection!</h1>

#### Mitigations strategies

- Sanitize Input: Use functions like htmlspecialchars to convert special characters into their HTML-safe equivalents.
- Validate Input: Ensure that user input conforms to expected formats and lengths.
- Output Encoding: Always encode user input before rendering it in the HTML content.
- Content Security Policy (CSP): Use CSP headers to restrict the sources from which content can be loaded.

#### Implement a solution with AWS WAF WebACL

##### Using custom rules

Return to WAF (Web Application Firewall console)

On left menu, choose "Regex pattern sets"
- Click on "Create regex pattern set"
- Regex pattern set name: Workshop-HTML-Tags
- Region: Global (CloudFront)
- Regular expressions: copy the following
```
<html>
<body>
<script>
<h1>
<h2>
<h3>
<div>
<p>
<a>
<span>
```
- Click on "Create regex pattern set" 

On the left menu click on Rule groups
- Click on "Create Rule group"
- Name Workshop-BlockHTMLTags-Group
- Region: Global (CloudFront)
- Click on "Add rule"
    - Name: BlockHTMLTagsOnHeaders
    - Type: Regular rule
    - If a request: matches the statement
    - Inspect: All headers
    - Headers match scope: Values
    - Content to inspect: All headers
    - Match type: Matches pattern from regex pattern set
    - Regex pattern set: Workshop-HTML-Tags
    - Text transformation: None
    - Oversize handling: Match - Treat web request as matching the rule statement
    - Action: Block
    - Click on "Add rule"
- Click on "Add rule"
    - Name: BlockHTMLTagsOnQueryParams
    - Type: Regular rule
    - If a request: matches the statement
    - Inspect: All query parameters
    - Match type: Matches pattern from regex pattern set
    - Regex pattern set: Workshop-HTML-Tags
    - Text transformation: URL decode
    - Action: Block
    - Click on "Add rule"
- Click on "Next"
- Click on "Next"
- Click on "Create Rule group"

On the left menu click on "Web ACLs"
- Choose WorkshopWebACL
- Go to tab "Rules"
- Click on "Add my own rules and rule groups"
    - Rule type: Choose Rule group
    - Name: Workshop-BlockHTMLTags-Ruleset
    - Rule group: Workshop-BlockHTMLTags-Group
    - Click on "Add rule"
    - Choose Workshop-BlockHTMLTags-Ruleset
    - Click on "Move up" until it reaches the top
    - Click on "Save"

### 5 - HTTP flood

![Alt text](/images/attacks-http-flood-02.webp?raw=true "attacks-http-flood")

#### Definition

HTTP Flood attacks are a type of Distributed Denial of Service (DDoS) attack where an attacker sends a large number of HTTP requests to a web server with the intent to overwhelm the server's resources and make it unavailable to legitimate users. 

These attacks exploit the HTTP protocol, often targeting web applications with complex URLs or forms that require significant server processing.

#### Types of HTTP Flood Attacks:

- GET Flood: The attacker sends a large number of HTTP - GET requests to fetch resources from the server.
- POST Flood: The attacker sends a large number of HTTP POST requests, often with large payloads, to submit data to the server.
- Slowloris: The attacker sends HTTP requests slowly, keeping many connections open and consuming server resources.

#### Mitigations:

To protect against HTTP Flood attacks, various strategies can be employed:

- Rate Limiting: Restrict the number of requests a single IP address can make in a given time period.
- CAPTCHA: Use CAPTCHA to ensure that requests are coming from real users.
- Web Application Firewall (WAF): Deploy a WAF to filter and block malicious traffic.
- IP Blacklisting: Identify and block IP addresses that are sending an excessive number of requests.
- Content Delivery Network (CDN): Use a CDN to distribute traffic and absorb large volumes of requests.
- Behavioral Analysis: Use tools to analyze traffic patterns and identify abnormal behavior indicative of an attack.

#### Implement Rate Limiting with AWS WAF WebACL

Return to WAF (Web Application Firewall console)

Go to WAF (Web Application Firewall console)

On left menu, choose "Web ACLs"
- Click on "WorkshopWebACL"
- Go to tab "Rules", 
- Choose "Add rules / Add my own rules and rule groups"
    - Rule type: choose "Rule builder"
    - Rule component:
        - Name: BlockHTTPFlood-rule
        - Type: Rate-based rule
    - Rate-limiting criteria component:
        - Rate limit: 200
        - Evaluation window: 1 minute (60 seconds)
        - Request aggregation: Source IP address
        - Scope of inspection and rate limiting: Consider all requests
- Then Action: Block
- Click on "Add rule"
- Move up BlockHTTPFlood-rule to the top of "Rules" component
- Click on "Save"

#### Demo

Open CloudShell (Just to the right side of Services search field on top of the AWS Management Console)

![Alt text](/images/CloudShell.png?raw=true "CloudShell")

Type:
```
TEST_URL=YOUR_CLOUDFRONT_DISTRIBUTION_DOMAIN_NAME
for ((i=1;i<=300;i++)); do curl  -I -k $TEST_URL; done
```

Then type:
```
curl -s $TEST_URL;
```

Expect the last curl request to be blocked

## VI - Prevent access from restricted locations

![Alt text](/images/allow-block-lists.webp?raw=true "allow-block-lists")

Go to CloudFront and select your S3 distribution
- Go to tab "Security"
- Expand "Security - Web Application Firewall (WAF)"
- Expand "CloudFront geographic restrictions"
- Click on "Edit" near Country -> "Countries - Edit"
![Alt text](/images/CloudFront-Edit-Countries-01.png?raw=true "CloudFront-Edit-Countries-01")
- Under restriction type, choose your preferred policy (Allow list or Block list)
![Alt text](/images/CloudFront-Edit-Countries-02.png?raw=true "CloudFront-Edit-Countries-02")
- Define your locations
- Save changes
- Wait for your distribution to be redeployed

Open CloudShell in a region matching your restriction rule
- Type:
```
TEST_URL=YOUR_CLOUDFRONT_DISTRIBUTION_DOMAIN_NAME
curl -s $TEST_URL;
```
- Assert the link behave as expected.

Open CloudShell in a region NOT matching your restriction rule
- Type:
```
TEST_URL=YOUR_CLOUDFRONT_DISTRIBUTION_DOMAIN_NAME
curl -s $TEST_URL;
```
- Assert the link behave as expected.

## VII - Clean up

### CloudFront initial clean up

- 01 - Go to CloudFront
- 02 - Choose your S3 distribution
- 03 - Go to tab Security
- 04 - Disable AWS WAF protection
- 05 - Go back to your distribution list
- 06 - Disable your S3 distribution
- 07 - Repeat steps 2 to 6 with your ALB distribution

### WAF initial clean up optional: Do steps 08 to 13 only if you used web-security-at-edge-demo.yaml, otherwise goto step 14

- 08 - Go to WAF
- 09 - Go to Web ACLs
- 10 - Choose WorkshopWebACL
- 11 - Go to tab Rules
- 12 - Delete all rules
- 13 - Delete WorkshopWebACL

### IAC clean up

#### With CloudFormation:  

- 14 - Go to CloudFormation
- 15 - Delete your workshop stack 

#### With Terraform: 

- 14 - Destroy resources
```HCL
terraform destroy -auto-approve -var="region=YOUR_AWS_REGION" -var="vpc_cidr=YOUR_VPC_CIDR" -var="aws_local_profile=YOUR_LOCAL_AWS_PROFILE" -var="exec_platform=YOUR_OPERATING_SYSTEM"
```
- 15 - Go to [WAF final clean up](#waf-final-cleanup)

### WAF final clean up <a name="waf-final-cleanup"></a>

- 16 - Go Rule groups
- 17 - Delete all Workshop-Block*-Group
- 18 - Go to Regex pattern sets
- 19 - Delete Workshop-HTML-Tags

### CloudFront final clean up

- 20 - Go to CloudFront
- 21 - Select your S3 and ALB distributions
- 22 - Delete both distributions