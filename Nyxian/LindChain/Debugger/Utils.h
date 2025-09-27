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

#ifndef LINDCHAIN_DEBUGGER_UTILS_H
#define LINDCHAIN_DEBUGGER_UTILS_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach/exc.h>
#include <mach/exception.h>
#include <mach/exception_types.h>
#include <mach/thread_act.h>
#include <mach/thread_state.h>
#import <Foundation/Foundation.h>
#import <LindChain/Decompiler/Decompiler.h>

const char *symbol_for_address(void *addr);

void stack_trace_from_thread_state(arm_thread_state64_t state);
void stack_trace_from_thread_state_of_task(task_t task,
                                           arm_thread_state64_t state);

uint64_t get_thread_id_from_port(thread_t thread);
int get_thread_index_from_port(thread_t target);

#endif /* LINDCHAIN_DEBUGGER_UTILS_H */
