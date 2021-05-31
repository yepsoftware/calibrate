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
