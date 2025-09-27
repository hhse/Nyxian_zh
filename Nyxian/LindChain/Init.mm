/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/TargetSelect.h"

extern "C"  int ls_getfd(void);

void NyxLLVMErrorHandler(void *userData, const char *reason, bool genCrashDiag) {
    //dprintf(ls_getfd(), "LLVM trapped fatal error: %s\n", reason);
}

__attribute__((constructor))
void llvm_init(void)
{
    llvm::InitializeAllTargetInfos();
    llvm::InitializeAllTargets();
    llvm::InitializeAllTargetMCs();
    llvm::InitializeAllAsmParsers();
    llvm::InitializeAllAsmPrinters();
    llvm::InitializeAllDisassemblers();
    llvm::install_fatal_error_handler(NyxLLVMErrorHandler);
}
