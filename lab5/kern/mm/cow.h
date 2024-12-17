#ifndef COW_H
#define COW_H


#include <mmu.h>
#include <vmm.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <proc.h>
#include <assert.h>

/*
 * COW机制中的关键函数定义
 * 
 * 1. setup_pgdir:
 *    创建新过程的页目对应的页目。
 * 
 * 2. put_pgdir:
 *    释放一个过程的页目。
 *
 * 3. cow_copy_mm:
 *    复制过程的内存管理为源过程的公共内存。
 *
 * 4. cow_copy_mmap:
 *    复制过程中的虚拟内存区域(VMA)和页表。
 *
 * 5. cow_copy_range:
 *    复制特定内存区域中的页表。
 *
 * 6. cow_pgfault:
 *    处理写日志时的页错误。
 */



// 处理复制过程的内存管理
int cow_copy_mm(struct proc_struct *proc);

// 复制 VMA 和页表
int cow_copy_mmap(struct mm_struct *to, struct mm_struct *from);

// 复制特定区域的页表
int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end);

// 处理页错误
int cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

#endif // COW_H


