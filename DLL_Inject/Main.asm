format PE Console 4.0
entry Start
    
include 'win32ax.inc'  
include 'MyH.inc' 

INFINITY  = 0xFFFFFFFF 
TH32CS_SNAPPROCESS = 0x00000002
    
section '.text' code readable executable

Start:
  ;������������� �������(��������:)
  invoke SetConsoleTitleA, conTitle
  test eax, eax
  jz Exit

  invoke GetStdHandle, [STD_OUTP_HNDL]
  mov [hStdOut], eax

  invoke GetStdHandle, [STD_INP_HNDL]
  mov [hStdIn], eax

  ;��������� ���������� ��������� ������
  invoke  GetCommandLineW 
  invoke  CommandLineToArgvW, eax, argc 
  mov [strbuffer],  eax
  add [argc], 48 
  mov ebx,  [eax + 4]
  mov [dwPID],  ebx                              ;!!!�������� ��������� ������ � ����������� ��������� ����������� ��   
  
  
   
 ; stdcall  GetPidByProcessName
;  mov [dwPID], eax                                  
   
  ;�������������� ������ PID � ���������� �����
  invoke  _wtoi, [dwPID]
  mov [dwPID],  eax 
  
    

  ;�������� 
  ;mov [dwPID],  7932               ;!!!�������
  ;�������� 
    
  ;�������� ��������
  invoke  OpenProcess, PROCESS_ALL_ACCESS, FALSE, [dwPID]
  mov [hProcess], eax  
  test  eax,  eax
  jnz @F  
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], OpenProcessError, OpenProcessErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@:
  
  ;��������� ����������� ������ 
  invoke  VirtualAllocEx, [hProcess], NULL, szDllPath, MEM_RESERVE or MEM_COMMIT, PAGE_READWRITE  
  mov [pRemoteBuf], eax  
  test  eax,  eax
  jnz @F       
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], VirtualAllocExError, VirtualAllocExErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@:
  
  ;������ ���� � ����� Dll � ������
  invoke  WriteProcessMemory, [hProcess], [pRemoteBuf], DllPath, szDllPath, NULL  
  test  eax,  eax
  jnz @F                    
  invoke  VirtualFreeEx, [hProcess], DllPath, szDllPath, MEM_RELEASE  
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], WriteProcessMemoryError, WriteProcessMemoryErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 
  
  ;��������� ����������� ������ 
  invoke  GetModuleHandleW, kernelPath 
  mov [hMod], eax                 
  test  eax,  eax
  jnz @F            
  invoke  VirtualFreeEx, [hProcess], DllPath, szDllPath, MEM_RELEASE  
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], GetModuleHandleError, GetModuleHandleErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 

  ;��������� ������ LoadLibrary
  invoke  GetProcAddress, [hMod], LoadLibraryWName  
  mov [pThreadProc], eax                         
  test  eax,  eax
  jnz @F   
  invoke  VirtualFreeEx, [hProcess], DllPath, szDllPath, MEM_RELEASE  
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], GetProcAddressError, GetProcAddressErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 

  ;����� ��������� ������
  invoke  CreateRemoteThread, [hProcess], NULL, 0, [pThreadProc], [pRemoteBuf], 0, dwThreadId   
  mov [hThread], eax          
  test  eax,  eax
  jnz @F            
  invoke  VirtualFreeEx, [hProcess], DllPath, szDllPath, MEM_RELEASE  
  invoke  CloseHandle, [hProcess]
  invoke WriteConsoleA, [hStdOut], CreateRemoteThreadError, CreateRemoteThreadErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 
    
  ;�������� ���������� ��������� ������
  invoke  WaitForSingleObject, [hThread], INFINITY  
  cmp  eax,  0xFFFFFFFF     
  jnz @F  
  invoke WriteConsoleA, [hStdOut], WaitForSingleObjectError, WaitForSingleObjectErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 

  ;�������� ���� ���������� ������
  invoke  GetExitCodeThread, [hThread], exitCode        
  test  eax,  eax
  jnz @F  
  invoke WriteConsoleA, [hStdOut], GetExitCodeThreadError, GetExitCodeThreadErrorLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 
  jmp Exit
@@: 
    
  ;������� ������ 
  invoke  CloseHandle, [hThread]  
  invoke  CloseHandle, [hProcess]
  invoke  VirtualFreeEx, [hProcess], DllPath, szDllPath, MEM_RELEASE        
  invoke LocalFree,  [strbuffer]                                                             
  
  invoke WriteConsoleA, [hStdOut], Success, SuccessLen, chrsWritten, 0
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0    
      
Exit:
  invoke  ExitProcess, 0

;������� ������ PID �������� �� �����
proc GetPidByProcessName                      ;!!!������� �������
  local pe32:PROCESSENTRY32
  local hSnapshot dd  ? 
  
  mov [pe32.dwSize], 26 ;!!!���������� ������ ��������� ����� sizeof
  
  invoke  CreateToolhelp32Snapshot, TH32CS_SNAPPROCESS, NULL
  mov [hSnapshot], eax
  cmp  eax,  INVALID_HANDLE_VALUE
  jnz @f
  invoke WriteConsoleA, [hStdOut], CreateToolhelp32SnapshotError, CreateToolhelp32SnapshotErrorLen, chrsWritten, 0
  jmp ._end
