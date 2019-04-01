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

output_bin "../dos/run", $2000, $0200

include "unodos.api"

parameters equ $FFFF;			// paramter stack

org $2000
start:
	ld a, l;					// test for
	or h;						// args
	jr nz, args;				// jump if found

no_args:
	scf;						// use UnoDOS error
	ld a, 2;					// syntax error
	ret;						// print it

args:
	call convert_args;			// convert the arguments to the path/filename 
	ld hl, path;				// point to path

chdir:
	ld a, '*';					// use current drive
	ld hl, path;				// path to use
	rst $08;					// UnoDOS call
	defb f_chdir;				// set path
	ret c;						// return with error

load:
	ld a, '*';					// use current drive
	ld b, fa_read | fa_open_ex;	// read file if exists
	ld hl, filename;			// point to file
	rst $08;					// UnoDOS call
	defb f_open;				// open file
	ret c;						// UnoDOS error if not found
	ld (handle), a;				// store handle
	ld hl, 32768;				// destination address
	ld bc, 32768;				// maximum bytes to read
	rst $08;					// UnoDOS call
	defb f_read;				// read bytes
	ret c;						// UnoDOS error if can't read
	ld a, (handle);				// restore handle
	rst $08;					// UnoDOS call
	defb f_close;				// close file
	ret c;						// UnoDOS error if can't close

run:
	rst $18;					// call routine with BASIC ROM paged in
	defw 32768;					// start of app

; return to BASIC must be handled by the app

; subroutines
	
convert_args:
	ld de, folder;				// location to hold string
	ld bc, $0bff;				// LD B, 10; LD C, 255;

first_11:
	ld a, (hl);					// get character
	cp ' ';						// space?
	jr z, params;				// check for parameters if so
	and a;						// test for zero
	jr z, set_end;				// jump if so
	cp ':';						// new statement?
	jr z, set_end;				// jump if so
	cp $0d;						// end of statement?
	jr z, set_end;				// jump if so
	ldi;						// copy byte
	djnz first_11;				// loop until done 

more_args:
	ld a, (hl);					// get character
	cp ' ';						// space?
	jr z, params;				// check for parameters if so
	and a;						// test for zero
	ret z;						// return if so
	cp ':';						// new statement?
	ret z;						// return if so
	cp $0d;						// end of statement?
	ret z;						// return if so
	inc hl;						// next byte
	jr more_args;				// loop until space or end found

params:
	call set_end;				// set end of path
	inc hl;						// skip the space
	ld de, parameters;			// location to copy to

get_params:
	ld a, (hl);					// get character
	and a;						// test for zero
	jr z, param_end;			// jump if so
	cp ':';						// new statement?
	jr z, param_end;			// jump if so
	cp $0d;						// end of statement?
	jr z, param_end;			// jump if so
	ld (de), a;					// write byte
	inc hl;						// next parameter byte
	dec de;						// next stack position
	jr get_params;				// loop until end found

param_end:
	xor a;						// LD A, 0;
	ld (de), a;					// write end marker
	ret;						// done
	
set_end:
	ld a, '/';
	ld (de), a;
	xor a;
	inc de;
	ld (de), a;
	ret;

; variables

handle:
	defb 0;

path:
	defb "/programs/";

folder:
	defb "programname/", 0;

filename:
	defb "unodos.app", 0;
