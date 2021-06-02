#!/bin/bash

#############################################################################
function log {
#############################################################################
   if [[ "${logfn}" != "" ]] && [[ -f "${logfn}" ]];then
      # output to logfile + stdout
      echo "$(date +'%Y%m%d %H:%M:%S,%N') $*" | tee -a ${logfn}
   else
      # logfile is not yet there, only output to stdout
      echo "$(date +'%Y%m%d %H:%M:%S,%N') $*"
   fi
}

#############################################################################
function edit_params {
#############################################################################
# $1: Text
# $2: Default parameters
   echo ""
   echo "$1"
   echo "Default parameters are:"
   echo "$2"
   echo "Your edits or hit enter to accept default:"
   read params
   if [[ "${params}" = "" ]];then
      params=$2
   fi
}

#############################################################################
function do_check {
#############################################################################

   log ""
   log "----- get-devices -------------------------"
   log ""
   colormgr get-devices

   log ""
   log "----- color.jcnf --------------------------"
   log ""
   if [[ -f ~/.config/color.jcnf ]];then
      cat  ~/.config/color.jcnf
   else
      log "~/.config/color.jcnf does not exist."
   fi

   log ""
   log "----- _ICC_PROFILE ------------------------"
   log ""
   xprop -display ${DISPLAY} -len 14 -root _ICC_PROFILE

   log ""
   log "----- profile hex dump --------------------"
   log ""
   hexdump ${profileNm} | head -n 1

   log ""
   log "----- reporting on display status ---------"
   log ""
   echo "Do you want to report on the display status ?"
   echo "A measuring device is needed for this!"
   echo -n "Run report y/N ? "
   read answer
   if [[ "$answer" = "y" ]];then
      dispcal_params_default="-y1 -d1 -r"
      edit_params "Provide parameters for dispcal" "${dispcal_params_default}"
      dispcal_params=${params}
      log "RUNNING: dispcal ${dispcal_params}"
      dispcal ${dispcal_params}
   fi
   log ""

}
#############################################################################
# MAIN
#############################################################################

set -o pipefail

# I do not expect this to work when you have >1 display device:
deviceId=$(colormgr get-devices-by-kind display | grep "^Device ID:" | tr -s " " | cut -f 2 -d ":" | sed -e 's/^ //')
profileNm=$(colormgr device-get-default-profile "${deviceId}" | grep "^Filename:" | tr -s " " | cut -f 2 -d ":" | sed -e 's/^ //')
profileId=$(colormgr device-get-default-profile "${deviceId}" | grep "^Profile ID:" | tr -s " " | cut -f 2 -d ":" | sed -e 's/^ //')


# Check if profile exists
if [[ ! -f ${profileNm} ]];then
   log "***ERROR*** profile ${profileNm} does not exist"
   exit 1
fi

log "#######################################"
log "#### Checking profile installation ####"
log "#######################################"
do_check

log ""
log "Done."

#EOF
