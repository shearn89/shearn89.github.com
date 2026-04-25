.PHONY: setup build public lint precheck postcheck spellcheck links

HUGO := mise exec -- hugo

build: setup precheck public postcheck

setup:
	@if ! command -v mise >/dev/null 2>&1; then \
		echo "Installing mise..."; \
		curl -fsSL https://mise.run | sh; \
		echo "mise installed. Ensure ~/.local/bin is on your PATH and shell is activated (see https://mise.jdx.dev/getting-started.html)."; \
	else \
		echo "mise already installed: $$(mise --version)"; \
	fi
	@command -v mise >/dev/null 2>&1 && mise install || echo "Run 'mise install' after activating mise in your shell."

public:
	$(HUGO) --config hugo.toml

precheck: spellcheck lint

postcheck: links

spellcheck:
	npx --yes -q spellchecker-cli@4.8.1 -l en-GB -p spell indefinite-article repeated-words syntax-mentions syntax-urls frontmatter \
		--frontmatter-keys title description \
		-d .dictionary.txt \
		-f content/**/*.md
lint:
	npx --yes -q markdownlint-cli2@0.4.0 content/**/*.md

links: public
	npx --yes -q markdown-link-check@3.9.3 --config .mdlc-config.json content/**/*.md
