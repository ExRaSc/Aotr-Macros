#NoEnv
#SingleInstance, Force
SetBatchLines, -1
DllCall("SetProcessDPIAware")
CoordMode, Mouse, Client

; Female Raid Macro - Needs AutoHotkey v1.1 (not v2).
; Aotr-Macros by ExRaSc - https://github.com/ExRaSc/Aotr-Macros
;
; QUICK START / SETUP:
;
;   F3   on a loading screen
;   F4   on a cutscene with the SKIP prompt showing: press F4, hover the SKIP box's top-left corner, F4, its bottom-right corner, F4.
;        After that, press F4 once at EACH other cutscene (while its SKIP prompt is showing) to add a look for it.
;        The box position is only set the first time. Shift+F4 clears everything and starts over.
;   F7   hotbar area: press F7, hover the top-left of slot 1's frame then press F7, then the bottom-right of slot 5's frame and press F7 (might need to get on the wall or one of the bridges between you and her for this).
;   F8   save the HUMAN hotbar look: in human form with every ability ready.
;   F9   save the TITAN hotbar look: in titan form with its abilities ready.
;   F10  on the chests screen with all 3 buttons showing: press F10, hover the left OPEN then press F10, the right OPEN and press F10, FINISH and press F10.
;   F5   on the Raid Completed popup: press F5, hover Leave then press, Modifiers and press F5, Retry and press F5.
; Then switch DRY_RUN off (edit it below, or press Ctrl+F1 in the running script), start a Female raid and press F1 inside it. F2 quits, F6 cancels a setup in progress.
; The status box in the corner of the Roblox window shows what it sees, so you can check each screen in DRY_RUN first.

; ======================= SETTINGS (times in milliseconds) =======================
global DRY_RUN := true            ; true = only watch and show the status box. false = press keys and click
global TICK_MS := 60              ; how often the screen is checked
global STATE_CONFIRM := 2         ; a screen must be seen this many checks in a row before the macro switches to it

; YOUR KEYS: one key per hotbar slot, left to right. Change them to your own keys (for example "r", "f", "c", "x", "z")
global ABILITY_ONE   := "1"       ; hotbar slot 1
global ABILITY_TWO   := "2"       ; hotbar slot 2
global ABILITY_THREE := "3"       ; hotbar slot 3
global ABILITY_FOUR  := "4"       ; hotbar slot 4
global ABILITY_FIVE  := "5"       ; hotbar slot 5 (Titan Shifting)
global SLOT_NAMES := ["ABILITY_ONE", "ABILITY_TWO", "ABILITY_THREE", "ABILITY_FOUR", "ABILITY_FIVE"]
global SLOT_KEYS  := [ABILITY_ONE, ABILITY_TWO, ABILITY_THREE, ABILITY_FOUR, ABILITY_FIVE]

global BUFF_SLOTS := ["ABILITY_FOUR", "ABILITY_THREE"]   ; human form: pressed whenever their slot is ready (have flare/order here).
global SHIFT_SLOT := "ABILITY_FIVE"   ; pressed once no buff is ready (have shift here).
global KEY_GAP := 220             ; minimum time between presses of the same key.

; Titan form, checked in this order every tick (the first READY one is pressed):
; Heatwave, Seismic Shock, Tectonic Quake, Incendiary Volley. The FIRST entry must be Heatwave.
; Tectonic Quake and Incendiary Volley are only pressed when Heatwave and Seismic Shock are not ready.
global PRIORITY := ["ABILITY_TWO", "ABILITY_ONE", "ABILITY_FOUR", "ABILITY_THREE"]
global ABIL_GAP := 150            ; minimum time between presses of the same ability
global HEAT_GAP := 120            ; heatwave is a toggle (a press while it is on turns it off): time between presses while turning it on
global HEAT_BURST_MS := 2500      ; stop pressing it after this long if its slot never went grey
global HEAT_ACTIVE_MS := 32000    ; after it turns on, never press it again for this long (30 s duration + margin)
global HEAT_RETRY_MS := 1500      ; if it did not turn on, try again after this long

global READY_MIN := 0.80          ; a hotbar slot must match its saved ready look this much to count as ready
global PRESENT_MIN := 0.30        ; ...and this much (against either saved look) to count as "this hotbar cell is on screen"

