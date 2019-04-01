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

output_bin "../dos/unocfg", $2000, $0800

include "unodos.api"
include "zx-uno.api"

org $2000
Main:
	ld a, h;
	or l;
	jr z, PrintAndExit;
	call RecogerParam;
	call ParseParam;
	jr nc, NoError;
	cp 255;
	ret z;
	ret c;

NoError:
	ld bc, zxunoaddr
	xor a;					// MASTERCONF
	out (c), a;
	inc b;
	ld a, (ConfValue);
	out (c), a;
	dec b;
	ld a, 11;
	out (c), a;
	inc b;
	ld a, (ScanDblCtrl);
	out (c), a;

PrintAndExit:
	call PrintCurrentMode;
	or a;
	ret;					// endproc

PrintCurrentMode:
	ld a, (QuietMode)
	or a
	ret nz
	call GetCoreID
	ld bc, zxunoaddr
	ld a, 0;				// MASTERCONF
	out (c), a
	inc b
	in a, (c)
	ld (ConfValue), a;		// Current config value
	dec b;
	ld a, 11;
	out (c), a;
	inc b;
	in a, (c);
	ld (ScanDblCtrl), a;
	ld hl, CurrConfString1;
	call v_pr_str;
	ld hl, TimmPenStr;
	ld a, (ConfValue);
	bit 6, a;
	jr nz, NoChTimm;
	ld hl, Timm128KStr;
	bit 4, a;
	jr nz, NoChTimm;
	ld hl, Timm48KStr;

NoChTimm:
	call v_pr_str;
	ld hl, CurrConfString2;
	call v_pr_str;
	ld hl, ContEnabledStr;
	ld a, (ConfValue);
	bit 5, a;
	jr z, NoChCont;
	ld hl, ContDisabledStr;

NoChCont:
	call v_pr_str;
	ld hl, CurrConfString3;
	call v_pr_str;
	ld a, (ConfValue);
	cpl;
	and $08;
	sra a;					// A = "2" or "3"
	sra a;					// depending upon the
	sra a;					// bit at 3
	or '2';
	rst $10;
	ld a, $0d;
	rst $10;
	call InitMouse;
	ld hl, CurrConfString4;
	call v_pr_str;
	ld hl, CurrConfString5;
	call v_pr_str;
	ld a, (ScanDblCtrl);
	and $c0;
	ld hl, Speed3d5Str;
	jr z, GoTurboPrint;
	cp $40;
	ld hl, Speed7Str;
	jr z, GoTurboPrint;
	cp $80;
	ld hl, Speed14Str;
	jr z, GoTurboPrint;
	ld hl, Speed28Str;

GoTurboPrint:
	call v_pr_str;
	ld hl, CurrConfString6;
	call v_pr_str;
	ld a, (ScanDblCtrl);
	ld hl, CompositeStr;
	bit 0, a;
	jr z, PrintVideo;
	ld hl, VGANoScansStr;
	and 3;
	cp 1;
	jr z, PrintVideo;
	ld hl, VGAScansStr;

PrintVideo:
	call v_pr_str;
	ld hl, CurrConfString7;
	call v_pr_str;
	ld a, (ScanDblCtrl);
	sra a;
	sra a;
	and 7;
	add a, a;
	ld e, a;
	ld d, 0;
	ld hl, TablaFreqStr;
	add hl, de;
	ld a, (hl);
	inc hl;
	ld h, (hl);
	ld l, a;
	call v_pr_str;

PrintHelpInfo:
	ld hl, HelpMsg;
	call v_pr_str;
	ret;					// endproc

RecogerParam:;				// HL points to the arguments
	ld de, BufferParam;

CheckCaracter:
	ld a, (hl);
	or a;
	jr z, FinRecoger;
	cp ':';
	jr z, FinRecoger
	cp 13
	jr z, FinRecoger
	ldi
	jr CheckCaracter

FinRecoger:
	ld a, " "
	ld (de), a
	inc de
	xor a
	ld (de), a
	ret;					// endproc

ParseParam:
	ld bc, zxunoaddr
	ld a, 0;				// MASTERCONF
	out (c), a
	inc b
	in a, (c)
	ld (ConfValue), a;		// Current config value
	ld bc, zxunoaddr
	ld a, 11;				// SCANDBLCTRL
	out (c), a;
	inc b;
	in a, (c);
	ld (ScanDblCtrl), a;
	ld hl, BufferParam;

