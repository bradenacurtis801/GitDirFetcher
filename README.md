# GitFolderDownloader

GitFolderDownloader is a CLI tool (with a future UI) that allows you to download specific directories from GitHub repositories without cloning the entire repository. This is particularly useful for large repositories where downloading the whole repository just to get a specific directory can be time-consuming and space-consuming.

## Features

- Download specific directories from GitHub repositories.
- Preserve the directory structure of the downloaded files.
- Specify the branch from which to download the directories.
- Optionally rename the local directory where files are saved.

## Use Case

When working with large GitHub repositories, you might often find yourself in situations where you need to make changes or retrieve files from a specific directory. Cloning the entire repository can be inefficient, especially if the repository size is in gigabytes. GitFolderDownloader addresses this problem by allowing you to download only the specific directories you need, saving both time and disk space.

## Installation

### Prerequisites

- `curl`: A command-line tool for transferring data with URLs.
- `jq`: A lightweight and flexible command-line JSON processor.

You can install `jq` using your package manager:

- **Debian/Ubuntu**: `sudo apt-get install jq`
- **macOS**: `brew install jq`
- **Windows**: Download from [https://stedolan.github.io/jq/download/](https://stedolan.github.io/jq/download/)

### Usage

```sh
./download_github_folder.sh -path <path> -branch <branch> [-dirname <dirname>] [-rebase] [-flat]
```

### Alternate Usage

```sh
path='PATH-TO-REPO-DIRECTORY'
repo='EXAMPLE/REPO'
branch='BRANCH-NAME'
dirname='DIRECTORY NAME TO CLONE INTO'

curl -L https://raw.githubusercontent.com/bradenacurtis801/GitDirFetcher/main/download_github_folder.sh | sh -s -- -path $path -repo $repo -branch $branch -dirname $dirname -rebase -flat
```

### Arguments
- -path <path>: The path in the repository to download.
- -branch <branch>: The branch of the repository to download from.
- -dirname <dirname>: Optional. The name of the local directory to save the files. Defaults to the basename of the path.
- -rebase: Optional. If specified, place the contents directly into the specified dirname, removing the parent directories but maintaining the file structure of the bottom directory.
- -flat: Optional. If specified, flatten the contents of the bottom directory, removing all subdirectories and placing all files directly into the root the bottom directory.
- -h: Display the help message.

### Example
```sh
./download_github_folder.sh -path charts/rancher-monitoring/102.0.1+up40.1.2 -branch dev-v2.9 -dirname my_custom_directory -rebase
```

This command will download the contents of the specified path from the specified branch into the directory my_custom_directory, preserving the original structure. If -dirname is not provided, it will use the basename of the path (102.0.1+up40.1.2) as the directory name.

### Future Plans
User Interface: A graphical user interface to make it even easier to specify repositories, branches, and paths for download.
Additional Features: Enhancements to support more complex use cases and improve usability.
Contributing
Contributions are welcome! Please open an issue or submit a pull request with your improvements.

License
This project is licensed under the MIT License.
