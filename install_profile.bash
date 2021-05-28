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
function do_import {
#############################################################################
   # Before trying to import the profile, first check if the profile is already imported

   colormgr find-profile-by-filename $(basename ${profileNm}) >/dev/null 2>&1
   last_colord_rc=$?

   if [[ ${last_colord_rc} -eq 1 ]];then
      # rc=1 means profile does not yet exist in colord database, so we can import it
      log "Importing profile ${profileNm} ..."
      stdbuf -i0 -o0 colormgr import-profile ${profileNm} 2>&1 | tee -a ${logfn}
      profile_already_exists=false
      last_colord_rc=$?
   else
      log "Profile already exists ... skipping import."
      profile_already_exists=true
      last_colord_rc=0
   fi

   if [[ ${last_colord_rc} -ne 0 ]];then
      return
   fi

   # Find profile ID
   profileId=$(colormgr find-profile-by-filename $(basename ${profileNm}) | grep "^Profile ID:" | cut -f 2 -d ":" | sed -e 's/ //g')
}

#############################################################################
function do_add_profile {
#############################################################################

   #colormgr device-add-profile "${deviceId}" "${profileId}"
   log "Adding profile to device ${deviceId} ..."
   stdbuf -i0 -o0 colormgr device-add-profile "${deviceId}" "${profileId}" 2>&1 | tee -a ${logfn}
   last_colord_rc=$?
}

#############################################################################
function do_dispwin {
#############################################################################

   #dispwin -v -c -I ${profileNm}
   log "Updating color.jcnf file ..."
   stdbuf -i0 -o0 dispwin -v -c -I ${profileNm} 2>&1 | tee -a ${logfn}
   last_colord_rc=$?
}

#############################################################################
function do_check {
#############################################################################

   log ""
   log "----- get-devices -------------------------"
   log ""
   stdbuf -i0 -o0 colormgr get-devices 2>&1 | tee -a ${logfn}

   log ""
   log "----- _ICC_PROFILE ------------------------"
   log ""
   # xprop -display :1 -len 14 -root _ICC_PROFILE
   stdbuf -i0 -o0 xprop -display ${DISPLAY} -len 14 -root _ICC_PROFILE 2>&1 | tee -a ${logfn}

   log ""
   log "----- color.jcnf --------------------------"
   log ""
   stdbuf -i0 -o0 cat  ~/.config/color.jcnf 2>&1 | tee -a ${logfn}

   log ""
   log "----- profile hex dump --------------------"
   log ""
   stdbuf -i0 -o0 hexdump ${profileNm} | head -n 1 2>&1 | tee -a ${logfn}

   log ""

}
#############################################################################
# MAIN
#############################################################################

set -o pipefail

logfn=""

if [[ $# -ne 1 ]];then
   log "Syntax error : $0 <profile_name>"
   exit 1
fi

profileNm=$1
profileId=""

deviceId=""
last_colord_rc=0
last_dispwin_rc=0
profile_already_exists=false     # true=profile is already in colord db / false=is not yet in colord db

# Check if profile exists
if [[ ! -f ${profileNm} ]];then
   log "***ERROR*** profile ${profileNm} does not exist"
   exit 1
fi

logfn=$(dirname ${profileNm})/$(basename ${profileNm} .icc).log
touch ${logfn}
log "###########################################"
log "### I N S T A L L I N G   P R O F I L E ###"
log "###########################################"

do_import ${profileName}
if [[ ${last_colord_rc} -ne 0 ]];then
   log "***ERROR*** Import failed"
   exit 1
else
   log "Import OK"
fi

if [[ ${profile_already_exists} = true ]];then
   # If the profile already existed in the colord db, then assume it is already assigned to a device and skip this step.
   log "Skipping assigning profile to device"
   log "Since the profile was already in the colord db, it is assumed it is also already assinged to the proper device."
else
   # Assign new profile to display device.
   # Do not expect this to work in case there is >1 display.
   deviceId=$(colormgr get-devices-by-kind display | grep "^Device ID:" | tr -s " " | cut -f 2 -d ":" | sed -e 's/^ //')
   do_add_profile
   if [[ ${last_colord_rc} -ne 0 ]];then
      log "***ERROR*** Assigning profile to device failed. profileId=${profileId}, DeviceId=${deviceId}"
      exit 1
   else
      log "Profile assigned to device: OK"
   fi

fi

# Update $HOME/.config/color.jcnf file
do_dispwin

log "#######################################"
log "#### Checking profile installation ####"
log "#######################################"
do_check

log ""
log "Done."

#EOF
