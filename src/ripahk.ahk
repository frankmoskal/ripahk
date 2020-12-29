; script information ==========================================================
; name:        ripahk
; description: ehancements to https://cancel.fm/ripcord/
; ahk version: ahk v2.0-a122-f595abc2
; author:      https://github.com/frankmoskal
; filename:    ripahk.ahk
; =============================================================================

; revision history ============================================================
; revision 1 (2020-12-24)
; * initial release
; =============================================================================


; external libraries ==========================================================
; =============================================================================
#Include LoggerObserver.ahk


; ahk directives ==============================================================
; =============================================================================
#HotkeyInterval 99000000
#KeyHistory 0
#MaxHotkeysPerInterval 99000000
#NoTrayIcon
#SingleInstance Force


; setenv ======================================================================
; =============================================================================
CoordMode "Mouse", "Screen"
DetectHiddenWindows True
ListLines False
OnExit( "AhkMaid" )
SendMode "Input"
SetControlDelay( -1 )
SetDefaultMouseSpeed( 0 )
SetKeyDelay( -1, -1 )
SetMouseDelay( -1 )
SetWinDelay( -1 )


; initialize global variables =================================================
; =============================================================================
global ripPID := ""
global ripLOG := LoggerObserver.New( ( "../ripcord.log" ), Func( "ParseRipcordLog" ) )
global ripVEC := ComObjCreate( "Scripting.Dictionary" )

; main function ===============================================================
; =============================================================================
Main()
ExitApp


; hotkeys =====================================================================
; =============================================================================

; winactive ctr+q =============================================================
; description: shortcut to close ripcord 
; input:       press ctr+q when ripcord is the active window
; =============================================================================
#HotIf WinActive( "ahk_pid" ripPID )
^q::
{
	ExitApp
}

; functions ===================================================================
; =============================================================================

; ahkmaid =====================================================================
; arguments:    exitReason (exit reason), exitCode (unused)
; description:  clean up ahk leftovers
; return value: n/a 
; ============================================================================= 
AhkMaid( exitReason, exitCode )
{
	; stop observing ripcord logs
	if( ripLOG )
		ripLOG.Del()	

	; if quitting ripcord, close ripcord windows via WM_QUIT
	if( exitReason != "Single" )
	{
		for (winID in WinGetList( "ahk_pid" ripPID ) )
			Try PostMessage( 0x0012,,,, "ahk_id" winID )
	}
}

; parseripcordlog =============================================================
; arguments:    logLine (current line of log)
; description:  determines if user has disconnected from VC
; return value: n/a 
; =============================================================================
ParseRipcordLog( logLine )
{
	; tokenize the log line
	Tokens := StrSplit( logLine, " " )

	; the error code, if it exists, is element 7, so output the corresponding message
	If( WinExist( "Ripcord Voice Chat ahk_pid " ripPID ) && Tokens.Length > 6 && ripVEC.Exists( Tokens[7] ) )
		MsgBox( Format( "{:s}", ripVEC.Item[ Tokens[7] ] )
			, Format( "ERROR: {:s}", Tokens[7] ) )
}

; main ========================================================================
; arguments:    n/a
; credits:      https://discord.com/developers/docs/topics/opcodes-and-status-codes
;               https://www.autohotkey.com/boards/viewtopic.php?t=59070
; description:  main function
; return value: n/a 
; =============================================================================
Main()
{
	; load voice error codes
	ripVEC.Add( "1000", "An unknown voice error occurred." )
	ripVEC.Add( "4001", "The client sent an invalid opcode to the voice server." )
	ripVEC.Add( "4002", "The client sent a invalid identification payload to the voice Gateway." )
	ripVEC.Add( "4003", "The client sent a payload before identifying with the voice Gateway." )
	ripVEC.Add( "4004", "The client sent an incorrect identity token to the voice server." )
	ripVEC.Add( "4005", "The client sent more than one identification payload to the voice server." )
	ripVEC.Add( "4006", "The voice session is no longer valid." )
	ripVEC.Add( "4009", "The voice session has timed out." )
	ripVEC.Add( "4011", "The client attempted to connect to an unrecognized voice server." )
	ripVEC.Add( "4012", "The client sent an unrecognized protocol to the voice server." )
	ripVEC.Add( "4014", "The client failed to reconnect the voice server - perhaps it was kicked?" )
	ripVEC.Add( "4015", "The voice server crashed." )
	ripVEC.Add( "4016", "The client is using an unrecognized encryption method." )

	; start ripcord if not already active, otherwise show main window
	ripPID := ProcessExist( "Ripcord.exe" )
	if( ripPID == 0 )
		Run( "../Ripcord.exe",,, ripPID )
	else
		; activate the hidden window with WM_USER (0x8065 doesn't seem to be documented anywhere)
		PostMessage( 0x8065, 0, 0x400,, "ahk_pid " ripPID " ahk_class QTrayIconMessageWindowClass" )

	; wait for ripcord to exit
	ProcessWaitClose( ripPID )
}