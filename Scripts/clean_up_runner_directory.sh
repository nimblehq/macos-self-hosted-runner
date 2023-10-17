#!/bin/bash

# Specify the directory path
directory_path="/Users/admin/actions-runner/runner_1"

# Calculate the timestamp for one month ago
one_month_ago=$(date -v -30d +%s)

# Iterate through each folder in the directory
for folder in "$directory_path"/*/; do
    # Check if the folder exists and is a directory
    if [ -d "$folder" ]; then
        # Get the last modification time of the folder in seconds since epoch
        folder_mtime=$(stat -f "%m" "$folder")

        # Compare the modification time with one month ago
        if [ "$folder_mtime" -lt "$one_month_ago" ]; then
            echo "$folder is older than 1 month. Removing."
            rm -rf $folder
        fi
    fi
done
