; SoftPLAY (c) 2013 Andrew Owen

; Original PLAY command by Kevin Males
; Original assembly comments by Paul Farrow

output_bin "../dos/play", $2000, $0840

include "../src/basic.api"

org	$2000
	ld (ch_add), hl;		// ch_add points to arguments
	ld hl, L5B00;			// code to run from RAM
	ld de, $5B00;			// location to run it from
	ld bc, 19;				// length of code
	ldir;					// copy it
	call PLAY;
	or a;
	ret;
	
PLAY:
L16AB:
	ld b, 0;				// string index
	rst $18;
	defw $18;
		
L16AE:
	push bc;
	rst $18;
	defw expt_exp; 			// get string expression
	pop bc;
	inc b;
	cp ',';					// comma indicates another string
	jr nz, L16BB;			// jump ahead if no more
	rst $18;
	defw $20;		
	jr L16AE;				// loop back

L16BB:
	ld a, b;				// check the index
	cp 9;					// maximum of 8 strings (to support synthesisers,
;							// drum machines or sequencers)
	jr c, L16C4;
	rst $18
	defw report_q

L16C4:
	rst $18;
	defw check_end;			// ensure end-of-statement or end-of-line
	jp L093F;				// continue with PLAY code

L093F:
	di;						// disable interrupts to ensure accurate timing.

;Create a workspace for the play channel command strings

	PUSH BC	   ; B=Number of channel string (range 1 to 8). Also used as string index number in the following loop.

	LD   DE,$0037     ;
	LD   HL,$003C     ;

L0947:
	ADD  HL,DE	; Calculate HL=$003C + ($0037 * B).
	DJNZ L0947	;

	LD   C,L	  ;
	LD   B,H	  ; BC=Space required (maximum = $01F4).
	rst $18;
	defw $30;				// $0030. Make BC bytes of space in the workspace.

	PUSH DE	   ;
	POP  IY	   ; IY=Points at first new byte - the command data block.

	PUSH HL	   ;
	POP  IX	   ; IX=Points at last new byte - byte after all channel information blocks.

	LD   (IY+$10),$FF ; Initial channel bitmap with value meaning 'zero strings'

;Loop over each string to be played

L095A:
	LD   BC,$FFC9     ; $-37 ($37 bytes is the size of a play channel string information block).
	ADD  IX,BC	; IX points to start of space for the last channel.
	LD   (IX+$03),$3C ; Default octave is 5.
	LD   (IX+$01),$FF ; No MIDI channel assigned.
	LD   (IX+$04),$0F ; Default volume is 15.
	LD   (IX+$05),$05 ; Default note duration.
	LD   (IX+$21),$00 ; Count of the number of tied notes.
	LD   (IX+$0A),$00 ; Signal not to repeat the string indefinitely.
	LD   (IX+$0B),$00 ; No opening bracket nesting level.
	LD   (IX+$16),$FF ; No closing bracket nesting level.
	LD   (IX+$17),$00 ; Return address for closing bracket nesting level 0.
	LD   (IX+$18),$00 ; [No need to initialise this since it is written to before it is ever tested]

	rst $18;
	defw stk_fetch    ; Get the details of the string from the stack.

	LD   (IX+$06),E   ; Store the current position within in the string, i.e. the beginning of it.
	LD   (IX+$07),D   ;
	LD   (IX+$0C),E   ; Store the return position within the string for a closing bracket,
	LD   (IX+$0D),D   ; which is initially the start of the string in case a single closing bracket is found.

	EX   DE,HL	; HL=Points to start of string. BC=Length of string.
	ADD  HL,BC	; HL=Points to address of byte after the string.
	LD   (IX+$08),L   ; Store the address of the character just
	LD   (IX+$09),H   ; after the string.

	POP  BC	   ; B=String index number (range 1 to 8).
	PUSH BC	   ; Save it on the stack again.
	DEC  B	    ; Reduce the index so it ranges from 0 to 7.

	LD   C,B	  ;
	LD   B,$00	;
	SLA  C	    ; BC=String index*2.

	PUSH IY	   ;
	POP  HL	   ; HL=Address of the command data block.
	ADD  HL,BC	; Skip 8 channel data pointer words.

	PUSH IX	   ;
	POP  BC	   ; BC=Address of current channel information block.

	LD   (HL),C       ; Store the pointer to the channel information block.
	INC  HL	   ;
	LD   (HL),B       ;

	OR   A	    ; Clear the carry flag.
	RL   (IY+$10)     ; Rotate one zero-bit into the least significant bit of the channel bitmap.
			  ; This initially holds $FF but once this loop is over, this byte has
			  ; a zero bit for each string parameter of the PLAY command.

	POP  BC	   ; B=Current string index.
	DEC  B	    ; Decrement string index so it ranges from 0 to 7.
	PUSH BC	   ; Save it for future use on the next iteration.
	LD   (IX+$02),B   ; Store the channel number.

	JR   NZ,L095A     ; Jump back while more channel strings to process.

	POP  BC	   ; Drop item left on the stack.

		LD   (IY+$27),$1A ; Set the initial tempo timing value.
	LD   (IY+$28),$0B ; Corresponds to a 'T' command value of 120, and gives two crotchets per second.

	LD   D,$07	; Register 7 - Mixer.
	LD   E,$F8	; I/O ports are inputs, noise output off, tone output on.
	CALL L0E2E	; Write to sound generator register.

	LD   D,$0B	; Register 11 - Envelope Period (Fine).
	LD   E,$FF	; Set period to maximum.
	CALL L0E2E	; Write to sound generator register.

	INC  D	    ; Register 12 - Envelope Period (Coarse).
	CALL L0E2E	; Write to sound generator register.

; This section begins by determining the first note to play on each channel and then enters
; a loop to play these notes, fetching the subsequent notes to play at the appropriate times.

	CALL L0A09	; Select channel data block pointers.

L0A3A:
	RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
	JR   C,L0A46      ; Jump ahead if there is no string for this channel.

;HL=Address of channel data pointer.

	CALL L0A21	; Get address of channel data block for the current string into IX.
	CALL L0B16	; Find the first note to play for this channel from its play string.

L0A46:
	SLA  (IY+$21)     ; Have all channels been processed?
	JR   C,L0A51      ; Jump ahead if so.

	CALL L0A28	; Advance to the next channel data block pointer.
	JR   L0A3A	; Jump back to process the next channel.

;The first notes to play for each channel have now been determined. A loop is entered that coordinates playing
;the notes and fetching subsequent notes when required. Notes across channels may be of different lengths and
;so the shortest one is determined, the tones for all channels set and then a waiting delay entered for the shortest
;note delay. This delay length is then subtracted from all channel note lengths to leave the remaining lengths that
;each note needs to be played for. For the channel with the smallest note length, this will now have completely played
;and so a new note is fetched for it. The smallest length of the current notes is then determined again and the process
;described above repeated. A test is made on each iteration to see if all channels have run out of data to play, and if
;so this ends the PLAY command.

L0A51:
	CALL L0F43	; Find smallest duration length of the current notes across all channels.

	PUSH DE	   ; Save the smallest duration length.
	CALL L0EF4	; Play a note on each channel.
	POP  DE	   ; DE=The smallest duration length.

L0A59:
	LD   A,(IY+$10)   ; Channel bitmap.
	CP   $FF	  ; Is there anything to play?
	JR   NZ,L0A65     ; Jump if there is.

	JP   L0E45	; Turn off all sound and restore IY.
			  ; Re-enable interrupts.
			  ; End of play command.

L0A65:
	DEC  DE	   ; DE=Smallest channel duration length, i.e. duration until the next channel state change.
	CALL L0F28	; Perform a wait.
	CALL L0F73	; Play a note on each channel and update the channel duration lengths.

	CALL L0F43	; Find smallest duration length of the current notes across all channels.
	JR   L0A59	; Jump back to see if there is more to process.

; --------------
; Test BREAK Key
; --------------
; Test for BREAK being pressed.
; Exit: Carry flag reset if BREAK is being pressed.

L09F8:
	LD   A,$7F	;
	IN   A,($FE)      ;
	RRA	       ;
	RET  C	    ; Return with carry flag set if SPACE not pressed.

	LD   A,$FE	;
	IN   A,($FE)      ;
	RRA	       ;
	RET	       ; Return with carry flag set if CAPS not pressed.

; -------------------------------------------
; Select Channel Data Block Duration Pointers
; -------------------------------------------
; Point to the start of the channel data block duration pointers within the command data block.
; Entry: IY=Address of the command data block.
; Exit : HL=Address of current channel pointer.

L0A04:
	LD   BC,$0011     ; Offset to the channel data block duration pointers table.
	JR   L0A0C	; Jump ahead to continue.

; ----------------------------------
; Select Channel Data Block Pointers
; ----------------------------------
; Point to the start of the channel data block pointers within the command data block.
; Entry: IY=Address of the command data block.
; Exit : HL=Address of current channel pointer.

L0A09:
	LD   BC,$0000     ; Offset to the channel data block pointers table.

L0A0C:
	PUSH IY	   ;
	POP  HL	   ; HL=Point to the command data block.

	ADD  HL,BC	; Point to the desired channel pointers table.

	LD   (IY+$23),L   ;
	LD   (IY+$24),H   ; Store the start address of channels pointer table.

	LD   A,(IY+$10)   ; Fetch the channel bitmap.
	LD   (IY+$22),A   ; Initialise the working copy.

	LD   (IY+$21),$01 ; Channel selector. Set the shift register to indicate the first channel.
	RET	       ;

; -------------------------------------------------
; Get Channel Data Block Address for Current String
; -------------------------------------------------
; Entry: HL=Address of channel data block pointer.
; Exit : IX=Address of current channel data block.

L0A21:
	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; Fetch the address of the current channel data block.

	PUSH DE	   ;
	POP  IX	   ; Return it in IX.
	RET	       ;

; -------------------------
; Next Channel Data Pointer
; -------------------------

L0A28:
	LD   L,(IY+$23)   ; The address of current channel data pointer.
	LD   H,(IY+$24)   ;
	INC  HL	   ;
	INC  HL	   ; Advance to the next channel data pointer.
	LD   (IY+$23),L   ;
	LD   (IY+$24),H   ; The address of new channel data pointer.
	RET	       ;

; ----------------------------
; PLAY Command Character Table
; ----------------------------
; Recognised characters in PLAY commands.

L0A71:
	DEFM "HZYXWUVMT)(NO!"

; ------------------
; Get Play Character
; ------------------
; Get the current character from the PLAY string and then increment the
; character pointer within the string.
; Exit: Carry flag set if string has been fully processed.
;       Carry flag reset if character is available.
;       A=Character available.

L0A7F:
	CALL L0E95	; Get the current character from the play string for this channel.
	RET  C	    ; Return if no more characters.

	INC  (IX+$06)     ; Increment the low byte of the string pointer.
	RET  NZ	   ; Return if it has not overflowed.

	INC  (IX+$07)     ; Else increment the high byte of the string pointer.
	RET	       ; Returns with carry flag reset.

; --------------------------
; Get Next Note in Semitones
; --------------------------
; Finds the number of semitones above C for the next note in the string,
; Entry: IX=Address of the channel data block.
; Exit : A=Number of semitones above C, or $80 for a rest.

L0A8B:
	PUSH HL	   ; Save HL.

	LD   C,$00	; Default is for a 'natural' note, i.e. no adjustment.

