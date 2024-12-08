
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	52660613          	addi	a2,a2,1318 # ffffffffc0206560 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	175010ef          	jal	ra,ffffffffc02019be <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	97e50513          	addi	a0,a0,-1666 # ffffffffc02019d0 <etext>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	282010ef          	jal	ra,ffffffffc02012e8 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	442010ef          	jal	ra,ffffffffc02014e8 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	40c010ef          	jal	ra,ffffffffc02014e8 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00002517          	auipc	a0,0x2
ffffffffc0200140:	8b450513          	addi	a0,a0,-1868 # ffffffffc02019f0 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	8be50513          	addi	a0,a0,-1858 # ffffffffc0201a10 <etext+0x40>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	87258593          	addi	a1,a1,-1934 # ffffffffc02019d0 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0201a30 <etext+0x60>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <free_area>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201a50 <etext+0x80>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3da58593          	addi	a1,a1,986 # ffffffffc0206560 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	8e250513          	addi	a0,a0,-1822 # ffffffffc0201a70 <etext+0xa0>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	7c558593          	addi	a1,a1,1989 # ffffffffc020695f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	8d450513          	addi	a0,a0,-1836 # ffffffffc0201a90 <etext+0xc0>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00002617          	auipc	a2,0x2
ffffffffc02001ce:	8f660613          	addi	a2,a2,-1802 # ffffffffc0201ac0 <etext+0xf0>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	90250513          	addi	a0,a0,-1790 # ffffffffc0201ad8 <etext+0x108>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00002617          	auipc	a2,0x2
ffffffffc02001ea:	90a60613          	addi	a2,a2,-1782 # ffffffffc0201af0 <etext+0x120>
ffffffffc02001ee:	00002597          	auipc	a1,0x2
ffffffffc02001f2:	92258593          	addi	a1,a1,-1758 # ffffffffc0201b10 <etext+0x140>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	92250513          	addi	a0,a0,-1758 # ffffffffc0201b18 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00002617          	auipc	a2,0x2
ffffffffc0200208:	92460613          	addi	a2,a2,-1756 # ffffffffc0201b28 <etext+0x158>
ffffffffc020020c:	00002597          	auipc	a1,0x2
ffffffffc0200210:	94458593          	addi	a1,a1,-1724 # ffffffffc0201b50 <etext+0x180>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	90450513          	addi	a0,a0,-1788 # ffffffffc0201b18 <etext+0x148>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00002617          	auipc	a2,0x2
ffffffffc0200224:	94060613          	addi	a2,a2,-1728 # ffffffffc0201b60 <etext+0x190>
ffffffffc0200228:	00002597          	auipc	a1,0x2
ffffffffc020022c:	95858593          	addi	a1,a1,-1704 # ffffffffc0201b80 <etext+0x1b0>
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	8e850513          	addi	a0,a0,-1816 # ffffffffc0201b18 <etext+0x148>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	92650513          	addi	a0,a0,-1754 # ffffffffc0201b90 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	92c50513          	addi	a0,a0,-1748 # ffffffffc0201bb8 <etext+0x1e8>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00002c17          	auipc	s8,0x2
ffffffffc02002a6:	986c0c13          	addi	s8,s8,-1658 # ffffffffc0201c28 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00002917          	auipc	s2,0x2
ffffffffc02002ae:	93690913          	addi	s2,s2,-1738 # ffffffffc0201be0 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00002497          	auipc	s1,0x2
ffffffffc02002b6:	93648493          	addi	s1,s1,-1738 # ffffffffc0201be8 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00002b17          	auipc	s6,0x2
ffffffffc02002c0:	934b0b13          	addi	s6,s6,-1740 # ffffffffc0201bf0 <etext+0x220>
        argv[argc ++] = buf;
