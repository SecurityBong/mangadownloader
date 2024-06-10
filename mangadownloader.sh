#!/bin/bash

# Function to download images for a specific chapter
download_chapter() {
    local manga_name=$1
    local chapter_number=$2
    local base_url="https://images.mangafreak.me/mangas/$manga_name/${manga_name}_$chapter_number"
    local output_dir="$manga_name/Chapter_$chapter_number"

    mkdir -p "$output_dir"

    local image_number=1
    local retry=0
    while : ; do
        image_url="${base_url}/${manga_name}_${chapter_number}_${image_number}.jpg"
        output_file="${output_dir}/${manga_name}_${chapter_number}_${image_number}.jpg"

        # Download the image
        wget -q "$image_url" -O "$output_file"
        
        # Check if the download was successful
        if [[ $? -eq 0 && -s $output_file ]]; then
            image_number=$((image_number + 1))
            retry=0  # Reset retry counter
        else
            ((retry++))
            echo "Retry $retry: Failed to download $image_url"
            # If all retries failed, break the loop
            if [[ $retry -eq 3 ]]; then
                echo "Error: Failed to download $image_url after multiple attempts. Moving to the next process."
                break
            fi
        fi
    done
}

# Main script
echo "Enter the manga URL (e.g., https://ww1.mangafreak.me/Manga/Iron_Ladies):"
read manga_url

echo "Enter the start chapter number:"
read start_chapter

echo "Enter the end chapter number:"
read end_chapter

# Validate the inputs
if [[ ! $manga_url =~ ^https://ww1.mangafreak.me/Manga/.+$ ]]; then
    echo "Invalid manga URL. Exiting."
    exit 1
fi

if ! [[ $start_chapter =~ ^[0-9]+$ ]] || ! [[ $end_chapter =~ ^[0-9]+$ ]]; then
    echo "Chapter numbers must be integers. Exiting."
    exit 1
fi

if (( start_chapter > end_chapter )); then
    echo "Start chapter number must be less than or equal to end chapter number. Exiting."
    exit 1
fi

# Extract the manga name from the URL
manga_name=$(basename "$manga_url")

# Convert the manga name to lowercase for the image URL
manga_name_lower=$(echo "$manga_name" | tr '[:upper:]' '[:lower:]')

# Loop through the specified range of chapters and download them
for (( chapter=start_chapter; chapter<=end_chapter; chapter++ )); do
    echo "Downloading Chapter $chapter..."
    download_chapter "$manga_name_lower" "$chapter"
done

# Compress the downloaded chapters into a zip file
zip_filename="${manga_name}_Chapters_${start_chapter}_to_${end_chapter}.zip"
zip -r "$zip_filename" "$manga_name"

echo "Download and compression complete. The file is saved as $zip_filename."

# Cleanup the downloaded files
rm -rf "$manga_name"