global SKIP_KEY := "e"            ; pressed while the SKIP prompt is showing
global E_GAP := 120               ; time between E presses
global SKIP_MATCH_MIN := 0.60     ; SKIP prompt match needed to count as showing

global LOADING_MIN := 0.50        ; loading-screen match needed to count as loading

global CHESTS_TO_OPEN := 2        ; 2 = open both chests (the second costs something), 1 = only the first (if you have no keys (:sob:))
global CHEST_CLICK_GAP := 1500    ; wait between OPEN clicks (it clicks again if the button is still there)
global CHEST_REVEAL_MS := 5000    ; after the last OPEN click, wait this long before FINISH may be clicked
global CHEST_SETTLE_MS := 2500    ; no OPEN button may be visible for this long before FINISH may be clicked
global FINISH_WAIT_MS := 9000     ; if no OPEN was ever clicked, FINISH is allowed after this long

global RETRY_COOLDOWN_MS := 2500  ; wait between Retry clicks

; ======================= ADVANCED (usually leave alone) =======================
global WIN := "Roblox ahk_class WINDOWSCLIENT"
global INI := A_ScriptDir . "\FemaleRaid.ini"
global HOT_COLS := 10
global HOT_ROWS := 8
global HOT_TOL := 50
global HOT_BRIGHT := 120
global SKIP_COLS := 24
global SKIP_ROWS := 6
global SKIP_TOL := 60
global SKIP_BRIGHT := 140
global BTN_HW := 0.02
global BTN_HH := 0.010
global BTN_MIN := 0.20
global MASK_TOL := 45

; ======================= DATA AND STATE =======================
global FW := 0
global FH := 0
global FBITS := 0
global FDC := 0
global FBMP := 0
global FSCREEN := 0
global FSX := 0
global FSY := 0
global LOADSIG := ""
global SKIPREG := ""
global SKIPLOOKS := []
global MASKIDX := []
global MASKCOL := []
global skBest := 0
global HOTREG := ""
global HUMANL := []
global TITANL := []
global POP := ""
global CH := ""
global LAST := {}
global state := "-"
global lastCand := ""
global candCount := 0
global ldMatch := -1
global skMatch := -1
global hotCount := 0
global form := ""
global rdyH := [-1, -1, -1, -1, -1]
global rdyT := [-1, -1, -1, -1, -1]
global fPop := [-1, -1, -1]
global fCh := [-1, -1, -1]
global popRx := 0
global popRy := 0
global f1x := 0
global f1y := 0
global f2x := 0
global f2y := 0
global fFx := 0
global fFy := 0
global lastChestsT := 0
global chLastClick := 0
global chNoOpenSince := 0
global heatLast := 0
global heatStart := 0
global lastNote := "-"
global tipX := 20
global tipY := 100
global wizName := ""
global wizPts := []

LoadAll()

F1::Macro()
F2::ExitApp
F3::CaptureLoading()
F4::SkipKey()
+F4::ResetSkip()
F5::Wiz("popup")
F6::CancelWiz()
F7::Wiz("hotbar")
F8::CaptureHotLook("human")
F9::CaptureHotLook("titan")
F10::Wiz("chests")
^F1::
    DRY_RUN := !DRY_RUN
    dryMsg := DRY_RUN ? "DRY_RUN is now ON (watch only)" : "DRY_RUN is now OFF (live)"
    Tip(dryMsg, 1500)
return

; ======================= MAIN LOOP =======================
Macro()
{
    global tipX, tipY, state, lastCand, candCount
    if (!DRY_RUN)
    {
        miss := Missing()
        if (miss != "")
        {
            Tip("Set these up first: " miss "then press F1 again (or leave DRY_RUN on to just watch).", 6000)
            return
        }
    }
    bad := CheckKeys()
    if (bad != "")
    {
        Tip("Unknown ability name in the settings: " bad ". Use ABILITY_ONE to ABILITY_FIVE.", 6000)
        return
    }
    WinGetPos, wx, wy, , , %WIN%
    tipX := wx + 20
    tipY := wy + 100
    state := "-"
    lastCand := ""
    candCount := 0
    WinActivate, %WIN%
    Sleep, 300
    Loop
    {
        if (!Grab())
        {
            Sleep, 200
            continue
        }
        cand := Detect()
        Confirm(cand)
        if (!DRY_RUN)
            Act()
        Status(cand)
        Sleep, %TICK_MS%
    }
}