L0A8E:
	CALL L0A7F	; Get the current character from the PLAY string, and advance the position pointer.
	JR   C,L0A9B      ; Jump if at the end of the string.

	CP   '&'	  ; $26. Is it a rest?
	JR   NZ,L0AA6     ; Jump ahead if not.

	LD   A,$80	; Signal that it is a rest.

L0A99:
	POP  HL	   ; Restore HL.
	RET	       ;

L0A9B:
	LD   A,(IY+$21)   ; Fetch the channel selector.
	OR   (IY+$10)     ; Clear the channel flag for this string.
	LD   (IY+$10),A   ; Store the new channel bitmap.
	JR   L0A99	; Jump back to return.

L0AA6:
	CP   '#'	  ; $23. Is it a sharpen?
	JR   NZ,L0AAD     ; Jump ahead if not.

	INC  C	    ; Increment by a semitone.
	JR   L0A8E	; Jump back to get the next character.

L0AAD:
	CP   '$'	  ; $24. Is it a flatten?
	JR   NZ,L0AB4     ; Jump ahead if not.

	DEC  C	    ; Decrement by a semitone.
	JR   L0A8E	; Jump back to get the next character.

L0AB4:
	BIT  5,A	  ; Is it a lower case letter?
	JR   NZ,L0ABE     ; Jump ahead if lower case.

	PUSH AF	   ; It is an upper case letter so
	LD   A,$0C	; increase an octave
	ADD  A,C	  ; by adding 12 semitones.
	LD   C,A	  ;
	POP  AF	   ;

L0ABE:
	AND  $DF	  ; Convert to upper case.
	SUB  $41	  ; Reduce to range 'A'->0 .. 'G'->6.
	JP   C,L0EC4      ; Jump if below 'A' to produce error report "k Invalid note name".

	CP   $07	  ; Is it 7 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "k Invalid note name".

	PUSH BC	   ; C=Number of semitones.

	LD   B,$00	;
	LD   C,A	  ; BC holds 0..6 for 'a'..'g'.
	LD   HL,L0DB6     ; Look up the number of semitones above note C for the note.
	ADD  HL,BC	;
	LD   A,(HL)       ; A=Number of semitones above note C.

	POP  BC	   ; C=Number of semitones due to sharpen/flatten characters.
	ADD  A,C	  ; Adjust number of semitones above note C for the sharpen/flatten characters.

	POP  HL	   ; Restore HL.
	RET	       ;

; ----------------------------------
; Get Numeric Value from Play String
; ----------------------------------
; Get a numeric value from a PLAY string, returning 0 if no numeric value present.
; Entry: IX=Address of the channel data block.
; Exit : BC=Numeric value, or 0 if no numeric value found.

L0AD7:
	PUSH HL	   ; Save registers.
	PUSH DE	   ;

	LD   L,(IX+$06)   ; Get the pointer into the PLAY string.
	LD   H,(IX+$07)   ;

	LD   DE,$0000     ; Initialise result to 0.

L0AE2:
	LD   A,(HL)       ;
	CP   '0'	  ; $30. Is character numeric?
	JR   C,L0AFF      ; Jump ahead if not.

	CP   ':'	  ; $3A. Is character numeric?
	JR   NC,L0AFF     ; Jump ahead if not.

	INC  HL	   ; Advance to the next character.
	PUSH HL	   ; Save the pointer into the string.

	CALL L0B0A	; Multiply result so far by 10.
	SUB  '0'	  ; $30. Convert ASCII digit to numeric value.
	LD   H,$00	;
	LD   L,A	  ; HL=Numeric digit value.
	ADD  HL,DE	; Add the numeric value to the result so far.
	JR   C,L0AFC      ; Jump ahead if an overflow to produce error report "l number too big".

	EX   DE,HL	; Transfer the result into DE.

	POP  HL	   ; Retrieve the pointer into the string.
	JR   L0AE2	; Loop back to handle any further numeric digits.

L0AFC:
	JP   L0EC4	; Jump to produce error report "l number too big".
			  ; [Could have saved 1 byte by directly using JP C,$0ECC (ROM 0) instead of using this JP and
			  ; the two JR C,$0AFC (ROM 0) instructions that come here]

;The end of the numeric value was reached

L0AFF:
	LD   (IX+$06),L   ; Store the new pointer position into the string.
	LD   (IX+$07),H   ;

	PUSH DE	   ;
	POP  BC	   ; Return the result in BC.

	POP  DE	   ; Restore registers.
	POP  HL	   ;
	RET	       ;

; -----------------
; Multiply DE by 10
; -----------------
; Entry: DE=Value to multiple by 10.
; Exit : DE=Value*10.

L0B0A:
	LD   HL,$0000     ;
	LD   B,$0A	; Add DE to HL ten times.

L0B0F:
	ADD  HL,DE	;
	JR   C,L0AFC      ; Jump ahead if an overflow to produce error report "l number too big".

	DJNZ L0B0F	;

	EX   DE,HL	; Transfer the result into DE.
	RET	       ;

; ----------------------------------
; Find Next Note from Channel String
; ----------------------------------
; Entry: IX=Address of channel data block.

L0B16:
	CALL L09F8	; Test for BREAK being pressed.
	JR   C,L0B23      ; Jump ahead if not pressed.

	CALL L0E45	; Turn off all sound and restore IY.

	rst $18;
	defw report_l;
	
L0B23:
	CALL L0A7F	; Get the current character from the PLAY string, and advance the position pointer.
	JP   C,L0D5F      ; Jump if at the end of the string.

	CALL L0DAD	; Find the handler routine for the PLAY command character.

	LD   B,$00	;
	SLA  C	    ; Generate the offset into the
	LD   HL,L0D87     ; command vector table.
	ADD  HL,BC	; HL points to handler routine for this command character.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; Fetch the handler routine address.

	EX   DE,HL	; HL=Handler routine address for this command character.
	CALL L0B3E	; Make an indirect call to the handler routine.
	JR   L0B16	; Jump back to handle the next character in the string.

;Comes here after processing a non-numeric digit that does not have a specific command routine handler
;Hence the next note to play has been determined and so a return is made to process the other channels.

L0B3D:
	RET	       ; Just make a return.

L0B3E:
	JP   (HL)	 ; Jump to the command handler routine.

; --------------------------
; Play Command '!' (Comment)
; --------------------------
; A comment is enclosed within exclamation marks, e.g. "! A comment !".
; Entry: IX=Address of the channel data block.

L0B3F:
	CALL L0A7F	; Get the current character from the PLAY string, and advance the position pointer.
	JP   C,L0D5E      ; Jump if at the end of the string.

	CP   '!'	  ; $21. Is it the end-of-comment character?
	RET  Z	    ; Return if it is.

	JR   L0B3F	; Jump back to test the next character.

; -------------------------
; Play Command 'O' (Octave)
; -------------------------
; The 'O' command is followed by a numeric value within the range 0 to 8,
; although due to loose range checking the value MOD 256 only needs to be
; within 0 to 8. Hence O256 operates the same as O0.
; Entry: IX=Address of the channel data block.

L0B4A:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   A,C	  ; Is it between 0 and 8?
	CP   $09	  ;
	JP   NC,L0EC4     ; Jump if above 8 to produce error report "n Out of range".

	SLA  A	    ; Multiply A by 12.
	SLA  A	    ;
	LD   B,A	  ;
	SLA  A	    ;
	ADD  A,B	  ;

	LD   (IX+$03),A   ; Store the octave value.
	RET	       ;

; ----------------------------
; Play Command 'N' (Separator)
; ----------------------------
; The 'N' command is simply a separator marker and so is ignored.
; Entry: IX=Address of the channel data block.

L0B5F:
	RET	       ; Nothing to do so make an immediate return.

; ----------------------------------
; Play Command '(' (Start of Repeat)
; ----------------------------------
; A phrase can be enclosed within brackets causing it to be repeated, i.e. played twice.
; Entry: IX=Address of the channel data block.

L0B60:
	LD   A,(IX+$0B)   ; A=Current level of open bracket nesting.
	INC  A	    ; Increment the count.
	CP   $05	  ; Only 4 levels supported.
	JP   Z,L0EC4      ; Jump if this is the fifth to produce error report "d Too many brackets".

	LD   (IX+$0B),A   ; Store the new open bracket nesting level.

	LD   DE,$000C     ; Offset to the bracket level return position stores.
	CALL L0BE1	; HL=Address of the pointer in which to store the return location of the bracket.

	LD   A,(IX+$06)   ; Store the current string position as the return address of the open bracket.
	LD   (HL),A       ;
	INC  HL	   ;
	LD   A,(IX+$07)   ;
	LD   (HL),A       ;
	RET	       ;

; --------------------------------
; Play Command ')' (End of Repeat)
; --------------------------------
; A phrase can be enclosed within brackets causing it to be repeated, i.e. played twice.
; Brackets can also be nested within each other, to 4 levels deep.
; If a closing bracket if used without a matching opening bracket then the whole string up
; until that point is repeated indefinitely.
; Entry: IX=Address of the channel data block.

L0B7C:
	LD   A,(IX+$16)   ; Fetch the nesting level of closing brackets.
	LD   DE,$0017     ; Offset to the closing bracket return address store.
	OR   A	    ; Is there any bracket nesting so far?
	JP   M,L0BAD      ; Jump if none.

;Has the bracket level been repeated, i.e. re-reached the same position in the string as the closing bracket return address?

	CALL L0BE1	; HL=Address of the pointer to the corresponding closing bracket return address store.
	LD   A,(IX+$06)   ; Fetch the low byte of the current address.
	CP   (HL)	 ; Re-reached the closing bracket?
	JR   NZ,L0BAA     ; Jump ahead if not.

	INC  HL	   ; Point to the high byte.
	LD   A,(IX+$07)   ; Fetch the high byte address of the current address.
	CP   (HL)	 ; Re-reached the closing bracket?
	JR   NZ,L0BAA     ; Jump ahead if not.

;The bracket level has been repeated. Now check whether this was the outer bracket level.

	DEC  (IX+$16)     ; Decrement the closing bracket nesting level since this level has been repeated.
	LD   A,(IX+$16)   ; [There is no need for the LD A,(IX+$16) and OR A instructions since the DEC (IX+$16) already set the flags]
	OR   A	    ; Reached the outer bracket nesting level?
	RET  P	    ; Return if not the outer bracket nesting level such that the character
			  ; after the closing bracket is processed next.

;The outer bracket level has been repeated

	BIT  0,(IX+$0A)   ; Was this a single closing bracket?
	RET  Z	    ; Return if it was not.

;The repeat was caused by a single closing bracket so re-initialise the repeat

	LD   (IX+$16),$00 ; Restore one level of closing bracket nesting.
	XOR  A	    ; Select closing bracket nesting level 0.
	JR   L0BC5	; Jump ahead to continue.

;A new level of closing bracket nesting

L0BAA:
	LD   A,(IX+$16)   ; Fetch the nesting level of closing brackets.

L0BAD:
	INC  A	    ; Increment the count.
	CP   $05	  ; Only 5 levels supported (4 to match up with opening brackets and a 5th to repeat indefinitely).
	JP   Z,L0EC4      ; Jump if this is the fifth to produce error report "d Too many brackets".

	LD   (IX+$16),A   ; Store the new closing bracket nesting level.

	CALL L0BE1	; HL=Address of the pointer to the appropriate closing bracket return address store.

	LD   A,(IX+$06)   ; Store the current string position as the return address for the closing bracket.
	LD   (HL),A       ;
	INC  HL	   ;
	LD   A,(IX+$07)   ;
	LD   (HL),A       ;

	LD   A,(IX+$0B)   ; Fetch the nesting level of opening brackets.

