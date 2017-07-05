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

echo "CAManager Copyright (C) U8N WXD"
echo "This program comes with ABSOLUTELY NO WARRANTY"
echo "This is free software, and you are welcome to redistribute it"
echo "under the conditions of the General Public License."
echo "License: <http://www.gnu.org/licenses/>"
echo "For details about licensing and attribution, see the README."
echo
echo "WARNING: This tool requires a specific directory structure, which is"
echo "created by the tool. Do not use it on existing setups or setups which"
echo "have been modified without this tool."
echo

# Reset getopts index variable to 1 so it looks at the first argument
OPTIND=1

# Arguments: The name of the resource directory to find
findResource() {
  name=$1
  # Determine path to directory based on trial-and-error
  # SOURCE: https://stackoverflow.com/questions/59838/check-if-a-directory-exists-in-a-shell-script
  lst[0]=~/"Library/Application Support/com.icloud.cs_temporary/CAManager/$name"
  lst[1]="$(pwd)/$name"
  for path in "${lst[@]}"
  do {
    if [ -d "$path" ]
      then {
        # https://www.linuxjournal.com/content/return-values-bash-functions
        echo "$path"
        return 0;
      }
    fi
  } done
  echo "ERROR: The '$name' directory cannot be found." >&2
  echo "It can be placed in your current working directory." >&2
  exit 1
}

confPath=$(findResource "configs")
libPath=$(findResource "Library")

source $libPath/parseFile.sh
source $libPath/ui.sh
source $libPath/ssss.sh

ssss=False

# Parse arguments
# SOURCE: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":ritnvckmsh" opt; do
  case $opt in
    r)
      operation="makeRoot"
      ;;
    i)
      operation="makeIntermediate"
      ;;
    t)
      operation="signIntermediate"
      ;;
    n)
      operation="makeNew"
      ;;
    v)
      operation="certServer"
      ;;
    c)
      operation="certClient"
      ;;
    k)
      operation="revoke"
      warn "ERROR: The functionality to revoke certificates is incomplete."
      exit 1
      ;;
    m)
      operation="revokeIntermediate"
      warn "ERROR: The functionality to revoke intermediate CAs is incomplete."
      exit 1
      ;;
    s)
      ssss=True
      ;;
    h)
      echo "CAManager Usage: camanager.sh -r -i -t -n -v -c -k -m -h [-s]"
      echo "-r create a new self-signed root CA"
      echo "-i create a new intermediate CA and CSR"
      echo "-t create a new intermediate CA certificate (using root CA)"
      echo "-n create a new client or server key and CSR"
      echo "-v create a new server certificate (using intermediate CA)"
      echo "-c create a new client certificate (using intermediate CA)"
      echo "-k revoke a client or server certificate (using intermediate CA)"
      echo "-m revoke an intermediate CA certificate (using root CA)"
      echo "-s split or combine a key with SSSS"
      echo "-h help"
      exit 0
      ;;
    \?)
      warn "ERROR: Invalid Option -$OPTARG"
      warn "Run ./camanager.sh -h for help"
      exit 1
      ;;
    :)
      warn "ERROR: Option -$OPTARG requires an argument"
      warn "Run ./camanager.sh -h for help"
      exit 1
      ;;
  esac
done

