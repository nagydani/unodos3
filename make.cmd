cd src
echo PROGRAMS
zcl app.asm
echo UNIT-TEST
zcl test.asm
echo BASIC
zcl busra.asm
echo ROM
zcl unodos.asm
echo SYS
zcl errors.asm
zcl tape.asm
echo CMD
zcl attrib.asm
zcl bload.asm
zcl bsave.asm
zcl chdir.asm
zcl color.asm
zcl copy.asm
zcl del.asm
zcl delete.asm
zcl dir.asm
zcl dload.asm
zcl dsave.asm
zcl echo.asm
zcl help.asm
zcl load.asm
zcl mkdir.asm
zcl mode.asm
zcl move.asm
zcl rmdir.asm
zcl run.asm
zcl save.asm
zcl sload.asm
zcl ssave.asm
zcl ver.asm
echo UNO
zcl backup.asm
zcl joy.asm
zcl keyb.asm
zcl restore.asm
zcl unocfg.asm

echo DOS
copy /b unodos-0.sys+unodos-1.sys "..\dos\unodos.sys"
echo TAP
copy /b loader.tap + unodos.tap "..\flashmmc.tap"
copy /y ..\unodos.rom "..\emu\esxmmc085.rom"
echo EXT
cd ..\ext
REM zcl play.asm
copy sd_card.mmc ..\emu\sd_card.mmc
echo MMC
cd ..\emu
imdisk -a -m G: -b 2048b -o rem -f sd_card.mmc
rd /s /q g:dos
rd /s /q g:bas
rd /s /q g:scr
cd ..
xcopy dos g:\dos\ /e
xcopy bas g:\bas\ /e
xcopy scr g:\scr\ /e
xcopy programs g:\programs\ /e
pause
imdisk -d -m G:
cd emu
raw2hdf sd_card.mmc sd_card.hdf
