---
title: "Installing Depthai on Apple Silicon"
subtitle: ""
date: 2022-01-14T10:25:01Z
lastmod: 2022-01-14T10:25:01Z
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
I finally got around to playing with my Oak D-Lite camera from Luxonis!
<!--more-->

Installation:

mac already had brew up and running, **not** under rosetta.

```bash
$> uname -m
arm64
$> python --version
Python 3.8.12
$> pyenv local
3.8.12
# takes a long time...
$> brew install cmake opencv
```
when it's done:
```bash
$> python -m pip install virtualenv                                                                             ✔  1211  11:03:56
Collecting virtualenv
  Using cached virtualenv-20.13.0-py2.py3-none-any.whl (6.5 MB)
Collecting distlib<1,>=0.3.1
  Using cached distlib-0.3.4-py2.py3-none-any.whl (461 kB)
Collecting filelock<4,>=3.2
  Using cached filelock-3.4.2-py3-none-any.whl (9.9 kB)
Collecting platformdirs<3,>=2
  Using cached platformdirs-2.4.1-py3-none-any.whl (14 kB)
Requirement already satisfied: six<2,>=1.9.0 in /Users/ajshearn/.pyenv/versions/3.8.12/lib/python3.8/site-packages (from virtualenv) (1.16.0)
Installing collected packages: platformdirs, filelock, distlib, virtualenv
Successfully installed distlib-0.3.4 filelock-3.4.2 platformdirs-2.4.1 virtualenv-20.13.0
WARNING: You are using pip version 21.1.1; however, version 21.3.1 is available.
You should consider upgrading via the '/Users/ajshearn/.pyenv/versions/3.8.12/bin/python -m pip install --upgrade pip' command.
$> python -m virtualenv .venv                                                                                   ✔  1212  11:04:15
created virtual environment CPython3.8.12.final.0-64 in 346ms
  creator CPython3Posix(dest=/Users/ajshearn/repos/playground/depthai/.venv, clear=False, no_vcs_ignore=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/Users/ajshearn/Library/Application Support/virtualenv)
    added seed packages: pip==21.3.1, setuptools==60.2.0, wheel==0.37.1
  activators BashActivator,CShellActivator,FishActivator,NushellActivator,PowerShellActivator,PythonActivator
$> . .venv/bin/activate
$> pip install -v numpy
$> pip install --no-use-pep517 -v depthai
```

Now clone the actual examples:
```bash
$> gh repo clone luxonis/depthai-python
$> cd depthai-python/
$> git checkout gen2_uvc
```
