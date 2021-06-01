
### CALIBRATE ###

20210513: This project has a script for calibating the screen using ArgyllCMS directly from the command line.

Info comes from:
https://www.youtube.com/watch?v=F5diGIqan9E
https://www.argyllcms.com/


See also the webpage at URL : https://sites.google.com/view/digitalpellicule/articles/calibration-with-argyll-from-command-line 

There are 3 scripts:

1) calibrate : to create a icc profile for your display.
2) install_profile: to install the profile created in 1).
3) chack_profile: to check if the profile is properly installed.

1) C A L I B R A T E
--------------------
Directory 'color_correction_matrix' *optionally* contains a correction matrix for your 'screen/measuring' device combination.
See https://colorimetercorrections.displaycal.net/
Download the correction profile for your 'screen/measuring' device combination and put it into the 'color_correction_matrix' directory.
Make sure the name of the file does *NOT* contain spaces, ampersands, commas etc ...
For your convenience, create a link called 'default' to that file:
eg: cd color_correcteion_matrix
    ln -s <name_of_file>.ccmx default
Then run the calibrate script:
The usage is simple: run 
   ./calibrate
and go over the menu option 1, 2, ... , 7, 0 .

At the end the icc file is created in the directory you specified for "output directory".
The profile is however *not* installed yet.

So, after generating the profile, nothing has been changed to you system's color settings yet.
Just running through the menu options does not do any harm to your sytem.


2) I N S T A L L
----------------
There are 2 ways to install the profile:
 a) using the GNOME Settings -> Color option .
 b) by running the ./install_profile script in this project.
    ./install_profile does a bit more than option a):
    it also updates the color.jcnf file (which maps the display's EDID to the profile)

After activating the new profile, it is recommended to log off and log on again to have 
both colord and the X11_ICC_PROFILE atom set correctly.
Without logoff/logon, they were not always set correctly ... maybe cashing thing ... maybe there is a command to refresh them ...

The procedure currently only works when you have only one display.

3) C H E C K
------------
The ./chec_profile script in thsi project displays 
 a) the colord datbase
 b) the color.jcnf file (if it exists)
 c) the X11 _ICC_PROFILE atom (only first 14 bytes)
 d) the first 16 bytes of the profile as known to colord


#EOF
