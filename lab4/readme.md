# 第四次实验报告

## lab4:进程管理

### 一、实验目的

- 了解内核线程创建/执行的管理过程
- 了解内核线程的切换和基本调度过程

### 二、实验环境

VMware fusion 、Ubuntu 22.04 、RISC-V 、QEMU

### 三、实验步骤

填写已有实验后，按练习与源码中提示信息编写代码即可。

### 四、练习回答

#### 练习0：填写已有实验

本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

**这次主要是将Lab3/kern/mm/vmm.c的do_pgfault补充完整。**

#### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

```c
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state = PROC_UNINIT;  //设置进程状态为未初始化
    proc->pid = -1;     //设置进程ID为-1（还未分配）
    proc->runs = 0;     //设置进程运行次数为0
    proc->kstack = 0;   //设置内核栈地址为0（还未分配）
    proc->need_resched = 0;     //设置无需重新调度
    proc->parent=NULL;      //设置父进程为控
    proc->mm = NULL;        //设置内存管理字段为控
    memset(&(proc->context),0,sizeof(struct context));      //初始化上下文信息为0
    proc->tf = NULL;    //设置trapframe为控
    proc->cr3 = boot_cr3;       //设置CR3寄存器的值（页目录基址）
    proc->flags = 0;       //设置进程标志为0
    memset(proc->name,0,PROC_NAME_LEN);     //初始化进程名为0
    }
    return proc;    //返回新分配的进程控制块
}
```

首先，调用kmalloc函数为改进程分配一个proc struct结构体所需要的内存大小如果分配成功，即proc的值不为空，则需要进行该进程初始化的变量及其值分别为:

+ state设置为PROC UNINIT，即其状态为未进行初始化;
+  pid设置为-1，表示进程pid的还未初始化;
+ runs设置为0，表示该进程被运行的次数为0;
+ kstack设置为0，代表还没有给该进程分配内核栈(因此内核的位置未知)0
+ need resched设置为0，代表该进程不需要调用schedule来释放自己所占用的CPU资源
+ parent设置为NULL，代表该进程没有父进程，
+ mm设置为NULL，代表还未给该进程准备好内存管理;
+ context在这里被使用memset进行了数据清零操作，代表为该进程准备了新的空白上下文;
+ tf设置为NULL，代表还未给该进程分配中断帧;
+ cr3设置为boot cr3，代表该进程使用的是内核页目录表。
+ flags设置为0，代表该进程还未被设置任何标志;
+ name在这里被使用memset进行数据清零操作，方便后续设置新的进程名 最后我们把该进程的指针返回。

```c
//见指导书lab4：设计关键数据结构--进程控制块  
struct proc_struct {
    enum proc_state state;                  // Process state
    int pid;                                // Process ID
    int runs;                               // the running times of Proces
    uintptr_t kstack;                       // Process kernel stack
    volatile bool need_resched;             // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;             // the parent process
    struct mm_struct *mm;                   // Process's memory management field
    struct context context;                 // Switch here to run process
    struct trapframe *tf;                   // Trap frame for current interrupt
    uintptr_t cr3;                          // CR3 register: the base addr of Page Directroy Table(PDT)
    uint32_t flags;                         // Process flag
    char name[PROC_NAME_LEN + 1];           // Process name
    list_entry_t list_link;                 // Process link list 
    list_entry_t hash_link;                 // Process hash list
};
```

context：context中保存了进程执行的上下文，也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态（进程切换的详细过程在后面会介绍）。切换过程的实现在kern/process/switch.S
tf：tf里保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中（注意这里需要保存的执行状态数量不同于上下文切换）。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。

context用于保存进程上下文使用结构体struct context保存，其中包含了ra，sp，s0~s11共14个寄存器。我们不需要保存所有的寄存，因为我们巧妙地利用了编译器对于函数的处理。寄存器可以分为调用者保存(caller-saved)寄存器和被调用者保存(callee-saved)寄存器。因为线程切换在一个函数当中，所以编译器会自动帮助我们生成保存和恢复调用者保存寄存器的代码，在实际的进程切换过程中我们只需要保存被调用者保存寄存器。
在本实验中，当idle进程被CPU切换为init进程时，将idle进程的上下文就会保存在 idle_proc->context 中，如果uCore调度器选择了idle_proc执行，就要根据 idle_proc->context 恢复现场，继续执行，具体的切换过程体现在switch.S中的switch to函数中。
tf保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中(注意这里需要保存的执行状态数量不同于上下文切换)。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。
在本次实验中，在我们进行进程切换的时候，switch to函数运行的最后会返回到forket函数中而这个时候我们会把此次中断的中断帧置于a0寄存器中，这样在执行trapret函数的时候，就会利用这个中断帧返回到指定的位置、以特定的参数执行某个函数。

#### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

#### 代码编写

```c
// 分配一个新的进程控制块（proc_struct）
proc = alloc_proc();

// 将新进程的父进程设置为当前进程
proc->parent = current;

// 为新进程分配内核栈。
setup_kstack(proc);

// 根据 clone_flags 决定是复制还是共享内存管理信息（mm）结构。
copy_mm(clone_flags, proc);

// 设置新进程的线程信息，包括在新进程的内核栈顶部设置陷阱帧（tf）和内核入口点。
copy_thread(proc, stack, tf);

// 获取一个唯一的进程ID
int pid = get_pid();

// 将获取到的唯一PID赋值给新进程的 pid 字段
proc->pid = pid;

// 将新进程加入到进程的哈希表中
hash_proc(proc);

// 将新进程加入到进程列表 proc_list 中
list_add(&proc_list, &(proc->list_link));

// 增加系统中进程的数量。
nr_process++;

// 将新进程的状态设置为 PROC_RUNNABLE，表示新进程已经准备好被调度执行（这里没有找到wakeup_proc函数，所以直接赋值）
proc->state = PROC_RUNNABLE;

// 将新进程的PID作为函数的返回值
ret = proc->pid;
```

#### 回答问题

ucore操作系统确实为每个新fork的进程分配了一个唯一的ID。do_fork函数调用get_pid函数来为进程赋予pid，而get_pid函数先是使用断言static_assert(MAX_PID > MAX_PROCESS)确保定义的最大PID数量大于最大进程数量，之后使用变量last_pid 和 next_safe 用于记录上一次分配的PID和下一个安全的PID值，接下来last_pid 自增，如果超过了 MAX_PID，则重置为1。这确保了PID在1到MAX_PID之间循环，最后检查PID是否可用，如果 last_pid 大于或等于 next_safe，则需要重新扫描进程列表以找到下一个安全的PID并通过遍历进程列表 proc_list，检查每个进程的PID（如果发现有进程的PID等于 last_pid，则自增 last_pid 并重新扫描，如果发现有进程的PID大于 last_pid 且小于 next_safe，则更新 next_safe 为该进程的PID）通过分析get_pid函数函数的实现可以知道它确保了每个新fork的进程都能获得一个唯一的PID。既考虑了PID的循环使用，也确保了在任何时候都能快速找到一个唯一的PID，从而避免了PID冲突。

#### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

#### 代码

```c
// proc_run - 用来切换到一个新的进程（线程）
void proc_run(struct proc_struct *proc) {
    // 首先判断要切换到的进程是不是当前进程，若是则不需进行任何处理。
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        local_intr_save(intr_flag); // 关闭中断

        struct proc_struct *prev = current; // 保存当前进程
        struct proc_struct *next = proc;    // 保存下一个进程

        current = proc; // 将当前进程设置为下一个进程
        lcr3(proc->cr3);    // 切换到下一个进程的页表
        switch_to(&(prev->context), &(next->context));  // 进行上下文切换

        local_intr_restore(intr_flag);  // 开启中断
    }
}
```

`proc_run` 主要在操作系统中切换到一个新的进程（线程）。它的主要作用是：

1. 检查目标进程是否已经是当前进程，如果是，则无需任何操作。
2. 如果目标进程不是当前进程：
   - 保存中断状态并关闭中断，确保切换过程中不会被打断。
   - 保存当前进程的信息（`prev`）和目标进程的信息（`next`）。
   - 更新全局变量 `current` 为目标进程。
   - 调用 `lcr3` 切换到目标进程的页表，确保其虚拟地址空间正确映射。
   - 调用 `switch_to` 执行上下文切换，保存当前进程寄存器并加载目标进程的寄存器。
   - 恢复之前的中断状态。

**过程**

1. **中断管理**：

   ```c
   local_intr_save(intr_flag);
   local_intr_restore(intr_flag);
   ```

   - **关闭中断**：防止在上下文切换过程中出现中断，影响切换的正确性。
   - **恢复中断**：切换完成后恢复之前的中断状态。

2. **页表切换**：

   ```c
   lcr3(proc->cr3);
   ```

   - **作用**：修改页表基地址寄存器（`CR3`），切换到目标进程的地址空间。
   - **意义**：多进程操作系统中，每个进程有自己的地址空间，切换页表保证目标进程运行时的虚拟地址访问正确映射。

