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

output_bin "../dos/joy", $2000, $0c50

include "basic.api"
include "unodos.api"
include "zx-uno.api"

org $2000
init:
	push hl;
	call main;
	pop af
	or a;					// reset carry: clean exit
	ld b, h;
	ld c, l;
	ret;

main:
	call enter_ix;
	ld a, (ix + 5);
	or (ix + 4);
	jr nz, L2019;
	call L23AD;
	jr L2024;

L2019: 
	ld l, (ix + 4);
	ld h, (ix + 5);
	push hl;
	call L2029;
	pop af;

L2024:
	ld l, 0;
	pop ix;
	ret;

L2029:
	call enter_ix;
	dec sp;
	ld a, 6;
	ld bc, zxunoaddr;
	out (c), a;
	ld a, $fd;
	in a, ($3b);
	and $0f;
	ld c, a;
	ld a, $fd;
	in a, ($3b);
	rlca;
	rlca;
	rlca;
	rlca;
	and $0f;
	and $0f;
	ld b, a;

L2048:
	ld e, (ix + 4)
	ld d, (ix + 5)
	ld a, (de);
	ld h, a;
	or a;
	jp z, L2193;
	sub $0d;
	jp z, L2193;
	ld a, h;
	sub ':';
	jp z, L2193;
	inc de;
	ld l, e;
	ld a, h;
	sub ' ';
	jr nz, L206E;
	ld (ix + 4), l;
	ld (ix + 5), d;
	jr L2048;

L206E:
	ld a, h;
	sub '-';
	jp nz, L218E;
	ld (ix + 4), l;
	ld (ix + 5), d;
	ld e, (ix + 4);
	ld d, (ix + 5);
	ld a, (de);
	ld l, a;
	inc de;
	ld a, l;
	sub 'k';
	jp nz, L210C;
	ld (ix + 4), e;
	ld (ix + 5), d;
	ld a, c;
	and $08;
	ld c, a;
	ld e, (ix + 4);
	ld d, (ix + 5);
	ld a, (de);
	ld l, a;
	sub '1';
	jr z, L20B8;
	ld a, l;
	cp '2';
	jr z, L20BC;
	cp 'c';
	jr z, L20C2;
	cp 'd';
	jr z, L20D2;
	cp 'f';
	jr z, L20C6;
	sub 'k';
	jr nz, L20CC;
	set 0, c;
	jr L20D2;

L20B8:
	set 1, c;
	jr L20D2;

L20BC:
	ld a, c;
	or $03;
	ld c, a;
	jr L20D2;

L20C2:
	set 2, c;
	jr L20D2;

L20C6:
	ld a, c;
	or $05;
	ld c, a;
	jr L20D2;

L20CC:
	call usage;
	jp L21A2;

L20D2:
	inc (ix + 4);
	jr nz, L20DA;
	inc (ix + 5);

L20DA:
	ld e, (ix + 4);
	ld d, (ix + 5);
	ld a, (de);
	ld (ix - 1), a;
	inc de;
	ld a, (ix - 1);
	sub '1';
	jr nz, L20F7;
	set 3, c;
	ld (ix + 4), e;
	ld (ix + 5), d;
	jp L2048;

L20F7:
	ld a, (ix - 1);
	sub '0';
	jp nz, L2048;
	ld a, c;
	and $07;
	ld c, a;
	ld (ix + 4), e;
	ld (ix + 5), d;
	jp L2048;

L210C:
	ld a, l;
	sub 'j';
	jp nz, L2048;
	ld (ix + 4), e;
	ld (ix + 5), d;
	ld a, b;
	and $08;
	ld b, a;
	ld e, (ix + 4);
	ld d, (ix + 5);
	ld a, (de);
	ld h, a;
	sub '1';
	jr z, L2141;
	ld a, h;
	cp '2';
	jr z, L2145;
	cp 'c';
	jr z, L214B;
	cp 'd';
	jr z, L215A;
	cp 'f';
	jr z, L214F;
	sub 'k';
	jr nz, L2155;
	set 0, b;
	jr L215A;

