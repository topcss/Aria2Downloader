#include <Process.au3>
#include <file.au3>

;~ 发布目录的处理
$workingDir =  @WorkingDir
$runPath = 'D:\AutoIt3\Aut2Exe\Aut2exe.exe'
$dist =  $workingDir & '\dist'
$sLogPath = $dist & '\' & @YEAR & @MON & @MDAY & '.log'

DirRemove($dist)
DirCreate($dist)

DirCopy ($workingDir & '\lib', $dist & '\lib')
DirCopy ($workingDir & '\www', $dist & '\www')

FileCopy($workingDir & '\404.html', $dist & '\www\404.html')

;~ 关闭程序
KillProc("aria2.exe")
KillProc("aria2c.exe")
KillProc("Aria2Downloader.exe")

_FileWriteLog($sLogPath, ' Publish Dll => ' & $dist & @CRLF)

;~ 修改关于的路径
$file = FileRead($dist & '\www\index.html')
$str = StringRegExpReplace($file, 'mayswind/AriaNg', 'topcss/Aria2Downloader')
FileWrite(FileOpen($dist & '\www\index.html', 1), $str)

;~ 编译程序
_RunDOS($runPath & " /in ./src/Main.au3 /out ./dist/Aria2Downloader.exe  /icon ./www/favicon.ico")

_FileWriteLog($sLogPath, ' Publish Exe. '  & @CRLF)

;~ 提示消息
_FileWriteLog($sLogPath, '编译成功！')

Func KillProc($sName)
    _FileWriteLog($sLogPath, ' KillProc -> ' & $sName & @CRLF)
    while ProcessExists($sName)
        ProcessClose($sName)
    WEnd
 EndFunc