3. **上下文切换**：

   ```c
   switch_to(&(prev->context), &(next->context));
   ```

   - **作用**：保存当前进程的寄存器状态到 `prev->context`，并从 `next->context` 加载目标进程的寄存器状态。
   - **意义**：实现从当前进程切换到目标进程，目标进程可以从切换点继续执行。

#### 相关宏与函数的阅读

`/kern/sync/sync.h`定义的宏`local_intr_save(x)`和`local_intr_restore(x)`

```c
#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <riscv.h>

// 保存中断状态
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

// 恢复中断状态
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ *
```

##### 宏 `local_intr_save(x)`

1. 调用 

   ```
   __intr_save()
   ```

    函数，检查当前是否启用了中断。

   - 如果中断启用 (`SSTATUS_SIE` 标志位为 1)，则调用 `intr_disable()` 禁用中断，并返回 `1`。
   - 如果中断未启用，则直接返回 `0`。

2. 将 `__intr_save()` 的返回值存储在变量 `x` 中，以便后续恢复原始中断状态。

**作用：**

- 保存当前的中断状态，并根据需要禁用中断。
- 确保代码进入临界区时，中断被关闭，防止并发访问引发的竞态条件。

------

##### 宏 `local_intr_restore(x)`

1. 调用 

   ```
   __intr_restore(x)
   ```

    函数。

   - 如果传入的 `x` 为 `true` (`1`)，则恢复中断（调用 `intr_enable()`）。
   - 如果传入的 `x` 为 `false` (`0`)，则不启用中断，保持中断关闭状态。

作用：

- 恢复 `local_intr_save(x)` 宏保存的中断状态，确保退出临界区后系统恢复到原始状态。

##### `/libs/riscv.h`中提供的`lcr3(unsigned int cr3)`函数

```c
#define write_csr(reg, val) ({ \
  asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })


static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
}

```

**`write_csr` 宏**
宏 `write_csr(reg, val)` 将指定的值 `val` 写入 CSR 寄存器 `reg`。

- `csrw` 指令是 RISC-V 用于写入 CSR 的汇编指令。
- `#reg` 代表目标 CSR 寄存器的名称，例如 `sptbr`。
- `"rK"` 限制表示参数 `val` 可以是寄存器值或常数。

**`lcr3` 函数实现**

1. **`cr3` 参数：**
   表示一个页表基地址（通常是物理地址）。
2. **页表基地址处理：**
   - 将 `cr3` 向右移位 `RISCV_PGSHIFT` 位（通常等于页面大小的对齐偏移，例如 12 位）。这将页表基地址对齐到页表要求的页大小边界。
3. **模式设置：**
   - 将页表基地址与 `SATP32_MODE` 按位或操作，设置页表工作模式。`SATP32_MODE` 是一个宏，指定页表管理的模式（例如 RISC-V Sv32 模式）。
4. **写入 `sptbr`：**
   - 将生成的值写入 `sptbr`（Supervisor Page Table Base Register），该寄存器存储页表的基地址。

##### `/kern/process/switch.S`定义的`switch_to()`函数

```assembly
#include <riscv.h>

.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)    // a0 is from
    STORE sp, 1*REGBYTES(a0)
    STORE s0, 2*REGBYTES(a0)
    STORE s1, 3*REGBYTES(a0)
    STORE s2, 4*REGBYTES(a0)
    STORE s3, 5*REGBYTES(a0)
    STORE s4, 6*REGBYTES(a0)
    STORE s5, 7*REGBYTES(a0)
    STORE s6, 8*REGBYTES(a0)
    STORE s7, 9*REGBYTES(a0)
    STORE s8, 10*REGBYTES(a0)
    STORE s9, 11*REGBYTES(a0)
    STORE s10, 12*REGBYTES(a0)
    STORE s11, 13*REGBYTES(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
    LOAD sp, 1*REGBYTES(a1)
    LOAD s0, 2*REGBYTES(a1)
    LOAD s1, 3*REGBYTES(a1)
    LOAD s2, 4*REGBYTES(a1)
    LOAD s3, 5*REGBYTES(a1)
    LOAD s4, 6*REGBYTES(a1)
    LOAD s5, 7*REGBYTES(a1)
    LOAD s6, 8*REGBYTES(a1)
    LOAD s7, 9*REGBYTES(a1)
    LOAD s8, 10*REGBYTES(a1)
    LOAD s9, 11*REGBYTES(a1)
    LOAD s10, 12*REGBYTES(a1)
    LOAD s11, 13*REGBYTES(a1)

    ret
```

