---
title: "AWS KMS Alias Based Policies"
subtitle: ""
date: 2024-05-23T11:14:36+01:00
lastmod: 2024-05-23T11:14:36+01:00
draft: false
author: ""
authorLink: ""
description: ""

tags:
  - aws
  - kms
  - iam
  - security
categories: []

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "/images/21W20-Blog-Banner-Encrypt.jpg"
featuredImagePreview: "/images/21W20-Blog-Banner-Encrypt.jpg"

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---

I recently implemented some stuff that set up KMS keys for each application
being deployed to a k8s cluster, for use with [SOPS](https://github.com/getsops/sops).
Turns out, aliases are not as trivial to use in policies as you might expect!
<!--more-->

My initial attempt at setting this up was to do the following in Terraform:

```hcl
data "aws_iam_policy_document" "my_key_access" {
  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    resources = [
      aws_kms_key.somekey.arn,
      "arn:aws:kms:${var.region}:${var.account_id}:alias/some-prefix-*-sops"
    ]

    actions = [
      "kms:Decrypt*",
      "kms:Encrypt*",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
      "kms:DescribeKey",
    ]
  }
}
```

This didn't work! I got the usual `AccessDenied` error and tried the policy
simulator, which gave me an inkling - it won't accept an Alias as a Resource.
It turns out that if you specify an Alias as a Resource in an IAM policy, it
means the /actual/ alias. Not the thing it refers to. There's no dereferencing
that happens!

So, to fix this, you have to use Request Conditions to check the alias. I
wrapped this in a dynamic block so that if the variable passed in is empty,
we don't create a policy with unexpected side effects.

```hcl
data "aws_iam_policy_document" "my_key_access" {
  dynamic "statement" {
    for_each = length(var.kms_alias_patterns) > 0 ? toset(var.kms_alias_patterns) : []
    content {
      sid       = "KMSAliasAccess"
      effect    = "Allow"
      resources = ["*"]

      actions = [
        "kms:Decrypt*",
        "kms:Encrypt*",
        "kms:GenerateDataKey",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
      ]

      condition {
        test     = "ForAnyValue:StringLike"
        variable = "kms:ResourceAliases"
        values   = [statement.value]
      }
    }
  }
}
```

Note that we use `kms:ResourceAliases`. This is because we want to allow access
to the underlying keys, and we don't really care if someone uses the alias or
not - we just care that they only access that key. Using `kms:RequestAliases`
would only work if they used the alias, and not the key ARN itself. So it's a
bit less flexible.

These keys are further locked down by the actual KMS policy, which has an
explicit deny on Encrypt/Decrypt type actions without some extra context. This
just makes the usage of the key a bit more specific and auditable.

There's a lot more info about this approach on
[the AWS docs](https://docs.aws.amazon.com/kms/latest/developerguide/alias-authorization.html).
I was just quite surprised that Aliases don't dereference in the way I expected!