L2141:
	set 1, b;
	jr L215A;

L2145:
	ld a, b;
	or $03;
	ld b, a;
	jr L215A;

L214B:
	set 2, b;
	jr L215A;
	
L214F:
	ld a, b;
	or $05;
	ld b, a;
	jr L215A;

L2155:
	call usage;
	jr L21A2;

L215A:
	inc (ix + 4);
	jr nz, L2162;
	inc (ix + 5);

L2162:
	ld e, (ix + 4);
	ld d, (ix + 5);
	ld a, (de);
	ld l, a;
	inc de;
	ld a, l;
	sub '1';
	jr nz, L217B;
	set 3, b;
	ld (ix + 4), e;
	ld (ix + 5), d;
	jp L2048;

L217B:
	ld a, l;
	sub '0';
	jp nz, L2048;
	ld a, b;
	and $07;
	ld b, a;
	ld (ix + 4), e;
	ld (ix + 5), d;
	jp L2048;

L218E:
	call usage;
	jr L21A2;

L2193:
	ld a, b;
	rlca;
	rlca;
	rlca;
	rlca;
	and $f0;
	or c;
	push bc;
	ld bc, zxunodata;
	out (c), a;
	pop bc;

L21A2:
	inc sp;
	pop ix;
	ret;
	
usage:
	ld hl, usage_str;
	push hl;
	call puts;
	pop af;
	ret;

usage_str:
	defb "Configures/tests protocols for", $0d;
	defb "both the keyboard built-in", $0d;
	defb "joystick and the DB9 joystick.", $0d, $0d;
	defb "Usage: JOYSTICK [-kAx] [-jBx]", $0d;
	defb "  where A,B can be:", $0d;
	defb "    d: Disabled", $0d;
	defb "    k: Kempston", $0d;
	defb "    1: Sinclair port 1", $0d;
	defb "    2: Sinclair port 2", $0d;
	defb "    c: Cursor/Protek/AGF", $0d;
	defb "    f: Fuller", $0d;
	defb "  where x can be:", $0d;
	defb "    0: disable autofire", $0d;
	defb "    1: enable autofire", $0d;
	defb "    other/none: keep setting", $0d;
	defb "  No arguments: interactive mode", $0d, $0d;
	defb "Example: JOYSTICK -kc0 -jk1", $0d;
	defb "Sets Cursor, no autofire for the";
	defb "keyboard joystick, and Kempston", $0d;
	defb "w/autofire for the DB9 joystick.", $0d, 0;
     
L23AD:
	ld hl, bordcr;
	ld e, (hl);
	ld hl, attr_p;
	ld d, (hl);
	push de;
	xor a;
	push af;
	inc sp;
	call L2B0E;
	inc sp;

L23bd:
	ld a, 'G';
	push af;
	inc sp;
	call L2ADF;
	inc sp;
	call printstatictext;
	pop de;

L23C9:
	push de;
	call L2673;
	ld a, l;

L23Ce:
	pop de;
	or a;
	jr z, L23C9;
	push de;
	ld a, e;
	push af;
	inc sp;
	call L2B0E;
	inc sp;
	inc sp;
	call L2ADF;
	inc sp;
	ret;