`switch_to` 函数是一个上下文切换函数，在操作系统中用于从一个进程（`from`）的上下文切换到另一个进程（`to`）的上下文。它保存当前进程的寄存器状态到 `from` 指向的数据结构，并加载另一个进程的寄存器状态到 CPU 寄存器，以恢复执行

1. **函数原型**：

   ```c
   void switch_to(struct proc_struct* from, struct proc_struct* to);
   ```

   - `from` 是指向当前正在运行的进程结构体的指针。
   - `to` 是指向目标进程结构体的指针。

2. **关键步骤**：

   - **保存 `from` 进程的寄存器上下文**：

     ```assembly
     STORE ra, 0*REGBYTES(a0)    # 保存返回地址寄存器 ra
     STORE sp, 1*REGBYTES(a0)    # 保存堆栈指针 sp
     STORE s0, 2*REGBYTES(a0)    # 保存保存寄存器 s0
     ...
     STORE s11, 13*REGBYTES(a0)  # 保存保存寄存器 s11
     ```

     - 使用 `STORE` 指令将寄存器内容存储到 `from` 的内存位置。
     - 假定 `a0` 存储了 `from` 的地址，`REGBYTES` 是每个寄存器所占字节数（通常是 4 或 8）。

   - **恢复 `to` 进程的寄存器上下文**：

     ```assembly
     LOAD ra, 0*REGBYTES(a1)     # 恢复返回地址寄存器 ra
     LOAD sp, 1*REGBYTES(a1)     # 恢复堆栈指针 sp
     LOAD s0, 2*REGBYTES(a1)     # 恢复保存寄存器 s0
     ...
     LOAD s11, 13*REGBYTES(a1)   # 恢复保存寄存器 s11
     ```

     - 使用 `LOAD` 指令将寄存器内容从 `to` 的内存位置加载到 CPU 寄存器。
     - 假定 `a1` 存储了 `to` 的地址。

   - **返回到新上下文**：

     ```assembly
     ret
     ```

     - `ret` 指令跳转到 `to` 进程的保存上下文中的返回地址，继续执行。

 **上下文切换的原理**

- **关键寄存器**：
  - **`ra`**：返回地址寄存器，决定从哪个位置继续执行。
  - **`sp`**：堆栈指针寄存器，指向当前函数调用栈。
  - **`s0`-`s11`**：RISC-V 中的保存寄存器（callee-saved registers），用于保存函数调用时需要保持的值。
- **保存和恢复寄存器的意义**：
  - 在切换到另一个任务前，必须将当前任务的寄存器状态保存到内存。
  - 切换到新任务后，恢复其寄存器状态，使得新任务能够从切换点继续运行。

 **作用总结**

1. **保存当前任务的寄存器上下文**（`from`），防止其数据丢失。
2. **加载新任务的寄存器上下文**（`to`），使得新任务能够继续执行。
3. 实现操作系统中的多任务调度，为进程/线程切换提供底层支持。

#### 问题回答

在本实验中，一共创建了两个内核线程，一个为 `idle` ，另外一个为执行 `init_main` 的 `init` 线程。



### 扩展练习 Challenge：

- 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

宏 `local_intr_save` 和 `local_intr_restore` 是为了在操作系统内核中安全地管理中断开关（启用和关闭中断），避免在关键代码执行时被打断。

```c
// 保存中断状态
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

// 恢复中断状态
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ *
```

 **1. 保存和关闭中断**

语句：

```c
local_intr_save(intr_flag);
```

展开后等价于：

```c
do {
    intr_flag = __intr_save();
} while (0);
```

- `__intr_save` 函数

  ```c
  static inline bool __intr_save(void) {
      if (read_csr(sstatus) & SSTATUS_SIE) {
          intr_disable();   // 关闭中断
          return 1;         // 返回中断原本为开启状态
      }
      return 0;             // 返回中断原本为关闭状态
  }
  ```

  - 读取状态

    ```
    read_csr(sstatus)
    ```

     读取当前中断状态寄存器。

    - `SSTATUS_SIE` 位（Supervisor Interrupt Enable）表示是否启用了中断。

  - 检查中断状态

    - 如果中断启用（`SSTATUS_SIE` 为 1），调用 `intr_disable` 关闭中断，并返回 `1` 表示之前中断是开启的。
    - 如果中断已关闭（`SSTATUS_SIE` 为 0），直接返回 `0`。

  - **结果**：`intr_flag` 被设置为中断的原始状态。

**2. 恢复中断**

语句：

```c
local_intr_restore(intr_flag);
```

展开后等价于：