L0BC5:
	LD   DE,$000C     ;
	CALL L0BE1	; HL=Address of the pointer to the opening bracket nesting level return address store.

	LD   A,(HL)       ; Set the return address of the nesting level's opening bracket
	LD   (IX+$06),A   ; as new current position within the string.
	INC  HL	   ;
	LD   A,(HL)       ; For a single closing bracket only, this will be the start address of the string.
	LD   (IX+$07),A   ;

	DEC  (IX+$0B)     ; Decrement level of open bracket nesting.
	RET  P	    ; Return if the closing bracket matched an open bracket.

;There is one more closing bracket then opening brackets, i.e. repeat string indefinitely

	LD   (IX+$0B),$00 ; Set the opening brackets nesting level to 0.
	SET  0,(IX+$0A)   ; Signal a single closing bracket only, i.e. to repeat the string indefinitely.
	RET	       ;

; ------------------------------------
; Get Address of Bracket Pointer Store
; ------------------------------------
; Entry: IX=Address of the channel data block.
;	DE=Offset to the bracket pointer stores.
;	A=Index into the bracket pointer stores.
; Exit : HL=Address of the specified pointer store.

L0BE1:
	PUSH IX	   ;
	POP  HL	   ; HL=IX.

	ADD  HL,DE	; HL=IX+DE.
	LD   B,$00	;
	LD   C,A	  ;
	SLA  C	    ;
	ADD  HL,BC	; HL=IX+DE+2*A.
	RET	       ;

; ------------------------
; Play Command 'T' (Tempo)
; ------------------------
; A temp command must be specified in the first play string and is followed by a numeric
; value in the range 60 to 240 representing the number of beats (crotchets) per minute.
; Entry: IX=Address of the channel data block.

L0BEC:
	CALL L0AD7	; Get following numeric value from the string into BC.
	LD   A,B	  ;
	OR   A	    ;
	JP   NZ,L0EC4     ; Jump if 256 or above to produce error report "n Out of range".

	LD   A,C	  ;
	CP   $3C	  ;
	JP   C,L0EC4      ; Jump if 59 or below to produce error report "n Out of range".

	CP   $F1	  ;
	JP   NC,L0EC4     ; Jump if 241 or above to produce error report "n Out of range".

;A holds a value in the range 60 to 240

	LD   A,(IX+$02)   ; Fetch the channel number.
	OR   A	    ; Tempo 'T' commands have to be specified in the first string.
	RET  NZ	   ; If it is in a later string then ignore it.

	LD   B,$00	; [Redundant instruction - B is already zero]
	PUSH BC	   ; C=Tempo value.
	POP  HL	   ;
	ADD  HL,HL	;
	ADD  HL,HL	; HL=Tempo*4.

	LD   B,H	  ;
	LD   C,L	  ; BC=Tempo*4.

	PUSH IY	   ; Save the pointer to the play command data block.
	rst $18;
	defw stack_bc     ; $2D2B. Place the contents of BC onto the stack. The call restores IY to $5C3A.

	POP  IY	   ; Restore IY to point at the play command data block.
	PUSH IY	   ; Save the pointer to the play command data block.

; -------------------------------------------------
; Calculate Timing Loop Counter <<< RAM Routine >>>
; -------------------------------------------------
; The routine calculates (10/x)/7.33e-6, where x is the tempo 'T' parameter value
; multiplied by 4. The result is used an inner loop counter in the wait routine at $0F28 (ROM 0).
; Each iteration of this loop takes 26 T-states. The time taken by 26 T-states
; is 7.33e-6 seconds. So the total time for the loop to execute is 2.5/TEMPO seconds.
;
; Entry: The value 4*TEMPO exists on the calculator stack (where TEMPO is in the range 60..240).
; Exit : The calculator stack holds the result.

L09EB:
;	RST  28H	  ; Invoke the floating point calculator.
;	defb $A4	  ; stk-ten.   = x, 10
;	defb $01	  ; exchange.  = 10, x
;	defb $05	  ; division.  = 10/x
;	defb $34	  ; stk-data.  = 10/x, 7.33e-6
;	defb $DF	  ; - exponent $6F (floating point number 7.33e-6).
;	defb $75	  ; - mantissa byte 1 -80
;	defb $F4	  ; - mantissa byte 2 -164
;	defb $38	  ; - mantissa byte 3 -92
;	defb $75	  ; - mantissa byte 4 -80
;	defb $05	  ; division.  = (10/x)/7.33e-6
;	defb $38	  ; end-calc.

	rst $18;
	defw $5b00;

; --------------------
; Tempo Command Return
; --------------------
; The calculator stack now holds the value (10/(Tempo*4))/7.33e-6 and this is stored as the tempo value.
; The result is used an inner loop counter in the wait routine at $0F28 (ROM 0). Each iteration of this loop
; takes 26 T-states. The time taken by 26 T-states is 7.33e-6 seconds. So the total time for the loop
; to execute is 2.5/TEMPO seconds.

L0C30:
	rst $18
	defw fp_to_bc     ; $2DA2. Fetch the value on the top of the calculator stack.

	POP  IY	   ; Restore IY to point at the play command data block.

	LD   (IY+$27),C   ; Store tempo timing value.
	LD   (IY+$28),B   ;
	RET	       ;

; ------------------------
; Play Command 'M' (Mixer)
; ------------------------
; This command is used to select whether to use tone and/or noise on each of the 3 channels.
; It is followed by a numeric value in the range 1 to 63, although due to loose range checking the
; value MOD 256 only needs to be within 0 to 63. Hence M256 operates the same as M0.
; Entry: IX=Address of the channel data block.

L0C3E:
	CALL L0AD7	; Get following numeric value from the string into BC.
	LD   A,C	  ; A=Mixer value.
	CP   $40	  ; Is it 64 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

;Bit 0: 1=Enable channel A tone.
;Bit 1: 1=Enable channel B tone.
;Bit 2: 1=Enable channel C tone.
;Bit 3: 1=Enable channel A noise.
;Bit 4: 1=Enable channel B noise.
;Bit 5: 1=Enable channel C noise.

	CPL	       ; Invert the bits since the sound generator's mixer register uses active low enable.
			  ; This also sets bit 6 1, which selects the I/O port as an output.
	LD   E,A	  ; E=Mixer value.
	LD   D,$07	; D=Register 7 - Mixer.
	JP   L0E2E	; Write to sound generator register to set the mixer.

; -------------------------
; Play Command 'V' (Volume)
; -------------------------
; This sets the volume of a channel and is followed by a numeric value in the range
; 0 (minimum) to 15 (maximum), although due to loose range checking the value MOD 256
; only needs to be within 0 to 15. Hence V256 operates the same as V0.
; Entry: IX=Address of the channel data block.

L0C4F:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   A,C	  ;
	CP   $10	  ; Is it 16 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

	LD   (IX+$04),A   ; Store the volume level.

	RET	       ;

; ------------------------------------
; Play Command 'U' (Use Volume Effect)
; ------------------------------------
; This command turns on envelope waveform effects for a particular sound chip channel. The volume level is now controlled by
; the selected envelope waveform for the channel, as defined by the 'W' command. MIDI channels do not support envelope waveforms
; and so the routine has the effect of setting the volume of a MIDI channel to maximum, i.e. 15. It might seem odd that the volume
; for MIDI channels is set to 15 rather than just filtered out. However, the three sound chip channels can also drive three MIDI
; channels and so it would be inconsistent for these MIDI channels to have their volume set to 15 but have the other MIDI channels
; behave differently. However, it could be argued that all MIDI channels should be unaffected by the 'U' command.
; There are no parameters to this command.
; Entry: IX=Address of the channel data block.

L0C67:
	LD   E,(IX+$02)   ; Get the channel number.
	LD   A,$08	; Offset by 8.
	ADD  A,E	  ; A=8+index.
	LD   D,A	  ; D=Sound generator register number for the channel. [This is not used and so there is no need to generate it. It was probably a left
			  ; over from copying and modifying the 'V' command routine. Deleting it would save 7 bytes. Credit: Ian Collier (+3), Paul Farrow (128)]

	LD   E,$1F	; E=Select envelope defined by register 13, and reset volume bits to maximum (though these are not used with the envelope).
	LD   (IX+$04),E   ; Store that the envelope is being used (along with the reset volume level).

	RET	       ;

; ------------------------------------------
; Play command 'W' (Volume Effect Specifier)
; ------------------------------------------
; This command selects the envelope waveform to use and is followed by a numeric value in the range
; 0 to 7, although due to loose range checking the value MOD 256 only needs to be within 0 to 7.
; Hence W256 operates the same as W0.
; Entry: IX=Address of the channel data block.

L0C77:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   A,C	  ;
	CP   $08	  ; Is it 8 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

	LD   B,$00	;
	LD   HL,L0DA5     ; Envelope waveform lookup table.
	ADD  HL,BC	; HL points to the corresponding value in the table.
	LD   A,(HL)       ;
	LD   (IY+$29),A   ; Store new effect waveform value.
	RET	       ;

; -----------------------------------------
; Play Command 'X' (Volume Effect Duration)
; -----------------------------------------
; This command allows the duration of a waveform effect to be specified, and is followed by a numeric
; value in the range 0 to 65535. A value of 1 corresponds to the minimum duration, increasing up to 65535
; and then maximum duration for a value of 0. If no numeric value is specified then the maximum duration is used.
; Entry: IX=Address of the channel data block.

L0C8B:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   D,$0B	; Register 11 - Envelope Period Fine.
	LD   E,C	  ;
	CALL L0E2E	; Write to sound generator register to set the envelope period (low byte).

	INC  D	    ; Register 12 - Envelope Period Coarse.
	LD   E,B	  ;
	JP   L0E2E	; Write to sound generator register to set the envelope period (high byte).

; -------------------------------
; Play Command 'Y' (MIDI Channel)
; -------------------------------
; This command sets the MIDI channel number that the string is assigned to and is followed by a numeric
; value in the range 1 to 16, although due to loose range checking the value MOD 256 only needs to be within 1 to 16.
; Hence Y257 operates the same as Y1.
; Entry: IX=Address of the channel data block.

L0C9A:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   A,C	  ;
	DEC  A	    ; Is it 0?
	JP   M,L0EC4      ; Jump if so to produce error report "n Out of range".

	CP   $10	  ; Is it 10 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

	LD   (IX+$01),A   ; Store MIDI channel number that this string is assigned to.
	RET	       ;

; ----------------------------------------
; Play Command 'Z' (MIDI Programming Code)
; ----------------------------------------
; This command is used to send a programming code to the MIDI port. It is followed by a numeric
; value in the range 0 to 255, although due to loose range checking the value MOD 256 only needs
; to be within 0 to 255. Hence Z256 operates the same as Z0.
; Entry: IX=Address of the channel data block.

L0CAB:
	CALL L0AD7	; Get following numeric value from the string into BC.

	LD   A,C	  ; A=(low byte of) the value.
	JP   L117F	; Write byte to MIDI device.

; -----------------------
; Play Command 'H' (Stop)
; -----------------------
; This command stops further processing of a play command. It has no parameters.
; Entry: IX=Address of the channel data block.

