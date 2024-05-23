.PHONY: build public lint precheck postcheck spellcheck links

build: precheck public postcheck

public:
	hugo --config hugo.toml

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
	npx --yes -q markdown-link-check@3.9.3 --config .mdlc-config.json content/**/*.md