printstatictext:
	call enter_ix;
	ld hl, $ffe0;
	add hl, sp;
	ld sp, hl;
	ld hl, 0;
	push hl;
	call locate;
	ld hl, static_t1;
	ex (sp), hl
	call puts;
	ld hl, 2;
	ex (sp), hl;
	call locate;
	ld hl, static_t2;
	ex (sp), hl;
	call puts;
	ld hl, 3;
	ex (sp), hl
	call locate;
	ld hl, static_t3;
	ex (sp), hl;
	call puts;
	ld hl, 5;
	ex (sp), hl;
	call locate;
	ld hl, static_t4;
	ex (sp), hl;
	call puts;
	ld hl, 6;
	ex (sp), hl;
	call locate;
	ld hl, static_t5;
	ex (sp), hl;
	call puts;
	ld hl, $13;
	ex (sp), hl;
	call locate;
	ld hl, static_t6;
	ex (sp), hl;
	call puts;
	pop af;
	ld hl, 0;
	add hl, sp;
	ex de, hl;
	ld a, 4;
	ld (de), a;
	ld l, e;
	ld h, d;
	inc hl;
	ld (hl), 'F';
	ld c, e;
	ld b, d;
	inc bc;
	inc bc;
	ld l, c;
	ld h, b;
	push bc;
	push de;
	push hl;
	call L2549;
	pop af;
	pop de;
	pop bc;
	ld a, (bc);
	or a;
	jr nz, pr_st_1;
	ld hl, static_t7;
	push hl;
	call puts;
	pop af;
	jr pr_st_2;

pr_st_1:
	push de;
	call puts;
	pop af;

pr_st_2:
	ld hl, $15;
	push hl;
	call locate;
	pop af;
	ld de, static_t8;
	push de;
	call puts;
	ld sp, ix;
	pop ix;
	ret; 

static_t1:
	defb $04, $78;
	defb "JOYSTICK CONFIGURATION AND TEST ", 0;

static_t2:
	defb "KBD joystick: ", 0;

static_t3:
	defb "DB9 joystick: ", 0;

static_t4:
	defb $04, $45;
	defb "Q/A to change KBD/DB9 protocol", 0;

static_t5:
	defb $04, $45;
	defb "W/S to change KBD/DB9 autofire", 0;

static_t6:
	defb $04, $47;
	defb "ZX-UNO Core ID: ", 0;

static_t7:
	defb $04, $46;
	defb "NOT AVAILABLE", 0;

static_t8:
	defb $04, $70;
	defb "      Press SPACE to exit       ", 0;

L2549:
	call enter_ix;
	dec sp;
	ld e, (ix + 4);
	ld d, (ix + 5);
	xor a;
	ld (de), a;
	ld a, $ff;
	ld bc, zxunoaddr;
	out (c), a;
	ld b, 0;

L255E:
	ld a, $fd;
	in a, ($3b);
	or a;
	jr z, L256D;
	ld a, b;
	sub ' ';
	jr nc, L256D;
	inc b;
	jr L255E;

L256D:
	ld a, b;
	sub ' ';
	jr z, L25B4;
	jr L2576;
	jr L25B4;

L2576:
	ld b, 0;

L2578:
	ld a, $fd;
	in a, ($3b);
	ld (ix - 1), a;
	inc b;
	ld a, (ix - 1);
	or a;
	jr nz, L258B
	ld a, b;
	sub ' ';
	jr c, L2578;

L258B:
	ld a, b;
	sub ' ';
	jr z, L25B4;
	jr L2594;
	jr L25B4;

L2594:
	ld a, (ix - 1);
	ld (de), a;
	inc de;
	ld (ix + 4), e;
	ld (ix + 5), d;
	ld e, (ix + 4);
	ld d, (ix + 5);

L25A5:
	ld a, $fd;
	in a, ($3b);
	ld (ix - 1), a;
	ld (de), a;
	inc de;
	ld a, (ix - 1);
	or a;
	jr nz, L25A5;

L25B4:
	inc sp;
	pop ix;
	ret;

L25B8:
	call enter_ix;
	ld l, (ix + 4);
	ld h, (ix + 5);
	push hl;
	call puts;
	pop af;
	bit 3, (ix + 6);
	jr z, L25d6;
	ld hl, L2641;
	push hl;
	call puts;
	pop af;
	jr L25DE

L25d6:
	ld hl, L2647;
	push hl;
	call puts;
	pop af;

L25DE:
	bit 2, (ix + 6);
	jr z, L25EE;
	ld hl, L264B;
	push hl;
	call puts;
	pop af;
	jr L25F6;

L25EE:
	ld hl, L2651;
	push hl;
	call puts;
	pop af;

