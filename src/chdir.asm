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

output_bin "../dos/chdir",$2000,$0200
output_bin "../dos/cd",$2000,$0200

include "unodos.api"

org $2000
L2000:
	ld a, l;
	or h;
	jr nz, L2018;

L2004:
	xor	a;
	rst $08;
	defb m_getsetdrv;
	rst $30;
	add hl, bc;
	ld hl, L2049;
	push hl;
	rst $08;
	defb f_getcwd;
	pop hl;
	call L203B
	ld a, $0d;
	rst $10
	or a;
	ret;

L2018:
	call L2025;
	ld a, '*';
	ld hl, L2049;
	rst $08;
	defb f_chdir;
	ret c;
	jr L2004;

L2025:
	ld de, L2049

L2028:
	ld a,(hl);
	and a;
	jr z, L2038;
	cp ':';
	jr z, L2038;
	cp $0d;
	jr z, L2038;
	ldi;
	jr L2028;

L2038:
	xor a;
	ld (de), a;
	ret;

L203B:
	call v_pr_str;
	ld a, $0d;
	rst $10;
	ret;

L2049:
	defb 0,0;
