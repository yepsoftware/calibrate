#!/usr/bin/bash


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
	echo "$(date +'%Y%m%d %H:%M:%S,%N') $*"
}

#############################################################################
function edit_params {
#############################################################################
# $1: Tekst
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
   while [[ "${dir}" = "" ]];
   do
      echo ""
      echo -n "Enter directory where to save profile (default= ~/Documents): "
      read dir
      if [[ "${dir}" = "" ]];then
	      dir="${HOME}/Documents"
      fi
   done
   
   # ask for the name you want to give to the profile
   while [[ "${nm}" = "" ]];
   do
      echo ""
      echo -n "Enter a name for your profile (will be suffixed with dt/tm automatically): "
      read nm
   done

   targetdir=${dir}/${nm}_${dt}
   mkdir -p ${targetdir}    # store all files for this run in this directory

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

   ccmx_default="${base}/color_correction_matrix/i1 DisplayPro, ColorMunki Display & Eizo CS270 (i1 Pro).ccmx"
}


#############################################################################
function do_calibrate {
#############################################################################
   # Calibrate
   #----------
   
   #ccmx="${base}/color_correction_matrix/i1 DisplayPro, ColorMunki Display & Eizo CS270 (i1 Pro).ccmx"
   #dispcal -v -d1 -qh -t6500 -b100 -g2.2 -X$ccmx ${nm}_${dt}

   #dispcal_params_default="-v -d1 -qh -t6500 -b100 -g2.2 ${nm}_${dt}"
   echo "RUNNING: dispcal ${dispcal_params}"
   dispcal ${dispcal_params}
}   
   
#############################################################################
function do_genTargets {   
#############################################################################
   # Generate profiling test targets
   #--------------------------------
   
   #targen_params_default="-v -g16 -d3 ${targetdir}/${nm}_${dt}"
   echo "RUNNING: targen ${targen_params}"
   targen ${targen_params}
}

#############################################################################
function do_profile {
#############################################################################
   # Profile
   #--------
   
   #dispread_params_default="-v -d1 -k ${targetdir}/${nm}_${dt}.cal ${targetdir}/${nm}_${dt}"
   echo "RUNNING: dispread ${dispread_params}"
   dispread ${dispread_params}
}

#############################################################################
function do_icc {   
#############################################################################
   # Generate ICC profile
   #---------------------
   
   #colprof_params_default="-v -qh -as -nc ${targetdir}/${nm}_${dt}"
   echo "RUNNING: colprof ${colprof_params}"
   colprof ${colprof_params}
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
      case $choice in
	 0)
	    stop="true"
	    ;;
	 1)
       log "----- Initializing ..."
	    do_init
       log "Initialization finished"
	    ;;
	 2)
       log "----- Starting calibration"

       echo "***WARNING*** add parameter -y1 ( y 'one' ) for Lenovo legion laptop !"
	    edit_params "Provide parameters for dispcal" "${dispcal_params_default}"
	    dispcal_params=${params}

       echo ""
       echo "You can check the below URL for a color correction matrix for your 'screen/measuring device' combination:"
       echo "    https://colorimetercorrections.displaycal.net/"
       echo "If you do not find one, reply 'none' (without the quotes) to the question below."
	    edit_params "Provide ccmx file if you have one, enter 'none' otherwise" "${base}/color_correction_matrix/i1 DisplayPro, ColorMunki Display & Eizo CS270 (i1 Pro).ccmx"

	    if [[ "${params}" != "none" ]];then
	       # check if file exists
	       if [[ -f "${params}" ]];then
             dispcal_params="-X \"${params}\" ${dispcal_params}"
	       else
	          log "Color correction matrix file deos not exist, ignored."
	       fi
	    fi

	    do_calibrate
       log "output: ${targetdir}/${nm}_${dt}.cal"
       log "Calibration finished, .cal created"
	    ;;
	 3)
       log "----- Starting to generate target"
	    edit_params "Provide parameters for targen" "${targen_params_default}"
	    targen_params=${params}
	    do_genTargets
       log "input : ${targetdir}/${nm}_${dt}.cal"
       log "output: ${targetdir}/${nm}_${dt}.ti1"
       log "Target generated, .ti1 created"
	    ;;
	 4)
       log "----- Starting profiling"
	    edit_params "Provide parameters for dispread" "${dispread_params_default}"
	    dispread_params=${params}
	    do_profile
       log "input : ${targetdir}/${nm}_${dt}.ti1"
       log "output: ${targetdir}/${nm}_${dt}.ti3"
       log "Profiling finished, .ti3 created"
	    ;;
	 5)
       log "----- Starting icc generation"
	    edit_params "Provide parameters for colprof" "${colprof_params_default}"
	    colprof_params=${params}
	    do_icc
       log "input : ${targetdir}/${nm}_${dt}.ti3"
       log "output: ${targetdir}/${nm}_${dt}.icc"
	    log "icc profile created, .icc created"
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

# default parameters
dispcal_params_default=""
targen_params_default=""
dispread_params_default=""
colprof_params_default=""
ccmx_default=""

# actual parameters
dispcal_params=""
targen_params=""
dispread_params=""
colprof_params=A
ccmx=""


stop="false"
base=$(dirname $0)

do_menu

# EOF
