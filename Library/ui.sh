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

# Coloration
black="$(tput setaf 0)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
blue="$(tput setaf 4)"
magenta="$(tput setaf 5)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"

endColor="$(tput sgr0)"

# Coloration Function
# Parameters: color, text
colorOutput() {
  color="$1"
  text="$2"
  if [ $color == "black" ]
    then echo "${black}$text${endColor}"
  elif [ $color == "red" ]
    then echo "${red}$text${endColor}"
  elif [ $color == "green" ]
    then echo "${green}$text${endColor}"
  elif [ $color == "yellow" ]
    then echo "${yellow}$text${endColor}"
  elif [ $color == "blue" ]
    then echo "${blue}$text${endColor}"
  elif [ $color == "magenta" ]
    then echo "${magenta}$text${endColor}"
  elif [ $color == "cyan" ]
    then echo "${cyan}$text${endColor}"
  elif [ $color == "white" ]
    then echo "${white}$text${endColor}"
  else
    echo "ERROR: Unknown Color $color" >&2
    exit 1
  fi
}

# Print status updates to user
# Parameters: text
update() {
  colorOutput "blue" "$1"
}

# Print warnings to user
# Parameters: text
warn() {
  colorOutput "red" "$1"
}

# Print completion notices to user
# Parameters: text
end() {
  colorOutput "green" "$1"
}

# Print instructions to user
# Parameters: text
instruct() {
  colorOutput "magenta" "$1"
}

# Print prompt for information to user
# Parameters: text
prompt() {
  echo -n "${magenta}$1${endColor}"
}
