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

output_bin "../dos/copy", $2000, $0200

include "basic.api"
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
	call L208B;
	ld hl, (L2111);
	ld a, l;
	or h;
	jr z, L2004;
	ld hl, L2116;
	ld a, (hl);
	and a;
	jr z, L2004;
	ld hl, (L2111);
	call L20C1;
	jr nz, L2030;
	push hl;
	ld hl, L2116;
	call L20AF;
	pop de;
	call L2083;

L2030:
	ld b, 1;
	ld a, '*';
	ld hl, L2116;
	rst $08;
	defb f_open;
	ret c;
	ld (L2113), a;
	ld b, 6;
	ld a, '*';
	ld hl, (L2111)
	rst $08;
	defb f_open;
	jr c, L206F;
	ld (L2114), a;
	call L20D5;

L204E:
L204F equ L204E + 1
	ld hl, $2200;

L2051:
L2052 equ L2051 + 1
	ld bc, $1000;
	ld a, (L2113);
	push hl;
	push bc;
	rst $08;
	defb f_read;
	pop de;
	pop hl;
	jr c, L206F;
	ld a, (L2114);
	push de;
	rst $08;
	defb f_write;
	pop de;
	jr c, L206F;
	ld a, b;
	cp d;
	jr nz, L206E;
	jr L204E;

L206E:
	or a;

L206F:
	push af;
	ld a, (L2113);
	and a;
	call nz, L2080;
	ld a, (L2114);
	and a;
	call nz, L2080;
	pop af;
	ret;

L2080:
	rst $08;
	defb f_close;
	ret;

L2083:
	ld a, (hl);
	ld (de), a;
	inc hl;
	inc de;
	and a;
	ret z;
	jr L2083;

L208B:
	ld de, L2116;

L208E:
	ld a, (hl);
	and a;
	jr z, L20A2;
	cp ':';
	jr z, L20A2;
	cp $0d;
	jr z, L20A2;
	cp ' ';
	jr z, L20A5;
	ldi;
	jr L208E;

L20A2:
	xor a;
	ld (de), a;
	ret;

L20A5:
	xor a;
	ld (de), a;
	inc de;
	inc hl;
	ld (L2111), de;
	jr L208E;

L20AF:
	xor a;
	ld bc, $80;
	cpir;
	dec hl;

L20B6:
	dec hl;
	ld a, (hl);
	and a;
	jr z, L20BF;
	cp '/';
	jr nz, L20B6;

L20BF:
	inc hl;
	ret;

L20C1:
	xor a;
	ld bc, $80;
	cpir;
	dec hl;
	dec hl;
	ld a, (hl);
	cp '/';
	inc hl;
	ret;

L20D5:
	ld hl, $8000;

L20D8:
	call L20ED;
	jr c, L20E5;
	srl h;
	ld a, h;
	cp $10;
	ret z;
	jr L20D8;

L20E5:
	ld (L2052), hl;
	ex de, hl;
	ld (L204F), hl;
	ret;

L20ED:
	push hl;
	ld de, (stkend);
	add hl, de;
	inc h;
	sbc hl, sp;
	pop hl;
	ret;

L2111:
	defb 0, 0;

L2113:
	defb 0;

L2114:
	defb 0, 0;

L2116:
	defb 0, 0;
