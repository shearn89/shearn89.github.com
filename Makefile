.PHONY: deps build public lint precheck postcheck spellcheck links

build: deps precheck public postcheck

deps:
	npm install

public:
	hugo

precheck: spellcheck lint 

postcheck: links

spellcheck:
	./node_modules/.bin/spellchecker -p spell indefinite-article repeated-words syntax-mentions syntax-urls frontmatter \
		--frontmatter-keys title description \
		-d .dictionary.txt \
		-f content/**/*.md
lint:
	./node_modules/.bin/markdownlint-cli2 content/**/*.md

links: public
	find content/posts/ -name \*.md -print0 | xargs -0 -n1 ./node_modules/.bin/markdown-link-check -c .mdlc-config.json
