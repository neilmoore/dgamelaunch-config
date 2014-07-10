#! /bin/bash

rm -r df_linux

wget http://www.bay12games.com/dwarves/df_40_01_linux.tar.bz2
tar -xjvf df_40_01_linux.tar.bz2

mv df_linux/command\ line.txt df_linux/command_line.txt
mv df_linux/data/art/font\ license.txt df_linux/data/art/font_license.txt
mv df_linux/file\ changes.txt df_linux/file_changes.txt
mv df_linux/raw/interaction\ examples/ df_linux/raw/interaction_examples/
mv df_linux/release\ notes.txt df_linux/release_notes.txt
mv df_linux/sdl/sdl\ license.txt df_linux/sdl/sdl_license.txt

sed -i 's/SOUND:YES/SOUND:NO/'  df_linux/data/init/init.txt
sed -i 's/VOLUME:255/VOLUME:NO/' df_linux/data/init/init.txt
sed -i 's/PRINT_MODE:2D/PRINT_MODE:TEXT/'  df_linux/data/init/init.txt
sed -i 's/MOUSE:YES/MOUSE:NO/'  df_linux/data/init/init.txt
sed -i 's/INTRO:YES/INTRO:NO/'  df_linux/data/init/init.txt
sed -i 's/WINDOWEDX:80/WINDOWEDX:800/'  df_linux/data/init/init.txt
sed -i 's/WINDOWEDY:25/WINDOWEDY:600/'  df_linux/data/init/init.txt

