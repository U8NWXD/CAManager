# CAManager: Manager for Personal Certificate Authorities
# Copyright (C) 2017 U8N WXD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Generate a 256-bit key and echo it for command substitution or piping
genKey() {
  key=$(openssl rand -base64 256)
  #SOURCE: https://stackoverflow.com/questions/1251999/how-can-i-replace-a-newline-n-using-sed
  tr -d "\n " <<< $key
}

# Generate SKI
# Parameters: fileWithPEMKey
# Requires the PEM Key passphrase be passed over STDIN
ski() {
  local key
  read key
  #SOURCE: https://certificateerror.blogspot.fr/2011/02/how-to-validate-subject-key-identifier.html
  trash=$(openssl rsa -in $1 -pubout -outform der -passin stdin <<< $key | openssl \
  asn1parse -inform der -strparse 19 -out out.der)
  #SOURCE: https://bash.cyberciti.biz/guide/Howto:_convert_string_to_all_uppercase
  cat out.der | openssl dgst -c -sha1 | tr [a-z] [A-Z]
  rm out.der
}

# Split the key found in 'pass' using ssss
# Users will be prompted for parameters, and key files will be created
# Encryption key for PEM Key must be provided via 'pass' file
# Parameters: pathToPEMKey
split() {
  update "Beginning to Split Key"
  path=$1
  local key
  key=$(<pass)
  rm -P pass
  program="CAManager.sh"
  date=$(date -u +"%Y-%m-%d-%H-%M-%S")
  title="SSSS Split"
  prompt "Informal Key Name: "
  read keyName
  #SOURCE: https://stackoverflow.com/questions/18761209/how-to-make-a-bash-function-which-can-read-from-standard-input
  print=$(ski $path <<< $key)
  prompt "Number of Splits to Make: "
  read make
  prompt "Number of Splits to Require for Unlocking: "
  read need

  splits="$(ssss-split -n $make -t $need <<< "$key")"
  update "Splits Generated"

  update "Creating Split Files"
  for (( i = 1; i <= make; i++ ))
  do {
    prompt "Name of Split Holder #$i: "
    read name

    split=$(grep "$i-" <<< "$splits")
    instruct "Choose how you would like your ssss-split encrypted."
    select choice in "GPG-Symmetric" "GPG-Asymmetric"; do
      case $choice in
        GPG-Symmetric )
          encrypted=$(gpg2 --symmetric --armor --cipher-algo AES256 <<< $split)
          break
          ;;
        GPG-Asymmetric )
          prompt "UserID of Key to Encrypt For (Must be Imported to GPG): "
          read uid
          encrypted=$(gpg2 -e -r $uid --armor --cipher-algo AES256 <<< $split)
          break
          ;;
      esac
    done

    #SOURCE: https://stackoverflow.com/questions/40664470/securely-passing-password-through-bash
    splitFile="SSSS-Split$i.txt"
    echo "-----BEGIN HEADER-----" > $splitFile
    echo "Program: $program" >> $splitFile
    echo "Date: $date" >> $splitFile
    echo "Title: SSSS Split #$i" >> $splitFile
    echo "Key Name: $keyName" >> $splitFile
    echo "Key SKI: $print" >> $splitFile
    echo "Splits Made: $make" >> $splitFile
    echo "Splits Needed: $need" >> $splitFile
    echo "Split Holder: $name"  >> $splitFile
    echo "-----END HEADER-----" >> $splitFile

    cat $path >> $splitFile

    echo "-----BEGIN ENCRYPTED KEY-----" >> $splitFile
    echo "$encrypted" >> $splitFile
    echo "-----END ENCRYPTED KEY-----" >> $splitFile

    end "Your Split File is Available At $splitFile"
  }
  done
  end "All Splits Created and Available in $(pwd)"
}

# Users will be prompted for paths to their split files
# Split files will be used to extract encryption key for PEM Key
# Decrypted PEM Key will be placed at the location specified by parameter
# Parameters: pathForPEM
combine() {
  update "Beginning Split Combination for Key Decryption"
  pathForPEM=$1
  update "Getting Initial Configuration from any Split File"
  prompt "Path to a Split File: "
  read initSplitPath
  initConf=$(getSection "HEADER" "$initSplitPath")
  made=$(getLabelledData "Splits Made" "$initConf")
  need=$(getLabelledData "Splits Needed" "$initConf")

  decryptedSplits=""

  update "Initialization Complete. Collecting Each Split File."
  for (( i = 1; i <= $need; i++ ))
  do {
    if [ $i == 1 ]
      then splitPath=$initSplitPath
    else {
      prompt "Enter Path to Another Split File: "
      read splitPath
    }
    fi
    currConf=$(getSection "HEADER" "$splitPath")
    name=$(getLabelledData "Split Holder" "$currConf")
    update "Now decrypting the key for $name. You will need to authenticate."
    encryptedSection=$(getSection "ENCRYPTED KEY" "$splitPath")
    encrypted="$(stripHeader "ENCRYPTED KEY" "$encryptedSection")"
    split=$(gpg2 -d <<< "$encrypted")
    decryptedSplits="$decryptedSplits$split\n"
  }
  done
  update "All splits processed and decrypted. Combining to decrypt key."
  decryptedSplits=$(echo -e "$decryptedSplits")
  #SOURCE: http://www.tldp.org/LDP/abs/html/io-redirection.html
  # ssss-combine sends the key to STDERR, so have to redirect with 2>&1
  key="$(ssss-combine -t $need -q <<< "$decryptedSplits" 2>&1)"
  #SOURCE: https://unix.stackexchange.com/questions/144298/delete-the-last-character-of-a-string-using-string-manipulation-in-shell-script

  while [ -f encryptedPEM.pem ]
  do {
    prompt "Rename the file at $(pwd)/encryptedPEM.pem and press [ENTER] when done."
    read
  }
  done

  while [ -f "$pathForPEM" ]
  do {
    prompt "Rename the file $pathForPEM and press [ENTER] when done."
    read
  }
  done

  getSection "RSA PRIVATE KEY" "$initSplitPath" > encryptedPEM.pem
  #SOURCE: https://support.citrix.com/article/CTX122930
  openssl rsa -in encryptedPEM.pem -out "$pathForPEM" -passin stdin <<< "$key"
  update "Deleting encryptedPEM.pem"
  rm -P encryptedPEM.pem
  end "Splits Combined and Key Decrypted"
}
