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

// MARK: Apple seems to have implemented mach port transmission into iOS 26, as in iOS 18.7 RC and below it crashes but on iOS 26.0 RC it actually transmitts the task port

#ifndef PROCENVIRONMENT_TFPOBJECT
#define PROCENVIRONMENT_TFPOBJECT

/* ----------------------------------------------------------------------
 *  Apple API Headers
 * -------------------------------------------------------------------- */
#import <Foundation/Foundation.h>
#import <mach/mach.h>

API_AVAILABLE(ios(26.0))
@interface TaskPortObject : NSObject <NSSecureCoding>

@property (nonatomic, readonly) mach_port_t port;

- (instancetype)initWithPort:(mach_port_t)port;

+ (instancetype)taskPortSelf;

- (BOOL)isUsable;

@end

#endif /* PROCENVIRONMENT_TFPOBJECT */
