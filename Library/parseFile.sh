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

# Extract the section bounded by -----BEGIN SOMETHING----- including the bounds
# Returns the section
# Arguments: Text identifying section, The file to search through
# e.g. Text: "HEADER" in "BEGIN HEADER" and "END HEADER"
# e.g. File: with -----BEGIN HEADER----- and -----END HEADER----- within
getSection() {
  name=$1
  path=$2
  while read line
  capture=False
  section=""
  do {
    if [ $line == "-----BEGIN $name-----" ]
      then {
        section="$section$line\n"
        capture=True
      } elif [ $line == "-----END $name-----"]
      then {
        section="$section$line\n"
        capture=False
      } elif [ $capture ]
      then section="$section$line\n"
    fi
  } done <$path
  # SOURCE: https://stackoverflow.com/questions/23929235/multi-line-string-with-extra-space-preserved-indentation
  return ${echo -e "$section"}
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

  line=${echo "$text" | grep "$label: "}
  # SOURCE: https://stackoverflow.com/questions/1405611/extracting-first-two-characters-of-a-string-shell-scripting
  data=${line:startIndex}
  return $data
}

# Remove the headers from a section extracted using getSection()
# Returns the section without the headers
# Arguments: section
# Just removes the first and last lines
stripHeader() {
  section=$1
  return ${echo $section | grep -v \-}
}