OtroChar:
	ld a, (hl);
	inc hl;
	or a;
	ret z;
	cp ' ';
	jp z, OtroChar;
	cp '-';
	jp nz, ErrorInvalidArg;

	ld a, (hl);
	inc hl;
	cp 't';
	jp z, ParseTimming;
	cp 'c';
	jp z, ParseContention;
	cp 'k';
	jp z, ParseKeyboard;
	cp 'h';
	jp z, ParseHelp;
	cp 'q';
	jp z, ParseQuiet;
	cp 's';
	jp z, ParseSpeed;
	cp 'v';
	jp z, ParseVideo;
	cp 'f';
	jp z, ParseFreq;
	jp ErrorInvalidArg;

ParseTimming:
	ld a, (hl);
	inc hl
	cp '4';
	jp z, Parse48K;
	cp '1';
	jp z, Parse128K;
	cp 'p';
	jp z, ParsePentagon;
	jp ErrorInvalidArg;

Parse48K:
	ld a, (hl);
	inc hl;
	cp '8';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	and $af;				// clear bit 4 and 6
	ld (ConfValue), a;
	jp OtroChar;

Parse128K:
	ld a, (hl);
	inc hl;
	cp '2';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp '8';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	and $af;				// clear bit 4 and 6
	or $10;					// set bit 4
	ld (ConfValue), a;
	jp OtroChar;

ParsePentagon:
	ld a, (hl);
	inc hl;
	cp 'e';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp 'n';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	and $af;				// clear bit 4 and 6
	or $40;					// set bit 6
	ld (ConfValue), a;
	jp OtroChar;

ParseContention:
	ld a, (hl);
	inc hl;
	cp 'y';
	jp nz, PutDisableCont;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	and $df;
	ld (ConfValue), a;
	jp OtroChar;

PutDisableCont:
	cp 'n';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	or ' ';
	ld (ConfValue), a;
	jp OtroChar;

ParseKeyboard:
	ld a, (hl);
	inc hl;
	cp '3';
	jp nz, PutIssue2;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	and $f7;
	ld (ConfValue), a;
	jp OtroChar;

PutIssue2:
	cp '2';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ConfValue);
	or $08;
	ld (ConfValue), a;
	jp OtroChar;

ParseSpeed:
	ld a, (hl);
	inc hl;
	cp '0';
	jp c, ErrorInvalidArg;
	cp '4';
	jp nc, ErrorInvalidArg;
	ld b, a;
	ld a, (hl);
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, b;
	and 3;
	add a, a;
	add a, a;
	add a, a;
	add a, a;
	add a, a;
	add a, a;
	ld b, a;
	ld a, (ScanDblCtrl);
	and $3f;
	or b;
	ld (ScanDblCtrl), a;
	jp OtroChar;

ParseVideo:
	ld a, (hl);
	inc hl;
	cp '0';
	jp z, Modo15khz;
	cp '1';
	jp z, ModoVGANoScans;
	cp '2';
	jp nz, ErrorInvalidArg;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ScanDblCtrl);
	and $fc;
	or 3;
	ld (ScanDblCtrl), a;
	jp OtroChar;

Modo15khz:
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ScanDblCtrl);
	and $fc;
	ld (ScanDblCtrl), a;
	jp OtroChar;

ModoVGANoScans:
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, (ScanDblCtrl);
	and $fc;
	or 1;
	ld (ScanDblCtrl), a;
	jp OtroChar;

ParseFreq:
	ld a, (hl);
	inc hl;
	cp '0';
	jp c, ErrorInvalidArg;
	cp '8';
	jp nc, ErrorInvalidArg;
	sub '0';
	ld b, a;
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, b;
	add a, a;
	add a, a;
	ld b, a;
	ld a, (ScanDblCtrl);
	and $e3;
	or b;
	ld (ScanDblCtrl), a;
	jp OtroChar;

ParseHelp:
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld hl, Uso;
	call v_pr_str;
	ld a, 255;
	scf;
	ret;

ParseQuiet:
	ld a, (hl);
	inc hl;
	cp ' ';
	jp nz, ErrorInvalidArg;
	ld a, 1;
	ld (QuietMode), a;
	jp OtroChar;

ErrorInvalidArg:
	scf;					// use UnoDOS error.
	ld a, 2;				// Syntax error
	ret;					// Print it.

GetCoreID:
	ld bc, zxunoaddr;
	ld a, 255;
	out (c), a;
	inc b;
	in a, (c);
	ld hl, StringCoreID + 13;
	ld d, 32;

gettext:
	or a;
	jr z, finget;
	cp 128;
	jr nc, finget;
	ld (hl), a;
	inc hl;
	dec d;
	jr z, finget;
	in a, (c);
	jr gettext;

