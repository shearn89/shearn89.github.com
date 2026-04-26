---
title: "Agentic Engineering So Far"
subtitle: ""
date: 2026-04-24T11:14:36+01:00
lastmod: 2026-04-24T11:14:36+01:00
draft: false
author: ""
authorLink: ""
description: ""

tags:
  - ai
categories:
  - Technical

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "/images/ai-noodling.webp"
featuredImagePreview: "/images/ai-noodling.webp"

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---

Recently I've been doing a lot more work with AI agents in my day to day
work, so this post is a bit of a rambling write-up of where I've got to.
Some semi-useful learnings that others may benefit from!

<!-- more -->

I was pretty skeptical at first. My view was that AI coding tools were
smart autocomplete - handy for boilerplate, better at filling in
parameters in terraform than the built in autocomplete, unit test
population, not much else. Then I started using them for small,
well-defined tasks - single files, single functions, clear inputs and
outputs. That worked surprisingly well, and I started to build up some
trust in what they produced.

Naturally, I tried more complex tasks next. That didn't go so well! I
wasn't specific enough in my prompts, there weren't enough guardrails,
and the test coverage wasn't there to catch the things the agent got
wrong. So I started breaking tasks down manually - the same way I'd
split work up for another engineer - and leaning hard on automated
tests and linting for validation. TDD works great too, as the tests
become part of the spec. I slowly began running multiple agents in
parallel for independent bits of work, and using git worktrees to keep
the isolated. The loop became: prompt, plan, review PR. Less typing,
more reviewing.

I think this lines up with the shift the industry is seeing - human
validation becoming the bottleneck, more than producing code.

## WALLIE, or: how a throwaway comment became a platform

The thing that really pushed me past "occasional helper" and into
building properly with agents was WALLIE - our internal service desk
agent. It came out of a fairly offhand "you should be doing more with
AI" comment from SLT, which I'll admit triggered a bit of an eye roll
at the time. The platform team at my company has been swamped, working
the requests desk is painful, and no one likes doing it.

But once I actually sat with it, I could see the shape of something
useful: we had a well-scoped problem (service desk tickets against a
known set of repos), good telemetry (Sentry, Datadog, Plain), and an
audit trail baked in (every change goes through a PR). That's actually
a pretty ideal environment for an agent to work in - bounded blast
radius, clear success criteria, humans still in the loop for anything
that matters. Generally the issues are either informational (what IP
does our traffic exit from?), simple (please add this permission to
this role), or complex (we're seeing 5xx's, why?). Clearly defined
boundaries and sizes.

The first version was pretty mechanical: manual trigger to an API,
Haiku for triage, onto an SQS queue feeding long running workers,
per-ticket worktrees on EFS, Claude Code doing the actual work, output
as a PR plus a Plain note for human review.

It worked, but it was over-engineered in places - I'd built a Python
routing layer that was doing work the model was perfectly capable of
doing itself. Also the model selection needed some work, and setting up
evals just ended up in a mess.

The redesign towards Steve Yegge's Zero Framework Cognition approach -
replacing the routing with a minimal bash escalation script - has been
a good lesson in resisting the urge to scaffold everything. Sometimes
the right answer is to trust the model and get out of its way, and the
engineering judgement is knowing _when_ that's the right answer versus
when you genuinely need guardrails.

## Orchestration

I've been playing with orchestration tools to push this development
process further.
[GASTOWN](https://github.com/gastownhall/gastown) with
[beads](https://github.com/gastownhall/beads) is what I've spent most
time with. Both are buggy. Beads has been inconsistent - its behaviour
varies between runs in ways I can't always explain, and the Dolt
migration hasn't really delivered the benefits I was hoping for. It
often seems to do something to the config that means tickets go
missing, and when the memory is in beads too it breaks pretty badly.
GASTOWN claims to coordinate agents, but in practice the agents get
stuck and the Mayor reports them as "finished" or "still working" when
neither is true. There's meant to be other processes catching this, but
it still needs manual coaxing.

There's plenty of other similar tools out there - Nelson, Conductor,
and more - and I suspect most of them will be gone or consolidated
within the year.

The strategic lesson for me has been to avoid getting too attached to
any particular tool right now. The primitives that matter - version
control, PRs, tests, CI, clear interfaces - aren't going anywhere. The
orchestration layer on top will churn for a while yet. So I'm building
WALLIE on stable primitives (SQS, EFS, git, Claude Code) and treating
the rest as swappable. If we invest heavily in a specific orchestrator
and it dies, we want the replacement cost to be low. There were some
good talks at a recent conference about this - how "black box" is the
code? Some companies think "the code is cheap, just rebuild it".
Linear, Pi, and other companies are being more selective, and making
sure that code is written well the first time. I think I lean more
towards the latter, but I think there's some value in building a cheap
throwaway POC to support a use case or proposal, demonstrate value, and
then iterate.

## What actually helps

One thing that's struck me is how much of this rewards the same habits
as being a senior engineer: tests, automation, documentation, clear
designs. What helps a human reason about a system helps an agent too.
There's only so much context a human can hold in their head, and the
same is true for agents - breaking docs and code into smaller,
well-scoped files is a win for both. If your codebase is a tangled mess
that humans struggle to onboard into, agents won't save you either.

Similarly, breaking a complex build down and iterating on it will (a)
produce better results, and (b) keep code reviewable. If the bottleneck
is in validating that the model generated the right output, keep the
output manageable and test often. In my personal work I'm going full
vibes - with a whole app built without me inspecting the code. It's a
simple use case, but I'm setting up BDD as a spec and Playwright for
some verification. Very much an experiment but I'm finding it an
excellent learning experience!

I think these soft skills are the bit that gets underweighted in a lot
of the "AI is going to replace engineers" discourse. The teams that are
going to get the most out of this explosion are the ones that already
have their house in order - good tests, clear module boundaries, decent
docs, tight feedback loops. Agents amplify whatever engineering culture
you've already got. That's actually an argument _for_ investing more in
platform work, not less: the better your platform, the more leverage
your agents get.

## Vibe reviewing

Next step for me is "vibe reviewing" - using AI to assist with PR
reviews, not just while writing code. Claude has been particularly good
at this. A colleague was recently in a region with very little time
zone overlap, pushing some chunky PRs in React. I could read through
the changes, but didn't always have the full context on the tech
involved. Claude picked up a security issue twice, and a neat circular
dependency resolution once. Excellent! Here's the review prompt I've
been iterating on:

```markdown
When reviewing PRs, highlight the following:

- overly broad permissions
- changes to access
- elevation of access
- exposing new things to the public internet
- exposing new routes in the application
- changes to database schemas
- overly complex database schemas
- overly complex code
- repetitive code
- using the wrong technology for the job (e.g. using DynamoDB but treating it like an SQL table)
- changes to interfaces, whether that's variables in Terraform or interface definitions in APIs
- strict adherence to semantic versioning
```

Quick tip: if you've got the Superpowers plugin installed, try turning
it off for PR reviews. It conflicts sometimes, and I've had cleaner
results without it.

./A
