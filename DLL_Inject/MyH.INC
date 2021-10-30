
; MyH.inc structures and constants

struct PROCESSENTRY32
  dwSize	dw	?    
  cntUsage	dw	?     
  th32ProcessID	dw	?  
  th32DefaultHeapID	dd	?  
  th32ModuleID	dw	?  
  cntThreads	dw	?  
  th32ParentProcessID	dw	?  
  pcPriClassBase	dd	?  
  dwFlags	dw	?      
  szExeFile	dd	?
ends