L0CB3:
	LD   (IY+$10),$FF ; Indicate no channels to play, thereby causing
	RET	       ; the play command to terminate.

; --------------------------------------------------------
; Play Commands 'a'..'g', 'A'..'G', '1'.."12", '&' and '_'
; --------------------------------------------------------
; This handler routine processes commands 'a'..'g', 'A'..'G', '1'.."12", '&' and '_',
; and determines the length of the next note to play. It provides the handling of triplet and tied notes.
; It stores the note duration in the channel data block's duration length entry, and sets a pointer in the command
; data block's duration lengths pointer table to point at it. A single note letter is deemed to be a tied
; note count of 1. Triplets are deemed a tied note count of at least 2.
; Entry: IX=Address of the channel data block.
;	A=Current character from play string.

L0CB8:
	CALL L0DD6	; Is the current character a number?
	JP   C,L0D3E      ; Jump if not number digit.

;The character is a number digit

	CALL L0D69	; HL=Address of the duration length within the channel data block.
	CALL L0D71	; Store address of duration length in command data block's channel duration length pointer table.

	XOR  A	    ;
	LD   (IX+$21),A   ; Set no tied notes.

	CALL L0E7A	; Get the previous character in the string, the note duration.
	CALL L0AD7	; Get following numeric value from the string into BC.
	LD   A,C	  ;
	OR   A	    ; Is the value 0?
	JP   Z,L0EC4      ; Jump if so to produce error report "n Out of range".

	CP   $0D	  ; Is it 13 or above?
	JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

	CP   $0A	  ; Is it below 10?
	JR   C,L0CEF      ; Jump if so.

;It is a triplet semi-quaver (10), triplet quaver (11) or triplet crotchet (12)

	CALL L0DBD	; DE=Note duration length for the duration value.
	CALL L0D31	; Increment the tied notes counter.
	LD   (HL),E       ; HL=Address of the duration length within the channel data block.
	INC  HL	   ;
	LD   (HL),D       ; Store the duration length.

L0CE5:
	CALL L0D31	; Increment the counter of tied notes.

	INC  HL	   ;
	LD   (HL),E       ;
	INC  HL	   ; Store the subsequent note duration length in the channel data block.
	LD   (HL),D       ;
	INC  HL	   ;
	JR   L0CF5	; Jump ahead to continue.

;The note duration was in the range 1 to 9

L0CEF:
	LD   (IX+$05),C   ; C=Note duration value (1..9).
	CALL L0DBD	; DE=Duration length for this duration value.

L0CF5:
	CALL L0D31	; Increment the tied notes counter.

L0CF8:
	CALL L0E95	; Get the current character from the play string for this channel.

	CP   '_'	  ; $5F. Is it a tied note?
	JR   NZ,L0D2B     ; Jump ahead if not.

	CALL L0A7F	; Get the current character from the PLAY string, and advance the position pointer.
	CALL L0AD7	; Get following numeric value from the string into BC.
	LD   A,C	  ; Place the value into A.
	CP   $0A	  ; Is it below 10?
	JR   C,L0D1C      ; Jump ahead for 1 to 9 (semiquaver ... semibreve).

;A triplet note was found as part of a tied note

	PUSH HL	   ; HL=Address of the duration length within the channel data block.
	PUSH DE	   ; DE=First tied note duration length.
	CALL L0DBD	; DE=Note duration length for this new duration value.
	POP  HL	   ; HL=Current tied note duration length.
	ADD  HL,DE	; HL=Current+new tied note duration lengths.
	LD   C,E	  ;
	LD   B,D	  ; BC=Note duration length for the duration value.
	EX   DE,HL	; DE=Current+new tied note duration lengths.
	POP  HL	   ; HL=Address of the duration length within the channel data block.

	LD   (HL),E       ;
	INC  HL	   ;
	LD   (HL),D       ; Store the combined note duration length in the channel data block.

	LD   E,C	  ;
	LD   D,B	  ; DE=Note duration length for the second duration value.
	JR   L0CE5	; Jump back.

;A non-triplet tied note

L0D1C:
	LD   (IX+$05),C   ; Store the note duration value.

	PUSH HL	   ; HL=Address of the duration length within the channel data block.
	PUSH DE	   ; DE=First tied note duration length.
	CALL L0DBD	; DE=Note duration length for this new duration value.
	POP  HL	   ; HL=Current tied note duration length.
	ADD  HL,DE	; HL=Current+new tied not duration lengths.
	EX   DE,HL	; DE=Current+new tied not duration lengths.
	POP  HL	   ; HL=Address of the duration length within the channel data block.

	JP   L0CF8	; Jump back to process the next character in case it is also part of a tied note.

;The number found was not part of a tied note, so store the duration value

L0D2B:
	LD   (HL),E       ; HL=Address of the duration length within the channel data block.
	INC  HL	   ; (For triplet notes this could be the address of the subsequent note duration length)
	LD   (HL),D       ; Store the duration length.
	JP   L0D59	; Jump forward to make a return.

; This subroutine is called to increment the tied notes counter

L0D31:
	LD   A,(IX+$21)   ; Increment counter of tied notes.
	INC  A	    ;
	CP   $0B	  ; Has it reached 11?
	JP   Z,L0EC4      ; Jump if so to produce to error report "o too many tied notes".

	LD   (IX+$21),A   ; Store the new tied notes counter.
	RET	       ;

;The character is not a number digit so is 'A'..'G', '&' or '_'

L0D3E:
	CALL L0E7A	; Get the previous character from the string.

	LD   (IX+$21),$01 ; Set the number of tied notes to 1.

;Store a pointer to the channel data block's duration length into the command data block

	CALL L0D69	; HL=Address of the duration length within the channel data block.
	CALL L0D71	; Store address of duration length in command data block's channel duration length pointer table.

	LD   C,(IX+$05)   ; C=The duration value of the note (1 to 9).
	PUSH HL	   ; [Not necessary]
	CALL L0DBD	; Find the duration length for the note duration value.
	POP  HL	   ; [Not necessary]

	LD   (HL),E       ; Store it in the channel data block.
	INC  HL	   ;
	LD   (HL),D       ;
	JP   L0D59	; Jump to the instruction below. [Redundant instruction]

L0D59:
	POP  HL	   ;
	INC  HL	   ;
	INC  HL	   ; Modify the return address to point to the RET instruction at $0B3D (ROM 0).
	PUSH HL	   ;
	RET	       ; [Over elaborate when a simple POP followed by RET would have sufficed, saving 3 bytes]

; -------------------
; End of String Found
; -------------------
;This routine is called when the end of string is found within a comment. It marks the
;string as having been processed and then returns to the main loop to process the next string.

L0D5E:
	POP  HL	   ; Drop the return address of the call to the comment command.

;Enter here if the end of the string is found whilst processing a string.

L0D5F:
	LD   A,(IY+$21)   ; Fetch the channel selector.
	OR   (IY+$10)     ; Clear the channel flag for this string.
	LD   (IY+$10),A   ; Store the new channel bitmap.
	RET	       ;

; --------------------------------------------------
; Point to Duration Length within Channel Data Block
; --------------------------------------------------
; Entry: IX=Address of the channel data block.
; Exit : HL=Address of the duration length within the channel data block.

L0D69:
	PUSH IX	   ;
	POP  HL	   ; HL=Address of the channel data block.
	LD   BC,$0022     ;
	ADD  HL,BC	; HL=Address of the store for the duration length.
	RET	       ;

; -------------------------------------------------------------------------
; Store Entry in Command Data Block's Channel Duration Length Pointer Table
; -------------------------------------------------------------------------
; Entry: IY=Address of the command data block.
;	IX=Address of the channel data block for the current string.
;	HL=Address of the duration length store within the channel data block.
; Exit : HL=Address of the duration length store within the channel data block.
;	DE=Channel duration.

L0D71:
	PUSH HL	   ; Save the address of the duration length within the channel data block.

	PUSH IY	   ;
	POP  HL	   ; HL=Address of the command data block.

	LD   BC,$0011     ;
	ADD  HL,BC	; HL=Address within the command data block of the channel duration length pointer table.

	LD   B,$00	;
	LD   C,(IX+$02)   ; BC=Channel number.

	SLA  C	    ; BC=2*Index number.
	ADD  HL,BC	; HL=Address within the command data block of the pointer to the current channel's data block duration length.

	POP  DE	   ; DE=Address of the duration length within the channel data block.

	LD   (HL),E       ; Store the pointer to the channel duration length in the command data block's channel duration pointer table.
	INC  HL	   ;
	LD   (HL),D       ;
	EX   DE,HL	;
	RET	       ;

; -----------------------
; PLAY Command Jump Table
; -----------------------
; Handler routine jump table for all PLAY commands.

L0D87:
	defw L0CB8	; Command handler routine for all other characters.
	defw L0B3F	; '!' command handler routine.
	defw L0B4A	; 'O' command handler routine.
	defw L0B5F	; 'N' command handler routine.
	defw L0B60	; '(' command handler routine.
	defw L0B7C	; ')' command handler routine.
	defw L0BEC	; 'T' command handler routine.
	defw L0C3E	; 'M' command handler routine.
	defw L0C4F	; 'V' command handler routine.
	defw L0C67	; 'U' command handler routine.
	defw L0C77	; 'W' command handler routine.
	defw L0C8B	; 'X' command handler routine.
	defw L0C9A	; 'Y' command handler routine.
	defw L0CAB	; 'Z' command handler routine.
	defw L0CB3	; 'H' command handler routine.

; ------------------------------
; Envelope Waveform Lookup Table
; ------------------------------
; Table used by the play 'W' command to find the corresponding envelope value
; to write to the sound generator envelope shape register (register 13). This
; filters out the two duplicate waveforms possible from the sound generator and
; allows the order of the waveforms to be arranged in a more logical fashion.

L0DA5:
	defb $00	  ; W0 - Single decay then off.   (Continue off, attack off, alternate off, hold off)
	defb $04	  ; W1 - Single attack then off.  (Continue off, attack on,  alternate off, hold off)
	defb $0B	  ; W2 - Single decay then hold.  (Continue on,  attack off, alternate on,  hold on)
	defb $0D	  ; W3 - Single attack then hold. (Continue on,  attack on,  alternate off, hold on)
	defb $08	  ; W4 - Repeated decay.	  (Continue on,  attack off, alternate off, hold off)
	defb $0C	  ; W5 - Repeated attack.	 (Continue on,  attack on,  alternate off, hold off)
	defb $0E	  ; W6 - Repeated attack-decay.   (Continue on,  attack on,  alternate on,  hold off)
	defb $0A	  ; W7 - Repeated decay-attack.   (Continue on,  attack off, alternate on,  hold off)

; --------------------------
; Identify Command Character
; --------------------------
; This routines attempts to match the command character to those in a table.
; The index position of the match indicates which command handler routine is required
; to process the character. Note that commands are case sensitive.
; Entry: A=Command character.
; Exit : Zero flag set if a match was found.
;	BC=Indentifying the character matched, 1 to 15 for match and 0 for no match.

L0DAD:
	LD   BC,$000F     ; Number of characters + 1 in command table.
	LD   HL,L0A71     ; Start of command table.
	CPIR	      ; Search for a match.
	RET	       ;

; ---------------
; Semitones Table
; ---------------
; This table contains an entry for each note of the scale, A to G,
; and is the number of semitones above the note C.

