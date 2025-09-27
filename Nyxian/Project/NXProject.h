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

#ifndef NXPROJECT_H
#define NXPROJECT_H

#import <Foundation/Foundation.h>
#import <Project/NXPlistHelper.h>

typedef int NXProjectType NS_TYPED_ENUM;
static NXProjectType const NXProjectTypeApp = 1;

@interface NXProjectConfig : NXPlistHelper

@property (nonatomic,strong,readonly) NSString *executable;
@property (nonatomic,strong,readonly) NSString *displayName;
@property (nonatomic,strong,readonly) NSString *bundleid;
@property (nonatomic,strong,readonly) NSString *version;
@property (nonatomic,strong,readonly) NSString *shortVersion;
@property (nonatomic,strong,readonly) NSDictionary *infoDictionary;
@property (nonatomic,strong,readonly) NSString *platformTriple;
@property (nonatomic,strong,readonly) NSArray *compilerFlags;
@property (nonatomic,strong,readonly) NSArray *linkerFlags;
@property (nonatomic,strong,readonly) NSString *platformMinimumVersion;
@property (nonatomic,readonly) int type;
@property (nonatomic,readonly) int threads;
@property (nonatomic,readonly) BOOL increment;

// NONE PUBLIC FEATURES - NOT READY FOR PUBLIC
@property (nonatomic,readonly) BOOL debug;

- (NSMutableArray*)generateCompilerFlags;

@end

@interface NXCodeEditorConfig : NXPlistHelper

@property (nonatomic,readonly) BOOL showLine;
@property (nonatomic,readonly) BOOL showSpaces;
@property (nonatomic,readonly) BOOL showReturn;
@property (nonatomic,readonly) BOOL wrapLine;
@property (nonatomic,readonly) double fontSize;

// NONE PUBLIC FEATURES - NOT READY FOR PUBLIC
@property (nonatomic,readonly) BOOL autocompletion;

@end

@interface NXProject : NSObject

//@property (nonatomic,strong,readonly) UITableViewCell *tableCell;
@property (nonatomic,strong,readonly) NXProjectConfig *projectConfig;
@property (nonatomic,strong,readonly) NXCodeEditorConfig *codeEditorConfig;

@property (nonatomic,strong,readonly) NSString *path;
@property (nonatomic,strong,readonly) NSString *cachePath;
@property (nonatomic,strong,readonly) NSString *resourcesPath;
@property (nonatomic,strong,readonly) NSString *payloadPath;
@property (nonatomic,strong,readonly) NSString *bundlePath;
@property (nonatomic,strong,readonly) NSString *machoPath;
@property (nonatomic,strong,readonly) NSString *packagePath;
@property (nonatomic,strong,readonly) NSString *homePath;
@property (nonatomic,strong,readonly) NSString *temporaryPath;
@property (nonatomic,strong,readonly) NSString *uuid;

- (instancetype)initWithPath:(NSString*)path;

+ (NXProject*)createProjectAtPath:(NSString*)path
                         withName:(NSString*)name
             withBundleIdentifier:(NSString*)bundleid
                         withType:(NXProjectType)type;
+ (NSMutableArray<NXProject*>*)listProjectsAtPath:(NSString*)path;
+ (void)removeProject:(NXProject*)project;

- (BOOL)reload;

@end

#endif /* NXPROJECT_H */
