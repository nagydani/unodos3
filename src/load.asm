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

output_bin "../dos/load", $2000, $0460

include "basic.api"
include "unodos.api"

org $2000
start:
	ld a, l;				// test for
	or h;					// args
	jr nz, init;			// jump if found

error:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.

init:
	call copy_line;

	xor	a;					// drive to A
	rst $08;
	defb m_getsetdrv;

	ld hl, filename;
	ld b, fa_read;

	rst $08;				// UnoDOS call
	defb f_open;			// open the file
	ret c;					// UnoDOS error handler

get_length:
	ld (handle), a;			// get handle
	ld hl, stats;			// buffer for stats
	rst $08;				// UnoDOS call
	defb f_fstat;			// get file stats
	ret c;					// UnoDOS error handler

remove_garbage:
	ld de, (prog);			// PROG to DE
	ld hl, (e_line);		// edit line to HL
	dec hl;					// leave end marker in tact
	rst $18;				// BASIC call
	defw reclaim_1;			// reclaim varibales area

make_space:
	ld bc, (size);			// length of data to BC
	push hl;				// save PROG
	push bc;				// save length
	rst $18;				// BASIC call
	defw make_room;			// make space for data
	
load_data:
	ld a, (handle);			// restore handle
	pop bc;					// restore length
	pop hl;					// restore PROG
	rst $08;				// UnoDOS call
	defb f_read;
	ret c;					// UnoDOS error handler
	ld a, (handle);
	rst $08;				// UnoDOS call
	defb f_close;
	ret c;					// UnoDOS error handler

stabilize_basic:
	ld hl, (e_line);		// get edir line
	dec hl;
	ld (vars), hl;			// set up varaibles
	dec hl;
	ld (datadd), hl;		// set up data add pointer

	or a;
	ret;

copy_line:
	ld de, filename;

copy_loop:
	ld a, (hl);
	and a;
	jr z, line_end;
	cp ':';
	jr z, line_end;
	cp $0d;
	jr z, line_end;
	ldi;
	jr copy_loop;

line_end:
	xor a;
	ld (de), a;
	ret;
	
handle:
	defb 0

stats:
	defb 0;					// drive
	defb 0;					// device
	defb 0;					// file attributes
	defw 0, 0;				// date

size:
	defw 0, 0;				// file size

filename:



