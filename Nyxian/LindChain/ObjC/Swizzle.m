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

#import <LindChain/ObjC/Swizzle.h>

@implementation ObjCSwizzler

+ (void)replaceInstanceAction:(SEL)originalAction
                      ofClass:(Class)class
                   withAction:(SEL)replacementAction
{
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, replacementAction));
}

+ (void)replaceClassAction:(SEL)originalAction
                   ofClass:(Class)class
                withAction:(SEL)replacementAction
{
    method_exchangeImplementations(class_getClassMethod(class, originalAction), class_getClassMethod(class, replacementAction));
}

+ (void)replaceInstanceAction:(SEL)originalAction
                      ofClass:(Class)class
                   withAction:(SEL)replacementAction
                      ofClass:(Class)replacementClass
{
    Method replacementMethod = class_getInstanceMethod(replacementClass, replacementAction);
    class_addMethod(class, replacementAction, method_getImplementation(replacementMethod), method_getTypeEncoding(replacementMethod));
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, replacementAction));
}

+ (void)replaceClassAction:(SEL)originalAction
                   ofClass:(Class)class
                withAction:(SEL)replacementAction
                   ofClass:(Class)replacementClass
{
    Method replacementMethod = class_getClassMethod(replacementClass, replacementAction);
    class_addMethod(class, replacementAction, method_getImplementation(replacementMethod), method_getTypeEncoding(replacementMethod));
    method_exchangeImplementations(class_getClassMethod(class, originalAction), class_getClassMethod(class, replacementAction));
}

+ (void)replaceInstanceAction:(SEL)originalAction
                      ofClass:(Class)class
                   withSymbol:(void*)symbol
{
    Method targetMethod = class_getInstanceMethod(class, originalAction);
    method_setImplementation(targetMethod, (IMP)symbol);
}

+ (void)replaceClassAction:(SEL)originalAction
                   ofClass:(Class)class
                withSymbol:(void*)symbol
{
    Method targetMethod = class_getClassMethod(class, originalAction);
    method_setImplementation(targetMethod, (IMP)symbol);
}

@end
