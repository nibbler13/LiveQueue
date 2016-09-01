#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>


LiveQueueServer()


Func LiveQueueServer()
	TCPStartup()
	OnAutoItExitRegister("OnAutoItExit")

	Local $sIPAddress = "172.16.166.182"
	Local $iPort = 1313

	Local $iListenSocket = TCPListen($sIPAddress, $iPort, 100)

	If @error Then
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", _
			"Server:" & @CRLF & "Could not listen, Error code: " & @error)
		Return False
	EndIf

	Local $iSocket = 0

	While 1
		$iSocket = TCPAccept($iListenSocket)

		If @error Then
;~ 			MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", _
;~ 				"Server:" & @CRLF & "Could not accept the incoming connection, Error code: " & @error)
;~ 			Return False
		EndIf

		If $iSocket <> -1 Then
			Local $sReceived = TCPRecv($iSocket, 10)
			ConsoleWrite($sReceived & @CRLF)

;~ 			MsgBox($MB_SYSTEMMODAL, "", "Server:" & @CRLF & "Received: " & $sReceived)

			Local $path = "C:\Temp\207-0.png"
			If $sReceived = "0x01000000" Then $path = "C:\Temp\207-1.png"
			ShellExecute($path)
		EndIf

		Sleep(20)
	WEnd

	TCPCloseSocket($iListenSocket)
	TCPCloseSocket($iSocket)
EndFunc


Func OnAutoItExit()
	TCPShutdown()
EndFunc
