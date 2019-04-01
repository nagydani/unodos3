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

output_bin "../dos/bload", $2000, $0460

include "basic.api"
include "unodos.api"

org $2000
start:
	ld a, l;				// test for
	or h;					// args
	jr nz, init;			// jump if found

error:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.
    
init:
	call get_fn;

parse:
	call args2buffer;		// copy arguments to buffer
	ld hl, buffer;			// point to buffer

; arg1 first digit
	call numeric;			// number?
	jr nc, error;			// error if not
	ld d, 0;				// clear H
	ld e, a;				// A to low byte of HL

; arg1 second digit
	inc hl;					// next address
	call numeric;			// number?
	jr nc, comma;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg1 third digit
	inc hl;
	call numeric;			// number?
	jr nc, comma;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg1 fourth digit
	inc hl;
	call numeric;			// number?
	jr nc, comma;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg1 fifth digit
	inc hl;
	call numeric;			// number?
	jr nc, comma;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; next character
	inc hl;

comma:
	ld a, (hl);
	cp ',';
	jr nz, error;
	ex de, hl;
	ld (arg1), hl;			// save firsr argument
	ex de, hl;

; next character
	inc hl;
	
; arg2 first digit
	call numeric;			// number?
	jr nc, zero;			// error if not
	ld d, 0;				// clear H
	ld e, a;				// A to low byte of HL

; arg2 second digit
	inc hl;					// next address
	call numeric;			// number?
	jr nc, zero;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg2 third digit
	inc hl;
	call numeric;			// number?
	jr nc, zero;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg2 fourth digit
	inc hl;
	call numeric;			// number?
	jr nc, zero;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; arg2 fifth digit
	inc hl;
	call numeric;			// number?
	jr nc, zero;			// test for comma if not;
	call add_digit;			// multiply current number by 10 and add A

; next character
	inc hl;

zero:
	ld a, (hl);
	and a;					// test for zero
	jr nz, error;
	ex de, hl;
	ld (arg2), hl;			// save firsr argument
	jr command

add_digit:
	ex de, hl;				// pointer to DE, number to HL
	call mult10;			// HL = HL x 10
	ld b, 0;				// clear BASIC
	ld c, a;				// A to low byte of BC
	add hl, bc;				// add next digit
	call c, overflow;		// test for overflow
	ex de, hl;				// pointer to HL, number to DE
	ret;					// done

numeric:
	ld a, (hl);				// get character
	sub 48;					// reduce range
	cp 10;					// 0-9?
	ret;

mult10:
	add hl, hl;				// x2
	jr c, overflow;			// test for overflow
	ld b, h;				//
	ld c, l;				//
	add hl, hl;				// x4
	jr c, overflow;			// test for overflow
	add hl, hl;				// x8
	jr c, overflow;			// test for overflow
	add hl, bc;				// x10
	jr c, overflow;			// test for overflow
	ret;
	
overflow:
	pop hl;
	pop hl;					// drop return address
	jp error;				// go to erro

conv16:
	dec hl;					// point top least significant digit
	ld d, 0;				// clear D
	ld a, (hl);				// get number
	sub 48;					// reduce range
	
args2buffer:
	ld de, buffer;

copychar:
	ld a, (hl);
	and a;
	jr z, setend;
	cp ':';
	jr z, setend;
	cp $0d;
	jr z, setend;
	ldi;
	jr copychar;

setend:
	xor a;
	ld (de), a;
	ret;

get_fn:
	ld de, filename;

copy_loop:
	ld a, (hl);
	cp ',';
	jr z, line_end;
	ldi;
	jr copy_loop;

line_end:
	inc hl; 				// skip past terminating comma
	ret;					// buffer is preloaded with terminating zeros

command:
	ld a, '*';
	ld b, fa_read | fa_open_ex;
	ld hl, filename;
	rst $08;
	defb f_open;
	ret c;
	ld (handle), a;
	ld hl, (arg1);			// destination address
	ld bc, (arg2);			// bytes to read
	rst $08;
	defb f_read;
	ret c;
	ld a, (handle);
	rst $08;
	defb f_close;
	ret c;
	or a;
	ret;
	
handle:
	defb 0;

arg1:
	defw 0;

arg2:
	defw 0;

filename:
	defs 13, 0;					// "filename.ext", 0

buffer:



