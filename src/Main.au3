#NoTrayIcon

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>

#include "CoProc.au3"
#include "HttpServer.au3"

Local $sURL = GetArgs()[3]
Local $iProcHttpServer = _CoProc("HttpServer")

; 进程中不存在，则打开服务端
Local $sAria2path = @WorkingDir & "\lib\aria2.exe"
Local $bFlag = False
If ProcessExists('aria2.exe') == 0 AND FileExists($sAria2path) Then
    ShellExecute($sAria2path)
    $bFlag = True
EndIf

; 定义界面
$GUIMain = GUICreate("Aria2Downloader 高速下载", 860, 600)
GUISetIcon("favicon.ico", 0);设置窗口图标

$oIE = ObjCreate("Shell.Explorer.2")
GUICtrlCreateObj($oIE, 0, 0, 860, 600)

$oIE.navigate($sURL)

Sleep(500)
GUISetState(@SW_SHOW) ;Show GUI

While 1

    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            If $bFlag Then ; 如果是程序打开的，就关闭它
                ;清理进程
                while ProcessExists("aria2.exe") ; Check if the aria2 process is running.
                    ProcessClose("aria2.exe")
                WEnd
                while ProcessExists("aria2c.exe") ; Check if the aria2c process is running.
                    ProcessClose("aria2c.exe")
                WEnd
            EndIf

            ExitLoop
    EndSwitch

WEnd

ProcessClose($iProcHttpServer)
GUIDelete()
Exit
