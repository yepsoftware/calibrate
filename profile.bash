#!/usr/bin/bash

function do_init{
   dispwin -c    # remove any currently active profile
}


function do_calibrate {
   # Calibrate
   #----------
   # -v      = verbose
   # -d1     = display 1
   # -qh     = quality high
   # -t6500  = color temperature
   # -b100   = brightness cd/m2
   # -g2.2   = gamma
   
   dispcal -v -d1 -qh -t6500 -b100 -g2.2 eizo_CS270_$dt
}   
   
function do_genTargets{   
   # Generate profiling test targets
   #--------------------------------
   # -v     = verbose
   # -g16   = steps (not sure what that means)
   # -d3    = video RGB
   
   targen -v -g16 -d3 eizo_CS270_$dt
}

function do_profile{
   # Profile
   #--------
   # -v      = verbose
   # -d1     = display 1
   # -H      = use high resolution spectrum mode (if available)
   # -k <fn> = calibration file; output from calibration step
   
   dispread -v -d1 -H -k eizo_CS270_$dt.cal eizo_CS270_$dt
}

function do_icc{   
   # Generate ICC profile
   #---------------------
   # -v    = verbose
   # -qh   = quality high
   # -as   = algorithm type override ; s =  shaper+matrix
   # -nc   = don't put the input .ti3 data in the profile
   
   colprof -v -qh -as -nc eizo_CS270_$dt
}   


##############################################################
# MAIN
##############################################################

# Date to be used as part of outputfilename:
dt=$(date +%Y%m%d_%h%m%s)



# EOF
