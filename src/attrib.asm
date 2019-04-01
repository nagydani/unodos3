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

output_bin "../dos/attrib", $2000, $0200

include "unodos.api"

org $2000
L2000:
	ld a, l;				// test for
	or h;					// args
	jr nz, L200C;			// jump if found

L2004:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.

L200C:
	call L206A;
	ld hl, L20C7;
	ld b, 0;
	ld a, (hl);
	and a;
	jr z, L2004;
	cp '-';
	jr nz, L201E;
	jr z, L2024;

L201E:
	cp '+';
	jr z, L2024;
	jr L2004;

L2024:
	ld (L20C4), a;
	inc hl;
	call L204E;
	jr c, L2004;
	call L203F;
	ld a, (hl);
	cp ' ';
	jr nz, L2004;
	inc hl;
	ld bc, (L20C5)
	ld a, '*';
	rst $08;
	defb f_attrib;
	ret;

L203F:
	ld a, (L20C4);
	ld b, 0;
	cp '-';
	jr z, L2049;
	ld b, c;

L2049:
	ld (L20C5), bc;
	ret;

L204E:
	ld c, 0;

L2050:
	ld a, (hl);
	cp ' ';
	ret z;
	ld de, L20B8;
	or ' ';
	ex de, hl;
	push bc;
	ld bc, $000c;
	cpir;
	pop bc;
	scf;
	ret nz;
	ld a, (hl);
	or c;
	ld c, a;
	ex de, hl;
	inc hl;
	jr L2050;

L206A:
	ld de, L20C7;

L206D:
	ld a, (hl);
	and a;
	jr z, L207D;
	cp ':';
	jr z, L207D;
	cp $0d;
	jr z, L207D;
	ldi;    
	jr L206D

L207D:
	xor a;
	ld (de), a;
	ret;

L20B8:
	defb "a", $20;
	defb "r", $80;
	defb "w", $01;
	defb "s", $04;
	defb "h", $02;
	defb "x", $40;
	defb 0;

L20C4:
	defb 0;

L20C5:
	defb 0,0 ;

L20C7:
	defb 0, 0;
