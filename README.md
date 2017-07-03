# CAManager
Manager for Personal Certificate Authorities

## Legal
Copyright (C) 2017 U8N WXD <cs.temporary@icloud.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Usage
```
CAManager Usage: camanager.sh -r -i -t -n -v -c -k -m -h [-s]
-r create a new self-signed root CA
-i create a new intermediate CA and CSR
-t create a new intermediate CA certificate (using root CA)
-n create a new client or server key and CSR
-v create a new server certificate (using intermediate CA)
-c create a new client certificate (using intermediate CA)
-k revoke a client or server certificate (using intermediate CA)
-m revoke an intermediate CA certificate (using root CA)
-s split or combine a key with SSSS
-h help
```

## Work Remaining
### Features to Add
* Encrypt the `pass` file used to pass keys when performing `ssss-split`
* Add stronger password protections like PBKDF2
* Add authenticated encryption
  * HMACs for private keys
  * Digital signatures or HMACs for SSSS splits
### Incomplete Features
* `-k revoke a client or server certificate (using intermediate CA)`: Unwritten
* `-m revoke an intermediate CA certificate (using root CA)`: Unwritten
* `-s split or combine a key with SSSS`: Integraton Untested

## Acknowledgements
### [OpenSSL Certificate Authority Tutorial](https://jamielinux.com/docs/openssl-certificate-authority/index.html)
* Copyright (c) 2013-2015, Jamie Nguyen <j@jamielinux.com>
* Licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
* Disclaimer: No warranties are given
* The configuration files from this tutorial were adapted for use in this
tool and can be found in the `configs` directory
* The procedure (including commands) described in this tutorial was adapted
for camanager.sh
* NOTE: CC BY-SA 4.0 is
[compatible](https://creativecommons.org/share-your-work/licensing-considerations/compatible-licenses)
with GPLv3 when going from CC to GPL
### Other
Much of the code and techniques used in this program came from sites like
[StackOverflow](https://stackoverflow.com). These are noted in comments above
the influenced sections headed by `SOURCE: ` or `Source: `.
