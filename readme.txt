UnoDOS 3 - A firmware for the ZX-Uno and divMMC.
Copyright (c) 2017 Source Solutions, Inc.

Version 3.0.69105

WARNING
=======
This software may cause data loss.

LEGAL
=====
This file is part of UnoDOS 3.

UnoDOS 3 is free software: you can redistribute it and/or modify
it under the terms of the Lesser GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

UnoDOS 3 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with UnoDOS 3.  If not, see <http://www.gnu.org/licenses/>.

CLEAN INSTALL (divMMC)
======================
1) Set write enable on the EEPROM.
2) Install the firmware on your divMMC using the flashmmc.tap file.
3) Set write protect on the EEPROM.
4) Copy the CMD, SYS, and TMP folders to the root folder of your SD card.

TEST INSTALL (divMMC)
=====================
If you have an existing esxDOS system installed you can perform a test install.
1) Copy the CMD folder to the root folder of your SD card.
2) Copy the contents of the SYS folder to the SYS folder on your SD card.
   You can safely overwrite the esxDOS version of the third party files.
3) Copy flashmmc.tap to your SD card.
4) Set write protect on the EEPROM.
5) From esxDOS, mount the flashmmc.tap file and load the flash utility.
6) Press ENTER, then after installation hold SPACE and press RESET.

UPGRADE (divMMC)
================
If you have an existing esxDOS system installed you can convet it to UnoDOS.
1) Copy the CMD folder to the root folder of your SD card.
2) Copy the contents of the SYS folder to the SYS folder on your SD card.
   You can safely overwrite the esxDOS version of the third party files.
3) Copy flashmmc.tap to your SD card.
4) Set write enable on the EEPROM.
5) From esxDOS, mount the flashmmc.tap file and load the flash utility.
6) Set write protect on the EEPROM.

UPGRADE (ZX-Uno)
================
1) Copy the CMD folder to the root folder of your SD card.
2) Copy the contents of the SYS folder to the SYS folder on your SD card.
   You can safely overwrite the esxDOS version of the third party files.
3) Rename UNODOS.ROM to ESXDOS.ZX1 and copy it to the root of your SD card.
4) From the BIOS, select "Upgrade ESXDOS for ZX".
5) Restart your machine.

UPGRADE (ZEsarUX)
=================
1) Copy the CMD, SYS, and TMP folders to the root folder of your SD image.
2) Rename unodos.rom to esxmmc085.rom and copy it to the ZEsarUX folder.

BOOT MODE
=========
By default, UnoDOS 3 performs a silent boot. To display information, hold
down SHIFT during boot.

COMMANDS
========
Enter .HELP for a list of commands.

Currently, the .HELP command does not cover the ZX-Uno commands (enter withour
parameters for inline help), or the following commands:

.COLOR r,v       - Set ULAplus palette register (r) to value (v).
                   For example, COLOR 64, 0 switches off ULAplus.

.MODE            - Force compatibility mode where m = 48 or 128.
				   
.LOAD f          - Load a BASIC program from filename (f).
.SAVE f          - Save a BASIC program to filename (f).

.BLOAD f,a,b     - Binary load (b) bytes to address (a) from filename (f).
.BSAVE f,a,b     - Binary save (b) bytes from address (a) to filename (f).

.DLOAD f         - Load program variables and arrays from filename (f).
.DSAVE f         - Save program variables and arrays to filename (f).

.SLOAD f         - Load a normal (6912 bytes) or ULAplus (6976 bytss)
                   headerless screen with filename (f).
.SSAVE f         - Save a normal (6912 bytes) or ULAplus (6976 bytss)
                   headerless screen with filename (f).

ZX-UNO COMMANDS
===============
The following commands that are not required to use UnoDOS 3 are included:

.BACKUP          - Backup flash / ROM set
.JOY             - Configure joysticks (D9 port / keyboard)
.KEYB            - Configure keyboard
.RESTORE         - Restore flash / ROM set
.UNOCFG          - Configure ZX-Uno

API REFERENCES
==============
The following application programming interface documents are included:

BASIC.API        - Interface to routines in the BASIC ROM used by UnoDOS.
UNODOS.API       - A superset of the esxDOS 0.8.5 API.
ZX-UNO.API       - Interface to the ZX-Uno hardware.

THIRD PARTY SOFTWARE
====================
The following external files that are not part of UnoDOS 3 are included in this
distribution:

AT28C64B EEPROM tool by Velesoft
================================
AT28C64B.TAP     - Write enable/protect EEPROM

Betadisk emulation by Pheonix
=============================
BETADISK.SYS     - Betadisk emulator
TRDOS-5.04T      - Betadisk firmware
CONFIG/TRDOS.CFG - Betadisk config file
VDISK            - Betadisk mount command

Tape emulation by Phoenix
=========================
TAPEIN           - Mount tape for reading
TAPEOUT          - Mount tape for writing

Snapshot support by Baze
========================
SNAPLOAD         - Load Z80 and SNA snapshots

NMI browser by ub880d
=====================
NMI.SYS          - File browser

Note: NMI browser cannot display ULAplus images or run BASIC programs.
