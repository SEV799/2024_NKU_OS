#include <cow.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));
}

// 检查是否是内核线程，若是则直接返回
int check_if_kernel_thread(struct mm_struct *oldmm) {
    if (oldmm == NULL) {
        return 0;  // 如果是内核线程，直接返回
    }
    return 1;
}

// 创建新的内存管理结构
struct mm_struct *create_new_mm() {
    struct mm_struct *mm = mm_create();
    return mm;
}

// 设置新的页目录
int setup_new_pgdir(struct mm_struct *mm) {
    return setup_pgdir(mm);
}

// 锁定内存管理结构
void lock_old_mm(struct mm_struct *oldmm) {
    lock_mm(oldmm);
}

// 解锁内存管理结构
void unlock_old_mm(struct mm_struct *oldmm) {
    unlock_mm(oldmm);
}

// 复制内存映射
int copy_mmap(struct mm_struct *mm, struct mm_struct *oldmm) {
    return cow_copy_mmap(mm, oldmm);
}

// 增加内存管理结构的引用计数
void increment_mm_ref_count(struct mm_struct *mm) {
    mm_count_inc(mm);
}

// 设置进程的内存管理结构和 CR3 寄存器
void set_proc_mm_and_cr3(struct proc_struct *proc, struct mm_struct *mm) {
    proc->mm = mm;
    proc->cr3 = PADDR(mm->pgdir);
}

// 清理内存映射
void cleanup_mmap(struct mm_struct *mm) {
    exit_mmap(mm);
}

// 清理页目录
void cleanup_pgdir(struct mm_struct *mm) {
    put_pgdir(mm);
}

// 销毁内存管理结构
void destroy_mm(struct mm_struct *mm) {
    mm_destroy(mm);
}

// 主函数，负责复制内存管理结构
int cow_copy_mm(struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;

    // 检查是否是内核线程
    if (!check_if_kernel_thread(oldmm)) {
        return 0;
    }

    int ret = 0;

    // 创建新的内存管理结构
    if ((mm = create_new_mm()) == NULL) {
        goto bad_mm;
    }

    // 设置新的页目录
    if (setup_new_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }

    // 锁定原进程的内存管理结构
    lock_old_mm(oldmm);

    // 复制内存映射
    ret = copy_mmap(mm, oldmm);

    // 解锁原进程的内存管理结构
    unlock_old_mm(oldmm);

    // 如果内存映射复制失败，进行清理
    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    // 增加内存管理结构的引用计数
    increment_mm_ref_count(mm);

    // 设置进程的内存管理结构和 CR3 寄存器
    set_proc_mm_and_cr3(proc, mm);

    return 0;  // 返回成功

bad_dup_cleanup_mmap:
    // 清理内存映射
    cleanup_mmap(mm);

    // 清理页目录
    cleanup_pgdir(mm);

bad_pgdir_cleanup_mm:
    // 销毁内存管理结构
    destroy_mm(mm);

bad_mm:
    return ret;  // 返回错误码
}

int
cow_copy_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }
        insert_vma_struct(to, nvma);
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0;
}

// 检查地址是否有效，并获取页表项
pte_t *get_valid_pte(pde_t *pgdir, uintptr_t addr) {
    pte_t *ptep = get_pte(pgdir, addr, 0);  // 获取页表项
    if (ptep == NULL) {
        return NULL;  // 如果页表项为空，返回NULL
    }
    return ptep;
}

// 检查页面是否有效
int check_and_prepare_page(pte_t *ptep, uintptr_t *start, uint32_t *perm) {
    if (*ptep & PTE_V) {  // 如果该页是有效的
        *ptep &= ~PTE_W;  // 只读权限，清除写权限
        *perm = (*ptep & PTE_USER & ~PTE_W);  // 计算新的权限
        return 0;  // 成功
    }
    return -1;  // 如果页表项无效，返回错误
}

// 进行页面复制操作
int insert_page(pde_t *to, pte_t *ptep, uintptr_t start, uint32_t perm) {
    struct Page *page = pte2page(*ptep);  // 获取页面结构
    assert(page != NULL);  // 确保页面结构有效
    int ret = page_insert(to, page, start, perm);  // 将页面插入目标页表
    assert(ret == 0);  // 确保页面插入成功
    return ret;
}

// 复制内存范围
int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);  // 确保起始地址和结束地址是页面大小的倍数
    assert(USER_ACCESS(start, end));  // 确保访问的地址范围是合法的用户空间范围

    while (start < end) {  // 遍历整个内存范围
        pte_t *ptep = get_valid_pte(from, start);  // 获取源进程的页表项
        if (ptep == NULL) {  // 如果没有对应的页表项
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);  // 跳到下一页
            continue;
        }

        uint32_t perm;
        if (check_and_prepare_page(ptep, &start, &perm) == 0) {  // 如果页表项有效并且准备好权限
            insert_page(to, ptep, start, perm);  // 将页面插入目标页表
        }
        start += PGSIZE;  // 处理下一个页面
    }
    return 0;  // 返回成功
}


// 打印页故障的地址
void print_page_fault(uintptr_t addr) {
    cprintf("COW page fault at 0x%x\n", addr);
}

// 获取页表项
pte_t *get_pte_for_fault(struct mm_struct *mm, uintptr_t addr) {
    return get_pte(mm->pgdir, addr, 0);
}

// 设置页面的写权限
uint32_t set_write_permission(pte_t *ptep) {
    return (*ptep & PTE_USER) | PTE_W;
}

// 分配新的页面
struct Page *allocate_new_page() {
    struct Page *npage = alloc_page();
    assert(npage != NULL);  // 确保新页面有效
    return npage;
}

// 复制原页面内容到新页面
void copy_page_content(struct Page *page, struct Page *npage) {
    uintptr_t* src = page2kva(page);  // 获取原页面的内核虚拟地址
    uintptr_t* dst = page2kva(npage);  // 获取新页面的内核虚拟地址
    memcpy(dst, src, PGSIZE);  // 将原页面内容复制到新页面
}

// 插入新页面到页表
int insert_new_page_to_pgdir(struct mm_struct *mm, struct Page *npage, uintptr_t start, uint32_t perm) {
    return page_insert(mm->pgdir, npage, start, perm);
}

// 处理COW页面故障
int cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    print_page_fault(addr);  // 打印页故障的地址
    int ret = 0;
    // 获取页表项
    pte_t *ptep = get_pte_for_fault(mm, addr);
    // 设置新的权限，允许写操作
    uint32_t perm = set_write_permission(ptep);
    // 获取原页面结构
    struct Page *page = pte2page(*ptep);
    // 分配新页面
    struct Page *npage = allocate_new_page();
    // 确保原页面有效
    assert(page != NULL);  
    // 复制页面内容
    copy_page_content(page, npage);
    // 获取页面对齐的起始地址
    uintptr_t start = ROUNDDOWN(addr, PGSIZE);
    // 清空页表项
    *ptep = 0;
    // 将新页面插入页表
    ret = insert_new_page_to_pgdir(mm, npage, start, perm);
    // 重新获取页表项
    ptep = get_pte(mm->pgdir, addr, 0);

    return ret;  // 返回结果
}


