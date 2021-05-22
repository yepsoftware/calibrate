
### CALIBRATE ###

20210513: This project has a script for calibating the screen using ArgyllCMS directly from the command line.

Info comes from:
https://www.youtube.com/watch?v=F5diGIqan9E
https://www.argyllcms.com/

Directory 'color_correction_matrix' optionally contains a correction matrix for your 'screen/measuring' device combination.
See https://colorimetercorrections.displaycal.net/
Download the correction profile for your 'screen/measuring' device combination and put it into the 'color_correction_matrix' directory.
Make sure the name of the file does *NOT* contain spaces, ampersands, commas etc ...
For your convenience, create a link called 'default' to that file:
eg: cd color_correcteion_matrix
    ln -s <name_of_file>.ccmx default
Then run the calibrate.bash script:
The usage is simple: run 
   ./calibrate.bash
and go over the menu option 1, 2, ... , 7, 0 .

At the end the icc file is created in the directory you specified for "output directory".
The profile is however not installed yet.
You have to do that manually using the Settings -> Color option .
(It could be activated automatically using dispwin, but I prefered not to do that).
So, after generating the profile, nothing has been changed to you system's color settings yet.
Just running through the menu options does not do any harm to your sytem.

After activating the new profile (Settings -> Color), it is recommended to log off and log on again to have 
both colord and the X11_ICC_PROFILE atom set correctly.
Without logoff/logon, they were not always set correctly ... maybe cashing thing ... maybe there is a command to refresh them, but I do not know which.