L25F6:
	bit 1, (ix + 6);
	jr z, L2606;
	ld hl, L2655;
	push hl;
	call puts;
	pop af;
	jr L260E;

L2606:
	ld hl, L265B;
	push hl;
	call puts;
	pop af;

L260E:
	bit 0, (ix + 6);
	jr z, L261E;
	ld hl, L265F;
	push hl;
	call puts;
	pop af;
	jr L2626;

L261E:
	ld hl, L2665;
	push hl;
	call puts;
	pop af;

L2626:
	bit 4, (ix + 6);
	jr z, L2636;
	ld hl, L2669;
	push hl;
	call puts;
	pop af;
	jr L263E;

L2636:
	ld hl, L266F;
	push hl;
	call puts;
	pop af;

L263E:
	pop ix;
	ret;

L2641:
	defb $04, $78, " U ", 0;
	
L2647:
	defb " U ", 0;

L264B:
	defb $04, $78, " D ", 0;

L2651:
	defb " D ", 0;

L2655:
	defb $04, $78, " L ", 0;

L265B:
	defb " L ", 0;

L265F:
	defb $04, $78, " R ", 0;

L2665:
	defb " R ", 0;

L2669:
	defb $04, $78, " F ", 0;

L266F:
	defb " F ", 0;

L2673:
	call enter_ix;
	push af;
	push af;
	push af;
	ld d, 0;
	ld (ix-06h), 0;
	halt;
	ld a, 6;
	ld bc, zxunoaddr;
	out (c), a;
	ld a, $fd;
	in a, ($3b);
	and $0f;
	ld (ix-04), a;
	ld a, $fd;
	in a, ($3b);
	rlca;
	rlca;
	rlca;

L2697:
	rlca;
	and $0f;

L269A:
	and $0f;
	ld (ix-05), a;
	push de;
	ld hl, $0e02;
	push hl;
	call locate;
	pop af;
	pop de;

L26A9:
	ld a, (ix-04);
	and $07;
	ld e, a;
	sub 1;
	jr c, L270B;

L26B3:
	ld a, 5;

L26B5:
	sub e;
	jr c, L270B;
	ld b, e;

L26B7 equ L26B5 + 2	

L26B9:
	dec b;
	push de;
	ld e, b;
	ld d, 0;
	ld hl, L26C5;
	add hl, de;
	add hl, de;
	pop de;
	jp (hl);

L26C5:
	jr L26CF;
	jr L26DB;
	jr L26E7;
	jr L26F3;
	jr L26FF;

L26CF:
	ld hl, conf_t01;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L2717;
	jr similar_1;

L26DB:
	ld hl, conf_t02;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L2717;
	jr similar_1;

L26E7:
	ld hl, conf_t03;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L2717;
	jr similar_1;

L26F3:
	ld hl, conf_t04;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L2717;
	jr similar_1;

L26FF:
	ld hl, conf_t05;

similar_1:
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	jr L2717;

L270B:
	ld hl, conf_t06;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	ld d, 1;

L2717:
	ld a, (ix-04);
	and $08;
	ld (ix - 1), a;
	ld a, d;
	or a;
	jr nz, L2735;
	ld a, (ix - 1);
	or a;
	jr z, L2735;
	ld hl, conf_t07;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	jr L273F;

L2735:
	ld hl, conf_t08;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;

L273F:
	push de;
	ld hl, $0e03;
	push hl;
	call locate;
	pop af;
	pop de;
	ld a, (ix-05);
	and $07;
	ld (ix-02h), a;
	sub 1;
	jr c, L27B1;
	ld a, 5;
	sub (ix - 2);
	jr c, L27B1;
	ld d, (ix - 2);
	dec d;
	push de;
	ld e, d;
	ld d, 0;
	ld hl, L276B;
	add hl, de;
	add hl, de;
	pop de;
	jp (hl);

L276B:
	jr L2775;
	jr L2781;
	jr L278D;
	jr L2799;
	jr L27A5;

