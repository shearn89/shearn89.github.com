---
categories:
- technical
date: "2022-01-05T16:33:11Z"
description: "Migrating the blog from Jekyll to Hugo"
tags:
- blog
- writing
- technical
featuredImage: "/images/hugo-logo.png"
featuredImagePreview: "/images/hugo-logo-preview.png"
draft: true
title: Migration to Hugo
---
I decided to update the blog, only to discover that Jekyll is now quite old, the framework around it that I used is not maintained, and generally could do with a change.
<!--more-->

## Introduction

With that in mind, I've ported it over to [Hugo](https://gohugo.io/) which seems much more appropriate! It's written in Go, and I also wanted to flex my AWS skills some more and set up my own CI/CD and hosting infrastructure, rather than using GitHub Pages.

I've set this up as a GitHub repo, but the CI/CD is now done by AWS CodeBuild. That runs the `hugo` command to generate the static files, and then uploads them to S3.

S3 is configured as a private bucket, with a CloudFront distribution in front of it. This way if any of my posts ever go viral (unlikely, but I can hope!) then I'll not have issues with load.

## Issues Encountered

Porting over to Hugo wasn't too painful, but I did have to dig into my chosen theme to work out where to put things and how to lay things out. It's not quite as intuitive! Once I'd got my head around that, it wasn't too bad.

Next issue was with the build - trying to get the Hugo Go module set up in CodeBuild was contentious. First it didn't like my `go install` syntax. Then I got this error:

```
[Container] 2022/01/05 16:28:22 Entering phase INSTALL
[Container] 2022/01/05 16:28:22 Running command go get github.com/gohugoio/hugo
package github.com/pelletier/go-toml/v2: cannot find package "github.com/pelletier/go-toml/v2" in any of:
    /root/.goenv/versions/1.14.12/src/github.com/pelletier/go-toml/v2 (from $GOROOT)
    /go/src/github.com/pelletier/go-toml/v2 (from $GOPATH)
    /codebuild/output/src251579062/src/github.com/pelletier/go-toml/v2
package github.com/jdkato/prose/transform: cannot find package "github.com/jdkato/prose/transform" in any of:
    /root/.goenv/versions/1.14.12/src/github.com/jdkato/prose/transform (from $GOROOT)
    /go/src/github.com/jdkato/prose/transform (from $GOPATH)
    /codebuild/output/src251579062/src/github.com/jdkato/prose/transform
unrecognized import path "io/fs": import path does not begin with hostname

[Container] 2022/01/05 16:38:15 Command did not exit successfully go get github.com/gohugoio/hugo exit status 1
[Container] 2022/01/05 16:38:15 Phase complete: INSTALL State: FAILED
```

Based on [this GitHub comment](https://github.com/aws/aws-codebuild-docker-images/issues/425#issuecomment-861921069), it looks like it's because CodeBuild uses an old version of Go. Adding the recommended commands to my `buildspec.yml` seemed to improve things:

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
      - 'go get github.com/gohugoio/hugo'
      - 'hugo'
artifacts:
  files:
    - public/*
```

However, I then got a different error:

```
[Container] 2022/01/05 17:14:11 Running command hugo
Start building sites … 
hugo v0.91.2 linux/amd64 BuildDate=unknown
Error: Error building site: TOCSS: failed to transform "css/style.scss" (text/x-scss). Check your Hugo installation; you need the extended version to build SCSS/SASS.: this feature is not available in your current Hugo version, see https://goo.gl/YMrWcn for more information
Total in 311 ms

[Container] 2022/01/05 17:14:11 Command did not exit successfully hugo exit status 255
```

The solution to this was on the Hugo website. I had to modify the tag I pulled from github:

```
      - 'go install --tags extended github.com/gohugoio/hugo@latest'
```

...which then worked! I ended up with a successful build and something in an S3 bucket!


## Tuning up the Output

At first the build was creating a directory structure to match the project name, but then losing the directory structure of the actual files. That was easily fixed by altering the `artifacts` section of the buildspec:

```
artifacts:
  files:
    - '**/*'
  base-directory: 'public'
```

This means that effectively the build moves into the `public/` folder before grabbing everything, including folders. By modifying the build to place everything at the path `/` in S3, I got the result I wanted, which was that the contents of `public` got placed in the bucket, ready for hosting.


## Integrating with CloudFront

I wanted to take the chance to play with CloudFront because it should allow me to keep the bucket private and then expose it using an [Origin Access Identity](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html). Initially I ran into some trouble because the documentation didn't seem to match the actual console - the option to specify an OAI just wasn't on my Distribution.

I tried to follow the documentation, but in the end I ended up creating a new S3 bucket, as that seemed to immediately present the option to use an OAI. The following were all tried and compared with a fresh bucket:

* Encryption settings
* Static website settings
* Public access settings

Nothing I did made a difference! I have yet to find the answer. In then end a new bucket seemed to allow me to attach the OAI. I have had the first bucket for a reeeeeally long time so it could always be something to do with that?

So even after setting all that up, I was still getting an XML `Access Denied` message from CloudFront. This turned out to be a typo in the 'default root object' (as far as I could tell) - when I re-ran the build to create all the files, and removed the leading slash from the root object (`/index.html` -> `index.html`) it all sprang into life!

## Site Testing

After getting the CloudFront distribution working and setting up the OAI, I wanted to run do some quick checks to make sure that things were secure and working as intended, before going back over doing it all with CloudFormation.

I wanted to check that the S3 bucket was definitely not accessible, and the new distribution was. I also wanted to check that it was using HTTPS and redirecting HTTP. All of these worked fine! I used AWS Config to enforce public access settings on the bucket, and some simple browser tests worked for the redirects.

## CI/CD

I wanted the site to build automatically, rather than requiring me to run the build. CodeBuild needed a trigger! I created a CodePipeline that used GitHub as a source, and my existing CodeBuild project as the build stage. I made sure to tick the 'Full Clone' option so that the build would actually be able to run as it had submodules. I skipped the Deploy stage.

When it first ran, it failed - this was because the service role that I had previously set up for the CodeBuild project did not have permissions to use the connection to GitHub that Pipelines configured. I had to modify the role and add the `codestar-connections:UseConnection` permission.

With that done, I re-ran the pipeline and could see the build running! Success! I then merged into `main` and update CodeBuild to work off that branch rather than the feature branch.

## Conclusion

Quite a fun little project! I will revisit all of this through the lens of Infrastructure as Code - I'd normally do that as I go but given that I hadn't worked with CloudFront before (or GitHub connections into AWS) I wanted to do it by hand first. I shall port everything across to CloudFormation (or the [CDK](https://aws.amazon.com/cdk/)) and potentially redeploy it all!

./A
