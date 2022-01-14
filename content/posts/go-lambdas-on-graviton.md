---
title: "Go Lambdas on Graviton"
subtitle: ""
date: 2022-01-11T10:17:07Z
lastmod: 2022-01-11T10:17:07Z
draft: false
author: ""
authorLink: ""
description: ""

tags: []
categories: []

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "/images/go-lambda-arm.png"
featuredImagePreview: "/images/go-lambda-arm-preview.png"

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---
I recently had a quick look at how to get Golang Lambdas running on ARM - specifically AWS' Graviton2 processors.
<!--more-->

It was quite a trivial process really, and I think there are some price/performance benefits to using ARM.

I referred to the following links:

* https://www.paulmowat.co.uk/blog/move-aws-lambdas-graviton2-easy-cf-sam
* https://docs.aws.amazon.com/lambda/latest/dg/golang-package.html#golang-package-al2
* https://github.com/aws-samples/sessions-with-aws-sam/tree/master/go-al2

I started with a simple [SAM](https://aws.amazon.com/serverless/sam/) hello world app, in Go:

```bash
$> sam init
Which template source would you like to use?
	1 - AWS Quick Start Templates
	2 - Custom Template Location
Choice: 1

Cloning from https://github.com/aws/aws-sam-cli-app-templates

Choose an AWS Quick Start application template
	1 - Hello World Example
	2 - Multi-step workflow
	3 - Serverless API
	4 - Scheduled task
	5 - Standalone function
	6 - Data processing
	7 - Infrastructure event management
	8 - Machine Learning
Template: 1

 Use the most popular runtime and package type? (Nodejs and zip) [y/N]: n

Which runtime would you like to use?
	1 - dotnet5.0
	2 - dotnetcore3.1
	3 - dotnetcore2.1
	4 - go1.x
	5 - java11
	6 - java8.al2
	7 - java8
	8 - nodejs14.x
	9 - nodejs12.x
	10 - nodejs10.x
	11 - python3.9
	12 - python3.8
	13 - python3.7
	14 - python3.6
	15 - python2.7
	16 - ruby2.7
	17 - ruby2.5
Runtime: 4

What package type would you like to use?
	1 - Zip
	2 - Image
Package type: 1

Based on your selections, the only dependency manager available is mod.
We will proceed copying the template using mod.

Project name [sam-app]: sam-go-graviton

    -----------------------
    Generating application:
    -----------------------
    Name: sam-go-graviton
    Runtime: go1.x
    Architectures: x86_64
    Dependency Manager: mod
    Application Template: hello-world
    Output Directory: .

    Next steps can be found in the README file at ./sam-go-graviton/README.md


    Commands you can use next
    =========================
    [*] Create pipeline: cd sam-go-graviton && sam pipeline init --bootstrap
    [*] Test Function in the Cloud: sam sync --stack-name {stack-name} --watch
```

Then, I had to modify the template generated to specify the right runtime and architecture. This is slightly odd because Go is treated differently in AWS:

```bash
$> cd sam-go-graviton
$> vim template.yml
```

Update values in the template - here's the full template, details on updates below:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: >
  sam-go-graviton

  Sample SAM Template for sam-go-graviton

# More info about Globals: https://github.com/awslabs/serverless-application-model/blob/master/docs/globals.rst
Globals:
  Function:
    Timeout: 5

Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function # More info about Function Resource: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#awsserverlessfunction
    Properties:
      CodeUri: hello-world/
      Handler: hello-world
      Runtime: provided.al2
      Architectures:
        - arm64
      Tracing: Active # https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html
      Events:
        CatchAll:
          Type: Api # More info about API Event Source: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#api
          Properties:
            Path: /hello
            Method: GET
      Environment: # More info about Env Vars: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#environment-object
        Variables:
          PARAM1: VALUE
    Metadata:
      BuildMethod: makefile

Outputs:
  # ServerlessRestApi is an implicit API created out of Events key under Serverless::Function
  # Find out more about other implicit resources you can reference within SAM
  # https://github.com/awslabs/serverless-application-model/blob/master/docs/internals/generated_resources.rst#api
  HelloWorldAPI:
    Description: "API Gateway endpoint URL for Prod environment for First Function"
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/hello/"
  HelloWorldFunction:
    Description: "First Lambda Function ARN"
    Value: !GetAtt HelloWorldFunction.Arn
  HelloWorldFunctionIamRole:
    Description: "Implicit IAM Role created for Hello World function"
    Value: !GetAtt HelloWorldFunctionRole.Arn
```

Specifically:

1. `Runtime` becomes `provided`.al2
2. `Architectures` becomes `arm64`
3. Add `Metadata` section

{{< admonition >}}
Note the indentation change on `Metadata`! It's at the same level as `Properties`.
{{< /admonition >}}

Then, create the `Makefile` for the go code:

```bash
$> cat hello-world/Makefile
build-HelloWorldFunction:
	GOOS=linux go build -o bootstrap
	cp ./bootstrap $(ARTIFACTS_DIR)/.
```

Lastly, run the build/deploy:

```bash
$> sam build
...
Build Succeeded
...
$> sam deploy --guided

Configuring SAM deploy
======================

	Looking for config file [samconfig.toml] :  Not found

	Setting default arguments for 'sam deploy'
	=========================================
	Stack Name [sam-app]: sam-go-graviton
	AWS Region [eu-west-2]:
	#Shows you resources changes to be deployed and require a 'Y' to initiate deploy
	Confirm changes before deploy [y/N]:
	#SAM needs permission to be able to create roles to connect to the resources in your template
	Allow SAM CLI IAM role creation [Y/n]:
	#Preserves the state of previously provisioned resources when an operation fails
	Disable rollback [y/N]:
	HelloWorldFunction may not have authorization defined, Is this okay? [y/N]: y
	Save arguments to configuration file [Y/n]:
	SAM configuration file [samconfig.toml]:
	SAM configuration environment [default]:
```

...and so on. Wait for it to finish, then copy the endpoint URL and:

```bash
$> curl https://<ENDPOINT>.execute-api.eu-west-2.amazonaws.com/Prod/hello/
Hello, <some ip address>
```

Et Voila! You've just deployed a SAM app running Go, all running on the new Graviton chips!

./A
