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

output_bin "../dos/delete", $2000, $0200

include "unodos.api"
include "basic.api"

org $2000
	ld (ch_add), hl;		// ch-add points to arguments
	rst $18;				// call BASIC
	defw $18;				// get-char
	rst $18;				// call BASIC
	defw expt_2num;			// expect two comma-separated numbers
	ld (bc), a;				// POKE
	or a;					//
	ret;					//

;	ld b, 0;				// parameter index
;	rst $18;				// call BASIC
;	defw $18;				// get-char
;	rst $18;				// call BASIC
;	defw expt_2num;			// expect two comma-separated numbers
;	call get_line;			// get a valid line number
;	call next_one;			// find address
;	push de;				// stack it
;	call get_line;			// get next line number
;	pop de;					// unstack address
;	and a;					// clear carry flag
;	sbc hl, de;				// check line range
;	jr nc, error;			// error if not valid
;	add hl, de;				// restore line number
;	ex de, hl;				// swap pointers
;	rst $18;				// call BASIC
;	defw reclaim_1;			// delete lines
;	or a;					// return to
;	ret;					// BASIC
;
;get_line:
;	rst $18;				// call BASIC
;	defw find_line;			// get line
;	ld h, b;				// BC
;	ld l, c;				// to HL
;	rst $18;				// call BASIC
;	defw line_addr;			// get line address
;	ret z;					// return if valid
;
;error:
;	rst $08;				// else
;	defb $09;				// invalid argument
;	
;find_line:
;	rst $18;				// call BASIC
;	defw find_int2;			// line number to BC
;	ld a, b;				// high byte to A
;	cp $40;					// less than 16384
;	ret c;					// return if so
;	rst $08;				// else
;	defb $0a;				// integer out of range
