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