L2775:
	ld hl, conf_t01;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L27BF;
	jr similar_2;

L2781:
	ld hl, conf_t02;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L27BF;
	jr similar_2;

L278D:
	ld hl, conf_t03;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L27BF;
	jr similar_2;

L2799:
	ld hl, conf_t04;
;	push de;
;	push hl;
;	call puts;
;	pop af;
;	pop de;
;	jr L27BF;
	jr similar_2;

L27A5:
	ld hl, conf_t05;

similar_2:
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	jr L27BF;

L27B1:
	ld hl, conf_t06;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	ld (ix - 6), 1;

L27BF:
	ld a, (ix - 5);
	and $08;
	ld (ix - 3), a;
	ld a, (ix - 6);
	or a;
	jr nz, L27DF;
	ld a, (ix - 3);
	or a;
	jr z, L27DF;
	ld hl, conf_t07;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;
	jr L27e9;

L27DF:
	ld hl, conf_t08;
	push de;
	push hl;
	call puts;
	pop af;
	pop de;

L27e9:
	ld hl, last_k;
	ld l, (hl);
	ld a, l;
	cp 'q';
	jr z, L27F6;
	sub 'Q';
	jr nz, L2811;

L27F6:
	ld l, e;
	ld h, 0;
	inc hl;
	ld a, l;
	sub 6;
	jr nz, L2802;
	or h;
	jr z, L2804;

L2802:
	ld a, e;
	inc a;

L2804:
	or (ix - 1);
	ld (ix - 4), a;
	ld hl, last_k;
	ld (hl), 0;
	jr L286E;

L2811:
	ld a, l;
	cp 'a';
	jr z, L281A;
	sub 'A';
	jr nz, L2839;

L281A:
	ld e, (ix - 2);
	ld d, 0;
	inc de;
	ld a, e;
	sub 6;
	jr nz, L2828;
	or d;
	jr z, L282C;

L2828:
	ld a, (ix - 2);
	inc a;

L282C:
	or (ix - 3);
	ld (ix - 5), a;
	ld hl, last_k;
	ld (hl), 0;
	jr L286E;

L2839:
	ld a, l;
	cp 'w';
	jr z, L2842;
	sub 'W';
	jr nz, L2851;

L2842:
	ld a, (ix - 4);
	xor $08;
	ld (ix - 4), a;
	ld hl, last_k;
	ld (hl), 0;
	jr L286E;

L2851:
	ld a, l;
	sub 's';
	jr nz, L285A;
	ld a, 1;
	jr L285B;

L285A:
	xor a;

L285B:
	or a;
	jr nz, L2861;
	or a;
	jr z, L286E;

L2861:
	ld a, (ix - 5);
	xor $08;
	ld (ix - 5), a;
	ld hl, last_k;
	ld (hl), 0;

