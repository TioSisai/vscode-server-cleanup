#!/bin/bash

# --- configuration ---
# The root directory of VS Code Server
SERVER_DIR="$HOME/.vscode-server"
echo "VS Code Server root: $SERVER_DIR"
echo "=================================================="

# Check if the root directory exists
if [ ! -d "$SERVER_DIR" ]; then
    echo "Error: the directory was not found: $SERVER_DIR"
    exit 1
fi


# --- Step 1: Clean up old Server versions (cli/servers, code-*, .cli.*.log) ---
CLI_SERVERS_DIR="$SERVER_DIR/cli/servers"

if [ -d "$CLI_SERVERS_DIR" ]; then
    echo "Step 1: Cleaning up old VS Code Server versions..."
    
    # Search for the latest Server directory (sorted by modification time)
    LATEST_SERVER_DIR=$(ls -t -1d "$CLI_SERVERS_DIR"/Stable-* 2>/dev/null | head -n 1)

    if [ -z "$LATEST_SERVER_DIR" ]; then
        echo "  - There is no Server version to clean up."
    else
        # Extract the latest commit hash from the directory name
        LATEST_COMMIT_HASH=$(basename "$LATEST_SERVER_DIR" | sed 's/Stable-//')
        echo "  - Detected latest version hash: $LATEST_COMMIT_HASH"

        # Clean up old versions in cli/servers/
        ls -1d "$CLI_SERVERS_DIR"/Stable-* 2>/dev/null | grep -v "$LATEST_COMMIT_HASH" | while read -r old_server_dir; do
            echo "    -> Deleting old Server package: $(basename "$old_server_dir")"
            rm -rf "$old_server_dir"
        done

        # Clean up old code-* launchers in the root directory
        ls -1 "$SERVER_DIR"/code-* 2>/dev/null | grep -v "$LATEST_COMMIT_HASH" | while read -r old_code_file; do
            echo "    -> Deleting old launcher: $(basename "$old_code_file")"
            rm -f "$old_code_file"
        done

        # Clean up old .cli.*.log files in the root directory
        ls -1 "$SERVER_DIR"/.cli.*.log 2>/dev/null | grep -v "$LATEST_COMMIT_HASH" | while read -r old_log_file; do
            echo "    -> Deleting old log file: $(basename "$old_log_file")"
            rm -f "$old_log_file"
        done
    fi
    echo "✅ Step 1: Servers cleanup completed!"
else
    echo "Step 1: No Server Binaries directory found ($CLI_SERVERS_DIR), skipped."
fi
echo "--------------------------------------------------"


# --- Step 2: Clean up old extension versions (extensions) ---
EXTENSIONS_DIR="$SERVER_DIR/extensions"

if [ -d "$EXTENSIONS_DIR" ]; then
    echo "Step 2: Cleaning up old extension versions..."
    
    # Using awk to identify and delete old version extensions
    ls -1 "$EXTENSIONS_DIR" | \
        sed -E 's/([a-zA-Z0-9.-]+)-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$/\1/' | \
        sort | uniq -c | awk '$1 > 1 {print $2}' | \
    while read -r ext_base_name; do
        echo "  - Found multiple versions of \"$ext_base_name\"..."
        
        # Fetch all versions of the current extension and sort them by version number
        versions=($(ls -1d "$EXTENSIONS_DIR/$ext_base_name"-[0-9]* 2>/dev/null | sort -V))
        
        # Get the latest version to keep
        latest_version="${versions[-1]}"
        echo "    -> Keeping version: $latest_version"
        
        # Delete all old versions except the latest one
        for ((i=0; i<${#versions[@]}-1; i++)); do
            old_version="${versions[$i]}"
            if [ -d "$old_version" ]; then
                echo "    -> Deleting old version: $old_version"
                rm -rf "$old_version"
            fi
        done
    done
    echo "✅ Step 2: Extensions directory cleanup completed!"
else
    echo "Step 2: No extensions directory found ($EXTENSIONS_DIR), skipped."
fi
echo "--------------------------------------------------"

# --- Step 3: Clean up cache and logs in the data directory ---
DATA_DIR="$HOME/.vscode-server/data"
echo "Step 3: Scanning data directory: $DATA_DIR"

if [ ! -d "$DATA_DIR" ]; then
    echo "Error: The data directory was not found: $DATA_DIR"
    exit 1
fi

# Clean up logs directory
if [ -d "$DATA_DIR/logs" ]; then
    echo "  -> Cleaning up logs directory: logs"
    rm -rf "$DATA_DIR/logs"
fi

# Clean up CachedExtensionVSIXs directory
if [ -d "$DATA_DIR/CachedExtensionVSIXs" ]; then
    echo "  -> Cleaning up CachedExtensionVSIXs directory: CachedExtensionVSIXs"
    rm -rf "$DATA_DIR/CachedExtensionVSIXs"
fi

# Clean up connection cache
if [ -d "$DATA_DIR/clp" ]; then
    echo "  -> Cleaning up connection cache: clp"
    rm -rf "$DATA_DIR/clp"
fi

echo "✅ Step 3: Data directory cleanup completed!"
echo "--------------------------------------------------"

echo "✅ Clean up all success!"
