format PE GUI 4.0
entry Start

include 'win32a.inc'

section '.text' code readable executable

Start:

;  invoke  LoadLibraryA,  _lib
;  mov [hLib], eax

  ;invoke  RaplaceSctring, srcString,  newString   

  invoke  MessageBoxW, NULL, _wait, srcString, 0  
  invoke  MessageBoxW, NULL, srcString, srcString, 0
  jmp end_loop
   
error:
  invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

end_loop:
  invoke ExitProcess, 0

section '.data' data readable writeable

  hLib  dd  ?
  AdrProc dd  ?
  
  srcString du  'Source string', 0  
  newString du  'New string', 0
  _wait du  'wait', 0
  
  _lib  db  'ERRORMSG.dll', 0
  _proc db  'ShowLastError', 0   
  _error  db  'Error', 0 

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
	  user32, 'USER32.DLL',\
    ERRORMSG, 'ERRORMSG.DLL'
    
  import ERRORMSG,\
       RaplaceSctring, 'RaplaceSctring'    

  include 'api\kernel32.inc'
  include 'api\user32.inc'