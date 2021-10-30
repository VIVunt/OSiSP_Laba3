format PE GUI 4.0
entry Start

include 'win32a.inc'

section '.text' code readable executable

Start:
  invoke  RaplaceString,  srcString,  newString
  invoke MessageBoxW, NULL, srcString, srcString, MB_OK 

end_loop:
  invoke ExitProcess, [msg.wParam]

section '.data' data readable writeable

  _class TCHAR 'FASMWIN32', 0
  _title TCHAR 'Win32 program template', 0
  _error TCHAR 'Startup failed.', 0
  
  srcString   du  'Source string', 0
  newString du  'New string', 0

  msg MSG

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
	  user32, 'USER32.DLL',\
    errormsg, 'ERRORMSG.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  
  import  errormsg,\
    RaplaceString, 'RaplaceString'