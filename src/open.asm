
; OPEN

	ld hl,(prog);			// a new channel starts below prog
	dec hl;
    ld bc,0x0005;			// make space
    call 0x1655; 
	inc hl;					// HL points to 1st byte of new channel data
	ld a,$fd;				// lsb of output routine
	ld (hl),a;
	inc hl;
	push hl; save address of 2nd byte of new channel data
	ld a,0xfd; msb of output routine
	ld (hl),a;
	inc hl;
	ld a,0xc4; lsb of input routine
	ld (hl),a;
	inc hl;
	ld a,0x15; msb of input routine
	ld (hl),a;
	inc hl;
	ld a,0x55; channel name 'u' 
	ld (hl),a;
	pop hl; get address of 2nd byte of output routine
	ld de,(chans); calculate the offset to the channel data
	and a; and store it in de
	sbc hl,de;
	ex de,hl;
	ld hl,'strms';
	ld a,0x04; stream to open, in this case #4.
	add a,0x03; calculate the offset and store it in hl
	add a,a;
	ld b,0x00;
	ld c,a;
	add hl,bc;
	ld (hl),e; lsb of 2nd byte of new channel data
	inc hl;
	ld (hl),d; msb of 2nd byte of new channel data
	ret;
	
; ---
; READ channel data (19 bytes)

	defw $15C4;				// report J
	defw input;				// address of input routine
	defb 'I';				// channel name
	
i_buffer:
	defb 0;					// data buffer

input:
	ld hl, buffer;			// set destination
	ld a, 0;				// get handle (value overwriten during setup)
	ld bc, 1;				// one byte to be read
	rst $08;				// UnoDOS call
	defb f_read;			// read one byte
	ld a, (buffer);			// byte to A
	ret;					// done

; ---
; WRITE channel data (17 bytes)

	defw output;			// address of output routine
	defw $15C4;				// report J
	defb 'O';				// channel name

o_buffer:
	defb 0;					// data buffer

output:
	ld hl, buffer;			// set source
	ld (hl), a;				// put value to write in buffer
	ld a, 0;				// get handle (value overwriten during setup)
	ld bc, 1;				// one byte
	rst $08;				// UnoDOS call
	defb f_write;			// write one byte
	ret;					// done	

; to CLOSE a channel, get the name, that will point to the handle and inform 
; of the channel length. f_close the handle. Reclaim the channel, then clear the
; stream