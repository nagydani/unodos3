; UnoDOS 3 - An operating system for the ZX-Uno and divMMC.
; Copyright (c) 2017 Source Solutions, Inc.

;	This file is part of UnoDOS 3.
;
;	UnoDOS 3 is free software: you can redistribute it and/or modify
;	it under the terms of the Lesser GNU General Public License as published by
;	the Free Software Foundation, either version 3 of the License, or
;	(at your option) any later version.
;
;	UnoDOS 3 is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU Lesser General Public License
;	along with UnoDOS 3.  If not, see <http://www.gnu.org/licenses/>.

output_bin "../dos/help",$2000,$1000

include "unodos.api"

org $2000
	ld a, l;				// test for
	or h;					// args
	jp nz, commands;		// argument found

main:
	ld hl, noargs;			// help text

output:
	call v_pr_str;			// print it
	or a;					// clean return
	ret;					// to BASIC

commands:
	inc hl;					// second location
	ld a, (hl);				// get arg value
	and $df;				// make upper case
	ex af, af';				// store it in a'
	dec hl;					// first location
	ld a, (hl);				// get arg value
	and $df;				// make upper case
	cp 'A';					// test for A
	ld hl, attrib;			// help text
	jr z, output;			// assume ATTRIB
	cp 'E';					// test for D
	ld hl, del;				// help text
	jr z, output;			// assume ERASE
	cp 'H';					// test for H
	ld hl, help;			// help text
	jr z, output;			// assume HELP
	cp 'V';					// test for V
	ld hl, ver;				// help text
	jr z, output;			// assume VER
	cp 'C';					// test for C
	jr nz, test_d;			// jump if not
	ex af, af';				// get second arg
	cp 'O';					// test for O
	ld hl, copy;			// help text
	jr z, output;			// assume COPY
	ld hl, chdir;			// else assume CD / CHDIR
	jr output;				// print it

test_d:
	cp 'D';					// test for D
	jr nz, test_m;			// jump if not
	ex af, af';				// get second arg
	cp 'E';					// test for E
	ld hl, del;				// help text
	jr z, output;			// assume DEL
	ld hl, dir;				// else assume DIR
	jr output;				// print it

test_m:
	cp 'M';					// test for M
	jr nz, test_r;			// no command found
	ex af, af';				// get second arg
	cp 'O';					// test for O
	ld hl, move;			// help text
	jr z, output;			// assume MOVE
	ld hl, mkdir;			// else assume MD / MKDIR
	jr output;				// print it

test_r:
	cp 'R';					// test for R
	jr nz, main;			// help text
	ex af, af';				// get second arg
	cp 'E';					// test for E
	ld hl, rename;			// help text
	jr z, output;			// assume RENAME
	ld hl, rmdir;			// else assume RD / RMDIR
	jr output;				// print it


command_table:
	defb "attrib", 0;
	defw attrib;
	defm "bload", 0;
	defw bload;
	defb "bsave", 0;
	defw bsave;
	defb "cd", 0;
	defw chdir;
	defb "chdir", 0;
	defw chdir;
	defb "color", 0;
	defw color;
	defb "copy", 0;
	defw copy;
	defb "del", 0;
	defw del;
	defb "dir", 0;
	defw dir;
	defb "dload", 0;
	defw dload;
	defb "dsave", 0;
	defw dsave;
	defb "echo", 0;
	defw echo;
	defb "erase", 0;
	defw erase;
	defb "help", 0;
	defw help;
	defb "load", 0;
	defw load;
	defb "md", 0;
	defw mkdir;
	defb "mkdir", 0;
	defw mkdir;
	defb "mode", 0;
	defw mode;
	defb "move", 0;
	defw move;
	defb "rd", 0;
	defw rmdir;
	defb "ren", 0;
	defw rename;
	defb "rename", 0;
	defw rename;
	defb "rmdir", 0;
	defw rmdir;
	defb "save", 0;
	defw save;
	defb "sload", 0;
	defw sload;
	defb "ssave", 0;
	defw ver;

noargs:
	defb "ATTRIB  Change file attributes.", $0d;	// 00
	defb "BLOAD   Load binary file.", $0d;			// 01
	defb "BSAVE   Save binary file", $0d;			// 02
	defb "CD      Display/change folder.", $0d;		// 03
	defb "CHDIR   Display/change folder.", $0d;		// 04
	defb "COLOR   Set ULAplus palette.", $0d;		// 05
	defb "COPY    Copy file to new path.", $0d;		// 06
	defb "DEL     Remove a file.", $0d;				// 07
	defb "DIR     List files/subfolders.", $0d;		// 08
	defb "DLOAD   Load DATA.", $0d;					// 09
	defb "DSAVE   Save DATA.", $0d;					// 10
	defb "ERASE   Remove a file.", $0d;				// 11
	defb "HELP    Help info for commands.", $0d;	// 12
	defb "LOAD    Load BASIC program.", $0d;		// 13
	defb "MD      Create a folder.", $0d;			// 14
	defb "MKDIR   Create a folder.", $0d;			// 15
	defb "MODE    Configures system.", $0d;			// 16
	defb "MOVE    Move file/rename folder.", $0d;	// 17
	defb "RD      Remove a folder.", $0d;			// 18
	defb "REN     Rename a file.", $0d;				// 19
	defb "RENAME  Rename a file.", $0d;				// 20
	defb "RMDIR   Remove a folder.", $0d;			// 21
	defb "SAVE    Save BASIC program.", $0d;		// 22
	defb "SLOAD   Load SCREEN$ file.", $0d;			// 23
	defb "SSAVE   Save SCREEN$ file.", $0d;			// 24
	defb "VER     Display UnoDOS version.", $0d;	// 25
	defb 0;											// end marker

