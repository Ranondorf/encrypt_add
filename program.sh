#!/bin/bash

# Program to add an existing file to GPG encrypted file
# File is added, encrypted, tested and then copied to the final resting location

# Normally called by encrypt_add.sh <Path to GPG file> <Base Folder> <Path for file to add> <Name for output file>

# <Path to GPG file> is the path to the existing GPG file you want to add a new file to
# <Base folder> this is the location where the temporary folders and files are created for this script..this will get cleaned up post run.
# <Path for file to add> The path to the new file that needs to be added
# <Name for output file> The name of the output GPG file without extension.

# Example:
# ./program.sh /mybackups/current/backup5.gpg /home/billybob/ /home/billybob/topsecret.txt backup6
# Result will be a new file called /mybackups/current/backup6.gpg
# Clean up tasks would be around what you did with backup5.gpg and topsecret.txt.

# Note always use absolute paths for the parameters!

abort_flag="False"
log_file="encrypt_add_log.txt"

echo "---------------------------------------" >> $log_file
echo "$(date)" >> $log_file
echo >> $log_file

# Check for "rsync"

gpg --help > /dev/null 2>&1

if [ $? -eq 127 ];
   then
       echo "gpg is missing, aborting." >> $log_file
       echo "The gpg program is required to use this script."
       exit 1
fi

echo
echo "Creating temporary folders:"
echo

parent_folder="$2/encrypt_add_temp_location/"
work_folder="$parent_folder/new_gpg/"
testing_folder="$parent_folder/testing_folder/"

mkdir $parent_folder
echo $parent_folder
mkdir $work_folder
echo $work_folder
mkdir $testing_folder
echo $testing_folder
echo

# Copy original GPG file to working folder


echo "Copying existing file to work folder"


cp "$1" "$work_folder"
old_gpg_file=$(basename "$1")
cd "$work_folder"

echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar $old_gpg_file
if [ $? -eq 0 ]; then
    echo
    echo "Password to decrypt file correct"
else
    echo
    echo "Incorrect password to decrypt file"
fi
echo
echo "Follwing files pulled from archive:"
echo
tar -xvf backup.tar
# Create new encypted file

cp "$3" .
rm $old_gpg_file
tar -cf backup.tar *
echo
echo "Adding new file, $3 to new archive"
echo
new_gpg_file="$4_$(date +"%Y%m%d_%H%M%S").gpg"
echo "This is the new output file $new_gpg_file"
gpg --symmetric --cipher-algo aes256 -o $new_gpg_file backup.tar
if [ $? -eq 0 ]; then
    echo "New encrypted file created"
else
    echo "Issue creating new encrypted file"
fi
echo

rm backup.tar

echo
echo
echo "Beginning verfications phase"

# Decrypt GPG file
mv "$new_gpg_file" "$testing_folder"
cd "$testing_folder"
if [ $? -ne 0 ]; then
    echo "Unable to open $testing_folder, program terminating"
    exit 1
fi


echo RELOADAGENT | gpg-connect-agent
gpg --decrypt --output backup.tar $new_gpg_file
echo
if [ $? -eq 0 ]; then
    echo "New encrypted file decrypted for testing"
else
    echo "Unable to decrypt newly created file"
fi

echo
echo
echo "Extracted the following files:"
echo
tar -xvf backup.tar
rm backup.tar

# Redo this section to get rid of the GPG check

echo
echo
echo "Comparing files in $work_folder and $testing_folder:"
echo
echo
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
    echo
    echo
    echo "Comparison testing passed"
    echo "Copying new outpu file back to source location"
    echo "Operation successful for file add"
fi

# Delete folders in safe way
echo
echo "Deleting temporary files and folders"
# There is a check further back when switching to $testing_folder, to ensure we are in the correct directory before calling rm *
rm *
cd $work_folder
# Check to make sure whe are in the right directory befoer calling rm *
if [ $? -ne 0 ]; then
    echo "Unable to open $work_folder, program terminating"
    exit 1
fi
rm *
cd $parent_folder
rmdir $work_folder
rmdir $testing_folder
cd $2
rmdir $parent_folder
echo "File $3 has been added" >> $log_file
echo "New file $new_gpg_file created and copied back" >> $log_file
echo "Program completed successufully" >> $log_file
echo
echo
