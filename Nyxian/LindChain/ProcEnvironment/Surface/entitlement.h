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

#ifndef PROC_ENTITLEMENT_H
#define PROC_ENTITLEMENT_H

#import <Foundation/Foundation.h>
#include <stdint.h>

/*!
 @enum PEEntitlement
 @abstract Entitlements which are responsible for the permitives of the environment hostsided
 */
typedef NS_OPTIONS(uint64_t, PEEntitlement) {
    /*! Grants getting the task port of other processes that shared the same uid or have a higher uid. */
    PEEntitlementTaskForPid =       1ull << 0,
    
    /*! Grants getting the task port of any process, even processes with a lower uid, except the host task port.*/
    PEEntitlementTaskForPidPrvt =   1ull << 1,
    
    /*! Grants getting the task port of the host process. */
    PEEntitlementGetHostTaskPort =  1ull << 2,
    
    /*! Grants getting information from the surface. */
    PEEntitlementSurfaceRead =      1ull << 3,
    
    /*! Grants setting user identifier. */
    PEEntitlementSetUidAllowed =    1ull << 4,
    
    /*! Grants setting group identifier. */
    PEEntitlementSetGidAllowed =    1ull << 5,
    
    /*! Grants receiving signals from processes. */
    PEEntitlementRecvSignal    =    1ull << 6,
    
    /*! Grants sending signals to processes that shared the same uid or have a higher uid. */
    PEEntitlementSendSignal    =    1ull << 7,
    
    /*! Grants sending signals, even to processes that dont have PEEntitlementRecvSignal. And it grants sending signals to processes with lower uids aswell. */
    PEEntitlementSendSignalPrvt =   1ull << 8,
    
    /*! Grants spawning processes. */
    PEEntitlementSpawnProc     =    1ull << 9,
    
    /*! Grants all permissions over a child process. */
    PEEntitlementChildSupervisor =  1ull << 10,
    
    /*! Grants permissions to read from the trustcache */
    PEEntitlementTrustCacheRead = 1ull << 11,
    
    /*! Grants permissions to write to the trustcache */
    PEEntitlementTrustCacheWrite = 1ull << 12,
    
    /*! Grants all entitlements */
    PEEntitlementAll = (PEEntitlementTaskForPid | PEEntitlementTaskForPidPrvt | PEEntitlementGetHostTaskPort | PEEntitlementSurfaceRead | PEEntitlementSetUidAllowed | PEEntitlementSetGidAllowed | PEEntitlementRecvSignal | PEEntitlementSendSignal | PEEntitlementSendSignalPrvt | PEEntitlementSpawnProc | PEEntitlementChildSupervisor),
    
    /*! Grants access to user application permitives */
    PEEntitlementDefaultUserApplication = (PEEntitlementTaskForPid | PEEntitlementSurfaceRead | PEEntitlementRecvSignal | PEEntitlementSendSignal | PEEntitlementSpawnProc | PEEntitlementChildSupervisor),
    
    /*! Grants access to system application permitives */
    PEEntitlementDefaultSystemApplication = (PEEntitlementDefaultUserApplication | PEEntitlementTaskForPidPrvt | PEEntitlementGetHostTaskPort | PEEntitlementSetUidAllowed | PEEntitlementSetGidAllowed),
    
    /*! Fine tuned permitives for applicationmgmtd */
    PEEntitlementDefaultApplicationManagementDaemon = 0
};

bool proc_got_entitlement(pid_t pid, PEEntitlement entitlement);

bool entitlement_got_entitlement(PEEntitlement present, PEEntitlement needed);

#endif /* PROC_ENTITLEMENT_H */
