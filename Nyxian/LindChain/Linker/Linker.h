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

#ifndef LINDCHAIN_LINKER_LINKER_H
#define LINDCHAIN_LINKER_LINKER_H

#import <Foundation/Foundation.h>

@interface Linker : NSObject

@property (nonatomic,strong) NSString *error;

- (instancetype)init;
- (int)ld64:(NSMutableArray*)flags;

@end

#endif /* LINDCHAIN_LINKER_LINKER_H */
