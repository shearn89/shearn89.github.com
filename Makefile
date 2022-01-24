.PHONY: build public lint precheck postcheck spellcheck links

build: precheck public postcheck

public:
	hugo

precheck: spellcheck lint 

postcheck: links

spellcheck:
	npx --yes -q spellchecker-cli@4.8.1 -p spell indefinite-article repeated-words syntax-mentions syntax-urls frontmatter \
		--frontmatter-keys title description \
		-d .dictionary.txt \
		-f content/**/*.md
lint:
	npx --yes -q markdownlint-cli2@0.4.0 content/**/*.md

links: public
	find content/posts/ -name \*.md -print0 | xargs -0 -n1 npx --yes -q markdown-link-check@3.9.0 --config .mdlc-config.json
