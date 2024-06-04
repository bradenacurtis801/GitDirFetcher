#!/usr/bin/env sh

download_github_folder() {
    # Initialize variables
    local path=""
    local repo=""
    local branch=""
    local dirname=""
    local rebase=false
    local flat=false
    local token=""
    local max_jobs=20  # Reasonable number of parallel jobs

    # Display help message
    show_help() {
        echo "Usage: download_github_folder -path <path> -repo <repo> -branch <branch> [-dirname <dirname>] [-rebase] [-flat] [-token <token>]"
        echo ""
        echo "Arguments:"
        echo "  -path <path>       The path in the repository to download."
        echo "  -repo <repo>       The repository name."
        echo "  -branch <branch>   The branch of the repository to download from."
        echo "  -dirname <dirname> Optional. The name of the local directory to save the files. Defaults to the basename of the path."
        echo "  -rebase            Optional. If specified, place the contents directly into the specified dirname."
        echo "  -flat              Optional. If specified, place all files directly into the specified dirname without preserving the directory structure."
        echo "  -token <token>     Optional. The GitHub personal access token for accessing private repositories."
        echo "  -h                 Display this help message."
    }

    # Function to clean quotes
    clean_quotes() {
        echo "$1" | sed "s/[‘’]/'/g; s/[“”]/\"/g; s/^'//; s/'$//"
    }

    # Parse arguments
    while [ "$#" -gt 0 ]; do
        case $1 in
            -path) path=$(clean_quotes "$2"); shift ;;
            -repo) repo=$(clean_quotes "$2"); shift ;;
            -branch) branch=$(clean_quotes "$2"); shift ;;
            -dirname) dirname=$(clean_quotes "$2"); shift ;;
            -rebase) rebase=true ;;
            -flat) flat=true ;;
            -token) token=$(clean_quotes "$2"); shift ;;
            -h) show_help; exit 0 ;;
            *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    # Validate required arguments
    if [ -z "$path" ]; then
        echo "Error: -path argument is required."
        show_help
        exit 1
    fi

    if [ -z "$repo" ]; then
        echo "Error: -repo argument is required."
        show_help
        exit 1
    fi

    if [ -z "$branch" ]; then
        echo "Error: -branch argument is required."
        show_help
        exit 1
    fi

    if [ -z "$token" ]; then
        echo "Error: -token argument is required for accessing private repositories."
        show_help
        exit 1
    fi

    # Print cleaned arguments for debugging
    echo "Cleaned Arguments:"
    echo "Path: $path"
    echo "Repo: $repo"
    echo "Branch: $branch"
    echo "Dirname: $dirname"
    echo "Rebase: $rebase"
    echo "Flat: $flat"

    # Set the directory name to the basename of the path if not provided
    if [ -z "$dirname" ]; then
        dirname="$(basename "$path")"
    fi

    # Construct the GitHub API URL
    local url="https://api.github.com/repos/$repo/contents/$path?ref=$branch"
    local base_url="https://api.github.com/repos/$repo/contents"
    local auth_header="Authorization: token $token"

    # Function to download files recursively
    download_files() {
        local folder_url="$1"
        local local_dir="$2"
        
        echo "Fetching URL: $folder_url"

        # Fetch the JSON response from the GitHub API
        local response=$(curl -s -H "$auth_header" "$folder_url")

        # Check if the response is valid JSON
        if ! echo "$response" | jq empty; then
            echo "Error: Invalid JSON response"
            echo "Response: $response"
            return
        fi

        # Loop through the JSON response and handle each item
        echo "$response" | jq -r '.[] | @base64' | while read -r file; do
            _jq() {
                echo "$file" | base64 --decode | jq -r "$1"
            }

            local type=$(_jq '.type')
            local file_path=$(_jq '.path')
            local download_url=$(_jq '.download_url')

            # Determine the destination path
            local destination_path
            if [ "$flat" = true ]; then
                if [ "$rebase" = true ]; then
                    destination_path="$local_dir/$(basename "$file_path")"
                else
                    destination_path="$local_dir/$(basename "$path")/$(basename "$file_path")"
                fi
            elif [ "$rebase" = true ]; then
                destination_path="$local_dir/$(echo "$file_path" | sed "s|^$path/||")"
            else
                destination_path="$local_dir/$file_path"
            fi

            # Check if the item is a file or directory
            if [ "$type" = "file" ]; then
                # Create the directory structure and download the file
                mkdir -p "$(dirname "$destination_path")"
                curl -s -H "$auth_header" "$download_url" -o "$destination_path" &
                echo "Downloaded: $destination_path"
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

    # Function to download a single file
    download_file() {
        local file_url="$1"
        local local_dir="$2"
        
        echo "Fetching URL: $file_url"

        # Fetch the JSON response from the GitHub API
        local response=$(curl -s -H "$auth_header" "$file_url")

        # Check if the response is valid JSON
        if ! echo "$response" | jq empty; then
            echo "Error: Invalid JSON response"
            echo "Response: $response"
            return
        fi

        # Extract the download URL from the JSON response
        local download_url=$(echo "$response" | jq -r '.download_url')
        local file_name=$(basename "$path")
        local destination_path="$local_dir/$file_name"

        # Download the file
        mkdir -p "$(dirname "$destination_path")"
        curl -s -H "$auth_header" "$download_url" -o "$destination_path"
        echo "Downloaded: $destination_path"
    }

    # Check if the path is a file or a directory
    local response=$(curl -s -H "$auth_header" "https://api.github.com/repos/$repo/contents/$path?ref=$branch")
    echo "API Response: $response" # Debugging line
    local path_type=$(echo "$response" | jq -r 'if type=="array" then "dir" elif type=="object" then .type else empty end')

    if [ "$path_type" = "file" ]; then
        download_file "$url" "$dirname"
    elif [ "$path_type" = "dir" ]; then
        download_files "$url" "$dirname"
    else
        echo "Error: Invalid path type. The path must be either a file or a directory."
        exit 1
    fi
}

# Call the function with the provided arguments
download_github_folder "$@"
