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

output_bin "../dos/restore", $2000, $0460

include "unodos.api"
include "zx-uno.api"

org $2000
start:
	ld a, l;				// test for
	or h;					// args
	jp nz, args;			// argument found

pr_help:
	ld hl, help;			// help text
	call v_pr_str;			// print it
	or a;					// clean return
	ret;					// to BASIC

help:
	defb "Restore flash or ROM set.", $0d;
	defb "(RESTORE -f or RESTORE -r)", $0d, $0d, 0;

args:
	inc hl;					// second location
	ld a, (hl);				// get arg value
	and $df;				// make upper case
	ex af, af';				// store it in a'
	dec hl;					// first location
	ld a, (hl);				// get arg value
	cp '-';					// test for minus sign
	jr nz, pr_help;			// print help text if not found
	ex af, af';				// get second arg
	cp 'F';					// test for F
	jp z, Flash;			// backup firmware
	cp 'R';					// test for R
	jr nz, pr_help;			// help text if not found else backup ROMs.

Roms:
	ld bc, zxunoaddr;
	out (c), f;
	inc b;
	in f, (c);
	jp p, RNonlock;
	call RPrint;
	defb "ROM not rooted", 0;
	ret;

RNonlock:
	ld a, scandbl_ctrl;
	dec b;
	out (c), a;
	inc b;
	in a, (c);
	and $3f;
	ld (Rnormal + 1), a;
	or $c0;
	out (c), a;
	call Rinit;
	ld bc, zxunoaddr;
	ld a, scandbl_ctrl;
	out (c), a;
	inc b;

Rnormal:
	ld a, 0;
	out (c), a;
	ret;

Rinit:
	xor a;
	rst $08;
	defb m_getsetdrv ; A = unidad actual;
	jr nc, RSDCard;
	call RPrint;
	defb "SD card not inserted", 0;
	ret;

RSDCard:
	ld b, fa_read ; B = modo de apertura;
	ld hl, RFileName ; HL = Puntero al nombre del fichero (ASCIIZ);
	rst $08;
	defb f_open;
	ld (Rhandle + 1), a;
	jr nc, RFileFound;
	call RPrint;
	defb "File ROMS.ZX1 not found", 0;
	ret;

RFileFound:
	call RPrint;
	defb "Restoring ROMS.ZX1 from SD", 13;
	defb '[', 6, " ]", 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0;
	ld ixl, 64;
	ld de, $8000;
	ld hl, $0060;
	ld a, $20;
	call Rrdflsh;
	ld de, $0060;
	exx;
	ld hl, $8000;
	ld bc, $1041;

Rhandle:
	ld a, 0;
	rst $08;
	defb f_read;
	jr c, RtError;
	ld a, $20;
	ld hl, $8000;
	exx;
	call Rwrflsh;
	ld e, $c0;
	exx;

RBucle:
	ld a, ixl;
	dec a;
	and $03;
	jr nz, Rpunto;
	ld a, 'o';
	exx;
	push de;
	rst $10;
	pop de;
	exx;

Rpunto:
	ld hl, $8000;
	ld bc, $4000;
	ld a, (Rhandle + 1);
	rst $08;
	defb f_read;
	jr nc, RReadOK;

RtError:
	call RPrint;
	defb "Read Error", 0;
	ret;

RReadOK:
	ld a, $40;
	ld hl, $8000;
	exx;
	call Rwrflsh;
	inc de;
	ld a, ixl;
	cp 46;
	jr nz, Ro45roms;
	ld de, $34c0;

Ro45roms:
	exx;
	dec ixl;
	jr nz, RBucle;
	ld a, (Rhandle + 1);
	rst $08;
	defb f_close;
	call RPrint;
	defb 13, "Restore complete", 13, 0;
	ret;

RPrint:
	pop hl;
	defb $3e;

RPrint1:
	rst $10;
	ld a, (hl);
	inc hl;
	or a;
	jr nz, RPrint1;
	jp (hl);

; ------------------------;
; Read from SPI flash;
; Parameters:;
; DE: destination address;
; HL: source address without last byte;
; A: number of pages (256 bytes) to read;
; ------------------------;

Rrdflsh:
	ex af, af';
	xor a;
	push hl;
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, 3 ; envio flash_spi un 3, orden de lectura;
	pop hl;
	push hl;
	out (c), h;
	out (c), l;
	out (c), a;
	ex af, af';
	ex de, hl;
	in f, (c);

Rrdfls1:
	ld e, $20;

Rrdfls2:
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	ini;
	inc b;
	dec e;
	jr nz, Rrdfls2;
	dec a;
	jr nz, Rrdfls1;
	call Rrst28;
	defb flash_cs, 1;
	pop hl;
	ret;

; ------------------------;
; Write to SPI flash;
; Parameters:;
; A: number of pages (256 bytes) to write;
; DE: target address without last byte;
; HL': source address from memory;
; ------------------------;
Rwrflsh:
	ex af, af';
	xor a;

Rwrfls1:
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, 6 ; envío write enable;
	call Rrst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, $20 ; envío sector erase;
	out (c), d;
	out (c), e;
	out (c), a;
	call Rrst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;

