#!/bin/bash

# Function to download images for a specific chapter
download_chapter() {
    local manga_name=$1
    local chapter_number=$2
    local base_url="https://images.mangafreak.me/mangas/$manga_name/${manga_name}_$chapter_number"
    local output_dir="$manga_name/Chapter_$chapter_number"

    mkdir -p "$output_dir"
    mkdir -p "tmp"

    local image_number=1
    while : ; do
        local retry=0
        while [[ $retry -lt 3 ]]; do  # Retry downloading the image up to 3 times
            image_url="${base_url}/${manga_name}_${chapter_number}_${image_number}.jpg"
            tmp_file="tmp/${manga_name}_${chapter_number}_${image_number}.jpg"
            output_file="${output_dir}/${manga_name}_${chapter_number}_${image_number}.jpg"

            # Download the image
            wget -q "$image_url" -O "$tmp_file"
            
            # Check if the download was successful
            if [[ $? -eq 0 && -s $tmp_file ]]; then
                mv "$tmp_file" "$output_file"
                break  # Break the retry loop if the image is downloaded successfully
            else
                ((retry++))
                echo "Retry $retry: Failed to download $image_url"
            fi
        done

        # If all retries failed, break the loop and move to the next process
        if [[ $retry -eq 3 ]]; then
            echo "Error: Failed to download $image_url after multiple attempts. Moving to the next process."
            rm -f "$tmp_file"
            break
        fi

        image_number=$((image_number + 1))
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

# Cleanup the downloaded files and temporary directory
rm -rf "$manga_name"
rm -rf "tmp"
