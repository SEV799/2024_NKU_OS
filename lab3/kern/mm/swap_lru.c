#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

extern list_entry_t pra_list_head;

// LRU页面置换算法初始化函数
static int _lru_init_mm(struct mm_struct* mm)
{
    list_init(&pra_list_head);// 初始化链表头节点
    mm->sm_priv = &pra_list_head;// 将链表头节点地址保存到mm结构体中
    return 0;
}

// 将页面加入到LRU链表中
static int _lru_map_swappable(struct mm_struct* mm, uintptr_t addr, struct Page* page, int swap_in)
{
    list_entry_t* head = (list_entry_t*)mm->sm_priv;// 获取链表头节点
    list_entry_t* entry = &(page->pra_page_link);// 获取页面的链表节点

    assert(entry != NULL && head != NULL);// 断言检查，确保链表节点不为空
    list_add((list_entry_t*)mm->sm_priv, entry);// 将页面加入到链表中
    return 0;
}

// 从LRU链表中选择一个页面进行置换
static int _lru_swap_out_victim(struct mm_struct* mm, struct Page** ptr_page, int in_tick)
{
    list_entry_t* head = (list_entry_t*)mm->sm_priv;// 获取链表头节点
    assert(head != NULL);// 断言检查，确保链表头节点不为空
    assert(in_tick == 0);// 断言检查，确保in_tick为0
    list_entry_t* entry = list_prev(head);// 获取链表中最后一个元素（即最不常用的页面）
    if (entry != head) {
        list_del(entry);// 从链表中删除该页面节点
        *ptr_page = le2page(entry, pra_page_link);// 将链表节点转换为页面结构体
    }
    else {
        *ptr_page = NULL;// 如果链表为空，则返回NULL
    }
    return 0;
}

// 打印LRU链表中的所有页面
static void print_mm_list() {
    cprintf("--------begin----------\n");// 打印开始标识
    list_entry_t* head = &pra_list_head, * le = head;// 获取链表头节点
    while ((le = list_next(le)) != head)// 遍历链表
    {
        struct Page* page = le2page(le, pra_page_link);// 将链表节点转换为页面结构体
        cprintf("vaddr: 0x%x\n", page->pra_vaddr);// 打印页面的虚拟地址
    }
    cprintf("---------end-----------\n");// 打印结束标识
}

// 测试LRU页面置换算法的函数
static int _lru_check_swap(void) {
    print_mm_list();// 打印当前LRU链表

    // 以下代码模拟对不同页面的访问，观察LRU链表的变化
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char*)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char*)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char*)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char*)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char*)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char*)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char*)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char*)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char*)0x4000 = 0x0d;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char*)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char*)0x1000 == 0x0a);
    *(unsigned char*)0x1000 = 0x0a;
    print_mm_list();
    return 0;
}

// LRU页面置换算法初始化函数
static int
_lru_init(void)
{
    return 0;
}

// 设置页面为不可置换
static int _lru_set_unswappable(struct mm_struct* mm, uintptr_t addr)
{
    return 0;
}

// 处理时钟事件
static int _lru_tick_event(struct mm_struct* mm)
{
    return 0;
}

// 设置所有页面不可读
static int unable_page_read(struct mm_struct* mm) {
    list_entry_t* head = (list_entry_t*)mm->sm_priv, * le = head;// 获取链表头节点
    while ((le = list_prev(le)) != head)// 遍历链表
    {
        struct Page* page = le2page(le, pra_page_link);// 将链表节点转换为页面结构体
        pte_t* ptep = NULL;// 定义页表项指针
        ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);// 获取页表项
        *ptep &= ~PTE_R;// 清除页表项的可读权限
    }
    return 0;
}

// 处理页面错误
int lru_pgfault(struct mm_struct* mm, uint_t error_code, uintptr_t addr) {
    cprintf("lru page fault at 0x%x\n", addr);// 打印页面错误信息
    // 如果已经初始化了交换空间，则设置所有页面不可读
    if (swap_init_ok)
        unable_page_read(mm);
    // 获取页表项
    pte_t* ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
    *ptep |= PTE_R;// 设置页表项为可读
    if (!swap_init_ok)
        return 0;// 如果没有初始化交换空间，则直接返回
    struct Page* page = pte2page(*ptep);// 将页表项转换为页面结构体
    // 在LRU链表中找到该页面，并将其移动到链表头部
    list_entry_t* head = (list_entry_t*)mm->sm_priv, * le = head;
    while ((le = list_prev(le)) != head)
    {
        struct Page* curr = le2page(le, pra_page_link);// 将链表节点转换为页面结构体
        if (page == curr) {

            list_del(le);// 从链表中删除该页面节点
            list_add(head, le);// 将该页面节点添加到链表头部
            break;
        }
    }
    return 0;
}

// 定义LRU页面置换算法的管理结构体
struct swap_manager swap_manager_lru =
{
    .name = "lru swap manager",// 管理器名称
    .init = &_lru_init,// 初始化函数
    .init_mm = &_lru_init_mm,// 初始化内存管理结构体函数
    .tick_event = &_lru_tick_event,// 时钟事件处理函数
    .map_swappable = &_lru_map_swappable,// 将页面加入到可置换列表函数
    .set_unswappable = &_lru_set_unswappable,// 设置页面为不可置换函数
    .swap_out_victim = &_lru_swap_out_victim,// 选择一个页面进行置换函数
    .check_swap = &_lru_check_swap,// 测试页面置换算法函数
};
