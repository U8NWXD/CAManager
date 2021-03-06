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

# Extract the section bounded by -----BEGIN SOMETHING----- including the bounds
# Returns the section
# Arguments: Text identifying section, The file to search through
# e.g. Text: "HEADER" in "BEGIN HEADER" and "END HEADER"
# e.g. File: with -----BEGIN HEADER----- and -----END HEADER----- within
getSection() {
  name=$1
  path=$2
  capture=False
  section=""
  while read line
  do {
    if [ "$line" == "-----BEGIN $name-----" ]
      then {
        section="$section$line\n"
        capture=True
      } elif [ "$line" == "-----END $name-----" ]
      then {
        section="$section$line\n"
        capture=False
      } elif [ $capture == True ]
      then section="$section$line\n"
    fi
  } done <$path
  # SOURCE: https://stackoverflow.com/questions/23929235/multi-line-string-with-extra-space-preserved-indentation
  echo -e "$section"
}

# Extract the data labelled within a section
# Returns the data
# Arguments: label, text
# e.g. Label: the data\n
getLabelledData() {
  label=$1
  text=$2

  length=${#label}
  startIndex=length+2

  line=$(echo "$text" | grep "$label: ")
  # SOURCE: https://stackoverflow.com/questions/1405611/extracting-first-two-characters-of-a-string-shell-scripting
  data=${line:startIndex}
  #SOURCE: https://stackoverflow.com/questions/15184358/how-to-avoid-bash-command-substitution-to-remove-the-newline-character
  echo "$data"
}

# Remove the headers from a section extracted using getSection()
# Returns the section without the headers
# Arguments: sectionID section
stripHeader() {
  id=$1
  section=$2
  # SOURCE: https://stackoverflow.com/questions/3548453/negative-matching-using-grep-match-lines-that-do-not-contain-foo
  replaced=${section/-----BEGIN $id-----/}
  replaced=${replaced/-----END $id-----/}
  echo "$replaced"
}

# Wait for a file to be renamed/moved/deleted
# Arguments: pathToFile
waitForRename() {
  while [ -f $1 ]
  do {
    prompt "Rename the file $(pwd)/$1 and press [ENTER] when done."
    read
  }
  done
}
