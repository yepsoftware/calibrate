#!/bin/bash


#############################################################################
function pressEnter {
#############################################################################
   echo ""
   echo -n "Press enter to continue ..."
   read X
}

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
function ask {
# $1: prompt
# $2: default value to return
   echo "---"
   echo "$1"
   echo "   default: $2"
   echo -n "> "
   read params
   if [[ "${params}" = "" ]];then
      params=$2
   fi
}
#############################################################################

#############################################################################
function do_init {
#############################################################################
   # Date to be used as part of outputfilename:
   dt=$(date +%Y%m%d_%H%M%S)
   
   # ask for directory where to store the output files
   params=""
   outdir_default="/home/pho/Photography/iccProfiles"
   ask "Enter output directory" ${outdir_default}
   outdir=${params}
   
   # ask for the name you want to give to the profile
   nm=""
   while [[ "${nm}" = "" ]];
   do
      echo ""
      echo "Enter a name for your profile (will be suffixed with dt/tm automatically): "
      echo -n "> "
      read nm
   done

   # ask for target color temperature
   ask "Enter target color temperature (K)" "6500"
   tct=${params}

   # ask for target brightness
   ask "Enter target brightness (cd/m2)" "100"
   tb=${params}
 
   # ask for target gamma
   ask "Enter desired gamma" "2.2"
   tgamma=${params}

   # ask for color correction matrix
   ccmx_default="${base}/color_correction_matrix/ColorMunki_Display_Eizo_CS270.ccmx"
   ccmx=""
   echo ""
   echo "Color Correction Matrix for 'screen/measuring device'."
   echo ""
   echo "You can check the below URL for a color correction matrix for your 'screen/measuring device' combination:"
   echo "    https://colorimetercorrections.displaycal.net/"
   echo ""
   echo "If you do not find one or do not want to use one, "
   echo "   reply 'none' (without the quotes) to the prompt below."
   echo ""
   echo "Note: the ccmx file MUST NOT HAVE spaces/commas/brackets/ampersands in the name !!!"
   echo "      rename the file first or create a link if needed !!!"
   echo ""
   ask "Enter filename (full path) of color correction matrix for you measuring device/screen combination" ${ccmx_default}
   if [[ "${params}" != "none" ]];then
      # check if ccmx file exists
      if [[ -f ${params} ]] || [[ -h ${params} ]];then
         ccmx=${params}
      else
         log "***WARNING*** Color correction matrix file [${params}] does not exist, ignoring."
      fi
   fi

   # We have enough info now to create directory and start logging
   targetprefix=${nm}_${dt}_${tct}K_${tb}cdm2_${tgamma}
   if [[ "${ccmx}" != "" ]];then
      targetprefix=${targetprefix}_CCMX
   fi
   targetdir=${outdir}/${targetprefix}
   mkdir -p ${targetdir}    # store all files for this run in this directory
   logfn=${targetdir}/${targetprefix}.log
   touch ${logfn}

   echo "Calibration run of ${dt}" >>${logfn}

   # ask for quality
   ask "Enter taget quality (l=low, m=medium, h=high)" "m"
   tq=${params}

   # set default params

   dispcal_params_default="-v2 -y1 -d1 -q${tq} -t${tct} -b${tb} -g${tgamma} -k0 ${targetdir}/${targetprefix}"
   if [[ "${ccmx}" != "" ]];then
      dispcal_params_default="-X${ccmx} ${dispcal_params_default}"
   fi
   # -v      = verboseA
   # -y1     = LCD IPS panel
   # -d1     = display 1
   # -qm     = quality h=high m=medium
   # -t6500  = color temperature
   # -b100   = brightness cd/m2
   # -g2.2   = gamma
   # -k0     = for max contrast ratio
   # -y1     = for LCD white LED IPS
   # -X<fn>  = color correction matrix

   targen_params_default="-v -g16 -d3 ${targetdir}/${targetprefix}"
   # -v     = verbose
   # -g16   = steps (not sure what that means)
   # -d3    = video RGB

   dispread_params_default="-v -d1 -k ${targetdir}/${targetprefix}.cal ${targetdir}/${targetprefix}"
   # -v      = verbose
   # -d1     = display 1
   # -H      = use high resolution spectrum mode (if available)
   # -k <fn> = calibration file; output from calibration step

   colprof_params_default="-v -q${tq} -as -nc ${targetdir}/${targetprefix}"
   # -v    = verbose
   # -qh   = quality high
   # -as   = algorithm type override ; s =  shaper+matrix
   # -nc   = don't put the input .ti3 data in the profile

   log "defaults after initialization:" 
   log "------------------------------"
   log "dispcal : ${dispcal_params_default}"
   log "targen  : ${targen_params_default}"
   log "dispread: ${dispread_params_default}"
   log "colprof : ${colprof_params_default}"
}

#############################################################################
function do_calibrate {
#############################################################################
   # Calibrate
   #----------

   #dispcal_params_default="-v -d1 -qh -t6500 -b100 -g2.2 ${nm}_${dt}"
   log "RUNNING: dispcal ${dispcal_params}"
   stdbuf -i0 -o0 dispcal ${dispcal_params} 2>&1 | tee -a ${logfn}
   last_argyll_rc=$?
}   
   
