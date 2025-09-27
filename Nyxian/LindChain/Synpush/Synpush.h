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
#import <LindChain/Synpush/Synitem.h>
#include <clang-c/Index.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

///
/// Created this to co-op with the code editor
///
@interface SynpushServer : NSObject

///
/// Functions
///
- (instancetype)init:(NSString*)filepath
                args:(NSArray*)args;

- (void)reparseFile:(NSString*)content;
- (NSArray<Synitem *> *)getDiagnostics;
- (NSArray<NSString*>*)getAutocompletionsAtLine:(UInt32)line
                                       atColumn:(UInt32)column;
- (void)updateBuffer:(NSString *)content;

@end
