#!/bin/bash

# Function to download manga chapters
download_chapters() {
    start="$1"
    end="$2"
    manga_name="$3"

    for ((i=start; i<=end; i++)); do
        chapter_url="https://images.mangafreak.me/downloads/${manga_name}_${i}"
        wget -r -np -nH --cut-dirs=3 --reject="index.html*" "$chapter_url"
    done
}

# Main script
manga_url="$1"

# Extract manga name from URL
manga_name=$(basename "$manga_url")

read -p "Enter the start chapter number: " start_chapter
read -p "Enter the end chapter number: " end_chapter

# Download chapters
download_chapters "$start_chapter" "$end_chapter" "$manga_name"

echo "Download completed."
