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
function do_init {
#############################################################################
   # Date to be used as part of outputfilename:
   dt=$(date +%Y%m%d_%H%M%S)

   # ask for directory where to store the output files
   params=""
   targetdir_default="/home/pho/Photography/iccProfiles"
   edit_params "Enter directory where to save profile" ${targetdir_default}
   if [[ "$params" = "" ]];then
      targetdir=${targetdir_default}
   else
      targetdir=${params}
   fi
   
   # ask for the name you want to give to the profile
   while [[ "${nm}" = "" ]];
   do
      echo ""
      echo -n "Enter a name for your profile (will be suffixed with dt/tm automatically): "
      read nm
   done

   targetdir=${targetdir}/${nm}_${dt}
   mkdir -p ${targetdir}    # store all files for this run in this directory

   logfn=${targetdir}/profile.log
   touch ${logfn}

   # set default params

   dispcal_params_default="-v2 -d1 -qm -t6500 -b100 -g2.2 -k0 ${targetdir}/${nm}_${dt}"
   # -v      = verbose
   # -d1     = display 1
   # -qm     = quality h=high m=medium
   # -t6500  = color temperature
   # -b100   = brightness cd/m2
   # -g2.2   = gamma
   # -k0     = for max contrast ratio
   # -y1     = for LCD white LED IPS
   # -X<fn>  = color correction matrix

   targen_params_default="-v -g16 -d3 ${targetdir}/${nm}_${dt}"
   # -v     = verbose
   # -g16   = steps (not sure what that means)
   # -d3    = video RGB

   dispread_params_default="-v -d1 -k ${targetdir}/${nm}_${dt}.cal ${targetdir}/${nm}_${dt}"
   # -v      = verbose
   # -d1     = display 1
   # -H      = use high resolution spectrum mode (if available)
   # -k <fn> = calibration file; output from calibration step

   colprof_params_default="-v -qh -as -nc ${targetdir}/${nm}_${dt}"
   # -v    = verbose
   # -qh   = quality high
   # -as   = algorithm type override ; s =  shaper+matrix
   # -nc   = don't put the input .ti3 data in the profile

   ccmx_default="${base}/color_correction_matrix/ColorMunki_Display_Eizo_CS270.ccmx"
}

#############################################################################
function do_calibrate {
#############################################################################
   # Calibrate
   #----------

   #dispcal_params_default="-v -d1 -qh -t6500 -b100 -g2.2 ${nm}_${dt}"
   echo "RUNNING: dispcal ${dispcal_params}"
   dispcal ${dispcal_params}
   last_argyll_rc=$?
}   
   
#############################################################################
function do_genTargets {   
#############################################################################
   # Generate profiling test targets
   #--------------------------------

   #targen_params_default="-v -g16 -d3 ${targetdir}/${nm}_${dt}"
   echo "RUNNING: targen ${targen_params}"
   targen ${targen_params}
   last_argyll_rc=$?
}

#############################################################################
function do_profile {
#############################################################################
   # Profile
   #--------

   #dispread_params_default="-v -d1 -k ${targetdir}/${nm}_${dt}.cal ${targetdir}/${nm}_${dt}"
   echo "RUNNING: dispread ${dispread_params}"
   dispread ${dispread_params}
   last_argyll_rc=$?
}

#############################################################################
function do_icc {   
#############################################################################
   # Generate ICC profile
   #---------------------

   #colprof_params_default="-v -qh -as -nc ${targetdir}/${nm}_${dt}"
   echo "RUNNING: colprof ${colprof_params}"
   colprof ${colprof_params}
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
  
         echo "***WARNING*** add parameter -y1 ( y 'one' ) for Lenovo legion laptop !"
         edit_params "Provide parameters for dispcal" "${dispcal_params_default}"
         dispcal_params=${params}
  
         echo ""
         echo "You can check the below URL for a color correction matrix for your 'screen/measuring device' combination:"
         echo "    https://colorimetercorrections.displaycal.net/"
         echo ""
         echo "If you do not find one or do not want to use one, "
         echo "   reply 'none' (without the quotes) to the question below."
         echo ""
         echo "Note: the ccmx file MUST NOT HAVE spaces/commas/brackets/ampersands in the name !!!"
         echo "      rename the file first or create a link if needed !!!"
         
         edit_params "Provide ccmx file if you have one, enter 'none' otherwise" "$ccmx_default"

         if [[ "${params}" != "none" ]];then
            # check if ccmx file exists
            if [[ -f ${params} ]] || [[ -h ${params} ]];then
               # Update parameters (add -X)
               dispcal_params="-X ${params} ${dispcal_params}"
            else
               log "***WARNING*** Color correction matrix file [${params}] does not exist, ignoring."
            fi
         fi
         do_calibrate > >(tee -a ${logfn}) 2>&1     # process substitution
         log "output: ${targetdir}/${nm}_${dt}.cal"
         if [[ ${last_argyll_rc} -ne 0 ]];then
            log "***WARNING*** Argyll rc=${last_argyll_rc}, check for errors ! See also ${logfn}"
         fi
         log "Continue with step 3 after checking for warnings/errors"
         ;;
      3)
         log "----- Start to generate target" 
         edit_params "Provide parameters for targen" "${targen_params_default}"
         targen_params=${params}
         do_genTargets > >(tee -a ${logfn}) 2>&1     # process substitution
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
         do_profile > >(tee -a ${logfn}) 2>&1     # process substitution
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
         do_icc > >(tee -a ${logfn}) 2>&1     # process substitution
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
