#!/usr/bin/env ruby

t = Time.now
title = $*[0..-1]

ptitle = []
title.each{|i| ptitle << i.downcase}
ptitle = ptitle.join('-')

date = t.strftime("%Y-%m-%d-#{ptitle}.md")

startstring=<<-EOF
---
layout: post
title: #{title.join(' ')}
---

#{Time.now.strftime("%B %d, %Y, %H:%M")}

# #{title.join(' ')} #



EOF

File.open(date, 'w') {|f| f.write(startstring) }
