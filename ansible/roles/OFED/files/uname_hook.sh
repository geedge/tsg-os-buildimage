#!/bin/bash

# Function to print help information
print_help() {
    echo "Usage: $0 --hook | --recover | --help"
    echo
    echo "--hook    : Backs up /usr/bin/uname and replaces it with the uname file from the script directory, setting permissions to 0755."
    echo "--recover : Restores /usr/bin/uname from the backup if /usr/bin/uname-backup exists."
    echo "--help    : Displays this help message."
    exit 0
}

# Check the input argument
if [ "$1" == "--hook" ]; then
    # Argument is --hook
    if [ -f /usr/bin/uname-backup ]; then
        echo "/usr/bin/uname-backup already exists. Skipping backup and replacement."
    else
        if [ -f /usr/bin/uname ]; then
            # Backup the original /usr/bin/uname
            cp /usr/bin/uname /usr/bin/uname-backup
            echo "/usr/bin/uname has been backed up as /usr/bin/uname-backup"
        fi
        # Copy the uname file from the script directory to /usr/bin/ and set permissions to 0755
        cp "$(dirname "$0")/uname" /usr/bin/uname
        chmod 0755 /usr/bin/uname
        echo "The uname file from the script directory has been copied to /usr/bin/uname with permissions set to 0755"
    fi

elif [ "$1" == "--recover" ]; then
    # Argument is --recover
    if [ -f /usr/bin/uname-backup ]; then
        # If backup exists, remove current /usr/bin/uname and restore the backup
        rm -f /usr/bin/uname
        mv /usr/bin/uname-backup /usr/bin/uname
        echo "/usr/bin/uname has been restored from the backup"
    else
        echo "/usr/bin/uname-backup does not exist, cannot restore"
    fi

elif [ "$1" == "--help" ]; then
    # Display help
    print_help
else
   # Invalid argument or no argument
    echo "Invalid or missing argument."
    print_help
fi