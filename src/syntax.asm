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

output_bin "../dos/syntax", $2000, $0200

include "unodos.api"
include "basic.api"

org $2000
start:
	ld a, l;				// test for
	or h;					// args
	jr nz, found;			// jump if found

not_found:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.
    
found:
	ld a, (hl);				// get character
	cp 'A';					// alpha?
	jr nc, s_letter;		// jump if so

insert_fp:
	push hl;				// save start of args
	ld (ch_add), hl;		// ch_add points to arguments (effectively RST $20)
	res 7, (iy + 1);		// checking syntax
	rst $18;				// BASIC call
	defw $24fb;				// scanning
	set 7, (iy + 1);		// runtime
	pop hl;					// restore start of args

s_letter:
	push hl;				// save start of args
	ld (ch_add), hl;		// ch_add points to arguments (effectively RST $20)
	rst $18;				// BASIC call
	defw expt_1num;			// evaluates expresion
	rst $18;				// BASIC call
	defw find_int2;			// put number on calc stack in BC
	rst $18;				// BASIC call
	defw $1a1b;				// out_num_1 (prints integer in BC)
	pop hl;					// restore start of args

extract_fp:
	rst $18;				// BASIC call
	defw $11a7;				// remove embedded numbers

done:
	or a;
	ret;
