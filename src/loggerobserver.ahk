; script information ==========================================================
; name:        loggerobserver
; description: class which watches a log file for new entries
; ahk version: ahk v2.0-a122-f595abc2
; author:      https://github.com/frankmoskal
; filename:    loggerobserver.ahk
; =============================================================================

; revision history ============================================================
; revision 1.01 (2020-12-21)
; * clean up multiple instances of "this"
; revision 1 (2020-11-28)
; * initial release
; =============================================================================


; classes =====================================================================
; =============================================================================

; loggerobserver ==============================================================
; description: watches a log file for new entries
; credits:     https://github.com/Bluscream/ahk-scripts/blob/master/Lib/logtail.ahk
; parameters:  fileName (file name), callback (callback fn)
; =============================================================================
class LoggerObserver
{
    File := "",
    Size := 0
    
    ; __new ===================================================================
    ; arguments:    fileName (file name), callback (callback fn)
    ; description:  creates a new instance of the logger observer
    ; return value: n/a 
    ; ========================================================================= 
    __New( fileName, callback )
    {
        
        ; try to open the file for reading
        try this.File := FileOpen( fileName, "r `n" )
        catch E
        {
            ; display error message and exit
            MsgBox( "Does it exist? Is it being used by another process?"
                        , Format( "ERROR: FileOpen {:s}", FileName), "Iconx" )
            ExitApp
        }

        ; set the file size, callback fn, and observer fn
        this.Size := this.File.Length
        , this.Callback := callback
        , this.Parser := ObjBindMethod( this, "Parse" )

        ; start watching for changes
        this.Observe()
    }
 
    ; del =====================================================================
    ; arguments:    n/a
    ; description:  free up instances of "this", disable logging, close file
    ; return value: n/a 
    ; =========================================================================
    Del()
    {
        SetTimer( this.Parser, 0 )
        this.Parser := ""
        this.File.Close()
    }

    ; observe =================================================================
    ; arguments:    n/a
    ; description:  watch for changes in the log file every 100ms
    ; return value: n/a 
    ; =========================================================================
    Observe()
    {
        ; jump to EOF
        this.File.Seek( this.Size, 0 )
        SetTimer( this.Parser, 100 )
    }

    ; parse ===============================================================
    ; arguments:    n/a
    ; description:  parses the log file
    ; return value: n/a 
    ; =====================================================================
    Parse()
    {      
        ; if the log file was reset, start over or go to current line
        this.File.Seek( ( this.File.Length < this.Size ) ? 0 : this.File.Pos, 0 )

        ; execute the callback until we reach EOF using trimmed log line
        while ( !this.File.AtEOF )
            this.callback.call( RegExReplace( Trim( this.File.ReadLine() )
                , "s)`r|`n", "" ) )

        ; store current file size for comparison
        this.Size := this.File.Length
    }
    
    ; stop ====================================================================
    ; arguments:    n/a
    ; description:  stop watching for changes, but don't disable the logger
    ; return value: n/a 
    ; =========================================================================
    Stop()
    {
        SetTimer( this.Parser, 0 )
    }
}