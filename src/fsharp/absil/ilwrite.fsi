// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.

/// The IL Binary writer.
module internal FSharp.Compiler.AbstractIL.ILBinaryWriter

open Internal.Utilities
open FSharp.Compiler.AbstractIL
open FSharp.Compiler.AbstractIL.Internal
open FSharp.Compiler.AbstractIL.IL
open FSharp.Compiler.AbstractIL.ILPdbWriter
open FSharp.Compiler.AbstractIL.Internal.StrongNameSign

type options =
 { ilg: ILGlobals
   pdbfile: string option
   portablePDB: bool
   embeddedPDB: bool
   embedAllSource: bool
   embedSourceList: string list
   sourceLink: string
   checksumAlgorithm: HashAlgorithm
   signer : ILStrongNameSigner option
   emitTailcalls: bool
   deterministic: bool
   showTimes : bool
   dumpDebugInfo : bool
   pathMap : PathMap }

/// Write a binary to the file system. Extra configuration parameters can also be specified. 
val WriteILBinary: filename: string * options:  options * inputModule: ILModuleDef * (ILAssemblyRef -> ILAssemblyRef) -> unit
