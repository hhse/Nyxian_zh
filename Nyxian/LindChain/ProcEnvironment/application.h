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

#ifndef PROCENVIRONMENT_APPLICATION_H
#define PROCENVIRONMENT_APPLICATION_H

/*!
 @function environment_application_init
 @abstract Initializes application environment.
 @discussion
    These fixes are supposed to fix headless programs. So they can choose if they rather wanna run a GUI or a CLI process or a being a background daemon.
 */
void environment_application_init(void);

#endif /* PROCENVIRONMENT_APPLICATION_H */
