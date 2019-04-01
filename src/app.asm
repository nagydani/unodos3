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

output_bin "../programs/sampleap.p/unodos.app", $8000, $0100

include "basic.api"
include "unodos.api"

; sample application

org $8000
start:

basic_call:
	ld a, 6;					// yellow
	call $229B;					// ROM border routine changes and sets border

unodos_call:
	ld a, '*';
	ld b, fa_read | fa_open_ex;
	ld ix, filename;
	rst $08;
	defb f_open;
	ret c;
	ld (handle), a;
	ld ix, 16384;				// destination address
	ld bc, 6912;				// bytes to read
	rst $08;
	defb f_read;
	ret c;
	ld a, (handle);
	rst $08;
	defb f_close;

return:
	exx;						// alternate register set
	pop hl;						// drop return addresses
	pop hl;
	pop hl;
	pop hl;
	pop hl;
	ld hl, $2758;				// restore value of HL'
	exx;						// main register set
	ld (iy + 0), $ff;			// clear error
	xor	a;						// clean return
	ret;						// return to BASIC
	
handle:
	defb 0;

filename:
	defb "unodos3.scr"