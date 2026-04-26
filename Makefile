.PHONY: setup build public lint precheck postcheck spellcheck links

MISE := $(shell command -v mise 2>/dev/null || echo $$HOME/.local/bin/mise)
HUGO := $(MISE) exec -- hugo

build: setup precheck public postcheck

setup:
	@if ! command -v mise >/dev/null 2>&1 && [ ! -x "$$HOME/.local/bin/mise" ]; then \
		echo "Installing mise..."; \
		curl -fsSL https://mise.run | sh; \
	else \
		echo "mise already installed: $$($(MISE) --version)"; \
	fi
	@$(MISE) install

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
