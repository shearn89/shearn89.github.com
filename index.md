---
layout: page
title: shearn89.com
tagline: My home away from $HOME.
---
{% include JB/setup %}

Welcome to my blog. Here is where I write out about anything I feel like, be it tech stuff I've worked on, problems I've solved, good beer I've drunk... Anything at all!

## Posts

Latest posts:

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

## Social

You can connect with me on various social media sites at:

* <a href="https://github.com/shearn89">GitHub</a>
* <a href="https://twitter.com/shearn89">Twitter</a>
* <a href="https://www.linkedin.com/in/alexshearn/">LinkedIn</a>
