#!/usr/bin/env python3
import re

# Read the poet output file
with open("poet_output.txt", "r") as f:
    poet_content = f.read()

# Find the hackbot resource stanza
hackbot_pattern = r'resource "hackbot" do\n.*?url "(.*?)"\n.*?sha256 "(.*?)"'
match = re.search(hackbot_pattern, poet_content, re.DOTALL)

if not match:
    print("Could not find hackbot resource stanza")
    exit(1)

url = match.group(1)
sha = match.group(2)

preamble_processed_name = "preamble_processed.txt"


# Read the preamble file
with open("preamble.txt", "r") as f:
    preamble_content = f.read()

# Replace the URL and SHA placeholders
preamble_content = re.sub(r"HACKBOT_URL", f'url "{url}"', preamble_content)
preamble_content = re.sub(r"HACKBOT_SHA256", f'sha256 "{sha}"', preamble_content)

# Write back the updated preamble
with open(preamble_processed_name, "w") as f:
    f.write(preamble_content)

# Remove the hackbot resource stanza from poet output
poet_content = re.sub(r'\n\s*resource "hackbot".*?end\n', "\n", poet_content, flags=re.DOTALL)

# Write back the modified poet output
with open("poet_output.txt", "w") as f:
    f.write(poet_content)
