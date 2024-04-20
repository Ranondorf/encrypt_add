#!/bin/bash

# Program to add an existing file to GPG encrypted file
# File is added, encrypted, tested and then copied to the final resting location

# Folder where log file and temporary files go.

# Normally called by encrypt_add.sh <Path to GPG file> <Base Folder, temp folders are created here> <Path for file to Add>


abort_flag="False"
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
echo $rule
mkdir $new_folder
mkdir $testing_folder

# Copy original GPG file to working folder

cp "$1" "$new_folder"
old_gpg_file=$(basename "$1")
cd "$new_folder"

echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar $old_gpg_file
if [ $? -eq 0 ]; then
    echo "Password to decrypt file correct"
else
    echo "Incorrect password to decrypt file"
fi
tar -xvf backup.tar

# Create new encypted file

cp "$3" .
rm $old_gpg_file
tar -cf backup.tar *
new_gpg_file=backup_$(date +"%Y%m%d_%H%M%S").gpg
echo "This is the new file $new_gpg_file"
gpg --symmetric --cipher-algo aes256 -o $new_gpg_file backup.tar
if [ $? -eq 0 ]; then
    echo "New encrypted file created"
else
    echo "Issue creating new encrypted file"
fi


rm backup.tar

# Decrypt GPG file

mv $new_gpg_file "$testing_folder"
cd "$testing_folder"
echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar $new_gpg_file
if [ $? -eq 0 ]; then
    echo "New encrypted file decrypted for testing"
else
    echo "Unable to decrypt newly created file"
fi

tar -xvf backup.tar
rm backup.tar

# Redo this section to get rid of the GPG check

for FILE in *
do

if [ $FILE != $new_gpg_file ]; then
    diff -s $FILE $new_folder$FILE
else
    continue
fi

if [ $? -eq 0 ]; then
        :
else
        echo "Unexpected result in comparison, program aborting"
	abort_flag="True"
	break
fi


done

if [ $abort_flag == "False" ]; then
    cp $new_gpg_file "$(dirname "$1")/"
    echo "Copying new file back to source location"
    echo "Operation successful for file add"
fi

# Delete folders in safe way

echo "Deleting temporary files and folders"
rm *
cd ..
cd "$new_folder" 
rm *
cd ..
rmdir $new_folder
rmdir $testing_folder
rm $3
