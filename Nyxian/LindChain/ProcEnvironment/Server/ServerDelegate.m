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

#import <LindChain/ProcEnvironment/Server/ServerDelegate.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>

@implementation ServerDelegate

- (instancetype)init
{
    self = [super init];
    _pidHistory = [[NSMutableSet alloc] init];
    return self;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    // Getting requestors pid
    pid_t requestorPid = newConnection.processIdentifier;
    
    // Checking if valid, if it is adding it to the pid history
    if(requestorPid == 0 || [_pidHistory containsObject:@(requestorPid)]) return NO;
    [_pidHistory addObject:@(requestorPid)];
    
    // Setting protocol interface
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ServerProtocol)];
    
    // Setting up server session
    Server *serverSession = [[Server alloc] init];
    serverSession.processIdentifier = requestorPid;
    
    // Set exported object to the created server session
    newConnection.exportedObject = serverSession;
    
    // Resume connection
    [newConnection resume];
    
    return YES;
}

- (NSXPCListener*)createAnonymousListener
{
    static NSXPCListener *listener = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        listener = [NSXPCListener anonymousListener];
        listener.delegate = self;
        [listener resume];
    });
    return listener;
}

+ (NSXPCListenerEndpoint*)getEndpoint
{
    static ServerDelegate *delegate = nil;
    static NSXPCListener *listener = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [[ServerDelegate alloc] init];
        listener = [NSXPCListener anonymousListener];
        listener.delegate = delegate;
        [listener resume];
    });
    return listener.endpoint;
}

@end
