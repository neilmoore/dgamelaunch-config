in DGL/dfdir

1) do what you gotta do to back up the old versions. for now it's manual
backup each user's folder
maybe backup the old df_linux folder template

2) modify df_dl_install.sh to point to the current version to wget and update sed statements as necessary
this creates a df_linux folder that will be used as the template for copying when new accounts are created

in dgamelaunch-config

1) update ./chroot/bin/dwizzell.pl.sh and dwarf-fortress-launcher.sh 

2) update dgamelaunch.config as needed to point to the new version

3) publish via: sudo /home/crawl-dev/crawl-dev/dgamelaunch-config/bin/dgl publish --confirm