L0DB6:
	defb $09	  ; 'A'
	defb $0B	  ; 'B'
	defb $00	  ; 'C'
	defb $02	  ; 'D'
	defb $04	  ; 'E'
	defb $05	  ; 'F'
	defb $07	  ; 'G'

; -------------------------
; Find Note Duration Length
; -------------------------
; Entry: C=Duration value (0 to 12, although a value of 0 is never used).
; Exit : DE=Note duration length.

L0DBD:
	PUSH HL	   ; Save HL.

	LD   B,$00	;
	LD   HL,L0DC9     ; Note duration table.
	ADD  HL,BC	; Index into the table.
	LD   D,$00	;
	LD   E,(HL)       ; Fetch the length from the table.

	POP  HL	   ; Restore HL.
	RET	       ;

; -------------------
; Note Duration Table
; -------------------
; A whole note is given by a value of 96d and other notes defined in relation to this.
; The value of 96d is the lowest common denominator from which all note durations
; can be defined.

L0DC9:
	defb $80	  ; Rest		 [Not used since table is always indexed into with a value of 1 or more]
	defb $06	  ; Semi-quaver	  (sixteenth note).
	defb $09	  ; Dotted semi-quaver   (3/32th note).
	defb $0C	  ; Quaver	       (eighth note).
	defb $12	  ; Dotted quaver	(3/16th note).
	defb $18	  ; Crotchet	     (quarter note).
	defb $24	  ; Dotted crotchet      (3/8th note).
	defb $30	  ; Minim		(half note).
	defb $48	  ; Dotted minim	 (3/4th note).
	defb $60	  ; Semi-breve	   (whole note).
	defb $04	  ; Triplet semi-quaver  (1/24th note).
	defb $08	  ; Triplet quaver       (1/12th note).
	defb $10	  ; Triplet crochet      (1/6th note).

; -----------------
; Is Numeric Digit?
; -----------------
; Tests whether a character is a number digit.
; Entry: A=Character.
; Exit : Carry flag reset if a number digit.

L0DD6:
	CP   '0'	  ; $30. Is it '0' or less?
	RET  C	    ; Return with carry flag set if so.

	CP   ':'	  ; $3A. Is it more than '9'?
	CCF	       ;
	RET	       ; Return with carry flag set if so.

; -----------------------------------
; Play a Note On a Sound Chip Channel
; -----------------------------------
; This routine plays the note at the current octave and current volume on a sound chip channel. For play strings 4 to 8,
; it simply stores the note number and this is subsequently played later.
; Entry: IX=Address of the channel data block.
;	A=Note value as number of semitones above C (0..11).

L0DDD:
	LD   C,A	  ; C=The note value.
	LD   A,(IX+$03)   ; Octave number * 12.
	ADD  A,C	  ; Add the octave number and the note value to form the note number.
	CP   $80	  ; Is note within range?
	JP   NC,L0EC4     ; Jump if not to produce error report "m Note out of range".

	LD   C,A	  ; C=Note number.
	LD   A,(IX+$02)   ; Get the channel number.
	OR   A	    ; Is it the first channel?
	JR   NZ,L0DF1     ; Jump ahead if not.

;Only set the noise generator frequency on the first channel

	LD   A,C	  ; A=Note number (0..107), in ascending audio frequency.
	CPL	       ; Invert since noise register value is in descending audio frequency.
	AND  $7F	  ; Mask off bit 7.
	SRL  A	    ;
	SRL  A	    ; Divide by 4 to reduce range to 0..31.
	LD   D,$06	; Register 6 - Noise pitch.
	LD   E,A	  ;
	CALL L0E2E	; Write to sound generator register.

L0DF1:
	LD   (IX+$00),C   ; Store the note number.
	LD   A,(IX+$02)   ; Get the channel number.
	CP   $03	  ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
	RET  NC	   ; Do not output anything for play strings 4 to 8.

;Channel 0, 1 or 2

	LD   HL,L1048     ; Start of note lookup table.
	LD   B,$00	; BC=Note number.
	SLA  C	    ; Generate offset into the table.
	ADD  HL,BC	; Point to the entry in the table.
	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; DE=Word to write to the sound chip registers to produce this note.

L0E10:
	EX   DE,HL	; HL=Register word value to produce the note.

	LD   D,(IX+$02)   ; Get the channel number.
	SLA  D	    ; D=2*Channel number, to give the tone channel register (fine control) number 0, 2, or 4.
	LD   E,L	  ; E=The low value byte.
	CALL L0E2E	; Write to sound generator register.

	INC  D	    ; D=Tone channel register (coarse control) number 1, 3, or 5.
	LD   E,H	  ; E=The high value byte.
	CALL L0E2E	; Write to sound generator register.

	BIT  4,(IX+$04)   ; Is the envelope waveform being used?
	RET  Z	    ; Return if it is not.

	LD   D,$0D	; Register 13 - Envelope Shape.
	LD   A,(IY+$29)   ; Get the effect waveform value.
	LD   E,A	  ;

; ----------------------------
; Set Sound Generator Register
; ----------------------------
; Entry: D=Register to write.
;	E=Value to set register to.

L0E2E:
	PUSH BC	   ;

	LD   BC,$FFFD     ;
	OUT  (C),D	; Select the register.
	LD   BC,$BFFD     ;
	OUT  (C),E	; Write out the value.

	POP  BC	   ;
	RET	       ;

; -----------------------------
; Read Sound Generator Register
; -----------------------------
; Entry: A=Register to read.
; Exit : A=Value of currently selected sound generator register.

L0E3B:
	PUSH BC	   ;

	LD   BC,$FFFD     ;
	OUT  (C),A	; Select the register.
	IN   A,(C)	; Read the register's value.

	POP  BC	   ;
	RET	       ;

; ------------------
; Turn Off All Sound
; ------------------

L0E45:
	LD   D,$07	; Register 7 - Mixer.
	LD   E,$FF	; I/O ports are inputs, noise output off, tone output off.
	CALL L0E2E	; Write to sound generator register.

;Turn off the sound from the AY-3-8912

	LD   D,$08	; Register 8 - Channel A volume.
	LD   E,$00	; Volume of 0.
	CALL L0E2E	; Write to sound generator register to set the volume to 0.

	INC  D	    ; Register 9 - Channel B volume.
	CALL L0E2E	; Write to sound generator register to set the volume to 0.

	INC  D	    ; Register 10 - Channel C volume.
	CALL L0E2E	; Write to sound generator register to set the volume to 0.

	CALL L0A09	; Select channel data block pointers.

;Now reset all MIDI channels in use

L0E5E:
	RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
	JR   C,L0E6A      ; Jump ahead if there is no string for this channel.

	CALL L0A21	; Get address of channel data block for the current string into IX.
	CALL L1169	; Turn off the MIDI channel sound assigned to this play string.

L0E6A:
	SLA  (IY+$21)     ; Have all channels been processed?
	JR   C,L0E75      ; Jump ahead if so.

	CALL L0A28	; Advance to the next channel data block pointer.
	JR   L0E5E	; Jump back to process the next channel.

L0E75:
	LD   IY,$5C3A     ; Restore IY.
	EI		; Re-enable interrupts.
	RET	       ;

; ---------------------------------------
; Get Previous Character from Play String
; ---------------------------------------
; Get the previous character from the PLAY string, skipping over spaces and 'Enter' characters.
; Entry: IX=Address of the channel data block.

L0E7A:
	PUSH HL	   ; Save registers.
	PUSH DE	   ;

	LD   L,(IX+$06)   ; Get the current pointer into the PLAY string.
	LD   H,(IX+$07)   ;

L0E82:
	DEC  HL	   ; Point to previous character.
	LD   A,(HL)       ; Fetch the character.
	CP   ' '	  ; $20. Is it a space?
	JR   Z,L0E82      ; Jump back if a space.

	CP   $0D	  ; Is it an 'Enter'?
	JR   Z,L0E82      ; Jump back if an 'Enter'.

	LD   (IX+$06),L   ; Store this as the new current pointer into the PLAY string.
	LD   (IX+$07),H   ;

	POP  DE	   ; Restore registers.
	POP  HL	   ;
	RET	       ;

; --------------------------------------
; Get Current Character from Play String
; --------------------------------------
; Get the current character from the PLAY string, skipping over spaces and 'Enter' characters.
; Exit: Carry flag set if string has been fully processed.
;       Carry flag reset if character is available.
;       A=Character available.

L0E95:
	PUSH HL	   ; Save registers.
	PUSH DE	   ;
	PUSH BC	   ;

	LD   L,(IX+$06)   ; HL=Pointer to next character to process within the PLAY string.
	LD   H,(IX+$07)   ;

L0E9E:
	LD   A,H	  ;
	CP   (IX+$09)     ; Reached end-of-string address high byte?
	JR   NZ,L0EAD     ; Jump forward if not.

	LD   A,L	  ;
	CP   (IX+$08)     ; Reached end-of-string address low byte?
	JR   NZ,L0EAD     ; Jump forward if not.

	SCF	       ; Indicate string all processed.
	JR   L0EB7	; Jump forward to return.

L0EAD:
	LD   A,(HL)       ; Get the next play character.
	CP   ' '	  ; $20. Is it a space?
	JR   Z,L0EBB      ; Ignore the space by jumping ahead to process the next character.

	CP   $0D	  ; Is it 'Enter'?
	JR   Z,L0EBB      ; Ignore the 'Enter' by jumping ahead to process the next character.

	OR   A	    ; Clear the carry flag to indicate a new character has been returned.

L0EB7:
	POP  BC	   ; Restore registers.
	POP  DE	   ;
	POP  HL	   ;
	RET	       ;

L0EBB:
	INC  HL	   ; Point to the next character.
	LD   (IX+$06),L   ;
	LD   (IX+$07),H   ; Update the pointer to the next character to process with the PLAY string.
	JR   L0E9E	; Jump back to get the next character.

; --------------------------
; Produce Play Error Reports
; --------------------------

L0EC4:
	CALL L0E45	; Turn off all sound and restore IY.
	rst $18;
	defw report_q;


; -------------------------
; Play Note on Each Channel
; -------------------------
; Play a note and set the volume on each channel for which a play string exists.

L0EF4:
	CALL L0A09	; Select channel data block pointers.

L0EF7:
	RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
	JR   C,L0F1E      ; Jump ahead if there is no string for this channel.

	CALL L0A21	; Get address of channel data block for the current string into IX.

	CALL L0A8B	; Get the next note in the string as number of semitones above note C.
	CP   $80	  ; Is it a rest?
	JR   Z,L0F1E      ; Jump ahead if so and do nothing to the channel.

	CALL L0DDD	; Play the note if a sound chip channel.

	LD   A,(IX+$02)   ; Get channel number.
	CP   $03	  ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
	JR   NC,L0F1B     ; Jump if not to skip setting the volume.

;One of the 3 sound chip generator channels so set the channel's volume for the new note

	LD   D,$08	;
	ADD  A,D	  ; A=0 to 2.
	LD   D,A	  ; D=Register (8 + string index), i.e. channel A, B or C volume register.
	LD   E,(IX+$04)   ; E=Volume for the current channel.
	CALL L0E2E	; Write to sound generator register to set the output volume.

L0F1B:
	CALL L114A	; Play a note and set the volume on the assigned MIDI channel.

L0F1E:
	SLA  (IY+$21)     ; Have all channels been processed?
	RET  C	    ; Return if so.

	CALL L0A28	; Advance to the next channel data block pointer.
	JR   L0EF7	; Jump back to process the next channel.

