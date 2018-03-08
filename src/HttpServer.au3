Func GetArgs()
    ; // OPTIONS HERE //
    Local $sRootDir = @ScriptDir & "\www" ; The absolute path to the root directory of the server.
    Local $sIP = @IPAddress1 ; ip address as defined by AutoIt
    Local $iPort = 8086 ; the listening port
    Local $sServerAddress = "http://" & $sIP & ":" & $iPort & "/"
    Local $iMaxUsers = 15 ; Maximum number of users who can simultaneously get/post
    Local $sServerName = "ManadarX/1.1 (" & @OSVersion & ") AutoIt " & @AutoItVersion
    ; // END OF OPTIONS //

    Local $aSocket[$iMaxUsers] ; Creates an array to store all the possible users
    Local $sBuffer[$iMaxUsers] ; All these users have buffers when sending/receiving, so we need a place to store those

    For $x = 0 to UBound($aSocket)-1 ; Fills the entire socket array with -1 integers, so that the server knows they are empty.
        $aSocket[$x] = -1
    Next

    Dim $Array[8]

    $Array[0]=$sRootDir
    $Array[1]=$sIP
    $Array[2]=$iPort
    $Array[3]=$sServerAddress
    $Array[4]=$iMaxUsers
    $Array[5]=$sServerName

    $Array[6]=$aSocket
    $Array[7]=$sBuffer

    Return  $Array
EndFunc


