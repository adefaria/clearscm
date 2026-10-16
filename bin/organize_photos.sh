#!/bin/bash

DRY_RUN=true
if [[ "$1" == "--execute" ]]; then DRY_RUN=false; fi

# Function to handle moving and converting
process_file() {
    local file=$1
    local ext="${file##*.}"
    
    # Get Date (using exiftool as before)
    DATE_INFO=$(exiftool -s3 -DateTimeOriginal -d "%Y/%m" "$file")
    [ -z "$DATE_INFO" ] && DATE_INFO=$(exiftool -s3 -FileModifyDate -d "%Y/%m" "$file")
    
    YEAR=$(echo "$DATE_INFO" | cut -d'/' -f1)
    MONTH=$(echo "$DATE_INFO" | cut -d'/' -f2)
    TARGET_DIR="$YEAR/$MONTH"

    if [[ -n "$YEAR" ]]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[Dry Run] $file -> $TARGET_DIR/ (Convert HEIC if applicable)"
        else
            mkdir -p "$TARGET_DIR"
            if [[ "$ext" =~ ^(heic|HEIC)$ ]]; then
                # Convert HEIC to JPG in the target folder
                FILENAME_NO_EXT=$(basename "${file%.*}")
                heif-convert "$file" "$TARGET_DIR/$FILENAME_NO_EXT.jpg"
                rm "$file" # Remove original after conversion
            else
                mv "$file" "$TARGET_DIR/"
            fi
        fi
    fi
}

# Run for all targeted files
for f in *.{jpg,JPG,jpeg,JPEG,heic,HEIC}; do
    [ -e "$f" ] || continue
    process_file "$f"
done