ffffffffc02002c4:	00002a17          	auipc	s4,0x2
ffffffffc02002c8:	84ca0a13          	addi	s4,s4,-1972 # ffffffffc0201b10 <etext+0x140>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	59a010ef          	jal	ra,ffffffffc020186a <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002d17          	auipc	s10,0x2
ffffffffc02002ea:	942d0d13          	addi	s10,s10,-1726 # ffffffffc0201c28 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	696010ef          	jal	ra,ffffffffc020198a <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	682010ef          	jal	ra,ffffffffc020198a <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	662010ef          	jal	ra,ffffffffc02019a8 <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	624010ef          	jal	ra,ffffffffc02019a8 <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	87250513          	addi	a0,a0,-1934 # ffffffffc0201c10 <etext+0x240>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	16c30313          	addi	t1,t1,364 # ffffffffc0206518 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00002517          	auipc	a0,0x2
ffffffffc02003de:	89650513          	addi	a0,a0,-1898 # ffffffffc0201c70 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	6c850513          	addi	a0,a0,1736 # ffffffffc0201ab8 <etext+0xe8>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	518010ef          	jal	ra,ffffffffc0201938 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	86250513          	addi	a0,a0,-1950 # ffffffffc0201c90 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	4f20106f          	j	ffffffffc0201938 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	andi	a0,a0,255
ffffffffc0200450:	4ce0106f          	j	ffffffffc020191e <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	4fe0106f          	j	ffffffffc0201952 <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	2e478793          	addi	a5,a5,740 # ffffffffc020074c <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00002517          	auipc	a0,0x2
ffffffffc0200482:	83250513          	addi	a0,a0,-1998 # ffffffffc0201cb0 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	83a50513          	addi	a0,a0,-1990 # ffffffffc0201cc8 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	84450513          	addi	a0,a0,-1980 # ffffffffc0201ce0 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	84e50513          	addi	a0,a0,-1970 # ffffffffc0201cf8 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	85850513          	addi	a0,a0,-1960 # ffffffffc0201d10 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	86250513          	addi	a0,a0,-1950 # ffffffffc0201d28 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201d40 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	87650513          	addi	a0,a0,-1930 # ffffffffc0201d58 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	88050513          	addi	a0,a0,-1920 # ffffffffc0201d70 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	88a50513          	addi	a0,a0,-1910 # ffffffffc0201d88 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	89450513          	addi	a0,a0,-1900 # ffffffffc0201da0 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0201db8 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	8a850513          	addi	a0,a0,-1880 # ffffffffc0201dd0 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	8b250513          	addi	a0,a0,-1870 # ffffffffc0201de8 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0201e00 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	8c650513          	addi	a0,a0,-1850 # ffffffffc0201e18 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	8d050513          	addi	a0,a0,-1840 # ffffffffc0201e30 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	8da50513          	addi	a0,a0,-1830 # ffffffffc0201e48 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	8e450513          	addi	a0,a0,-1820 # ffffffffc0201e60 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0201e78 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	8f850513          	addi	a0,a0,-1800 # ffffffffc0201e90 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	90250513          	addi	a0,a0,-1790 # ffffffffc0201ea8 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	90c50513          	addi	a0,a0,-1780 # ffffffffc0201ec0 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	91650513          	addi	a0,a0,-1770 # ffffffffc0201ed8 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	92050513          	addi	a0,a0,-1760 # ffffffffc0201ef0 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	92a50513          	addi	a0,a0,-1750 # ffffffffc0201f08 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	93450513          	addi	a0,a0,-1740 # ffffffffc0201f20 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	93e50513          	addi	a0,a0,-1730 # ffffffffc0201f38 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	94850513          	addi	a0,a0,-1720 # ffffffffc0201f50 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	95250513          	addi	a0,a0,-1710 # ffffffffc0201f68 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	95c50513          	addi	a0,a0,-1700 # ffffffffc0201f80 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	96250513          	addi	a0,a0,-1694 # ffffffffc0201f98 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	96650513          	addi	a0,a0,-1690 # ffffffffc0201fb0 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	96650513          	addi	a0,a0,-1690 # ffffffffc0201fc8 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201fe0 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	97650513          	addi	a0,a0,-1674 # ffffffffc0201ff8 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	97a50513          	addi	a0,a0,-1670 # ffffffffc0202010 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	a4070713          	addi	a4,a4,-1472 # ffffffffc02020f0 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	9c650513          	addi	a0,a0,-1594 # ffffffffc0202088 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	99c50513          	addi	a0,a0,-1636 # ffffffffc0202068 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	95250513          	addi	a0,a0,-1710 # ffffffffc0202028 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	9c850513          	addi	a0,a0,-1592 # ffffffffc02020a8 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	e2e68693          	addi	a3,a3,-466 # ffffffffc0206520 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00002517          	auipc	a0,0x2
ffffffffc0200714:	9c050513          	addi	a0,a0,-1600 # ffffffffc02020d0 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0202048 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	99450513          	addi	a0,a0,-1644 # ffffffffc02020c0 <commands+0x498>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
ffffffffc020073c:	0007c763          	bltz	a5,ffffffffc020074a <trap+0x12>
    switch (tf->cause) {
ffffffffc0200740:	472d                	li	a4,11
ffffffffc0200742:	00f76363          	bltu	a4,a5,ffffffffc0200748 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200746:	8082                	ret
            print_trapframe(tf);
ffffffffc0200748:	bded                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc020074a:	bfa1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f89ff0ef          	jal	ra,ffffffffc0200738 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200802:	00006797          	auipc	a5,0x6
ffffffffc0200806:	80e78793          	addi	a5,a5,-2034 # ffffffffc0206010 <free_area>
ffffffffc020080a:	e79c                	sd	a5,8(a5)
ffffffffc020080c:	e39c                	sd	a5,0(a5)

/* 初始化空闲链表并将nr_free设为0 */
static void
best_fit_init(void) {
    list_init(&free_list); //初始化空闲链表
    nr_free = 0;           //空闲内存页设置为0
ffffffffc020080e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200814:	00006517          	auipc	a0,0x6
ffffffffc0200818:	80c56503          	lwu	a0,-2036(a0) # ffffffffc0206020 <free_area+0x10>
ffffffffc020081c:	8082                	ret

ffffffffc020081e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020081e:	c14d                	beqz	a0,ffffffffc02008c0 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200820:	00005617          	auipc	a2,0x5
ffffffffc0200824:	7f060613          	addi	a2,a2,2032 # ffffffffc0206010 <free_area>
ffffffffc0200828:	01062803          	lw	a6,16(a2)
ffffffffc020082c:	86aa                	mv	a3,a0
ffffffffc020082e:	02081793          	slli	a5,a6,0x20
ffffffffc0200832:	9381                	srli	a5,a5,0x20
ffffffffc0200834:	08a7e463          	bltu	a5,a0,ffffffffc02008bc <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200838:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc020083a:	0018059b          	addiw	a1,a6,1
ffffffffc020083e:	1582                	slli	a1,a1,0x20
ffffffffc0200840:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200842:	4501                	li	a0,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0200844:	06c78b63          	beq	a5,a2,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
         if (p->property >= n && p->property < min_size) {
ffffffffc0200848:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020084c:	00d76763          	bltu	a4,a3,ffffffffc020085a <best_fit_alloc_pages+0x3c>
ffffffffc0200850:	00b77563          	bgeu	a4,a1,ffffffffc020085a <best_fit_alloc_pages+0x3c>
         struct Page *p = le2page(le, page_link);
ffffffffc0200854:	fe878513          	addi	a0,a5,-24
ffffffffc0200858:	85ba                	mv	a1,a4
ffffffffc020085a:	679c                	ld	a5,8(a5)
     while ((le = list_next(le)) != &free_list) {
ffffffffc020085c:	fec796e3          	bne	a5,a2,ffffffffc0200848 <best_fit_alloc_pages+0x2a>
     if (page != NULL) {
ffffffffc0200860:	cd29                	beqz	a0,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200862:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200864:	6d18                	ld	a4,24(a0)
         if (page->property > n) {
ffffffffc0200866:	490c                	lw	a1,16(a0)
             p->property = page->property - n; // 剩余大小
ffffffffc0200868:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020086c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020086e:	e398                	sd	a4,0(a5)
         if (page->property > n) {
ffffffffc0200870:	02059793          	slli	a5,a1,0x20
ffffffffc0200874:	9381                	srli	a5,a5,0x20
ffffffffc0200876:	02f6f863          	bgeu	a3,a5,ffffffffc02008a6 <best_fit_alloc_pages+0x88>
             struct Page *p = page + n;
ffffffffc020087a:	00269793          	slli	a5,a3,0x2
ffffffffc020087e:	97b6                	add	a5,a5,a3
ffffffffc0200880:	078e                	slli	a5,a5,0x3
ffffffffc0200882:	97aa                	add	a5,a5,a0
             p->property = page->property - n; // 剩余大小
ffffffffc0200884:	411585bb          	subw	a1,a1,a7
ffffffffc0200888:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020088a:	4689                	li	a3,2
ffffffffc020088c:	00878593          	addi	a1,a5,8
ffffffffc0200890:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200894:	6714                	ld	a3,8(a4)
             list_add(prev, &(p->page_link)); // 插入到链表
ffffffffc0200896:	01878593          	addi	a1,a5,24
         nr_free -= n;          // 更新空闲页数量
ffffffffc020089a:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc020089e:	e28c                	sd	a1,0(a3)
ffffffffc02008a0:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008a2:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02008a4:	ef98                	sd	a4,24(a5)
ffffffffc02008a6:	4118083b          	subw	a6,a6,a7
ffffffffc02008aa:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008ae:	57f5                	li	a5,-3
ffffffffc02008b0:	00850713          	addi	a4,a0,8
ffffffffc02008b4:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc02008b8:	8082                	ret
}
ffffffffc02008ba:	8082                	ret
        return NULL;
ffffffffc02008bc:	4501                	li	a0,0
ffffffffc02008be:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02008c0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008c2:	00002697          	auipc	a3,0x2
ffffffffc02008c6:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202120 <commands+0x4f8>
ffffffffc02008ca:	00002617          	auipc	a2,0x2
ffffffffc02008ce:	85e60613          	addi	a2,a2,-1954 # ffffffffc0202128 <commands+0x500>
ffffffffc02008d2:	07300593          	li	a1,115
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	86a50513          	addi	a0,a0,-1942 # ffffffffc0202140 <commands+0x518>
best_fit_alloc_pages(size_t n) {
ffffffffc02008de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e0:	acdff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02008e4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008e4:	715d                	addi	sp,sp,-80
ffffffffc02008e6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008e8:	00005417          	auipc	s0,0x5
ffffffffc02008ec:	72840413          	addi	s0,s0,1832 # ffffffffc0206010 <free_area>
ffffffffc02008f0:	641c                	ld	a5,8(s0)
ffffffffc02008f2:	e486                	sd	ra,72(sp)
ffffffffc02008f4:	fc26                	sd	s1,56(sp)
ffffffffc02008f6:	f84a                	sd	s2,48(sp)
ffffffffc02008f8:	f44e                	sd	s3,40(sp)
ffffffffc02008fa:	f052                	sd	s4,32(sp)
ffffffffc02008fc:	ec56                	sd	s5,24(sp)
ffffffffc02008fe:	e85a                	sd	s6,16(sp)
ffffffffc0200900:	e45e                	sd	s7,8(sp)
ffffffffc0200902:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200904:	26878b63          	beq	a5,s0,ffffffffc0200b7a <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200908:	4481                	li	s1,0
ffffffffc020090a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020090c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200910:	8b09                	andi	a4,a4,2
ffffffffc0200912:	26070863          	beqz	a4,ffffffffc0200b82 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200916:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091a:	679c                	ld	a5,8(a5)
ffffffffc020091c:	2905                	addiw	s2,s2,1
ffffffffc020091e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200920:	fe8796e3          	bne	a5,s0,ffffffffc020090c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200924:	89a6                	mv	s3,s1
ffffffffc0200926:	189000ef          	jal	ra,ffffffffc02012ae <nr_free_pages>
ffffffffc020092a:	33351c63          	bne	a0,s3,ffffffffc0200c62 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020092e:	4505                	li	a0,1
ffffffffc0200930:	101000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200934:	8a2a                	mv	s4,a0
ffffffffc0200936:	36050663          	beqz	a0,ffffffffc0200ca2 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020093a:	4505                	li	a0,1
ffffffffc020093c:	0f5000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200940:	89aa                	mv	s3,a0
ffffffffc0200942:	34050063          	beqz	a0,ffffffffc0200c82 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200946:	4505                	li	a0,1
ffffffffc0200948:	0e9000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc020094c:	8aaa                	mv	s5,a0
ffffffffc020094e:	2c050a63          	beqz	a0,ffffffffc0200c22 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200952:	253a0863          	beq	s4,s3,ffffffffc0200ba2 <best_fit_check+0x2be>
ffffffffc0200956:	24aa0663          	beq	s4,a0,ffffffffc0200ba2 <best_fit_check+0x2be>
ffffffffc020095a:	24a98463          	beq	s3,a0,ffffffffc0200ba2 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020095e:	000a2783          	lw	a5,0(s4)
ffffffffc0200962:	26079063          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
ffffffffc0200966:	0009a783          	lw	a5,0(s3)
ffffffffc020096a:	24079c63          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
ffffffffc020096e:	411c                	lw	a5,0(a0)
ffffffffc0200970:	24079963          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200974:	00006797          	auipc	a5,0x6
ffffffffc0200978:	bbc7b783          	ld	a5,-1092(a5) # ffffffffc0206530 <pages>
ffffffffc020097c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200980:	870d                	srai	a4,a4,0x3
ffffffffc0200982:	00002597          	auipc	a1,0x2
ffffffffc0200986:	e8e5b583          	ld	a1,-370(a1) # ffffffffc0202810 <error_string+0x38>
ffffffffc020098a:	02b70733          	mul	a4,a4,a1
ffffffffc020098e:	00002617          	auipc	a2,0x2
ffffffffc0200992:	e8a63603          	ld	a2,-374(a2) # ffffffffc0202818 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200996:	00006697          	auipc	a3,0x6
ffffffffc020099a:	b926b683          	ld	a3,-1134(a3) # ffffffffc0206528 <npage>
ffffffffc020099e:	06b2                	slli	a3,a3,0xc
ffffffffc02009a0:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009a2:	0732                	slli	a4,a4,0xc
ffffffffc02009a4:	22d77f63          	bgeu	a4,a3,ffffffffc0200be2 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009a8:	40f98733          	sub	a4,s3,a5
ffffffffc02009ac:	870d                	srai	a4,a4,0x3
ffffffffc02009ae:	02b70733          	mul	a4,a4,a1
ffffffffc02009b2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009b4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009b6:	3ed77663          	bgeu	a4,a3,ffffffffc0200da2 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009ba:	40f507b3          	sub	a5,a0,a5
ffffffffc02009be:	878d                	srai	a5,a5,0x3
ffffffffc02009c0:	02b787b3          	mul	a5,a5,a1
ffffffffc02009c4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009c6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02009c8:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200d82 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc02009cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009ce:	00043c03          	ld	s8,0(s0)
ffffffffc02009d2:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02009d6:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02009da:	e400                	sd	s0,8(s0)
ffffffffc02009dc:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02009de:	00005797          	auipc	a5,0x5
ffffffffc02009e2:	6407a123          	sw	zero,1602(a5) # ffffffffc0206020 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009e6:	04b000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc02009ea:	36051c63          	bnez	a0,ffffffffc0200d62 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc02009ee:	4585                	li	a1,1
ffffffffc02009f0:	8552                	mv	a0,s4
ffffffffc02009f2:	07d000ef          	jal	ra,ffffffffc020126e <free_pages>
    free_page(p1);
ffffffffc02009f6:	4585                	li	a1,1
ffffffffc02009f8:	854e                	mv	a0,s3
ffffffffc02009fa:	075000ef          	jal	ra,ffffffffc020126e <free_pages>
    free_page(p2);
ffffffffc02009fe:	4585                	li	a1,1
ffffffffc0200a00:	8556                	mv	a0,s5
ffffffffc0200a02:	06d000ef          	jal	ra,ffffffffc020126e <free_pages>
    assert(nr_free == 3);
ffffffffc0200a06:	4818                	lw	a4,16(s0)
ffffffffc0200a08:	478d                	li	a5,3
ffffffffc0200a0a:	32f71c63          	bne	a4,a5,ffffffffc0200d42 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a0e:	4505                	li	a0,1
ffffffffc0200a10:	021000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a14:	89aa                	mv	s3,a0
ffffffffc0200a16:	30050663          	beqz	a0,ffffffffc0200d22 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a1a:	4505                	li	a0,1
ffffffffc0200a1c:	015000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a20:	8aaa                	mv	s5,a0
ffffffffc0200a22:	2e050063          	beqz	a0,ffffffffc0200d02 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a26:	4505                	li	a0,1
ffffffffc0200a28:	009000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a2c:	8a2a                	mv	s4,a0
ffffffffc0200a2e:	2a050a63          	beqz	a0,ffffffffc0200ce2 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200a32:	4505                	li	a0,1
ffffffffc0200a34:	7fc000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a38:	28051563          	bnez	a0,ffffffffc0200cc2 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200a3c:	4585                	li	a1,1
ffffffffc0200a3e:	854e                	mv	a0,s3
ffffffffc0200a40:	02f000ef          	jal	ra,ffffffffc020126e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a44:	641c                	ld	a5,8(s0)
ffffffffc0200a46:	1a878e63          	beq	a5,s0,ffffffffc0200c02 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200a4a:	4505                	li	a0,1
ffffffffc0200a4c:	7e4000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a50:	52a99963          	bne	s3,a0,ffffffffc0200f82 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200a54:	4505                	li	a0,1
ffffffffc0200a56:	7da000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a5a:	50051463          	bnez	a0,ffffffffc0200f62 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200a5e:	481c                	lw	a5,16(s0)
ffffffffc0200a60:	4e079163          	bnez	a5,ffffffffc0200f42 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200a64:	854e                	mv	a0,s3
ffffffffc0200a66:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a68:	01843023          	sd	s8,0(s0)
ffffffffc0200a6c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a70:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a74:	7fa000ef          	jal	ra,ffffffffc020126e <free_pages>
    free_page(p1);
ffffffffc0200a78:	4585                	li	a1,1
ffffffffc0200a7a:	8556                	mv	a0,s5
ffffffffc0200a7c:	7f2000ef          	jal	ra,ffffffffc020126e <free_pages>
    free_page(p2);
ffffffffc0200a80:	4585                	li	a1,1
ffffffffc0200a82:	8552                	mv	a0,s4
ffffffffc0200a84:	7ea000ef          	jal	ra,ffffffffc020126e <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a88:	4515                	li	a0,5
ffffffffc0200a8a:	7a6000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200a8e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a90:	48050963          	beqz	a0,ffffffffc0200f22 <best_fit_check+0x63e>
ffffffffc0200a94:	651c                	ld	a5,8(a0)
ffffffffc0200a96:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200a98:	8b85                	andi	a5,a5,1
ffffffffc0200a9a:	46079463          	bnez	a5,ffffffffc0200f02 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a9e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200aa0:	00043a83          	ld	s5,0(s0)
ffffffffc0200aa4:	00843a03          	ld	s4,8(s0)
ffffffffc0200aa8:	e000                	sd	s0,0(s0)
ffffffffc0200aaa:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200aac:	784000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200ab0:	42051963          	bnez	a0,ffffffffc0200ee2 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200ab4:	4589                	li	a1,2
ffffffffc0200ab6:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200aba:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200abe:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200ac2:	00005797          	auipc	a5,0x5
ffffffffc0200ac6:	5407af23          	sw	zero,1374(a5) # ffffffffc0206020 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200aca:	7a4000ef          	jal	ra,ffffffffc020126e <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200ace:	8562                	mv	a0,s8
ffffffffc0200ad0:	4585                	li	a1,1
ffffffffc0200ad2:	79c000ef          	jal	ra,ffffffffc020126e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ad6:	4511                	li	a0,4
ffffffffc0200ad8:	758000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200adc:	3e051363          	bnez	a0,ffffffffc0200ec2 <best_fit_check+0x5de>
ffffffffc0200ae0:	0309b783          	ld	a5,48(s3)
ffffffffc0200ae4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200ae6:	8b85                	andi	a5,a5,1
ffffffffc0200ae8:	3a078d63          	beqz	a5,ffffffffc0200ea2 <best_fit_check+0x5be>
ffffffffc0200aec:	0389a703          	lw	a4,56(s3)
ffffffffc0200af0:	4789                	li	a5,2
ffffffffc0200af2:	3af71863          	bne	a4,a5,ffffffffc0200ea2 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200af6:	4505                	li	a0,1
ffffffffc0200af8:	738000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200afc:	8baa                	mv	s7,a0
ffffffffc0200afe:	38050263          	beqz	a0,ffffffffc0200e82 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b02:	4509                	li	a0,2
ffffffffc0200b04:	72c000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200b08:	34050d63          	beqz	a0,ffffffffc0200e62 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200b0c:	337c1b63          	bne	s8,s7,ffffffffc0200e42 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b10:	854e                	mv	a0,s3
ffffffffc0200b12:	4595                	li	a1,5
ffffffffc0200b14:	75a000ef          	jal	ra,ffffffffc020126e <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b18:	4515                	li	a0,5
ffffffffc0200b1a:	716000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200b1e:	89aa                	mv	s3,a0
ffffffffc0200b20:	30050163          	beqz	a0,ffffffffc0200e22 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	4505                	li	a0,1
ffffffffc0200b26:	70a000ef          	jal	ra,ffffffffc0201230 <alloc_pages>
ffffffffc0200b2a:	2c051c63          	bnez	a0,ffffffffc0200e02 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b2e:	481c                	lw	a5,16(s0)
ffffffffc0200b30:	2a079963          	bnez	a5,ffffffffc0200de2 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b34:	4595                	li	a1,5
ffffffffc0200b36:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b38:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200b3c:	01543023          	sd	s5,0(s0)
ffffffffc0200b40:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200b44:	72a000ef          	jal	ra,ffffffffc020126e <free_pages>
    return listelm->next;
ffffffffc0200b48:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b4a:	00878963          	beq	a5,s0,ffffffffc0200b5c <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b4e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b52:	679c                	ld	a5,8(a5)
ffffffffc0200b54:	397d                	addiw	s2,s2,-1
ffffffffc0200b56:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b58:	fe879be3          	bne	a5,s0,ffffffffc0200b4e <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200b5c:	26091363          	bnez	s2,ffffffffc0200dc2 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200b60:	e0ed                	bnez	s1,ffffffffc0200c42 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b62:	60a6                	ld	ra,72(sp)
ffffffffc0200b64:	6406                	ld	s0,64(sp)
ffffffffc0200b66:	74e2                	ld	s1,56(sp)
ffffffffc0200b68:	7942                	ld	s2,48(sp)
ffffffffc0200b6a:	79a2                	ld	s3,40(sp)
ffffffffc0200b6c:	7a02                	ld	s4,32(sp)
ffffffffc0200b6e:	6ae2                	ld	s5,24(sp)
ffffffffc0200b70:	6b42                	ld	s6,16(sp)
ffffffffc0200b72:	6ba2                	ld	s7,8(sp)
ffffffffc0200b74:	6c02                	ld	s8,0(sp)
ffffffffc0200b76:	6161                	addi	sp,sp,80
ffffffffc0200b78:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b7a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b7c:	4481                	li	s1,0
ffffffffc0200b7e:	4901                	li	s2,0
ffffffffc0200b80:	b35d                	j	ffffffffc0200926 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b82:	00001697          	auipc	a3,0x1
ffffffffc0200b86:	5d668693          	addi	a3,a3,1494 # ffffffffc0202158 <commands+0x530>
ffffffffc0200b8a:	00001617          	auipc	a2,0x1
ffffffffc0200b8e:	59e60613          	addi	a2,a2,1438 # ffffffffc0202128 <commands+0x500>
ffffffffc0200b92:	11a00593          	li	a1,282
ffffffffc0200b96:	00001517          	auipc	a0,0x1
ffffffffc0200b9a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202140 <commands+0x518>
ffffffffc0200b9e:	80fff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ba2:	00001697          	auipc	a3,0x1
ffffffffc0200ba6:	64668693          	addi	a3,a3,1606 # ffffffffc02021e8 <commands+0x5c0>
ffffffffc0200baa:	00001617          	auipc	a2,0x1
ffffffffc0200bae:	57e60613          	addi	a2,a2,1406 # ffffffffc0202128 <commands+0x500>
ffffffffc0200bb2:	0e600593          	li	a1,230
ffffffffc0200bb6:	00001517          	auipc	a0,0x1
ffffffffc0200bba:	58a50513          	addi	a0,a0,1418 # ffffffffc0202140 <commands+0x518>
ffffffffc0200bbe:	feeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bc2:	00001697          	auipc	a3,0x1
ffffffffc0200bc6:	64e68693          	addi	a3,a3,1614 # ffffffffc0202210 <commands+0x5e8>
ffffffffc0200bca:	00001617          	auipc	a2,0x1
ffffffffc0200bce:	55e60613          	addi	a2,a2,1374 # ffffffffc0202128 <commands+0x500>
ffffffffc0200bd2:	0e700593          	li	a1,231
ffffffffc0200bd6:	00001517          	auipc	a0,0x1
ffffffffc0200bda:	56a50513          	addi	a0,a0,1386 # ffffffffc0202140 <commands+0x518>
ffffffffc0200bde:	fceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200be2:	00001697          	auipc	a3,0x1
ffffffffc0200be6:	66e68693          	addi	a3,a3,1646 # ffffffffc0202250 <commands+0x628>
ffffffffc0200bea:	00001617          	auipc	a2,0x1
ffffffffc0200bee:	53e60613          	addi	a2,a2,1342 # ffffffffc0202128 <commands+0x500>
ffffffffc0200bf2:	0e900593          	li	a1,233
ffffffffc0200bf6:	00001517          	auipc	a0,0x1
ffffffffc0200bfa:	54a50513          	addi	a0,a0,1354 # ffffffffc0202140 <commands+0x518>
ffffffffc0200bfe:	faeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c02:	00001697          	auipc	a3,0x1
ffffffffc0200c06:	6d668693          	addi	a3,a3,1750 # ffffffffc02022d8 <commands+0x6b0>
ffffffffc0200c0a:	00001617          	auipc	a2,0x1
ffffffffc0200c0e:	51e60613          	addi	a2,a2,1310 # ffffffffc0202128 <commands+0x500>
ffffffffc0200c12:	10200593          	li	a1,258
ffffffffc0200c16:	00001517          	auipc	a0,0x1
ffffffffc0200c1a:	52a50513          	addi	a0,a0,1322 # ffffffffc0202140 <commands+0x518>
ffffffffc0200c1e:	f8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c22:	00001697          	auipc	a3,0x1
ffffffffc0200c26:	5a668693          	addi	a3,a3,1446 # ffffffffc02021c8 <commands+0x5a0>
ffffffffc0200c2a:	00001617          	auipc	a2,0x1
ffffffffc0200c2e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0202128 <commands+0x500>
ffffffffc0200c32:	0e400593          	li	a1,228
ffffffffc0200c36:	00001517          	auipc	a0,0x1
ffffffffc0200c3a:	50a50513          	addi	a0,a0,1290 # ffffffffc0202140 <commands+0x518>
ffffffffc0200c3e:	f6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0200c42:	00001697          	auipc	a3,0x1
ffffffffc0200c46:	7c668693          	addi	a3,a3,1990 # ffffffffc0202408 <commands+0x7e0>
ffffffffc0200c4a:	00001617          	auipc	a2,0x1
ffffffffc0200c4e:	4de60613          	addi	a2,a2,1246 # ffffffffc0202128 <commands+0x500>
ffffffffc0200c52:	15c00593          	li	a1,348
ffffffffc0200c56:	00001517          	auipc	a0,0x1
ffffffffc0200c5a:	4ea50513          	addi	a0,a0,1258 # ffffffffc0202140 <commands+0x518>
ffffffffc0200c5e:	f4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c62:	00001697          	auipc	a3,0x1
ffffffffc0200c66:	50668693          	addi	a3,a3,1286 # ffffffffc0202168 <commands+0x540>
ffffffffc0200c6a:	00001617          	auipc	a2,0x1
ffffffffc0200c6e:	4be60613          	addi	a2,a2,1214 # ffffffffc0202128 <commands+0x500>
ffffffffc0200c72:	11d00593          	li	a1,285
ffffffffc0200c76:	00001517          	auipc	a0,0x1
ffffffffc0200c7a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0202140 <commands+0x518>
ffffffffc0200c7e:	f2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c82:	00001697          	auipc	a3,0x1
ffffffffc0200c86:	52668693          	addi	a3,a3,1318 # ffffffffc02021a8 <commands+0x580>
ffffffffc0200c8a:	00001617          	auipc	a2,0x1
ffffffffc0200c8e:	49e60613          	addi	a2,a2,1182 # ffffffffc0202128 <commands+0x500>
ffffffffc0200c92:	0e300593          	li	a1,227
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202140 <commands+0x518>
ffffffffc0200c9e:	f0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ca2:	00001697          	auipc	a3,0x1
ffffffffc0200ca6:	4e668693          	addi	a3,a3,1254 # ffffffffc0202188 <commands+0x560>
ffffffffc0200caa:	00001617          	auipc	a2,0x1
ffffffffc0200cae:	47e60613          	addi	a2,a2,1150 # ffffffffc0202128 <commands+0x500>
ffffffffc0200cb2:	0e200593          	li	a1,226
ffffffffc0200cb6:	00001517          	auipc	a0,0x1
ffffffffc0200cba:	48a50513          	addi	a0,a0,1162 # ffffffffc0202140 <commands+0x518>
ffffffffc0200cbe:	eeeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cc2:	00001697          	auipc	a3,0x1
ffffffffc0200cc6:	5ee68693          	addi	a3,a3,1518 # ffffffffc02022b0 <commands+0x688>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	45e60613          	addi	a2,a2,1118 # ffffffffc0202128 <commands+0x500>
ffffffffc0200cd2:	0ff00593          	li	a1,255
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	46a50513          	addi	a0,a0,1130 # ffffffffc0202140 <commands+0x518>
ffffffffc0200cde:	eceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	4e668693          	addi	a3,a3,1254 # ffffffffc02021c8 <commands+0x5a0>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	43e60613          	addi	a2,a2,1086 # ffffffffc0202128 <commands+0x500>
ffffffffc0200cf2:	0fd00593          	li	a1,253
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	44a50513          	addi	a0,a0,1098 # ffffffffc0202140 <commands+0x518>
ffffffffc0200cfe:	eaeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d02:	00001697          	auipc	a3,0x1
ffffffffc0200d06:	4a668693          	addi	a3,a3,1190 # ffffffffc02021a8 <commands+0x580>
ffffffffc0200d0a:	00001617          	auipc	a2,0x1
ffffffffc0200d0e:	41e60613          	addi	a2,a2,1054 # ffffffffc0202128 <commands+0x500>
ffffffffc0200d12:	0fc00593          	li	a1,252
ffffffffc0200d16:	00001517          	auipc	a0,0x1
ffffffffc0200d1a:	42a50513          	addi	a0,a0,1066 # ffffffffc0202140 <commands+0x518>
ffffffffc0200d1e:	e8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d22:	00001697          	auipc	a3,0x1
ffffffffc0200d26:	46668693          	addi	a3,a3,1126 # ffffffffc0202188 <commands+0x560>
ffffffffc0200d2a:	00001617          	auipc	a2,0x1
ffffffffc0200d2e:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202128 <commands+0x500>
ffffffffc0200d32:	0fb00593          	li	a1,251
ffffffffc0200d36:	00001517          	auipc	a0,0x1
ffffffffc0200d3a:	40a50513          	addi	a0,a0,1034 # ffffffffc0202140 <commands+0x518>
ffffffffc0200d3e:	e6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200d42:	00001697          	auipc	a3,0x1
ffffffffc0200d46:	58668693          	addi	a3,a3,1414 # ffffffffc02022c8 <commands+0x6a0>
ffffffffc0200d4a:	00001617          	auipc	a2,0x1
ffffffffc0200d4e:	3de60613          	addi	a2,a2,990 # ffffffffc0202128 <commands+0x500>
ffffffffc0200d52:	0f900593          	li	a1,249
ffffffffc0200d56:	00001517          	auipc	a0,0x1
ffffffffc0200d5a:	3ea50513          	addi	a0,a0,1002 # ffffffffc0202140 <commands+0x518>
ffffffffc0200d5e:	e4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d62:	00001697          	auipc	a3,0x1
ffffffffc0200d66:	54e68693          	addi	a3,a3,1358 # ffffffffc02022b0 <commands+0x688>
ffffffffc0200d6a:	00001617          	auipc	a2,0x1
ffffffffc0200d6e:	3be60613          	addi	a2,a2,958 # ffffffffc0202128 <commands+0x500>
ffffffffc0200d72:	0f400593          	li	a1,244
ffffffffc0200d76:	00001517          	auipc	a0,0x1
ffffffffc0200d7a:	3ca50513          	addi	a0,a0,970 # ffffffffc0202140 <commands+0x518>
ffffffffc0200d7e:	e2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d82:	00001697          	auipc	a3,0x1
ffffffffc0200d86:	50e68693          	addi	a3,a3,1294 # ffffffffc0202290 <commands+0x668>
ffffffffc0200d8a:	00001617          	auipc	a2,0x1
ffffffffc0200d8e:	39e60613          	addi	a2,a2,926 # ffffffffc0202128 <commands+0x500>
ffffffffc0200d92:	0eb00593          	li	a1,235
ffffffffc0200d96:	00001517          	auipc	a0,0x1
ffffffffc0200d9a:	3aa50513          	addi	a0,a0,938 # ffffffffc0202140 <commands+0x518>
ffffffffc0200d9e:	e0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200da2:	00001697          	auipc	a3,0x1
ffffffffc0200da6:	4ce68693          	addi	a3,a3,1230 # ffffffffc0202270 <commands+0x648>
ffffffffc0200daa:	00001617          	auipc	a2,0x1
ffffffffc0200dae:	37e60613          	addi	a2,a2,894 # ffffffffc0202128 <commands+0x500>
ffffffffc0200db2:	0ea00593          	li	a1,234
ffffffffc0200db6:	00001517          	auipc	a0,0x1
ffffffffc0200dba:	38a50513          	addi	a0,a0,906 # ffffffffc0202140 <commands+0x518>
ffffffffc0200dbe:	deeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200dc2:	00001697          	auipc	a3,0x1
ffffffffc0200dc6:	63668693          	addi	a3,a3,1590 # ffffffffc02023f8 <commands+0x7d0>
ffffffffc0200dca:	00001617          	auipc	a2,0x1
ffffffffc0200dce:	35e60613          	addi	a2,a2,862 # ffffffffc0202128 <commands+0x500>
ffffffffc0200dd2:	15b00593          	li	a1,347
ffffffffc0200dd6:	00001517          	auipc	a0,0x1
ffffffffc0200dda:	36a50513          	addi	a0,a0,874 # ffffffffc0202140 <commands+0x518>
ffffffffc0200dde:	dceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200de2:	00001697          	auipc	a3,0x1
ffffffffc0200de6:	52e68693          	addi	a3,a3,1326 # ffffffffc0202310 <commands+0x6e8>
ffffffffc0200dea:	00001617          	auipc	a2,0x1
ffffffffc0200dee:	33e60613          	addi	a2,a2,830 # ffffffffc0202128 <commands+0x500>
ffffffffc0200df2:	15000593          	li	a1,336
ffffffffc0200df6:	00001517          	auipc	a0,0x1
ffffffffc0200dfa:	34a50513          	addi	a0,a0,842 # ffffffffc0202140 <commands+0x518>
ffffffffc0200dfe:	daeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e02:	00001697          	auipc	a3,0x1
ffffffffc0200e06:	4ae68693          	addi	a3,a3,1198 # ffffffffc02022b0 <commands+0x688>
ffffffffc0200e0a:	00001617          	auipc	a2,0x1
ffffffffc0200e0e:	31e60613          	addi	a2,a2,798 # ffffffffc0202128 <commands+0x500>
ffffffffc0200e12:	14a00593          	li	a1,330
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	32a50513          	addi	a0,a0,810 # ffffffffc0202140 <commands+0x518>
ffffffffc0200e1e:	d8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e22:	00001697          	auipc	a3,0x1
ffffffffc0200e26:	5b668693          	addi	a3,a3,1462 # ffffffffc02023d8 <commands+0x7b0>
ffffffffc0200e2a:	00001617          	auipc	a2,0x1
ffffffffc0200e2e:	2fe60613          	addi	a2,a2,766 # ffffffffc0202128 <commands+0x500>
ffffffffc0200e32:	14900593          	li	a1,329
ffffffffc0200e36:	00001517          	auipc	a0,0x1
ffffffffc0200e3a:	30a50513          	addi	a0,a0,778 # ffffffffc0202140 <commands+0x518>
ffffffffc0200e3e:	d6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e42:	00001697          	auipc	a3,0x1
ffffffffc0200e46:	58668693          	addi	a3,a3,1414 # ffffffffc02023c8 <commands+0x7a0>
ffffffffc0200e4a:	00001617          	auipc	a2,0x1
ffffffffc0200e4e:	2de60613          	addi	a2,a2,734 # ffffffffc0202128 <commands+0x500>
ffffffffc0200e52:	14100593          	li	a1,321
ffffffffc0200e56:	00001517          	auipc	a0,0x1
ffffffffc0200e5a:	2ea50513          	addi	a0,a0,746 # ffffffffc0202140 <commands+0x518>
ffffffffc0200e5e:	d4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e62:	00001697          	auipc	a3,0x1
ffffffffc0200e66:	54e68693          	addi	a3,a3,1358 # ffffffffc02023b0 <commands+0x788>
ffffffffc0200e6a:	00001617          	auipc	a2,0x1
ffffffffc0200e6e:	2be60613          	addi	a2,a2,702 # ffffffffc0202128 <commands+0x500>
ffffffffc0200e72:	14000593          	li	a1,320
ffffffffc0200e76:	00001517          	auipc	a0,0x1
ffffffffc0200e7a:	2ca50513          	addi	a0,a0,714 # ffffffffc0202140 <commands+0x518>
ffffffffc0200e7e:	d2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e82:	00001697          	auipc	a3,0x1
ffffffffc0200e86:	50e68693          	addi	a3,a3,1294 # ffffffffc0202390 <commands+0x768>
ffffffffc0200e8a:	00001617          	auipc	a2,0x1
ffffffffc0200e8e:	29e60613          	addi	a2,a2,670 # ffffffffc0202128 <commands+0x500>
ffffffffc0200e92:	13f00593          	li	a1,319
ffffffffc0200e96:	00001517          	auipc	a0,0x1
ffffffffc0200e9a:	2aa50513          	addi	a0,a0,682 # ffffffffc0202140 <commands+0x518>
ffffffffc0200e9e:	d0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200ea2:	00001697          	auipc	a3,0x1
ffffffffc0200ea6:	4be68693          	addi	a3,a3,1214 # ffffffffc0202360 <commands+0x738>
ffffffffc0200eaa:	00001617          	auipc	a2,0x1
ffffffffc0200eae:	27e60613          	addi	a2,a2,638 # ffffffffc0202128 <commands+0x500>
ffffffffc0200eb2:	13d00593          	li	a1,317
ffffffffc0200eb6:	00001517          	auipc	a0,0x1
ffffffffc0200eba:	28a50513          	addi	a0,a0,650 # ffffffffc0202140 <commands+0x518>
ffffffffc0200ebe:	ceeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ec2:	00001697          	auipc	a3,0x1
ffffffffc0200ec6:	48668693          	addi	a3,a3,1158 # ffffffffc0202348 <commands+0x720>
ffffffffc0200eca:	00001617          	auipc	a2,0x1
ffffffffc0200ece:	25e60613          	addi	a2,a2,606 # ffffffffc0202128 <commands+0x500>
ffffffffc0200ed2:	13c00593          	li	a1,316
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	26a50513          	addi	a0,a0,618 # ffffffffc0202140 <commands+0x518>
ffffffffc0200ede:	cceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ee2:	00001697          	auipc	a3,0x1
ffffffffc0200ee6:	3ce68693          	addi	a3,a3,974 # ffffffffc02022b0 <commands+0x688>
ffffffffc0200eea:	00001617          	auipc	a2,0x1
ffffffffc0200eee:	23e60613          	addi	a2,a2,574 # ffffffffc0202128 <commands+0x500>
ffffffffc0200ef2:	13000593          	li	a1,304
ffffffffc0200ef6:	00001517          	auipc	a0,0x1
ffffffffc0200efa:	24a50513          	addi	a0,a0,586 # ffffffffc0202140 <commands+0x518>
ffffffffc0200efe:	caeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f02:	00001697          	auipc	a3,0x1
ffffffffc0200f06:	42e68693          	addi	a3,a3,1070 # ffffffffc0202330 <commands+0x708>
ffffffffc0200f0a:	00001617          	auipc	a2,0x1
ffffffffc0200f0e:	21e60613          	addi	a2,a2,542 # ffffffffc0202128 <commands+0x500>
ffffffffc0200f12:	12700593          	li	a1,295
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	22a50513          	addi	a0,a0,554 # ffffffffc0202140 <commands+0x518>
ffffffffc0200f1e:	c8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200f22:	00001697          	auipc	a3,0x1
ffffffffc0200f26:	3fe68693          	addi	a3,a3,1022 # ffffffffc0202320 <commands+0x6f8>
ffffffffc0200f2a:	00001617          	auipc	a2,0x1
ffffffffc0200f2e:	1fe60613          	addi	a2,a2,510 # ffffffffc0202128 <commands+0x500>
ffffffffc0200f32:	12600593          	li	a1,294
ffffffffc0200f36:	00001517          	auipc	a0,0x1
ffffffffc0200f3a:	20a50513          	addi	a0,a0,522 # ffffffffc0202140 <commands+0x518>
ffffffffc0200f3e:	c6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200f42:	00001697          	auipc	a3,0x1
ffffffffc0200f46:	3ce68693          	addi	a3,a3,974 # ffffffffc0202310 <commands+0x6e8>
ffffffffc0200f4a:	00001617          	auipc	a2,0x1
ffffffffc0200f4e:	1de60613          	addi	a2,a2,478 # ffffffffc0202128 <commands+0x500>
ffffffffc0200f52:	10800593          	li	a1,264
ffffffffc0200f56:	00001517          	auipc	a0,0x1
ffffffffc0200f5a:	1ea50513          	addi	a0,a0,490 # ffffffffc0202140 <commands+0x518>
ffffffffc0200f5e:	c4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f62:	00001697          	auipc	a3,0x1
ffffffffc0200f66:	34e68693          	addi	a3,a3,846 # ffffffffc02022b0 <commands+0x688>
ffffffffc0200f6a:	00001617          	auipc	a2,0x1
ffffffffc0200f6e:	1be60613          	addi	a2,a2,446 # ffffffffc0202128 <commands+0x500>
ffffffffc0200f72:	10600593          	li	a1,262
ffffffffc0200f76:	00001517          	auipc	a0,0x1
ffffffffc0200f7a:	1ca50513          	addi	a0,a0,458 # ffffffffc0202140 <commands+0x518>
ffffffffc0200f7e:	c2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f82:	00001697          	auipc	a3,0x1
ffffffffc0200f86:	36e68693          	addi	a3,a3,878 # ffffffffc02022f0 <commands+0x6c8>
ffffffffc0200f8a:	00001617          	auipc	a2,0x1
ffffffffc0200f8e:	19e60613          	addi	a2,a2,414 # ffffffffc0202128 <commands+0x500>
ffffffffc0200f92:	10500593          	li	a1,261
ffffffffc0200f96:	00001517          	auipc	a0,0x1
ffffffffc0200f9a:	1aa50513          	addi	a0,a0,426 # ffffffffc0202140 <commands+0x518>
ffffffffc0200f9e:	c0eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200fa2 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200fa2:	1141                	addi	sp,sp,-16
ffffffffc0200fa4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fa6:	14058a63          	beqz	a1,ffffffffc02010fa <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0200faa:	00259693          	slli	a3,a1,0x2
ffffffffc0200fae:	96ae                	add	a3,a3,a1
ffffffffc0200fb0:	068e                	slli	a3,a3,0x3
ffffffffc0200fb2:	96aa                	add	a3,a3,a0
ffffffffc0200fb4:	87aa                	mv	a5,a0
ffffffffc0200fb6:	02d50263          	beq	a0,a3,ffffffffc0200fda <best_fit_free_pages+0x38>
ffffffffc0200fba:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fbc:	8b05                	andi	a4,a4,1
ffffffffc0200fbe:	10071e63          	bnez	a4,ffffffffc02010da <best_fit_free_pages+0x138>
ffffffffc0200fc2:	6798                	ld	a4,8(a5)
ffffffffc0200fc4:	8b09                	andi	a4,a4,2
ffffffffc0200fc6:	10071a63          	bnez	a4,ffffffffc02010da <best_fit_free_pages+0x138>
        p->flags = 0;      // 清除页标志
ffffffffc0200fca:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200fce:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fd2:	02878793          	addi	a5,a5,40
ffffffffc0200fd6:	fed792e3          	bne	a5,a3,ffffffffc0200fba <best_fit_free_pages+0x18>
    base->property = n;            // 设置空闲块大小
ffffffffc0200fda:	2581                	sext.w	a1,a1
ffffffffc0200fdc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);         // 标记为空闲
ffffffffc0200fde:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200fe2:	4789                	li	a5,2
ffffffffc0200fe4:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;                  // 更新空闲页数量
ffffffffc0200fe8:	00005697          	auipc	a3,0x5
ffffffffc0200fec:	02868693          	addi	a3,a3,40 # ffffffffc0206010 <free_area>
ffffffffc0200ff0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0200ff2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200ff4:	01850613          	addi	a2,a0,24
    nr_free += n;                  // 更新空闲页数量
ffffffffc0200ff8:	9db9                	addw	a1,a1,a4
ffffffffc0200ffa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200ffc:	0ad78863          	beq	a5,a3,ffffffffc02010ac <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201000:	fe878713          	addi	a4,a5,-24
ffffffffc0201004:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201008:	4581                	li	a1,0
            if (base < page) {
ffffffffc020100a:	00e56a63          	bltu	a0,a4,ffffffffc020101e <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020100e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201010:	06d70263          	beq	a4,a3,ffffffffc0201074 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201014:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201016:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020101a:	fee57ae3          	bgeu	a0,a4,ffffffffc020100e <best_fit_free_pages+0x6c>
ffffffffc020101e:	c199                	beqz	a1,ffffffffc0201024 <best_fit_free_pages+0x82>
ffffffffc0201020:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201024:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201026:	e390                	sd	a2,0(a5)
ffffffffc0201028:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020102a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020102c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020102e:	02d70063          	beq	a4,a3,ffffffffc020104e <best_fit_free_pages+0xac>
        if (p + p->property == base) { // 如果前块与当前块相连
ffffffffc0201032:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201036:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) { // 如果前块与当前块相连
ffffffffc020103a:	02081613          	slli	a2,a6,0x20
ffffffffc020103e:	9201                	srli	a2,a2,0x20
ffffffffc0201040:	00261793          	slli	a5,a2,0x2
ffffffffc0201044:	97b2                	add	a5,a5,a2
ffffffffc0201046:	078e                	slli	a5,a5,0x3
ffffffffc0201048:	97ae                	add	a5,a5,a1
ffffffffc020104a:	02f50f63          	beq	a0,a5,ffffffffc0201088 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc020104e:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201050:	00d70f63          	beq	a4,a3,ffffffffc020106e <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201054:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201056:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020105a:	02059613          	slli	a2,a1,0x20
ffffffffc020105e:	9201                	srli	a2,a2,0x20
ffffffffc0201060:	00261793          	slli	a5,a2,0x2
ffffffffc0201064:	97b2                	add	a5,a5,a2
ffffffffc0201066:	078e                	slli	a5,a5,0x3
ffffffffc0201068:	97aa                	add	a5,a5,a0
ffffffffc020106a:	04f68863          	beq	a3,a5,ffffffffc02010ba <best_fit_free_pages+0x118>
}
ffffffffc020106e:	60a2                	ld	ra,8(sp)
ffffffffc0201070:	0141                	addi	sp,sp,16
ffffffffc0201072:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201074:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201076:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201078:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020107a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020107c:	02d70563          	beq	a4,a3,ffffffffc02010a6 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201080:	8832                	mv	a6,a2
ffffffffc0201082:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201084:	87ba                	mv	a5,a4
ffffffffc0201086:	bf41                	j	ffffffffc0201016 <best_fit_free_pages+0x74>
             p->property += base->property; // 更新块大小
ffffffffc0201088:	491c                	lw	a5,16(a0)
ffffffffc020108a:	0107883b          	addw	a6,a5,a6
ffffffffc020108e:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201092:	57f5                	li	a5,-3
ffffffffc0201094:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201098:	6d10                	ld	a2,24(a0)
ffffffffc020109a:	711c                	ld	a5,32(a0)
             base = p; // 继续合并
ffffffffc020109c:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020109e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02010a0:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02010a2:	e390                	sd	a2,0(a5)
ffffffffc02010a4:	b775                	j	ffffffffc0201050 <best_fit_free_pages+0xae>
ffffffffc02010a6:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02010a8:	873e                	mv	a4,a5
ffffffffc02010aa:	b761                	j	ffffffffc0201032 <best_fit_free_pages+0x90>
}
ffffffffc02010ac:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02010ae:	e390                	sd	a2,0(a5)
ffffffffc02010b0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010b2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010b4:	ed1c                	sd	a5,24(a0)
ffffffffc02010b6:	0141                	addi	sp,sp,16
ffffffffc02010b8:	8082                	ret
            base->property += p->property;
ffffffffc02010ba:	ff872783          	lw	a5,-8(a4)
ffffffffc02010be:	ff070693          	addi	a3,a4,-16
ffffffffc02010c2:	9dbd                	addw	a1,a1,a5
ffffffffc02010c4:	c90c                	sw	a1,16(a0)
ffffffffc02010c6:	57f5                	li	a5,-3
ffffffffc02010c8:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010cc:	6314                	ld	a3,0(a4)
ffffffffc02010ce:	671c                	ld	a5,8(a4)
}
ffffffffc02010d0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02010d2:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02010d4:	e394                	sd	a3,0(a5)
ffffffffc02010d6:	0141                	addi	sp,sp,16
ffffffffc02010d8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010da:	00001697          	auipc	a3,0x1
ffffffffc02010de:	33e68693          	addi	a3,a3,830 # ffffffffc0202418 <commands+0x7f0>
ffffffffc02010e2:	00001617          	auipc	a2,0x1
ffffffffc02010e6:	04660613          	addi	a2,a2,70 # ffffffffc0202128 <commands+0x500>
ffffffffc02010ea:	09e00593          	li	a1,158
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	05250513          	addi	a0,a0,82 # ffffffffc0202140 <commands+0x518>
ffffffffc02010f6:	ab6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02010fa:	00001697          	auipc	a3,0x1
ffffffffc02010fe:	02668693          	addi	a3,a3,38 # ffffffffc0202120 <commands+0x4f8>
ffffffffc0201102:	00001617          	auipc	a2,0x1
ffffffffc0201106:	02660613          	addi	a2,a2,38 # ffffffffc0202128 <commands+0x500>
ffffffffc020110a:	09b00593          	li	a1,155
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	03250513          	addi	a0,a0,50 # ffffffffc0202140 <commands+0x518>
ffffffffc0201116:	a96ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020111a <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020111a:	1141                	addi	sp,sp,-16
ffffffffc020111c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020111e:	c9ed                	beqz	a1,ffffffffc0201210 <best_fit_init_memmap+0xf6>
    for (; p != base + n; p ++) {
ffffffffc0201120:	00259693          	slli	a3,a1,0x2
ffffffffc0201124:	96ae                	add	a3,a3,a1
ffffffffc0201126:	068e                	slli	a3,a3,0x3
ffffffffc0201128:	96aa                	add	a3,a3,a0
ffffffffc020112a:	87aa                	mv	a5,a0
ffffffffc020112c:	02d50063          	beq	a0,a3,ffffffffc020114c <best_fit_init_memmap+0x32>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201130:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201132:	8b05                	andi	a4,a4,1
ffffffffc0201134:	cf55                	beqz	a4,ffffffffc02011f0 <best_fit_init_memmap+0xd6>
ffffffffc0201136:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));  // 确保当前页是保留状态
ffffffffc0201138:	8b05                	andi	a4,a4,1
ffffffffc020113a:	cb59                	beqz	a4,ffffffffc02011d0 <best_fit_init_memmap+0xb6>
        p->flags = 0;             // 清除页标志
ffffffffc020113c:	0007b423          	sd	zero,8(a5)
ffffffffc0201140:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201144:	02878793          	addi	a5,a5,40
ffffffffc0201148:	fed794e3          	bne	a5,a3,ffffffffc0201130 <best_fit_init_memmap+0x16>
    base->property = n;           // 设置空闲块的大小
ffffffffc020114c:	2581                	sext.w	a1,a1
ffffffffc020114e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201150:	4789                	li	a5,2
ffffffffc0201152:	00850713          	addi	a4,a0,8
ffffffffc0201156:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;                 // 更新空闲页总数
ffffffffc020115a:	00005697          	auipc	a3,0x5
ffffffffc020115e:	eb668693          	addi	a3,a3,-330 # ffffffffc0206010 <free_area>
ffffffffc0201162:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201164:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201166:	01850613          	addi	a2,a0,24
    nr_free += n;                 // 更新空闲页总数
ffffffffc020116a:	9db9                	addw	a1,a1,a4
ffffffffc020116c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020116e:	04d78a63          	beq	a5,a3,ffffffffc02011c2 <best_fit_init_memmap+0xa8>
            struct Page* page = le2page(le, page_link);
ffffffffc0201172:	fe878713          	addi	a4,a5,-24
ffffffffc0201176:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020117a:	4581                	li	a1,0
            if (base < page) { // 插入到第一个比base大的页前面
ffffffffc020117c:	00e56a63          	bltu	a0,a4,ffffffffc0201190 <best_fit_init_memmap+0x76>
    return listelm->next;
ffffffffc0201180:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0201182:	02d70263          	beq	a4,a3,ffffffffc02011a6 <best_fit_init_memmap+0x8c>
    for (; p != base + n; p ++) {
ffffffffc0201186:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201188:	fe878713          	addi	a4,a5,-24
            if (base < page) { // 插入到第一个比base大的页前面
ffffffffc020118c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201180 <best_fit_init_memmap+0x66>
ffffffffc0201190:	c199                	beqz	a1,ffffffffc0201196 <best_fit_init_memmap+0x7c>
ffffffffc0201192:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201196:	6398                	ld	a4,0(a5)
}
ffffffffc0201198:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020119a:	e390                	sd	a2,0(a5)
ffffffffc020119c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020119e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011a0:	ed18                	sd	a4,24(a0)
ffffffffc02011a2:	0141                	addi	sp,sp,16
ffffffffc02011a4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02011a6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011a8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02011aa:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02011ac:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02011ae:	00d70663          	beq	a4,a3,ffffffffc02011ba <best_fit_init_memmap+0xa0>
    prev->next = next->prev = elm;
ffffffffc02011b2:	8832                	mv	a6,a2
ffffffffc02011b4:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02011b6:	87ba                	mv	a5,a4
ffffffffc02011b8:	bfc1                	j	ffffffffc0201188 <best_fit_init_memmap+0x6e>
}
ffffffffc02011ba:	60a2                	ld	ra,8(sp)
ffffffffc02011bc:	e290                	sd	a2,0(a3)
ffffffffc02011be:	0141                	addi	sp,sp,16
ffffffffc02011c0:	8082                	ret
ffffffffc02011c2:	60a2                	ld	ra,8(sp)
ffffffffc02011c4:	e390                	sd	a2,0(a5)
ffffffffc02011c6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011c8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011ca:	ed1c                	sd	a5,24(a0)
ffffffffc02011cc:	0141                	addi	sp,sp,16
ffffffffc02011ce:	8082                	ret
        assert(PageReserved(p));  // 确保当前页是保留状态
ffffffffc02011d0:	00001697          	auipc	a3,0x1
ffffffffc02011d4:	27068693          	addi	a3,a3,624 # ffffffffc0202440 <commands+0x818>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	f5060613          	addi	a2,a2,-176 # ffffffffc0202128 <commands+0x500>
ffffffffc02011e0:	05400593          	li	a1,84
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	f5c50513          	addi	a0,a0,-164 # ffffffffc0202140 <commands+0x518>
ffffffffc02011ec:	9c0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
        assert(PageReserved(p));
ffffffffc02011f0:	00001697          	auipc	a3,0x1
ffffffffc02011f4:	25068693          	addi	a3,a3,592 # ffffffffc0202440 <commands+0x818>
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	f3060613          	addi	a2,a2,-208 # ffffffffc0202128 <commands+0x500>
ffffffffc0201200:	05000593          	li	a1,80
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	f3c50513          	addi	a0,a0,-196 # ffffffffc0202140 <commands+0x518>
ffffffffc020120c:	9a0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0201210:	00001697          	auipc	a3,0x1
ffffffffc0201214:	f1068693          	addi	a3,a3,-240 # ffffffffc0202120 <commands+0x4f8>
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	f1060613          	addi	a2,a2,-240 # ffffffffc0202128 <commands+0x500>
ffffffffc0201220:	04d00593          	li	a1,77
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	f1c50513          	addi	a0,a0,-228 # ffffffffc0202140 <commands+0x518>
ffffffffc020122c:	980ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201230 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201230:	100027f3          	csrr	a5,sstatus
ffffffffc0201234:	8b89                	andi	a5,a5,2
ffffffffc0201236:	e799                	bnez	a5,ffffffffc0201244 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201238:	00005797          	auipc	a5,0x5
ffffffffc020123c:	3007b783          	ld	a5,768(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc0201240:	6f9c                	ld	a5,24(a5)
ffffffffc0201242:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201244:	1141                	addi	sp,sp,-16
ffffffffc0201246:	e406                	sd	ra,8(sp)
ffffffffc0201248:	e022                	sd	s0,0(sp)
ffffffffc020124a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020124c:	a12ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201250:	00005797          	auipc	a5,0x5
ffffffffc0201254:	2e87b783          	ld	a5,744(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc0201258:	6f9c                	ld	a5,24(a5)
ffffffffc020125a:	8522                	mv	a0,s0
ffffffffc020125c:	9782                	jalr	a5
ffffffffc020125e:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201260:	9f8ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201264:	60a2                	ld	ra,8(sp)
ffffffffc0201266:	8522                	mv	a0,s0
ffffffffc0201268:	6402                	ld	s0,0(sp)
ffffffffc020126a:	0141                	addi	sp,sp,16
ffffffffc020126c:	8082                	ret

ffffffffc020126e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020126e:	100027f3          	csrr	a5,sstatus
ffffffffc0201272:	8b89                	andi	a5,a5,2
ffffffffc0201274:	e799                	bnez	a5,ffffffffc0201282 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201276:	00005797          	auipc	a5,0x5
ffffffffc020127a:	2c27b783          	ld	a5,706(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc020127e:	739c                	ld	a5,32(a5)
ffffffffc0201280:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201282:	1101                	addi	sp,sp,-32
ffffffffc0201284:	ec06                	sd	ra,24(sp)
ffffffffc0201286:	e822                	sd	s0,16(sp)
ffffffffc0201288:	e426                	sd	s1,8(sp)
ffffffffc020128a:	842a                	mv	s0,a0
ffffffffc020128c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020128e:	9d0ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201292:	00005797          	auipc	a5,0x5
ffffffffc0201296:	2a67b783          	ld	a5,678(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc020129a:	739c                	ld	a5,32(a5)
ffffffffc020129c:	85a6                	mv	a1,s1
ffffffffc020129e:	8522                	mv	a0,s0
ffffffffc02012a0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02012a2:	6442                	ld	s0,16(sp)
ffffffffc02012a4:	60e2                	ld	ra,24(sp)
ffffffffc02012a6:	64a2                	ld	s1,8(sp)
ffffffffc02012a8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02012aa:	9aeff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc02012ae <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012ae:	100027f3          	csrr	a5,sstatus
ffffffffc02012b2:	8b89                	andi	a5,a5,2
ffffffffc02012b4:	e799                	bnez	a5,ffffffffc02012c2 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02012b6:	00005797          	auipc	a5,0x5
ffffffffc02012ba:	2827b783          	ld	a5,642(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc02012be:	779c                	ld	a5,40(a5)
ffffffffc02012c0:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02012c2:	1141                	addi	sp,sp,-16
ffffffffc02012c4:	e406                	sd	ra,8(sp)
ffffffffc02012c6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02012c8:	996ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02012cc:	00005797          	auipc	a5,0x5
ffffffffc02012d0:	26c7b783          	ld	a5,620(a5) # ffffffffc0206538 <pmm_manager>
ffffffffc02012d4:	779c                	ld	a5,40(a5)
ffffffffc02012d6:	9782                	jalr	a5
ffffffffc02012d8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02012da:	97eff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02012de:	60a2                	ld	ra,8(sp)
ffffffffc02012e0:	8522                	mv	a0,s0
ffffffffc02012e2:	6402                	ld	s0,0(sp)
ffffffffc02012e4:	0141                	addi	sp,sp,16
ffffffffc02012e6:	8082                	ret

ffffffffc02012e8 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012e8:	00001797          	auipc	a5,0x1
ffffffffc02012ec:	18078793          	addi	a5,a5,384 # ffffffffc0202468 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012f0:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02012f2:	1101                	addi	sp,sp,-32
ffffffffc02012f4:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	1aa50513          	addi	a0,a0,426 # ffffffffc02024a0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012fe:	00005497          	auipc	s1,0x5
ffffffffc0201302:	23a48493          	addi	s1,s1,570 # ffffffffc0206538 <pmm_manager>
void pmm_init(void) {
ffffffffc0201306:	ec06                	sd	ra,24(sp)
ffffffffc0201308:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020130a:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020130c:	da7fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0201310:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201312:	00005417          	auipc	s0,0x5
ffffffffc0201316:	23e40413          	addi	s0,s0,574 # ffffffffc0206550 <va_pa_offset>
    pmm_manager->init();
ffffffffc020131a:	679c                	ld	a5,8(a5)
ffffffffc020131c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020131e:	57f5                	li	a5,-3
ffffffffc0201320:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201322:	00001517          	auipc	a0,0x1
ffffffffc0201326:	19650513          	addi	a0,a0,406 # ffffffffc02024b8 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020132a:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc020132c:	d87fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201330:	46c5                	li	a3,17
ffffffffc0201332:	06ee                	slli	a3,a3,0x1b
ffffffffc0201334:	40100613          	li	a2,1025
ffffffffc0201338:	16fd                	addi	a3,a3,-1
ffffffffc020133a:	07e005b7          	lui	a1,0x7e00
ffffffffc020133e:	0656                	slli	a2,a2,0x15
ffffffffc0201340:	00001517          	auipc	a0,0x1
ffffffffc0201344:	19050513          	addi	a0,a0,400 # ffffffffc02024d0 <best_fit_pmm_manager+0x68>
ffffffffc0201348:	d6bfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020134c:	777d                	lui	a4,0xfffff
ffffffffc020134e:	00006797          	auipc	a5,0x6
ffffffffc0201352:	21178793          	addi	a5,a5,529 # ffffffffc020755f <end+0xfff>
ffffffffc0201356:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201358:	00005517          	auipc	a0,0x5
ffffffffc020135c:	1d050513          	addi	a0,a0,464 # ffffffffc0206528 <npage>
ffffffffc0201360:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201364:	00005597          	auipc	a1,0x5
ffffffffc0201368:	1cc58593          	addi	a1,a1,460 # ffffffffc0206530 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020136c:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020136e:	e19c                	sd	a5,0(a1)
ffffffffc0201370:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201372:	4701                	li	a4,0
ffffffffc0201374:	4885                	li	a7,1
ffffffffc0201376:	fff80837          	lui	a6,0xfff80
ffffffffc020137a:	a011                	j	ffffffffc020137e <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc020137c:	619c                	ld	a5,0(a1)
ffffffffc020137e:	97b6                	add	a5,a5,a3
ffffffffc0201380:	07a1                	addi	a5,a5,8
ffffffffc0201382:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201386:	611c                	ld	a5,0(a0)
ffffffffc0201388:	0705                	addi	a4,a4,1
ffffffffc020138a:	02868693          	addi	a3,a3,40
ffffffffc020138e:	01078633          	add	a2,a5,a6
ffffffffc0201392:	fec765e3          	bltu	a4,a2,ffffffffc020137c <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201396:	6190                	ld	a2,0(a1)
ffffffffc0201398:	00279713          	slli	a4,a5,0x2
ffffffffc020139c:	973e                	add	a4,a4,a5
ffffffffc020139e:	fec006b7          	lui	a3,0xfec00
ffffffffc02013a2:	070e                	slli	a4,a4,0x3
ffffffffc02013a4:	96b2                	add	a3,a3,a2
ffffffffc02013a6:	96ba                	add	a3,a3,a4
ffffffffc02013a8:	c0200737          	lui	a4,0xc0200
ffffffffc02013ac:	08e6ef63          	bltu	a3,a4,ffffffffc020144a <pmm_init+0x162>
ffffffffc02013b0:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02013b2:	45c5                	li	a1,17
ffffffffc02013b4:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013b6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02013b8:	04b6e863          	bltu	a3,a1,ffffffffc0201408 <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02013bc:	609c                	ld	a5,0(s1)
ffffffffc02013be:	7b9c                	ld	a5,48(a5)
ffffffffc02013c0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013c2:	00001517          	auipc	a0,0x1
ffffffffc02013c6:	1a650513          	addi	a0,a0,422 # ffffffffc0202568 <best_fit_pmm_manager+0x100>
ffffffffc02013ca:	ce9fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02013ce:	00004597          	auipc	a1,0x4
ffffffffc02013d2:	c3258593          	addi	a1,a1,-974 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02013d6:	00005797          	auipc	a5,0x5
ffffffffc02013da:	16b7b923          	sd	a1,370(a5) # ffffffffc0206548 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013de:	c02007b7          	lui	a5,0xc0200
ffffffffc02013e2:	08f5e063          	bltu	a1,a5,ffffffffc0201462 <pmm_init+0x17a>
ffffffffc02013e6:	6010                	ld	a2,0(s0)
}
ffffffffc02013e8:	6442                	ld	s0,16(sp)
ffffffffc02013ea:	60e2                	ld	ra,24(sp)
ffffffffc02013ec:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02013ee:	40c58633          	sub	a2,a1,a2
ffffffffc02013f2:	00005797          	auipc	a5,0x5
ffffffffc02013f6:	14c7b723          	sd	a2,334(a5) # ffffffffc0206540 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013fa:	00001517          	auipc	a0,0x1
ffffffffc02013fe:	18e50513          	addi	a0,a0,398 # ffffffffc0202588 <best_fit_pmm_manager+0x120>
}
ffffffffc0201402:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201404:	caffe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201408:	6705                	lui	a4,0x1
ffffffffc020140a:	177d                	addi	a4,a4,-1
ffffffffc020140c:	96ba                	add	a3,a3,a4
ffffffffc020140e:	777d                	lui	a4,0xfffff
ffffffffc0201410:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201412:	00c6d513          	srli	a0,a3,0xc
ffffffffc0201416:	00f57e63          	bgeu	a0,a5,ffffffffc0201432 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc020141a:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020141c:	982a                	add	a6,a6,a0
ffffffffc020141e:	00281513          	slli	a0,a6,0x2
ffffffffc0201422:	9542                	add	a0,a0,a6
ffffffffc0201424:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201426:	8d95                	sub	a1,a1,a3
ffffffffc0201428:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020142a:	81b1                	srli	a1,a1,0xc
ffffffffc020142c:	9532                	add	a0,a0,a2
ffffffffc020142e:	9782                	jalr	a5
}
ffffffffc0201430:	b771                	j	ffffffffc02013bc <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc0201432:	00001617          	auipc	a2,0x1
ffffffffc0201436:	10660613          	addi	a2,a2,262 # ffffffffc0202538 <best_fit_pmm_manager+0xd0>
ffffffffc020143a:	06c00593          	li	a1,108
ffffffffc020143e:	00001517          	auipc	a0,0x1
ffffffffc0201442:	11a50513          	addi	a0,a0,282 # ffffffffc0202558 <best_fit_pmm_manager+0xf0>
ffffffffc0201446:	f67fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020144a:	00001617          	auipc	a2,0x1
ffffffffc020144e:	0b660613          	addi	a2,a2,182 # ffffffffc0202500 <best_fit_pmm_manager+0x98>
ffffffffc0201452:	07200593          	li	a1,114
ffffffffc0201456:	00001517          	auipc	a0,0x1
ffffffffc020145a:	0d250513          	addi	a0,a0,210 # ffffffffc0202528 <best_fit_pmm_manager+0xc0>
ffffffffc020145e:	f4ffe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201462:	86ae                	mv	a3,a1
ffffffffc0201464:	00001617          	auipc	a2,0x1
ffffffffc0201468:	09c60613          	addi	a2,a2,156 # ffffffffc0202500 <best_fit_pmm_manager+0x98>
ffffffffc020146c:	08d00593          	li	a1,141
ffffffffc0201470:	00001517          	auipc	a0,0x1
ffffffffc0201474:	0b850513          	addi	a0,a0,184 # ffffffffc0202528 <best_fit_pmm_manager+0xc0>
ffffffffc0201478:	f35fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020147c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020147c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201480:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201482:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201486:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201488:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020148c:	f022                	sd	s0,32(sp)
ffffffffc020148e:	ec26                	sd	s1,24(sp)
ffffffffc0201490:	e84a                	sd	s2,16(sp)
ffffffffc0201492:	f406                	sd	ra,40(sp)
ffffffffc0201494:	e44e                	sd	s3,8(sp)
ffffffffc0201496:	84aa                	mv	s1,a0
ffffffffc0201498:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020149a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020149e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02014a0:	03067e63          	bgeu	a2,a6,ffffffffc02014dc <printnum+0x60>
ffffffffc02014a4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02014a6:	00805763          	blez	s0,ffffffffc02014b4 <printnum+0x38>
ffffffffc02014aa:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02014ac:	85ca                	mv	a1,s2
ffffffffc02014ae:	854e                	mv	a0,s3
ffffffffc02014b0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02014b2:	fc65                	bnez	s0,ffffffffc02014aa <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014b4:	1a02                	slli	s4,s4,0x20
ffffffffc02014b6:	00001797          	auipc	a5,0x1
ffffffffc02014ba:	11278793          	addi	a5,a5,274 # ffffffffc02025c8 <best_fit_pmm_manager+0x160>
ffffffffc02014be:	020a5a13          	srli	s4,s4,0x20
ffffffffc02014c2:	9a3e                	add	s4,s4,a5
}
ffffffffc02014c4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014c6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02014ca:	70a2                	ld	ra,40(sp)
ffffffffc02014cc:	69a2                	ld	s3,8(sp)
ffffffffc02014ce:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014d0:	85ca                	mv	a1,s2
ffffffffc02014d2:	87a6                	mv	a5,s1
}
ffffffffc02014d4:	6942                	ld	s2,16(sp)
ffffffffc02014d6:	64e2                	ld	s1,24(sp)
ffffffffc02014d8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014da:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02014dc:	03065633          	divu	a2,a2,a6
ffffffffc02014e0:	8722                	mv	a4,s0
ffffffffc02014e2:	f9bff0ef          	jal	ra,ffffffffc020147c <printnum>
ffffffffc02014e6:	b7f9                	j	ffffffffc02014b4 <printnum+0x38>

ffffffffc02014e8 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02014e8:	7119                	addi	sp,sp,-128
ffffffffc02014ea:	f4a6                	sd	s1,104(sp)
ffffffffc02014ec:	f0ca                	sd	s2,96(sp)
ffffffffc02014ee:	ecce                	sd	s3,88(sp)
ffffffffc02014f0:	e8d2                	sd	s4,80(sp)
ffffffffc02014f2:	e4d6                	sd	s5,72(sp)
ffffffffc02014f4:	e0da                	sd	s6,64(sp)
ffffffffc02014f6:	fc5e                	sd	s7,56(sp)
ffffffffc02014f8:	f06a                	sd	s10,32(sp)
ffffffffc02014fa:	fc86                	sd	ra,120(sp)
ffffffffc02014fc:	f8a2                	sd	s0,112(sp)
ffffffffc02014fe:	f862                	sd	s8,48(sp)
ffffffffc0201500:	f466                	sd	s9,40(sp)
ffffffffc0201502:	ec6e                	sd	s11,24(sp)
ffffffffc0201504:	892a                	mv	s2,a0
ffffffffc0201506:	84ae                	mv	s1,a1
ffffffffc0201508:	8d32                	mv	s10,a2
ffffffffc020150a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020150c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201510:	5b7d                	li	s6,-1
ffffffffc0201512:	00001a97          	auipc	s5,0x1
ffffffffc0201516:	0eaa8a93          	addi	s5,s5,234 # ffffffffc02025fc <best_fit_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020151a:	00001b97          	auipc	s7,0x1
ffffffffc020151e:	2beb8b93          	addi	s7,s7,702 # ffffffffc02027d8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201522:	000d4503          	lbu	a0,0(s10)
ffffffffc0201526:	001d0413          	addi	s0,s10,1
ffffffffc020152a:	01350a63          	beq	a0,s3,ffffffffc020153e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020152e:	c121                	beqz	a0,ffffffffc020156e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201530:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201532:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201534:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201536:	fff44503          	lbu	a0,-1(s0)
ffffffffc020153a:	ff351ae3          	bne	a0,s3,ffffffffc020152e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020153e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201542:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201546:	4c81                	li	s9,0
ffffffffc0201548:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020154a:	5c7d                	li	s8,-1
ffffffffc020154c:	5dfd                	li	s11,-1
ffffffffc020154e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201552:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201554:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201558:	0ff5f593          	andi	a1,a1,255
ffffffffc020155c:	00140d13          	addi	s10,s0,1
ffffffffc0201560:	04b56263          	bltu	a0,a1,ffffffffc02015a4 <vprintfmt+0xbc>
ffffffffc0201564:	058a                	slli	a1,a1,0x2
ffffffffc0201566:	95d6                	add	a1,a1,s5
ffffffffc0201568:	4194                	lw	a3,0(a1)
ffffffffc020156a:	96d6                	add	a3,a3,s5
ffffffffc020156c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020156e:	70e6                	ld	ra,120(sp)
ffffffffc0201570:	7446                	ld	s0,112(sp)
ffffffffc0201572:	74a6                	ld	s1,104(sp)
ffffffffc0201574:	7906                	ld	s2,96(sp)
ffffffffc0201576:	69e6                	ld	s3,88(sp)
ffffffffc0201578:	6a46                	ld	s4,80(sp)
ffffffffc020157a:	6aa6                	ld	s5,72(sp)
ffffffffc020157c:	6b06                	ld	s6,64(sp)
ffffffffc020157e:	7be2                	ld	s7,56(sp)
ffffffffc0201580:	7c42                	ld	s8,48(sp)
ffffffffc0201582:	7ca2                	ld	s9,40(sp)
ffffffffc0201584:	7d02                	ld	s10,32(sp)
ffffffffc0201586:	6de2                	ld	s11,24(sp)
ffffffffc0201588:	6109                	addi	sp,sp,128
ffffffffc020158a:	8082                	ret
            padc = '0';
ffffffffc020158c:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020158e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201592:	846a                	mv	s0,s10
ffffffffc0201594:	00140d13          	addi	s10,s0,1
ffffffffc0201598:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020159c:	0ff5f593          	andi	a1,a1,255
ffffffffc02015a0:	fcb572e3          	bgeu	a0,a1,ffffffffc0201564 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02015a4:	85a6                	mv	a1,s1
ffffffffc02015a6:	02500513          	li	a0,37
ffffffffc02015aa:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02015ac:	fff44783          	lbu	a5,-1(s0)
ffffffffc02015b0:	8d22                	mv	s10,s0
ffffffffc02015b2:	f73788e3          	beq	a5,s3,ffffffffc0201522 <vprintfmt+0x3a>
ffffffffc02015b6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02015ba:	1d7d                	addi	s10,s10,-1
ffffffffc02015bc:	ff379de3          	bne	a5,s3,ffffffffc02015b6 <vprintfmt+0xce>
ffffffffc02015c0:	b78d                	j	ffffffffc0201522 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02015c2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02015c6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015ca:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02015cc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02015d0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02015d4:	02d86463          	bltu	a6,a3,ffffffffc02015fc <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02015d8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02015dc:	002c169b          	slliw	a3,s8,0x2
ffffffffc02015e0:	0186873b          	addw	a4,a3,s8
ffffffffc02015e4:	0017171b          	slliw	a4,a4,0x1
ffffffffc02015e8:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02015ea:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02015ee:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02015f0:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02015f4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02015f8:	fed870e3          	bgeu	a6,a3,ffffffffc02015d8 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02015fc:	f40ddce3          	bgez	s11,ffffffffc0201554 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201600:	8de2                	mv	s11,s8
ffffffffc0201602:	5c7d                	li	s8,-1
ffffffffc0201604:	bf81                	j	ffffffffc0201554 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201606:	fffdc693          	not	a3,s11
ffffffffc020160a:	96fd                	srai	a3,a3,0x3f
ffffffffc020160c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201610:	00144603          	lbu	a2,1(s0)
ffffffffc0201614:	2d81                	sext.w	s11,s11
ffffffffc0201616:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201618:	bf35                	j	ffffffffc0201554 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020161a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020161e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201622:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201624:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201626:	bfd9                	j	ffffffffc02015fc <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201628:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020162a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020162e:	01174463          	blt	a4,a7,ffffffffc0201636 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201632:	1a088e63          	beqz	a7,ffffffffc02017ee <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201636:	000a3603          	ld	a2,0(s4)
ffffffffc020163a:	46c1                	li	a3,16
ffffffffc020163c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020163e:	2781                	sext.w	a5,a5
ffffffffc0201640:	876e                	mv	a4,s11
ffffffffc0201642:	85a6                	mv	a1,s1
ffffffffc0201644:	854a                	mv	a0,s2
ffffffffc0201646:	e37ff0ef          	jal	ra,ffffffffc020147c <printnum>
            break;
ffffffffc020164a:	bde1                	j	ffffffffc0201522 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020164c:	000a2503          	lw	a0,0(s4)
ffffffffc0201650:	85a6                	mv	a1,s1
ffffffffc0201652:	0a21                	addi	s4,s4,8
ffffffffc0201654:	9902                	jalr	s2
            break;
ffffffffc0201656:	b5f1                	j	ffffffffc0201522 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201658:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020165a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020165e:	01174463          	blt	a4,a7,ffffffffc0201666 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201662:	18088163          	beqz	a7,ffffffffc02017e4 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201666:	000a3603          	ld	a2,0(s4)
ffffffffc020166a:	46a9                	li	a3,10
ffffffffc020166c:	8a2e                	mv	s4,a1
ffffffffc020166e:	bfc1                	j	ffffffffc020163e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201670:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201674:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201676:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201678:	bdf1                	j	ffffffffc0201554 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020167a:	85a6                	mv	a1,s1
ffffffffc020167c:	02500513          	li	a0,37
ffffffffc0201680:	9902                	jalr	s2
            break;
ffffffffc0201682:	b545                	j	ffffffffc0201522 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201684:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201688:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020168a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020168c:	b5e1                	j	ffffffffc0201554 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020168e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201690:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201694:	01174463          	blt	a4,a7,ffffffffc020169c <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201698:	14088163          	beqz	a7,ffffffffc02017da <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020169c:	000a3603          	ld	a2,0(s4)
ffffffffc02016a0:	46a1                	li	a3,8
ffffffffc02016a2:	8a2e                	mv	s4,a1
ffffffffc02016a4:	bf69                	j	ffffffffc020163e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02016a6:	03000513          	li	a0,48
ffffffffc02016aa:	85a6                	mv	a1,s1
ffffffffc02016ac:	e03e                	sd	a5,0(sp)
ffffffffc02016ae:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02016b0:	85a6                	mv	a1,s1
ffffffffc02016b2:	07800513          	li	a0,120
ffffffffc02016b6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02016b8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02016ba:	6782                	ld	a5,0(sp)
ffffffffc02016bc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02016be:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02016c2:	bfb5                	j	ffffffffc020163e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02016c4:	000a3403          	ld	s0,0(s4)
ffffffffc02016c8:	008a0713          	addi	a4,s4,8
ffffffffc02016cc:	e03a                	sd	a4,0(sp)
ffffffffc02016ce:	14040263          	beqz	s0,ffffffffc0201812 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02016d2:	0fb05763          	blez	s11,ffffffffc02017c0 <vprintfmt+0x2d8>
ffffffffc02016d6:	02d00693          	li	a3,45
ffffffffc02016da:	0cd79163          	bne	a5,a3,ffffffffc020179c <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016de:	00044783          	lbu	a5,0(s0)
ffffffffc02016e2:	0007851b          	sext.w	a0,a5
ffffffffc02016e6:	cf85                	beqz	a5,ffffffffc020171e <vprintfmt+0x236>
ffffffffc02016e8:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016ec:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016f0:	000c4563          	bltz	s8,ffffffffc02016fa <vprintfmt+0x212>
ffffffffc02016f4:	3c7d                	addiw	s8,s8,-1
ffffffffc02016f6:	036c0263          	beq	s8,s6,ffffffffc020171a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02016fa:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016fc:	0e0c8e63          	beqz	s9,ffffffffc02017f8 <vprintfmt+0x310>
ffffffffc0201700:	3781                	addiw	a5,a5,-32
ffffffffc0201702:	0ef47b63          	bgeu	s0,a5,ffffffffc02017f8 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201706:	03f00513          	li	a0,63
ffffffffc020170a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020170c:	000a4783          	lbu	a5,0(s4)
ffffffffc0201710:	3dfd                	addiw	s11,s11,-1
ffffffffc0201712:	0a05                	addi	s4,s4,1
ffffffffc0201714:	0007851b          	sext.w	a0,a5
ffffffffc0201718:	ffe1                	bnez	a5,ffffffffc02016f0 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020171a:	01b05963          	blez	s11,ffffffffc020172c <vprintfmt+0x244>
ffffffffc020171e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201720:	85a6                	mv	a1,s1
ffffffffc0201722:	02000513          	li	a0,32
ffffffffc0201726:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201728:	fe0d9be3          	bnez	s11,ffffffffc020171e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020172c:	6a02                	ld	s4,0(sp)
ffffffffc020172e:	bbd5                	j	ffffffffc0201522 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201730:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201732:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201736:	01174463          	blt	a4,a7,ffffffffc020173e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020173a:	08088d63          	beqz	a7,ffffffffc02017d4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020173e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201742:	0a044d63          	bltz	s0,ffffffffc02017fc <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201746:	8622                	mv	a2,s0
ffffffffc0201748:	8a66                	mv	s4,s9
ffffffffc020174a:	46a9                	li	a3,10
ffffffffc020174c:	bdcd                	j	ffffffffc020163e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020174e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201752:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201754:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201756:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020175a:	8fb5                	xor	a5,a5,a3
ffffffffc020175c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201760:	02d74163          	blt	a4,a3,ffffffffc0201782 <vprintfmt+0x29a>
ffffffffc0201764:	00369793          	slli	a5,a3,0x3
ffffffffc0201768:	97de                	add	a5,a5,s7
ffffffffc020176a:	639c                	ld	a5,0(a5)
ffffffffc020176c:	cb99                	beqz	a5,ffffffffc0201782 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020176e:	86be                	mv	a3,a5
ffffffffc0201770:	00001617          	auipc	a2,0x1
ffffffffc0201774:	e8860613          	addi	a2,a2,-376 # ffffffffc02025f8 <best_fit_pmm_manager+0x190>
ffffffffc0201778:	85a6                	mv	a1,s1
ffffffffc020177a:	854a                	mv	a0,s2
ffffffffc020177c:	0ce000ef          	jal	ra,ffffffffc020184a <printfmt>
ffffffffc0201780:	b34d                	j	ffffffffc0201522 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201782:	00001617          	auipc	a2,0x1
ffffffffc0201786:	e6660613          	addi	a2,a2,-410 # ffffffffc02025e8 <best_fit_pmm_manager+0x180>
ffffffffc020178a:	85a6                	mv	a1,s1
ffffffffc020178c:	854a                	mv	a0,s2
ffffffffc020178e:	0bc000ef          	jal	ra,ffffffffc020184a <printfmt>
ffffffffc0201792:	bb41                	j	ffffffffc0201522 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201794:	00001417          	auipc	s0,0x1
ffffffffc0201798:	e4c40413          	addi	s0,s0,-436 # ffffffffc02025e0 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020179c:	85e2                	mv	a1,s8
ffffffffc020179e:	8522                	mv	a0,s0
ffffffffc02017a0:	e43e                	sd	a5,8(sp)
ffffffffc02017a2:	1cc000ef          	jal	ra,ffffffffc020196e <strnlen>
ffffffffc02017a6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02017aa:	01b05b63          	blez	s11,ffffffffc02017c0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02017ae:	67a2                	ld	a5,8(sp)
ffffffffc02017b0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017b4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02017b6:	85a6                	mv	a1,s1
ffffffffc02017b8:	8552                	mv	a0,s4
ffffffffc02017ba:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017bc:	fe0d9ce3          	bnez	s11,ffffffffc02017b4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017c0:	00044783          	lbu	a5,0(s0)
ffffffffc02017c4:	00140a13          	addi	s4,s0,1
ffffffffc02017c8:	0007851b          	sext.w	a0,a5
ffffffffc02017cc:	d3a5                	beqz	a5,ffffffffc020172c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017ce:	05e00413          	li	s0,94
ffffffffc02017d2:	bf39                	j	ffffffffc02016f0 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02017d4:	000a2403          	lw	s0,0(s4)
ffffffffc02017d8:	b7ad                	j	ffffffffc0201742 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02017da:	000a6603          	lwu	a2,0(s4)
ffffffffc02017de:	46a1                	li	a3,8
ffffffffc02017e0:	8a2e                	mv	s4,a1
ffffffffc02017e2:	bdb1                	j	ffffffffc020163e <vprintfmt+0x156>
ffffffffc02017e4:	000a6603          	lwu	a2,0(s4)
ffffffffc02017e8:	46a9                	li	a3,10
ffffffffc02017ea:	8a2e                	mv	s4,a1
ffffffffc02017ec:	bd89                	j	ffffffffc020163e <vprintfmt+0x156>
ffffffffc02017ee:	000a6603          	lwu	a2,0(s4)
ffffffffc02017f2:	46c1                	li	a3,16
ffffffffc02017f4:	8a2e                	mv	s4,a1
ffffffffc02017f6:	b5a1                	j	ffffffffc020163e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02017f8:	9902                	jalr	s2
ffffffffc02017fa:	bf09                	j	ffffffffc020170c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	02d00513          	li	a0,45
ffffffffc0201802:	e03e                	sd	a5,0(sp)
ffffffffc0201804:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201806:	6782                	ld	a5,0(sp)
ffffffffc0201808:	8a66                	mv	s4,s9
ffffffffc020180a:	40800633          	neg	a2,s0
ffffffffc020180e:	46a9                	li	a3,10
ffffffffc0201810:	b53d                	j	ffffffffc020163e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201812:	03b05163          	blez	s11,ffffffffc0201834 <vprintfmt+0x34c>
ffffffffc0201816:	02d00693          	li	a3,45
ffffffffc020181a:	f6d79de3          	bne	a5,a3,ffffffffc0201794 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020181e:	00001417          	auipc	s0,0x1
ffffffffc0201822:	dc240413          	addi	s0,s0,-574 # ffffffffc02025e0 <best_fit_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201826:	02800793          	li	a5,40
ffffffffc020182a:	02800513          	li	a0,40
ffffffffc020182e:	00140a13          	addi	s4,s0,1
ffffffffc0201832:	bd6d                	j	ffffffffc02016ec <vprintfmt+0x204>
ffffffffc0201834:	00001a17          	auipc	s4,0x1
ffffffffc0201838:	dada0a13          	addi	s4,s4,-595 # ffffffffc02025e1 <best_fit_pmm_manager+0x179>
ffffffffc020183c:	02800513          	li	a0,40
ffffffffc0201840:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201844:	05e00413          	li	s0,94
ffffffffc0201848:	b565                	j	ffffffffc02016f0 <vprintfmt+0x208>

ffffffffc020184a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020184a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020184c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201850:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201852:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201854:	ec06                	sd	ra,24(sp)
ffffffffc0201856:	f83a                	sd	a4,48(sp)
ffffffffc0201858:	fc3e                	sd	a5,56(sp)
ffffffffc020185a:	e0c2                	sd	a6,64(sp)
ffffffffc020185c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020185e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201860:	c89ff0ef          	jal	ra,ffffffffc02014e8 <vprintfmt>
}
ffffffffc0201864:	60e2                	ld	ra,24(sp)
ffffffffc0201866:	6161                	addi	sp,sp,80
ffffffffc0201868:	8082                	ret

ffffffffc020186a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020186a:	715d                	addi	sp,sp,-80
ffffffffc020186c:	e486                	sd	ra,72(sp)
ffffffffc020186e:	e0a6                	sd	s1,64(sp)
ffffffffc0201870:	fc4a                	sd	s2,56(sp)
ffffffffc0201872:	f84e                	sd	s3,48(sp)
ffffffffc0201874:	f452                	sd	s4,40(sp)
ffffffffc0201876:	f056                	sd	s5,32(sp)
ffffffffc0201878:	ec5a                	sd	s6,24(sp)
ffffffffc020187a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020187c:	c901                	beqz	a0,ffffffffc020188c <readline+0x22>
ffffffffc020187e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201880:	00001517          	auipc	a0,0x1
ffffffffc0201884:	d7850513          	addi	a0,a0,-648 # ffffffffc02025f8 <best_fit_pmm_manager+0x190>
ffffffffc0201888:	82bfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc020188c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020188e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201890:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201892:	4aa9                	li	s5,10
ffffffffc0201894:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201896:	00005b97          	auipc	s7,0x5
ffffffffc020189a:	882b8b93          	addi	s7,s7,-1918 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020189e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02018a2:	889fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02018a6:	00054a63          	bltz	a0,ffffffffc02018ba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018aa:	00a95a63          	bge	s2,a0,ffffffffc02018be <readline+0x54>
ffffffffc02018ae:	029a5263          	bge	s4,s1,ffffffffc02018d2 <readline+0x68>
        c = getchar();
ffffffffc02018b2:	879fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02018b6:	fe055ae3          	bgez	a0,ffffffffc02018aa <readline+0x40>
            return NULL;
ffffffffc02018ba:	4501                	li	a0,0
ffffffffc02018bc:	a091                	j	ffffffffc0201900 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02018be:	03351463          	bne	a0,s3,ffffffffc02018e6 <readline+0x7c>
ffffffffc02018c2:	e8a9                	bnez	s1,ffffffffc0201914 <readline+0xaa>
        c = getchar();
ffffffffc02018c4:	867fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02018c8:	fe0549e3          	bltz	a0,ffffffffc02018ba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018cc:	fea959e3          	bge	s2,a0,ffffffffc02018be <readline+0x54>
ffffffffc02018d0:	4481                	li	s1,0
            cputchar(c);
ffffffffc02018d2:	e42a                	sd	a0,8(sp)
ffffffffc02018d4:	815fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc02018d8:	6522                	ld	a0,8(sp)
ffffffffc02018da:	009b87b3          	add	a5,s7,s1
ffffffffc02018de:	2485                	addiw	s1,s1,1
ffffffffc02018e0:	00a78023          	sb	a0,0(a5)
ffffffffc02018e4:	bf7d                	j	ffffffffc02018a2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02018e6:	01550463          	beq	a0,s5,ffffffffc02018ee <readline+0x84>
ffffffffc02018ea:	fb651ce3          	bne	a0,s6,ffffffffc02018a2 <readline+0x38>
            cputchar(c);
ffffffffc02018ee:	ffafe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02018f2:	00005517          	auipc	a0,0x5
ffffffffc02018f6:	82650513          	addi	a0,a0,-2010 # ffffffffc0206118 <buf>
ffffffffc02018fa:	94aa                	add	s1,s1,a0
ffffffffc02018fc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201900:	60a6                	ld	ra,72(sp)
ffffffffc0201902:	6486                	ld	s1,64(sp)
ffffffffc0201904:	7962                	ld	s2,56(sp)
ffffffffc0201906:	79c2                	ld	s3,48(sp)
ffffffffc0201908:	7a22                	ld	s4,40(sp)
ffffffffc020190a:	7a82                	ld	s5,32(sp)
ffffffffc020190c:	6b62                	ld	s6,24(sp)
ffffffffc020190e:	6bc2                	ld	s7,16(sp)
ffffffffc0201910:	6161                	addi	sp,sp,80
ffffffffc0201912:	8082                	ret
            cputchar(c);
ffffffffc0201914:	4521                	li	a0,8
ffffffffc0201916:	fd2fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc020191a:	34fd                	addiw	s1,s1,-1
ffffffffc020191c:	b759                	j	ffffffffc02018a2 <readline+0x38>

ffffffffc020191e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020191e:	4781                	li	a5,0
ffffffffc0201920:	00004717          	auipc	a4,0x4
ffffffffc0201924:	6e873703          	ld	a4,1768(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201928:	88ba                	mv	a7,a4
ffffffffc020192a:	852a                	mv	a0,a0
ffffffffc020192c:	85be                	mv	a1,a5
ffffffffc020192e:	863e                	mv	a2,a5
ffffffffc0201930:	00000073          	ecall
ffffffffc0201934:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201936:	8082                	ret

ffffffffc0201938 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201938:	4781                	li	a5,0
ffffffffc020193a:	00005717          	auipc	a4,0x5
ffffffffc020193e:	c1e73703          	ld	a4,-994(a4) # ffffffffc0206558 <SBI_SET_TIMER>
ffffffffc0201942:	88ba                	mv	a7,a4
ffffffffc0201944:	852a                	mv	a0,a0
ffffffffc0201946:	85be                	mv	a1,a5
ffffffffc0201948:	863e                	mv	a2,a5
ffffffffc020194a:	00000073          	ecall
ffffffffc020194e:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201950:	8082                	ret

ffffffffc0201952 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201952:	4501                	li	a0,0
ffffffffc0201954:	00004797          	auipc	a5,0x4
ffffffffc0201958:	6ac7b783          	ld	a5,1708(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc020195c:	88be                	mv	a7,a5
ffffffffc020195e:	852a                	mv	a0,a0
ffffffffc0201960:	85aa                	mv	a1,a0
ffffffffc0201962:	862a                	mv	a2,a0
ffffffffc0201964:	00000073          	ecall
ffffffffc0201968:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc020196a:	2501                	sext.w	a0,a0
ffffffffc020196c:	8082                	ret

ffffffffc020196e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020196e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201970:	e589                	bnez	a1,ffffffffc020197a <strnlen+0xc>
ffffffffc0201972:	a811                	j	ffffffffc0201986 <strnlen+0x18>
        cnt ++;
ffffffffc0201974:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201976:	00f58863          	beq	a1,a5,ffffffffc0201986 <strnlen+0x18>
ffffffffc020197a:	00f50733          	add	a4,a0,a5
ffffffffc020197e:	00074703          	lbu	a4,0(a4)
ffffffffc0201982:	fb6d                	bnez	a4,ffffffffc0201974 <strnlen+0x6>
ffffffffc0201984:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201986:	852e                	mv	a0,a1
ffffffffc0201988:	8082                	ret

ffffffffc020198a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020198a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020198e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201992:	cb89                	beqz	a5,ffffffffc02019a4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201994:	0505                	addi	a0,a0,1
ffffffffc0201996:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201998:	fee789e3          	beq	a5,a4,ffffffffc020198a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020199c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02019a0:	9d19                	subw	a0,a0,a4
ffffffffc02019a2:	8082                	ret
ffffffffc02019a4:	4501                	li	a0,0
ffffffffc02019a6:	bfed                	j	ffffffffc02019a0 <strcmp+0x16>

ffffffffc02019a8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02019a8:	00054783          	lbu	a5,0(a0)
ffffffffc02019ac:	c799                	beqz	a5,ffffffffc02019ba <strchr+0x12>
        if (*s == c) {
ffffffffc02019ae:	00f58763          	beq	a1,a5,ffffffffc02019bc <strchr+0x14>
    while (*s != '\0') {
ffffffffc02019b2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02019b6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02019b8:	fbfd                	bnez	a5,ffffffffc02019ae <strchr+0x6>
    }
    return NULL;
ffffffffc02019ba:	4501                	li	a0,0
}
ffffffffc02019bc:	8082                	ret

ffffffffc02019be <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02019be:	ca01                	beqz	a2,ffffffffc02019ce <memset+0x10>
ffffffffc02019c0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02019c2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02019c4:	0785                	addi	a5,a5,1
ffffffffc02019c6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02019ca:	fec79de3          	bne	a5,a2,ffffffffc02019c4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02019ce:	8082                	ret
