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

#include <LindChain/ProcEnvironment/Surface/memfd.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <limits.h>

int memfd_create(const char *name,
                 unsigned int flags)
{
    // Creating temporary file path and appending name to it
    const char *temporaryDirectory = getenv("TMPDIR");
    char path[PATH_MAX];
    snprintf(path, PATH_MAX, "%s/%s", temporaryDirectory, name);
    
    // Opening "real" file descriptor
    int fd = open(path, flags, 0777);
    
    // Forcing the operating system to make it a anonymous file descriptor
    if(unlink(path) == -1) return -1;
    
    // Return if fcntl says that its a valid file descriptor
    return (fcntl(fd, F_GETFD) == -1) ? -1 : fd;
}
