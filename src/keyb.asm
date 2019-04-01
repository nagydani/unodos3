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

output_bin "../dos/keyb", $2000, $0200

include "unodos.api"
include "zx-uno.api"

org $2000
Main:
	ld a, l;
	or h;
	jr z, PrintUso;			// if file name not specified, print usage

clr_buffer:
	ld hl, Buffer;
	xor a;
	ld (hl), a;
	ld de, Buffer + 1;
	ld bc, 4095;
	ldir;

do_it:
	call RecogerNFile;
	call ReadMap;
	ret;

PrintUso:
	ld hl, Uso
	jp v_pr_str;

RecogerNFile:
	ld de, BufferNFich;		// HL points to arguments (filename)

CheckCaracter:
	ld a, (hl);
	or a;
	jr z, FinRecoger;
	cp ' ';
	jr z, FinRecoger;
	cp ':';
	jr z, FinRecoger;
	cp $0d;
	jr z, FinRecoger;
	ldi;
	jr CheckCaracter;

FinRecoger:
	xor a;
	ld (de), a;
	inc de;					// DE is pointing to the buffer that is needed in
;							// OPEN, I do not know why
	ret;					// endproc

ReadMap:
	xor a;
	rst $08;
	db m_getsetdrv;			// A = current unit
	ld b, fa_read;			// B = opening mode
	ld hl, MapFile;			// HL = pointer to filename (ASCII)
	rst $08;
	defb f_open;
	ret c;					// back if there is error
	ld (FHandle), a;
	ld bc, zxunoaddr;
	ld a, 7;
	out (c), a;				// select KEYMAP register
	ld b, 4;				// 4 chunks of 4096 bytes each to load

BucReadMapFromFile:
	push bc;
	ld bc, 4096;
	ld hl, Buffer;
	ld a, (FHandle);
	rst $08;
	defb f_read;
	jr c, PrematureEnd;		// if error, end of reading

	ld hl, Buffer;
	ld bc, zxunodata;
	ld de, 4096;

BucWriteMapToFPGA:
	ld a, (hl);
	out (c), a;
	inc hl;
	dec de;
	ld a, d;
	or e;
	jr nz, BucWriteMapToFPGA;
	pop bc;
	djnz BucReadMapFromFile;
	jr FinReadMap;

PrematureEnd:
	pop bc;
	push af;
	ld a, (FHandle);
	rst $08;
	defb f_close;
	pop af;
	ret;

FinReadMap:
	ld a, (FHandle);
	rst $08;
	defb f_close;
	or a;				// back without errors to UnoDOS
	ret;				// endproc

Uso:
	defb "KEYB file", $0d, $0d;
	defb "Loads the specified keymap from", $0d;
	defb "/DOS/KEYMAPS and enables it.", $0d, 0;

FHandle:
	defb 0;

;Buffer:
;	defs 4096;			// 4KB for read buffer

MapFile:
	defb "/dos/keymaps/"

BufferNFich:
	defb 0;				// this from the RAM for the filename

Buffer equ $2200