; ------------------
; Wait Note Duration
; ------------------
; This routine is the main timing control of the PLAY command.
; It waits for the specified length of time, which will be the
; lowest note duration of all active channels.
; The actual duration of the wait is dictated by the current tempo.
; Entry: DE=Note duration, where 96d represents a whole note.

;Enter a loop waiting for (135+ ((26*(tempo-100))-5) )*DE+5 T-states

L0F28:
	 LD   C,(IY+$27)   ; (19) Get the tempo timing value.
	 LD   B,(IY+$28)   ; (19)

;Tempo timing value = (10/(TEMPO*4))/7.33e-6, where 7.33e-6 is the time for 26 T-states.
;The loop below takes 26 T-states per iteration, where the number of iterations is given by the tempo timing value.
;So the time for the loop to execute is 2.5/TEMPO seconds.
;
;For a TEMPO of 60 beats (crotchets) per second, the time per crotchet is 1/24 second.
;The duration of a crotchet is defined as 24 from the table at $0E0C, therefore the loop will get executed 24 times
;and hence the total time taken will be 1 second.

L0F38:
	DEC  BC	   ; (6)  Wait for tempo-100 loops.
	LD   A,B	  ; (4)
	OR   C	    ; (4)
	JR   NZ,L0F38     ; (12/7)

	DEC  DE	   ; (6) Repeat DE times
	LD   A,D	  ; (4)
	OR   E	    ; (4)
	JR   NZ,L0F28     ; (12/7)

	RET	       ; (10)

; -----------------------------
; Find Smallest Duration Length
; -----------------------------
; This routine finds the smallest duration length for all current notes
; being played across all channels.
; Exit: DE=Smallest duration length.

L0F43:
	LD   DE,$FFFF     ; Set smallest duration length to 'maximum'.

	CALL L0A04	; Select channel data block duration pointers.

L0F49:
	RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
	JR   C,L0F61      ; Jump ahead if there is no string for this channel.

;HL=Address of channel data pointer. DE holds the smallest duration length found so far.

	PUSH DE	   ; Save the smallest duration length.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ;
	EX   DE,HL	; DE=Channel data block duration length.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; DE=Channel duration length.

	PUSH DE	   ;
	POP  HL	   ; HL=Channel duration length.

	POP  BC	   ; Last channel duration length.
	OR   A	    ;
	SBC  HL,BC	; Is current channel's duration length smaller than the smallest so far?
	JR   C,L0F61      ; Jump ahead if so, with the new smallest value in DE.

;The current channel's duration was not smaller so restore the last smallest into DE.

	PUSH BC	   ;
	POP  DE	   ; DE=Smallest duration length.

L0F61:
	SLA  (IY+$21)     ; Have all channel strings been processed?
	JR   C,L0F6C      ; Jump ahead if so.

	CALL L0A28	; Advance to the next channel data block duration pointer.
	JR   L0F49	; Jump back to process the next channel.

L0F6C:
	LD   (IY+$25),E   ;
	LD   (IY+$26),D   ; Store the smallest channel duration length.
	RET	       ;

; ---------------------------------------------------------------
; Play a Note on Each Channel and Update Channel Duration Lengths
; ---------------------------------------------------------------
; This routine is used to play a note and set the volume on all channels.
; It subtracts an amount of time from the duration lengths of all currently
; playing channel note durations. The amount subtracted is equivalent to the
; smallest note duration length currently being played, and as determined earlier.
; Hence one channel's duration will go to 0 on each call of this routine, and the
; others will show the remaining lengths of their corresponding notes.
; Entry: IY=Address of the command data block.

L0F73:
	XOR  A	    ;
	LD   (IY+$2A),A   ; Holds a temporary channel bitmap.

	CALL L0A09	; Select channel data block pointers.

L0F7A:
	RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
	JP   C,L100C      ; Jump ahead if there is no string for this channel.

	CALL L0A21	; Get address of channel data block for the current string into IX.

	PUSH IY	   ;
	POP  HL	   ; HL=Address of the command data block.

	LD   BC,$0011     ;
	ADD  HL,BC	; HL=Address of channel data block duration pointers.

	LD   B,$00	;
	LD   C,(IX+$02)   ; BC=Channel number.
	SLA  C	    ; BC=2*Channel number.
	ADD  HL,BC	; HL=Address of channel data block duration pointer for this channel.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; DE=Address of duration length within the channel data block.

	EX   DE,HL	; HL=Address of duration length within the channel data block.
	PUSH HL	   ; Save it.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; DE=Duration length for this channel.

	EX   DE,HL	; HL=Duration length for this channel.

	LD   E,(IY+$25)   ;
	LD   D,(IY+$26)   ; DE=Smallest duration length of all current channel notes.

	OR   A	    ;
	SBC  HL,DE	; HL=Duration length - smallest duration length.
	EX   DE,HL	; DE=Duration length - smallest duration length.

	POP  HL	   ; HL=Address of duration length within the channel data block.
	JR   Z,L0FAE      ; Jump if this channel uses the smallest found duration length.

	LD   (HL),E       ;
	INC  HL	   ; Update the duration length for this channel with the remaining length.
	LD   (HL),D       ;

	JR   L100C	; Jump ahead to update the next channel.

;The current channel uses the smallest found duration length

;[A note has been completed and so the channel volume is set to 0 prior to the next note being played.
;This occurs on both sound chip channels and MIDI channels. When a MIDI channel is assigned to more than
;one play string and a rest is used in one of those strings. As soon as the end of the rest period is
;encountered, the channel's volume is set to off even though one of the other play strings controlling
;the MIDI channel may still be playing. This can be seen using the command PLAY "Y1a&", "Y1N9a". Here,
;string 1 starts playing 'a' for the period of a crotchet (1/4 of a note), where as string 2 starts playing
;'a' for nine periods of a crotchet (9/4 of a note). When string 1 completes its crotchet, it requests
;to play a period of silence via the rest '&'. This turns the volume of the MIDI channel off even though
;string 2 is still timing its way through its nine crotchets. The play command will therefore continue for
;a further seven crotchets but in silence. This is because the volume for note is set only at its start
;and no coordination occurs between strings to turn the volume back on for the second string. It is arguably
;what the correct behaviour should be in such a circumstance where the strings are providing conflicting instructions,
;but having the latest command or note take precedence seems a logical approach. Credit: Ian Collier (+3), Paul Farrow (128)]

L0FAE:
	LD   A,(IX+$02)   ; Get the channel number.
	CP   $03	  ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
	JR   NC,L0FBE     ; Jump ahead if not a sound generator channel.

	LD   D,$08	;
	ADD  A,D	  ;
	LD   D,A	  ; D=Register (8+channel number) - Channel volume.
	LD   E,$00	; E=Volume level of 0.
	CALL L0E2E	; Write to sound generator register to turn the volume off.

L0FBE:
	CALL L1169	; Turn off the assigned MIDI channel sound.

	PUSH IX	   ;
	POP  HL	   ; HL=Address of channel data block.

	LD   BC,$0021     ;
	ADD  HL,BC	; HL=Points to the tied notes counter.

	DEC  (HL)	 ; Decrement the tied notes counter. [This contains a value of 1 for a single note]
	JR   NZ,L0FD8     ; Jump ahead if there are more tied notes.

	CALL L0B16	; Find the next note to play for this channel from its play string.

	LD   A,(IY+$21)   ; Fetch the channel selector.
	AND  (IY+$10)     ; Test whether this channel has further data in its play string.
	JR   NZ,L100C     ; Jump to process the next channel if this channel does not have a play string.

	JR   L0FEF	; The channel has more data in its play string so jump ahead.

;The channel has more tied notes

L0FD8:
	PUSH IY	   ;
	POP  HL	   ; HL=Address of the command data block.

	LD   BC,$0011     ;
	ADD  HL,BC	; HL=Address of channel data block duration pointers.

	LD   B,$00	;
	LD   C,(IX+$02)   ; BC=Channel number.
	SLA  C	    ; BC=2*Channel number.
	ADD  HL,BC	; HL=Address of channel data block duration pointer for this channel.

	LD   E,(HL)       ;
	INC  HL	   ;
	LD   D,(HL)       ; DE=Address of duration length within the channel data block.

	INC  DE	   ;
	INC  DE	   ; Point to the subsequent note duration length.

	LD   (HL),D       ;
	DEC  HL	   ;
	LD   (HL),E       ; Store the new duration length.

L0FEF:
	CALL L0A8B	; Get next note in the string as number of semitones above note C.
	LD   C,A	  ; C=Number of semitones.

	LD   A,(IY+$21)   ; Fetch the channel selector.
	AND  (IY+$10)     ; Test whether this channel has a play string.
	JR   NZ,L100C     ; Jump to process the next channel if this channel does not have a play string.

	LD   A,C	  ; A=Number of semitones.
	CP   $80	  ; Is it a rest?
	JR   Z,L100C      ; Jump to process the next channel if it is.

	CALL L0DDD	; Play the new note on this channel at the current volume if a sound chip channel, or simply store the note for play strings 4 to 8.

	LD   A,(IY+$21)   ; Fetch the channel selector.
	OR   (IY+$2A)     ; Insert a bit in the temporary channel bitmap to indicate this channel has more to play.
	LD   (IY+$2A),A   ; Store it.

;Check whether another channel needs its duration length updated

L100C:
	SLA  (IY+$21)     ; Have all channel strings been processed?
	JR   C,L1018      ; Jump ahead if so.

	CALL L0A28	; Advance to the next channel data pointer.
	JP   L0F7A	; Jump back to update the duration length for the next channel.

L1018:
	CALL L0A09	; Select channel data block pointers.

;All channel durations have been updated. Update the volume on each sound chip channel, and the volume and note on each MIDI channel

L1021:
	RR   (IY+$2A)     ; Temporary channel bitmap. Test if next string present.
	JR   NC,L103E     ; Jump ahead if there is no string for this channel.

	CALL L0A21	; Get address of channel data block for the current string into IX.

	LD   A,(IX+$02)   ; Get the channel number.
	CP   $03	  ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
	JR   NC,L103B     ; Jump ahead if so to process the next channel.

	LD   D,$08	;
	ADD  A,D	  ;
	LD   D,A	  ; D=Register (8+channel number) - Channel volume.
	LD   E,(IX+$04)   ; Get the current volume.
	CALL L0E2E	; Write to sound generator register to set the volume of the channel.

L103B:
	CALL L114A	; Play a note and set the volume on the assigned MIDI channel.

L103E:
	SLA  (IY+$21)     ; Have all channels been processed?
	RET  C	    ; Return if so.

	CALL L0A28	; Advance to the next channel data pointer.
	JR   L1021	; Jump back to process the next channel.

; -----------------
; Note Lookup Table
; -----------------
; Each word gives the value of the sound generator tone registers for a given note.
; There are 10 octaves, containing a total of 128 notes. Notes 0 to 20 cannot be
; reproduced correctly on the sound chip and so only notes 21 to 128 should be used.
; However, they will be sent to a MIDI device if one is assigned to a channel.
; [Note that both the sound chip and the MIDI port can not play note 128 and so
; its inclusion in the table is a waste of 2 bytes]. The PLAY command does not allow
; octaves higher than 8 to be selected directly. Using PLAY "O8G" will select note 115. To
; select higher notes, sharps must be included, e.g. PLAY "O8#G" for note 116, PLAY "O8##G"
; for note 117, etc, up to PLAY "O8############G" for note 127. Attempting to access note
; 128 using PLAY "O8#############G" will lead to error report "m Note out of range".

