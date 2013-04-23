module LLVM.FFI.GenericValue
       (GenericValue()
       ,newGenericValue
       ,genericValueGetDouble
       ,genericValueSetDouble
       ,genericValueGetFloat
       ,genericValueSetFloat
       ,genericValueGetPointer
       ,genericValueSetPointer
       ,genericValueGetInt
       ,genericValueSetInt
#if HS_LLVM_VERSION>=302
       ,genericValueGetAggregate
       ,genericValueSetAggregate
#endif
       ) where

import LLVM.FFI.Interface