#include <Process.au3>

$workingDir =  @WorkingDir
$runPath = 'D:\AutoIt3\Aut2Exe\Aut2exe.exe'
$dist =  $workingDir & '\dist'

DirRemove($dist)
DirCreate($dist)

DirCopy ($workingDir & '\lib', $dist & '\lib')
DirCopy ($workingDir & '\www', $dist & '\www')

_RunDOS($runPath & " /in ./src/Main.au3 /out ./dist/Aria2Downloader.exe  /icon ./www/favicon.ico")

MsgBox(0, '消息', '编译成功！')