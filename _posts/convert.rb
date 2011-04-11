require 'reverse_markdown'


files = Dir.glob('*.html')

files.each do |htmlfile|
	r = ReverseMarkdown.new
	htmlstring= ""
	drop = false
	date=""
	title=""
	name=""
	File.open("#{htmlfile}", 'r') do |infile|
		puts htmlfile
		while (line = infile.gets)
			begin
				if line.include? 'TUMBLR'
					drop = !drop
					next
				end
				if line.include? 'date-gmt'
					date=line.split[5].split('"')[1]
					title=line.split[16].split('"')[1]
					name=date+"-"+title+".md"
				end
				if !(line.split[0][1] == 33) && !drop
					htmlstring << line.gsub(/..\/images/, '/img').strip+"\n"
				end
			rescue
			end
		end
	end
	text= <<-EOF
---
layout: post
---
EOF
	File.open("#{name}", 'w') {|f| f.write(text+r.parse_string(htmlstring))}
end
