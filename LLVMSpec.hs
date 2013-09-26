module LLVMSpec where

import Data.Version
import Generator
import CPPType

llvm3_3 :: Version
llvm3_3 = Version { versionBranch = [3,3]
                  , versionTags = []
                  }

llvm3_2 :: Version
llvm3_2 = Version { versionBranch = [3,2]
                  , versionTags = []
                  }

llvm3_1 :: Version
llvm3_1 = Version { versionBranch = [3,1]
                  , versionTags = []
                  }

llvm3_0 :: Version
llvm3_0 = Version { versionBranch = [3,0]
                  , versionTags = []
                  }

llvm2_9 :: Version
llvm2_9 = Version { versionBranch = [2,9]
                  , versionTags = []
                  }

irInclude :: Version -> String -> String
irInclude ver hdr = if ver >= llvm3_3
                    then "llvm/IR/"++hdr
                    else "llvm/"++hdr

llvm :: Version -> [Spec]
llvm version
  = [Spec { specHeader = "llvm/ADT/StringRef.h"
          , specNS = llvmNS
          , specName = "StringRef"
          , specTemplateArgs = []
          , specType = ClassSpec
                       [(Constructor { ftConArgs = [] },"newStringRefEmpty")
                       ,(Constructor { ftConArgs = [(False,constT cstring)] },"newStringRef_")
                       ,(Destructor False,"deleteStringRef")
                       ,(memberFun { ftReturnType = constT cstring
                                   , ftName = "data"
                                   },"stringRefData_")
                       ,(memberFun { ftReturnType = normalT size_t
                                   , ftName = "size"
                                   },"stringRefSize_")
                       ]
          }
    ]++
    [Spec { specHeader = "llvm/ADT/OwningPtr.h"
          , specNS = llvmNS
          , specName = "OwningPtr"
          , specTemplateArgs = [rtp]
          , specType = ClassSpec
                       [(Constructor { ftConArgs = [(False,toPtr rtp)] },"newOwningPtr"++tp)
                       ,(Destructor False,"deleteOwningPtr"++tp)
                       ,(memberFun { ftReturnType = toPtr rtp
                                   , ftName = "take"
                                   },"takeOwningPtr"++tp)]
          }
     | tp <- ["MemoryBuffer"]
    , let rtp = Type [] (NamedType llvmNS tp [])
    ]++
    (if version>=llvm2_9
     then [Spec { specHeader = "llvm/ADT/ArrayRef.h"
                , specNS = llvmNS
                , specName = "ArrayRef"
                , specTemplateArgs = [rtp]
                , specType = ClassSpec $
                             [(Constructor { ftConArgs = [] },"newArrayRefEmpty"++tp)
                             ,(Constructor { ftConArgs = [(False,toPtr rtp)
                                                         ,(False,normalT size_t)] },"newArrayRef"++tp)
                             ,(Destructor False,"deleteArrayRef"++tp)
                             ,(memberFun { ftReturnType = normalT size_t
                                         , ftName = "size"
                                         },"arrayRefSize"++tp)]++
                             (if version>=llvm3_0
                              then [(memberFun { ftReturnType = normalT bool
                                               , ftName = "equals"
                                               , ftArgs = [(False,normalT $ NamedType llvmNS "ArrayRef" [rtp])]
                                               },"arrayRefEquals"++tp)]
                              else [])++
                             [(memberFun { ftReturnType = toConstRef rtp
                                         , ftName = "operator[]"
                                         , ftArgs = [(False,normalT size_t)]
                                         },"arrayRefIndex"++tp)
                             ]
                }
           | (tp,rtp) <- [("Type",normalT $ ptr $ llvmType "Type")
                        ,("CChar",constT $ ptr char)]
          ]
     else [])++
    concat [[Spec { specHeader = "llvm/ADT/ilist.h"
                  , specNS = llvmNS
                  , specName = "iplist"
                  , specTemplateArgs = [rtp]
                  , specType = ClassSpec
                               [(Constructor { ftConArgs = [] },"new"++tp++"List")
                               ,(Destructor False,"delete"++tp++"List")
                               ,(memberFun { ftReturnType = normalT size_t
                                           , ftName = "size"
                                           },"list"++tp++"Size")
                               ,(memberFun { ftReturnType = normalT $ NamedType llvmNS "ilist_iterator" [rtp]
                                           , ftName = "begin"
                                           },"list"++tp++"Begin")
                               ,(memberFun { ftReturnType = normalT $ NamedType llvmNS "ilist_iterator" [rtp]
                                           , ftName = "end"
                                           },"list"++tp++"End")
                               ]
                  }
            ,Spec { specHeader = "llvm/ADT/ilist.h"
                  , specNS = llvmNS
                  , specName = "ilist_iterator"
                  , specTemplateArgs = [rtp]
                  , specType = ClassSpec
                               [(memberFun { ftReturnType = toPtr rtp
                                           , ftName = "operator->"
                                           },"listIterator"++tp++"Deref")
                               ,(memberFun { ftReturnType = normalT $ RefType $ 
                                                            NamedType llvmNS "ilist_iterator" [rtp]
                                           , ftName = "operator++"
                                           },"listIterator"++tp++"Next")
                               ,(memberFun { ftReturnType = normalT bool
                                           , ftName = "operator=="
                                           , ftArgs = [(False,constT $ RefType $ 
                                                             NamedType llvmNS "ilist_iterator" [rtp])] 
                                           },"listIterator"++tp++"Eq")
                               ,(memberFun { ftReturnType = normalT bool
                                           , ftName = "operator!="
                                           , ftArgs = [(False,constT $ RefType $ 
                                                             NamedType llvmNS "ilist_iterator" [rtp])] 
                                           },"listIterator"++tp++"NEq")]
                  }
            ]
            | tp <- ["Function","Instruction","BasicBlock","GlobalVariable","Argument"]
           , let rtp = Type [] (NamedType llvmNS tp [])
           ]++
    concat [[Spec { specHeader = "llvm/ADT/SetVector.h"
                  , specNS = llvmNS
                  , specName = "SetVector"
                  , specTemplateArgs = [rtp]
                  , specType = ClassSpec
                               [(memberFun { ftReturnType = normalT bool
                                           , ftName = "empty"
                                           },"setVector"++tp++"Empty")
                               ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" []
                                           , ftName = "begin"
                                           },"setVector"++tp++"Begin")
                               ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" []
                                           , ftName = "end"
                                           },"setVector"++tp++"End")
                               ]
                  }
            ,Spec { specHeader = "vector"
                  , specNS = [ClassName "std" []]
                  , specName = "vector"
                  , specTemplateArgs = [rtp]
                  , specType = ClassSpec
                               [(memberFun { ftReturnType = constT $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" []
                                           , ftName = "begin"
                                           , ftOverloaded = True
                                           },"vector"++tp++"Begin")
                               ,(memberFun { ftReturnType = constT $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" []
                                           , ftName = "end"
                                           , ftOverloaded = True
                                           },"vector"++tp++"End")]
                  }
            ,Spec { specHeader = "vector"
                  , specNS = [ClassName "std" [],ClassName "vector" [rtp]]
                  , specName = "const_iterator"
                  , specTemplateArgs = []
                  , specType = ClassSpec
                               [(memberFun { ftReturnType = rtp
                                           , ftName = "operator*"
                                           },"vectorIterator"++tp++"Deref")
                               ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" []
                                           , ftName = "operator++"
                                           },"vectorIterator"++tp++"Next")
                               ]
                  }
            ,Spec { specHeader = "vector"
                  , specNS = []
                  , specName = "operator=="
                  , specTemplateArgs = []
                  , specType = GlobalFunSpec { gfunReturnType = normalT bool
                                             , gfunArgs = [(False,constT $ ref $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" [])
                                                          ,(False,constT $ ref $ NamedType [ClassName "std" [],ClassName "vector" [rtp]] "const_iterator" [])]
                                             , gfunHSName = "vectorIterator"++tp++"Eq"
                                             }
                  }
            ]
            | (tp,rtp) <- [("Type",normalT $ ptr $ llvmType "Type")
                         ,("Loop",normalT $ ptr $ llvmType "Loop")
                         ,("BasicBlock",normalT $ ptr $ llvmType "BasicBlock")
                         ,("DominatorTree",normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType "BasicBlock"])]
           ]++
    [Spec { specHeader = "llvm/ADT/SmallVector.h"
          , specNS = llvmNS
          , specName = "SmallVector"
          , specTemplateArgs = [rtp,TypeInt 16]
          , specType = ClassSpec
                       [(Constructor [],"newSmallVector"++tp)
                       ,(Destructor False,"deleteSmallVector"++tp)
                       ,(memberFun { ftReturnType = normalT size_t
                                   , ftName = "size"
                                   , ftOverloaded = True
                                   },"smallVectorSize"++tp)
                       ,(memberFun { ftReturnType = toPtr rtp
                                   , ftName = "data"
                                   , ftOverloaded = True
                                   },"smallVectorData"++tp)]
          }
     | (tp,rtp) <- [("Loop",normalT $ ptr $ llvmType "Loop")
                  ,("Edge",normalT $ NamedType [ClassName "std" []] "pair" [normalT $ ptr $ llvmType "BasicBlock"
                                                                           ,normalT $ ptr $ llvmType "BasicBlock"])]
    ]++
    [Spec { specHeader = "utility"
          , specNS = [ClassName "std" []]
          , specName = "pair"
          , specTemplateArgs = [rtp1,rtp2]
          , specType = ClassSpec
                       [(Getter { ftGetType = rtp1
                                , ftGetVar = "first"
                                , ftGetStatic = False
                                },"pairFirst"++tp1++"_"++tp2)
                       ,(Getter { ftGetType = rtp2
                                , ftGetVar = "second"
                                , ftGetStatic = False
                                },"pairSecond"++tp1++"_"++tp2)
                       ,(SizeOf,"sizeofPair"++tp1++"_"++tp2)
                       ]
          }
     | (tp1,tp2) <- [("BasicBlock","BasicBlock")]
    , let rtp1 = normalT $ ptr $ llvmType tp1
          rtp2 = normalT $ ptr $ llvmType tp2 ]++
       [Spec { specHeader = "llvm/ADT/APFloat.h"
             , specNS = llvmNS
             , specName = "APFloat"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT double
                                      , ftName = "convertToDouble"
                                      },"apFloatConvertToDouble")]
             }
       ,Spec { specHeader = "llvm/ADT/APInt.h"
             , specNS = llvmNS
             , specName = "APInt"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [(False,normalT unsigned)
                                        ,(False,normalT uint64_t)
                                        ,(False,normalT bool)]
                           ,"newAPIntLimited")
                          ,if version>=llvm3_0
                           then (Constructor [(False,normalT unsigned)
                                             ,(False,normalT $ NamedType llvmNS "ArrayRef"
                                                        [normalT uint64_t])]
                                ,"newAPInt")
                           else (Constructor [(False,normalT unsigned)
                                             ,(False,normalT unsigned)
                                             ,(False,constT $ ptr $ uint64_t)]
                                ,"newAPInt")
                          ,(Constructor [(False,normalT unsigned)
                                        ,(False,normalT $ llvmType "StringRef")
                                        ,(False,normalT uint8_t)]
                           ,"newAPIntFromString")
                          ,(Destructor False,"deleteAPInt")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getBitWidth"
                                      },"apIntGetBitWidth")
                          ,(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getZExtValue"
                                      },"apIntGetZExtValue")
                          ,(memberFun { ftReturnType = normalT int64_t
                                      , ftName = "getSExtValue"
                                      },"apIntGetSExtValue")]
             }
       ,Spec { specHeader = "llvm/Support/DebugLoc.h"
             , specNS = llvmNS
             , specName = "DebugLoc"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(Constructor { ftConArgs = [] },"newDebugLoc")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "isUnknown"
                                      },"debugLocIsUnknown")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getLine"
                                      },"debugLocGetLine")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getCol"
                                      },"debugLocGetCol")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "MDNode" []
                                      , ftName = "getScope"
                                      , ftArgs = [(False,constT $ ref $ NamedType llvmNS "LLVMContext" [])]
                                      },"debugLocGetScope")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "MDNode" []
                                      , ftName = "getInlinedAt"
                                      , ftArgs = [(False,constT $ ref $ NamedType llvmNS "LLVMContext" [])]
                                      },"debugLocGetInlinedAt")]++
                          (if version>=llvm3_0
                           then [(memberFun { ftName = "dump" 
                                            , ftArgs = [(False,constT $ ref $ NamedType llvmNS "LLVMContext" [])]
                                            },"debugLocDump")]
                           else [])
             }
       ]++
       [Spec { specHeader = irInclude version "Type.h"
             , specNS = llvmNS
             , specName = "Type"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT void
                                      , ftName = "dump"
                                      , ftOverloaded = True
                                      },"typeDump_")
                          ,(memberFun { ftReturnType = normalT $ ref $ llvmType "LLVMContext"
                                      , ftName = "getContext"
                                      , ftOverloaded = True
                                      },"typeGetContext_")
                          ]++
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "is"++tp++"Ty"
                                      , ftOverloaded = True
                                      , ftPure = True
                                      },"is"++tp++"Ty_")
                           | tp <- ["Void"]++(if version>=llvm3_1
                                             then ["Half"]
                                             else [])++
                                  ["Float","Double","X86_FP80","FP128","PPC_FP128"
                                  ,"FloatingPoint"]++
                                  (if version>=llvm2_9
                                   then ["X86_MMX"]
                                   else [])++
                                  ["Label","Metadata"]
                          ]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "IntegerType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getBitWidth"
                                      },"getBitWidth_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "IntegerType" [] 
                                      , ftName = "get"
                                      , ftArgs = [(False,normalT $ RefType $ NamedType llvmNS "LLVMContext" [])
                                                 ,(False,normalT $ NamedType [] "unsigned" [])]
                                      , ftStatic = True
                                      },"getIntegerType_")]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "CompositeType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Type" []
                                      , ftName = "getTypeAtIndex"
                                      , ftArgs = [(False,normalT unsigned)]
                                      , ftOverloaded = True
                                      },"compositeTypeGetTypeAtIndex_")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "indexValid"
                                      , ftArgs = [(False,normalT unsigned)]
                                      , ftOverloaded = True
                                      },"compositeTypeIndexValid_")]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "SequentialType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Type" []
                                      , ftName = "getElementType"
                                      , ftOverloaded = True
                                      },"sequentialTypeGetElementType_")]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "ArrayType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getNumElements"
                                      },"arrayTypeGetNumElements_")]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "PointerType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getAddressSpace"
                                      },"pointerTypeGetAddressSpace_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "PointerType" []
                                      , ftName = "get"
                                      , ftArgs = [(True,normalT $ ptr $ NamedType llvmNS "Type" [])
                                                 ,(False,normalT unsigned)]
                                      , ftStatic = True
                                      },"pointerTypeGet_")]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "VectorType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumElements"
                                      },"vectorTypeGetNumElements_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "VectorType" []
                                      , ftName = "get"
                                      , ftArgs = [(True,normalT $ ptr $ NamedType llvmNS "Type" [])
                                                 ,(False,normalT unsigned)]
                                      , ftStatic = True
                                      },"vectorTypeGet_")
                          ]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "StructType"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isPacked"
                                      },"structTypeIsPacked")]++
                          (if version>=llvm3_0
                           then [(memberFun { ftReturnType = normalT bool
                                            , ftName = "hasName"
                                            },"structTypeHasName")
                                ,(memberFun { ftReturnType = normalT $ NamedType llvmNS "StringRef" []
                                            , ftName = "getName"
                                            },"structTypeGetName")]
                           else [])++
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumElements"
                                      },"structTypeGetNumElements_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Type" []
                                      , ftName = "getElementType"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"structTypeGetElementType_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "StructType"
                                      , ftName = "get"
                                      , ftArgs = [(False,normalT $ ref $ llvmType "LLVMContext")
                                                 ,(False,if version>=llvm3_0
                                                         then normalT $ NamedType llvmNS "ArrayRef" [normalT $ ptr $ llvmType "Type"]
                                                         else constT $ ref $ NamedType [ClassName "std" []] "vector" [constT $ ptr $ llvmType "Type"])
                                                 ,(False,normalT bool)]
                                      , ftStatic = True
                                      },"newStructType")
                          ]
             }
       ,Spec { specHeader = irInclude version "DerivedTypes.h"
             , specNS = llvmNS
             , specName = "FunctionType"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isVarArg"
                                      },"functionTypeIsVarArg")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumParams"
                                      },"functionTypeGetNumParams_")
                          ,(memberFun { ftReturnType = normalT (ptr $ NamedType llvmNS "Type" [])
                                      , ftName = "getParamType"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"functionTypeGetParamType_")
                          ,(memberFun { ftReturnType = normalT (ptr $ NamedType llvmNS "Type" [])
                                      , ftName = "getReturnType"
                                      },"functionTypeGetReturnType")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "FunctionType"
                                      , ftName = "get"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Type")
                                                 ,(False,if version>=llvm3_0
                                                         then normalT $ NamedType llvmNS "ArrayRef" [normalT $ ptr $ llvmType "Type"]
                                                         else constT $ ref $ NamedType [ClassName "std" []] "vector" [constT $ ptr $ llvmType "Type"])
                                                 ,(False,normalT bool)
                                                 ]
                                      , ftStatic = True
                                      },"newFunctionType_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Value.h"
             , specNS = llvmNS
             , specName = "Value"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Destructor True,"deleteValue_")
                          ,(memberFun { ftName = "dump"
                                      , ftOverloaded = True
                                      },"valueDump_")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "hasName"
                                      , ftOverloaded = True
                                      },"hasName_")
                          ,(memberFun { ftReturnType = normalT $ NamedType llvmNS "StringRef" []
                                      , ftName = "getName"
                                      , ftOverloaded = True
                                      },"getName_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Type" []
                                      , ftName = "getType"
                                      , ftOverloaded = True
                                      },"valueGetType_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Argument.h"
             , specNS = llvmNS
             , specName = "Argument"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Function"
                                      , ftName = "getParent"
                                      },"argumentGetParent")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getArgNo"
                                      },"argumentGetArgNo_")
                          ]
             }
       ,Spec { specHeader = irInclude version "BasicBlock.h"
             , specNS = llvmNS
             , specName = "BasicBlock"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Function" []
                                      , ftName = "getParent"
                                      },"basicBlockGetParent")
                          ,(memberFun { ftReturnType = normalT $ RefType $ NamedType llvmNS "iplist" 
                                                       [normalT $ NamedType llvmNS "Instruction" []]
                                      , ftName = "getInstList"
                                      },"getInstList")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "TerminatorInst" []
                                      , ftName = "getTerminator"
                                      },"getTerminator")
                          ]
             }
       ,Spec { specHeader = irInclude version "InlineAsm.h"
             , specNS = llvmNS
             , specName = "InlineAsm"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Metadata.h"
             , specNS = llvmNS
             , specName = "MDNode"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Metadata.h"
             , specNS = llvmNS
             , specName = "MDString"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = "llvm/CodeGen/PseudoSourceValue.h"
             , specNS = llvmNS
             , specName = "FixedStackPseudoSourceValue"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Constant.h"
             , specNS = llvmNS
             , specName = "Constant"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          (if version>=llvm3_1
                           then [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Constant"
                                            , ftName = "getAggregateElement"
                                            , ftArgs = [(False,normalT unsigned)]
                                            , ftOverloaded = True
                                            },"constantGetAggregateElement_")]
                           else [])++
                          (if version >= llvm3_3
                           then [(memberFun { ftReturnType = normalT bool
                                            , ftName = "isNullValue"
                                            },"isNullValue")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "canTrap"
                                            },"canTrap")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isThreadDependent"
                                            },"isThreadDependent")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isConstantUsed"
                                            },"isConstantUsed")
                                ]
                           else [])
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "BlockAddress"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantArray"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "ArrayType" []
                                      , ftName = "getType"
                                      },"constantArrayGetType")]
             }
       ]++
    (if version>=llvm3_1
     then [Spec { specHeader = irInclude version "Constants.h"
                , specNS = llvmNS
                , specName = "ConstantDataSequential"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "SequentialType" []
                                         , ftName = "getType"
                                         , ftOverloaded = True
                                         },"constantDataSequentialGetType")
                             ,(memberFun { ftReturnType = normalT unsigned
                                         , ftName = "getNumElements"
                                         , ftOverloaded = True
                                         },"constantDataSequentialGetNumElements_")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Constant"
                                         , ftName = "getElementAsConstant"
                                         , ftOverloaded = True
                                         , ftArgs = [(False,normalT unsigned)]
                                         },"constantDataSequentialGetElementAsConstant_")]
                }
          ,Spec { specHeader = irInclude version "Constants.h"
                , specNS = llvmNS
                , specName = "ConstantDataArray"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "ArrayType" []
                                         , ftName = "getType"
                                         },"constantDataArrayGetType")]
                }
          ,Spec { specHeader = irInclude version "Constants.h"
                , specNS = llvmNS
                , specName = "ConstantDataVector"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "VectorType" []
                                         , ftName = "getType"
                                         },"constantDataVectorGetType")]
                }]
     else [])++
       [Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantExpr"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getOpcode"
                                      },"constantExprGetOpcode_")]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantFP"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = constT $ ref $ llvmType "APFloat"
                                      , ftName = "getValueAPF"
                                      },"constantFPGetValueAPF")]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantInt"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "IntegerType" []
                                      , ftName = "getType"
                                      },"constantIntGetType")
                          ,(memberFun { ftReturnType = constT $ ref $ llvmType "APInt"
                                      , ftName = "getValue"
                                      },"constantIntGetValue")]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantPointerNull"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "PointerType" []
                                      , ftName = "getType"
                                      },"constantPointerNullGetType")]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantStruct"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "StructType" []
                                      , ftName = "getType"
                                      },"constantStructGetType")]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantVector"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "VectorType" []
                                      , ftName = "getType"
                                      },"constantVectorGetType")]
             }
       ,Spec { specHeader = irInclude version "GlobalValue.h"
             , specNS = llvmNS
             , specName = "GlobalValue"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "PointerType" []
                                      , ftName = "getType"
                                      , ftOverloaded = True
                                      },"globalValueGetType")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "isDeclaration"
                                      , ftOverloaded = True
                                      },"globalValueIsDeclaration_")]
             }
       ,Spec { specHeader = irInclude version "GlobalValue.h"
             , specNS = llvmNS
             , specName = "GlobalAlias"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "GlobalValue.h"
             , specNS = llvmNS
             , specName = "GlobalVariable"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isConstant"
                                      },"globalVariableIsConstant")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "isThreadLocal"
                                      },"globalVariableIsThreadLocal")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Constant"
                                      , ftName = "getInitializer"
                                      },"globalVariableGetInitializer")
                          ]
             }
       ,Spec { specHeader = irInclude version "Function.h"
             , specNS = llvmNS
             , specName = "Function"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isVarArg"
                                      },"functionIsVarArg")
                          ,(memberFun { ftReturnType = normalT $ RefType $ NamedType llvmNS "iplist" 
                                                       [normalT $ NamedType llvmNS "BasicBlock" []]
                                      , ftName = "getBasicBlockList"
                                      },"getBasicBlockList")
                          ,(memberFun { ftReturnType = normalT $ RefType $ NamedType llvmNS "BasicBlock" []
                                      , ftName = "getEntryBlock"
                                      },"getEntryBlock")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "FunctionType"
                                      , ftName = "getFunctionType"
                                      },"functionGetFunctionType")
                          ,(memberFun { ftReturnType = normalT $ ref $ NamedType llvmNS "iplist"
                                                       [normalT $ llvmType "Argument"]
                                      , ftName = "getArgumentList"
                                      },"functionGetArgumentList")
                          ]
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "UndefValue"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }]++
    (if version>=llvm2_9
     then [Spec { specHeader = "llvm/Support/system_error.h"
                , specNS = llvmNS
                , specName = "error_code"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(Destructor False,"deleteErrorCode")
                             ,(memberFun { ftReturnType = normalT (NamedType [] "int" [])
                                         , ftName = "value"
                                         },"errorCodeValue_")]
                }]
     else [])++
       [Spec { specHeader = "llvm/Support/MemoryBuffer.h"
             , specNS = llvmNS
             , specName = "MemoryBuffer"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Destructor False,"deleteMemoryBuffer")
                          ,(memberFun { ftReturnType = normalT size_t 
                                      , ftName = "getBufferSize"
                                      },"getBufferSize_")
                          ,if version>=llvm2_9
                           then (memberFun { ftReturnType = normalT (NamedType llvmNS "error_code" []) 
                                           , ftName = "getFile"
                                           , ftArgs = [(False,normalT (NamedType llvmNS "StringRef" []))
                                                      ,(False,normalT (RefType $ NamedType llvmNS "OwningPtr" 
                                                                                   [normalT (NamedType llvmNS "MemoryBuffer" [])]))
                                                      ,(False,normalT (NamedType [] "int64_t" []))]++
                                                      (if version>=llvm3_0
                                                       then [(False,normalT (NamedType [] "bool" []))]
                                                       else [])
                                           , ftStatic = True
                                           },"getFileMemoryBuffer")
                           else (memberFun { ftReturnType = normalT $ ptr $ llvmType "MemoryBuffer"
                                           , ftName = "getFile"
                                           , ftArgs = [(False,normalT (NamedType llvmNS "StringRef" []))]
                                           , ftStatic = True
                                           },"getFileMemoryBuffer")
                          ]
             }
       ,Spec { specHeader = "llvm/Support/SourceMgr.h"
             , specNS = llvmNS
             , specName = "SMDiagnostic"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [],"newSMDiagnostic")
                          ,(Destructor False,"deleteSMDiagnostic")
                          ,(memberFun { ftReturnType = normalT (NamedType llvmNS "StringRef" [])
                                      , ftName = "getFilename"
                                      },"getFilename")
                          ,(memberFun { ftReturnType = normalT (NamedType [] "int" [])
                                      , ftName = "getLineNo"
                                      },"getLineNo_")
                          ,(memberFun { ftReturnType = normalT (NamedType [] "int" [])
                                      , ftName = "getColumnNo"
                                      },"getColumnNo_")
                          ]
             }
       ,Spec { specHeader = irInclude version "LLVMContext.h"
             , specNS = llvmNS
             , specName = "LLVMContext"
             , specTemplateArgs = []
             , specType = ClassSpec [(Constructor [],"newLLVMContext")
                                    ,(Destructor False,"deleteLLVMContext")]
             }
       ,Spec { specHeader = irInclude version "LLVMContext.h"
             , specNS = llvmNS
             , specName = "getGlobalContext"
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ref $ llvmType "LLVMContext"
                                        , gfunArgs = []
                                        , gfunHSName = "getGlobalContext"
                                        }
             }
       ,Spec { specHeader = irInclude version "Module.h"
             , specNS = llvmNS
             , specName = "Module"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [(False,normalT $ NamedType llvmNS "StringRef" [])
                                        ,(False,normalT $ RefType $ NamedType llvmNS "LLVMContext" [])
                                        ],"newModule")
                          ,(Destructor False,"deleteModule")
                          ,(memberFun { ftReturnType = normalT void
                                      , ftName = "dump"
                                      },"moduleDump")
                          ,(memberFun { ftReturnType = normalT $ RefType $ NamedType llvmNS "iplist"
                                                       [normalT $ NamedType llvmNS "Function" []]
                                      , ftName = "getFunctionList"
                                      },"moduleGetFunctionList")
                          ,(memberFun { ftReturnType = normalT $ ref $ NamedType llvmNS "iplist"
                                                       [normalT $ NamedType llvmNS "GlobalVariable" []]
                                      , ftName = "getGlobalList"
                                      },"moduleGetGlobalList")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "StructType"
                                      , ftName = "getTypeByName"
                                      , ftArgs = [(False,normalT $ llvmType "StringRef")]
                                      },"moduleGetTypeByName")
                          ,(memberFun { ftReturnType = normalT $ ref $ llvmType "LLVMContext"
                                      , ftName = "getContext"
                                      },"moduleGetContext")
                          ]
             }
       ,Spec { specHeader = if version>=llvm3_3
                            then "llvm/IRReader/IRReader.h"
                            else "llvm/Support/IRReader.h"
             , specNS = []
             , specName = "llvm"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT (PtrType $ NamedType llvmNS "Module" []) 
                                      , ftName = "ParseIR"
                                      , ftArgs = [(False,normalT (PtrType $ NamedType llvmNS "MemoryBuffer" []))
                                                 ,(False,normalT (RefType $ NamedType llvmNS "SMDiagnostic" []))
                                                 ,(False,normalT (RefType $ NamedType llvmNS "LLVMContext" []))]
                                      , ftStatic = True
                                      },"parseIR")
                          {-,(memberFun { ftReturnType = normalT $ ptr $ llvmType "FunctionPass"
                                      , ftName = "createCFGSimplificationPass"
                                      , ftStatic = True
                                      },"createCFGSimplificationPass")-}
                          ]++
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isa"
                                      , ftTemplArgs = [to_tp,from_tp]
                                      , ftArgs = [(True,toConstRef from_tp)]
                                      , ftStatic = True
                                      , ftOverloaded = True
                                      , ftPure = True
                                      },"isA"++to)
                           | (to,from) <- [(to',"Value")
                                              | to' <- ["Value"
                                                      ,"Argument"
                                                      ,"BasicBlock"
                                                      ,"InlineAsm"
                                                      ,"MDNode"
                                                      ,"MDString"
                                                      ,"PseudoSourceValue"
                                                      ,"User"
                                                      ,"FixedStackPseudoSourceValue"
                                                      ,"Constant"
                                                      ,"BlockAddress"
                                                      ,"ConstantAggregateZero"
                                                      ,"ConstantArray"]++
                                                      (if version>=llvm3_1
                                                       then ["ConstantDataSequential"
                                                            ,"ConstantDataArray"
                                                            ,"ConstantDataVector"]
                                                       else [])++
                                                      ["ConstantExpr"
                                                      {-,"BinaryConstantExpr"
                                                        ,"CompareConstantExpr"
                                                        ,"ExtractElementConstantExpr"
                                                        ,"ExtractValueConstantExpr"
                                                        ,"GetElementPtrConstantExpr"
                                                        ,"InsertElementConstantExpr"
                                                        ,"InsertValueConstantExpr"
                                                        ,"SelectConstantExpr"
                                                        ,"ShuffleVectorConstantExpr"
                                                        ,"UnaryConstantExpr"-}
                                                      ,"ConstantFP"
                                                      ,"ConstantInt"
                                                      ,"ConstantPointerNull"
                                                      ,"ConstantStruct"
                                                      ,"ConstantVector"
                                                      ,"GlobalValue"
                                                      ,"Function"
                                                      ,"GlobalAlias"
                                                      ,"GlobalVariable"
                                                      ,"UndefValue"
                                                      ,"Instruction"]++
                                                      (if version>=llvm3_0
                                                       then ["AtomicCmpXchgInst"
                                                            ,"AtomicRMWInst"]
                                                       else [])++
                                                      ["BinaryOperator"
                                                      ,"CallInst"
                                                      ,"CmpInst"
                                                      ,"FCmpInst"
                                                      ,"ICmpInst"
                                                      ,"ExtractElementInst"]++
                                                      (if version>=llvm3_0
                                                       then ["FenceInst"]
                                                       else [])++
                                                      ["GetElementPtrInst"
                                                      ,"InsertElementInst"
                                                      ,"InsertValueInst"]++
                                                      (if version>=llvm3_0
                                                       then ["LandingPadInst"]
                                                       else [])++
                                                      ["PHINode"
                                                      ,"SelectInst"
                                                      ,"ShuffleVectorInst"
                                                      ,"StoreInst"
                                                      ,"TerminatorInst"
                                                      ,"BranchInst"
                                                      ,"IndirectBrInst"
                                                      ,"InvokeInst"]++
                                                      (if version>=llvm3_0
                                                       then ["ResumeInst"]
                                                       else [])++
                                                      ["ReturnInst"
                                                      ,"SwitchInst"
                                                      ,"UnreachableInst"
                                                      ,"UnaryInstruction"
                                                      ,"AllocaInst"
                                                      ,"CastInst"
                                                      ,"BitCastInst"
                                                      ,"FPExtInst"
                                                      ,"FPToSIInst"
                                                      ,"FPToUIInst"
                                                      ,"FPTruncInst"
                                                      ,"IntToPtrInst"
                                                      ,"PtrToIntInst"
                                                      ,"SExtInst"
                                                      ,"SIToFPInst"
                                                      ,"TruncInst"
                                                      ,"UIToFPInst"
                                                      ,"ZExtInst"
                                                      ,"ExtractValueInst"
                                                      ,"LoadInst"
                                                      ,"VAArgInst"
                                                      ,"Operator"
                                                      ]]++
                                         [(to',"Type") 
                                              | to' <- ["Type"
                                                      ,"CompositeType"
                                                      ,"SequentialType"
                                                      ,"ArrayType"
                                                      ,"PointerType"
                                                      ,"VectorType"
                                                      ,"StructType"
                                                      ,"FunctionType"
                                                      ,"IntegerType"]]
                          , let to_tp = normalT $ NamedType llvmNS to []
                                from_tp = normalT $ NamedType llvmNS from []
                          ]
             }
       ,Spec { specHeader = "llvm/CodeGen/PseudoSourceValue.h"
             , specNS = llvmNS
             , specName = "PseudoSourceValue"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Constants.h"
             , specNS = llvmNS
             , specName = "ConstantAggregateZero"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instruction.h"
             , specNS = llvmNS
             , specName = "Instruction"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "BasicBlock" []
                                      , ftName = "getParent"
                                      },"instructionGetParent")
                          ,(memberFun { ftReturnType = constT $ ref $ NamedType llvmNS "DebugLoc" []
                                      , ftName = "getDebugLoc"
                                      },"instructionGetDebugLoc")]
             }]++
    (if version>=llvm3_0
     then [Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "AtomicCmpXchgInst"
                , specTemplateArgs = []
                , specType = ClassSpec 
                             [(memberFun { ftReturnType = normalT bool
                                         , ftName = "isVolatile"
                                         },"atomicCmpXchgInstIsVolatile")
                             ,(memberFun { ftReturnType = normalT int
                                         , ftName = "getOrdering"
                                         },"atomicCmpXchgInstGetOrdering_")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getPointerOperand"
                                         },"atomicCmpXchgInstGetPointerOperand")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getCompareOperand"
                                         },"atomicCmpXchgInstGetCompareOperand")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getNewValOperand"
                                         },"atomicCmpXchgInstGetNewValOperand")
                             ,(Constructor [(True,normalT $ ptr $ llvmType "Value")
                                           ,(True,normalT $ ptr $ llvmType "Value")
                                           ,(True,normalT $ ptr $ llvmType "Value")
                                           ,(False,normalT $ EnumType llvmNS "AtomicOrdering")
                                           ,(False,normalT $ EnumType llvmNS "SynchronizationScope")
                                           ],"newAtomicCmpXchgInst_")]
                }
          ,Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "AtomicRMWInst"
                , specTemplateArgs = []
                , specType = ClassSpec 
                             [(memberFun { ftReturnType = normalT int
                                         , ftName = "getOperation"
                                         },"atomicRMWInstGetOperation_")
                             ,(memberFun { ftReturnType = normalT bool
                                         , ftName = "isVolatile"
                                         },"atomicRMWInstIsVolatile")
                             ,(memberFun { ftReturnType = normalT int
                                         , ftName = "getOrdering"
                                         },"atomicRMWInstGetOrdering_")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getPointerOperand"
                                         },"atomicRMWInstGetPointerOperand")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getValOperand"
                                         },"atomicRMWInstGetValOperand")
                             ,(Constructor [(False,normalT $ EnumType [ClassName "llvm" [],ClassName "AtomicRMWInst" []] "BinOp")
                                           ,(True,normalT $ ptr $ llvmType "Value")
                                           ,(True,normalT $ ptr $ llvmType "Value")
                                           ,(False,normalT $ EnumType llvmNS "AtomicOrdering")
                                           ,(False,normalT $ EnumType llvmNS "SynchronizationScope")
                                           ],"newAtomicRMWInst_")]
                }]
     else [])++
       [Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "BinaryOperator"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT int
                                      , ftName = "getOpcode"
                                      },"binOpGetOpCode_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BinaryOperator"
                                      , ftName = "Create"
                                      , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" [],ClassName "Instruction" []] "BinaryOps")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newBinaryOperator_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "CallInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isTailCall"
                                      },"callInstIsTailCall")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumArgOperands"
                                      },"callInstGetNumArgOperands_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getArgOperand"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"callInstGetArgOperand_")
                          ,(memberFun { ftReturnType = normalT int
                                      , ftName = "getCallingConv"
                                      },"callInstGetCallingConv_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getCalledValue"
                                      },"callInstGetCalledValue")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "CallInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,if version>=llvm3_0
                                                  then (False,normalT $ NamedType llvmNS "ArrayRef" [normalT $ ptr $ llvmType "Value"])
                                                  else (False,normalT $ ptr $ llvmType "Value")
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newCallInst_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "CmpInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT int
                                      , ftName = "getPredicate" 
                                      , ftOverloaded = True
                                      },"cmpInstGetPredicate_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "FCmpInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor
                            [(False,normalT $ EnumType [ClassName "llvm" []
                                                       ,ClassName "CmpInst" []] "Predicate")
                            ,(True,normalT $ ptr $ llvmType "Value")
                            ,(True,normalT $ ptr $ llvmType "Value")
                            ,(False,constT $ ref $ llvmType "Twine")
                            ],"newFCmpInst_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "ICmpInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor
                            [(False,normalT $ EnumType [ClassName "llvm" []
                                                       ,ClassName "CmpInst" []] "Predicate")
                            ,(True,normalT $ ptr $ llvmType "Value")
                            ,(True,normalT $ ptr $ llvmType "Value")
                            ,(False,constT $ ref $ llvmType "Twine")
                            ],"newICmpInst_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "ExtractElementInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getVectorOperand"
                                      },"extractElementInstGetVectorOperand")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getIndexOperand"
                                      },"extractElementInstGetIndexOperand")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "ExtractElementInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newExtractElementInst_")]
             }]++
    (if version>=llvm3_0
     then [Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "FenceInst"
                , specTemplateArgs = []
                , specType = ClassSpec 
                             [(memberFun { ftReturnType = normalT int
                                         , ftName = "getOrdering"
                                         },"fenceInstGetOrdering_")
                             ,(Constructor
                               [(False,normalT $ ref $ llvmType "LLVMContext")
                               ,(False,normalT $ EnumType llvmNS "AtomicOrdering")
                               ,(False,normalT $ EnumType llvmNS "SynchronizationScope")
                               ],"newFenceInst_")]
                }]
     else [])++
       [Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "GetElementPtrInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "PointerType" []
                                      , ftName = "getType"
                                      },"getElementPtrInstGetType")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "isInBounds"
                                      },"getElementPtrInstIsInBounds")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getPointerOperand"
                                      },"getElementPtrInstGetPointerOperand")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Use"
                                      , ftName = "idx_begin"
                                      },"getElementPtrInstIdxBegin")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Use"
                                      , ftName = "idx_end"
                                      },"getElementPtrInstIdxEnd")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumIndices"
                                      },"getElementPtrInstGetNumIndices_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "GetElementPtrInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,if version>=llvm3_0
                                                  then (False,normalT $ NamedType llvmNS "ArrayRef" [normalT $ ptr $ llvmType "Value"])
                                                  else (False,normalT $ ptr $ llvmType "Value")
                                                 ,(False,normalT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newGetElementPtrInst_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "InsertElementInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "VectorType" []
                                      , ftName = "getType"
                                      },"insertElementInstGetType")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "InsertElementInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newInsertElementInst_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "InsertValueInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "InsertValueInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,if version>=llvm3_0
                                                  then (False,normalT $ NamedType llvmNS "ArrayRef" [normalT unsigned])
                                                  else (False,normalT unsigned)
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newInsertValueInst_")]
             }]++
    (if version>=llvm3_0
     then [Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "LandingPadInst"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getPersonalityFn"
                                         },"landingPadInstGetPersonaliteFn")
                             ,(memberFun { ftReturnType = normalT bool
                                         , ftName = "isCleanup"
                                         },"landingPadInstIsCleanup")
                             ,(memberFun { ftReturnType = normalT unsigned
                                         , ftName = "getNumClauses"
                                         },"landingPadInstGetNumClauses_")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                         , ftName = "getClause"
                                         , ftArgs = [(False,normalT unsigned)]
                                         },"landingPadInstGetClause_")
                             ,(memberFun { ftReturnType = normalT bool
                                         , ftName = "isCatch"
                                         , ftArgs = [(False,normalT unsigned)]
                                         },"landingPadInstIsCatch_")
                             ,(memberFun { ftReturnType = normalT bool
                                         , ftName = "isFilter"
                                         , ftArgs = [(False,normalT unsigned)]
                                         },"landingPadInstIsFilter_")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "LandingPadInst"
                                         , ftName = "Create"
                                         , ftArgs = [(True,normalT $ ptr $ llvmType "Type")
                                                    ,(True,normalT $ ptr $ llvmType "Value")
                                                    ,(False,normalT unsigned)
                                                    ,(False,constT $ ref $ llvmType "Twine")]
                                         , ftStatic = True
                                         },"newLandingPadInst_")
                             ,(memberFun { ftName = "setCleanup"
                                         , ftArgs = [(False,normalT bool)]
                                         },"landingPadInstSetCleanup")
                             ,(memberFun { ftName = "addClause"
                                         , ftArgs = [(True,normalT $ ptr $ llvmType "Value")]
                                         },"landingPadInstAddClause_")
                             ]
                }]
     else [])++
       [Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "PHINode"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumIncomingValues"
                                      },"phiNodeGetNumIncomingValues_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getIncomingValue"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"phiNodeGetIncomingValue_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "BasicBlock" []
                                      , ftName = "getIncomingBlock"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"phiNodeGetIncomingBlock_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "PHINode"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]++
                                                 (if version>=llvm3_0
                                                  then [(False,normalT unsigned)]
                                                  else [])++
                                                 [(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newPhiNode_")
                          ,(memberFun { ftName = "addIncoming"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,(False,normalT $ ptr $ llvmType "BasicBlock")]
                                      },"phiNodeAddIncoming_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "SelectInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getCondition"
                                      },"selectInstGetCondition")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getTrueValue"
                                      },"selectInstGetTrueValue")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getFalseValue"
                                      },"selectInstGetFalseValue")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "SelectInst"
                                      , ftName = "Create"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(True,normalT $ ptr $ llvmType "Value")
                                                 ,(False,constT $ ref $ llvmType "Twine")]
                                      , ftStatic = True
                                      },"newSelectInst_")
                          ]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "ShuffleVectorInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "VectorType" []
                                      , ftName = "getType"
                                      },"shuffleVectorInstGetType")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "StoreInst"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isVolatile"
                                      },"storeInstIsVolatile")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getAlignment"
                                      },"storeInstGetAlignment_")]++
               (if version>=llvm3_0
                then [(memberFun { ftReturnType = normalT int
                                 , ftName = "getOrdering"
                                 },"storeInstGetOrdering_")]
                else [])++
               [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                           , ftName = "getValueOperand"
                           },"storeInstGetValueOperand")
               ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                           , ftName = "getPointerOperand"
                           },"storeInstGetPointerOperand")
               ]
             }
       ,Spec { specHeader = irInclude version "InstrTypes.h"
             , specNS = llvmNS
             , specName = "TerminatorInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumSuccessors"
                                      , ftOverloaded = True
                                      },"terminatorInstGetNumSuccessors_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BasicBlock"
                                      , ftName = "getSuccessor"
                                      , ftArgs = [(False,normalT unsigned)]
                                      , ftOverloaded = True
                                      },"terminatorInstGetSuccessor_")]
             }
       ,Spec { specHeader = irInclude version "InstrTypes.h"
             , specNS = llvmNS
             , specName = "BranchInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isConditional"
                                      },"branchInstIsConditional")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getCondition"
                                      },"branchInstGetCondition")]
             }
       ,Spec { specHeader = irInclude version "InstrTypes.h"
             , specNS = llvmNS
             , specName = "IndirectBrInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "InstrTypes.h"
             , specNS = llvmNS
             , specName = "InvokeInst"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumArgOperands"
                                      },"invokeInstGetNumArgOperands_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftArgs = [(False,normalT unsigned)]
                                      , ftName = "getArgOperand"
                                      },"invokeInstGetArgOperand_")
                          ,(memberFun { ftReturnType = normalT int
                                      , ftName = "getCallingConv"
                                      },"invokeInstGetCallingConv_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getCalledValue"
                                      },"invokeInstGetCalledValue")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BasicBlock"
                                      , ftName = "getNormalDest"
                                      },"invokeInstGetNormalDest")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BasicBlock"
                                      , ftName = "getUnwindDest"
                                      },"invokeInstGetUnwindDest")]++
                          (if version>=llvm3_0
                           then [(memberFun { ftReturnType = normalT $ ptr $ llvmType "LandingPadInst"
                                            , ftName = "getLandingPadInst"
                                            },"invokeInstGetLandingPadInst")]
                           else [])
             }]++
    (if version>=llvm3_0
     then [Spec { specHeader = irInclude version "InstrTypes.h"
                , specNS = llvmNS
                , specName = "ResumeInst"
                , specTemplateArgs = []
                , specType = ClassSpec []
                }]
     else [])++
       [Spec { specHeader = irInclude version "InstrTypes.h"
             , specNS = llvmNS
             , specName = "ReturnInst"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getReturnValue"
                                      },"returnInstGetReturnValue")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "SwitchInst"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getCondition"
                                      },"switchInstGetCondition")]++
                          (if version>=llvm3_1
                           then [(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" []
                                            , ftName = "case_begin"
                                            },"switchInstCaseBegin")
                                ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" []
                                            , ftName = "case_end"
                                            },"switchInstCaseEnd")
                                ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" []
                                            , ftName = "case_default"
                                            },"switchInstCaseDefault")]
                           else [])
             }]++
    (if version>=llvm3_1
     then [Spec { specHeader = irInclude version "InstrTypes.h"
                , specNS = [ClassName "llvm" [],ClassName "SwitchInst" []]
                , specName = "CaseIt"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" []
                                         , ftName = "operator++"
                                         },"caseItNext")
                             ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" []
                                         , ftName = "operator--"
                                         },"caseItPrev")
                             ,(memberFun { ftReturnType = normalT bool
                                         , ftName = "operator=="
                                         , ftArgs = [(False,constT $ ref $ NamedType [ClassName "llvm" [],ClassName "SwitchInst" []] "CaseIt" [])]
                                         },"caseItEq")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "ConstantInt"
                                         , ftName = "getCaseValue"
                                         },"caseItGetCaseValue")
                             ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BasicBlock"
                                         , ftName = "getCaseSuccessor"
                                         },"caseItGetCaseSuccessor")]
                }]
     else [])++
       [Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "UnreachableInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "UnaryInstruction"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "AllocaInst"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "PointerType" []
                                      , ftName = "getType"
                                      },"allocaInstGetType")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "isArrayAllocation"
                                      },"allocaInstIsArrayAllocation")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "getArraySize"
                                      },"allocaInstGetArraySize")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getAlignment"
                                      },"allocaInstGetAlignment_")]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "CastInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "BitCastInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "FPExtInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "FPToUIInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "FPTruncInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "IntToPtrInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "PtrToIntInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "SExtInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "SIToFPInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "TruncInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "UIToFPInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "ZExtInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "ExtractValueInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "LoadInst"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isVolatile"
                                      },"loadInstIsVolatile")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getAlignment"
                                      },"loadInstGetAlignment_")]++
               (if version>=llvm3_0
                then [(memberFun { ftReturnType = normalT int
                                 , ftName = "getOrdering"
                                 },"loadInstGetOrdering_")]
                else [])++
               [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                           , ftName = "getPointerOperand"
                           },"loadInstGetPointerOperand")
               ]
             }
       ,Spec { specHeader = irInclude version "Instructions.h"
             , specNS = llvmNS
             , specName = "VAArgInst"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "User.h"
             , specNS = llvmNS
             , specName = "User"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getNumOperands" 
                                      , ftOverloaded = True
                                      },"getNumOperands_")
                          ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "Value" []
                                      , ftName = "getOperand" 
                                      , ftArgs = [(False,normalT unsigned)]
                                      , ftOverloaded = True
                                      },"getOperand_")]
             }
       ,Spec { specHeader = irInclude version "Operator.h"
             , specNS = llvmNS
             , specName = "Operator"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = irInclude version "Use.h"
             , specNS = llvmNS
             , specName = "Use"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Value"
                                      , ftName = "get"
                                      },"useGet")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Use"
                                      , ftName = "getNext"
                                      },"useGetNext")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "User"
                                      , ftName = "getUser"
                                      },"useGetUser")]
               
             }
       ,Spec { specHeader = "llvm/PassManager.h"
             , specNS = llvmNS
             , specName = "PassManager"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [],"newPassManager")
                          ,(Destructor False,"deletePassManager")
                          ,(memberFun { ftReturnType = normalT void
                                      , ftName = "add"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Pass")]
                                      },"passManagerAdd_")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "run"
                                      , ftArgs = [(False,normalT $ ref $ llvmType "Module")]
                                      },"passManagerRun")
                          ]
             }
       ,Spec { specHeader = "llvm/PassManager.h"
             , specNS = llvmNS
             , specName = "FunctionPassManager"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [(False,normalT $ ptr $ llvmType "Module")],"newFunctionPassManager")
                          ,(Destructor False,"deleteFunctionPassManager")
                          ,(memberFun { ftReturnType = normalT void
                                      , ftName = "add"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Pass")]
                                      },"functionPassManagerAdd_")
                          ,(memberFun { ftReturnType = normalT bool
                                      , ftName = "run"
                                      , ftArgs = [(False,normalT $ ref $ llvmType "Function")]
                                      },"functionPassManagerRun")
                          ]
             }
       ,Spec { specHeader = "llvm/Pass.h"
             , specNS = llvmNS
             , specName = "Pass"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(Destructor True,"deletePass_")
                          ,(memberFun { ftReturnType = constT $ ptr $ llvmType "PassInfo"
                                      , ftName = "lookupPassInfo"
                                      , ftArgs = [(False,normalT $ llvmType "StringRef")]
                                      , ftStatic = True
                                      },"passLookupPassInfo")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "AnalysisResolver"
                                      , ftName = "getResolver"
                                      , ftOverloaded = True
                                      },"passGetResolver_")
                          ,(memberFun { ftReturnType = normalT $ ptr void
                                      , ftName = "getAdjustedAnalysisPointer"
                                      , ftArgs = [(False,constT $ ptr void)]
                                      , ftOverloaded = True
                                      },"passGetAdjustedAnalysisPointer_")
                          ,(memberFun { ftReturnType = normalT $ EnumType llvmNS "PassKind"
                                      , ftName = "getPassKind"
                                      , ftOverloaded = True
                                      },"passGetKind_")
                          ,(memberFun { ftReturnType = constT $ ptr char
                                      , ftName = "getPassName"
                                      , ftOverloaded = True
                                      },"passGetName_")
                          ,(memberFun { ftName = "dump"
                                      , ftOverloaded = True
                                      },"passDump_")
                          ]
             }
       ,Spec { specHeader = "llvm/Pass.h"
             , specNS = llvmNS
             , specName = "FunctionPass"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "runOnFunction"
                                      , ftArgs = [(False,normalT $ ref $ llvmType "Function")]
                                      , ftOverloaded = True
                                      },"functionPassRun_")]
             }
       ,Spec { specHeader = "llvm/Pass.h"
             , specNS = llvmNS
             , specName = "ModulePass"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "runOnModule"
                                      , ftArgs = [(False,normalT $ ref $ llvmType "Module")]
                                      , ftOverloaded = True
                                      },"modulePassRunOnModule_")
                          ]
             }
       ,Spec { specHeader = "llvm/Pass.h"
             , specNS = llvmNS
             , specName = "ImmutablePass"
             , specTemplateArgs = []
             , specType = ClassSpec []
             }
       ,Spec { specHeader = "llvm/Analysis/FindUsedTypes.h"
             , specNS = llvmNS
             , specName = "FindUsedTypes"
             , specTemplateArgs = []
             , specType = ClassSpec 
                          [(Constructor [],"newFindUsedTypes")
                          ,(Destructor False,"deleteFindUsedTypes")
                          ,(memberFun { ftReturnType = constT $ ref $ NamedType [ClassName "llvm" []] "SetVector" [normalT $ ptr $ llvmType "Type"]
                                      , ftName = "getTypes"
                                      },"findUsedTypesGetTypes")]
             }]++
    (if version>=llvm2_9
     then [Spec { specHeader = "llvm/Target/TargetLibraryInfo.h"
                , specNS = llvmNS
                , specName = "TargetLibraryInfo"
                , specTemplateArgs = []
                , specType = ClassSpec $
                             [(Constructor [],"newTargetLibraryInfo")
                             ,(Destructor False,"deleteTargetLibraryInfo")]++
                             (if version>=llvm3_3
                              then [(memberFun { ftReturnType = normalT bool
                                               , ftName = "getLibFunc"
                                               , ftArgs = [(False,normalT $ llvmType "StringRef")
                                                          ,(False,normalT $ ref $ EnumType [ClassName "llvm" [],ClassName "LibFunc" []] "Func")]
                                               },"targetLibraryInfoGetLibFunc_")]
                              else [])++
                             (if version>=llvm3_1
                              then [(memberFun { ftReturnType = normalT $ llvmType "StringRef"
                                               , ftName = "getName"
                                               , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" [],ClassName "LibFunc" []] "Func")]
                                               },"targetLibraryInfoGetName_")]
                              else [])++
                             [(memberFun { ftReturnType = normalT bool
                                         , ftName = "has"
                                         , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" [],ClassName "LibFunc" []] "Func")]
                                         },"targetLibraryInfoHas_")
                             ]
                }]
     else [])++
       (if version >= llvm3_2
        then [Spec { specHeader = irInclude version "DataLayout.h"
                   , specNS = llvmNS
                   , specName = "DataLayout"
                   , specTemplateArgs = []
                   , specType = ClassSpec
                                [(Constructor [(False,normalT $ llvmType "StringRef")],"newDataLayoutFromString")
                                ,(Constructor [(False,constT $ ptr $ llvmType "Module")],"newDataLayoutFromModule")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isLittleEndian"
                                            },"dataLayoutIsLittleEndian")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isBigEndian"
                                            },"dataLayoutIsBigEndian")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isLegalInteger"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutIsLegalInteger")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "exceedsNaturalStackAlignment"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutExceedsNaturalStackAlignment")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "fitsInLegalInteger"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutFitsInLegalInteger")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerABIAlignment"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutPointerABIAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerPrefAlignment"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutPointerPrefAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerSize"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutPointerSize")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeSizeInBits"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutTypeSizeInBits_")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeStoreSize"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutTypeStoreSize_")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeAllocSize"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutTypeAllocSize_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getABITypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutABITypeAlignment_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getABIIntegerTypeAlignment"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"dataLayoutABIIntegerTypeAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getCallFrameTypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutCallFrameTypeAlignment_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPrefTypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutPrefTypeAlignment_")
                                ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "IntegerType"
                                            , ftName = "getIntPtrType"
                                            , ftArgs = [(False,normalT $ ref $ llvmType "LLVMContext")
                                                       ,(False,normalT unsigned)]
                                            },"dataLayoutIntPtrType")
                                ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Type"
                                            , ftName = "getIntPtrType"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"dataLayoutIntPtrTypeForType_")
                                ,(memberFun { ftReturnType = constT $ ptr $ llvmType "StructLayout"
                                            , ftName = "getStructLayout"
                                            , ftArgs = [(False,normalT $ ptr $ llvmType "StructType")]
                                            },"dataLayoutStructLayout")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPreferredAlignment"
                                            , ftArgs = [(False,normalT $ ptr $ llvmType "GlobalVariable")]
                                            },"dataLayoutPreferedAlignment")]
                   }]
        else [Spec { specHeader = "llvm/Target/TargetData.h"
                   , specNS = llvmNS
                   , specName = "TargetData"
                   , specTemplateArgs = []
                   , specType = ClassSpec $
                                [(Constructor [(False,normalT $ llvmType "StringRef")],"newTargetDataFromString")
                                ,(Constructor [(False,constT $ ptr $ llvmType "Module")],"newTargetDataFromModule")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isLittleEndian"
                                            },"targetDataIsLittleEndian")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isBigEndian"
                                            },"targetDataIsBigEndian")
                                ,(memberFun { ftReturnType = normalT bool
                                            , ftName = "isLegalInteger"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"targetDataIsLegalInteger")]++
                                (if version>=llvm3_0
                                 then [(memberFun { ftReturnType = normalT bool
                                                  , ftName = "exceedsNaturalStackAlignment"
                                                  , ftArgs = [(False,normalT unsigned)]
                                                  },"targetDataExceedsNaturalStackAlignment")
                                      ,(memberFun { ftReturnType = normalT bool
                                                  , ftName = "fitsInLegalInteger"
                                                  , ftArgs = [(False,normalT unsigned)]
                                                  },"targetDataFitsInLegalInteger")]
                                 else [])++
                                [(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerABIAlignment"
                                            },"targetDataPointerABIAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerPrefAlignment"
                                            },"targetDataPointerPrefAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPointerSize"
                                            },"targetDataPointerSize")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeSizeInBits"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataTypeSizeInBits_")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeStoreSize"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataTypeStoreSize_")
                                ,(memberFun { ftReturnType = normalT uint64_t
                                            , ftName = "getTypeAllocSize"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataTypeAllocSize_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getABITypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataABITypeAlignment_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getABIIntegerTypeAlignment"
                                            , ftArgs = [(False,normalT unsigned)]
                                            },"targetDataABIIntegerTypeAlignment")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getCallFrameTypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataCallFrameTypeAlignment_")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPrefTypeAlignment"
                                            , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                            },"targetDataPrefTypeAlignment_")
                                ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "IntegerType"
                                            , ftName = "getIntPtrType"
                                            , ftArgs = [(False,normalT $ ref $ llvmType "LLVMContext")]
                                            },"targetDataIntPtrType")
                                ,(memberFun { ftReturnType = constT $ ptr $ llvmType "StructLayout"
                                            , ftName = "getStructLayout"
                                            , ftArgs = [(False,normalT $ ptr $ llvmType "StructType")]
                                            },"targetDataStructLayout")
                                ,(memberFun { ftReturnType = normalT unsigned
                                            , ftName = "getPreferredAlignment"
                                            , ftArgs = [(False,normalT $ ptr $ llvmType "GlobalVariable")]
                                            },"targetDataPreferedAlignment")]
                   }])++
       [Spec { specHeader = if version >= llvm3_2
                            then irInclude version "DataLayout.h"
                            else "llvm/Target/TargetData.h"
             , specNS = llvmNS
             , specName = "StructLayout"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getSizeInBytes"
                                      },"structLayoutSizeInBytes")
                          ,(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getSizeInBits"
                                      },"structLayoutSizeInBits")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getAlignment"
                                      },"structLayoutAlignment")
                          ,(memberFun { ftReturnType = normalT unsigned
                                      , ftName = "getElementContainingOffset"
                                      , ftArgs = [(False,normalT uint64_t)]
                                      },"structLayoutElementContainingOffset")
                          ,(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getElementOffset"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"structLayoutElementOffset")
                          ,(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getElementOffsetInBits"
                                      , ftArgs = [(False,normalT unsigned)]
                                      },"structLayoutElementOffsetInBits")]
             }
       ,Spec { specHeader = "llvm/PassSupport.h"
             , specNS = llvmNS
             , specName = "PassInfo"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Destructor False,"deletePassInfo")
                          ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Pass"
                                      , ftName = "createPass"
                                      },"passInfoCreatePass")
                          ,(memberFun { ftReturnType = constT $ ptr $ char
                                      , ftName = "getPassName"
                                      },"passInfoGetPassName_")
                          ,(memberFun { ftReturnType = constT $ ptr $ char
                                      , ftName = "getPassArgument"
                                      },"passInfoGetPassArgument_")
                          ]
             }
       ,Spec { specHeader = "llvm/Analysis/LoopInfo.h"
             , specNS = llvmNS
             , specName = "LoopInfo"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [],"newLoopInfo")
                          ,(memberFun { ftReturnType = normalT $ ref $ NamedType llvmNS "LoopInfoBase" 
                                                       [normalT $ llvmType "BasicBlock"
                                                       ,normalT $ llvmType "Loop"]
                                      , ftName = "getBase"
                                      },"loopInfoGetBase")
                          ]
             }
       ]++
    (if version>=llvm3_0
     then [Spec { specHeader = "llvm/Transforms/IPO/PassManagerBuilder.h"
                , specNS = llvmNS
                , specName = "PassManagerBuilder"
                , specTemplateArgs = []
                , specType = ClassSpec $
                             [(Constructor [],"newPassManagerBuilder")
                             ,(Destructor False,"deletePassManagerBuilder")
                             ,(memberFun { ftName = "populateFunctionPassManager"
                                         , ftArgs = [(False,normalT $ ref $ llvmType "FunctionPassManager")
                                                    ]
                                         },"populateFunctionPassManager")
                             ,(Setter { ftSetVar = "OptLevel"
                                      , ftSetType = normalT unsigned
                                      },"setPassManagerBuilderOptLevel")
                             ,(Setter { ftSetVar = "SizeLevel"
                                      , ftSetType = normalT unsigned
                                      },"setPassManagerBuilderSizeLevel")
                             ,(Setter { ftSetVar = "Inliner"
                                      , ftSetType = normalT $ ptr $ llvmType "Pass"
                                      },"setPassManagerBuilderInliner")
                             ,(Setter { ftSetVar = "DisableSimplifyLibCalls"
                                      , ftSetType = normalT bool
                                      },"setPassManagerBuilderDisableSimplifyLibCalls")
                             ,(Setter { ftSetVar = "DisableUnitAtATime"
                                      , ftSetType = normalT bool
                                      },"setPassManagerBuilderDisableUnitAtATime")
                             ,(Setter { ftSetVar = "DisableUnrollLoops"
                                      , ftSetType = normalT bool
                                      },"setPassManagerBuilderDisableUnrollLoops")]++
                             (if version>=llvm3_1
                              then (if version>=llvm3_3
                                    then [(Setter { ftSetVar = "BBVectorize"
                                                  , ftSetType = normalT bool
                                                  },"setPassManagerBuilderBBVectorize")
                                         ,(Setter { ftSetVar = "SLPVectorize"
                                                  , ftSetType = normalT bool
                                                  },"setPassManagerBuilderSLPVectorize")]
                                    else [(Setter { ftSetVar = "Vectorize"
                                                  , ftSetType = normalT bool
                                                  },"setPassManagerBuilderVectorize")])++
                                   [(Setter { ftSetVar = "LoopVectorize"
                                            , ftSetType = normalT bool
                                            },"setPassManagerBuilderLoopVectorize")]
                              else [])
                }]
     else [])++
       [Spec { specHeader = "llvm/Transforms/Scalar.h"
             , specNS = llvmNS
             , specName = f
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ptr $ llvmType "Pass"
                                        , gfunArgs = []
                                        , gfunHSName = f
                                        }
             } | f <- ["createCFGSimplificationPass"
                     ,"createConstantPropagationPass"
                     ,"createDemoteRegisterToMemoryPass"
                     ,"createGVNPass"
                     ,"createInstructionCombiningPass"
                     ,"createPromoteMemoryToRegisterPass"
                     ,"createReassociatePass"
                     ,"createAggressiveDCEPass"
                     ,"createDeadStoreEliminationPass"
                     ,"createIndVarSimplifyPass"
                     ,"createJumpThreadingPass"
                     ,"createLICMPass"
                     ,"createLoopDeletionPass"
                     ,"createLoopRotatePass"
                     ,"createLoopSimplifyPass"
                     ,"createLoopStrengthReducePass"
                     ,"createLoopUnrollPass"
                     ,"createLoopUnswitchPass"
                     ,"createMemCpyOptPass"
                     ,"createSCCPPass"
                     ,"createScalarReplAggregatesPass"
                     ,"createSimplifyLibCallsPass"
                     ,"createTailCallEliminationPass"
                     ]
       ]++
       [Spec { specHeader = "llvm/Transforms/IPO.h"
             , specNS = llvmNS
             , specName = f
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ptr $ llvmType p
                                        , gfunArgs = fmap (\x -> (False,x)) a
                                        , gfunHSName = f
                                        }
             } | (p,f,a) <- [("ModulePass","createStripSymbolsPass",[normalT bool])
                           ,("ModulePass","createStripNonDebugSymbolsPass",[])
                           ,("ModulePass","createStripDebugDeclarePass",[])
                           ,("ModulePass","createStripDeadDebugInfoPass",[])
                           ,("ModulePass","createConstantMergePass",[])
                           ,("ModulePass","createGlobalOptimizerPass",[])
                           ,("ModulePass","createGlobalDCEPass",[])
                           ,("Pass","createFunctionInliningPass",[normalT int])
                           ,("Pass","createAlwaysInlinerPass",if version>=llvm3_1
                                                              then [normalT bool]
                                                              else [])
                           ,("Pass","createPruneEHPass",[])
                           ,("ModulePass","createInternalizePass",[if version>=llvm3_0
                                                                   then normalT $ NamedType llvmNS "ArrayRef" [constT $ ptr $ char]
                                                                   else constT $ NamedType [ClassName "std" []] "vector" [constT $ ptr char]])
                           ,("ModulePass","createDeadArgEliminationPass",[])
                           ,("ModulePass","createDeadArgHackingPass",[])
                           ,("Pass","createArgumentPromotionPass",[normalT unsigned])
                           ,("ModulePass","createIPConstantPropagationPass",[])
                           ,("ModulePass","createIPSCCPPass",[])
                           ,("Pass","createLoopExtractorPass",[])
                           ,("Pass","createSingleLoopExtractorPass",[])
                           ,("ModulePass","createBlockExtractorPass",[])
                           ,("ModulePass","createStripDeadPrototypesPass",[])
                           ,("Pass","createFunctionAttrsPass",[])
                           ,("ModulePass","createMergeFunctionsPass",[])
                           ,("ModulePass","createPartialInliningPass",[])]++
        (if version>=llvm3_3
         then [("ModulePass","createMetaRenamerPass",[])
              ,("ModulePass","createBarrierNoopPass",[])]
         else [])
       ]++
       [Spec { specHeader = "llvm/Analysis/Verifier.h"
             , specNS = llvmNS
             , specName = "createVerifierPass"
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ptr $ llvmType "FunctionPass"
                                        , gfunArgs = []
                                        , gfunHSName = "createVerifierPass"
                                        }
             }
       ,Spec { specHeader = "llvm/Support/raw_ostream.h"
             , specNS = llvmNS
             , specName = "raw_ostream"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Destructor True,"deleteOStream_")
                          ]
             }
       ,Spec { specHeader = "llvm/Support/raw_ostream.h"
             , specNS = llvmNS
             , specName = "raw_fd_ostream"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [(False,normalT int),(False,normalT bool),(False,normalT bool)],"newFDOStream_")
                          ,(Destructor False,"deleteFDOStream")]
             }
       ,Spec { specHeader = "llvm/Analysis/AliasAnalysis.h"
             , specNS = llvmNS
             , specName = "AliasAnalysis"
             , specTemplateArgs = []
             , specType = ClassSpec $
                          [(Constructor [],"newAliasAnalysis")
                          ,(Destructor True,"deleteAliasAnalysis_")]++
                          (if version>=llvm3_3
                           then [(memberFun { ftReturnType = constT $ ptr $ llvmType "TargetLibraryInfo"
                                            , ftName = "getTargetLibraryInfo"
                                            , ftOverloaded = True
                                            },"aliasAnalysisGetTargetLibraryInfo_")]
                           else [])++
                          [(memberFun { ftReturnType = normalT uint64_t
                                      , ftName = "getTypeStoreSize"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Type")]
                                      , ftOverloaded = True
                                      },"aliasAnalysisGetTypeStoreSize_")]++
                          (if version>=llvm2_9
                           then [(memberFun { ftReturnType = normalT $ NamedType [ClassName "llvm" [],ClassName "AliasAnalysis" []] "Location" []
                                            , ftName = "getLocation"
                                            , ftArgs = [(False,constT $ ptr $ llvmType (inst++"Inst"))]
                                            , ftOverloaded = True
                                            },"aliasAnalysisGetLocation"++inst++"_")
                                 | inst <- ["Load","Store","VAArg"]++(if version>=llvm3_0
                                                                     then ["AtomicCmpXchg","AtomicRMW"]
                                                                     else [])]
                           else [])++
                          [(memberFun { ftReturnType = normalT $ EnumType [ClassName "llvm" [],ClassName "AliasAnalysis" []] "AliasResult"
                                      , ftName = "alias"
                                      , ftArgs = if version>=llvm2_9
                                                 then [(False,constT $ ref $ NamedType [ClassName "llvm" [],ClassName "AliasAnalysis" []] "Location" [])
                                                      ,(False,constT $ ref $ NamedType [ClassName "llvm" [],ClassName "AliasAnalysis" []] "Location" [])]
                                                 else [(False,constT $ ptr $ llvmType "Value")
                                                      ,(False,normalT unsigned)
                                                      ,(False,constT $ ptr $ llvmType "Value")
                                                      ,(False,normalT unsigned)]
                                      , ftOverloaded = True
                                      },"aliasAnalysisAlias_")
                          ]
             }]++
    (if version>=llvm2_9
     then [Spec { specHeader = "llvm/Analysis/AliasAnalysis.h"
                , specNS = [ClassName "llvm" [],ClassName "AliasAnalysis" []]
                , specName = "Location"
                , specTemplateArgs = []
                , specType = ClassSpec
                             [(Constructor [(True,constT $ ptr $ llvmType "Value")
                                           ,(False,normalT uint64_t)
                                           ,(False,constT $ ptr $ llvmType "MDNode")
                                           ],"newLocation_")]
                }]
     else [])++
       [Spec { specHeader = "llvm/Analysis/MemoryBuiltins.h"
             , specNS = llvmNS
             , specName = "getMallocAllocatedType"
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ptr $ llvmType "Type"
                                        , gfunArgs = [(False,constT $ ptr $ llvmType "CallInst")]++
                                                     (if version>=llvm3_2
                                                      then [(False,constT $ ptr $ llvmType "TargetLibraryInfo")]
                                                      else [])
                                        , gfunHSName = "getMallocAllocatedType"
                                        }
             }
       ,Spec { specHeader = "llvm/Analysis/MemoryBuiltins.h"
             , specNS = llvmNS
             , specName = "getMallocArraySize"
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT $ ptr $ llvmType "Value"
                                        , gfunArgs = [(False,normalT $ ptr $ llvmType "CallInst")]++
                                                     (if version >= llvm3_2
                                                      then [(False,constT $ ptr $ llvmType "DataLayout")
                                                           ,(False,constT $ ptr $ llvmType "TargetLibraryInfo")]
                                                      else [(False,constT $ ptr $ llvmType "TargetData")])++
                                                     [(False,normalT bool)]
                                        , gfunHSName = "getMallocArraySize"
                                        }
             }
       ,Spec { specHeader = "llvm/Analysis/MemoryBuiltins.h"
             , specNS = llvmNS
             , specName = if version>=llvm3_2
                          then "isMallocLikeFn"
                          else "isMalloc"
             , specTemplateArgs = []
             , specType = GlobalFunSpec { gfunReturnType = normalT bool
                                        , gfunArgs = [(True,constT $ ptr $ llvmType "Value")]++
                                                     (if version>=llvm3_2
                                                      then [(False,constT $ ptr $ llvmType "TargetLibraryInfo")
                                                           ,(False,normalT bool)]
                                                      else [])
                                        , gfunHSName = "isMallocLikeFn_"
                                        }
             }
       ,Spec { specHeader = "llvm/ADT/Twine.h"
             , specNS = llvmNS
             , specName = "Twine"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(Constructor [],"newTwineEmpty")
                          ,(Constructor [(False,constT $ ptr char)],"newTwineString_")
                          ]
             }
       ,Spec { specHeader = "llvm/Analysis/LoopInfo.h"
             , specNS = llvmNS
             , specName = "Loop"
             , specTemplateArgs = []
             , specType = ClassSpec
                          [(memberFun { ftReturnType = normalT bool
                                      , ftName = "isLoopInvariant"
                                      , ftArgs = [(True,normalT $ ptr $ llvmType "Value")]
                                      },"loopIsLoopInvariant_")]
             }
       ]++
    concat
    [[Spec { specHeader = "llvm/Analysis/LoopInfo.h"
           , specNS = llvmNS
           , specName = "LoopBase"
           , specTemplateArgs = [blk,loop]
           , specType = ClassSpec
                        [(memberFun { ftReturnType = normalT unsigned
                                    , ftName = "getLoopDepth"
                                    , ftOverloaded = True
                                    },"loopGetDepth_")
                        ,(memberFun { ftReturnType = toPtr blk
                                    , ftName = "getHeader"
                                    , ftOverloaded = True
                                    },"loopGetHeader_")
                        ,(memberFun { ftReturnType = toPtr loop
                                    , ftName = "getParentLoop"
                                    , ftOverloaded = True
                                    },"loopGetParent_")
                        ,(memberFun { ftReturnType = normalT bool
                                    , ftName = "contains"
                                    , ftArgs = [(False,toConstPtr loop)]
                                    , ftOverloaded = True
                                    },"loopContainsLoop_")
                        ,(memberFun { ftReturnType = normalT bool
                                    , ftName = "contains"
                                    , ftArgs = [(False,toConstPtr blk)]
                                    , ftOverloaded = True
                                    },"loopContainsBlock_")
                        ,(memberFun { ftReturnType = constT $ NamedType [ClassName "std" []] "vector" [toPtr loop]
                                    , ftName = "getSubLoops"
                                    , ftOverloaded = True
                                    },"loopGetSubLoops_")
                        ,(memberFun { ftReturnType = constT $ NamedType [ClassName "std" []] "vector" [toPtr blk]
                                    , ftName = "getBlocks"
                                    , ftOverloaded = True
                                    },"loopGetBlocks_")
                        ,(memberFun { ftName = "getExitEdges"
                                    , ftArgs = [(False,normalT $ ref $ NamedType llvmNS "SmallVector"
                                                          [normalT $ NamedType [ClassName "std" []] "pair" [constT $ ptr $ llvmType "BasicBlock"
                                                                                                           ,constT $ ptr $ llvmType "BasicBlock"]
                                                          ,TypeInt 16])]
                                    , ftOverloaded = True
                                    },"loopGetExitEdges_")
                        ,(memberFun { ftReturnType = normalT unsigned
                                    , ftName = "getNumBackEdges"
                                    , ftOverloaded = True
                                    },"loopGetNumBackEdges_")]
             }
     ,Spec { specHeader = "llvm/Analysis/LoopInfo.h"
           , specNS = llvmNS
           , specName = "LoopInfoBase"
           , specTemplateArgs = [blk,loop]
           , specType = ClassSpec
                        [(memberFun { ftReturnType = normalT $ NamedType [ClassName "std" []
                                                                         ,ClassName "vector" [toPtr loop]
                                                                         ] "const_iterator" []
                                    , ftName = "begin"
                                    },"loopInfoBaseBegin_")
                        ,(memberFun { ftReturnType = normalT $ NamedType [ClassName "std" []
                                                                         ,ClassName "vector" [toPtr loop]
                                                                         ] "const_iterator" []
                                    , ftName = "end"
                                    },"loopInfoBaseEnd_")
                        ,(memberFun { ftReturnType = toPtr loop
                                    , ftName = "getLoopFor"
                                    , ftArgs = [(False,toConstPtr blk)]
                                    },"loopInfoBaseGetLoopFor_")]
           }]
     | (blk,loop) <- [(normalT $ llvmType "BasicBlock",normalT $ llvmType "Loop")]
    ]++
    [Spec { specHeader = "llvm/PassAnalysisSupport.h"
          , specNS = llvmNS
          , specName = "AnalysisUsage"
          , specTemplateArgs = []
          , specType = ClassSpec
                       [(Constructor [],"newAnalysisUsage")
                       ,(memberFun { ftName = "addRequiredID"
                                   , ftArgs = [(False,normalT $ ref char)]
                                   , ftIgnoreReturn = True
                                   },"analysisUsageAddRequired_")
                       ,(memberFun { ftName = "addRequiredTransitiveID"
                                   , ftArgs = [(False,normalT $ ref char)]
                                   , ftIgnoreReturn = True
                                   },"analysisUsageAddRequiredTransitive_")
                       ,(memberFun { ftName = "addPreservedID"
                                   , ftArgs = [(False,normalT $ ref char)]
                                   , ftIgnoreReturn = True
                                   },"analysisUsageAddPreserved_")
                       ,(memberFun { ftName = "setPreservesAll"
                                   },"analysisUsagePreservesAll")
                       ,(memberFun { ftName = "setPreservesCFG"
                                   },"analysisUsagePreservesCFG")]
          }
    ,Spec { specHeader = "llvm/PassAnalysisSupport.h"
          , specNS = llvmNS
          , specName = "AnalysisResolver"
          , specTemplateArgs = []
          , specType = ClassSpec
                       [(memberFun { ftReturnType = normalT $ ptr $ llvmType "Pass"
                                   , ftName = "findImplPass"
                                   , ftArgs = [(False,constT $ ptr void)]
                                   },"analysisResolverFindImplPass_")
                       ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Pass"
                                   , ftName = "findImplPass"
                                   , ftArgs = [(True,normalT $ ptr $ llvmType "Pass")
                                              ,(False,constT $ ptr void)
                                              ,(False,normalT $ ref $ llvmType "Function")]
                                   },"analysisResolverFindImplPassFun_")]
          }
    ,Spec { specHeader = "llvm/ExecutionEngine/GenericValue.h"
          , specNS = llvmNS
          , specName = "GenericValue"
          , specTemplateArgs = []
          , specType = ClassSpec $
                       [(Constructor [],"newGenericValue")
                       ,(Getter { ftGetVar = "DoubleVal"
                                , ftGetType = normalT double
                                , ftGetStatic = False
                                },"genericValueGetDouble")
                       ,(Setter { ftSetVar = "DoubleVal"
                                , ftSetType = normalT double
                                },"genericValueSetDouble")
                       ,(Getter { ftGetVar = "FloatVal"
                                , ftGetType = normalT float
                                , ftGetStatic = False
                                },"genericValueGetFloat")
                       ,(Setter { ftSetVar = "FloatVal"
                                , ftSetType = normalT float
                                },"genericValueSetFloat")
                       ,(Getter { ftGetVar = "PointerVal"
                                , ftGetType = normalT $ ptr void
                                , ftGetStatic = False
                                },"genericValueGetPointer")
                       ,(Setter { ftSetVar = "PointerVal"
                                , ftSetType = normalT $ ptr void
                                },"genericValueSetPointer")
                       ,(Getter { ftGetVar = "IntVal"
                                , ftGetType = normalT $ llvmType "APInt"
                                , ftGetStatic = False
                                },"genericValueGetInt")
                       ,(Setter { ftSetVar = "IntVal"
                                , ftSetType = normalT $ llvmType "APInt"
                                },"genericValueSetInt")]++
                       (if version>=llvm3_3
                        then [(Getter { ftGetVar = "AggregateVal"
                                      , ftGetType = normalT $ NamedType [ClassName "std" []] "vector"
                                                    [normalT $ llvmType "GenericValue"]
                                      , ftGetStatic = False
                                      },"genericValueGetAggregate")
                             ,(Setter { ftSetVar = "AggregateVal"
                                      , ftSetType = normalT $ NamedType [ClassName "std" []] "vector"
                                                    [normalT $ llvmType "GenericValue"]
                                      },"genericValueSetAggregate")]
                        else [])
          }
    ,Spec { specHeader = "llvm/ExecutionEngine/ExecutionEngine.h"
          , specNS = llvmNS
          , specName = "ExecutionEngine"
          , specTemplateArgs = []
          , specType = ClassSpec $
                       [(Destructor True,"deleteExecutionEngine_")
                       ,(memberFun { ftName = "addModule"
                                   , ftArgs = [(False,normalT $ ptr $ llvmType "Module")]
                                   , ftOverloaded = True
                                   },"executionEngineAddModule_")
                       ,if version >= llvm3_2
                        then (memberFun { ftReturnType = normalT $ ptr $ llvmType "DataLayout"
                                        , ftName = "getDataLayout"
                                        , ftOverloaded = True
                                        },"executionEngineGetDataLayout_")
                        else (memberFun { ftReturnType = normalT $ ptr $ llvmType "TargetData"
                                        , ftName = "getTargetData"
                                        , ftOverloaded = True
                                        },"executionEngineGetTargetData_")
                       ,(memberFun { ftReturnType = normalT bool
                                   , ftName = "removeModule"
                                   , ftArgs = [(False,normalT $ ptr $ llvmType "Module")]
                                   , ftOverloaded = True
                                   },"executionEngineRemoveModule_")
                       ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "Function"
                                   , ftName = "FindFunctionNamed"
                                   , ftArgs = [(False,constT $ ptr char)]
                                   , ftOverloaded = True
                                   },"executionEngineFindFunctionNamed_")
                       ,(memberFun { ftReturnType = normalT $ llvmType "GenericValue"
                                   , ftName = "runFunction"
                                   , ftArgs = [(False,normalT $ ptr $ llvmType "Function")
                                              ,(False,constT $ ref $ NamedType [ClassName "std" []] "vector"
                                                         [normalT $ llvmType "GenericValue"])]
                                   , ftOverloaded = True
                                   },"executionEngineRunFunction_")]++
            (if version >= llvm3_1
             then [(memberFun { ftReturnType = normalT $ ptr void
                              , ftName = "getPointerToNamedFunction"
                              , ftArgs = [(False,constT $ ptr char)
                                         ,(False,normalT bool)]
                              , ftOverloaded = True
                              },"executionEngineGetPointerToNamedFunction_")
                  ,(memberFun { ftName = "mapSectionAddress"
                        , ftArgs = [(False,if version >= llvm3_2
                                           then constT $ ptr void
                                           else normalT $ ptr void)
                                   ,(False,normalT uint64_t)]
                                   , ftOverloaded = True
                        },"executionEngineMapSectionAddress_")]
             else [])++
            [(memberFun { ftName = "runStaticConstructorsDestructors"
                        , ftArgs = [(False,normalT bool)]
                        , ftOverloaded = True
                        },"executionEngineRunStaticConstructorsDestructors_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getPointerToFunction"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "Function")]
                        , ftOverloaded = True
                        },"executionEngineGetPointerToFunction_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getPointerToFunctionOrStub"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "Function")]
                        , ftOverloaded = True
                        },"executionEngineGetPointerToFunctionOrStub_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getPointerToGlobal"
                        , ftArgs = [(True,constT $ ptr $ llvmType "GlobalValue")]
                        , ftOverloaded = True
                        },"executionEngineGetPointerToGlobal_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getPointerToGlobalIfAvailable"
                        , ftArgs = [(True,constT $ ptr $ llvmType "GlobalValue")]
                        , ftOverloaded = True
                        },"executionEngineGetPointerToGlobalIfAvailable_")
            ,(memberFun { ftName = "addGlobalMapping"
                        , ftArgs = [(True,constT $ ptr $ llvmType "GlobalValue")
                                   ,(False,normalT $ ptr void)]
                        , ftOverloaded = True
                        },"executionEngineAddGlobalMapping_")
            ,(memberFun { ftName = "clearAllGlobalMappings"
                        , ftOverloaded = True
                        },"executionEngineClearAllGlobalMappings_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "updateGlobalMapping"
                        , ftArgs = [(True,constT $ ptr $ llvmType "GlobalValue")
                                   ,(False,normalT $ ptr void)]
                        , ftOverloaded = True
                        },"executionEngineUpdateGlobalMapping_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getPointerToBasicBlock"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "BasicBlock")]
                        , ftOverloaded = True
                        },"executionEngineGetPointerToBasicBlock_")
            ,(memberFun { ftName = "runJITOnFunction"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "Function")
                                   ,(False,normalT $ ptr $ llvmType "MachineCodeInfo")]
                        , ftOverloaded = True
                        },"executionEngineRunJITOnFunction_")
            ,(memberFun { ftReturnType = constT $ ptr $ llvmType "GlobalValue"
                        , ftName = "getGlobalValueAtAddress"
                        , ftArgs = [(False,normalT $ ptr void)]
                        , ftOverloaded = True
                        },"executionEngineGetGlobalValueAtAddress_")
            ,(memberFun { ftName = "StoreValueToMemory"
                        , ftArgs = [(False,constT $ ref $ llvmType "GenericValue")
                                   ,(False,normalT $ ptr $ llvmType "GenericValue")
                                   ,(True,normalT $ ptr $ llvmType "Type")]
                        , ftOverloaded = True
                        },"executionEngineStoreValueToMemory_")
            ,(memberFun { ftName = "InitializeMemory"
                        , ftArgs = [(True,constT $ ptr $ llvmType "Constant")
                                   ,(False,normalT $ ptr void)]
                        , ftOverloaded = True
                        },"executionEngineInitializeMemory_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "recompileAndRelinkFunction"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "Function")]
                        , ftOverloaded = True
                        },"executionEngineRecompileAndRelinkFunction_")
            ,(memberFun { ftName = "freeMachineCodeForFunction"
                        , ftArgs = [(False,normalT $ ptr $ llvmType "Function")]
                        , ftOverloaded = True
                        },"executionEngineFreeMachineCodeForFunction_")
            ,(memberFun { ftReturnType = normalT $ ptr void
                        , ftName = "getOrEmitGlobalVariable"
                        , ftArgs = [(False,constT $ ptr $ llvmType "GlobalVariable")]
                        , ftOverloaded = True
                        },"executionEngineGetOrEmitGlobalVariable_")
            ]
          }
    ,Spec { specHeader = if version>=llvm3_0
                         then "llvm/Support/CodeGen.h"
                         else "llvm/Target/TargetMachine.h"
          , specNS = [ClassName "llvm" []
                     ,ClassName "CodeGenOpt" []]
          , specName = "Level"
          , specTemplateArgs = []
          , specType = EnumSpec "CodeGenOptLevel"
                       [("None","CodeGenOptNone")
                       ,("Less","CodeGenOptLess")
                       ,("Default","CodeGenOptDefault")
                       ,("Aggressive","CodeGenOptAggressive")]
          }
    ,Spec { specHeader = if version>=llvm3_0
                         then "llvm/Support/CodeGen.h"
                         else "llvm/Target/TargetMachine.h"
          , specNS = [ClassName "llvm" []
                     ,ClassName "CodeModel" []]
          , specName = "Model"
          , specTemplateArgs = []
          , specType = EnumSpec "CodeModel" $
                       [("Default","CodeModelDefault")
                       ,("Small","CodeModelSmall")
                       ,("Kernel","CodeModelKernel")
                       ,("Medium","CodeModelMedium")
                       ,("Large","CodeModelLarge")]++
                       (if version>=llvm3_0
                        then [("JITDefault","CodeModelJITDefault")]
                        else [])
          }
    ,Spec { specHeader = if version>=llvm3_0
                         then "llvm/Support/CodeGen.h"
                         else "llvm/Target/TargetMachine.h"
          , specNS = [ClassName "llvm" []
                     ,ClassName "Reloc" []]
          , specName = "Model"
          , specTemplateArgs = []
          , specType = EnumSpec "RelocModel" $
                       [("Default","RelocModelDefault")
                       ,("Static","RelocModelStatic")
                       ,("PIC_","RelocModelPIC")
                       ,("DynamicNoPIC","RelocModelDynamicNoPIC")]
          }
    ,Spec { specHeader = "llvm/ExecutionEngine/ExecutionEngine.h"
          , specNS = llvmNS
          , specName = "EngineBuilder"
          , specTemplateArgs = []
          , specType = ClassSpec $
                       [(Constructor [(False,normalT $ ptr $ llvmType "Module")],"newEngineBuilder")
                       ,(Destructor False,"deleteEngineBuilder")
                       ,(memberFun { ftIgnoreReturn = True
                                   , ftName = "setEngineKind"
                                   , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" []
                                                                         ,ClassName "EngineKind" []
                                                                         ] "Kind")]
                                   },"engineBuilderSetKind")
                       ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "ExecutionEngine"
                                   , ftName = "create"
                                   },"engineBuilderCreate")
                       ,(memberFun { ftIgnoreReturn = True
                                   , ftName = "setOptLevel"
                                   , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" []
                                                                         ,ClassName "CodeGenOpt" []
                                                                         ] "Level")]
                                   },"engineBuilderSetOptLevel")
                       ,(memberFun { ftIgnoreReturn = True
                                   , ftName = "setCodeModel"
                                   , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" []
                                                                         ,ClassName "CodeModel" []
                                                                         ] "Model")]
                                   },"engineBuilderSetCodeModel")]++
            (if version>=llvm3_0
             then [(memberFun { ftIgnoreReturn = True
                              , ftName = "setRelocationModel"
                              , ftArgs = [(False,normalT $ EnumType [ClassName "llvm" []
                                                                    ,ClassName "Reloc" []
                                                                    ] "Model")]
                              },"engineBuilderSetRelocationModel")]
             else [])
          }
    ,Spec { specHeader = "llvm/ExecutionEngine/ExecutionEngine.h"
          , specNS = [ClassName "llvm" [],ClassName "EngineKind" []]
          , specName = "Kind"
          , specTemplateArgs = []
          , specType = EnumSpec "EngineKind" [("JIT","JIT")
                                             ,("Interpreter","Interpreter")
                                             ,("Either","EitherEngine")]
          }
    ,Spec { specHeader = "llvm/CodeGen/MachineCodeInfo.h"
          , specNS = llvmNS
          , specName = "MachineCodeInfo"
          , specTemplateArgs = []
          , specType = ClassSpec
                       [(Constructor [],"newMachineCodeInfo")
                       ,(memberFun { ftName = "setSize"
                                   , ftArgs = [(False,normalT size_t)]
                                   },"machineCodeInfoSetSize")
                       ,(memberFun { ftName = "setAddress"
                                   , ftArgs = [(False,normalT $ ptr void)]
                                   },"machineCodeInfoSetAddress")
                       ,(memberFun { ftReturnType = normalT size_t
                                   , ftName = "size"
                                   },"machineCodeInfoGetSize")
                       ,(memberFun { ftReturnType = normalT $ ptr void
                                   , ftName = "address"
                                   },"machineCodeInfoGetAddress")]
          }
    ,Spec { specHeader = "llvm/Pass.h"
          , specNS = llvmNS
          , specName = "PassKind"
          , specTemplateArgs = []
          , specType = EnumSpec "PassKind" [("PT_"++name,"PassKind"++name)
                                            | name <- ["BasicBlock"]++
                                                     (if version>=llvm2_9
                                                      then ["Region"]
                                                      else [])++
                                                     ["Loop"
                                                     ,"Function"
                                                     ,"CallGraphSCC"
                                                     ,"Module"
                                                     ,"PassManager"]]
          }
    ,Spec { specHeader = irInclude version "InstrTypes.h"
          , specNS = [ClassName "llvm" [],ClassName "CmpInst" []]
          , specName = "Predicate"
          , specTemplateArgs = []
          , specType = EnumSpec "FCmpOp"
                       [("FCMP_"++name,"F_"++name)
                        | name <- ["OEQ","OGT","OGE","OLT"
                                 ,"OLE","ONE","ORD","UNO"
                                 ,"UEQ","UGT","UGE","ULT"
                                 ,"ULE","UNE"]]
          }
    ,Spec { specHeader = irInclude version "InstrTypes.h"
          , specNS = [ClassName "llvm" [],ClassName "CmpInst" []]
          , specName = "Predicate"
          , specTemplateArgs = []
          , specType = EnumSpec "ICmpOp"
                       [("ICMP_"++name,"I_"++name)
                        | name <- ["EQ","NE","UGT","UGE"
                                 ,"ULT","ULE","SGT","SGE"
                                 ,"SLT","SLE"]]
          }
    ,Spec { specHeader = irInclude version "CallingConv.h"
          , specNS = [ClassName "llvm" [],ClassName "CallingConv" []]
          , specName = "ID"
          , specTemplateArgs = []
          , specType = EnumSpec "CallingConv"
                       [(name,name)
                        | name <- ["C","Fast","Cold","GHC"
                                 ,"FirstTargetCC"
                                 ,"X86_StdCall","X86_FastCall"
                                 ,"ARM_APCS","ARM_AAPCS"
                                 ,"ARM_AAPCS_VFP"
                                 ,"MSP430_INTR"
                                 ,"X86_ThisCall"]++
                                 (if version>=llvm2_9
                                  then ["PTX_Kernel","PTX_Device"
                                       ,"MBLAZE_INTR","MBLAZE_SVOL"]
                                  else [])++
                                 (if version>llvm3_1
                                  then ["SPIR_FUNC"
                                       ,"SPIR_KERNEL"
                                       ,"Intel_OCL_BI"]
                                  else [])]
          }]++
    (if version>=llvm3_0
     then [Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "SynchronizationScope"
                , specTemplateArgs = []
                , specType = EnumSpec "SynchronizationScope"
                             [("SingleThread","SingleThread")
                             ,("CrossThread","CrossThread")]
                }
          ,Spec { specHeader = irInclude version "Instructions.h"
                , specNS = llvmNS
                , specName = "AtomicOrdering"
                , specTemplateArgs = []
                , specType = EnumSpec "AtomicOrdering"
                             [(name,name) | name <- ["NotAtomic"
                                                   ,"Unordered"
                                                   ,"Monotonic"
                                                   ,"Acquire"
                                                   ,"Release"
                                                   ,"AcquireRelease"
                                                   ,"SequentiallyConsistent"]]
                }
          ,Spec { specHeader = irInclude version "Instructions.h"
                , specNS = [ClassName "llvm" [],ClassName "AtomicRMWInst" []]
                , specName = "BinOp"
                , specTemplateArgs = []
                , specType = EnumSpec "RMWBinOp"
                             [(name,"RMW"++name)
                                  | name <- ["Xchg"
                                           ,"Add"
                                           ,"Sub"
                                           ,"And"
                                           ,"Nand"
                                           ,"Or"
                                           ,"Xor"
                                           ,"Max"
                                           ,"Min"
                                           ,"UMax"
                                           ,"UMin"]]
                }]
     else [])++
    [Spec { specHeader = "llvm/Analysis/AliasAnalysis.h"
          , specNS = [ClassName "llvm" [],ClassName "AliasAnalysis" []]
          , specName = "AliasResult"
          , specTemplateArgs = []
          , specType = EnumSpec "AliasResult" $
                       [("NoAlias","NoAlias")
                       ,("MayAlias","MayAlias")]++
                       (if version>=llvm2_9
                        then [("PartialAlias","PartialAlias")]
                        else [])++
                       [("MustAlias","MustAlias")]
          }
    ,Spec { specHeader = if version>=llvm3_0
                         then "llvm/Support/TargetRegistry.h"
                         else "llvm/Target/TargetRegistry.h"
          , specNS = llvmNS
          , specName = "Target"
          , specTemplateArgs = []
          , specType = ClassSpec $
                       [(memberFun { ftReturnType = constT $ ptr $ llvmType "Target"
                                   , ftName = "getNext"
                                   },"targetNext")
                       ,(memberFun { ftReturnType = constT $ ptr char
                                   , ftName = "getName"
                                   },"targetName")
                       ,(memberFun { ftReturnType = constT $ ptr char
                                   , ftName = "getShortDescription"
                                   },"targetShortDescription")]++
                       [(memberFun { ftReturnType = normalT bool
                                   , ftName = "has"++name
                                   },"targetHas"++name)
                        | name <- ["JIT","TargetMachine","AsmPrinter"]++
                                 (if version>=llvm2_9
                                  then ["AsmStreamer"]
                                  else [])++
                                 (if version>=llvm3_0
                                  then ["MCAsmBackend","MCAsmParser","MCDisassembler","MCInstPrinter"
                                       ,"MCCodeEmitter","MCObjectStreamer"]
                                  else []) ]
          }
    ,Spec { specHeader = "llvm/Target/TargetMachine.h"
          , specNS = llvmNS
          , specName = "TargetMachine"
          , specTemplateArgs = []
          , specType = ClassSpec
                       [(Destructor True,"deleteTargetMachine_")
                       ,(memberFun { ftReturnType = constT $ ref $ llvmType "Target"
                                   , ftName = "getTarget"
                                   , ftOverloaded = True
                                   },"targetMachineTarget_")]
          }]++
    (if version>=llvm2_9
     then [Spec { specHeader = "llvm/Target/TargetLibraryInfo.h"
                , specNS = [ClassName "llvm" [],ClassName "LibFunc" []]
                , specName = "Func"
                , specTemplateArgs = []
                , specType = EnumSpec "LibFunc"
                             [(name,"Func_"++name)
                              | name <- ["fiprintf"
                                       ,"iprintf"
                                       ,"memcpy"
                                       ,"memset"
                                       ,"memset_pattern16"
                                       ,"siprintf"]++
                                       (if version>=llvm3_0
                                        then ["memmove"]
                                        else [])++
                                       (if version>=llvm3_1
                                        then ["cxa_atexit"
                                             ,"cxa_guard_abort"
                                             ,"cxa_guard_acquire"
                                             ,"cxa_guard_release"
                                             ,"acos"
                                             ,"acosf"
                                             ,"acosl"
                                             ,"asin"
                                             ,"asinf"
                                             ,"asinl"
                                             ,"atan"
                                             ,"atan2"
                                             ,"atan2f"
                                             ,"atan2l"
                                             ,"atanf"
                                             ,"atanl"
                                             ,"ceil"
                                             ,"ceilf"
                                             ,"ceill"
                                             ,"copysign"
                                             ,"copysignf"
                                             ,"copysignl"
                                             ,"cos"
                                             ,"cosf"
                                             ,"cosh"
                                             ,"coshf"
                                             ,"coshl"
                                             ,"cosl"
                                             ,"exp"
                                             ,"exp2"
                                             ,"exp2f"
                                             ,"exp2l"
                                             ,"expf"
                                             ,"expl"
                                             ,"expm1"
                                             ,"expm1f"
                                             ,"expm1l"
                                             ,"fabs"
                                             ,"fabsf"
                                             ,"fabsl"
                                             ,"floor"
                                             ,"floorf"
                                             ,"floorl"
                                             ,"fmod"
                                             ,"fmodf"
                                             ,"fmodl"
                                             ,"fputs"
                                             ,"fwrite"
                                             ,"log"
                                             ,"log10"
                                             ,"log10f"
                                             ,"log10l"
                                             ,"log1p"
                                             ,"log1pf"
                                             ,"log1pl"
                                             ,"log2"
                                             ,"log2f"
                                             ,"log2l"
                                             ,"logf"
                                             ,"logl"
                                             ,"nearbyint"
                                             ,"nearbyintf"
                                             ,"nearbyintl"
                                             ,"pow"
                                             ,"powf"
                                             ,"powl"
                                             ,"rint"
                                             ,"rintf"
                                             ,"rintl"
                                             ,"round"
                                             ,"roundf"
                                             ,"roundl"
                                             ,"sin"
                                             ,"sinf"
                                             ,"sinh"
                                             ,"sinhf"
                                             ,"sinhl"
                                             ,"sinl"
                                             ,"sqrt"
                                             ,"sqrtf"
                                             ,"sqrtl"
                                             ,"tan"
                                             ,"tanf"
                                             ,"tanh"
                                             ,"tanhf"
                                             ,"tanhl"
                                             ,"tanl"
                                             ,"trunc"
                                             ,"truncf"
                                             ,"truncl"]++
                                        (if version>=llvm3_3
                                         then ["under_IO_getc"
                                              ,"under_IO_putc"
                                              ,"ZdaPv"
                                              ,"ZdlPv"
                                              ,"Znaj"
                                              ,"ZnajRKSt9nothrow_t"
                                              ,"Znam"
                                              ,"ZnamRKSt9nothrow_t"
                                              ,"Znwj"
                                              ,"ZnwjRKSt9nothrow_t"
                                              ,"Znwm"
                                              ,"ZnwmRKSt9nothrow_t"
                                              ,"dunder_isoc99_scanf"
                                              ,"dunder_isoc99_sscanf"
                                              ,"memcpy_chk"
                                              ,"dunder_strdup"
                                              ,"dunder_strndup"
                                              ,"dunder_strtok_r"
                                              ,"abs"
                                              ,"access"
                                              ,"acosh"
                                              ,"acoshf"
                                              ,"acoshl"
                                              ,"asinh"
                                              ,"asinhf"
                                              ,"asinhl"
                                              ,"atanh"
                                              ,"atanhf"
                                              ,"atanhl"
                                              ,"atof"
                                              ,"atoi"
                                              ,"atol"
                                              ,"atoll"
                                              ,"bcmp"
                                              ,"bcopy"
                                              ,"bzero"
                                              ,"calloc"
                                              ,"cbrt"
                                              ,"cbrtf"
                                              ,"cbrtl"
                                              ,"chmod"
                                              ,"chown"
                                              ,"clearerr"
                                              ,"closedir"
                                              ,"ctermid"
                                              ,"exp10"
                                              ,"exp10f"
                                              ,"exp10l"
                                              ,"fclose"
                                              ,"fdopen"
                                              ,"feof"
                                              ,"ferror"
                                              ,"fflush"
                                              ,"ffs"
                                              ,"ffsl"
                                              ,"ffsll"
                                              ,"fgetc"
                                              ,"fgetpos"
                                              ,"fgets"
                                              ,"fileno"
                                              ,"flockfile"
                                              ,"fopen"
                                              ,"fopen64"
                                              ,"fprintf"
                                              ,"fputc"
                                              ,"fread"
                                              ,"free"
                                              ,"frexp"
                                              ,"frexpf"
                                              ,"frexpl"
                                              ,"fscanf"
                                              ,"fseek"
                                              ,"fseeko"
                                              ,"fseeko64"
                                              ,"fsetpos"
                                              ,"fstat"
                                              ,"fstat64"
                                              ,"fstatvfs"
                                              ,"fstatvfs64"
                                              ,"ftell"
                                              ,"ftello"
                                              ,"ftello64"
                                              ,"ftrylockfile"
                                              ,"funlockfile"
                                              ,"getc"
                                              ,"getc_unlocked"
                                              ,"getchar"
                                              ,"getenv"
                                              ,"getitimer"
                                              ,"getlogin_r"
                                              ,"getpwnam"
                                              ,"gets"
                                              ,"htonl"
                                              ,"htons"
                                              ,"isascii"
                                              ,"isdigit"
                                              ,"labs"
                                              ,"lchown"
                                              ,"llabs"
                                              ,"logb"
                                              ,"logbf"
                                              ,"logbl"
                                              ,"lstat"
                                              ,"lstat64"
                                              ,"malloc"
                                              ,"memalign"
                                              ,"memccpy"
                                              ,"memchr"
                                              ,"memcmp"
                                              ,"memrchr"
                                              ,"mkdir"
                                              ,"mktime"
                                              ,"modf"
                                              ,"modff"
                                              ,"modfl"
                                              ,"ntohl"
                                              ,"ntohs"
                                              ,"open"
                                              ,"open64"
                                              ,"opendir"
                                              ,"pclose"
                                              ,"perror"
                                              ,"popen"
                                              ,"posix_memalign"
                                              ,"pread"
                                              ,"printf"
                                              ,"putc"
                                              ,"putchar"
                                              ,"puts"
                                              ,"pwrite"
                                              ,"qsort"
                                              ,"read"
                                              ,"readlink"
                                              ,"realloc"
                                              ,"reallocf"
                                              ,"realpath"
                                              ,"remove"
                                              ,"rename"
                                              ,"rewind"
                                              ,"rmdir"
                                              ,"scanf"
                                              ,"setbuf"
                                              ,"setitimer"
                                              ,"setvbuf"
                                              ,"snprintf"
                                              ,"sprintf"
                                              ,"sscanf"
                                              ,"stat"
                                              ,"stat64"
                                              ,"statvfs"
                                              ,"statvfs64"
                                              ,"stpcpy"
                                              ,"stpncpy"
                                              ,"strcasecmp"
                                              ,"strcat"
                                              ,"strchr"
                                              ,"strcmp"
                                              ,"strcoll"
                                              ,"strcpy"
                                              ,"strcspn"
                                              ,"strdup"
                                              ,"strlen"
                                              ,"strncasecmp"
                                              ,"strncat"
                                              ,"strncmp"
                                              ,"strncpy"
                                              ,"strndup"
                                              ,"strnlen"
                                              ,"strpbrk"
                                              ,"strrchr"
                                              ,"strspn"
                                              ,"strstr"
                                              ,"strtod"
                                              ,"strtof"
                                              ,"strtok"
                                              ,"strtok_r"
                                              ,"strtol"
                                              ,"strtold"
                                              ,"strtoll"
                                              ,"strtoul"
                                              ,"strtoull"
                                              ,"strxfrm"
                                              ,"system"
                                              ,"times"
                                              ,"tmpfile"
                                              ,"tmpfile64"
                                              ,"toascii"
                                              ,"uname"
                                              ,"ungetc"
                                              ,"unlink"
                                              ,"unsetenv"
                                              ,"utime"
                                              ,"utimes"
                                              ,"valloc"
                                              ,"vfprintf"
                                              ,"vfscanf"
                                              ,"vprintf"
                                              ,"vscanf"
                                              ,"vsnprintf"
                                              ,"vsprintf"
                                              ,"vsscanf"
                                              ,"write"]
                                         else[])
                                        else [])
                             ]
                }
          ]
      else [])++
   [Spec { specHeader = "llvm/Analysis/Dominators.h"
         , specNS = llvmNS
         , specName = "DominatorTree"
         , specTemplateArgs = []
         , specType = ClassSpec
                      [(Constructor [],"newDominatorTree")
                      ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType "BasicBlock"]
                                  , ftName = "getRootNode"
                                  },"dominatorTreeGetRootNode")
                      ,(memberFun { ftReturnType = normalT bool
                                  , ftName = "compare"
                                  , ftArgs = [(False,normalT $ ref $ llvmType "DominatorTree")]
                                  },"dominatorTreeCompare")
                      ,(memberFun { ftReturnType = normalT bool
                                  , ftName = "dominates"
                                  , ftArgs = [(False,(if version>=llvm2_9
                                                      then constT
                                                      else normalT) $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType "BasicBlock"])
                                             ,(False,(if version>=llvm2_9
                                                      then constT
                                                      else normalT) $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType "BasicBlock"])]
                                  },"dominatorTreeDominates")
                      ,(memberFun { ftReturnType = normalT $ ptr $ llvmType "BasicBlock"
                                  , ftName = "findNearestCommonDominator"
                                  , ftArgs = [(False,normalT $ ptr $ llvmType "BasicBlock")
                                             ,(False,normalT $ ptr $ llvmType "BasicBlock")]
                                  },"dominatorTreeFindNearestCommonDominator")
                      ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType "BasicBlock"]
                                  , ftName = "getNode"
                                  , ftArgs = [(False,normalT $ ptr $ llvmType "BasicBlock")]
                                  },"dominatorTreeGetNode")]
         }]++
   [Spec { specHeader = "llvm/Analysis/Dominators.h"
         , specNS = llvmNS
         , specName = "DomTreeNodeBase"
         , specTemplateArgs = [normalT $ llvmType tp]
         , specType = ClassSpec
                      [(memberFun { ftReturnType = normalT $ ptr $ llvmType tp
                                  , ftName = "getBlock"
                                  },"domTreeNodeBaseGetBlock"++tp)
                      ,(memberFun { ftReturnType = normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType tp]
                                  , ftName = "getIDom"
                                  },"domTreeNodeBaseGetIDom"++tp)
                      ,(memberFun { ftReturnType = constT $ ref $ NamedType [ClassName "std" []] "vector" [normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType tp]]
                                  , ftName = "getChildren"
                                  },"domTreeNodeBaseGetChildren"++tp)
                      ,(memberFun { ftReturnType = normalT bool
                                  , ftName = "compare"
                                  , ftArgs = [(False,normalT $ ptr $ NamedType llvmNS "DomTreeNodeBase" [normalT $ llvmType tp])]
                                  },"domTreeNodeBaseCompare"++tp)
                      ,(memberFun { ftReturnType = normalT unsigned
                                  , ftName = "getDFSNumIn"
                                  },"domTreeNodeBaseGetDFSNumIn"++tp)
                      ,(memberFun { ftReturnType = normalT unsigned
                                  , ftName = "getDFSNumOut"
                                  },"domTreeNodeBaseGetDFSNumOut"++tp)]
         }
    | tp <- ["BasicBlock"]]
