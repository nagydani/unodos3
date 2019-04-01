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

output_bin "../dos/backup", $2000, $0350

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
	defb "Backup flash or ROM set.", $0d;
	defb "(BACKUP -f or BACKUP -r)", $0d, $0d, 0;

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
	ld b, fa_write | fa_open_al ; B = modo de apertura;
	ld hl, RFileName ; HL = Puntero al nombre del fichero (ASCIIZ);
	rst $08;
	defb f_open;
	ld (Rhandle + 1), a;
	jr nc, RFileFound;
	call RPrint;
	defb "Can't open ROMS.ZX1", 0;
	ret;

RFileFound:
	call RPrint;
	defb "Backing up ROMS.ZX1 to SD", 13;
	defb '[', 6, " ]", 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0;
	ld ixl, 64;
	ld de, $8000;
	ld hl, $0060;
	ld a, $11;
	call Rrdflsh;
	ld hl, $8000;
	ld bc, $1041;

Rhandle:
	ld a, 0;
	rst $08;
	defb f_write;
	ld hl, $00c0;
	jr c, RtError;

RBucle:
	ld a, ixl;
	dec a;
	and $03;
	jr nz, Rpunto;
	ld a, 'o';
	rst $10;

Rpunto:
	ld a, ixl;
	cp 45;
	jr nz, Ro45roms;
	ld hl, $34c0;

Ro45roms:
	ld de, $8000;
	ld a, $40;
	call Rrdflsh;
	ld de, $0040;
	add hl, de;
	push hl;
	ld hl, $8000;
	ld bc, $4000;
	ld a, (Rhandle + 1);
	rst $08;
	defb f_write;
	pop hl;
	jr nc, RReadOK;

RtError:
	call RPrint;
	defb "Write Error", 0;
	ret;

RReadOK:
	dec ixl;
	jr nz, RBucle;
	ld a, (Rhandle + 1);
	rst $08;
	defb f_close;
	call RPrint;
	defb 13, "Backup complete", 13, 0;
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
	ld b, fa_write | fa_open_al ; B = modo de apertura;
	ld hl, FFileName ; HL = Puntero al nombre del fichero (ASCIIZ);
	rst $08;
	defb f_open;
	ld (Fhandle + 1), a;
	jr nc, FFileFound;
	call FPrint;
	defb "Can't open FLASH.ZX1", 0;
	ret;

FFileFound:
	call FPrint;
	defb "Backing up FLASH.ZX1 to SD", 13;
	defb '[', 6, " ]", 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0;
	ld hl, $0000;

FBucle:
	push hl;
	ld de, $8000;
	ld a, $40;
	call Frdflsh;
	add hl, hl;
	add hl, hl;
	ld a, h;
	and $0f;
	jr nz, Fpunto;
	ld a, 'o';
	rst $10;

Fpunto:
	ld hl, $8000;
	ld bc, $4000;

Fhandle:
	ld a, 0;
	rst $08;
	defb f_write;
	pop hl;
	jr nc, FWriteOK;
	call FPrint;
	defb "Write Error", 0;
	ret;

FWriteOK:
	ld de, $0040;
	add hl, de;
	bit 6, h;
	jr z, FBucle;
	rst $08;
	defb f_close;
	call FPrint;
	defb 13, "Backup complete", 0;
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
; Read from SPI flash;
; Parameters:;
; DE: destination address;
; HL: source address without last byte;
; A: number of pages (256 bytes) to read;
; ------------------------;

Frdflsh:
	ex af, af';
	xor a;
	push hl;
	call Frst28;
	defb flash_cs, 0 ; activamos spi, enviando un 0;
	call Frst28;
	defb flash_spi, 3 ; envio flash_spi un 3, orden de lectura;
	pop hl;
	push hl;
	out (c), h;
	out (c), l;
	out (c), a;
	ex af, af';
	ex de, hl;
	in f, (c);

Frdfls1:
	ld e, $20;

Frdfls2:
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
	jr nz, Frdfls2;
	dec a;
	jr nz, Frdfls1;
	call Frst28;
	defb flash_cs, 1;
	pop hl;
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
