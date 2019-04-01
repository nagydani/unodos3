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

output_bin "../dos/move", $2000, $0200
output_bin "../dos/ren", $2000, $0200
output_bin "../dos/rename", $2000, $0200

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
	call L2044;
	ld hl, (L20A7);
	ld a, l;
	or h;
	jr z, L2004;
	ld hl, L20AA;
	ld a, (hl);
	and a;
	jr z, L2004;
	ld hl, (L20A7);
	call L207A;
	jr nz, L2030;
	push hl;
	ld hl, L20AA;
	call L2068;
	pop de;
	call L203C;

L2030:
	ld de, (L20A7);
	ld hl, L20AA;
	ld a, '*';
	rst $08;
	defb f_rename;
	ret;

L203C:
	ld a, (hl);
	ld (de), a;
	inc de;
	inc hl;
	and a;
	ret z;
	jr L203C;

L2044:
	ld de, L20AA;

L2047:
	ld a, (hl);
	and a;
	jr z, L205B;
	cp ':';
	jr z, L205B;
	cp $0d;
	jr z, L205B;
	cp ' ';
	jr z, L205E;
	ldi;
	jr L2047;

L205B:
	xor a;
	ld (de), a;
	ret;

L205E:
	xor a;
	ld (de), a;
	inc hl;
	inc de;
	ld (L20A7), de;
	jr L2047;

L2068:
	ld bc, $80;
	xor a;
	cpir;
	dec hl;

L206F:
	dec hl;
	ld a, (hl);
	and a;
	jr z, L2078;
	cp '/';
	jr nz, L206F;

L2078:
	inc hl;
	ret ;

L207A:
	ld bc, $80;
	xor a;
	cpir;
	dec hl;
	dec hl;
	ld a, (hl);
	cp '/';
	inc hl;
	ret;

L20A7:
	defb 0, 0, 0;

L20AA:
	defb 0, 0;
