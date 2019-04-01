output_bin "../dos/echo", $2000, $0460

include "unodos.api"

org $2000;				// esxdos commands are executed at 2000h
start:	
	ld a,h;				// on entry hl = address of commandline	
	or l;				// arguments
	jr nz, echo;		// if hl is not zero, carry on to echo routine

message:	
	ld hl, string;		// point to custom error message
	xor	a;				// set return code to zero
	scf;				// set the carry flah
	ret;				// return to esxdos
	
echo:
	ld a, (hl);			// grab next byte of commandline
	and a;				// check for zero
	ret z;
	cp '$';				// check for '$'
	ret z;
	cp ':';				// check for ':'
	ret z;
	cp $0d;				// check for <cr>
	ret z
	rst 16;				// print the character
	inc hl;				// move on to next character
	jr echo;			// loop back to echo routine
	
	xor	a;				// a=0, cf=0 (esxdos clean exit)
	ret;				// return to esxdos

string:
	defb "No argument", 's' + $80



	
	