@@: 
  invoke  Process32First, [hSnapshot], addr pe32
  
@@:  
  invoke  wcscmp, addr pe32.szExeFile, lpszProcessName  
  test  eax,  eax
  jz  @F
  invoke  Process32Next, [hSnapshot], addr pe32    
  jmp @B
@@: 
  mov ax, [pe32.th32ProcessID]
  movzx eax,  ax
._end:
  ret
endp

section '.data' data readable writeable
  conTitle    db 'Console', 0
  mes         db 'Hello World!', 0dh, 0ah, 0
  mesLen      = $-mes

  hStdIn      dd 0
  hStdOut     dd 0
  chrsRead    dd 0
  chrsWritten dd 0

  STD_INP_HNDL  dd -10
  STD_OUTP_HNDL dd -11
  
  dwPID dd  ?
  
  DllPath du  'ERRORMSG.dll', 0
  szDllPath = $-DllPath  
  
  argc  dd  ?
  
  lpszProcessName du  'Project.exe', 0
  
  strbuffer dd  ?     
  
  hProcess dd ?
  
  pRemoteBuf  dd  ?
  
  hMod  dd  ?
  
  pThreadProc   dd  ?
  
  hThread dd  ?
  
  kernelPath  du  'kernel32.dll', 0
  
  dwThreadId  dd  ?
  
  exitCode  dd  ?
  
  LoadLibraryWName  db  'LoadLibraryW', 0
  
  OpenProcessError  db  'OpenProcess Faild', 0  
  OpenProcessErrorLen      = $-OpenProcessError  
    
  VirtualAllocExError  db  'VirtualAllocEx Faild', 0  
  VirtualAllocExErrorLen      = $-VirtualAllocExError
  
  WriteProcessMemoryError db  'WriteProcessMemoryError', 0
  WriteProcessMemoryErrorLen  = $-WriteProcessMemoryError  
  
  GetModuleHandleError  db  'GetModuleHandleError', 0
  GetModuleHandleErrorLen = $-GetModuleHandleError 
  
  GetProcAddressError db  'GetProcAddressError', 0
  GetProcAddressErrorLen  = $-GetProcAddressError 
  
  CreateRemoteThreadError db  'CreateRemoteThreadError', 0
  CreateRemoteThreadErrorLen = $-CreateRemoteThreadError 
                       
  WaitForSingleObjectError db  'WaitForSingleObjectError', 0
  WaitForSingleObjectErrorLen = $-WaitForSingleObjectError           
                       
  GetExitCodeThreadError db  'GetExitCodeThreadError', 0
  GetExitCodeThreadErrorLen = $-GetExitCodeThreadError 
                                                                                          
  CreateToolhelp32SnapshotError db  'CreateToolhelp32SnapshotError INVALID_HANDLE_VALUE', 0
  CreateToolhelp32SnapshotErrorLen = $-CreateToolhelp32SnapshotError 
  
  Success db  'Success', 0
  SuccessLen = $-Success
   
section '.bss' readable writeable

  readBuf  db ?

section '.idata' import data readable

  library kernel, 'KERNEL32.DLL',\
    shell,    'SHELL32.DLL',\
    msvcrt, 'MSVCRT.DLL'
        
  import kernel,\
    SetConsoleTitleA, 'SetConsoleTitleA',\
    GetStdHandle, 'GetStdHandle',\
    WriteConsoleA, 'WriteConsoleA',\
    WriteConsoleW,  'WriteConsoleW',\
    ReadConsoleA, 'ReadConsoleA',\
    GetCommandLineW, 'GetCommandLineW',\
    LocalFree, 'LocalFree',\
    OpenProcess, 'OpenProcess',\
    VirtualAllocEx, 'VirtualAllocEx',\
    WriteProcessMemory, 'WriteProcessMemory',\
    GetModuleHandleW,  'GetModuleHandleW',\
    GetProcAddress, 'GetProcAddress',\
    CreateRemoteThread, 'CreateRemoteThread',\
    WaitForSingleObject, 'WaitForSingleObject',\
    CloseHandle, 'CloseHandle',\
    GetLastError, 'GetLastError',\
    GetExitCodeThread,  'GetExitCodeThread',\
    VirtualFreeEx, 'VirtualFreeEx',\
    CreateToolhelp32Snapshot, 'CreateToolhelp32Snapshot',\
    Process32First, 'Process32First',\
    Process32Next, 'Process32Next',\
    ExitProcess, 'ExitProcess'

  import shell,\ 
    CommandLineToArgvW, 'CommandLineToArgvW'  
    
  import msvcrt,\
    _wtoi, '_wtoi',\
    wcslen, 'wcslen',\
    wcscmp, 'wcscmp' 