L286E:
	ld a, (ix - 5);
	rlca;
	rlca;
	rlca;
	rlca;
	and $f0;
	or (ix - 4);
	ld bc, zxunodata;
	out (c), a;
	in a, ($1f);
	ld d, a;
	push de;
	ld hl, 8;
	push hl;
	call locate;
	pop af;
	pop de;
	ld bc, conf_t09;
	push de;
	inc sp;
	push bc;
	call L25B8;
	pop af;
	inc sp;
	ld a, $ef;
	in a, (ula);
	cpl;
	ld d, a;
	and $01;
	rlca;
	rlca;
	rlca;
	rlca;
	and $f0;
	ld h, a;
	ld a, d;
	and $02;
	add a, a;
	add a, a;
	or h;
	ld l, a;
	ld a, d;
	and $04;
	or l;
	ld h, a;
	ld a, d;
	and $10;
	rrca;
	rrca;
	rrca;
	and $1f;
	or h;
	ld l, a;
	ld a, d;
	and $08;
	rrca;
	rrca;
	rrca;
	and $1f;
	or l;
	ld d, a;
	push de;
	ld hl, $0a;
	push hl;
	call locate;
	pop af;
	pop de;
	ld bc, conf_t10;
	push de;
	inc sp;
	push bc;
	call L25B8;
	pop af;
	inc sp;
	ld a, $f7;
	in a, (ula);
	cpl;
	ld d, a;
	and $1c;
	ld h, a;
	ld a, d;
	and $02;
	srl a;
	or h;
	ld l, a;
	ld a, d;
	and $01;
	add a, a;
	or l;
	ld d, a;
	push de;
	ld hl, $0c;
	push hl;
	call locate
	pop af;
	pop de;
	ld bc, conf_t11;
	push de;
	inc sp;
	push bc;
	call L25B8;
	pop af;
	inc sp;
	ld a, $ef;
	in a, (ula);
	cpl;
	ld d, a;
	ld a, $f7;
	in a, (ula)
	cpl;;
	ld e, a;
	ld a, d;
	and $01;
	rlca;
	rlca;
	rlca;
	rlca;
	and $f0;
	ld l, a;
	ld a, d;
	and $08;
	or l;
	ld l, a;
	ld a, d;
	and $10;
	rrca;
	rrca;
	and $3f;
	or l;
	ld l, a;
	ld a, e;
	and $10;
	rrca;
	rrca;
	rrca;
	and $1f;
	or l;
	ld h, a;
	ld a, d;
	and $04;
	rrca;
	rrca;
	and $3f;
	or h;
	ld d, a;
	push de;
	ld hl, $0e;
	push hl;
	call locate;
	pop af;
	pop de;
	ld bc, conf_t12;
	push de;
	inc sp;
	push bc;
	call L25B8;
	pop af;
	inc sp;
	in a, ($7f);
	cpl;
	ld d, a;
	and $80;
	rrca;
	rrca;
	rrca;
	and $1f;
	ld h, a;
	ld a, d;
	and $01;
	rlca;
	rlca;
	rlca;
	and $f8;
	or h;
	ld l, a;
	ld a, d;
	and $02;
	add a, a;
	or l;
	ld h, a;
	ld a, d;
	and $04;
	srl a;
	or h;
	ld l, a;
	ld a, d;
	and $08;
	rrca;
	rrca;
	rrca;
	and $1f;
	or l;
	ld d, a;
	push de;
	ld hl, $10;
	push hl;
	call locate;
	pop af;
	pop de;
	ld bc, conf_t13;
	push de;
	inc sp;
	push bc;
	call L25B8;
	pop af;
	inc sp;
	ld a, (last_k);
	sub ' ';
	jr nz, L299F;
	ld l, 1;
	jr L29A1;

L299F:
	ld l, 0;

L29A1:
	ld sp, ix;
	pop ix;
	ret;

conf_t01:
	defb $04, $46;
	defb "KEMPSTON", 0;

conf_t02:
	defb $04, $46;
	defb "SINCL P1", 0;

conf_t03:
	defb $04, $46;
	defb "SINCL P2", 0;

conf_t04:
	defb $04, $46;
	defb "CURSOR  ", 0;

conf_t05:
	defb $04, $46;
	defb "FULLER  ", 0;

conf_t06:
	defb $04, $46;
	defb "DISABLED", 0;

conf_t07:
	defb $04, $45;
	defb " AUTOFIRE", 0;

conf_t08:
	defb "         ", 0;

conf_t09:
	defb $04, $07;
	defb "Kempston  : ", 0;

conf_t10:
	defb $04, $07;
	defb "Sinclair 1: ", 0;

conf_t11:
	defb $04, $07;
	defb "Sinclair 2: ", 0;

conf_t12:
	defb $04, $07;
	defb "Cursor    : ", 0;

conf_t13:
	defb $04, $07;
	defb "Fuller    : ", 0;

L2A49:
	call enter_ix;
	dec sp;
	bit 7, (ix + 5);
	jr nz, L2A5B;
	ld d, (ix + 4);
	ld e, (ix + 5);
	jr L2A66;

