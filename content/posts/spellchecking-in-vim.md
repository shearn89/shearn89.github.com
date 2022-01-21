---
title: "Spellchecking in Vim"
subtitle: ""
date: 2022-01-21T10:22:49Z
lastmod: 2022-01-21T10:22:49Z
draft: true
author: ""
authorLink: ""
description: ""

tags: []
categories: []

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: ""
featuredImagePreview: ""

toc:
  enable: true
math:
  enable: false
lightgallery: false
license: ""
---
It's taken me years, but I finally found out about spellchecking in Vim!
<!--more-->
Neovim

Add rule to init.vim/vimrc

`]s` to go to next bad word
`zg` to add to dictionary
`zw` to add as 'bad' word
`zug` or `zuw` to undo last
