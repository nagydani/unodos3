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

output_bin "../dos/mode",$2000,$0200

include "unodos.api"

org $2000
	ld a, l;				// test for
	or h;					// args
	jp nz, commands;		// argument found

exit:
	or a;					// clean return
	ret;					// to BASIC

commands:
	ld a, (hl);				// get value at first location
	inc hl;					// second location
	cp '1';					// test for 128
	jr z, c2;				// jump if matched
	cp '4';					// test for 48
	jr nz, exit;			// exit if no match
	ld a, (hl);				// get value at second location
	cp '8';					// test for 48
	jr nz, exit;			// quit if not else ignore subsequent characters

_48_mode:
	ld a, 204;				// clear bit 4 of FLAGS sysvar (48 mode)
	ld (23611), a;			// write it
	ld l, 48;				// force 48 mode
	jr _128_mode;			// jump to set it

c2:
	ld a, (hl);				// get value at second location
	cp '2';					// test for 128
	jr nz, exit;			// exit if no match
	inc hl;					// third location
	ld a, (hl);				// get value
	cp '8';					// test for 128
	jr nz, exit;			// quit if not else ignore subsequent characters
	inc hl;					// fourth location
	ld a, (hl);				// get value
	cp '+';					// test for 128+
	ld l, 16;				// force ROM1, VRAM0, RAM0
	jr nz, _128_mode;		// jump if 128
	ld a, 220;				// set bit 4 of FLAGS sysvar (128 mode)
	ld (23611), a;			// write it (causes a crash with original 128 ROM-1)
	
_128_mode:
	ld bc, 8189;			// +3 paging
	ld a, 4;				// normal memory map
	out (c), a;				// set it
	ld (23399), a;			// write it to BANK678 sysvar (to enable test)
	ld bc, 32765;			// 128 paging
	ld a, l;				// L will contain 16 for 128 mode or 48 for 48 mode
	out (c), a;				// set it
	ld (23388), a;			// write it to BANKM sysvar (to enable test)
	jr exit;				// done
