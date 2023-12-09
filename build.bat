@ECHO .
@ECHO .    ***   ***   ***   *   *     *    *         *****
@ECHO .   *       *   *      **  *    * *   *            *
@ECHO .    ***    *   *  **  * * *   *****  *     ***  *** 
@ECHO .       *   *   *   *  *  **   *   *  *          *
@ECHO .    ***   ***   ***   *   *   *   *  *****     *****
@ECHO .
@ECHO . build file for version 1.1
@ECHO .
@REM set installation directory of assembler
@REM 
SET MPASM="%MPLAB%\mpasmwin.exe"
@REM
if "%1" == "clean" GOTO :clean
if "%1" == "distclean" GOTO :distclean
%MPASM% signal-z.asm
%MPASM% "signal-z (switcher).asm"
GOTO :fin
:distclean
ERASE *.HEX
:clean
ERASE *.COD
ERASE *.ERR
ERASE *.LST
:fin
