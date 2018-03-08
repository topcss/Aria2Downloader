#NoTrayIcon

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>

#include "CoProc.au3"
#include "HttpServer.au3"

Local $sURL = GetArgs()[3]

; 进程中不存在，则打开服务端
Local $sAria2path = @WorkingDir & "\lib\aria2.exe"
Local $bFlag = False
If ProcessExists('aria2.exe') == 0 AND FileExists($sAria2path) Then
    ShellExecute($sAria2path)
    $bFlag = True
EndIf

ConsoleWrite("Start " & $sAria2path & @CRLF)

Local $iProcHttpServer = _CoProc("HttpServer")
ConsoleWrite("Start New Process " & $iProcHttpServer & @CRLF)

; 定义界面
$GUIMain = GUICreate("Aria2Downloader 高速下载工具", 860, 600)
GUISetIcon("favicon.ico", 0);设置窗口图标

$oIE = ObjCreate("Shell.Explorer.2")
GUICtrlCreateObj($oIE, 0, 0, 860, 600)

$oIE.navigate($sURL)

Sleep(1000)
GUISetState(@SW_SHOW) ;Show GUI

ConsoleWrite("Start " & $sURL & @CRLF)

While 1

    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            ConsoleWrite("ExitLoop " & @CRLF)

            If $bFlag Then ; 如果是程序打开的，就关闭它
                ;清理进程
                KillProc("aria2.exe")
                KillProc("aria2c.exe")
            EndIf

            ExitLoop
    EndSwitch

    Sleep(20)
WEnd

ProcessClose($iProcHttpServer)
GUIDelete()
Exit

Func KillProc($sName)
    ConsoleWrite(' KillProc -> ' & $sName & @CRLF)
    while ProcessExists($sName)
        ProcessClose($sName)
    WEnd
 EndFunc
