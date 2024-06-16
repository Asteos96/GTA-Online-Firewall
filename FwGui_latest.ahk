/* GTA Online Firewall */
/* You can find a few settings at the end of this file */
/* Last update June 16, 2024 */

#Requires AutoHotkey v2.0
#SingleInstance

if not A_IsAdmin {
	Run("*RunAs " A_ScriptFullPath "")
	Pause
}

mainGuiInit()
mainGuiSettings()
mainGuiControlsInit()
switch appMinTray {
	case ("Min"): mainGui.Minimize
	case ("Tray"): mainGui.Hide
}

mainGuiInit() {
	global
	appFont := "Verdana"
	mainGui := Gui("-MinimizeBox")
	mainGui.OnEvent("Close", appExit)
	mainGui.BackColor := "272b34"
	mainGui.Title := "GTA Online Firewall"
	mainGui.SetFont(, "Verdana")
	mainGui.Opt("+Caption")
	mainGui.Show("w200 h300")
}

mainGuiSettings() {
	global

	if isFirstTime()
		setDefaultSettings()

	mainHotkey := IniRead(A_ScriptFullPath, "Settings", "mainHotkey")
	soundsDefaultState := IniRead(A_ScriptFullPath, "Settings", "soundsDefaultState")
	appOptions := IniRead(A_ScriptFullPath, "Settings", "appOptions")
	appMinTray := IniRead(A_ScriptFullPath, "Settings", "appMinTray")

	Hotkey mainHotkey, main
	mainGui.Opt(appOptions)
}

mainGuiControlsInit() {
	global

	stateText := mainGui.Add("Text", "Hidden")
    placeControl(mainGui, stateText, , 100, "-Hidden ce94b4b Center", "s25 Bold", "OFF")
    
    hotkeyText := mainGui.Add("Text", "Hidden")
    placeControl(mainGui, hotkeyText, , 150, "-Hidden cWhite Center", "s11 Norm", "Hotkey - " mainHotkey)
    
    soundsCheckbox := mainGui.Add("CheckBox", "cWhite")
    placeControl(mainGui, soundsCheckbox, , 20, "-Hidden Center", "s11 Norm", "Enable Sounds")
    soundsCheckbox.Value := soundsDefaultState
	soundsCheckbox.onEvent("Click", updateSettings)
    
    trayControl := mainGui.Add("Button", "Hidden")
    placeControl(mainGui, trayControl, , 245, "-Hidden", "s11 Norm", "Minimize")
    trayControl.OnEvent("Click", appHide)
}

isFirstTime()
{
	if not IniRead(A_ScriptFullPath, "General", "LastUser") = A_UserName
		return true
}

setDefaultSettings() {
	IniWrite A_UserName, A_ScriptFullPath, "General", "lastUser"
	IniWrite "PgDn", A_ScriptFullPath, "Settings", "mainHotkey"
	IniWrite "1", A_ScriptFullPath, "Settings", "soundsDefaultState"
	IniWrite "-AlwaysOnTop", A_ScriptFullPath, "Settings", "appOptions"
	IniWrite "", A_ScriptFullPath, "Settings", "appMinTray"
}

updateSettings(*) {
	IniWrite soundsCheckbox.Value, A_ScriptFullPath, "Settings", "soundsDefaultState"
}

main(*) {
    static isActive := false

	switch isActive {
		case false:
			try gamePath := WinGetProcessPath("ahk_exe GTA5.exe")
			catch {
				mainGui.Opt("-AlwaysOnTop")
				MsgBox("GTA5 process is not found, start the game!", "Oops!")
				mainGui.Opt(appOptions)
				return
			}
			isActive := true
			placeControl(mainGui, stateText, , 100, "-Hidden c83f783 Center", "s25 Bold", "ON")
			RunWait('netsh advfirewall firewall add rule name="GTA Online Firewall (80/443)" dir=out action=block remoteport="80","443" protocol=TCP program="' gamePath '"', , "hide")
		case true:
			isActive := false
			placeControl(mainGui, stateText, , 100, "-Hidden ce94b4b Center", "s25 Bold", "OFF")
			RunWait('netsh advfirewall firewall delete rule name="GTA Online Firewall (80/443)"', , "hide")
	}
	playSound(isActive)
}

playSound(isActive) {
	if (soundsCheckbox.Value == false)
		return

	switch isActive {
		case false:
			SoundBeep(350, 50)
		case true:
			SoundBeep(423, 50), SoundBeep(623, 50)
	}
}

placeControl(guiName, controlName, controlPosX?, controlPosY?, controlOptions := "", controlFontStyle := "", controlText := "") {
	controlName.Move(controlPosX?, controlPosY?)
	controlName.Text := controlText
	controlResize(controlName, controlFontStyle)
	if not IsSet(controlPosX)
		controlAlignCenter(guiName, , controlName)
	controlName.SetFont(controlFontStyle)
	controlName.Opt(controlOptions)
}

controlResize(controlName, controlFontStyle) {
	dummyGui := Gui()
	dummyGui.SetFont(controlFontStyle, appFont)
	dummyControl := dummyGui.Add(controlName.Type, , controlName.Text)
	dummyControl.GetPos(, , &dummyControlHeight, &dummyControlWidth)
	controlName.Move(, , dummyControlHeight, dummyControlWidth)
	dummyGui.Destroy()
}

controlAlignCenter(guiName, intervalWidth := 0, controls*) {
	controlsWidths := []
	guiName.GetClientPos(, , &guiWidth)
	for i in controls {
		controls[A_Index].GetPos(, , &controlWidth)
		controlsWidths.Push(controlWidth)
		totalControlsWidth := (totalControlsWidth ?? 0) + controlWidth
	}
	for i in controls {
		controlPosX := (guiWidth - totalControlsWidth - (controls.Length - 1) * intervalWidth) / 2
		if A_Index > 1
			controlPosX += controlsWidths[A_Index - 1] + intervalWidth * (A_Index - 1)
		controls[A_Index].Move(controlPosX)
	}
}

appHide(*) {
    mainGui.Minimize()
}

appRestart() {
	Reload
}

appExit(*) {
    RunWait('netsh advfirewall firewall delete rule name="GTA Online Firewall (80/443)"', , "hide")
	ExitApp
}

/*
[General]
Updates automatically, do not change!
lastUser=Asteos

[Settings]
The main hotkey. All supported key names: https://www.autohotkey.com/docs/v2/KeyList.htm
mainHotkey=PgDn

The default state of "Enable Sounds" checkbox. Valid values are 0 or 1
soundsDefaultState=1

Whether the app should be on top of other windows or not. Valid values are +AlwaysOnTop or -AlwaysOnTop
appOptions=-AlwaysOnTop

Whether the app should be minimized or hidden in tray on startup. Keep empty or use valid values: Min or Tray
appMinTray=Tray
