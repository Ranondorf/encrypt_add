#!/bin/bash

# Program to add an existing file to GPG encrypted file
# File is added, encrypted, tested and then copied to the final resting location

# Folder where log file and temporary files go.

# Normally called by encrypt_add.sh <Path to GPG file> <Base Folder> <File to Add>

base_folder=""

log_file="encrypt_add_log.txt"

echo "---------------------------------------" >> $log_file
echo "$(date)" >> $log_file


# Check for "rsync"

gpg --help > /dev/null 2>&1

if [ $? -eq 127 ];
   then
       echo "gpg is missing, aborting." >> $log_file
       echo "The gpg program is required to use this script."
       exit 0
fi


new_folder="$2/new_gpg/"
testing_folder="$2/testing_folder/"

mkdir $new_folder
mkdir $testing_folder

# Copy original GPG file to working folder

cp "$1" "$new_folder"
cd "$new_folder"
echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar backup.gpg
tar -xvf backup.tar

# Create new encypted file

cp "$3" .
rm backup.gpg
tar -cf backup.tar *
gpg --symmetric --cipher-algo aes256 -o backup.gpg backup.tar
rm backup.tar

# Decrypt GPG file

mv backup.gpg "$testing_folder"
cd "$testing_folder"
echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar backup.gpg
tar -xvf backup.tar
rm backup.tar

# Redo this section to get rid of the GPG check

for FILE in *
do

diff -s $FILE $new_folder$FILE

if [ $FILE = "backup.gpg" ]; then
        echo "Pass this"
elif [ $? -eq 1 ]; then
        echo "Pass statement should go here"
else
        echo "Unexpected result in comparison, program aborting"
fi


done

cp backup.gpg "$1"

# Delete folders in safe way

rm *
cd ..
cd "$new_folder" 
rm *
cd ..
rmdir $new_folder
rmdir $testing_folder
rm $3
