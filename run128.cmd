echo off
cls
cd emu
zesarux.exe --machine 128k --mmc-file sd_card.mmc --enable-mmc --enable-divmmc --enableulaplus --disablefooter --nowelcomemessage --quickexit --nosplash