L2A5B:
	xor a;
	sub (ix + 4);
	ld d, a;
	ld a, 0;
	sbc a, (ix + 5);
	ld e, a;

L2A66:
	ld l, d;
	ld h, e;
	inc sp;
	pop ix;
	ret;
	call enter_ix;
	dec sp;
	bit 7, (ix + 5);
	jr nz, L2A7A;
	ld l, 1;
	jr L2A7C;

L2A7A:
	ld l, $ff;

L2A7C:
	inc sp;
	pop ix;
	ret;
	ld a, (frames);
	ld l, a;
	ld a, (frames + 1);
	ld h, a;
	ld a, (frames + 2);
	ld e, a;
	ld d, 0;
	ret;
	call enter_ix;
	ld d, 0;

L2A94:
	ld a, (ix + 4);
	sub d;
	jr z, L2A9E;
	halt;
	inc d;
	jr L2A94;

L2A9E:
	pop ix;
	ret;

;org $2aa1
memset:
	call enter_ix;
	push bc;
	push de;
	ld l, (ix + 4);
	ld h, (ix + 5);
	ld a, (ix + 6);
	ld c, (ix + 7);
	ld b, (ix + 8);
	ld d, h;
	ld e, l;
	inc de;
	dec bc;
	ld (hl), a;
	ldir;
	pop de;
	pop bc;
	pop ix;
	ret;

; this subroutine does not appear to be used
;org $2ac1:
;memcpy:
;	call enter_ix;
;	push bc;
;	push de;
;	ld e, (ix + 4);
;	ld d, (ix + 5);
;	ld l, (ix + 6);
;	ld h, (ix + 7);
;	ld c, (ix + 8);
;	ld b, (ix + 9);
;	ldir;
;	pop de;
;	pop bc;
;	pop ix;
;	ret;   

L2ADF:
	call enter_ix;
	ld hl, $1800;
	push hl;
	xor a;
	push af;
	inc sp;
	ld h, $40;
	push hl;
	call memset;
	pop af;
	pop af;
	inc sp;
	ld hl, $0300;
	push hl;
	ld a, (ix + 4);
	push af;
	inc sp;
	ld h, $58
	push hl;
	call memset;
	pop af;
	pop af;
	inc sp;
	ld hl, attr_p;
	ld a, (ix + 4);
	ld (hl), a;
	pop ix;
	ret;

L2B0E:
	call enter_ix;
	ld a, (ix + 4);
	rrca;
	rrca;
	rrca;
	and $1f
	and $07;
	out (ula), a;
	ld hl, bordcr;
	ld a, (ix + 4);
	ld (hl), a;
	pop ix;
	ret;

;org $2b27		
puts:
	call enter_ix;
	push bc;
	push de;
	ld a, (attr_t);
	push af;
	ld a, (attr_p);
	ld (attr_t), a;
	ld l, (ix + 4);
	ld h, (ix + 5);

buc_print:
	ld a, (hl);
	or a;
	jp z, fin_print;
	cp 4;
	jr nz, no_attr;
	inc hl;
	ld a, (hl);
	ld (attr_t), a;
	inc hl;
	jr buc_print;

no_attr:
	rst $10;
	inc hl;
	jp buc_print; could use jr

fin_print:
	pop af;
	ld (attr_t), a;
	pop de;
	pop bc;
	pop ix;
	ret;

;org $2b5b
locate:
	call enter_ix;
	push bc;
	push de;
	ld a, $16;
	rst $10;
	ld a, (ix + 4);
	rst $10;
	ld a, (ix + 5);
	rst $10;
	pop de;
	pop bc;
	pop ix;
	ret;
	
	call enter_ix;
	ld d, (ix + 5);
	ld e, 0;
	ld l, (ix + 6);
	ld h, (ix + 7);
	push hl;
	push de;
	inc sp;
	call L2B9E;
	pop af;
	inc sp;
	ld e, (ix + 6);
	ld d, (ix + 7);
	inc de;
	inc de;
	ld b, (ix + 4);
	ld c, 0;
	push de;
	push bc;
	inc sp;
	call L2B9E;
	pop af;
	inc sp;
	pop ix;
	ret;