finget:
	ld a, (hl);
	cp 13;
	jr z, finrell;
	ld (hl), 32;
	inc hl;
	jr finget;

finrell:
	ret;					// endproc

InitMouse:
	ld bc, zxunoaddr;
	ld a, 9;
	out (c), a;
	inc b;
	ld a, $f4;
	out (c), a;

NoMouse:
	ret;					// endproc

Uso:
	defb "Configure/print ZX-Uno options.", $0d, $0d;
	defb "CONFIG [switches]", $0d;
	defb " No switches: print config", $0d;
	defb " -h : shows this help and exits", $0d;
	defb " -q : silent operation", $0d;

	defb " -tN: choose ULA timings", $0d;
	defb "      N=48:   48K timings", $0d;
	defb "      N=128: 128K timings", $0d;
	defb "      N=pen: Pentagon timings", $0d;

	defb " -cS: en/dis contention", $0d;
	defb "      S=y: enable contention", $0d;
	defb "      S=n: disable contention", $0d;

	defb " -kN: choose keyboard mode", $0d;
	defb "      N=2: issue 2 keyboard", $0d;
	defb "      N=3: issue 3 keyboard", $0d;

	defb " -sN: choose CPU speed", $0d;
	defb "      N=0: std. speed (3.5 Mhz)", $0d;
	defb "      N=1, 2 or 3: turbo speed", $0d;
	defb "             (7, 14 or 28 MHz)", $0d;

	defb " -vN: choose video output", $0d;
	defb "      N=0: composite/RGB 15kHz", $0d;
	defb "      N=1: VGA no scanlines", $0d;
	defb "      N=2: VGA with scanlines", $0d;

	defb " -fN: choose master frequency", $0d;
	defb "      N=0-7: master freq option", $0d, $0d;

	defb "Example: CONFIG -tpen -cn -k3", $0d;
	defb "  (Pentagon 128 compatible mode)", $0d;
	defb 0;

CurrConfString1:
	defb "ZX-Uno current configuration:", $0d;

StringCoreID:
	defb "       Core: NOT AVAILABLE   ", $0d;
	defb "     Timing: ",0

Timm48KStr:
	defb "48K", $0d, 0;

Timm128KStr:
	defb "128K", $0d, 0;

TimmPenStr:
	defb "Pentagon", $0d, 0;

CurrConfString2:
	defb " Contention: ", 0;

ContEnabledStr:
	defb "ENABLED", $0d, 0;

ContDisabledStr:
	defb "DISABLED", $0d, 0;

CurrConfString3:
	defb "   Keyboard: ISSUE ", 0;

CurrConfString4:
	defb "      Mouse: INITIALIZED", $0d, 0;

CurrConfString5:
	defb "      Speed: ", 0;

Speed3d5Str:
	defb "3.5 MHz", $0d, 0;

Speed7Str:
	defb "7 MHz", $0d, 0;

Speed14Str:
	defb "14 MHz", $0d, 0;

Speed28Str:
	defb "28 MHz", $0d, 0;

CurrConfString6:
	defb "      Video: ", 0;

CompositeStr:
	defb "CVBS/RGB 15 kHz", $0d, 0;

VGANoScansStr:
	defb "VGA", $0d, 0;

VGAScansStr:
	defb "VGA w/scanlines", $0d, 0;

CurrConfString7:
	defb "  VFreq opt: ", 0;

Freq0Str:
	defb "50 Hz (0)", $0d, 0;

Freq1Str:
	defb "51 Hz (1)", $0d, 0;

Freq2Str:
	defb "53.50 Hz (2)", $0d, 0;

Freq3Str:
	defb "55.80 Hz (3)", 13, 0;

Freq4Str:
	defb "57.39 Hz (4)", $0d, 0;

Freq5Str:
	defb "59.52 Hz (5)", $0d, 0;

Freq6Str:
	defb "61.80 Hz (6)", $0d, 0;

Freq7Str:
	defb "63.77 Hz (7)", $0d, 0;

TablaFreqStr:
	defw Freq0Str, Freq1Str, Freq2Str, Freq3Str;
	defw Freq4Str, Freq5Str, Freq6Str,Freq7Str;

HelpMsg:
	defb $0d, "CONFIG -h displays help.", $0d, $0d, 0;

ConfValue:
	defb 0;

ScanDblCtrl:
	defb 0;

QuietMode:
	defb 0;

BufferParam:
	defb 0;					// this from the RAM for the filename
