#!/bin/bash

# Check if required tools are installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Please install it and try again."
    exit 1
fi

if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed. Please install it and try again."
    exit 1
fi

# Check input arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <URL> <Title (without quotes)>"
    exit 1
fi

# Get the URL and Title arguments
URL=$1
shift
TITLE="$*"

# Create a temporary file for the HTML content
TMP_HTML=$(mktemp)

# Download the HTML content
echo "Downloading content from $URL..."
wget -q -O "$TMP_HTML" "$URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download content from $URL."
    rm -f "$TMP_HTML"
    exit 1
fi

# Generate output file name
OUTPUT_RMD="${TITLE// /_}.Rmd"

# Convert HTML to Markdown using pandoc
echo "Converting HTML to Markdown..."
pandoc -f html -t markdown "$TMP_HTML" -o "$OUTPUT_RMD"

if [ $? -ne 0 ]; then
    echo "Error: Failed to convert HTML to Markdown."
    rm -f "$TMP_HTML"
    exit 1
fi

# Add YAML header to the R Markdown file
echo "Adding YAML header..."
sed -i '' "1i\\
---\\
title: \"$TITLE\"\\
output: html_document\\
---\\
" "$OUTPUT_RMD"

# Replace ``` {.sourceCode .r} with ```{r}
echo "Fixing code block markers..."
sed -i '' -E 's/^``` \{\.sourceCode \.r\}$/```{r}/g' "$OUTPUT_RMD"

# Fix any doubled code delimiters
echo "Fixing doubled delimiters..."
sed -i '' -E '/^```$/N;s/```\n```/```/g' "$OUTPUT_RMD"

# Cleanup temporary file
rm -f "$TMP_HTML"

echo "R Markdown file created: $OUTPUT_RMD"