#############################################################################
function do_genTargets {   
#############################################################################
   # Generate profiling test targets
   #--------------------------------

   #targen_params_default="-v -g16 -d3 ${targetdir}/${nm}_${dt}"
   log "RUNNING: targen ${targen_params}"
   stdbuf -i0 -o0 targen ${targen_params} 2>&1 | tee -a ${logfn}
   last_argyll_rc=$?
}

#############################################################################
function do_profile {
#############################################################################
   # Profile
   #--------

   #dispread_params_default="-v -d1 -k ${targetdir}/${nm}_${dt}.cal ${targetdir}/${nm}_${dt}"
   log "RUNNING: dispread ${dispread_params}"
   stdbuf -i0 -o0 dispread ${dispread_params} 2>&1 | tee -a ${logfn}
   last_argyll_rc=$?
}

#############################################################################
function do_icc {   
#############################################################################
   # Generate ICC profile
   #---------------------

   #colprof_params_default="-v -qh -as -nc ${targetdir}/${nm}_${dt}"
   log "RUNNING: colprof ${colprof_params}"
   stdbuf -i0 -o0 colprof ${colprof_params} 2>&1 | tee -a ${logfn}
   last_argyll_rc=$?
}   

#############################################################################
function do_menu {
#############################################################################
   while [[ "$stop" != "true" ]];
   do
      #clear
      echo ""
      echo "========"
      echo "= Menu ="
      echo "========"
      echo ""
      if [[ "${targetdir}" != "" ]];then
         echo "All files will be stored in ${targetdir}"
      fi
      echo ""
      echo "0 - Exit"
      echo "1 - Init"
      echo "2 - Calibrate"
      echo "3 - Gen targets"
      echo "4 - Profile"
      echo "5 - Create icc"
      echo ""
      echo -n "Your choice: "
      read choice
      echo ""
      case $choice in
      0)
         stop="true"
         ;;
      1)
         log "----- Start initializing ..." 
         do_init
         log "Initialization finished"
         log "Continue with step 2 after checking for warnings/errors"
         ;;
      2)
         log "----- Start calibration" 
  
         edit_params "Provide parameters for dispcal" "${dispcal_params_default}"
         dispcal_params=${params}
  
         do_calibrate #  > >(tee -a ${logfn}) 2>&1     # process substitution
         log "output: ${targetdir}/${targetprefix}.cal"
         if [[ ${last_argyll_rc} -ne 0 ]];then
            log "***WARNING*** Argyll rc=${last_argyll_rc}, check for errors ! See also ${logfn}"
         fi
         log "Continue with step 3 after checking for warnings/errors"
         ;;
      3)
         log "----- Start to generate target" 
         edit_params "Provide parameters for targen" "${targen_params_default}"
         targen_params=${params}
         do_genTargets # > >(tee -a ${logfn}) 2>&1     # process substitution
         log "input : ${targetdir}/${nm}_${dt}.cal" 
         log "output: ${targetdir}/${nm}_${dt}.ti1"
         if [[ ${last_argyll_rc} -ne 0 ]];then
            log "***WARNING*** Argyll rc=${last_argyll_rc}, check for errors ! See also ${logfn}"
         fi
         log "Continue with step 4 after checking for warnings/errors"
         ;;
      4)
         log "----- Start profiling"
         edit_params "Provide parameters for dispread" "${dispread_params_default}"
         dispread_params=${params}
         do_profile # > >(tee -a ${logfn}) 2>&1     # process substitution
         log "input : ${targetdir}/${nm}_${dt}.ti1"
         log "output: ${targetdir}/${nm}_${dt}.ti3"
         if [[ ${last_argyll_rc} -ne 0 ]];then
            log "***WARNING*** Argyll rc=${last_argyll_rc}, check for errors ! See also ${logfn}"
         fi
         log "Continue with step 5 after checking for warnings/errors"
         ;;
      5)
         log "----- Start icc generation"
         edit_params "Provide parameters for colprof" "${colprof_params_default}"
         colprof_params=${params}
         do_icc  # > >(tee -a ${logfn}) 2>&1     # process substitution
         log "input : ${targetdir}/${nm}_${dt}.ti3"
         log "output: ${targetdir}/${nm}_${dt}.icc"
         if [[ ${last_argyll_rc} -ne 0 ]];then
            log "***WARNING*** Argyll rc=${last_argyll_rc}, check for errors ! See also ${logfn}"
         fi
         ;;
      *)
         echo "***ERROR*** Invalid choice"
         sleep 1
         ;;
      esac
   done
   return
}
   

#############################################################################
# MAIN
#############################################################################

# report return status of second last commant in a pipe ( eg dispcal <parms> | tee out )
set -o pipefail

dt=""
nm="" # name of profile
dir="" # directory where profile will be saved
params=""

# default parameters for argyll commands
dispcal_params_default=""
targen_params_default=""
dispread_params_default=""
colprof_params_default=""
ccmx_default=""

# actual parameters for argyll commands
dispcal_params=""
targen_params=""
dispread_params=""
colprof_params=""
ccmx=""

targetdir_default="" # where all output goes, incl .icc profile
targetdir="" # where all output goes, incl .icc profile
logfn="" # full path of the log file

last_argyll_rc=0  # rc from argyll commands

stop="false"   # when set to 'true', then exit menu
base=$(dirname $0)

do_menu

# EOF
