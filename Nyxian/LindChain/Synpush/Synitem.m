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

#import <LindChain/Synpush/Synitem.h>

@implementation Synitem

+ (UInt8)SynitemLevelOfClangLevel:(NSString*)error
{
    if([error isEqual:@" error"])
        return 2;
    
    if([error isEqual:@" warning"])
        return 1;
    
    return 0;
}

+ (NSArray<Synitem*> *)OfClangErrorWithString:(NSString*)errorString
{
    NSMutableArray<Synitem*> *issues = [[NSMutableArray alloc] init];
    NSArray *errorLines = [errorString componentsSeparatedByString:@"\n"];
    
    for(NSString *line in errorLines)
    {
        NSArray *errorComponents = [line componentsSeparatedByString:@":"];
        if([errorComponents count] >= 5)
        {
            Synitem *item = [[Synitem alloc] init];
            item.line = [errorComponents[1] unsignedIntValue];
            item.column = [errorComponents[2] unsignedIntValue];
            item.type = [Synitem SynitemLevelOfClangLevel:errorComponents[3]];
            
            // MARK: Notes aint tracked anyways by Synpush and it must come as close to Synpush as possible
            if(item.type == 0)
                continue;
            
            NSRange messageRange = NSMakeRange(4, errorComponents.count - 4);
            item.message = [[errorComponents subarrayWithRange:messageRange] componentsJoinedByString:@":"];
            
            [issues addObject:item];
        }
    }
    
    return issues;
}

+ (void)OfClangErrorWithString:(NSString*)errorString usingArray:(NSMutableArray<Synitem*> **)issues
{
    NSArray *errorLines = [errorString componentsSeparatedByString:@"\n"];
    
    for(NSString *line in errorLines)
    {
        NSArray *errorComponents = [line componentsSeparatedByString:@":"];
        if([errorComponents count] >= 5)
        {
            Synitem *item = [[Synitem alloc] init];
            item.line = [errorComponents[1] unsignedIntValue];
            item.column = [errorComponents[2] unsignedIntValue];
            item.type = [Synitem SynitemLevelOfClangLevel:errorComponents[3]];
            
            // MARK: Notes aint tracked anyways by Synpush and it must come as close to Synpush as possible
            if(item.type == 0)
                continue;
            
            NSRange messageRange = NSMakeRange(4, errorComponents.count - 4);
            item.message = [[errorComponents subarrayWithRange:messageRange] componentsJoinedByString:@":"];
            
            [*issues addObject:item];
        }
    }
}

@end
