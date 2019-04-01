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

output_bin "../dos/ssave", $2000, $0460

include "unodos.api"

org $2000
L2000:
	ld a, l;				// test for
	or h;					// args
	jr nz, L2020;			// jump if found

L2004:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.
    
L2020:
	call L202B;

open_file:
	ld a, '*';
	ld b, fa_write | fa_open_al
	ld hl, L2048;
	rst $08;
	defb f_open;
	ret c;
	ld (handle), a;

get_palette:
    ld bc, $bf3b;			// ULAplus™ port
    ld de, $ffbf;			// d = data, e = register
    ld hl, $5b3f;			// mode group register
    ld a, 64;				// mode register
	out (c), a;				// select it
	ld b, d;				// data port
	in a, (c);				// read it
	and a;					// test for zero
	jr z, no_pal;			// no palette
	ld a, 64;				// becomes 63
	
palette_loop:
    dec a;					// next register
    ld b, e;				// register port
    out (c), a;				// select register
    ld b, d;				// data port
    ind;					// out bc, (hl); dec hl; dec b
    and a;					// was that the last register?
    jr nz, palette_loop;	// set all 64 entries
	ld bc, 6976;			// with palette data
	jr write_file;			// write it

no_pal:
	ld bc, 6912;			// without palette data

write_file:
	ld a, (handle);
	ld hl, $4000;
	rst $08;
	defb f_write;
	ret c;
	ld a, (handle);
	rst $08;
	defb f_close;
	ret c;
	or a;
	ret;

L202B:
	ld de, L2048;

L202E:
	ld a, (hl);
	and a;
	jr z, L203E;
	cp ':';
	jr z, L203E;
	cp $0d;
	jr z, L203E;
	ldi;
	jr L202E;

L203E:
	xor a;
	ld (de), a;
	ret;
	
handle:
	defb 0

L2048:



