#!/bin/bash

download_github_folder() {
    # Initialize variables
    local path=""
    local repo=""
    local branch=""
    local dirname=""
    local max_jobs=100  # Maximum number of parallel jobs

    # Display help message
    show_help() {
        echo "Usage: download_github_folder -path <path> -repo <repo> -branch <branch> [-dirname <dirname>]"
        echo ""
        echo "Arguments:"
        echo "  -path <path>       The path in the repository to download."
        echo "  -repo <repo>       The repository name."
        echo "  -branch <branch>   The branch of the repository to download from."
        echo "  -dirname <dirname> Optional. The name of the local directory to save the files. Defaults to the basename of the path."
        echo "  -h                 Display this help message."
    }

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -path) path="$2"; shift ;;
            -repo) repo="$2"; shift ;;
            -branch) branch="$2"; shift ;;
            -dirname) dirname="$2"; shift ;;
            -h) show_help; exit 0 ;;
            *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    # Check if path, repo, and branch are provided
    if [ -z "$path" ] || [ -z "$repo" ] || [ -z "$branch" ]; then
        echo "Error: -path, -repo, and -branch arguments are required."
        show_help
        exit 1
    fi

    # Set the directory name to the basename of the path if not provided
    if [ -z "$dirname" ]; then
        dirname="$(basename "$path")"
    fi

    # Construct the GitHub API URL
    local url="https://api.github.com/repos/$repo/contents/$path?ref=$branch"
    local base_url="https://api.github.com/repos/$repo/contents"

    # Function to download files recursively
    download_files() {
        local folder_url="$1"
        local local_dir="$2"

        # Fetch the JSON response from the GitHub API
        local response=$(curl -s "$folder_url")

        # Loop through the JSON response and handle each item
        echo "$response" | jq -r '.[] | @base64' | while read -r file; do
            _jq() {
                echo "$file" | base64 --decode | jq -r "$1"
            }

            local type=$(_jq '.type')
            local file_path=$(_jq '.path')
            local download_url=$(_jq '.download_url')

            # Check if the item is a file or directory
            if [ "$type" = "file" ]; then
                # Create the directory structure and download the file
                mkdir -p "$local_dir/$(dirname "$file_path")"
                curl -s "$download_url" -o "$local_dir/$file_path" &
                echo "Downloaded: $local_dir/$file_path"
            elif [ "$type" = "dir" ]; then
                # If the item is a directory, recursively download its contents
                local dir_url="${base_url}/${file_path}?ref=${branch}"
                download_files "$dir_url" "$local_dir"
            fi

            # Limit the number of parallel jobs
            while (( $(jobs -r | wc -l) >= max_jobs )); do
                sleep 0.1
            done
        done

        # Wait for all background jobs to finish
        wait
    }

    # Start downloading files from the specified URL
    download_files "$url" "$dirname"
}

# Example usage
# download_github_folder -path charts/rancher-monitoring/102.0.1+up40.1.2 -repo rancher/charts -branch dev-v2.9 -dirname my_custom_directory

# Call the function with the provided arguments
download_github_folder "$@"
