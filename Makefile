.PHONY: build public lint precheck postcheck spellcheck links

build: precheck public postcheck

public:
	hugo

precheck: spellcheck lint 

postcheck: links

spellcheck:
	npx -q spellchecker-cli@latest -p spell indefinite-article repeated-words syntax-mentions syntax-urls frontmatter \
		--frontmatter-keys title description \
		-d .dictionary.txt \
		-f content/**/*.md
lint:
	npx -q markdownlint-cli2@latest content/**/*.md

links: public
	find content/posts/ -name \*.md -print0 | xargs -0 -n1 npx -q markdown-link-check@latest -c .mdlc-config.json