```c
__intr_restore(intr_flag);
```

- `__intr_restore` 函数

  ```c
  static inline void __intr_restore(bool flag) {
      if (flag) {
          intr_enable();    // 只有在 flag 为 1 时恢复中断
      }
  }
  ```

  - 检查 

    ```
    flag
    ```

    - 如果 `flag == 1`，调用 `intr_enable` 启用中断。
    - 如果 `flag == 0`，保持中断关闭。

------

 **关键函数解析**

1. **`intr_disable`**:

   - 通过写控制寄存器清除 `SSTATUS_SIE` 位，关闭中断。

   ```c
   write_csr(sstatus, read_csr(sstatus) & ~SSTATUS_SIE);
   ```

2. **`intr_enable`**:

   - 通过写控制寄存器设置 `SSTATUS_SIE` 位，启用中断。

   ```c
   write_csr(sstatus, read_csr(sstatus) | SSTATUS_SIE);
   ```

------

**为什么这样设计？**

1. **保护临界区代码**：
   - 在关键代码段中关闭中断，避免被中断服务程序打断，从而确保操作的原子性。
2. **恢复中断的灵活性**：
   - 恢复时依据原中断状态来决定是否启用中断，防止过度关闭中断导致系统不可预期行为。

------

**执行过程**

1. 假设当前 `SSTATUS_SIE = 1`（中断开启）。

2. 执行 

   ```
   local_intr_save(intr_flag)
   ```

   - 调用 `__intr_save`，`intr_flag` 被设置为 `1`，并关闭中断。

3. 执行关键代码。

4. 执行 

   ```
   local_intr_restore(intr_flag)
   ```

   - 调用 `__intr_restore`，根据 `intr_flag` 恢复中断（重新设置 `SSTATUS_SIE = 1`）。

这样实现了中断状态的保存、关闭和恢复。

### 五、知识点与注意事项总结

1. **进程管理（Process Management）**： 进程管理是操作系统中的一个核心功能，它涉及到进程的整个生命周期的管理。这包括进程的创建，其中操作系统为新进程分配必要的资源如内存和CPU时间；进程的执行，即调度进程运行的过程；进程的等待和唤醒，当进程等待某个事件如I/O操作完成时会被置入等待状态，事件完成后被唤醒；以及进程的结束，这涉及到资源的回收和进程的终止。进程管理确保了系统中的多个进程能够有序、高效地运行。
2. **内核线程（Kernel Threads）**： 内核线程是操作系统内核中运行的线程，它们通常用于执行一些需要内核权限的任务，如设备驱动程序、系统调用处理等。与用户态线程相比，内核线程拥有更多的控制权，能够直接访问硬件和内核数据结构。内核线程的轻量级特性使得它们在创建和销毁时消耗的资源较少，因此可以创建大量的内核线程来提高系统的并发处理能力。
3. **进程控制块（Process Control Block, PCB）**： 进程控制块是操作系统为每个进程维护的一个数据结构，它包含了进程的所有必要信息，如进程ID、状态、优先级、程序计数器、寄存器集合、CPU时间等。PCB是操作系统管理进程的核心，它不仅用于跟踪进程的状态，还用于在进程切换时保存和恢复进程的上下文。操作系统通过PCB来调度进程，决定哪个进程应该获得CPU时间。
4. **上下文切换（Context Switching）**： 上下文切换是操作系统在多任务环境中进行进程或线程切换的过程。当操作系统从一个进程切换到另一个进程时，它需要保存当前进程的状态（上下文），包括寄存器值、程序计数器等，以便在进程再次执行时能够从中断点继续执行。然后，操作系统加载下一个要执行的进程的状态，使其开始运行。上下文切换是实现多任务和时间共享的关键技术。
5. **中断和异常处理（Interrupts and Exceptions）**： 中断是硬件设备用来通知操作系统某个事件已经发生的信号，如键盘输入或磁盘读写完成。异常是程序执行过程中出现的错误，如除零操作。操作系统需要能够响应这些中断和异常，执行相应的处理程序，如服务I/O请求或处理程序错误。中断和异常处理是操作系统与硬件交互的重要机制。
6. **内存管理（Memory Management）**： 内存管理是操作系统中负责分配、管理和回收内存资源的模块。它包括内存分配，为进程分配内存空间；内存回收，当进程结束时释放内存；内存共享，允许多个进程共享内存区域；以及内存保护，防止进程访问不属于它的内存区域。虚拟内存技术是内存管理的一个重要部分，它允许进程使用比物理内存更大的地址空间，通过分页和交换技术实现。
