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

PYTHON_WITH_VERSION="python3.12"
PYTHON_VERSION="python\@3.12"

ensure_venv:
	@echo "$(BLUE)🔧 Creating Python virtual environment...$(RESET)"
	$(PYTHON_WITH_VERSION) -m venv $(VENV_NAME)

# Create the package, with preamble and postamble from preamble.txt and postamble.txt
poet: ensure_venv
	@echo "$(BLUE)📝 Generating resource stanzas with homebrew-pypi-poet...$(RESET)"
	. $(VENV_ACTIVATE) && \
	pip install -U --force-reinstall hackbot && \
	pip install homebrew-pypi-poet
	. $(VENV_ACTIVATE) && \
	poet -f hackbot > hackbot.rb
	@echo "$(GREEN)✅ Formula generated successfully!$(RESET)"

assemble_formula: poet
	# Replace the description with the description from the formula
	perl -pi -e 's/desc "Shiny new formula"/desc "CLI tool for source code analysis using the Hackbot service"/' hackbot.rb
	# Replace the homepage with the homepage from the formula
	perl -pi -e 's|homepage "None"|homepage "https://github.com/GatlingX/hackbot"|' hackbot.rb
	@# Remove the resource stanza for cryptography, i.e. just the 2 lines before and after the resource "cryptography" do line
	perl -0777 -pi -e 's/resource "cryptography" do.*\n(?:.*\n){3}//' hackbot.rb
	@# Replace the python version with the python version from default formula "python3" with the specific version we want
	@# virtualenv_create(libexec, "python3") -> virtualenv_create(libexec, "python3.12")
	perl -pi -e 's|libexec, \"python3\"|libexec, $(PYTHON_WITH_VERSION)|' hackbot.rb
	@# depends_on "python3" -> depends_on "python@3.12"
	@# the cryptography and maturin dependencies after the depends_on line
	perl -pi -e 's|depends_on "python3"|depends_on $(PYTHON_VERSION)\n  depends_on "cryptography"\n  depends_on "maturin"|' hackbot.rb
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