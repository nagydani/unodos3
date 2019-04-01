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

output_bin "../dos/dir", $2000, $0280

include "unodos.api"

org $2000
L2000:
	ld a, l;
	or h;
	jr z, L200F;
	ld bc, $50;
	ld de, L227D;
	call L20EA;
	jr nz, L2019;

L200F:
	ld a, '*'
	ld hl, L227D
	rst $08;
	defb f_getcwd;
	ret c;
	jr L2069;

L2019:
	ld b, 1;
	ld a, '*';
	ld hl, L227D;
	rst $08;
	defb f_open;
	jr c, L2069;
	ld hl, L2272;
	ld (L2271), a;
	rst $08;
	defb f_fstat;
	ld a, (L2271);
	rst $08;
	defb f_close;
	ld b, $0c;
	ld hl, L227D;

L2036:
	ld a, (hl);
	or a;
	jr nz, L203E;
	ld a, ' ';
	jr L2045;

L203E:
	inc hl;
	cp ' ';
	jr nc, L2045;
	ld a, '?';

L2045:
	cp 'a';
	jr c, L204F;
	cp '{';
	jr nc, L204F;
	sub ' ';

L204F:
	rst $10;
	djnz L2036;
	ld a, ' ';
	rst $10;
	ld hl, L2279;
	call L21D5;
	ld a, ' ';
	rst $10;
	ld hl, (L2277);
	call L216B
	ld a, $0d;
	rst $10;
	xor a;
	ret;

L2069:
	ld b, 0;
	ld a, '*';
	ld hl, L227D;
	rst $08;
	defb f_opendir;
	ret c;
	ld (L2271), a;

L2076:
	ld hl, L227D;
	ld a, (L2271);
	rst $08;
	defb f_readdir;
	jr c, L20CE;
	or a;
	jr z, L20CE;
	ld hl, L227D;
	ld c, (hl);
	inc hl;
	ld b, $0c;

L208A:
	ld a, (hl);
	or a;
	jr nz, L2092;
	ld a, ' ';
	jr L2099;

L2092:
	inc hl;
	cp ' ';
	jr nc, L2099;
	ld a, '?';

L2099:
	rst $10;
	djnz L208A
	ld a, ' ';
	inc hl;
	rst $10;
	ld e, (hl);
	inc hl;
	ld d, (hl);
	inc hl;
	ld (L2275), de;
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, c;
	ld (L2277), de;
	and $10;
	jr z, L20BD
	ld hl, L226B;
	call L213D;
	jr L20C0;

L20BD:
	call L21D5;

L20C0:
	ld a, ' ';
	rst $10;
	ld hl, (L2277);
	call L216B;
	ld a, $0d;
	rst $10;
	jr L2076;

L20CE:
	ld a, $0d;
	rst $10;
	ld a, (L2271);
	rst $08;
	defb f_close;
	ret;

L20D7:
	ld a, (hl);
	or a;
	ret z;
	cp $0d;
	ret z;
	cp ':';
	ret;

L20E0:
	call L20D7;
	ret z;
	cp ' ';
	ret nz;
	inc hl;
	jr L20E0;

L20EA:
	ld a, c;
	or b;
	ret z;
	call L20E0;
	jr nz, L20F5;
	xor a
	ld (de), a
	ret;

L20F5:
	push de;

L20F6:
	call L20D7;
	jr z, L2109;
	cp ' ';
	jr z, L2109;
	dec bc;
	ld (de), a;
	ld a, c;
	or b;
	jr z, L2109;
	inc hl;
	inc de;
	jr L20F6;

L2109:
	xor a;
	ld (de), a;
	pop de;
	inc a;
	ret;

L2116:
	call L20D7;
	ret z;
	sub '0';
	ret c;
	cp $0a;
	ccf; 
	ret c;
	push hl;
	ld l, e;
	ld h, d;
	add hl, hl;
	jr c, L213B;
	add hl, hl;
	jr c, L213B;
	add hl, de;
	jr c, L213B;
	add hl, hl;
	jr c, L213B;
	ld d, 0;
	ld e, a;
	add hl, de;
	jr c, L213B;
	ex de, hl;
	pop hl;
	inc hl;
	jr L2116;

L213B:
	pop hl;
	ret;

