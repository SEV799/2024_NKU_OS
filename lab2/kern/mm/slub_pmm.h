#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <pmm.h>

void slub_init(void);
struct Page *slub_alloc_pages(size_t n);
void slub_free_pages(struct Page *base, size_t n);
void slub_check(void);
size_t slub_nr_free_pages(void);
int slobfree_len(void);
extern const struct pmm_manager slub_pmm_manager;
#endif /* !__KERN_MM_SLUB_PMM_H__ */
