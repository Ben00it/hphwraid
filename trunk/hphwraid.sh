#!/bin/bash
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#
# This script test HP hardware raid status for XYmon/Hobbit monitoring tool


  ###################################
  # Vars
  #
  PATHTOHPACMD="/usr/sbin/hpacucli" # Define binary (install HP package : hpacucli RPM)
  HPACMDSLOT="sudo ${PATHTOHPACMD} ctrl all show"
  BBHTAG="HPRAID"           # What we put in bb-hosts to trigger this test
  COLUMN=${BBHTAG}          # Name of the column, often same as tag in bb-hosts
  COLOR="red"
  FINALCOLOR="green"
  LOGFILES="${BBTMP}/hphwraid.log"

  ###################################
  # Pre-Run tests
  # Is hpacucli is around ?
  if [ ! -e "${PATHTOHPACMD}" ]; then
      echo -e "\n\r\t/!\ hpacucli binary is not present on your system. It should be in ${PATHTOHPACMD}.\n\r"
      exit 1
  fi

  ###################################
  # Functions
  #
  function CheckTheResult {
    if [ "${1}" = "OK" -o "${1}" = "Ok" ]; then
        COLOR="green"
    else
        COLOR="red"
	FINALCOLOR="red"
    fi
  }
  function SendResult {
    COLOR=${FINALCOLOR}
    MSG=$(cat ${LOGFILES})
    # I sent back the result to the Hobbit Server
    $BB $BBDISP "status ${MACHINE}.${COLUMN} ${COLOR} $(date)

    ${MSG}
    "
  }


  ###################################
  #  Main
  # For each RAID controller found
  while read CTRL; do
    set ${CTRL}
    SLOT=${CTRL}

    # Some vars must be defined in the main()
    HPACMDPHY="sudo ${PATHTOHPACMD} controller slot=${SLOT} physicaldrive all show status"
    HPACMDLOG="sudo ${PATHTOHPACMD} controller slot=${SLOT} logicaldrive all show status"

    # Reset of log file
    cat /dev/null > ${LOGFILES}
    echo "<br /><u>Hardware overview on SLOT ${SLOT}:</u>" >> ${LOGFILES}
 
    # Launch the raid physical hardware test
    while read LINE; do 
      set $LINE
      echo $LINE >> ${LOGFILES}
      CheckTheResult $(echo ${LINE} | awk '{ print $NF }')
    done < <(${HPACMDPHY} | sed -e '/^$/d')

    # Launch the raid physical hardware test
    echo " " >> ${LOGFILES}
    echo "<u>OS overview:</u>" >> ${LOGFILES}
    while read LINE; do
      set $LINE
      echo $LINE >> ${LOGFILES}
      CheckTheResult $(echo ${LINE} | awk '{ print $NF }')
    done < <(${HPACMDLOG} | sed -e '/^$/d')
  done < <(${HPACMDSLOT} | awk '{print $6}' | sed -e '/^$/d')

  # Time to send the result back to Hobbit
  SendResult
 
  # Happy End
  exit 0