if [ $operation == "makeRoot" ]
then {
  warn "WARNING: This operation should only be performed on an airgapped system"
  update "Creating Directory Structure in $(pwd)"
  mkdir root
  mkdir root/ca
  cd root/ca
  mkdir certs crl newcerts private csr
  touch index.txt
  echo 1000 > serial
  if [ $ssss == True ]
  then {
    update "Generating Root CA Key and Split Key Files"
    key="$(genKey)"
    waitForRename pass
    echo "$key" > pass
    update "Generating Root CA Key encrypted with a random key."
    openssl genrsa -aes256 -out private/ca.key.pem -passout file:pass 4096
    update "Creating Root Certificate."
    openssl req -config $confPath/root.cnf -key private/ca.key.pem -new -x509 \
    -days 3650 -sha512 -extensions v3_ca -out certs/ca.cert.pem \
    -passin file:pass
    update "Generating Split Files"
    split private/ca.key.pem
    rm -P pass
  } else {
    update "Generating Root CA Key. You will need to enter a strong passphrase."
    openssl genrsa -aes256 -out private/ca.key.pem 4096
    update "Creating Root Certificate. You will need to enter the passphrase again."
    openssl req -config $confPath/root.cnf -key private/ca.key.pem -new -x509 \
    -days 3650 -sha512 -extensions v3_ca -out certs/ca.cert.pem
  }
  fi
  end "Root Certificate Generated"
  end "The Root Certificate will be valid for 10 years."
} elif [ $operation == "makeIntermediate" ]
then {
  warn "WARNING: This operation should only be performed on a secured system"
  update "Creating Directory Structure in $(pwd)"
  mkdir root
  prompt "Choose a name to identify this Intermediate CA in the filesystem: "
  read intID
  while [ $intID == "intermediate" ]
  do {
    warn "ERROR: 'intermediate' cannot be used to name the Intermediate CA"
    prompt "Please choose another: "
    read intID
  } done
  mkdir root/$intID
  cd root/$intID
  mkdir certs crl csr newcerts private
  touch index.txt
  echo 1000 > serial
  echo 1000 > crlnumber
  if [ $ssss == True ]
  then {
    update "Generating Intermediate CA Key and Split Key Files"
    key="$(genKey)"
    waitForRename pass
    echo "$key" > pass
    update "Generating Intermediate CA key encrypted with a random key"
    openssl genrsa -aes256 -out private/$intID.key.pem -passout file:pass 4096
    update "Creating CSR."
    openssl req -config $confPath/intermediate.cnf -new -sha512 \
    -key private/$intID.key.pem -out csr/$intID.csr.pem -passin file:pass
    update "Generating Split Files"
    split private/$intID.key.pem
    rm -P pass
  } else {
    update "Generating Intermediate CA Key. You will need to enter a strong passphrase."
    openssl genrsa -aes256 -out private/$intID.key.pem 4096
    update "Creating CSR. You will need to enter the passphrase again."
    openssl req -config $confPath/intermediate.cnf -new -sha512 \
    -key private/$intID.key.pem -out csr/$intID.csr.pem
  }
  fi
  end "Intermediate CA CSR and Key Generation Complete"
  end "The CSR can be found at $(pwd)/csr/$intID.csr.pem."
  instruct "Give the CSR to the Root CA for signing to generate the intermediate\
  certificate. Signing will be done with: camanager.sh -t"
} elif [ $operation == "signIntermediate" ]
then {
  if [ -d root/ca ]
  then {
    prompt "Enter filesystem identifying name of Intermediate CA to sign: "
    read intID
    if [ ! -f root/ca/csr/$intID.csr.pem ]
    then {
      prompt "Copy the Intermediate CA's CSR to $(pwd)/root/ca/csr/$intID.csr.pem and press [ENTER] when complete. "
      read
    } else
    update "Using CSR found at $(pwd)/root/ca/csr/$intID.csr.pem"
    fi
    cd root/ca
    if [ $ssss == True ]
    then {
      update "Combining Splits to Unlock Root CA Key"
      combine private/ca.key.pem
      update "Generating certificate"
      openssl ca -config $confPath/root.cnf -extensions v3_intermediate_ca \
      -days 1825 -notext -md sha512 -in csr/$intID.csr.pem \
      -out certs/$intID.cert.pem
      update "Securely Erasing Decrypted Key File"
      rm -P private/ca.key.pem
    } else  {
      update "Generating certificate. You will need to enter the passphrase for the Root CA key."
      openssl ca -config $confPath/root.cnf -extensions v3_intermediate_ca \
      -days 1825 -notext -md sha512 -in csr/$intID.csr.pem \
      -out certs/$intID.cert.pem
    }
    fi
    update "Generating certificate chain file."
    cat certs/$intID.cert.pem certs/ca.cert.pem > certs/$intID-chain.cert.pem
    end "The Intermediate Certificate will be valid for 5 years."
    end "The certificate file is at $(pwd)/certs/$intID.cert.pem"
    end "The chain file is at $(pwd)/certs/$intID-chain.cert.pem"
    instruct "Send both back to the Intermediate CA who sent you the CSR"
  } else {
    warn "ERROR: The 'root' directory of the Root CA must be in your current
    working directory."
    exit 1
  }
  fi
} elif [ $operation == "makeNew" ]
then {
  if [ -d root ]
  then update "Using the 'root' directory found at $(pwd)/root"
  else {
    update "Creating 'root' directory at $(pwd)/root"
    mkdir root
  }
  fi
  prompt "Choose a name to identify this client/server in the filesystem: "
  read clID
  update "Creating directory structure"
  mkdir root
  mkdir root/$clID
  cd root/$clID
  mkdir certs csr private
  if [ $ssss == True ]
  then {
    update "Generating private key and split files."
    key=$(genKey)
    waitForRename pass
    echo "$key" > pass
    update "Generating private key, encrypted with a random key."
    openssl genrsa -aes256 -out private/$clID.key.pem -passout file:pass 4096
    update "Generating CSR."
    openssl req -config $confPath/intermediate.cnf -key private/$clID.key.pem \
    -new -sha512 -out csr/$clID.csr.pem -passin file:pass
    rm -P pass
  } else {
    update "Generating private key. You will need to choose a strong passphrase."
    openssl genrsa -aes256 -out private/$clID.key.pem 4096
    update "Generating CSR. You will need to enter the passphrase again."
    openssl req -config $confPath/intermediate.cnf -key private/$clID.key.pem \
    -new -sha512 -out csr/$clID.csr.pem
    update "Generating Split Files"
    split private/$clID.key.pem
  }
  fi
  end "Private Key and CSR Generated"
  instruct "Give the CSR at $(pwd)/csr/$clID.csr.pem to the Intermediate CA."
# SOURCE: https://stackoverflow.com/questions/4111475/how-to-do-a-logical-or-operation-in-shell-scripting#4111510
} elif [ $operation == "certServer" ] || [ $operation == "certClient" ]
then {
  if [ $operation == "certServer" ]
  then {
    kind="Server"
    ext="server_cert"
  } else {
    kind="Client"
    ext="usr_cert"
  }
  fi
  prompt "Enter filesystem identifying name of the Intermediate CA: "
  read intID
  if [ -d root/$intID ]
  then {
    prompt "Enter filesystem identifying name of the $kind: "
    read clID
    if [ ! -f root/$intID/csr/$clID.csr.pem ]
    then {
      prompt "Copy the $client's CSR to
      $(pwd)/root/$intID/csr/$clID.csr.pem and press [ENTER] when complete. "
      read
    } else
    update "Using CSR found at $(pwd)/root/$intID/csr/$clID.csr.pem"
    fi
    cd root/$intID
    if [ $ssss == True ]
    then {
      update "Combining Splits to Unlock Intermediate CA ($intID) Key"
      update "Renaming Intermediate CA certificate file temporarily"
      mv certs/$intID.cert.pem certs/intermediate.cert.pem
      update "Combining Splits"
      combine private/intermediate.key.pem
      update "Generating certificate."
      openssl ca -config $confPath/intermediate.cnf -extensions $ext \
      -days 375 -notext -md sha512 -in csr/$clID.csr.pem \
      -out certs/$clID.cert.pem
      update "Securely Erasing Decrypted Key File"
      rm -P private/intermediate.key.pem
      update "Undoing Renaming of Intermediate CA certificate file"
      mv certs/intermediate.cert.pem certs/$intID.cert.pem
    } else {
      update "Renaming Intermediate CA key file temporarily"
      mv private/$intID.key.pem private/intermediate.key.pem
      update "Renaming Intermediate CA certificate file temporarily"
      mv certs/$intID.cert.pem certs/intermediate.cert.pem
      update "Generating certificate. You will need to enter the passphrsae for the Intermediate CA key."
      openssl ca -config $confPath/intermediate.cnf -extensions $ext \
      -days 375 -notext -md sha512 -in csr/$clID.csr.pem \
      -out certs/$clID.cert.pem
      update "Undoing Renaming of Intermediate CA key file"
      mv private/intermediate.key.pem private/$intID.key.pem
      update "Undoing Renaming of Intermediate CA certificate file"
      mv certs/intermediate.cert.pem certs/$intID.cert.pem
    }
    fi
    end "$kind Certificate Generated"
    end "The $kind certificate will be valid for 1 years (+10 days)."
    end "The certificate file is at $(pwd)/certs/$clID.cert.pem"
    instruct "Send it back to the $kind who sent you the CSR"
    instruct "The $kind may also require the chain file at $(pwd)/root/$intID/certs/$intID-chain.cert.pem"
  } else {
    warn "ERROR: The 'root' directory of the Intermediate CA must be in your current
    working directory."
    exit 0
  }
  fi
}
fi