L1048:
	defw $34F5	; Octave  0, Note   0 - C  ( 8.18Hz, Ideal= 8.18Hz, Error=-0.00%) C-1
	defw $31FC	; Octave  0, Note   1 - C# ( 8.66Hz, Ideal= 8.66Hz, Error=-0.00%)
	defw $2F2E	; Octave  0, Note   2 - D  ( 9.18Hz, Ideal= 9.18Hz, Error=+0.00%)
	defw $2C88	; Octave  0, Note   3 - D# ( 9.72Hz, Ideal= 9.72Hz, Error=+0.01%)
	defw $2A08	; Octave  0, Note   4 - E  (10.30Hz, Ideal=10.30Hz, Error=+0.00%)
	defw $27AC	; Octave  0, Note   5 - F  (10.91Hz, Ideal=10.91Hz, Error=+0.00%)
	defw $2572	; Octave  0, Note   6 - F# (11.56Hz, Ideal=11.56Hz, Error=+0.00%)
	defw $2358	; Octave  0, Note   7 - G  (12.25Hz, Ideal=12.25Hz, Error=+0.00%)
	defw $215D	; Octave  0, Note   8 - G# (12.98Hz, Ideal=12.98Hz, Error=-0.00%)
	defw $1F7D	; Octave  0, Note   9 - A  (13.75Hz, Ideal=13.75Hz, Error=+0.00%)
	defw $1DB9	; Octave  0, Note  10 - A# (14.57Hz, Ideal=14.58Hz, Error=-0.10%)
	defw $1C0E	; Octave  0, Note  11 - B  (15.43Hz, Ideal=15.43Hz, Error=-0.00%)

	defw $1A7A	; Octave  1, Note  12 - C  (16.35Hz, Ideal=16.35Hz, Error=+0.01%) C0
	defw $18FE	; Octave  1, Note  13 - C# (17.32Hz, Ideal=17.33Hz, Error=-0.00%)
	defw $1797	; Octave  1, Note  14 - D  (18.35Hz, Ideal=18.35Hz, Error=+0.00%)
	defw $1644	; Octave  1, Note  15 - D# (19.45Hz, Ideal=19.44Hz, Error=+0.01%)
	defw $1504	; Octave  1, Note  16 - E  (20.60Hz, Ideal=20.60Hz, Error=+0.00%)
	defw $13D6	; Octave  1, Note  17 - F  (21.83Hz, Ideal=21.83Hz, Error=+0.00%)
	defw $12B9	; Octave  1, Note  18 - F# (23.13Hz, Ideal=23.13Hz, Error=+0.00%)
	defw $11AC	; Octave  1, Note  19 - G  (24.50Hz, Ideal=24.50Hz, Error=+0.00%)
	defw $10AE	; Octave  1, Note  20 - G# (25.96Hz, Ideal=25.96Hz, Error=+0.01%)
	defw $0FBF	; Octave  1, Note  21 - A  (27.50Hz, Ideal=27.50Hz, Error=-0.01%)
	defw $0EDC	; Octave  1, Note  22 - A# (29.14Hz, Ideal=29.16Hz, Error=-0.08%)
	defw $0E07	; Octave  1, Note  23 - B  (30.87Hz, Ideal=30.87Hz, Error=-0.00%)

	defw $0D3D	; Octave  2, Note  24 - C  (32.71Hz, Ideal=32.70Hz, Error=+0.01%) C1
	defw $0C7F	; Octave  2, Note  25 - C# (34.65Hz, Ideal=34.65Hz, Error=-0.00%)
	defw $0BCC	; Octave  2, Note  26 - D  (36.70Hz, Ideal=36.71Hz, Error=-0.01%)
	defw $0B22	; Octave  2, Note  27 - D# (38.89Hz, Ideal=38.89Hz, Error=+0.01%)
	defw $0A82	; Octave  2, Note  28 - E  (41.20Hz, Ideal=41.20Hz, Error=+0.00%)
	defw $09EB	; Octave  2, Note  29 - F  (43.66Hz, Ideal=43.65Hz, Error=+0.00%)
	defw $095D	; Octave  2, Note  30 - F# (46.24Hz, Ideal=46.25Hz, Error=-0.02%)
	defw $08D6	; Octave  2, Note  31 - G  (49.00Hz, Ideal=49.00Hz, Error=+0.00%)
	defw $0857	; Octave  2, Note  32 - G# (51.92Hz, Ideal=51.91Hz, Error=+0.01%)
	defw $07DF	; Octave  2, Note  33 - A  (55.01Hz, Ideal=55.00Hz, Error=+0.01%)
	defw $076E	; Octave  2, Note  34 - A# (58.28Hz, Ideal=58.33Hz, Error=-0.08%)
	defw $0703	; Octave  2, Note  35 - B  (61.75Hz, Ideal=61.74Hz, Error=+0.02%)

	defw $069F	; Octave  3, Note  36 - C  ( 65.39Hz, Ideal= 65.41Hz, Error=-0.02%) C2
	defw $0640	; Octave  3, Note  37 - C# ( 69.28Hz, Ideal= 69.30Hz, Error=-0.04%)
	defw $05E6	; Octave  3, Note  38 - D  ( 73.40Hz, Ideal= 73.42Hz, Error=-0.01%)
	defw $0591	; Octave  3, Note  39 - D# ( 77.78Hz, Ideal= 77.78Hz, Error=+0.01%)
	defw $0541	; Octave  3, Note  40 - E  ( 82.41Hz, Ideal= 82.41Hz, Error=+0.00%)
	defw $04F6	; Octave  3, Note  41 - F  ( 87.28Hz, Ideal= 87.31Hz, Error=-0.04%)
	defw $04AE	; Octave  3, Note  42 - F# ( 92.52Hz, Ideal= 92.50Hz, Error=+0.02%)
	defw $046B	; Octave  3, Note  43 - G  ( 98.00Hz, Ideal= 98.00Hz, Error=+0.00%)
	defw $042C	; Octave  3, Note  44 - G# (103.78Hz, Ideal=103.83Hz, Error=-0.04%)
	defw $03F0	; Octave  3, Note  45 - A  (109.96Hz, Ideal=110.00Hz, Error=-0.04%)
	defw $03B7	; Octave  3, Note  46 - A# (116.55Hz, Ideal=116.65Hz, Error=-0.08%)
	defw $0382	; Octave  3, Note  47 - B  (123.43Hz, Ideal=123.47Hz, Error=-0.03%)

	defw $034F	; Octave  4, Note  48 - C  (130.86Hz, Ideal=130.82Hz, Error=+0.04%) C3
	defw $0320	; Octave  4, Note  49 - C# (138.55Hz, Ideal=138.60Hz, Error=-0.04%)
	defw $02F3	; Octave  4, Note  50 - D  (146.81Hz, Ideal=146.83Hz, Error=-0.01%)
	defw $02C8	; Octave  4, Note  51 - D# (155.68Hz, Ideal=155.55Hz, Error=+0.08%)
	defw $02A1	; Octave  4, Note  52 - E  (164.70Hz, Ideal=164.82Hz, Error=-0.07%)
	defw $027B	; Octave  4, Note  53 - F  (174.55Hz, Ideal=174.62Hz, Error=-0.04%)
	defw $0257	; Octave  4, Note  54 - F# (185.04Hz, Ideal=185.00Hz, Error=+0.02%)
	defw $0236	; Octave  4, Note  55 - G  (195.83Hz, Ideal=196.00Hz, Error=-0.09%)
	defw $0216	; Octave  4, Note  56 - G# (207.57Hz, Ideal=207.65Hz, Error=-0.04%)
	defw $01F8	; Octave  4, Note  57 - A  (219.92Hz, Ideal=220.00Hz, Error=-0.04%)
	defw $01DC	; Octave  4, Note  58 - A# (232.86Hz, Ideal=233.30Hz, Error=-0.19%)
	defw $01C1	; Octave  4, Note  59 - B  (246.86Hz, Ideal=246.94Hz, Error=-0.03%)

	defw $01A8	; Octave  5, Note  60 - C  (261.42Hz, Ideal=261.63Hz, Error=-0.08%) C4 Middle C
	defw $0190	; Octave  5, Note  61 - C# (277.10Hz, Ideal=277.20Hz, Error=-0.04%)
	defw $0179	; Octave  5, Note  62 - D  (294.01Hz, Ideal=293.66Hz, Error=+0.12%)
	defw $0164	; Octave  5, Note  63 - D# (311.35Hz, Ideal=311.10Hz, Error=+0.08%)
	defw $0150	; Octave  5, Note  64 - E  (329.88Hz, Ideal=329.63Hz, Error=+0.08%)
	defw $013D	; Octave  5, Note  65 - F  (349.65Hz, Ideal=349.23Hz, Error=+0.12%)
	defw $012C	; Octave  5, Note  66 - F# (369.47Hz, Ideal=370.00Hz, Error=-0.14%)
	defw $011B	; Octave  5, Note  67 - G  (391.66Hz, Ideal=392.00Hz, Error=-0.09%)
	defw $010B	; Octave  5, Note  68 - G# (415.13Hz, Ideal=415.30Hz, Error=-0.04%)
	defw $00FC	; Octave  5, Note  69 - A  (439.84Hz, Ideal=440.00Hz, Error=-0.04%)
	defw $00EE	; Octave  5, Note  70 - A# (465.72Hz, Ideal=466.60Hz, Error=-0.19%)
	defw $00E0	; Octave  5, Note  71 - B  (494.82Hz, Ideal=493.88Hz, Error=+0.19%)

	defw $00D4	; Octave  6, Note  72 - C  (522.83Hz, Ideal=523.26Hz, Error=-0.08%) C5
	defw $00C8	; Octave  6, Note  73 - C# (554.20Hz, Ideal=554.40Hz, Error=-0.04%)
	defw $00BD	; Octave  6, Note  74 - D  (586.46Hz, Ideal=587.32Hz, Error=-0.15%)
	defw $00B2	; Octave  6, Note  75 - D# (622.70Hz, Ideal=622.20Hz, Error=+0.08%)
	defw $00A8	; Octave  6, Note  76 - E  (659.77Hz, Ideal=659.26Hz, Error=+0.08%)
	defw $009F	; Octave  6, Note  77 - F  (697.11Hz, Ideal=698.46Hz, Error=-0.19%)
	defw $0096	; Octave  6, Note  78 - F# (738.94Hz, Ideal=740.00Hz, Error=-0.14%)
	defw $008D	; Octave  6, Note  79 - G  (786.10Hz, Ideal=784.00Hz, Error=+0.27%)
	defw $0085	; Octave  6, Note  80 - G# (833.39Hz, Ideal=830.60Hz, Error=+0.34%)
	defw $007E	; Octave  6, Note  81 - A  (879.69Hz, Ideal=880.00Hz, Error=-0.04%)
	defw $0077	; Octave  6, Note  82 - A# (931.43Hz, Ideal=933.20Hz, Error=-0.19%)
	defw $0070	; Octave  6, Note  83 - B  (989.65Hz, Ideal=987.76Hz, Error=+0.19%)

	defw $006A	; Octave  7, Note  84 - C  (1045.67Hz, Ideal=1046.52Hz, Error=-0.08%) C6
	defw $0064	; Octave  7, Note  85 - C# (1108.41Hz, Ideal=1108.80Hz, Error=-0.04%)
	defw $005E	; Octave  7, Note  86 - D  (1179.16Hz, Ideal=1174.64Hz, Error=+0.38%)
	defw $0059	; Octave  7, Note  87 - D# (1245.40Hz, Ideal=1244.40Hz, Error=+0.08%)
	defw $0054	; Octave  7, Note  88 - E  (1319.53Hz, Ideal=1318.52Hz, Error=+0.08%)
	defw $004F	; Octave  7, Note  89 - F  (1403.05Hz, Ideal=1396.92Hz, Error=+0.44%)
	defw $004B	; Octave  7, Note  90 - F# (1477.88Hz, Ideal=1480.00Hz, Error=-0.14%)
	defw $0047	; Octave  7, Note  91 - G  (1561.14Hz, Ideal=1568.00Hz, Error=-0.44%)
	defw $0043	; Octave  7, Note  92 - G# (1654.34Hz, Ideal=1661.20Hz, Error=-0.41%)
	defw $003F	; Octave  7, Note  93 - A  (1759.38Hz, Ideal=1760.00Hz, Error=-0.04%)
	defw $003B	; Octave  7, Note  94 - A# (1878.65Hz, Ideal=1866.40Hz, Error=+0.66%)
	defw $0038	; Octave  7, Note  95 - B  (1979.30Hz, Ideal=1975.52Hz, Error=+0.19%)

	defw $0035	; Octave  8, Note  96 - C  (2091.33Hz, Ideal=2093.04Hz, Error=-0.08%) C7
	defw $0032	; Octave  8, Note  97 - C# (2216.81Hz, Ideal=2217.60Hz, Error=-0.04%)
	defw $002F	; Octave  8, Note  98 - D  (2358.31Hz, Ideal=2349.28Hz, Error=+0.38%)
	defw $002D	; Octave  8, Note  99 - D# (2463.13Hz, Ideal=2488.80Hz, Error=-1.03%)
	defw $002A	; Octave  8, Note 100 - E  (2639.06Hz, Ideal=2637.04Hz, Error=+0.08%)
	defw $0028	; Octave  8, Note 101 - F  (2771.02Hz, Ideal=2793.84Hz, Error=-0.82%)
	defw $0025	; Octave  8, Note 102 - F# (2995.69Hz, Ideal=2960.00Hz, Error=+1.21%)
	defw $0023	; Octave  8, Note 103 - G  (3166.88Hz, Ideal=3136.00Hz, Error=+0.98%)
	defw $0021	; Octave  8, Note 104 - G# (3358.81Hz, Ideal=3322.40Hz, Error=+1.10%)
	defw $001F	; Octave  8, Note 105 - A  (3575.50Hz, Ideal=3520.00Hz, Error=+1.58%)
	defw $001E	; Octave  8, Note 106 - A# (3694.69Hz, Ideal=3732.80Hz, Error=-1.02%)
	defw $001C	; Octave  8, Note 107 - B  (3958.59Hz, Ideal=3951.04Hz, Error=+0.19%)

	defw $001A	; Octave  9, Note 108 - C  (4263.10Hz, Ideal=4186.08Hz, Error=+1.84%) C8
	defw $0019	; Octave  9, Note 109 - C# (4433.63Hz, Ideal=4435.20Hz, Error=-0.04%)
	defw $0018	; Octave  9, Note 110 - D  (4618.36Hz, Ideal=4698.56Hz, Error=-1.71%)
	defw $0016	; Octave  9, Note 111 - D# (5038.21Hz, Ideal=4977.60Hz, Error=+1.22%)
	defw $0015	; Octave  9, Note 112 - E  (5278.13Hz, Ideal=5274.08Hz, Error=+0.08%)
	defw $0014	; Octave  9, Note 113 - F  (5542.03Hz, Ideal=5587.68Hz, Error=-0.82%)
	defw $0013	; Octave  9, Note 114 - F# (5833.72Hz, Ideal=5920.00Hz, Error=-1.46%)
	defw $0012	; Octave  9, Note 115 - G  (6157.81Hz, Ideal=6272.00Hz, Error=-1.82%)
	defw $0011	; Octave  9, Note 116 - G# (6520.04Hz, Ideal=6644.80Hz, Error=-1.88%)
	defw $0010	; Octave  9, Note 117 - A  (6927.54Hz, Ideal=7040.00Hz, Error=-1.60%)
	defw $000F	; Octave  9, Note 118 - A# (7389.38Hz, Ideal=7465.60Hz, Error=-1.02%)
	defw $000E	; Octave  9, Note 119 - B  (7917.19Hz, Ideal=7902.08Hz, Error=+0.19%)

	defw $000D	; Octave 10, Note 120 - C  ( 8526.20Hz, Ideal= 8372.16Hz, Error=+1.84%) C9
	defw $000C	; Octave 10, Note 121 - C# ( 9236.72Hz, Ideal= 8870.40Hz, Error=+4.13%)
	defw $000C	; Octave 10, Note 122 - D  ( 9236.72Hz, Ideal= 9397.12Hz, Error=-1.71%)
	defw $000B	; Octave 10, Note 123 - D# (10076.42Hz, Ideal= 9955.20Hz, Error=+1.22%)
	defw $000B	; Octave 10, Note 124 - E  (10076.42Hz, Ideal=10548.16Hz, Error=-4.47%)
	defw $000A	; Octave 10, Note 125 - F  (11084.06Hz, Ideal=11175.36Hz, Error=-0.82%)
	defw $0009	; Octave 10, Note 126 - F# (12315.63Hz, Ideal=11840.00Hz, Error=+4.02%)
	defw $0009	; Octave 10, Note 127 - G  (12315.63Hz, Ideal=12544.00Hz, Error=-1.82%)
	defw $0008	; Octave 10, Note 128 - G# (13855.08Hz, Ideal=13289.60Hz, Error=+4.26%)

