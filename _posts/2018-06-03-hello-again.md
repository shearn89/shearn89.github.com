---
layout: post
title: "We meet again..."
description: ""
category: other
tags: [nontech, blog]
---
{% include JB/setup %}

# Hello internet! #

It's been a fair while since I've written anything on here. That's mostly because it's been an absolutely mad year. I finished working on one major project, worked on 2 more, and then moved to New Zealand...

The move had been on the radar for a long time but took ages to sort out contracts and paperwork: I finally moved in April of 2018 and am enjoying it immensely so far!

As to other projects, I had the opportunity to lead on a very interesting project at work where we were building a [BGP](https://en.wikipedia.org/wiki/Border_Gateway_Protocol) monitoring platform. BGP is the protocol that enables routers on the internet to share routes to IP spaces that they own, and it's quite vulnerable to attack. In fact there's been some pretty high profile attacks in recent years where all of a Communication Service Provider's traffic was routed out of the UK and via Ukraine (for example). We were working to build a platform that can watch for these malicious announcements and then alert us to them.

It sounds like a simple problem: the more we worked on it the more we discovered that it really isn't! We managed to build a simple proof-of-concept, but it was only once we'd spent some time dealing with the problems that we fully worked out what they were. Effectively you end up building a state model that provides a map (from your viewpoint) of the whole internet, and then trying to efficiently update it. Not trivial! Anyway: it was a very enjoyable project, and we got excellent feedback from the customer for it, so that's always good!

I'm hoping in the next few months to do some major updates to my [Puppet hardening module](https://github.com/shearn89/puppet-toughen) - I'd like to get the basics done, then update it to be compatible with Puppet 5 and add in any bells and whistles that allows. I'd also like to get round to supporting Debian-based distros, but we'll see how much progress I make with that...

Other goals for this year? I'd like to get some certifications under my belt. I've been chasing RedHat qualifications for a while but have never got the budget approved for the learning subscription: fingers crossed this is my year! With a bit of luck I could probably get RHCSA, RHCE, and 3 of the 5 specialist certifications for RHCA.

I'd also like to branch out from automation a bit. I might start dabbling with Node.js and try to build some simple web-apps, purely for the experience. I find I learn a whole lot better when I've a project to do rather than when I'm just reading and not doing!

That's all for now. Here's hoping it won't be 12 months 'til my next post... O_O

./A
