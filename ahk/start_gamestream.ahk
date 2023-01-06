/**
* @description AutoHotKey script to enable Gamestream without user interaction.
* @author Bryan Wiebe info@hutzmedia.com
* @license MIT
*/
Debug := 0 ;; set to 1 to log colors

/*
State-Codes:
- CLOSED         1
- LISTEN         2
- SYN_SENT       3
- SYN_RCVD       4
- ESTAB          5
- FIN_WAIT1      6
- FIN_WAIT2      7
- CLOSE_WAIT     8
- CLOSING        9
- LAST_ACK      10
- TIME_WAIT     11
- DELETE_TCB    12
*/
TCP_PortExist(port) {
	static hIPHLPAPI := DllCall("LoadLibrary", "str", "iphlpapi.dll", "ptr"), table := []
	VarSetCapacity(TBL, 4 + (s := (20 * 32)), 0)
	while (DllCall("iphlpapi\GetTcpTable", "ptr", &TBL, "uint*", s, "uint", 1) = 122)
		VarSetCapacity(TBL, 4 + s, 0)

	loop % NumGet(TBL, 0, "uint") {
		o := 4 + ((A_index - 1) * 20)
		, temp_port := (((ROW := NumGet(TBL, o+8,  "uint"))&0xff00)>>8) | ((ROW&0xff)<<8)
		, state := NumGet(TBL, o, "uint")
		if (temp_port = port)
			return state, DllCall("FreeLibrary", "ptr", hIPHLPAPI)
	}
	return 0, DllCall("FreeLibrary", "ptr", hIPHLPAPI)
}

WriteLog(text) {
	FileAppend, % A_NowUTC ": " text "`n", logfile.txt ; can provide a full path to write to another directory
}

;;;;;;;;;;;;;;;;;;;;;;;;;

Code := TCP_PortExist(47989)
if (%Code% != 11 && %Code% != 0) {
    ; port is open meaning gamestream is currently running
    WinClose, GeForce Experience
    Exit,
}
   
; open geforce experience
Run, "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"

; wait for games to load in or the cog/settings page may not load in properly
WinActivate, GeForce Experience
WriteLog("waiting for games to load")
Loop
{
    PixelGetColor, color, 70,68
    if (color = 0x00B976) {
        break
    }
    if (debug) {
        WriteLog(color)
    }
    Sleep, 8
}

WinGetPos, WinX, WinY, WinW, WinH, A

; wait for cog icon to be ready
x := WinW - 332
WriteLog("Waiting for cog.")
Loop
{
    PixelGetColor, color, x, 74
    if (color = 0x777777) {
        break
    }
    if (debug) {
        WriteLog(color)
    }
    Sleep, 8
}

MouseClick, left, x, 74

Sleep, 500

; wait for gamestream radio to be ready
; scan from 50% to right side of window and look for radio button
mid := Floor(WinW / 2) - 1 
x := mid
WriteLog("waiting for radio.")
Loop
{
    x := x + 25
    if (x > WinW) {
        x := mid
    }
    PixelGetColor, color, x, 146
    if (color = 0xFAFAFA || color = 0x9E9E9E) {
        break
    }
    if (debug) {
        WriteLog(color " x=" x)
    }
}
MouseClick, left, x, 146

Loop
{
    ; wait for port to open
    Code := TCP_PortExist(47989)
    if (%Code% != 11 && %Code% != 0) {
        ; port is open meaning gamestream is currently running
        break
    }
}

; close window
WinClose, GeForce Experience

; done