; -------------------------
; Play Note on MIDI Channel
; -------------------------
; This routine turns on a note on the MIDI channel and sets its volume, if MIDI channel is assigned to the current string.
; Three bytes are sent, and have the following meaning:
;   Byte 1: Channel number $00..$0F, with bits 4 and 7 set.
;   Byte 2: Note number $00..$7F.
;   Byte 3: Note velocity $00..$7F.
; Entry: IX=Address of the channel data block.

L114A:
	LD   A,(IX+$01)   ; Is a MIDI channel assigned to this string?
	OR   A	    ;
	RET  M	    ; Return if not.

;A holds the assigned channel number ($00..$0F)

	OR   $90	  ; Set bits 4 and 7 of the channel number. A=$90..$9F.
	CALL L117F	; Write byte to MIDI device.

	LD   A,(IX+$00)   ; The note number.
	CALL L117F	; Write byte to MIDI device.

	LD   A,(IX+$04)   ; Fetch the channel's volume.
	RES  4,A	  ; Ensure the 'using envelope' bit is reset so
	SLA  A	    ; that A holds a value between $00 and $0F.
	SLA  A	    ; Multiply by 8 to increase the range to $00..$78.
	SLA  A	    ; A=Note velocity.
	JP   L117F	; Write byte to MIDI device.

; ---------------------
; Turn MIDI Channel Off
; ---------------------
; This routine turns off a note on the MIDI channel, if a MIDI channel is assigned to the current string.
; Three bytes are sent, and have the following meaning:
;   Byte 1: Channel number $00..$0F, with bit 7 set.
;   Byte 2: Note number $00..$7F.
;   Byte 3: Note velocity $00..$7F.
; Entry: IX=Address of the channel data block.

L1169:
	LD   A,(IX+$01)   ; Is a MIDI channel assigned to this string?
	OR   A	    ;
	RET  M	    ; Return if not.

;A holds the assigned channel number ($00..$0F)

	OR   $80	  ; Set bit 7 of the channel number. A=$80..$8F.
	CALL L117F	; Write byte to MIDI device.

	LD   A,(IX+$00)   ; The note number.
	CALL L117F	; Write byte to MIDI device.

	LD   A,$40	; The note velocity.

; ------------------------
; Send Byte to MIDI Device
; ------------------------
; This routine sends a byte to the MIDI port. MIDI devices communicate at 31250 baud,
; although this routine actually generates a baud rate of 31388, which is within the 1%
; tolerance supported by MIDI devices.
; Entry: A=Byte to send.

L117F:
	LD   L,A	  ; Store the byte to send.

	LD   BC,$FFFD     ;
	LD   A,$0E	;
	OUT  (C),A	; Select register 14 - I/O port.

	LD   BC,$BFFD     ;
	LD   A,$FA	; Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
	OUT  (C),A	; Send out the START bit.

	LD   E,$03	; (7) Introduce delays such that the next bit is output 113 T-states from now.

L1190:
	DEC  E	    ; (4)
	JR   NZ,L1190     ; (12/7)

	NOP	       ; (4)
	NOP	       ; (4)
	NOP	       ; (4)
	NOP	       ; (4)

	LD   A,L	  ; (4) Retrieve the byte to send.

	LD   D,$08	; (7) There are 8 bits to send.

L119A:
	RRA	       ; (4) Rotate the next bit to send into the carry.
	LD   L,A	  ; (4) Store the remaining bits.
	JP   NC,L11A5     ; (10) Jump if it is a 0 bit.

	LD   A,$FE	; (7) Set RS232 'RXD' transmit line to 1. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
	OUT  (C),A	; (11)
	JR   L11AB	; (12) Jump forward to process the next bit.

L11A5:
	LD   A,$FA	; (7) Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
	OUT  (C),A	; (11)
	JR   L11AB	; (12) Jump forward to process the next bit.

L11AB:
	LD   E,$02	; (7) Introduce delays such that the next data bit is output 113 T-states from now.

L11AD:
	DEC  E	    ; (4)
	JR   NZ,L11AD     ; (12/7)

	NOP	       ; (4)
	ADD  A,$00	; (7)

	LD   A,L	  ; (4) Retrieve the remaining bits to send.
	DEC  D	    ; (4) Decrement the bit counter.
	JR   NZ,L119A     ; (12/7) Jump back if there are further bits to send.

	NOP	       ; (4) Introduce delays such that the stop bit is output 113 T-states from now.
	NOP	       ; (4)
	ADD  A,$00	; (7)
	NOP	       ; (4)
	NOP	       ; (4)

	LD   A,$FE	; (7) Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
	OUT  (C),A	; (11) Send out the STOP bit.

	LD   E,$06	; (7) Delay for 101 T-states (28.5us).

L11C3:
	DEC  E	    ; (4)
	JR   NZ,L11C3     ; (12/7)

	RET	       ; (10)
	

; This routine is copied to RAM as it must be run with BASIC paged in.
L5B00:
	rst $28;				// Invoke the floating point calculator.
	defb $A4;				// stk-ten.   = x, 10
	defb $01;				// exchange.  = 10, x
	defb $05;				// division.  = 10/x
	defb $34;				// stk-data.  = 10/x, 7.33e-6
	defb $DF;				// - exponent $6F (floating point number 7.33e-6).
	defb $75;				// - mantissa byte 1 -80
	defb $F4;				// - mantissa byte 2 -164
	defb $38;				// - mantissa byte 3 -92
	defb $75;				// - mantissa byte 4 -80
	defb $05;				// division.  = (10/x)/7.33e-6
	defb $38;				// end-calc.
	ret;

report_l:
	rst $08;
	defb $14;				// "L Break into program"

report_q:
	rst $08
	defb $19;				// "Q Parameter Error"

