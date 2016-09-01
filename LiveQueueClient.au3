#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
;~ #include <Array.au3>
;~ #include <Date.au3>
#include <File.au3>


Local $logsPath = @ScriptDir & "\Logs\"
If Not FileExists($logsPath) Then _
	DirCreate($logsPath)

ToLog("---App started---")
ToLog(@ComputerName)
ToLog(@UserName)
ToLog("-----------------")

Local $ipToConnect = "172.16.166.182"
Local $portToConnect = 1313

Local $timeOut = 500 * 1000
Local $onePercent = $timeOut / 100

Local $mainWidth = 200
Local $mainHeight = 100
Local $mainGap = 6

Local $mainBkColor = 0xffffff

$mainGui = GUICreate("", $mainWidth, $mainHeight, @DesktopWidth - $mainWidth - 40, _
	@DesktopHeight - $mainHeight - 40, BitOr($WS_BORDER, $WS_POPUP), $WS_EX_TOPMOST)
;~ _ArrayDisplay(WinGetClientSize($mainGui))
GUISetBkColor($mainBkColor)
GUISetFont(12, 400, -1, "Franklin Gothic Book")

Local $labelHeight = 30
Local $freeBkColor = 0xabd047
Local $busyBkColor = 0xf34942
Local $ndefBkColor = $mainBkColor
Local $freeColor = 0x2d3d3f
Local $ndefColor = $freeColor
Local $busyColor = $mainBkColor
Local $ndefText = "Состояние неизвестно"
Local $freeText = "Кабинет свободен"
Local $busyText = "Кабинет занят"

Local $cabinetLabel = GUICtrlCreateLabel($ndefText, $mainGap, $mainGap, _
	$mainWidth - $mainGap * 2, $labelHeight, _
	BitOr($SS_CENTER, $SS_CENTERIMAGE), $GUI_WS_EX_PARENTDRAG)
GUICtrlSetFont(-1, -1, 600)
GUICtrlSetBkColor(-1, $ndefBkColor)
GUICtrlSetColor(-1, $ndefColor)

Local $progressHeight = 5
Local $prevPos = ControlGetPos($mainGui, "", $cabinetLabel)
Local $progress = GUICtrlCreateProgress($prevPos[0], _
	$prevPos[1] + $prevPos[3] - $progressHeight, $prevPos[2], $progressHeight)
GUICtrlSetState(-1, $GUI_HIDE)

$prevPos = ControlGetPos($mainGui, "", $progress)
Local $button = GUICtrlCreateButton("Переключить", $prevPos[0], _
	$prevPos[1] + $prevPos[3] + $mainGap, $prevPos[2], $labelHeight)

Local $prevGuiPos = WinGetPos($mainGui, "")
;~ _ArrayDisplay($prevGuiPos)
$prevPos = ControlGetPos($mainGui, "", $button)
WinMove($mainGui, "", $prevGuiPos[0], $prevGuiPos[1], $prevGuiPos[2], _
	$prevPos[1] + $prevPos[3] + $mainGap + 2)
;~ _ArrayDisplay(WinGetClientSize($mainGui))

Local $needToUpdate = True

GUISetState()

Local $counter = 0
Local $sleepTime = 50
While 1
	Local $nMsg = GUIGetMsg()

	If $counter Or _
		GUICtrlRead($cabinetLabel) = $busyText Or _
		GUICtrlRead($cabinetLabel) = $ndefText Then

		$counter += $sleepTime
		If $counter >= $onePercent Then
			Local $current = GUICtrlRead($progress)
			GUICtrlSetData($progress, $current - 1)
			$counter = 0

			If $current = 1 Then $nMsg = $button
		EndIf
	EndIf

	If $nMsg = $button Or $needToUpdate Then
		$needToUpdate = False
		Local $setFree = False
		If GUICtrlRead($cabinetLabel) <> $freeText Then
			$setFree = True
			$counter = 0
		EndIf

		Local $updated = UpdateCabinetStatus($setFree)

		Local $newText = $updated ? ($setFree ? $freeText : $busyText) : $ndefText
		GUICtrlSetData($cabinetLabel, $newText)

		Local $newBkColor = $updated ? ($setFree ? $freeBkColor : $busyBkColor) : $ndefBkColor
		GUICtrlSetBkColor($cabinetLabel, $newBkColor)

		Local $newColor = $updated ? ($setFree ? $freeColor : $busyColor) : $ndefColor
		GUICtrlSetColor($cabinetLabel, $newColor)

		Local $newState = $updated ? ($setFree ? $GUI_HIDE : $GUI_SHOW) : $GUI_SHOW
		GUICtrlSetState($progress, $newState)

		Local $newProgress = $updated ? ($setFree ? 0 : 100) : 100
		GUICtrlSetData($progress, $newProgress)

		ToLog("New state: " & $newText)
	EndIf

	Sleep($sleepTime)
WEnd


Func UpdateCabinetStatus($markToSend)
	TCPStartup()

	Local $iSocket = TCPConnect($ipToConnect, $portToConnect)

	If @error Then
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "Сетевая ошибка", _
			"Не удается соединиться с монитором над кабинетом" & @CRLF & _
			"Необходимо обратиться к системному администратору")
		Return False
	EndIf

	TCPSend($iSocket, int($markToSend))

	If @error Then
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "Сетевая ошибка", _
			"Не удается отправить данные на монитор над кабинетом" & @CRLF & _
			"Необходимо обратиться к системному администратору")
		Return False
	EndIf

	TCPCloseSocket($iSocket)
	TCPShutdown()

	Return True
EndFunc


Func ToLog($message)
	Local $logFilePath = $logsPath & @ScriptName & "_" & @YEAR & @MON & @MDAY & ".log"
	$message &= @CRLF
	ConsoleWrite($message)
	_FileWriteLog($logFilePath, $message)
EndFunc