---
title: "Docker on Codebuild"
subtitle: ""
date: 2022-01-10T12:23:48Z
lastmod: 2022-01-10T12:23:48Z
draft: false
author: ""
authorLink: ""
description: ""

tags: []
categories: []

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: ""
featuredImagePreview: "/images/docker-codebuild-preview.png"

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---
I've recently been playing with building some containers for use in CodeBuild. Here's what I learned.
<!--more-->

## Introduction

Initially, I wanted to set up a custom build environment to speed up my build process. The build of the blog was taking ages (minutes) to run, when it should be super speedy. Realizing that the bulk of the time was spent updating Go and installing dependencies, it was clear that I could save a bunch of time if I built those into the container. 

The original `buildspec.yml` looked like this:

```yaml
version: 0.2
phases:
  install:
    commands:
      - 'cd $HOME/.goenv && git pull --ff-only && cd -'
      - 'goenv install 1.17.5'
      - 'goenv local 1.17.5'
  build:
    commands:
      - 'go install --tags extended github.com/gohugoio/hugo@latest'
      - 'hugo'
artifacts:
  files:
    - '**/*'
  base-directory: 'public'
```

As you can see, most of the build file is installing Go and Hugo. Let's fix that.

## Creating a new repository

I'll do this on AWS directly rather than adding in GitHub integration. Since it's such a simple repository it's easy enough to share the code here!

I created a Dockerfile:

```docker
FROM public.ecr.aws/docker/library/golang:1.17

RUN go install --tags extended github.com/gohugoio/hugo@latest
```

...and a buildspec:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...          
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG      
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```

The buildspec is shamelessly taken from the [AWS examples](https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html), it's pretty simple:

* Log in to ECR
* Run `docker build`
* Tag the image for push to ECR
* Push the image

Not much to it.

The Dockerfile is also pretty simple: install Hugo! The only thing to note here is that we use `public.ecr.aws` instead of the standard Docker Hub: that's because Docker is rate limiting requests now, and CodeBuild otherwise gets blocked because it gets used so much. You can set up your own private mirrors in ECR, or configure [pull-through caching](https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-ecr-cache-repositories/), or just use the AWS repos. I opted for the last option.

## Create the pipeline

First, I created a simple CodeBuild project, then wrapped it in a pipeline. As per my [last post](https://www.shearn89.com/2022/01/05/hugo-migration/) I should really be doing this with CI, but I was going for quick & dirty...

The build project was simple:

* Clone from codecommit, main branch.
* Use the Ubuntu `aws/codebuild/standard:5.0` build environment, elevated for using Docker. Add some environment variables for region, account, repo name and tag - as per the `buildspec.yml`
* Refer to buildspec for build commands
* No artifacts

Save the project and give it a test run. Shouldn't be any real issues, unless you left the 'modify the service role' box unticked - leave it ticked and then codebuild will automatically add sensible permissions to the role.

Next, add the CodePipeline wrap to auto-run it. Create a CodePipeline project, using:

* Source - CodeCommit
* Build - CodeBuild

...and that's about it! Save and push your code, and it should build the Docker image and push it up to ECR.

./A
