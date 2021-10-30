format PE GUI 4.0 DLL
entry DllEntryPoint

include 'win32ax.inc'     
include 'MyH.inc' 
         
DLL_PROCESS_DETACH = 0  
DLL_PROCESS_ATTACH = 1    
DLL_THREAD_ATTACH = 2    
DLL_THREAD_DETACH = 3    

MEM_IMAGE = 0x01000000

section '.text' code readable executable

proc DllEntryPoint hinstDLL, fdwReason, lpvReserved 
  cmp [fdwReason], DLL_PROCESS_ATTACH
  jnz @F    
  stdcall RaplaceString, srcString, newString 
  jmp .endEntry
@@: 
.endEntry:
  mov eax, TRUE                                              
  ret
endp

proc  RaplaceString, str1, str2                                        ;!!Как передать через командную строку строки 
  local hProc  dd  ?
  local lpSystemInfo:SYSTEM_INFO 
  local lpBuffer:MEMORY_BASIC_INFORMATION
  local dwPID dd  ?
  local address  dd  ?
  local szstr1 dd  ?
  local szstr2 dd  ?
  local baseAddress dd  ?
  local endBaseAddress  dd  ?

  ;Получение размеров строки
  invoke  wcslen, [str1]
  mov [szstr1], eax     
  invoke  wcslen, [str2]
  mov [szstr2], eax
  

  ;Получение PID процесса
  invoke GetCurrentProcessId
  mov [dwPID],  eax
  
  ;Открытие процесса
  invoke  OpenProcess, PROCESS_ALL_ACCESS, FALSE, [dwPID]
  mov [hProc], eax 
  test  eax,  eax
  jnz @F  
  invoke  CloseHandle, [hProc]
  invoke MessageBox, NULL, OpenProcessError, Error, MB_ICONWARNING
  jmp .Exit
@@:   

  ;Получение стандартного размера страницы из системной инфйормации
  invoke  GetSystemInfo, addr lpSystemInfo 
  mov eax,  [lpSystemInfo.lpMinimumApplicationAddress]
  mov [address], eax      
  
.start_cycle:
  mov eax,  [lpSystemInfo.lpMaximumApplicationAddress]
  cmp [address],  eax
  ja  .Exit
  
  ;Получение информации о странице   
  invoke  VirtualQueryEx, [hProc], [address], addr  lpBuffer, 28              ;!!!Задать размер через sizeof  
  test  eax,  eax
  jnz @F  
  invoke  CloseHandle, [hProc]
  invoke MessageBox, NULL, VirtualQueryExError, Error, MB_ICONWARNING
  jmp .Exit
@@: 
  
  ;Поиск строки  
  
  cmp [lpBuffer.AllocationProtect], PAGE_EXECUTE_WRITECOPY
  jne .end_search_string
  cmp [lpBuffer.State], MEM_COMMIT     
  jne .end_search_string                             
  cmp [lpBuffer.Type], MEM_IMAGE     
  jne .end_search_string
  
  ;Замена строки
  mov eax,  [lpBuffer.BaseAddress]
  mov [baseAddress],  eax
  mov [endBaseAddress], eax
  mov eax, [lpBuffer.RegionSize] 
  add [endBaseAddress], eax
  mov eax,  [szstr1]
  imul  eax,  eax,  2
  add eax,  1
  sub [endBaseAddress], eax
  
.start_rep:
  mov eax,  [endBaseAddress]   
  cmp [baseAddress],  eax
  ja  .end_rep
  invoke  wcscmp, [str1], [baseAddress]
  add esp,  8
  test  eax,  eax
  jnz @f
  mov eax,  [szstr2]
  imul  eax,  eax,  2
  add eax,  1
  invoke  WriteProcessMemory, [hProc], [baseAddress], [str2], eax, NULL  
@@:
  add [baseAddress],  1 
  jmp .start_rep
.end_rep: 
  
.end_search_string:
  
  mov eax,  [lpBuffer.RegionSize]
  add [address], eax
  jmp .start_cycle
  
.Exit:
  ret
endp

section '.data' data readable writeable   
  
  srcString du  'Source string', 0
  newString du  'New string', 0
           
  Error db  'Error', 0
                                               
  OpenProcessError  db  'OpenProcess Faild', 0  
                            
  VirtualQueryExError  db  'VirtualQueryEx Faild', 0 

section '.idata' import data readable writeable

  library kernel, 'KERNEL32.DLL',\
    user, 'USER32.DLL',\
    msvcrt, 'MSVCRT.DLL' 
               
  include 'api\kernel32.inc'
  include 'api\user32.inc' 
  
  import kernel,\ 
    LocalFree, 'LocalFree',\
    GetCurrentProcess, 'GetCurrentProcess',\      ;странности с подключение api     
    GetSystemInfo, 'GetSystemInfo',\    
    FormatMessageA, 'FormatMessageA',\
    OpenProcess,  'OpenProcess',\
    CloseHandle,  'CloseHandle',\ 
    GetCurrentProcessId, 'GetCurrentProcessId',\
    VirtualQueryEx, 'VirtualQueryEx',\
    WriteProcessMemory, 'WriteProcessMemory'     
  
  import user,\ 
    MessageBoxA, 'MessageBoxA'  
    
  import msvcrt,\
    wcslen, 'wcslen',\
    wcscmp, 'wcscmp' 

section '.edata' export data readable

export 'ERRORMSG.DLL',\
    RaplaceString, 'RaplaceString'

section '.reloc' fixups data readable discardable  