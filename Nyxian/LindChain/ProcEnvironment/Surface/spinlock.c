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

#include <LindChain/ProcEnvironment/Surface/spinlock.h>

#pragma mark - spinlock helper

static inline void cpu_relax(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause");
#elif defined(__aarch64__)
    __asm__ volatile("yield");
#else
    // fallback: nothing
#endif
}

#pragma mark - spin baby, spin!

void spinlock_lock(spinlock_t *s)
{
    while(__atomic_exchange_n(&s->lock, 1, __ATOMIC_ACQUIRE) == 1)
    {
        cpu_relax();
    }
    __atomic_add_fetch(&s->seq, 1, __ATOMIC_RELEASE);
}

void spinlock_unlock(spinlock_t *s)
{
    __atomic_store_n(&s->lock, 0, __ATOMIC_RELEASE);
    __atomic_add_fetch(&s->seq, 1, __ATOMIC_RELEASE);
}

void spinlock_wait_for_unlock(const spinlock_t *s)
{
    while(__atomic_load_n(&s->lock, __ATOMIC_ACQUIRE) != 0)
    {
        cpu_relax();
    }
}

unsigned long spinlock_read_begin(const spinlock_t *s)
{
    unsigned long seq;

    while(1)
    {
        seq = __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE);
        if(seq & 1)
        {
            do
            {
                cpu_relax();
                seq = __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE);
            }
            while(seq & 1);
        }

        if (__atomic_load_n(&s->seq, __ATOMIC_ACQUIRE) == seq)
            return seq;
    }
}


bool spinlock_read_retry(const spinlock_t *s, unsigned long start_seq)
{
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
    return __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE) != start_seq;
}
