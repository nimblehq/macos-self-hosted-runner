#!/bin/bash

# Get a list of all keychains
keychain_list=$(security list-keychains)
echo "$keychain_list"

# Filter out keychains with names 'login.keychain-db', 'system.keychain'
for keychain in $keychain_list; do
    if [[ ! $keychain =~ "/login.keychain-db" && ! $keychain =~ "/System.keychain" ]]; then
      # Remove double quotes from the front
      keychain="${keychain#\"}"

      # Remove double quotes from the back
      keychain="${keychain%\"}"

      echo "Deleting keychain: $keychain"
      security delete-keychain "$keychain"
    fi
done

echo "Keychain clean up completed."
