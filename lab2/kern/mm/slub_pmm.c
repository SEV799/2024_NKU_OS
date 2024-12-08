#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <pmm.h>
#include <stdio.h>

#define SLUB_MAX_ORDER 10 // 定义最大阶数为10，相当于2^10个页面

// 定义SLUB内存块结构体
struct slob_block {
    int units;              // 块的大小，以sizeof(slob_t)为单位
    struct slob_block *next;// 下一个SLUB块
};
typedef struct slob_block slob_t;

// 定义单个SLUB单元的大小
#define SLOB_UNIT sizeof(slob_t)
// 计算所需SLUB单元的数量
#define SLOB_UNITS(size) (((size) + SLOB_UNIT - 1)/SLOB_UNIT)

// 定义大内存块结构体
struct bigblock {
    int order;             // 页面数量的对数
    void *pages;           // 页面起始地址
    struct bigblock *next;// 下一个大内存块
};
typedef struct bigblock bigblock_t;

// 定义SLUB内存分配器的管理结构体
typedef struct {
    list_entry_t free_list; // 空闲列表
    bigblock_t *bigblocks; // 大内存块链表
    unsigned int nr_free;   // 空闲内存块数量
} slub_manager_t;

// 创建全局SLUB管理器实例
static slub_manager_t slub_manager = {
    .free_list = {0},
    .bigblocks = NULL,
    .nr_free = 0,
};

// 初始化SLUB分配器
static void
slub_init(void) {
    list_init(&slub_manager.free_list);
    slub_manager.bigblocks = NULL;
    slub_manager.nr_free = 0;
    cprintf("SLUB init succeeded!\n");
}

// 初始化物理内存映射
static void
slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    slub_manager.nr_free += n;
    list_add_before(&(slub_manager.free_list), &(base->page_link));
}

// 分配页面
static struct Page *
slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > (1 << SLUB_MAX_ORDER)) {
        return NULL;
    }

    struct Page *page = NULL;
    list_entry_t *le = list_next(&(slub_manager.free_list));
    while (le != &(slub_manager.free_list)) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
        le = list_next(le);
    }

    if (page) {
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(&(slub_manager.free_list), &(p->page_link));
        }
        ClearPageProperty(page);
        slub_manager.nr_free -= n;
    } else {
        page = alloc_pages(n);
        if (page) {
            slub_init_memmap(page, n);
            slub_manager.nr_free -= n;
        }
    }
    return page;
}

// 释放页面
static void
slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    if (n > (1 << SLUB_MAX_ORDER)) {
        return;
    }

    base->property = n;
    SetPageProperty(base);
    slub_manager.nr_free += n;
    list_add(&(slub_manager.free_list), &(base->page_link));

    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &(slub_manager.free_list)) {
        struct Page *p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += n;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &(slub_manager.free_list)) {
        struct Page *p = le2page(le, page_link);
        if (base + n == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

// 获取当前空闲页面的数量
static size_t
slub_nr_free_pages(void) {
    return slub_manager.nr_free;
}

// 定义SLUB内存分配器的接口结构体
const struct pmm_manager slub_pmm_manager = {
    .name = "SLUB PMM Manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
};