Rwrfls2:
	call Rwaits5;
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, 6 ; envío write enable;
	call Rrst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, 2 ; page program;
	out (c), d;
	out (c), e;
	out (c), a;
	ld a, $20;
	exx;
	ld bc, zxunoaddr + $100;

Rwrfls3:
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	dec a;
	jr nz, Rwrfls3;
	exx;
	call Rrst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	ex af, af';
	dec a;
	jr z, Rwaits5;
	ex af, af';
	inc e;
	ld a, e;
	and $0f;
	jr nz, Rwrfls2;
	ld hl, Rwrfls1;
	push hl;

Rwaits5:
	call Rrst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Rrst28;
	defb flash_spi, 5 ; envío read status;
	in a, (c);

Rwaits6:
	in a, (c);
	and 1;
	jr nz, Rwaits6;
	call Rrst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	ret;

Rrst28:
	ld bc, zxunoaddr + $100;
	pop hl;
	outi;
	ld b, (zxunoaddr >> 8) + 2;
	outi;
	jp (hl);

RFileName:
	defb "ROMS.ZX1", 0;

Flash:
	ld bc, zxunoaddr;
	out (c), f;
	inc b;
	in f, (c);
	jp p, FNonlock;
	call FPrint;
	defb "ROM not rooted", 0;
	ret;

FNonlock:
	ld a, scandbl_ctrl;
	dec b;
	out (c), a;
	inc b;
	in a, (c);
	and $3f;
	ld (Fnormal + 1), a;
	or $c0;
	out (c), a;
	call Finit;
	ld bc, zxunoaddr;
	ld a, scandbl_ctrl;
	out (c), a;
	inc b;

Fnormal:
	ld a, 0;
	out (c), a;
	ret;

Finit:
	xor a;
	rst $08;
	defb m_getsetdrv ; A = unidad actual;
	jr nc, FSDCard;
	call FPrint;
	defb "SD card not inserted", 0;
	ret;

FSDCard:
	ld b, fa_read ; B = modo de apertura;
	ld hl, FFileName ; HL = Puntero al nombre del fichero (ASCIIZ);
	rst $08;
	defb f_open;
	ld (Fhandle + 1), a;
	jr nc, FFileFound;
	call FPrint;
	defb "File FLASH.ZX1 not found", 0;
	ret;

FFileFound:
	call FPrint;
	defb "Restoring FLASH.ZX1 from SD", 13;
	defb '[', 6, " ]", 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0;
	ld ixl, 0;
	ld de, $0000;
	exx;

FBucle:
	ld a, ixl;
	inc a;
	and $0f;
	jr nz, Fpunto;
	ld a, 'o';
	exx;
	push de;
	rst $10;
	pop de;
	exx;

Fpunto:
	ld hl, $8000;
	ld bc, $4000;

Fhandle:
	ld a, 0;
	rst $08;
	defb f_read;
	jr nc, FReadOK;
	call FPrint;
	defb "Read Error", 0;
	ret;

FReadOK:
	ld a, $40;
	ld hl, $8000;
	exx;
	call Fwrflsh;
	inc de;
	exx;
	dec ixl;
	jr nz, FBucle;
	ld a, (Fhandle + 1);
	rst $08;
	defb f_close;
	call FPrint;
	defb 13, "Restore complete", 0;
	ret;

FPrint:
	pop hl;
	defb $3e;

FPrint1:
	rst $10;
	ld a, (hl);
	inc hl;
	or a;
	jr nz, FPrint1;
	jp (hl);

; ------------------------;
; Write to SPI flash;
; Parameters:;
; A: number of pages (256 bytes) to write;
; DE: target address without last byte;
; BC': zxunoaddr + $100 (constant);
; HL': source address from memory;
; ------------------------;

Fwrflsh:
	ex af, af';
	xor a;

Fwrfls1:
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, 6 ; envío write enable;
	call Frst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, $20 ; envío sector erase;
	out (c), d;
	out (c), e;
	out (c), a;
	call Frst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;

Fwrfls2:
	call Fwaits5;
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, 6 ; envío write enable;
	call Frst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, 2 ; page program;
	out (c), d;
	out (c), e;
	out (c), a;
	ld a, $20;
	exx;
	ld bc, zxunoaddr + $100;

Fwrfls3:
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	inc b;
	outi;
	dec a;
	jr nz, Fwrfls3;
	exx;
	call Frst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	ex af, af';
	dec a;
	jr z, Fwaits5;
	ex af, af';
	inc e;
	ld a, e;
	and $0f;
	jr nz, Fwrfls2;
	ld hl, Fwrfls1;
	push hl;

Fwaits5:
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, 5 ; envío read status;
	in a, (c);

Fwaits6:
	in a, (c);
	and 1;
	jr nz, Fwaits6;
	call Frst28;
	defb flash_cs, 1 ; desactivamos spi, enviando un 1;
	ret;

Frst28:
	ld bc, zxunoaddr + $100;
	pop hl;
	outi;
	ld b, (zxunoaddr >> 8) + 2;
	outi;
	jp (hl);

FFileName:
	defb "FLASH.ZX1", 0;
