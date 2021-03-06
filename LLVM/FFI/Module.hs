module LLVM.FFI.Module 
       (Module()
        -- * Public Member Functions
        -- ** Constructors
       ,newModule
       ,deleteModule
        -- ** Module Level Accessors
       ,moduleGetContext
        -- ** Function Accessors
       ,moduleGetFunction
       ,moduleGetFunctionString
       ,moduleGetOrInsertFunction
        -- ** Utility functions for printing and dumping Module objects
       ,moduleDump
        -- * Generic Value Accessors
       ,moduleGetNamedValue
       ,moduleGetTypeByName
        -- * Named Metadata Accessors
       ,moduleGetNamedMetadata
       ,moduleGetOrInsertNamedMetadata
       ,moduleEraseNamedMetadata
        -- * Globals list, functions list, and symbol table
       ,moduleGetGlobalList
       ,moduleGetFunctionList
#if HS_LLVM_VERSION >= 302
       ,moduleGetNamedMDList
#endif
       ,parseIR
       ,writeBitCodeToFile
       ) where

import LLVM.FFI.Interface
import LLVM.FFI.StringRef
#if HS_LLVM_VERSION>=305
import LLVM.FFI.CPP.UniquePtr
#endif

import Foreign
import Foreign.C

#include "Helper.h"

writeBitCodeToFile :: Ptr Module -> String -> IO Bool
writeBitCodeToFile md name = withCString name
                             $ \str -> do
                               res <- writeBitCodeToFile_ md str
                               return $ res==0

moduleGetFunctionString :: Ptr Module -> String -> IO (Ptr Function)
moduleGetFunctionString md name
  = withStringRef name (moduleGetFunction md)

foreign import capi "extra.h writeBitCodeToFile"
  writeBitCodeToFile_ :: Ptr Module -> CString -> IO CInt

#if HS_LLVM_VERSION>=305
SPECIALIZE_UNIQUEPTR(Module,capi)
#endif
