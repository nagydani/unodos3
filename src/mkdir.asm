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

output_bin "../dos/mkdir", $2000, $0200
output_bin "../dos/md", $2000, $0200

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
	ld hl, L2048;
	rst $08;
	defb f_mkdir;
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
	
L2048:
