#NoEnv
#SingleInstance, Force
SetBatchLines, -1
CoordMode, Pixel, Client
CoordMode, Mouse, Client

; Outskirt Mission Macro - Needs AutoHotkey v1.1 (not v2).
; Aotr-Macros by ExRaSc - https://github.com/ExRaSc/Aotr-Macros
;
; QUICK START:
;   1. On the Mission Completed popup press F5, then hover Leave, Modifiers, Retry and press F5 on each.
;   2. Press F3 on a loading screen, then F4 in the map at the start.
;   3. Set DRY_RUN to false to have the macro run.
;
; HOTKEYS:  F1 start | F2 quit | F3 save loading screen | F4 save map
;           F5 set popup buttons (F6 cancels) | F7 test one dash
;
; SETTINGS (all times are in milliseconds)
global DRY_RUN := true             ; true = only watch and show info, no keys or clicks. false = run the macro.

; YOUR KEYS: one key per hotbar slot, left to right. Change them to your own keys if you changed your keybinds (for example "r", "f", "c", "x", "z")
global ABILITY_ONE   := "1"       ; hotbar slot 1
global ABILITY_TWO   := "2"       ; hotbar slot 2
global ABILITY_THREE := "3"       ; hotbar slot 3
global ABILITY_FOUR  := "4"       ; hotbar slot 4
global ABILITY_FIVE  := "5"       ; hotbar slot 5 (Titan Shifting)
global SLOT_NAMES := ["ABILITY_ONE", "ABILITY_TWO", "ABILITY_THREE", "ABILITY_FOUR", "ABILITY_FIVE"]
global SLOT_KEYS  := [ABILITY_ONE, ABILITY_TWO, ABILITY_THREE, ABILITY_FOUR, ABILITY_FIVE]

global DASH_COUNT      := 4       ; dashes per mission
global DOUBLE_GAP      := 156     ; time between the 2 Space taps of one dash
global DASH_PAIR_GAP   := 2160    ; wait between dashes (dash cooldown)
global POST_DASH       := 50      ; wait after the last dash before shifting (lower = shifts sooner)
global DASH_HOLD       := 60      ; how long each Space tap is held (too short = plain jump) (ignore this unless dashes aren't working)
global DASH_HOLD_W     := false   ; hold W during the dash (ignore this too, testing stuff)
global DASH_JUMP_FIRST := false   ; jump first, then double-tap  (ignore this too, testing stuff)
global DASH_JUMP_WAIT  := 350     ; wait after that jump (ignore this too, testing stuff)

global SHIFT_SLOT := "ABILITY_FIVE"   ; the slot that shifts you into a titan
global SHIFT_WAIT := 18000        ; wait after pressing the shift key (titan shift)

global ABIL_DELAY := 200          ; delay between ability presses
global HEATWAVE_SLOT := "ABILITY_TWO"   ; the slot with Heatwave
global HEATWAVE_MS   := 4000         ; how long to spam Heatwave first
global ROTATION := [["ABILITY_ONE", 5000], ["ABILITY_THREE", 4000], ["ABILITY_FOUR", 3000]]   ; then loop [slot, spam time] until the mission ends

global POPUP_CONFIRM_MS  := 1000  ; popup must show this long before Retry is clicked
global RETRY_COOLDOWN_MS := 2500  ; wait between Retry clicks

global LOADING_MIN     := 0.50    ; loading-screen match needed to count as loading (0.5 = 50%)
global LOADING_MAP_MAX := 0.50    ; ...while the map match is below this
global MAP_LOADED_MIN  := 0.45    ; map match needed to count as loaded
global LOAD_STABLE_MS  := 2500    ; map must look loaded this long before the mission starts
global MAX_MISSION_MS  := 240000  ; stop the macro if a mission runs longer than this

; Advanced (usually leave alone)
global WIN := "Roblox ahk_class WINDOWSCLIENT"
global INI := A_ScriptDir . "\signatures.ini"
global LEAVE := [0.522, 0.772]    ; popup button positions, set by F5
global MODS  := [0.578, 0.772]
global RETRY := [0.634, 0.772]
global SCAN_EVERY_MS  := 300
global LOAD_CHECK_MS  := 300
global LOAD_ABSENT_MS := 4000
global LOAD_MAX       := 90000
global POST_LOAD_WAIT := 500

global SIG_COLS := 8
global SIG_ROWS := 5
global SIGS := {}
global popupSeenAt := 0
global lastScan := 0
global lastRetryClick := 0
global lastLoadCheck := 0
global loadHits := 0
global missionStart := 0
global calStep := 0
global calPts := []

LoadSignatures()
LoadPopupPositions()

F1::Macro()
F2::ExitApp
F3::CaptureSig("loading")
F4::CaptureSig("map")
F5::CalibratePopup()
F6::CancelCalibration()
F7::TestDash()
^F1::
    DRY_RUN := !DRY_RUN
    dryMsg := DRY_RUN ? "DRY_RUN is now ON (watch only)" : "DRY_RUN is now OFF (live)"
    Tip(dryMsg, 1500)
return

Macro()
{
    global popupSeenAt, lastRetryClick, loadHits, missionStart
    if (DRY_RUN)
    {
        DryRun()
        return
    }
    bad := CheckKeys()
    if (bad != "")
    {
        Tip("Unknown ability name in the settings: " bad ". Use ABILITY_ONE to ABILITY_FIVE.", 6000)
        return
    }
    if !IsObject(SIGS["loading"])
    {
        Tip("Capture the loading screen first (press F3 while it is showing), then press F1 again.", 4000)
        return
    }
    WinActivate, %WIN%
    Sleep, 500
    if !StartSync()
        return
    Loop
    {
        popupSeenAt := 0
        lastRetryClick := 0
        loadHits := 0
        missionStart := A_TickCount
        try
        {
            RunMission()
        }
        catch e
        {
            if (e = "TIMEOUT")
            {
                Tip("No loading screen after MAX_MISSION_MS - macro stopped. F1 to start again.", 5000)
                return
            }
            else if (e != "LOADING")
                throw e
        }
        ToolTip, Loading screen detected - waiting for the map...
        WaitLoadEnd()
    }
}

StartSync()
{
    if PopupVisible()
    {
        Loop, 3
        {
            ToolTip, Popup showing - clicking Retry first...
            ClickRetry()
            t := A_TickCount
            while (A_TickCount - t < 8000)
            {
                ScreenState(lm, mm)
                if (Classify(lm, mm) = "LOADING SCREEN")
                    break 2
                Sleep, 200
            }
        }
        if PopupVisible()
        {
            Tip("Clicked Retry 3 times but the popup is still there. Check the button positions (F5) and try again.", 4500)
            return false
        }
    }
    ScreenState(lm, mm)
    if (Classify(lm, mm) = "LOADING SCREEN")
    {
        ToolTip, Loading screen - waiting for the map...
        WaitLoadEnd()
    }
    return true
}


DoDashes()
{
    Loop, %DASH_COUNT%
    {
        DashOnce()
        if (A_Index < DASH_COUNT)
            Nap(DASH_PAIR_GAP)
    }
    Nap(POST_DASH)
}

DashOnce()
{
    if (DASH_JUMP_FIRST)
    {
        SendEvent, {Space down}
        Sleep, %DASH_HOLD%
        SendEvent, {Space up}
        Sleep, %DASH_JUMP_WAIT%
    }
    if (DASH_HOLD_W)
        SendEvent, {w down}
    SendEvent, {Space down}
    Sleep, %DASH_HOLD%
    SendEvent, {Space up}
    Sleep, % Max(1, DOUBLE_GAP - DASH_HOLD)
    SendEvent, {Space down}
    Sleep, %DASH_HOLD%
    SendEvent, {Space up}
    if (DASH_HOLD_W)
        SendEvent, {w up}
}

TestDash()
{
    WinActivate, %WIN%
    Tip("Dash test in 2 seconds - get ready...", 2000)
    DashOnce()
}

SpamKey(key, ms)
{
    end := A_TickCount + ms
    while (A_TickCount < end)
    {
        Send, %key%
        Nap(ABIL_DELAY)
        HandlePopup()
    }
}

Nap(ms)
{
    end := A_TickCount + ms
    while (A_TickCount < end)
    {
        Sleep, % Max(1, Min(100, end - A_TickCount))
        CheckLoading()
    }
}

CheckLoading()
{
    global lastLoadCheck, loadHits
    if (A_TickCount - missionStart > MAX_MISSION_MS)
        throw "TIMEOUT"
    if (A_TickCount - lastLoadCheck < LOAD_CHECK_MS)
        return
    lastLoadCheck := A_TickCount
    ScreenState(lm, mm)
    if (Classify(lm, mm) = "LOADING SCREEN")
    {
        loadHits++
        if (loadHits >= 2)
            throw "LOADING"
    }
    else
        loadHits := 0
}

HandlePopup()
{
    global popupSeenAt, lastScan, lastRetryClick
    if (A_TickCount - lastScan < SCAN_EVERY_MS)
        return
    lastScan := A_TickCount
    if PopupVisible()
    {
        if (popupSeenAt = 0)
            popupSeenAt := A_TickCount
        else if (A_TickCount - popupSeenAt >= POPUP_CONFIRM_MS && A_TickCount - lastRetryClick > RETRY_COOLDOWN_MS)
        {
            ToolTip, Popup found - clicking Retry
            ClickRetry()
            lastRetryClick := A_TickCount
        }
    }
    else
        popupSeenAt := 0
}

WaitLoadEnd()
{
    start := A_TickCount
    stableSince := 0
    hasMap := IsObject(SIGS["map"])
    need := hasMap ? LOAD_STABLE_MS : LOAD_ABSENT_MS
    Loop
    {
        ScreenState(lm, mm)
        state := Classify(lm, mm)
        ok := hasMap ? (state = "MAP / LOADED") : (lm >= 0 && lm < LOADING_MIN)
        if (ok)
        {
            if (stableSince = 0)
                stableSince := A_TickCount
            else if (A_TickCount - stableSince >= need)
                break
        }
        else
            stableSince := 0
        if (A_TickCount - start > LOAD_MAX)
            break
        Sleep, 150
    }
    Sleep, %POST_LOAD_WAIT%
}

SamplePoints(w, h)
{
    colors := []
    r := 1
    while (r <= SIG_ROWS)
    {
        c := 1
        while (c <= SIG_COLS)
        {
            x := Round((c - 0.5) / SIG_COLS * w)
            y := Round((r - 0.5) / SIG_ROWS * h)
            PixelGetColor, col, x, y, RGB
            colors.Push(col)
            c++
        }
        r++
    }
    return colors
}

MatchSample(cur, name, tol := 35)
{
    sig := SIGS[name]
    if !IsObject(sig)
        return -1
    hits := 0
    for i, c in cur
    {
        s := sig[i]
        if (Abs(((c >> 16) & 0xFF) - ((s >> 16) & 0xFF)) <= tol
         && Abs(((c >> 8) & 0xFF) - ((s >> 8) & 0xFF)) <= tol
         && Abs((c & 0xFF) - (s & 0xFF)) <= tol)
            hits++
    }
    return hits / cur.Length()
}

ScreenState(ByRef lm, ByRef mm)
{
    GetClientSize(w, h)
    if (w < 100)
    {
        lm := 0, mm := 0
        return
    }
    cur := SamplePoints(w, h)
    lm := MatchSample(cur, "loading", 35)
    mm := MatchSample(cur, "map", 60)
}

Classify(lm, mm)
{
    if (lm < 0)
        return "neither"
    if (lm >= LOADING_MIN && (mm < 0 || mm < LOADING_MAP_MAX))
        return "LOADING SCREEN"
    if (lm < LOADING_MIN && (mm < 0 || mm >= MAP_LOADED_MIN))
        return "MAP / LOADED"
    return "neither"
}

CaptureSig(name)
{
    global SIGS
    GetClientSize(w, h)
    if (w < 100)
    {
        Tip("Can't find the Roblox window")
        return
    }
    cur := SamplePoints(w, h)
    s := ""
    for i, c in cur
        s .= (i > 1 ? "," : "") . c
    IniWrite, %s%, %INI%, signatures, %name%
    SIGS[name] := cur
    Tip("Saved '" name "' signature")
}

LoadSignatures()
{
    global SIGS
    SIGS := {}
    for _, name in ["loading", "map"]
    {
        IniRead, s, %INI%, signatures, %name%, %A_Space%
        s := Trim(s)
        if (s != "" && s != "ERROR")
            SIGS[name] := StrSplit(s, ",")
    }
}

CalibratePopup()
{
    global LEAVE, MODS, RETRY, calStep, calPts
    names := ["LEAVE", "MODIFIERS", "RETRY"]
    if (calStep = 0)
    {
        calPts := []
        calStep := 1
        CalTip("Step 1 of 3: hover over LEAVE, then press F5`n(F6 cancels)")
        return
    }
    GetClientSize(w, h)
    MouseGetPos, mx, my
    if (w < 100)
    {
        CalTip("Can't find the Roblox window")
        return
    }
    fx := Round(mx / w, 3)
    fy := Round(my / h, 3)
    if (fx < 0 || fx > 1 || fy < 0 || fy > 1)
    {
        CalTip("Mouse isn't over the Roblox window - hover the button and press F5 again")
        return
    }
    calPts.Push([fx, fy])
    calStep++
    if (calStep <= 3)
    {
        CalTip("Saved. Step " calStep " of 3: hover over " names[calStep] ", then press F5`n(F6 cancels)")
        return
    }

    LEAVE := calPts[1]
    MODS  := calPts[2]
    RETRY := calPts[3]
    keys := ["leave", "mods", "retry"]
    for i, pt in calPts
    {
        val := pt[1] "," pt[2]
        nm := keys[i]
        IniWrite, %val%, %INI%, popup, %nm%
    }
    calStep := 0
    ok := PopupVisible()
    CalTip("All 3 buttons saved.`nScanner check: " (ok ? "POPUP DETECTED" : "not detected - press F5 and redo it"))
    Sleep, 3500
    CalTipOff()
}

CancelCalibration()
{
    global calStep
    calStep := 0
    CalTipOff()
}

CalTip(text)
{
    WinGetPos, wx, wy, , , %WIN%
    tx := wx + 20
    ty := wy + 20
    ToolTip, %text%, %tx%, %ty%, 2
}

CalTipOff()
{
    ToolTip, , , , 2
}

LoadPopupPositions()
{
    global LEAVE, MODS, RETRY
    for _, name in ["leave", "mods", "retry"]
    {
        IniRead, s, %INI%, popup, %name%, %A_Space%
        s := Trim(s)
        if (s = "" || s = "ERROR")
            continue
        p := StrSplit(s, ",")
        v := [p[1] + 0, p[2] + 0]
        if (name = "leave")
            LEAVE := v
        else if (name = "mods")
            MODS := v
        else
            RETRY := v
    }
}

DryRun()
{
    Loop
    {
        ScreenState(lm, mm)
        ToolTip, % "DRY RUN (F2 quits)`nPopup: " (PopupVisible() ? "YES" : "no") "`nLoading match: " Pct(lm) "`nMap match: " Pct(mm) "`nState: " Classify(lm, mm)
        Sleep, 200
    }
}

Pct(v)
{
    return (v < 0) ? "not captured" : Round(v * 100) "%"
}

Tip(text, ms := 1800)
{
    ToolTip, %text%
    Sleep, %ms%
    ToolTip
}

GetClientSize(ByRef w, ByRef h)
{
    WinGet, hwnd, ID, %WIN%
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rc)
    w := NumGet(rc, 8, "Int"), h := NumGet(rc, 12, "Int")
}

IsGold(c)
{
    r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
    return (r > 180 && g > 130 && b < 170 && r >= g && (r - b) > 70)
}

ButtonGold(btn, w, h)
{
    hits := 0, total := 0
    Loop, 7
    {
        i := A_Index - 4
        Loop, 3
        {
            j := A_Index - 2
            x := Round((btn[1] + i * 0.005) * w)
            y := Round((btn[2] + j * 0.005) * h)
            PixelGetColor, c, x, y, RGB
            total++
            if IsGold(c)
                hits++
        }
    }
    return (hits / total) >= 0.3
}

PopupVisible()
{
    GetClientSize(w, h)
    if (w < 100)
        return false
    if !ButtonGold(LEAVE, w, h)
        return false
    if !ButtonGold(MODS, w, h)
        return false
    if ButtonGold(RETRY, w, h)
        return true
    MouseGetPos, mx, my
    return (Abs(mx - RETRY[1] * w) < 0.06 * w && Abs(my - RETRY[2] * h) < 0.05 * h)
}

ClickRetry()
{
    GetClientSize(w, h)
    x := Round(RETRY[1] * w), y := Round(RETRY[2] * h)
    px := Round(0.3 * w), py := Round(0.3 * h)
    WinActivate, %WIN%
    Sleep, 300
    MouseMove, %x%, %y%
    Sleep, 100
    Click, %x%, %y%, Left, Down
    Sleep, 141
    Click, %x%, %y%, Left, Up
    Sleep, 200
    MouseMove, %px%, %py%
}

RunMission()
{
    shiftKey := KeyOf(SHIFT_SLOT)
    ToolTip, Dashing...
    DoDashes()

    ToolTip, Shifting...
    Send, %shiftKey%
    Nap(DOUBLE_GAP)
    Send, %shiftKey%
    Nap(SHIFT_WAIT)

    ToolTip, Abilities...
    SpamKey(KeyOf(HEATWAVE_SLOT), HEATWAVE_MS)
    Loop
    {
        for _, p in ROTATION
        {
            SpamKey(KeyOf(p[1]), p[2])
        }
    }
}

KeyOf(name)
{
    for i, n in SLOT_NAMES
    {
        if (n = name)
            return SLOT_KEYS[i]
    }
    return ""
}

CheckKeys()
{
    bad := ""
    names := [SHIFT_SLOT, HEATWAVE_SLOT]
    for _, p in ROTATION
        names.Push(p[1])
    for _, nm in names
    {
        if (KeyOf(nm) = "")
            bad .= nm " "
    }
    return bad
}