L213D:
	ld a, (hl);
	or a;
	ret z;
	rst $10;
	inc hl;
	jr L213D;

L2144:
	ld a, c;
	or b;
	ret z;
	ld a, (hl);
	rst $10;
	dec bc;
	inc hl;
	jr L2144;
	ld b, a;
	and $f0;
	rrca;
	rrca;
	rrca;
	rrca;
	call L2163;
	rst $10;
	ld a, b;
	and $0f;
	call L2163;
	rst $10;
	ld a, ' ';
	rst $10;
	ret;

L2163:
	add a, '0';
	cp ':';
	ret c
	add a, 7;
	ret;

L216B:
	ld a, l;
	and $1f;
	call L218E;
	ld a, '.';
	rst $10;
	ld a, l;
	srl h;
	rla;
	rla;
	rla;
	rla;
	and $0f;
	call L218E;
	ld a, '.';
	rst $10;
	ld l, h;
	ld h, 0;
	ld de, $07bc
	add hl, de;
	call L21A1
	ret;

L218E:
	ld b, 0;

L2190:
	sub $0a;
	jr c, L2197;
	inc b;
	jr L2190;

L2197:
	ld c, a;
	ld a, b;
	add a, '0';
	rst $10;
	ld a, c;
	add a, ':';
	rst $10;
	ret;

L21A1:
	ld de, $64;
	xor a;

L21A5:
	sbc hl, de;
	jr c, L21AC;
	inc a;
	jr L21A5

L21AC:
	add hl, de;
	call L218E;
	ld a, l;
	call L218E;
	ret;

L21B5:
	push hl;
	push de;
	ld b, 4;
	ex de, hl;
	or a;

L21BB:
	ld a, (de);
	adc a, (hl);
	ld (de), a;
	inc de;
	inc hl;
	djnz L21BB;
	pop de;
	pop hl;
	ret;

L21C5:
	ld b, 4;
	push hl;
	push de;
	ex de, hl;
	or a;

L21CB:
	ld a, (de);
	sbc a, (hl);
	ld (de), a;
	inc de;
	inc hl;
	djnz L21CB;
	pop de;
	pop hl;
	ret;

L21D5:
	ld b, 0;
	ld de, L2241;
	call L2217;
	ld de, L2245;
	call L2217
	ld de, L2249;
	ld a, b;
	or a;
	jr nz, L21EB;
	inc b;

L21EB:
	call L2217;
	ld de, L224D;
	call L2217;
	ld de, L2251;
	call L2217;
	ld de, L2255;
	call L2217;
	ld de, L2259;
	call L2217;
	ld de, L225D;
	call L2217;
	ld de, L2261;
	call L2217;
	ld b, 2;
	ld de, L2265;

L2217:
	ld c, '/';
	push bc;

L221A:
	inc c;
	call L21C5;
	jr nc, L221A;
	call L21B5;
	ld a, c;
	pop bc;
	ld c, a;
	ld a, b;
	or a;
	jr z, L2230;
	dec a;
	jr z, L2238;

L222D:
	ld a, c;

L222E:
	rst $10;
	ret;

L2230:
	ld a, c;
	cp '0';
	ret z;

L2234:
	ld b, 2;
	jr L222D;

L2238:
	ld a, c;
	cp '0';
	jr nz, L2234;
	ld a, ' ';
	jr L222E;

L2241:
	defb $00, $ca, $9a, $3b;

L2245:
	defb $00, $e1, $f5, $05;

L2249:
	defb $80, $96, $98, $00;

L224D:
	defb $40, $42, $0f, $00;

L2251:
	defb $a0, $86, $01, $00;

L2255:
	defb $10, $27, $00, $00;

L2259:
	defb $e8, $03, $00, $00;

L225D:
	defb $64, $00, $00, $00;

L2261:
	defb $0a, $00, $00, $00;

L2265:
	defb $01, $00, $00, $00;

L2269:
	defb "RH"

L226B:
	defb "<DIR>", 0;

L2271:
	defb 0;

L2272:
	defb 0, 0, 0;

L2275:
	defb 0, 0;

L2277:
	defb 0, 0;

L2279:
	defb 0, 0, 0 ,0;

L227D:
	defb 0, 0, 0;