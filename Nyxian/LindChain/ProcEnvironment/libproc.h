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

#ifndef PROCENVIRONMENT_LIBPROC_H
#define PROCENVIRONMENT_LIBPROC_H

/*!
 @function environment_proc_listallpids
 @abstract Takes in a preallocated buffer and writes all pids on it depending on the size that run on proc surface.
 */
int environment_proc_listallpids(void *buffer, int buffersize);

/*!
 @function environment_libproc_init
 @abstract Initializes the libproc environment.
 */
void environment_libproc_init(void);

#endif /* PROCENVIRONMENT_LIBPROC_H */
