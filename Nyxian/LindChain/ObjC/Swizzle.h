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

#ifndef LINDCHAIN_OBJC_SWIZZLE_H
#define LINDCHAIN_OBJC_SWIZZLE_H

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface ObjCSwizzler : NSObject

+ (void)replaceInstanceAction:(SEL)originalAction ofClass:(Class)class withAction:(SEL)replacementAction;
+ (void)replaceClassAction:(SEL)originalAction ofClass:(Class)class withAction:(SEL)replacementAction;
+ (void)replaceInstanceAction:(SEL)originalAction ofClass:(Class)class withAction:(SEL)replacementAction ofClass:(Class)replacementClass;
+ (void)replaceClassAction:(SEL)originalAction ofClass:(Class)class withAction:(SEL)replacementAction ofClass:(Class)replacementClass;
+ (void)replaceInstanceAction:(SEL)originalAction ofClass:(Class)class withSymbol:(void*)symbol;
+ (void)replaceClassAction:(SEL)originalAction ofClass:(Class)class withSymbol:(void*)symbol;

@end

#endif /* LINDCHAIN_OBJC_SWIZZLE_H */
