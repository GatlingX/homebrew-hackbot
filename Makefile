DEFAULT_GOAL := help
.PHONY: all update-formula test audit install clean update-sha poet assemble_formula ensure_venv

# COLORS
GREEN=\033[0;32m
YELLOW=\033[0;33m
RED=\033[0;31m
BLUE=\033[0;34m
RESET=\033[0m

FORMULA_NAME = hackbot
FORMULA_FILE = $(FORMULA_NAME).rb
REPO_OWNER = GatlingX

all: update-formula test

VENV_NAME=venv
VENV_ACTIVATE=$(VENV_NAME)/bin/activate

ensure_venv:
	@echo "$(BLUE)🔧 Creating Python virtual environment...$(RESET)"
	python3 -m venv $(VENV_NAME)

# Create the package, with preamble and postamble from preamble.txt and postamble.txt
poet: ensure_venv
	@echo "$(BLUE)📝 Generating resource stanzas with homebrew-pypi-poet...$(RESET)"
	. $(VENV_ACTIVATE) && \
	pip install -U hackbot && \
	pip install homebrew-pypi-poet
	. $(VENV_ACTIVATE) && \
	poet hackbot > poet_output.txt 
	# Run a simple script to move the hackbot resource stanza to url and sha256
	./move_hackbot_resource.py
	@echo "$(GREEN)✅ Resource stanzas generated successfully!$(RESET)"

assemble_formula: poet
	@echo "$(BLUE)🔨 Assembling formula file...$(RESET)"
	@cat preamble_processed.txt poet_output.txt postamble.txt > $(FORMULA_FILE)
	@rm poet_output.txt
	@# Get version from pip
	@. $(VENV_ACTIVATE) && \
	VERSION=$$(pip show hackbot | grep Version | cut -d ' ' -f 2) && \
	echo "$(BLUE)📌 Setting version to: $$VERSION$(RESET)" && \
	perl -pi -e "s/version \"VERSION\"/version \"$$VERSION\"/" $(FORMULA_FILE)
	@echo "$(GREEN)✅ Formula assembled successfully!$(RESET)"

# Run brew audit on the formula
audit:
	@echo "$(BLUE)🔍 Running brew audit...$(RESET)"
	brew audit --strict --online $(FORMULA_FILE)
	@echo "$(GREEN)✅ Audit passed!$(RESET)"

# Test installing the formula
test: audit
	@echo "$(BLUE)🧪 Testing formula installation...$(RESET)"
	brew install --build-from-source $(FORMULA_FILE)
	brew test $(FORMULA_NAME)
	@echo "$(BLUE)🚀 Running basic hackbot test...$(RESET)"
	hackbot --help
	@echo "$(GREEN)✅ All tests passed!$(RESET)"

# Install the formula locally
install:
	@echo "$(BLUE)📦 Installing formula...$(RESET)"
	brew install --build-from-source $(FORMULA_FILE)
	@echo "$(GREEN)✅ Installation complete!$(RESET)"

# Clean up installed formula
clean:
	@echo "$(YELLOW)🧹 Cleaning up...$(RESET)"
	brew uninstall $(FORMULA_NAME) || true
	brew untap $(REPO_OWNER)/$(FORMULA_NAME) || true
	@echo "$(GREEN)✨ Cleanup complete!$(RESET)"

# Helper to print current version
version:
	@echo "$(BLUE)📌 Current version: $(VERSION)$(RESET)"

help:
	@echo "$(BLUE)🔎 Available targets:$(RESET)"
	@echo "  make poet          - 📝 Generate resource stanzas using homebrew-pypi-poet"
	@echo "  make assemble_formula - 🔨 Combine preamble, poet output and postamble into formula"
	@echo "  make audit         - 🔍 Run brew audit on formula"
	@echo "  make test          - 🧪 Test formula installation"
	@echo "  make install       - 📦 Install formula locally"
	@echo "  make clean         - 🧹 Uninstall formula and untap repo"
	@echo "  make version       - 📌 Print current version"
	@echo "  make help          - 💡 Show this help message"