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

output_bin "../dos/dsave", $2000, $0460

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

open_file:
	ld a, '*';
	ld b, fa_write | fa_open_al
	ld hl, buffer;
	rst $08;
	defb f_open;
	ret c;
	ld (handle), a;			// save handle

get_length:
	ld hl, (e_line);		// address of variables
	ld de, (vars);			// start of BASIC
	sbc hl, de;				// get program length
	ex de, hl;				// E_LINE to HL
	ld b, d;				// length to BC
	ld c, e;				//
	
write_file:
	rst $08;
	defb f_write;
	ret c;
	ld a, (handle);
	rst $08;
	defb f_close;
	ret c;
	or a;
	ret;

copy_line:
	ld de, buffer;

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

buffer:
