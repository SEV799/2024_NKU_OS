#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

#define MAX_ORDER 11  // 定义最大支持的块级别。块大小是2的幂次

free_area_t free_area[MAX_ORDER];  // 按块级别分配的空闲块数组

// 快捷宏定义
#define free_list(i) free_area[(i)].free_list  // 获取第i级的空闲链表
#define nr_free(i) free_area[(i)].nr_free      // 获取第i级的空闲块数
#define IS_POWER_OF_2(x) (!((x)&((x)-1)))      // 检查x是否为2的幂

// 伙伴系统初始化，清空所有级别的空闲链表，并将每级的空闲块数设为0
static void buddy_system_init(void) {
    for (int i = 0; i < MAX_ORDER; i++) {
        list_init(&(free_area[i].free_list));
        free_area[i].nr_free = 0;
    }
}

// 初始化内存块，按块大小从大到小分配到合适级别的链表中
static void buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);  // 确保块大小有效
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));  // 确保页面已被标记为保留
        p->flags = p->property = 0;  // 清除标志和属性
        set_page_ref(p, 0);  // 设置引用计数为0
    }

    // 初始化并插入块到适当链表
    size_t curr_size = n;
    uint32_t order = MAX_ORDER - 1;
    uint32_t order_size = 1 << order;
    p = base;
    while (curr_size != 0) {
        p->property = order_size;
        SetPageProperty(p);
        nr_free(order) += 1;
        list_add_before(&(free_list(order)), &(p->page_link));
        curr_size -= order_size;
        while (order > 0 && curr_size < order_size) {
            order_size >>= 1;
            order -= 1;
        }
        p += order_size;
    }
}

// 递归拆分高一级的块，将其分成两个较小块，并放入低一级链表中
static void split_page(int order) {
    if (list_empty(&(free_list(order)))) {  // 若高一级链表为空，则再递归调用下一高一级
        split_page(order + 1);
    }
    list_entry_t *le = list_next(&(free_list(order)));  // 取出链表的第一个块
    struct Page *page = le2page(le, page_link);
    list_del(&(page->page_link));  // 从链表中删除该块
    nr_free(order) -= 1;

    // 拆分块并插入到低一级链表
    uint32_t n = 1 << (order - 1);
    struct Page *p = page + n;
    page->property = n;
    p->property = n;
    SetPageProperty(p);
    list_add(&(free_list(order - 1)), &(page->page_link));
    list_add(&(page->page_link), &(p->page_link));
    nr_free(order - 1) += 2;
}

// 分配一块指定大小的页，如果对应大小的链表中没有块，则尝试从更大块拆分
static struct Page *buddy_system_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > (1 << (MAX_ORDER - 1))) {  // 超出最大可分配块大小
        return NULL;
    }
    struct Page *page = NULL;
    uint32_t order = MAX_ORDER - 1;
    while (n < (1 << order)) {
        order -= 1;
    }
    order += 1;

    // 检查是否有足够的空闲块可分配
    uint32_t flag = 0;
    for (int i = order; i < MAX_ORDER; i++) flag += nr_free(i);
    if (flag == 0) return NULL;

    // 如无合适块则拆分更高一级的块
    if (list_empty(&(free_list(order)))) {
        split_page(order + 1);
    }
    if (list_empty(&(free_list(order)))) return NULL;

    // 从链表中分配一块并返回
    list_entry_t *le = list_next(&(free_list(order)));
    page = le2page(le, page_link);
    list_del(&(page->page_link));
    ClearPageProperty(page);
    return page;
}

// 添加块到指定链表中，按地址顺序排列
static void add_page(uint32_t order, struct Page *base) {
    if (list_empty(&(free_list(order)))) {
        list_add(&(free_list(order)), &(base->page_link));
    } else {
        list_entry_t *le = &(free_list(order));
        while ((le = list_next(le)) != &(free_list(order))) {
            struct Page *page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &(free_list(order))) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

// 递归合并相邻的伙伴块，尝试将其合并到更高一级的链表中
static void merge_page(uint32_t order, struct Page *base) {
    if (order == MAX_ORDER - 1) {
        return;  // 达到最大级别，无法再升级
    }

    // 检查前一个块是否为伙伴块
    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &(free_list(order))) {
        struct Page *p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
            if (order != MAX_ORDER - 1) {
                list_del(&(base->page_link));
                add_page(order + 1, base);
            }
        }
    }

    // 检查后一个块是否为伙伴块
    le = list_next(&(base->page_link));
    if (le != &(free_list(order))) {
        struct Page *p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
            if (order != MAX_ORDER - 1) {
                list_del(&(base->page_link));
                add_page(order + 1, base);
            }
        }
    }
    merge_page(order + 1, base);
}

// 释放指定块并尝试合并
static void buddy_system_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(IS_POWER_OF_2(n));
    assert(n < (1 << (MAX_ORDER - 1)));
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);

    // 计算所需级别并合并
    uint32_t order = 0;
    size_t temp = n;
    while (temp != 1) {
        temp >>= 1;
        order++;
    }
    add_page(order, base);
    merge_page(order, base);
}

// 计算并返回所有空闲页的总数
static size_t buddy_system_nr_free_pages(void) {
    size_t num = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        num += nr_free(i) << i;
    }
    return num;
}

// 基础检查功能，用于测试分配器功能的正确性
static void basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    for (int i = 0; i < MAX_ORDER; i++) {
        list_init(&(free_area[i].free_list));
        free_area[i].nr_free = 0;
    }
}

// 提供全局指向分配器函数表的指针，允许通过函数表接口调用分配器函数
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = basic_check,
};


