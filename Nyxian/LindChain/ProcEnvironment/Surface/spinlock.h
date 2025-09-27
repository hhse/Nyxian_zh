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

#ifndef PROCENVIRONMENT_SPINLOCK
#define PROCENVIRONMENT_SPINLOCK

#include <stdbool.h>

typedef struct {
    volatile int lock;
    volatile unsigned long seq;
} spinlock_t;

void spinlock_lock(spinlock_t *s);
void spinlock_unlock(spinlock_t *s);
void spinlock_wait_for_unlock(const spinlock_t *s);
unsigned long spinlock_read_begin(const spinlock_t *s);
bool spinlock_read_retry(const spinlock_t *s, unsigned long start_seq);

#endif /* PROCENVIRONMENT_SPINLOCK */