Confirm(c)
{
    global state, lastCand, candCount
    if (c = lastCand)
        candCount++
    else
    {
        lastCand := c
        candCount := 1
    }
    need := (c = "SKIP") ? 1 : STATE_CONFIRM
    if (candCount >= need && c != state)
    {
        if (c = "LOADING")
            ResetRaid()
        state := c
    }
}

ResetRaid()
{
    global heatLast, heatStart, lastChestsT, chLastClick, chNoOpenSince
    heatLast := 0
    heatStart := 0
    lastChestsT := 0
    chLastClick := 0
    chNoOpenSince := 0
    Note("loading screen - new raid")
}

; ======================= WHAT IS ON SCREEN =======================
Detect()
{
    global ldMatch, skMatch, hotCount, fPop, fCh, popRx, popRy, f1x, f1y, f2x, f2y, fFx, fFy, lastChestsT
    ldMatch := LoadingScore()
    if (ldMatch >= LOADING_MIN)
        return "LOADING"
    HotbarScan()
    hotVis := (hotCount >= 3)
    fPop := [-1, -1, -1]
    fCh := [-1, -1, -1]
    if (!hotVis && IsObject(POP))
    {
        fPop[1] := BtnFrac(POP[1], ax, ay)
        fPop[2] := BtnFrac(POP[2], bx, by)
        fPop[3] := BtnFrac(POP[3], popRx, popRy)
        if (fPop[1] >= BTN_MIN && fPop[2] >= BTN_MIN && fPop[3] >= BTN_MIN)
            return "POPUP"
    }
    if (!hotVis && IsObject(CH))
    {
        fCh[1] := BtnFrac(CH[1], f1x, f1y)
        fCh[2] := BtnFrac(CH[2], f2x, f2y)
        fCh[3] := BtnFrac(CH[3], fFx, fFy)
        openSeen := (fCh[1] >= BTN_MIN || fCh[2] >= BTN_MIN)
        if (openSeen)
            lastChestsT := A_TickCount
        if (openSeen || (fCh[3] >= BTN_MIN && lastChestsT > 0 && A_TickCount - lastChestsT < 40000))
            return "CHESTS"
    }
    skMatch := SkipScore()
    if (skMatch >= SKIP_MATCH_MIN)
        return "SKIP"
    if (hotVis)
        return form
    return "UNKNOWN"
}

LoadingScore()
{
    if !IsObject(LOADSIG)
        return -1
    return Score(GridRect([0, 0, 1, 1], 8, 5), LOADSIG, 35, 0)
}

CellReg(i)
{
    cw := (HOTREG[3] - HOTREG[1]) / 5
    return [HOTREG[1] + (i - 1) * cw, HOTREG[2], HOTREG[1] + i * cw, HOTREG[4]]
}

HotbarScan()
{
    global hotCount, form, rdyH, rdyT
    hotCount := 0
    form := ""
    rdyH := [-1, -1, -1, -1, -1]
    rdyT := [-1, -1, -1, -1, -1]
    if !IsObject(HOTREG)
        return
    empty5 := false
    Loop, 5
    {
        i := A_Index
        cur := GridRect(CellReg(i), HOT_COLS, HOT_ROWS)
        sh := IsObject(HUMANL[i]) ? Score(cur, HUMANL[i], HOT_TOL, HOT_BRIGHT, true) : -1
        st := IsObject(TITANL[i]) ? Score(cur, TITANL[i], HOT_TOL, HOT_BRIGHT, true) : -1
        rdyH[i] := sh
        rdyT[i] := st
        if (Max(sh, st) >= PRESENT_MIN)
            hotCount++
        if (i = 5)
            empty5 := SlotEmpty(cur)
    }
    if (hotCount >= 3)
        form := empty5 ? "TITAN" : "HUMAN"
}