attrib:
	defb "Change file attributes.", $0d;			//
	defb $0d;										//
	defb "ATTRIB [+R|-R][+W|-W][+X|-X]", $0d;		//
	defb "       [+A|-A][+S|-S][+H|-H]", $0d;		//
	defb "       [path][filename]", $0d;			//
	defb $0d;										//
	defb "  +   Sets an attribute.", $0d;			//
	defb "  -   Clears an attribute.", $0d;			//
	defb "  R   Read-only file attribute. ", $0d;	//
	defb "  W   Undocumented.", $0d;				//
	defb "  X   Undocumented.", $0d;				//
	defb "  A   Archive file attribute.", $0d;		//
	defb "  S   System file attribute.", $0d;		//
	defb "  H   Hidden file attribute.", $0d;		//
	defb $0d, 0;									//

bload:
	defb "Load binary file.", $0d;					//
	defb $0d;										//
	defb "BLOAD [path][filename],";					//
	defb "      [address],[bytes]";					//
	defb $0d, 0;									//

bsave:
	defb "Save binary file", $0d;					//
	defb $0d;										//
	defb "BSAVE [path][filename],";					//
	defb "      [address],[bytes]";					//
	defb $0d, 0;									//

chdir:
	defb "Display or change folder", $0d;			//
	defb $0d;										//
	defb "CHDIR [path]", $0d;						//
	defb "CHDIR [..]", $0d;							//
	defb "CD [path]", $0d;							//
	defb "CD [..]", $0d;							//
	defb $0d;										//
	defb "  ..   Change to parent folder.", $0d;	//
	defb $0d;										//
	defb "Type CD without parameters to", $0d;		//
	defb "display current drive/folder.", $0d;		//
	defb $0d, 0;									//

copy:
	defb "Copy file to new path.", $0d;				//
	defb $0d;										//
	defb "COPY source target", $0d;					//
	defb $0d;										//
	defb "  source  File to be copied.", $0d;		//
	defb "  target  New [path]filename.", $0d;		//
	defb $0d, 0;									//

del:
	defb "Removes a file.", $0d;					//
	defb $0d;										//
	defb "DEL path", $0d;							//
	defb "ERASE path", $0d;							//
	defb $0d, 0;									//
	
dir:
	defb "List files and subfolders.", $0d;			//
	defb $0d;										//
	defb "DIR [path][filename]", $0d;				//
	defb $0d;										//
	defb "  [path][filename]", $0d;					//
	defb "     Folder and/or file to list.", $0d;	//
	defb $0d, 0;									//

help:
	defb "Help info for UnoDOS commands.  ", $0d;	//
	defb $0d;										//
	defb "HELP [command]", $0d;						//
	defb $0d;										//
	defb "  command  Displays help info", $0d;		//
	defb "           on the command.", $0d;			//
	defb $0d, 0;									//

mkdir:
	defb "Create a folder", $0d;					//
	defb $0d;										//
	defb "MKDIR path", $0d;							//
	defb "MD path", $0d;							//
	defb $0d, 0;									//

move:
	defb "Move file or move/rename folder.", $0d;	//
	defb $0d;										//
	defb "To move a file or folder:", $0d;			//
	defb "MOVE [path]filename target", $0d;			//
	defb $0d;										//
	defb "To rename a folder:", $0d;				//
	defb "MOVE [path]folder1 [path]folder2", $0d;	//
	defb $0d;										//
	defb "  [path]filename The [path]name", $0d;	//
	defb "                 of file/folder", $0d;	//
	defb "                 to move.", $0d;			//
	defb "                 want to move.", $0d;		//
	defb "  target         New [path]name", $0d;	//
	defb "                 of file/folder.", $0d;	//
	defb "  [path]folder1  Folder to be", $0d;		//
	defb "                 renamed.", $0d;			//
	defb "  [path]folder2  New folder", $0d;		//
	defb "                 name.", $0d;				//
	defb $0d, 0;									//

rename:
	defb "Rename a file.", $0d;						//
	defb $0d;										//
	defb "RENAME [path]filename1 filename2", $0d;	//
	defb "REN [path]filename1 filename2", $0d;	//
	defb $0d, 0;									//

rmdir:
	defb "Remove a folder", $0d;					//
	defb $0d;										//
	defb "RMDIR path", $0d;							//
	defb "RD path", $0d;							//
	defb $0d, 0;									//

ver:
	defb "Display the UnoDOS version.", $0d;		//
	defb $0d;										//
	defb "VER", $0d;								//
	defb $0d, 0;									//

	
	