L2B9E:
	call enter_ix;
	ld a, (ix + 4);
	and $0f;
	ld b, a;
	ld e, (ix + 5);
	ld d, (ix + 6);
	inc de;
	ld a, 9;
	sub b;
	jr nc, L2BB8;
	ld a, b;
	add a, '7';
	jr L2BBB;

L2BB8:
	ld a, b;
	add a, '0';

L2BBB:
	ld (de), a;
	ld a, (ix + 4);
	rlca;
	rlca;
	rlca;
	rlca;
	and $0f;
	ld d, a;
	ld c, (ix + 5);
	ld b, (ix + 6);
	ld a, 9;
	sub d;
	jr nc, L2BD6;
	ld a, d;
	add a, '7';
	jr L2BD9;

L2BD6:
	ld a, d;
	add a, '0';

L2BD9:
	ld (bc), a
	ld l, c
	ld h, b
	inc hl
	inc hl
	ld (hl), 0
	pop ix
	ret;

L2BE3:
	in a, (ula);
	and $1f;
	sub $1f;
	jr z, L2BE3;
	ret;
	call enter_ix;
	ld a, (ix + 4);
	sub 1;
	jr c, L2C5A;
	ld a, 8;
	sub (ix + 4)
	jr c, L2C5A;
	ld e, (ix + 4);
	dec e;
	ld d, 0;
	ld hl, L2C0A;
	add hl, de;
	add hl, de;
	add hl, de;
	jp (hl);

L2C0A:
;	jp L2C22;
;	jp L2C29;
;	jp L2C30;
;	jp L2C37;
;	jp L2C3E;
;	jp L2C45;
;	jp L2C4C;
;	jp L2C53;
	jr L2C22;
	jr L2C29;
	jr L2C30;
	jr L2C37;
	jr L2C3E;
	jr L2C45;
	jr L2C4C;
	jr L2C53;

L2C22:
	ld a, $f7;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C29:
	ld a, $ef;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C30:
	ld a, $fb;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C37:
	ld a, $df;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C3E:
	ld a, $fd;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C45:
	ld a, $bf;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;

L2C4C:
	ld a, $fe;
;	in a, (ula);
;	ld d, a;
;	jr L2C5D;
	jr similar_3;
	
L2C53:
	ld a, $7f;

similar_3:
	in a, (ula);
	ld d, a;
	jr L2C5D;

L2C5A:
	in a, (ula);
	ld d, a;

L2C5D:
	ld b, (ix + 5);
	dec b;
	push af;
	ld h, 1;
	pop af;
	inc b;
	jr L2C6A;

L2C68:
	sla h;

L2C6A:
	djnz L2C68;
	ld a, d;
	and h;
	jr z, L2C74;
	ld l, 0;
	jr L2C76;

L2C74:
	ld l, 1;

L2C76:
	pop ix;
	ret;
	ld a, i;
	di;
	push af;
	call enter_ix;
	dec sp;
	ld hl, bordcr;
	ld a, (hl);
	ld (ix - 1), a;
	push bc;
	push de;
	ld l, (ix + 6);
	ld h, (ix + 7);
	ld d, (ix - 1);
	ld b, (ix + 8);
	xor a;
	sub b;
	ld b, a;
	ld c, a;

bucbeep:
	ld a, d;
	xor $18;
	ld d, a;
	out (ula), a;
	ld b, c;

bucperiodbeep:
	djnz bucperiodbeep;
	dec hl;
	ld a, h;
	or l;
	jr nz, bucbeep;
	pop de;
	pop bc;
	inc sp;
	pop ix;
	pop af;
	ret po;
	ei;
	ret;

enter_ix:
	pop hl;					// return address
	push ix;				// save frame pointer
	ld ix, 0;
	add ix, sp;				// set ix to the stack frame
	jp (hl);				// and return
