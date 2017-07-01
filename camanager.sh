# CAManager: Manager for Personal Certificate Authorities
# Copyright (C) 2017 U8N WXD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "CAManager Copyright (C) U8N WXD"
echo "This program comes with ABSOLUTELY NO WARRANTY"
echo "This is free software, and you are welcome to redistribute it"
echo "under the conditions of the Affero General Public License."
echo "License: <http://www.gnu.org/licenses/>"
echo "For details about licensing and attribution, see the README."
echo
echo "WARNING: This tool requires a specific directory structure, which is"
echo "created by the tool. Do not use it on existing setups or setups which"
echo "have been modified without this tool."
echo

# Reset getopts index variable to 1 so it looks at the first argument
OPTIND=1

# Determine path to data directory based on trial-and-error
# SOURCE: https://stackoverflow.com/questions/59838/check-if-a-directory-exists-in-a-shell-script
if [ -d ~/"Library/Application Support/com.icloud.cs_temporary/CAManager/configs" ]
  then confPath=~/"Library/Application Support/com.icloud.cs_temporary/CAManager/configs"
elif [ -d "configs" ]
  then confPath="configs"
else {
  echo "ERROR: The 'configs' directory cannot be found."
  echo "It can be placed in your current working directory."
  exit 1
}
fi

# Parse arguments
# SOURCE: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":l:e:bsnca:h" opt; do
  case $opt in
    r)
      operation="makeRoot"
      ;;
    i)
      operation="makeIntermediate"
      ;;
    t)
      operation="signIntermediate"
    c)
      operation="makeClient"
      ;;
    v)
      operation="makeServer"
      ;;
    s)
      operation="makeCert"
      ;;
    k)
      operation="revoke"
      ;;
    h)
      echo "CAManager Usage: camanager.sh -r -i -c -v -s -k -h"
      echo "-r create a new self-signed root CA"
      echo "-i create a new intermediate CA and CSR"
      echo "-t create a new intermediate CA certificate (using root CA)"
      echo "-c create a new client key and CSR"
      echo "-v create a new server key and CSR"
      echo "-s create a new client or server certificate (using intermediate CA)"
      echo "-k revoke a client or server certificate (using intermediate CA)"
      echo "-m revoke an intermediate CA certificate (using root CA)"
      echo "-h help"
      exit 0
      ;;
    \?)
      echo "Invalid Option: -$OPTARG"
      echo "Run ./camanager.sh -h for help"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      echo "Run ./camanager.sh -h for help"
      exit 1
      ;;
  esac
done

if [ $operation != "makeRoot" && !( -d ../root ) ]
then echo "ERROR: This tool needs to be run in the 'root' directory it created."
fi

if [ $operation == "makeRoot" ]
then {
  echo "WARNING: This operation should only be performed on an airgapped system"
  echo "Creating Directory Structure in ${pwd}"
  mkdir root
  mkdir root/ca
  cd root/ca
  mkdir certs crl newcerts private csr
  touch index.txt
  echo 1000 > serial
  echo "Generating Root CA Key. You will need to enter a strong passphrase."
  openssl genrsa -aes256 -out private/ca.key.pem 4096
  echo "Creating Root Certificate. You will need to enter the passphrase again."
  openssl req -config $confPath/root.cnf -key private/ca.key.pem -new -x509 \
  -days 3650 -sha512 -extensions v3_ca -out certs/ca.cert.pem
  echo "The root certificate will be valid for 10 years."
} elif [ $operation == "makeIntermediate"]
then {
  echo "WARNING: This operation should only be performed on a secured system"
  echo "Creating Directory Structure in ${pwd}"
  mkdir root
  mkdir root/intermediate
  cd root/intermediate
  mkdir certs crl csr newcerts private
  touch index.txt
  echo 1000 > serial
  echo 1000 > crlnumber
  echo "Generating Intermediate CA Key. \
  You will need to enter a strong passphrase."
  openssl genrsa -aes256 -out private/intermediate.key.pem 4096
  echo "Creating CSR. You will need to enter the passphrase again."
  openssl req -config $confPath/intermediate.cnf -new -sha512 \
  -key private/intermediate.key.pem -out csr/intermediate.csr.pem
  echo "The CSR can be found at ${pwd}/csr/intermediate.csr.pem."
  echo "Give the CSR to the Root CA for signing to generate the intermediate \
  certificate. Signing will be done with: camanager.sh -t"
}
fi
