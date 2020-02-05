#!/bin/bash

# This is a script to reset the RIPE RPKI Validator 3 (https://github.com/RIPE-NCC/rpki-validator-3) 
# back to it's oringial state when first installed.  
# The usual reason for this is that there is something wrong with the database and it doesn't match what 
# other validators show (like the one at https://rpki-validator.ripe.net).

# Make sure a command line argument of the ARIN TAL file is specified
if [ -f "$1" ]; then
    FILE=$1
elif [ -f "arin-ripevalidator.tal" ]; then
    FILE="arin-ripevalidator.tal"
else 
    echo "You must specify the location of the ARIN TAL file.  It can be downloaded here: https://www.arin.net/resources/manage/rpki/arin-ripevalidator.tal"
    exit 1
fi

# Make sure this script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Stop the RPKI validator service
echo "Stopping the RPKI validator service."
systemctl stop rpki-validator-3.service 

# Remove all the database files
echo "Deleting all the database files in the /var/lib/rpki-validator-3/db/ directory."
rm /var/lib/rpki-validator-3/db/*.xd

# Start the RPKI validator service
echo "Starting the RPKI validator service."
systemctl start rpki-validator-3.service     

# Wait for 120 seconds to make sure the rpki-validator service comes back up
echo "Waiting for 120 seconds to make sure the rpki-validator service comes back up."
sleep 120

# Upload the ARIN TAL
echo "Uploading the ARIN TAL"
upload-tal.sh $FILE http://localhost:8080/

# Restart RTR service just to make sure all's good
systemctl restart rpki-rtr-server.service

echo "Validator successfully restarted, database removed and ARIN TAL re-added.  Please wait ~15 mins for the validator to download all the ROAs from the RIRs and process them."
