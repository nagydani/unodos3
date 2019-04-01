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

output_bin "../dos/sload", $2000, $0460

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
	ld a, '*';
	ld b, fa_read | fa_open_ex;
	ld hl, L2048;
	rst $08;
	defb f_open;
	ret c;
	ld (handle), a;
	ld hl, $4000;
	ld bc, 6977;
	rst $08;
	defb f_read;
	ret c;
	push bc;				// save bytes read
	ld a, (handle);
	rst $08;
	defb f_close;
	pop bc;					// restore bytes read
	ret c;
	ld a, c;				// low byte of count to ANY
	ld bc, $bf3b;			// register port
	ld e, 64;				// mode register
	out (c), e;				// select it
	ld b, $ff;				// data port
	and a;					// test for zero (no palette data)
	jr nz, set_palette;		// set palette if not
	out (c), a;				// switch off ULAplus™.
	jr done;				// and exit

set_palette:
	ld a, 1;				// enable
	out (c), a;				// ULAplus™.
    ld de, $00bf;			// d = data, e = register
    ld hl, $5b3f;			// mode group register
    ld a, 64;				// becomes 63

palette_loop:
    dec a;					// next register
    ld b, e;				// register port
    out (c), a;				// select register
    ld b, d;				// data port
    outd;					// out bc, (hl); dec hl; dec b
    and a;					// was that the last register?
    jr nz, palette_loop;	// set all 64 entries

done:
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



