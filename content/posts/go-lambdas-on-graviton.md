---
title: "Go Lambdas on Graviton"
subtitle: ""
date: 2022-01-11T10:17:07Z
lastmod: 2022-01-11T10:17:07Z
draft: true
author: ""
authorLink: ""
description: ""

tags: []
categories: []

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "go-lambda-arm.png"
featuredImagePreview: "go-lambda-arm-preview.png"

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---
I recently had a quick look at how to get Golang Lambdas running on ARM - specifically AWS' Graviton2 processors.
<!--more-->

https://www.paulmowat.co.uk/blog/move-aws-lambdas-graviton2-easy-cf-sam
https://docs.aws.amazon.com/lambda/latest/dg/golang-package.html#golang-package-al2
https://github.com/aws-samples/sessions-with-aws-sam/tree/master/go-al2

In general quite easy

Using SAM app:

modify template - arch, runtime, buildmethod
Add makefile

sam build/sam deploy