Func HttpServer()
    
    Local $sRootDir = GetArgs()[0]
    Local $sIP = GetArgs()[1]
    Local $iPort = GetArgs()[2]
    Local $sServerAddress = GetArgs()[3]
    Local $iMaxUsers = GetArgs()[4]
    Local $sServerName = GetArgs()[5]
    Local $aSocket = GetArgs()[6]
    Local $sBuffer = GetArgs()[7]


    TCPStartup() ; AutoIt needs to initialize the TCP functions

    $iMainSocket = TCPListen($sIP,$iPort) ;create main listening socket
    If @error Then ; if you fail creating a socket, exit the application
        MsgBox(0x20, "AutoIt Webserver", "Unable to create a socket on port " & $iPort & ".") ; notifies the user that the HTTP server will not run
        Exit ; if your server is part of a GUI that has nothing to do with the server, you'll need to remove the Exit keyword and notify the user that the HTTP server will not work.
    EndIf


    ConsoleWrite( "Server created on " & $sServerAddress & @CRLF) ; If you're in SciTE,

    While 1
        $iNewSocket = TCPAccept($iMainSocket) ; Tries to accept incoming connections

        If $iNewSocket >= 0 Then ; Verifies that there actually is an incoming connection
            For $x = 0 to UBound($aSocket)-1 ; Attempts to store the incoming connection
                If $aSocket[$x] = -1 Then
                    $aSocket[$x] = $iNewSocket ;store the new socket
                    ExitLoop
                EndIf
            Next
        EndIf

        For $x = 0 to UBound($aSocket)-1 ; A big loop to receive data from everyone connected
            If $aSocket[$x] = -1 Then ContinueLoop ; if the socket is empty, it will continue to the next iteration, doing nothing
            $sNewData = TCPRecv($aSocket[$x],1024) ; Receives a whole lot of data if possible
            If @error Then ; Client has disconnected
                $aSocket[$x] = -1 ; Socket is freed so that a new user may join
                ContinueLoop ; Go to the next iteration of the loop, not really needed but looks oh so good
            ElseIf $sNewData Then ; data received
                $sBuffer[$x] &= $sNewData ;store it in the buffer
                If StringInStr(StringStripCR($sBuffer[$x]),@LF&@LF) Then ; if the request has ended ..
                    $sFirstLine = StringLeft($sBuffer[$x],StringInStr($sBuffer[$x],@LF)) ; helps to get the type of the request
                    $sRequestType = StringLeft($sFirstLine,StringInStr($sFirstLine," ")-1) ; gets the type of the request
                    If $sRequestType = "GET" Then ; user wants to download a file or whatever ..
                        $sRequest = StringTrimRight(StringTrimLeft($sFirstLine,4),11) ; let's see what file he actually wants
                        If StringInStr(StringReplace($sRequest,"\","/"), "/.") Then ; Disallow any attempts to go back a folder
                            _HTTP_SendError($aSocket[$x]) ; sends back an error
                        Else
                            If $sRequest = "/" Then ; user has requested the root
                                $sRequest = "/index.html" ; instead of root we'll give him the index page
                            EndIf
                            $sRequest = StringReplace($sRequest,"/","\") ; convert HTTP slashes to windows slashes, not really required because windows accepts both

                            ; 解决带参数 ? 的文件找不到的问题
                            If StringInStr($sRequest, '?') > 0 Then
                                $sRequest = StringLeft($sRequest, StringInStr($sRequest, '?') - 1);
                            EndIf

                            If FileExists($sRootDir & "\" & $sRequest) Then ; makes sure the file that the user wants exists
                                $sFileType = StringRight($sRequest,4) ; determines the file type, so that we may choose what mine type to use
                                Switch $sFileType
                                    Case "html", ".htm" ; in case of normal HTML files
                                        _HTTP_SendFile($aSocket[$x], $sRootDir & $sRequest, "text/html")
                                    Case ".css" ; in case of style sheets
                                        _HTTP_SendFile($aSocket[$x], $sRootDir & $sRequest, "text/css")
                                    Case ".jpg", "jpeg" ; for common images
                                        _HTTP_SendFile($aSocket[$x], $sRootDir & $sRequest, "image/jpeg")
                                    Case ".png" ; another common image format
                                        _HTTP_SendFile($aSocket[$x], $sRootDir & $sRequest, "image/png")
                                    Case Else ; this is for .exe, .zip, or anything else that is not supported is downloaded to the client using a application/octet-stream
                                        _HTTP_SendFile($aSocket[$x], $sRootDir & $sRequest, "application/octet-stream")
                                EndSwitch
                            Else
                                _HTTP_SendFileNotFoundError($aSocket[$x]) ; File does not exist, so we'll send back an error..
                            EndIf
                        EndIf
                    EndIf

                    $sBuffer[$x] = "" ; clears the buffer because we just used to buffer and did some actions based on them
                    $aSocket[$x] = -1 ; the socket is automatically closed so we reset the socket so that we may accept new clients

                EndIf
            EndIf
        Next

        Sleep(10)
    WEnd
    
EndFunc



Func _HTTP_ConvertString(ByRef $sInput) ; converts any characters like %20 into space 8)
    $sInput = StringReplace($sInput, '+', ' ')
    StringReplace($sInput, '%', '')
    For $t = 0 To @extended
        $Find_Char = StringLeft( StringTrimLeft($sInput, StringInStr($sInput, '%')) ,2)
        $sInput = StringReplace($sInput, '%' & $Find_Char, Chr(Dec($Find_Char)))
    Next
EndFunc

Func _HTTP_SendHTML($hSocket, $sHTML, $sReply = "200 OK") ; sends HTML data on X socket
    _HTTP_SendData($hSocket, Binary($sHTML), "text/html", $sReply)
EndFunc

Func _HTTP_SendFile($hSocket, $sFileLoc, $sMimeType, $sReply = "200 OK") ; Sends a file back to the client on X socket, with X mime-type
    Local $hFile, $sImgBuffer, $sPacket, $a

	ConsoleWrite("Sending " & $sFileLoc & @CRLF)

    $hFile = FileOpen($sFileLoc,16)
    $bFileData = FileRead($hFile)
    FileClose($hFile)

    _HTTP_SendData($hSocket, $bFileData, $sMimeType, $sReply)
EndFunc

Func _HTTP_SendData($hSocket, $bData, $sMimeType, $sReply = "200 OK")
 
    Local $sServerName = GetArgs()[5]

    Local	$sPacket = Binary("HTTP/1.1 " & $sReply & @CRLF & _
    "Server: " & $sServerName & @CRLF & _
	"Connection: close" & @CRLF & _
	"Content-Lenght: " & BinaryLen($bData) & @CRLF & _
    "Content-Type: " & $sMimeType & @CRLF & _
    @CRLF)
    TCPSend($hSocket,$sPacket) ; Send start of packet

    While BinaryLen($bData) ; Send data in chunks (most code by Larry)
        $a = TCPSend($hSocket, $bData) ; TCPSend returns the number of bytes sent
        $bData = BinaryMid($bData, $a+1, BinaryLen($bData)-$a)
    WEnd

    $sPacket = Binary(@CRLF & @CRLF) ; Finish the packet
    TCPSend($hSocket,$sPacket)

	TCPCloseSocket($hSocket)
EndFunc

Func _HTTP_SendFileNotFoundError($hSocket) ; Sends back a basic 404 error

    Local $sRootDir = GetArgs()[0]

	Local $s404Loc = $sRootDir & "\404.html"
	If (FileExists($s404Loc)) Then
		_HTTP_SendFile($hSocket, $s404Loc, "text/html")
	Else
		_HTTP_SendHTML($hSocket, "404 Error: " & @CRLF & @CRLF & "The file you requested could not be found.")
	EndIf
EndFunc