SlotEmpty(cur)
{
    dark := 0
    total := 0
    r := 3
    while (r <= HOT_ROWS - 2)
    {
        c := 3
        while (c <= HOT_COLS - 2)
        {
            v := cur[(r - 1) * HOT_COLS + c]
            total++
            if (Max((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF) < 70)
                dark++
            c++
        }
        r++
    }
    return (total > 0 && dark / total >= 0.92)
}

; fraction of the button area (around a saved point) that is gold, and the centre of that gold
BtnFrac(pt, ByRef cx, ByRef cy)
{
    cols := 9
    rows := 5
    hits := 0
    total := 0
    sx := 0
    sy := 0
    r := 1
    while (r <= rows)
    {
        c := 1
        while (c <= cols)
        {
            fx := pt[1] + ((c - 1) / (cols - 1) - 0.5) * 2 * BTN_HW
            fy := pt[2] + ((r - 1) / (rows - 1) - 0.5) * 2 * BTN_HH
            total++
            if IsBtnGold(P(fx, fy))
            {
                hits++
                sx += fx
                sy += fy
            }
            c++
        }
        r++
    }
    cx := hits ? sx / hits : pt[1]
    cy := hits ? sy / hits : pt[2]
    return hits / total
}

IsBtnGold(c)
{
    r := (c >> 16) & 0xFF
    g := (c >> 8) & 0xFF
    b := c & 0xFF
    return (r > 190 && g > 150 && b < 160 && (r - b) > 80)
}

; ======================= WHAT TO DO =======================
Act()
{
    if (state = "SKIP")
    {
        if Due("e", E_GAP)
            TapKey(SKIP_KEY, 40)
    }
    else if (state = "HUMAN")
        HumanAct()
    else if (state = "TITAN")
        TitanAct()
    else if (state = "CHESTS")
        ChestAct()
    else if (state = "POPUP")
        PopupAct()
}

ChestAct()
{
    global chLastClick, chNoOpenSince
    now := A_TickCount
    v1 := (fCh[1] >= BTN_MIN)
    v2 := (CHESTS_TO_OPEN >= 2 && fCh[2] >= BTN_MIN)
    vF := (fCh[3] >= BTN_MIN)
    if (v1 || v2)
    {
        chNoOpenSince := 0
        if (now - chLastClick >= CHEST_CLICK_GAP)
        {
            if (v1)
                ClickAt(f1x, f1y)
            else
                ClickAt(f2x, f2y)
            chLastClick := A_TickCount
            Note("clicked OPEN")
        }
        return
    }
    if (chNoOpenSince = 0)
        chNoOpenSince := now
    waited := now - chNoOpenSince
    if (vF && waited >= CHEST_SETTLE_MS && now - chLastClick >= CHEST_REVEAL_MS && (chLastClick > 0 || waited >= FINISH_WAIT_MS))
    {
        if Due("finish", 1500)
        {
            ClickAt(fFx, fFy)
            Note("clicked FINISH")
        }
    }
}

PopupAct()
{
    if Due("retry", RETRY_COOLDOWN_MS)
    {
        ClickAt(popRx, popRy)
        Note("clicked RETRY")
    }
}

; ======================= SMALL HELPERS =======================
Due(name, gap)
{
    global LAST
    t := LAST[name]
    if (t != "" && A_TickCount - t < gap)
        return false
    LAST[name] := A_TickCount
    return true
}

Note(text)
{
    global lastNote
    lastNote := text " (" A_Hour ":" A_Min ":" A_Sec ")"
}

TapKey(key, hold := 60)
{
    SendEvent, {%key% down}
    Sleep, %hold%
    SendEvent, {%key% up}
}

ClickAt(fx, fy)
{
    x := Round(fx * FW)
    y := Round(fy * FH)
    px := Round(0.3 * FW)
    py := Round(0.3 * FH)
    WinActivate, %WIN%
    MouseMove, %x%, %y%
    Sleep, 120
    Click, %x%, %y%, Left, Down
    Sleep, 120
    Click, %x%, %y%, Left, Up
    Sleep, 150
    MouseMove, %px%, %py%
}

Pct(v)
{
    return (v < 0) ? "n/a" : Round(v * 100) "%"
}

RdyText(a)
{
    s := ""
    for i, v in a
        s .= i ":" Pct(v) "  "
    return s
}

Status(cand)
{
    mode := DRY_RUN ? "  [DRY RUN - no keys or clicks]" : ""
    msg := "Female Raid Macro" mode "`nState: " state "   (this check sees: " cand ")`nLoading match: " Pct(ldMatch) "   SKIP prompt match: " Pct(skMatch) "  (" SKIPLOOKS.Length() " looks, " MASKIDX.Length() " shared points)`nHotbar cells seen: " hotCount " of 5   Form: " form "`nHuman-look match: " RdyText(rdyH) "`nTitan-look match: " RdyText(rdyT) "`nPopup buttons: " RdyText(fPop) "`nChest buttons: " RdyText(fCh) "`nLast: " lastNote
    ToolTip, % msg, %tipX%, %tipY%, 3
}

Tip(text, ms := 2500)
{
    ToolTip, %text%
    Sleep, %ms%
    ToolTip
}

Missing()
{
    m := ""
    if !IsObject(LOADSIG)
        m .= "loading screen (F3), "
    if (!IsObject(SKIPREG) || SKIPLOOKS.Length() = 0)
        m .= "SKIP prompt (F4), "
    if !IsObject(HOTREG)
        m .= "hotbar area (F7), "
    if (HUMANL.Length() < 5)
        m .= "human hotbar look (F8), "
    if (TITANL.Length() < 5)
        m .= "titan hotbar look (F9), "
    if !IsObject(CH)
        m .= "chest buttons (F10), "
    if !IsObject(POP)
        m .= "popup buttons (F5), "
    return m
}

; ======================= SCREEN GRAB =======================
MakeBuffer(w, h)
{
    global FW, FH, FBITS, FDC, FBMP, FSCREEN
    if (FDC)
    {
        DllCall("DeleteObject", "Ptr", FBMP)
        DllCall("DeleteDC", "Ptr", FDC)
        FDC := 0
    }
    if (!FSCREEN)
        FSCREEN := DllCall("GetDC", "Ptr", 0, "Ptr")
    FDC := DllCall("CreateCompatibleDC", "Ptr", FSCREEN, "Ptr")
    VarSetCapacity(bi, 40, 0)
    NumPut(40, bi, 0, "UInt")
    NumPut(w, bi, 4, "Int")
    NumPut(-h, bi, 8, "Int")
    NumPut(1, bi, 12, "UShort")
    NumPut(32, bi, 14, "UShort")
    bits := 0
    FBMP := DllCall("CreateDIBSection", "Ptr", FSCREEN, "Ptr", &bi, "UInt", 0, "Ptr*", bits, "Ptr", 0, "UInt", 0, "Ptr")
    DllCall("SelectObject", "Ptr", FDC, "Ptr", FBMP)
    FBITS := bits
    FW := w
    FH := h
}

Grab()
{
    global FW, FH, FDC, FSCREEN, FSX, FSY
    WinGet, hwnd, ID, %WIN%
    if (!hwnd)
        return false
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rc)
    w := NumGet(rc, 8, "Int")
    h := NumGet(rc, 12, "Int")
    if (w < 200 || h < 200)
        return false
    VarSetCapacity(pt, 8, 0)
    DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
    FSX := NumGet(pt, 0, "Int")
    FSY := NumGet(pt, 4, "Int")
    if (w != FW || h != FH || !FDC)
        MakeBuffer(w, h)
    return DllCall("BitBlt", "Ptr", FDC, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", FSCREEN, "Int", FSX, "Int", FSY, "UInt", 0x00CC0020)
}

; colour (0xRRGGBB) at a spot given as fractions of the window
P(fx, fy)
{
    x := Round(fx * FW)
    y := Round(fy * FH)
    x := (x < 0) ? 0 : (x >= FW ? FW - 1 : x)
    y := (y < 0) ? 0 : (y >= FH ? FH - 1 : y)
    return NumGet(FBITS + (y * FW + x) * 4, 0, "UInt") & 0xFFFFFF
}

GridRect(reg, cols, rows)
{
    a := []
    r := 1
    while (r <= rows)
    {
        c := 1
        while (c <= cols)
        {
            a.Push(P(reg[1] + (c - 0.5) / cols * (reg[3] - reg[1]), reg[2] + (r - 0.5) / rows * (reg[4] - reg[2])))
            c++
        }
        r++
    }
    return a
}

; fraction of the saved look's bright points that still match (dark background points are ignored, so a dark scene cannot fake a match)
Score(cur, sig, tol, brightMin, needBright := false)
{
    n := 0
    hits := 0
    for j, c in cur
    {
        sv := sig[j]
        sr := (sv >> 16) & 0xFF
        sg := (sv >> 8) & 0xFF
        sb := sv & 0xFF
        if (Max(sr, sg, sb) < brightMin)
            continue
        n++
        if (Abs(((c >> 16) & 0xFF) - sr) <= tol && Abs(((c >> 8) & 0xFF) - sg) <= tol && Abs((c & 0xFF) - sb) <= tol)
            hits++
    }
    if (n >= 3)
        return hits / n
    if (needBright)
        return -1
    return 0
}

; ======================= SETUP HOTKEYS =======================
CaptureLoading()
{
    global LOADSIG
    if (!Grab())
    {
        CalTip("Can't find the Roblox window")
        return
    }
    LOADSIG := GridRect([0, 0, 1, 1], 8, 5)
    IniSet("loading", "sig", Join(LOADSIG))
    CalTip("Loading screen saved")
    Sleep, 1500
    CalTipOff()
}

CaptureHotLook(which)
{
    global HUMANL, TITANL
    if !IsObject(HOTREG)
    {
        CalTip("Set the hotbar area first (F7)")
        Sleep, 2000
        CalTipOff()
        return
    }
    if (!Grab())
        return
    px := Round(0.3 * FW)
    py := Round(0.3 * FH)
    MouseMove, %px%, %py%
    Sleep, 400
    if (!Grab())
        return
    looks := []
    Loop, 5
    {
        i := A_Index
        looks[i] := GridRect(CellReg(i), HOT_COLS, HOT_ROWS)
        IniSet(which, i, Join(looks[i]))
    }
    if (which = "human")
        HUMANL := looks
    else
        TITANL := looks
    CalTip("Saved the " which " hotbar look")
    Sleep, 1800
    CalTipOff()
}

SkipKey()
{
    if (IsObject(SKIPREG) && wizName = "")
        AddSkipLook()
    else
        Wiz("skip")
}

WizPrompts(name)
{
    if (name = "popup")
        return ["hover the LEAVE button", "hover the MODIFIERS button", "hover the RETRY button"]
    if (name = "chests")
        return ["hover the LEFT OPEN button (all three buttons must be on screen)", "hover the RIGHT OPEN button", "hover the FINISH button"]
    if (name = "skip")
        return ["hover the TOP-LEFT corner of the SKIP box", "hover the BOTTOM-RIGHT corner of the SKIP box"]
    return ["hover the TOP-LEFT corner of slot 1's frame", "hover the BOTTOM-RIGHT corner of slot 5's frame (include the number box under it)"]
}

Wiz(name)
{
    global wizName, wizPts
    prompts := WizPrompts(name)
    if (wizName != name)
    {
        wizName := name
        wizPts := []
        total := prompts.Length()
        CalTip(name " setup, step 1 of " total ": " prompts[1] ", then press the same key again`n(F6 cancels)")
        return
    }
    if (!Grab())
    {
        CalTip("Can't find the Roblox window")
        return
    }
    MouseGetPos, mx, my
    fx := Round(mx / FW, 4)
    fy := Round(my / FH, 4)
    if (fx < 0 || fx > 1 || fy < 0 || fy > 1)
    {
        CalTip("The mouse isn't over the Roblox window - hover the spot and press the key again")
        return
    }
    wizPts.Push([fx, fy])
    n := wizPts.Length()
    if (n < prompts.Length())
    {
        nxt := n + 1
        total := prompts.Length()
        CalTip("Saved. Step " nxt " of " total ": " prompts[nxt] ", then press the same key again`n(F6 cancels)")
        return
    }
    WizDone(name)
}

WizDone(name)
{
    global wizName, wizPts, POP, CH, SKIPREG, SKIPLOOKS, HOTREG
    pts := wizPts
    wizName := ""
    if (name = "popup" || name = "chests")
    {
        Loop, 3
            IniSet(name, "p" A_Index, pts[A_Index][1] "," pts[A_Index][2])
        if (name = "popup")
            POP := pts
        else
            CH := pts
        CalTip(name " buttons saved")
    }
    else
    {
        reg := [Min(pts[1][1], pts[2][1]), Min(pts[1][2], pts[2][2]), Max(pts[1][1], pts[2][1]), Max(pts[1][2], pts[2][2])]
        IniSet(name, "region", reg[1] "," reg[2] "," reg[3] "," reg[4])
        if (name = "skip")
        {
            SKIPREG := reg
            SKIPLOOKS := []
            CalTipOff()
            AddSkipLook()
            return
        }
        HOTREG := reg
        CalTip("Hotbar area saved. Now press F8 in human form (abilities ready) and F9 in titan form (abilities ready).")
        Sleep, 3500
        CalTipOff()
        return
    }
    Sleep, 1800
    CalTipOff()
}

CancelWiz()
{
    global wizName
    wizName := ""
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

; ======================= SAVE AND LOAD =======================
Join(a)
{
    s := ""
    for i, v in a
        s .= (i > 1 ? "," : "") . v
    return s
}

IniSet(sec, key, val)
{
    IniWrite, %val%, %INI%, %sec%, %key%
}

IniGet(sec, key)
{
    IniRead, v, %INI%, %sec%, %key%, %A_Space%
    v := Trim(v)
    return (v = "ERROR") ? "" : v
}

LoadPts(sec)
{
    pts := []
    Loop, 3
    {
        v := IniGet(sec, "p" A_Index)
        if (v = "")
            return ""
        p := StrSplit(v, ",")
        pts.Push([p[1] + 0, p[2] + 0])
    }
    return pts
}

LoadAll()
{
    global LOADSIG, SKIPREG, SKIPLOOKS, HOTREG, HUMANL, TITANL, POP, CH
    v := IniGet("loading", "sig")
    if (v != "")
        LOADSIG := StrSplit(v, ",")
    v := IniGet("skip", "region")
    if (v != "")
    {
        p := StrSplit(v, ",")
        SKIPREG := [p[1] + 0, p[2] + 0, p[3] + 0, p[4] + 0]
    }
    SKIPLOOKS := []
    Loop, 6
    {
        v := IniGet("skip", "look" A_Index)
        if (v != "")
            SKIPLOOKS.Push(StrSplit(v, ","))
    }
    RebuildMask()
    v := IniGet("hotbar", "region")
    if (v != "")
    {
        p := StrSplit(v, ",")
        HOTREG := [p[1] + 0, p[2] + 0, p[3] + 0, p[4] + 0]
    }
    HUMANL := []
    TITANL := []
    Loop, 5
    {
        i := A_Index
        v := IniGet("human", i)
        if (v != "")
            HUMANL[i] := StrSplit(v, ",")
        v := IniGet("titan", i)
        if (v != "")
            TITANL[i] := StrSplit(v, ",")
    }
    POP := LoadPts("popup")
    CH := LoadPts("chests")
}

; points that look the same in EVERY saved look = the prompt itself (its border and text), not the scene behind it
RebuildMask()
{
    global MASKIDX, MASKCOL
    MASKIDX := []
    MASKCOL := []
    if (SKIPLOOKS.Length() < 2)
        return
    base := SKIPLOOKS[1]
    for j, bc in base
    {
        if (Max((bc >> 16) & 0xFF, (bc >> 8) & 0xFF, bc & 0xFF) < SKIP_BRIGHT)
            continue
        same := true
        for k, look in SKIPLOOKS
        {
            c := look[j]
            if (Abs(((c >> 16) & 0xFF) - ((bc >> 16) & 0xFF)) > MASK_TOL || Abs(((c >> 8) & 0xFF) - ((bc >> 8) & 0xFF)) > MASK_TOL || Abs((c & 0xFF) - (bc & 0xFF)) > MASK_TOL)
            {
                same := false
                break
            }
        }
        if (same)
        {
            MASKIDX.Push(j)
            MASKCOL.Push(bc)
        }
    }
}

SkipScore()
{
    global skBest
    skBest := 0
    if (!IsObject(SKIPREG) || SKIPLOOKS.Length() = 0)
        return -1
    cur := GridRect(SKIPREG, SKIP_COLS, SKIP_ROWS)
    best := 0
    for k, look in SKIPLOOKS
    {
        m := Score(cur, look, SKIP_TOL, SKIP_BRIGHT, true)
        if (m > best)
        {
            best := m
            skBest := k
        }
    }
    if (MASKIDX.Length() >= 6)
    {
        hits := 0
        for n, j in MASKIDX
        {
            c := cur[j]
            bc := MASKCOL[n]
            if (Abs(((c >> 16) & 0xFF) - ((bc >> 16) & 0xFF)) <= SKIP_TOL && Abs(((c >> 8) & 0xFF) - ((bc >> 8) & 0xFF)) <= SKIP_TOL && Abs((c & 0xFF) - (bc & 0xFF)) <= SKIP_TOL)
                hits++
        }
        m := hits / MASKIDX.Length()
        if (m > best)
        {
            best := m
            skBest := 0
        }
    }
    return best
}

AddSkipLook()
{
    global SKIPLOOKS
    if (SKIPLOOKS.Length() >= 6)
    {
        CalTip("6 SKIP looks are saved already. Shift+F4 clears them to start over.")
        Sleep, 2500
        CalTipOff()
        return
    }
    if (!Grab())
        return
    px := Round(0.3 * FW)
    py := Round(0.3 * FH)
    MouseMove, %px%, %py%
    Sleep, 300
    if (!Grab())
        return
    look := GridRect(SKIPREG, SKIP_COLS, SKIP_ROWS)
    SKIPLOOKS.Push(look)
    cnt := SKIPLOOKS.Length()
    lk := "look" cnt
    IniSet("skip", lk, Join(look))
    RebuildMask()
    shared := MASKIDX.Length()
    CalTip("SKIP look " cnt " saved (the box position stays the same).`nPress F4 at each other cutscene, while its SKIP prompt is showing, to add more (up to 6).`nShared prompt points found so far: " shared)
    Sleep, 3500
    CalTipOff()
}

ResetSkip()
{
    global SKIPREG, SKIPLOOKS, wizName, MASKIDX, MASKCOL
    SKIPREG := ""
    SKIPLOOKS := []
    MASKIDX := []
    MASKCOL := []
    wizName := ""
    IniDelete, %INI%, skip
    CalTip("SKIP setup cleared. Press F4 to start again.")
    Sleep, 2000
    CalTipOff()
}

HumanAct()
{
    for _, nm in BUFF_SLOTS
    {
        slot := SlotOf(nm)
        if (rdyH[slot] >= READY_MIN)
        {
            if Due("k" slot, KEY_GAP)
                SendKey(slot)
            return
        }
    }
    s := SlotOf(SHIFT_SLOT)
    if (rdyH[s] >= READY_MIN)
    {
        if Due("k" s, KEY_GAP)
            SendKey(s)
    }
}

TitanAct()
{
    global heatLast, heatStart
    now := A_TickCount
    heatSlot := SlotOf(PRIORITY[1])
    heatReady := (rdyT[heatSlot] >= READY_MIN)
    if (heatStart)
    {
        if (!heatReady)
        {
            heatLast := heatStart
            heatStart := 0
            Note("heatwave turned on")
        }
        else if (now - heatStart > HEAT_BURST_MS)
        {
            heatLast := now - HEAT_ACTIVE_MS + HEAT_RETRY_MS
            heatStart := 0
            Note("heatwave press not confirmed, retrying")
        }
    }
    for i, nm in PRIORITY
    {
        slot := SlotOf(nm)
        if (rdyT[slot] < READY_MIN)
            continue
        if (i = 1)
        {
            if (heatLast > 0 && now - heatLast < HEAT_ACTIVE_MS)
                continue
            if (!heatStart)
                heatStart := now
            if Due("heat", HEAT_GAP)
                SendKey(slot)
            return
        }
        if Due("k" slot, ABIL_GAP)
            SendKey(slot)
        return
    }
}

SlotOf(name)
{
    for i, n in SLOT_NAMES
    {
        if (n = name)
            return i
    }
    return 0
}

SendKey(slot)
{
    key := SLOT_KEYS[slot]
    Send, %key%
}

CheckKeys()
{
    bad := ""
    names := [SHIFT_SLOT]
    for _, nm in BUFF_SLOTS
        names.Push(nm)
    for _, nm in PRIORITY
        names.Push(nm)
    for _, nm in names
    {
        if (SlotOf(nm) = 0)
            bad .= nm " "
    }
    return bad
}
