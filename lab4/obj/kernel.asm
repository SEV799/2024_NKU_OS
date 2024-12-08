
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
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
ffffffffc0200024:	c0209137          	lui	sp,0xc0209

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000a517          	auipc	a0,0xa
ffffffffc0200036:	02e50513          	addi	a0,a0,46 # ffffffffc020a060 <buf>
ffffffffc020003a:	00015617          	auipc	a2,0x15
ffffffffc020003e:	59260613          	addi	a2,a2,1426 # ffffffffc02155cc <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	5a5040ef          	jal	ra,ffffffffc0204dee <memset>

    cons_init();                // init the console
ffffffffc020004e:	4a6000ef          	jal	ra,ffffffffc02004f4 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	dee58593          	addi	a1,a1,-530 # ffffffffc0204e40 <etext+0x4>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	e0650513          	addi	a0,a0,-506 # ffffffffc0204e60 <etext+0x24>
ffffffffc0200062:	11e000ef          	jal	ra,ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	162000ef          	jal	ra,ffffffffc02001c8 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	67d010ef          	jal	ra,ffffffffc0201ee6 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	55a000ef          	jal	ra,ffffffffc02005c8 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5c8000ef          	jal	ra,ffffffffc020063a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	18b030ef          	jal	ra,ffffffffc0203a00 <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	58e040ef          	jal	ra,ffffffffc0204608 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	4e8000ef          	jal	ra,ffffffffc0200566 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	2d9020ef          	jal	ra,ffffffffc0202b5a <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	41c000ef          	jal	ra,ffffffffc02004a2 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	532000ef          	jal	ra,ffffffffc02005bc <intr_enable>

    cpu_idle();                 // run idle process
ffffffffc020008e:	7c6040ef          	jal	ra,ffffffffc0204854 <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	addi	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a6                	sd	s1,64(sp)
ffffffffc0200098:	fc4a                	sd	s2,56(sp)
ffffffffc020009a:	f84e                	sd	s3,48(sp)
ffffffffc020009c:	f452                	sd	s4,40(sp)
ffffffffc020009e:	f056                	sd	s5,32(sp)
ffffffffc02000a0:	ec5a                	sd	s6,24(sp)
ffffffffc02000a2:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00005517          	auipc	a0,0x5
ffffffffc02000ac:	dc050513          	addi	a0,a0,-576 # ffffffffc0204e68 <etext+0x2c>
ffffffffc02000b0:	0d0000ef          	jal	ra,ffffffffc0200180 <cprintf>
readline(const char *prompt) {
ffffffffc02000b4:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4aa9                	li	s5,10
ffffffffc02000bc:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000be:	0000ab97          	auipc	s7,0xa
ffffffffc02000c2:	fa2b8b93          	addi	s7,s7,-94 # ffffffffc020a060 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000ca:	0ee000ef          	jal	ra,ffffffffc02001b8 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a95a63          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	029a5263          	bge	s4,s1,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	0de000ef          	jal	ra,ffffffffc02001b8 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03351463          	bne	a0,s3,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	e8a9                	bnez	s1,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ec:	0cc000ef          	jal	ra,ffffffffc02001b8 <getchar>
        if (c < 0) {
ffffffffc02000f0:	fe0549e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f4:	fea959e3          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000f8:	4481                	li	s1,0
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0ba000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	009b87b3          	add	a5,s7,s1
ffffffffc0200106:	2485                	addiw	s1,s1,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01550463          	beq	a0,s5,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb651ce3          	bne	a0,s6,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	0a0000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	0000a517          	auipc	a0,0xa
ffffffffc020011e:	f4650513          	addi	a0,a0,-186 # ffffffffc020a060 <buf>
ffffffffc0200122:	94aa                	add	s1,s1,a0
ffffffffc0200124:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6486                	ld	s1,64(sp)
ffffffffc020012c:	7962                	ld	s2,56(sp)
ffffffffc020012e:	79c2                	ld	s3,48(sp)
ffffffffc0200130:	7a22                	ld	s4,40(sp)
ffffffffc0200132:	7a82                	ld	s5,32(sp)
ffffffffc0200134:	6b62                	ld	s6,24(sp)
ffffffffc0200136:	6bc2                	ld	s7,16(sp)
ffffffffc0200138:	6161                	addi	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	078000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            i --;
ffffffffc0200142:	34fd                	addiw	s1,s1,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	3a8000ef          	jal	ra,ffffffffc02004f6 <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addiw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	07d040ef          	jal	ra,ffffffffc02049f0 <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	addi	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200186:	8e2a                	mv	t3,a0
ffffffffc0200188:	f42e                	sd	a1,40(sp)
ffffffffc020018a:	f832                	sd	a2,48(sp)
ffffffffc020018c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018e:	00000517          	auipc	a0,0x0
ffffffffc0200192:	fb850513          	addi	a0,a0,-72 # ffffffffc0200146 <cputch>
ffffffffc0200196:	004c                	addi	a1,sp,4
ffffffffc0200198:	869a                	mv	a3,t1
ffffffffc020019a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020019c:	ec06                	sd	ra,24(sp)
ffffffffc020019e:	e0ba                	sd	a4,64(sp)
ffffffffc02001a0:	e4be                	sd	a5,72(sp)
ffffffffc02001a2:	e8c2                	sd	a6,80(sp)
ffffffffc02001a4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001aa:	047040ef          	jal	ra,ffffffffc02049f0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ae:	60e2                	ld	ra,24(sp)
ffffffffc02001b0:	4512                	lw	a0,4(sp)
ffffffffc02001b2:	6125                	addi	sp,sp,96
ffffffffc02001b4:	8082                	ret

ffffffffc02001b6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b6:	a681                	j	ffffffffc02004f6 <cons_putc>

ffffffffc02001b8 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001b8:	1141                	addi	sp,sp,-16
ffffffffc02001ba:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001bc:	36e000ef          	jal	ra,ffffffffc020052a <cons_getc>
ffffffffc02001c0:	dd75                	beqz	a0,ffffffffc02001bc <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001c2:	60a2                	ld	ra,8(sp)
ffffffffc02001c4:	0141                	addi	sp,sp,16
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001ca:	00005517          	auipc	a0,0x5
ffffffffc02001ce:	ca650513          	addi	a0,a0,-858 # ffffffffc0204e70 <etext+0x34>
void print_kerninfo(void) {
ffffffffc02001d2:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001d4:	fadff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001d8:	00000597          	auipc	a1,0x0
ffffffffc02001dc:	e5a58593          	addi	a1,a1,-422 # ffffffffc0200032 <kern_init>
ffffffffc02001e0:	00005517          	auipc	a0,0x5
ffffffffc02001e4:	cb050513          	addi	a0,a0,-848 # ffffffffc0204e90 <etext+0x54>
ffffffffc02001e8:	f99ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001ec:	00005597          	auipc	a1,0x5
ffffffffc02001f0:	c5058593          	addi	a1,a1,-944 # ffffffffc0204e3c <etext>
ffffffffc02001f4:	00005517          	auipc	a0,0x5
ffffffffc02001f8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0204eb0 <etext+0x74>
ffffffffc02001fc:	f85ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200200:	0000a597          	auipc	a1,0xa
ffffffffc0200204:	e6058593          	addi	a1,a1,-416 # ffffffffc020a060 <buf>
ffffffffc0200208:	00005517          	auipc	a0,0x5
ffffffffc020020c:	cc850513          	addi	a0,a0,-824 # ffffffffc0204ed0 <etext+0x94>
ffffffffc0200210:	f71ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200214:	00015597          	auipc	a1,0x15
ffffffffc0200218:	3b858593          	addi	a1,a1,952 # ffffffffc02155cc <end>
ffffffffc020021c:	00005517          	auipc	a0,0x5
ffffffffc0200220:	cd450513          	addi	a0,a0,-812 # ffffffffc0204ef0 <etext+0xb4>
ffffffffc0200224:	f5dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200228:	00015597          	auipc	a1,0x15
ffffffffc020022c:	7a358593          	addi	a1,a1,1955 # ffffffffc02159cb <end+0x3ff>
ffffffffc0200230:	00000797          	auipc	a5,0x0
ffffffffc0200234:	e0278793          	addi	a5,a5,-510 # ffffffffc0200032 <kern_init>
ffffffffc0200238:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020023c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200240:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200242:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200246:	95be                	add	a1,a1,a5
ffffffffc0200248:	85a9                	srai	a1,a1,0xa
ffffffffc020024a:	00005517          	auipc	a0,0x5
ffffffffc020024e:	cc650513          	addi	a0,a0,-826 # ffffffffc0204f10 <etext+0xd4>
}
ffffffffc0200252:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200254:	b735                	j	ffffffffc0200180 <cprintf>

ffffffffc0200256 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200256:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200258:	00005617          	auipc	a2,0x5
ffffffffc020025c:	ce860613          	addi	a2,a2,-792 # ffffffffc0204f40 <etext+0x104>
ffffffffc0200260:	04d00593          	li	a1,77
ffffffffc0200264:	00005517          	auipc	a0,0x5
ffffffffc0200268:	cf450513          	addi	a0,a0,-780 # ffffffffc0204f58 <etext+0x11c>
void print_stackframe(void) {
ffffffffc020026c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020026e:	1d8000ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0200272 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200272:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200274:	00005617          	auipc	a2,0x5
ffffffffc0200278:	cfc60613          	addi	a2,a2,-772 # ffffffffc0204f70 <etext+0x134>
ffffffffc020027c:	00005597          	auipc	a1,0x5
ffffffffc0200280:	d1458593          	addi	a1,a1,-748 # ffffffffc0204f90 <etext+0x154>
ffffffffc0200284:	00005517          	auipc	a0,0x5
ffffffffc0200288:	d1450513          	addi	a0,a0,-748 # ffffffffc0204f98 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020028c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020028e:	ef3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0200292:	00005617          	auipc	a2,0x5
ffffffffc0200296:	d1660613          	addi	a2,a2,-746 # ffffffffc0204fa8 <etext+0x16c>
ffffffffc020029a:	00005597          	auipc	a1,0x5
ffffffffc020029e:	d3658593          	addi	a1,a1,-714 # ffffffffc0204fd0 <etext+0x194>
ffffffffc02002a2:	00005517          	auipc	a0,0x5
ffffffffc02002a6:	cf650513          	addi	a0,a0,-778 # ffffffffc0204f98 <etext+0x15c>
ffffffffc02002aa:	ed7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002ae:	00005617          	auipc	a2,0x5
ffffffffc02002b2:	d3260613          	addi	a2,a2,-718 # ffffffffc0204fe0 <etext+0x1a4>
ffffffffc02002b6:	00005597          	auipc	a1,0x5
ffffffffc02002ba:	d4a58593          	addi	a1,a1,-694 # ffffffffc0205000 <etext+0x1c4>
ffffffffc02002be:	00005517          	auipc	a0,0x5
ffffffffc02002c2:	cda50513          	addi	a0,a0,-806 # ffffffffc0204f98 <etext+0x15c>
ffffffffc02002c6:	ebbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc02002ca:	60a2                	ld	ra,8(sp)
ffffffffc02002cc:	4501                	li	a0,0
ffffffffc02002ce:	0141                	addi	sp,sp,16
ffffffffc02002d0:	8082                	ret

ffffffffc02002d2 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d2:	1141                	addi	sp,sp,-16
ffffffffc02002d4:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002d6:	ef3ff0ef          	jal	ra,ffffffffc02001c8 <print_kerninfo>
    return 0;
}
ffffffffc02002da:	60a2                	ld	ra,8(sp)
ffffffffc02002dc:	4501                	li	a0,0
ffffffffc02002de:	0141                	addi	sp,sp,16
ffffffffc02002e0:	8082                	ret

ffffffffc02002e2 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e2:	1141                	addi	sp,sp,-16
ffffffffc02002e4:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002e6:	f71ff0ef          	jal	ra,ffffffffc0200256 <print_stackframe>
    return 0;
}
ffffffffc02002ea:	60a2                	ld	ra,8(sp)
ffffffffc02002ec:	4501                	li	a0,0
ffffffffc02002ee:	0141                	addi	sp,sp,16
ffffffffc02002f0:	8082                	ret

ffffffffc02002f2 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002f2:	7115                	addi	sp,sp,-224
ffffffffc02002f4:	ed5e                	sd	s7,152(sp)
ffffffffc02002f6:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f8:	00005517          	auipc	a0,0x5
ffffffffc02002fc:	d1850513          	addi	a0,a0,-744 # ffffffffc0205010 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc0200300:	ed86                	sd	ra,216(sp)
ffffffffc0200302:	e9a2                	sd	s0,208(sp)
ffffffffc0200304:	e5a6                	sd	s1,200(sp)
ffffffffc0200306:	e1ca                	sd	s2,192(sp)
ffffffffc0200308:	fd4e                	sd	s3,184(sp)
ffffffffc020030a:	f952                	sd	s4,176(sp)
ffffffffc020030c:	f556                	sd	s5,168(sp)
ffffffffc020030e:	f15a                	sd	s6,160(sp)
ffffffffc0200310:	e962                	sd	s8,144(sp)
ffffffffc0200312:	e566                	sd	s9,136(sp)
ffffffffc0200314:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200316:	e6bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020031a:	00005517          	auipc	a0,0x5
ffffffffc020031e:	d1e50513          	addi	a0,a0,-738 # ffffffffc0205038 <etext+0x1fc>
ffffffffc0200322:	e5fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200326:	000b8563          	beqz	s7,ffffffffc0200330 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020032a:	855e                	mv	a0,s7
ffffffffc020032c:	4f4000ef          	jal	ra,ffffffffc0200820 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	4581                	li	a1,0
ffffffffc0200334:	4601                	li	a2,0
ffffffffc0200336:	48a1                	li	a7,8
ffffffffc0200338:	00000073          	ecall
ffffffffc020033c:	00005c17          	auipc	s8,0x5
ffffffffc0200340:	d6cc0c13          	addi	s8,s8,-660 # ffffffffc02050a8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200344:	00005917          	auipc	s2,0x5
ffffffffc0200348:	d1c90913          	addi	s2,s2,-740 # ffffffffc0205060 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034c:	00005497          	auipc	s1,0x5
ffffffffc0200350:	d1c48493          	addi	s1,s1,-740 # ffffffffc0205068 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200354:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200356:	00005b17          	auipc	s6,0x5
ffffffffc020035a:	d1ab0b13          	addi	s6,s6,-742 # ffffffffc0205070 <etext+0x234>
        argv[argc ++] = buf;
ffffffffc020035e:	00005a17          	auipc	s4,0x5
ffffffffc0200362:	c32a0a13          	addi	s4,s4,-974 # ffffffffc0204f90 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200366:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200368:	854a                	mv	a0,s2
ffffffffc020036a:	d29ff0ef          	jal	ra,ffffffffc0200092 <readline>
ffffffffc020036e:	842a                	mv	s0,a0
ffffffffc0200370:	dd65                	beqz	a0,ffffffffc0200368 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200376:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200378:	e1bd                	bnez	a1,ffffffffc02003de <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020037a:	fe0c87e3          	beqz	s9,ffffffffc0200368 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020037e:	6582                	ld	a1,0(sp)
ffffffffc0200380:	00005d17          	auipc	s10,0x5
ffffffffc0200384:	d28d0d13          	addi	s10,s10,-728 # ffffffffc02050a8 <commands>
        argv[argc ++] = buf;
ffffffffc0200388:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020038a:	4401                	li	s0,0
ffffffffc020038c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020038e:	22d040ef          	jal	ra,ffffffffc0204dba <strcmp>
ffffffffc0200392:	c919                	beqz	a0,ffffffffc02003a8 <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200394:	2405                	addiw	s0,s0,1
ffffffffc0200396:	0b540063          	beq	s0,s5,ffffffffc0200436 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020039a:	000d3503          	ld	a0,0(s10)
ffffffffc020039e:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	219040ef          	jal	ra,ffffffffc0204dba <strcmp>
ffffffffc02003a6:	f57d                	bnez	a0,ffffffffc0200394 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003a8:	00141793          	slli	a5,s0,0x1
ffffffffc02003ac:	97a2                	add	a5,a5,s0
ffffffffc02003ae:	078e                	slli	a5,a5,0x3
ffffffffc02003b0:	97e2                	add	a5,a5,s8
ffffffffc02003b2:	6b9c                	ld	a5,16(a5)
ffffffffc02003b4:	865e                	mv	a2,s7
ffffffffc02003b6:	002c                	addi	a1,sp,8
ffffffffc02003b8:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003bc:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003be:	fa0555e3          	bgez	a0,ffffffffc0200368 <kmonitor+0x76>
}
ffffffffc02003c2:	60ee                	ld	ra,216(sp)
ffffffffc02003c4:	644e                	ld	s0,208(sp)
ffffffffc02003c6:	64ae                	ld	s1,200(sp)
ffffffffc02003c8:	690e                	ld	s2,192(sp)
ffffffffc02003ca:	79ea                	ld	s3,184(sp)
ffffffffc02003cc:	7a4a                	ld	s4,176(sp)
ffffffffc02003ce:	7aaa                	ld	s5,168(sp)
ffffffffc02003d0:	7b0a                	ld	s6,160(sp)
ffffffffc02003d2:	6bea                	ld	s7,152(sp)
ffffffffc02003d4:	6c4a                	ld	s8,144(sp)
ffffffffc02003d6:	6caa                	ld	s9,136(sp)
ffffffffc02003d8:	6d0a                	ld	s10,128(sp)
ffffffffc02003da:	612d                	addi	sp,sp,224
ffffffffc02003dc:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003de:	8526                	mv	a0,s1
ffffffffc02003e0:	1f9040ef          	jal	ra,ffffffffc0204dd8 <strchr>
ffffffffc02003e4:	c901                	beqz	a0,ffffffffc02003f4 <kmonitor+0x102>
ffffffffc02003e6:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003ea:	00040023          	sb	zero,0(s0)
ffffffffc02003ee:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f0:	d5c9                	beqz	a1,ffffffffc020037a <kmonitor+0x88>
ffffffffc02003f2:	b7f5                	j	ffffffffc02003de <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc02003f4:	00044783          	lbu	a5,0(s0)
ffffffffc02003f8:	d3c9                	beqz	a5,ffffffffc020037a <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc02003fa:	033c8963          	beq	s9,s3,ffffffffc020042c <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc02003fe:	003c9793          	slli	a5,s9,0x3
ffffffffc0200402:	0118                	addi	a4,sp,128
ffffffffc0200404:	97ba                	add	a5,a5,a4
ffffffffc0200406:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020040a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020040e:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200410:	e591                	bnez	a1,ffffffffc020041c <kmonitor+0x12a>
ffffffffc0200412:	b7b5                	j	ffffffffc020037e <kmonitor+0x8c>
ffffffffc0200414:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200418:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041a:	d1a5                	beqz	a1,ffffffffc020037a <kmonitor+0x88>
ffffffffc020041c:	8526                	mv	a0,s1
ffffffffc020041e:	1bb040ef          	jal	ra,ffffffffc0204dd8 <strchr>
ffffffffc0200422:	d96d                	beqz	a0,ffffffffc0200414 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200424:	00044583          	lbu	a1,0(s0)
ffffffffc0200428:	d9a9                	beqz	a1,ffffffffc020037a <kmonitor+0x88>
ffffffffc020042a:	bf55                	j	ffffffffc02003de <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020042c:	45c1                	li	a1,16
ffffffffc020042e:	855a                	mv	a0,s6
ffffffffc0200430:	d51ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0200434:	b7e9                	j	ffffffffc02003fe <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200436:	6582                	ld	a1,0(sp)
ffffffffc0200438:	00005517          	auipc	a0,0x5
ffffffffc020043c:	c5850513          	addi	a0,a0,-936 # ffffffffc0205090 <etext+0x254>
ffffffffc0200440:	d41ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
ffffffffc0200444:	b715                	j	ffffffffc0200368 <kmonitor+0x76>

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200446:	00015317          	auipc	t1,0x15
ffffffffc020044a:	0f230313          	addi	t1,t1,242 # ffffffffc0215538 <is_panic>
ffffffffc020044e:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200452:	715d                	addi	sp,sp,-80
ffffffffc0200454:	ec06                	sd	ra,24(sp)
ffffffffc0200456:	e822                	sd	s0,16(sp)
ffffffffc0200458:	f436                	sd	a3,40(sp)
ffffffffc020045a:	f83a                	sd	a4,48(sp)
ffffffffc020045c:	fc3e                	sd	a5,56(sp)
ffffffffc020045e:	e0c2                	sd	a6,64(sp)
ffffffffc0200460:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200462:	020e1a63          	bnez	t3,ffffffffc0200496 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200466:	4785                	li	a5,1
ffffffffc0200468:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020046c:	8432                	mv	s0,a2
ffffffffc020046e:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200470:	862e                	mv	a2,a1
ffffffffc0200472:	85aa                	mv	a1,a0
ffffffffc0200474:	00005517          	auipc	a0,0x5
ffffffffc0200478:	c7c50513          	addi	a0,a0,-900 # ffffffffc02050f0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d03ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cdbff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00006517          	auipc	a0,0x6
ffffffffc020048e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0206060 <default_pmm_manager+0x4d0>
ffffffffc0200492:	cefff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200496:	12c000ef          	jal	ra,ffffffffc02005c2 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020049a:	4501                	li	a0,0
ffffffffc020049c:	e57ff0ef          	jal	ra,ffffffffc02002f2 <kmonitor>
    while (1) {
ffffffffc02004a0:	bfed                	j	ffffffffc020049a <__panic+0x54>

ffffffffc02004a2 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004a2:	67e1                	lui	a5,0x18
ffffffffc02004a4:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004a8:	00015717          	auipc	a4,0x15
ffffffffc02004ac:	0af73023          	sd	a5,160(a4) # ffffffffc0215548 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004b0:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004b4:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004b6:	953e                	add	a0,a0,a5
ffffffffc02004b8:	4601                	li	a2,0
ffffffffc02004ba:	4881                	li	a7,0
ffffffffc02004bc:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004c0:	02000793          	li	a5,32
ffffffffc02004c4:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004c8:	00005517          	auipc	a0,0x5
ffffffffc02004cc:	c4850513          	addi	a0,a0,-952 # ffffffffc0205110 <commands+0x68>
    ticks = 0;
ffffffffc02004d0:	00015797          	auipc	a5,0x15
ffffffffc02004d4:	0607b823          	sd	zero,112(a5) # ffffffffc0215540 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004d8:	b165                	j	ffffffffc0200180 <cprintf>

ffffffffc02004da <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004da:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004de:	00015797          	auipc	a5,0x15
ffffffffc02004e2:	06a7b783          	ld	a5,106(a5) # ffffffffc0215548 <timebase>
ffffffffc02004e6:	953e                	add	a0,a0,a5
ffffffffc02004e8:	4581                	li	a1,0
ffffffffc02004ea:	4601                	li	a2,0
ffffffffc02004ec:	4881                	li	a7,0
ffffffffc02004ee:	00000073          	ecall
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004f4:	8082                	ret

ffffffffc02004f6 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004f6:	100027f3          	csrr	a5,sstatus
ffffffffc02004fa:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004fc:	0ff57513          	andi	a0,a0,255
ffffffffc0200500:	e799                	bnez	a5,ffffffffc020050e <cons_putc+0x18>
ffffffffc0200502:	4581                	li	a1,0
ffffffffc0200504:	4601                	li	a2,0
ffffffffc0200506:	4885                	li	a7,1
ffffffffc0200508:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020050c:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020050e:	1101                	addi	sp,sp,-32
ffffffffc0200510:	ec06                	sd	ra,24(sp)
ffffffffc0200512:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200514:	0ae000ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc0200518:	6522                	ld	a0,8(sp)
ffffffffc020051a:	4581                	li	a1,0
ffffffffc020051c:	4601                	li	a2,0
ffffffffc020051e:	4885                	li	a7,1
ffffffffc0200520:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200524:	60e2                	ld	ra,24(sp)
ffffffffc0200526:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200528:	a851                	j	ffffffffc02005bc <intr_enable>

ffffffffc020052a <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020052a:	100027f3          	csrr	a5,sstatus
ffffffffc020052e:	8b89                	andi	a5,a5,2
ffffffffc0200530:	eb89                	bnez	a5,ffffffffc0200542 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200532:	4501                	li	a0,0
ffffffffc0200534:	4581                	li	a1,0
ffffffffc0200536:	4601                	li	a2,0
ffffffffc0200538:	4889                	li	a7,2
ffffffffc020053a:	00000073          	ecall
ffffffffc020053e:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200540:	8082                	ret
int cons_getc(void) {
ffffffffc0200542:	1101                	addi	sp,sp,-32
ffffffffc0200544:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200546:	07c000ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc020054a:	4501                	li	a0,0
ffffffffc020054c:	4581                	li	a1,0
ffffffffc020054e:	4601                	li	a2,0
ffffffffc0200550:	4889                	li	a7,2
ffffffffc0200552:	00000073          	ecall
ffffffffc0200556:	2501                	sext.w	a0,a0
ffffffffc0200558:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020055a:	062000ef          	jal	ra,ffffffffc02005bc <intr_enable>
}
ffffffffc020055e:	60e2                	ld	ra,24(sp)
ffffffffc0200560:	6522                	ld	a0,8(sp)
ffffffffc0200562:	6105                	addi	sp,sp,32
ffffffffc0200564:	8082                	ret

ffffffffc0200566 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200566:	8082                	ret

ffffffffc0200568 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200568:	00253513          	sltiu	a0,a0,2
ffffffffc020056c:	8082                	ret

ffffffffc020056e <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020056e:	03800513          	li	a0,56
ffffffffc0200572:	8082                	ret

ffffffffc0200574 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200574:	0000a797          	auipc	a5,0xa
ffffffffc0200578:	eec78793          	addi	a5,a5,-276 # ffffffffc020a460 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc020057c:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200580:	1141                	addi	sp,sp,-16
ffffffffc0200582:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200584:	95be                	add	a1,a1,a5
ffffffffc0200586:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020058a:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020058c:	075040ef          	jal	ra,ffffffffc0204e00 <memcpy>
    return 0;
}
ffffffffc0200590:	60a2                	ld	ra,8(sp)
ffffffffc0200592:	4501                	li	a0,0
ffffffffc0200594:	0141                	addi	sp,sp,16
ffffffffc0200596:	8082                	ret

ffffffffc0200598 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200598:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020059c:	0000a517          	auipc	a0,0xa
ffffffffc02005a0:	ec450513          	addi	a0,a0,-316 # ffffffffc020a460 <ide>
                   size_t nsecs) {
ffffffffc02005a4:	1141                	addi	sp,sp,-16
ffffffffc02005a6:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005a8:	953e                	add	a0,a0,a5
ffffffffc02005aa:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02005ae:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005b0:	051040ef          	jal	ra,ffffffffc0204e00 <memcpy>
    return 0;
}
ffffffffc02005b4:	60a2                	ld	ra,8(sp)
ffffffffc02005b6:	4501                	li	a0,0
ffffffffc02005b8:	0141                	addi	sp,sp,16
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005bc:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005c0:	8082                	ret

ffffffffc02005c2 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005c2:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005c6:	8082                	ret

ffffffffc02005c8 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005ca:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005ce:	1141                	addi	sp,sp,-16
ffffffffc02005d0:	e022                	sd	s0,0(sp)
ffffffffc02005d2:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005d4:	1007f793          	andi	a5,a5,256
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005d8:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005dc:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005de:	05500613          	li	a2,85
ffffffffc02005e2:	c399                	beqz	a5,ffffffffc02005e8 <pgfault_handler+0x1e>
ffffffffc02005e4:	04b00613          	li	a2,75
ffffffffc02005e8:	11843703          	ld	a4,280(s0)
ffffffffc02005ec:	47bd                	li	a5,15
ffffffffc02005ee:	05700693          	li	a3,87
ffffffffc02005f2:	00f70463          	beq	a4,a5,ffffffffc02005fa <pgfault_handler+0x30>
ffffffffc02005f6:	05200693          	li	a3,82
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	b3650513          	addi	a0,a0,-1226 # ffffffffc0205130 <commands+0x88>
ffffffffc0200602:	b7fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200606:	00015517          	auipc	a0,0x15
ffffffffc020060a:	f9a53503          	ld	a0,-102(a0) # ffffffffc02155a0 <check_mm_struct>
ffffffffc020060e:	c911                	beqz	a0,ffffffffc0200622 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200610:	11043603          	ld	a2,272(s0)
ffffffffc0200614:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200618:	6402                	ld	s0,0(sp)
ffffffffc020061a:	60a2                	ld	ra,8(sp)
ffffffffc020061c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020061e:	1b70306f          	j	ffffffffc0203fd4 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200622:	00005617          	auipc	a2,0x5
ffffffffc0200626:	b2e60613          	addi	a2,a2,-1234 # ffffffffc0205150 <commands+0xa8>
ffffffffc020062a:	06200593          	li	a1,98
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0205168 <commands+0xc0>
ffffffffc0200636:	e11ff0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020063a <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020063a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020063e:	00000797          	auipc	a5,0x0
ffffffffc0200642:	47a78793          	addi	a5,a5,1146 # ffffffffc0200ab8 <__alltraps>
ffffffffc0200646:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020064a:	000407b7          	lui	a5,0x40
ffffffffc020064e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200654:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200656:	1141                	addi	sp,sp,-16
ffffffffc0200658:	e022                	sd	s0,0(sp)
ffffffffc020065a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020065c:	00005517          	auipc	a0,0x5
ffffffffc0200660:	b2450513          	addi	a0,a0,-1244 # ffffffffc0205180 <commands+0xd8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200664:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200666:	b1bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020066a:	640c                	ld	a1,8(s0)
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0205198 <commands+0xf0>
ffffffffc0200674:	b0dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200678:	680c                	ld	a1,16(s0)
ffffffffc020067a:	00005517          	auipc	a0,0x5
ffffffffc020067e:	b3650513          	addi	a0,a0,-1226 # ffffffffc02051b0 <commands+0x108>
ffffffffc0200682:	affff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200686:	6c0c                	ld	a1,24(s0)
ffffffffc0200688:	00005517          	auipc	a0,0x5
ffffffffc020068c:	b4050513          	addi	a0,a0,-1216 # ffffffffc02051c8 <commands+0x120>
ffffffffc0200690:	af1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200694:	700c                	ld	a1,32(s0)
ffffffffc0200696:	00005517          	auipc	a0,0x5
ffffffffc020069a:	b4a50513          	addi	a0,a0,-1206 # ffffffffc02051e0 <commands+0x138>
ffffffffc020069e:	ae3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006a2:	740c                	ld	a1,40(s0)
ffffffffc02006a4:	00005517          	auipc	a0,0x5
ffffffffc02006a8:	b5450513          	addi	a0,a0,-1196 # ffffffffc02051f8 <commands+0x150>
ffffffffc02006ac:	ad5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006b0:	780c                	ld	a1,48(s0)
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0205210 <commands+0x168>
ffffffffc02006ba:	ac7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006be:	7c0c                	ld	a1,56(s0)
ffffffffc02006c0:	00005517          	auipc	a0,0x5
ffffffffc02006c4:	b6850513          	addi	a0,a0,-1176 # ffffffffc0205228 <commands+0x180>
ffffffffc02006c8:	ab9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006cc:	602c                	ld	a1,64(s0)
ffffffffc02006ce:	00005517          	auipc	a0,0x5
ffffffffc02006d2:	b7250513          	addi	a0,a0,-1166 # ffffffffc0205240 <commands+0x198>
ffffffffc02006d6:	aabff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006da:	642c                	ld	a1,72(s0)
ffffffffc02006dc:	00005517          	auipc	a0,0x5
ffffffffc02006e0:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0205258 <commands+0x1b0>
ffffffffc02006e4:	a9dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006e8:	682c                	ld	a1,80(s0)
ffffffffc02006ea:	00005517          	auipc	a0,0x5
ffffffffc02006ee:	b8650513          	addi	a0,a0,-1146 # ffffffffc0205270 <commands+0x1c8>
ffffffffc02006f2:	a8fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02006f6:	6c2c                	ld	a1,88(s0)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	b9050513          	addi	a0,a0,-1136 # ffffffffc0205288 <commands+0x1e0>
ffffffffc0200700:	a81ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200704:	702c                	ld	a1,96(s0)
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	b9a50513          	addi	a0,a0,-1126 # ffffffffc02052a0 <commands+0x1f8>
ffffffffc020070e:	a73ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200712:	742c                	ld	a1,104(s0)
ffffffffc0200714:	00005517          	auipc	a0,0x5
ffffffffc0200718:	ba450513          	addi	a0,a0,-1116 # ffffffffc02052b8 <commands+0x210>
ffffffffc020071c:	a65ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200720:	782c                	ld	a1,112(s0)
ffffffffc0200722:	00005517          	auipc	a0,0x5
ffffffffc0200726:	bae50513          	addi	a0,a0,-1106 # ffffffffc02052d0 <commands+0x228>
ffffffffc020072a:	a57ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020072e:	7c2c                	ld	a1,120(s0)
ffffffffc0200730:	00005517          	auipc	a0,0x5
ffffffffc0200734:	bb850513          	addi	a0,a0,-1096 # ffffffffc02052e8 <commands+0x240>
ffffffffc0200738:	a49ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020073c:	604c                	ld	a1,128(s0)
ffffffffc020073e:	00005517          	auipc	a0,0x5
ffffffffc0200742:	bc250513          	addi	a0,a0,-1086 # ffffffffc0205300 <commands+0x258>
ffffffffc0200746:	a3bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020074a:	644c                	ld	a1,136(s0)
ffffffffc020074c:	00005517          	auipc	a0,0x5
ffffffffc0200750:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0205318 <commands+0x270>
ffffffffc0200754:	a2dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200758:	684c                	ld	a1,144(s0)
ffffffffc020075a:	00005517          	auipc	a0,0x5
ffffffffc020075e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0205330 <commands+0x288>
ffffffffc0200762:	a1fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200766:	6c4c                	ld	a1,152(s0)
ffffffffc0200768:	00005517          	auipc	a0,0x5
ffffffffc020076c:	be050513          	addi	a0,a0,-1056 # ffffffffc0205348 <commands+0x2a0>
ffffffffc0200770:	a11ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200774:	704c                	ld	a1,160(s0)
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205360 <commands+0x2b8>
ffffffffc020077e:	a03ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200782:	744c                	ld	a1,168(s0)
ffffffffc0200784:	00005517          	auipc	a0,0x5
ffffffffc0200788:	bf450513          	addi	a0,a0,-1036 # ffffffffc0205378 <commands+0x2d0>
ffffffffc020078c:	9f5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200790:	784c                	ld	a1,176(s0)
ffffffffc0200792:	00005517          	auipc	a0,0x5
ffffffffc0200796:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0205390 <commands+0x2e8>
ffffffffc020079a:	9e7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020079e:	7c4c                	ld	a1,184(s0)
ffffffffc02007a0:	00005517          	auipc	a0,0x5
ffffffffc02007a4:	c0850513          	addi	a0,a0,-1016 # ffffffffc02053a8 <commands+0x300>
ffffffffc02007a8:	9d9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007ac:	606c                	ld	a1,192(s0)
ffffffffc02007ae:	00005517          	auipc	a0,0x5
ffffffffc02007b2:	c1250513          	addi	a0,a0,-1006 # ffffffffc02053c0 <commands+0x318>
ffffffffc02007b6:	9cbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ba:	646c                	ld	a1,200(s0)
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	c1c50513          	addi	a0,a0,-996 # ffffffffc02053d8 <commands+0x330>
ffffffffc02007c4:	9bdff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007c8:	686c                	ld	a1,208(s0)
ffffffffc02007ca:	00005517          	auipc	a0,0x5
ffffffffc02007ce:	c2650513          	addi	a0,a0,-986 # ffffffffc02053f0 <commands+0x348>
ffffffffc02007d2:	9afff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007d6:	6c6c                	ld	a1,216(s0)
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	c3050513          	addi	a0,a0,-976 # ffffffffc0205408 <commands+0x360>
ffffffffc02007e0:	9a1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007e4:	706c                	ld	a1,224(s0)
ffffffffc02007e6:	00005517          	auipc	a0,0x5
ffffffffc02007ea:	c3a50513          	addi	a0,a0,-966 # ffffffffc0205420 <commands+0x378>
ffffffffc02007ee:	993ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02007f2:	746c                	ld	a1,232(s0)
ffffffffc02007f4:	00005517          	auipc	a0,0x5
ffffffffc02007f8:	c4450513          	addi	a0,a0,-956 # ffffffffc0205438 <commands+0x390>
ffffffffc02007fc:	985ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200800:	786c                	ld	a1,240(s0)
ffffffffc0200802:	00005517          	auipc	a0,0x5
ffffffffc0200806:	c4e50513          	addi	a0,a0,-946 # ffffffffc0205450 <commands+0x3a8>
ffffffffc020080a:	977ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020080e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200810:	6402                	ld	s0,0(sp)
ffffffffc0200812:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200814:	00005517          	auipc	a0,0x5
ffffffffc0200818:	c5450513          	addi	a0,a0,-940 # ffffffffc0205468 <commands+0x3c0>
}
ffffffffc020081c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020081e:	b28d                	j	ffffffffc0200180 <cprintf>

ffffffffc0200820 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200820:	1141                	addi	sp,sp,-16
ffffffffc0200822:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200824:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200826:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200828:	00005517          	auipc	a0,0x5
ffffffffc020082c:	c5850513          	addi	a0,a0,-936 # ffffffffc0205480 <commands+0x3d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200830:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200832:	94fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200836:	8522                	mv	a0,s0
ffffffffc0200838:	e1dff0ef          	jal	ra,ffffffffc0200654 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020083c:	10043583          	ld	a1,256(s0)
ffffffffc0200840:	00005517          	auipc	a0,0x5
ffffffffc0200844:	c5850513          	addi	a0,a0,-936 # ffffffffc0205498 <commands+0x3f0>
ffffffffc0200848:	939ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020084c:	10843583          	ld	a1,264(s0)
ffffffffc0200850:	00005517          	auipc	a0,0x5
ffffffffc0200854:	c6050513          	addi	a0,a0,-928 # ffffffffc02054b0 <commands+0x408>
ffffffffc0200858:	929ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020085c:	11043583          	ld	a1,272(s0)
ffffffffc0200860:	00005517          	auipc	a0,0x5
ffffffffc0200864:	c6850513          	addi	a0,a0,-920 # ffffffffc02054c8 <commands+0x420>
ffffffffc0200868:	919ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020086c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200870:	6402                	ld	s0,0(sp)
ffffffffc0200872:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200874:	00005517          	auipc	a0,0x5
ffffffffc0200878:	c6c50513          	addi	a0,a0,-916 # ffffffffc02054e0 <commands+0x438>
}
ffffffffc020087c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020087e:	903ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200882 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200882:	11853783          	ld	a5,280(a0)
ffffffffc0200886:	472d                	li	a4,11
ffffffffc0200888:	0786                	slli	a5,a5,0x1
ffffffffc020088a:	8385                	srli	a5,a5,0x1
ffffffffc020088c:	06f76c63          	bltu	a4,a5,ffffffffc0200904 <interrupt_handler+0x82>
ffffffffc0200890:	00005717          	auipc	a4,0x5
ffffffffc0200894:	d1870713          	addi	a4,a4,-744 # ffffffffc02055a8 <commands+0x500>
ffffffffc0200898:	078a                	slli	a5,a5,0x2
ffffffffc020089a:	97ba                	add	a5,a5,a4
ffffffffc020089c:	439c                	lw	a5,0(a5)
ffffffffc020089e:	97ba                	add	a5,a5,a4
ffffffffc02008a0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02008a2:	00005517          	auipc	a0,0x5
ffffffffc02008a6:	cb650513          	addi	a0,a0,-842 # ffffffffc0205558 <commands+0x4b0>
ffffffffc02008aa:	8d7ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02008ae:	00005517          	auipc	a0,0x5
ffffffffc02008b2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0205538 <commands+0x490>
ffffffffc02008b6:	8cbff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	c3e50513          	addi	a0,a0,-962 # ffffffffc02054f8 <commands+0x450>
ffffffffc02008c2:	8bfff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008c6:	00005517          	auipc	a0,0x5
ffffffffc02008ca:	c5250513          	addi	a0,a0,-942 # ffffffffc0205518 <commands+0x470>
ffffffffc02008ce:	8b3ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008d2:	1141                	addi	sp,sp,-16
ffffffffc02008d4:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02008d6:	c05ff0ef          	jal	ra,ffffffffc02004da <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02008da:	00015697          	auipc	a3,0x15
ffffffffc02008de:	c6668693          	addi	a3,a3,-922 # ffffffffc0215540 <ticks>
ffffffffc02008e2:	629c                	ld	a5,0(a3)
ffffffffc02008e4:	06400713          	li	a4,100
ffffffffc02008e8:	0785                	addi	a5,a5,1
ffffffffc02008ea:	02e7f733          	remu	a4,a5,a4
ffffffffc02008ee:	e29c                	sd	a5,0(a3)
ffffffffc02008f0:	cb19                	beqz	a4,ffffffffc0200906 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008f2:	60a2                	ld	ra,8(sp)
ffffffffc02008f4:	0141                	addi	sp,sp,16
ffffffffc02008f6:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc02008f8:	00005517          	auipc	a0,0x5
ffffffffc02008fc:	c9050513          	addi	a0,a0,-880 # ffffffffc0205588 <commands+0x4e0>
ffffffffc0200900:	881ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc0200904:	bf31                	j	ffffffffc0200820 <print_trapframe>
}
ffffffffc0200906:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200908:	06400593          	li	a1,100
ffffffffc020090c:	00005517          	auipc	a0,0x5
ffffffffc0200910:	c6c50513          	addi	a0,a0,-916 # ffffffffc0205578 <commands+0x4d0>
}
ffffffffc0200914:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200916:	86bff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc020091a <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020091a:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020091e:	1101                	addi	sp,sp,-32
ffffffffc0200920:	e822                	sd	s0,16(sp)
ffffffffc0200922:	ec06                	sd	ra,24(sp)
ffffffffc0200924:	e426                	sd	s1,8(sp)
ffffffffc0200926:	473d                	li	a4,15
ffffffffc0200928:	842a                	mv	s0,a0
ffffffffc020092a:	14f76a63          	bltu	a4,a5,ffffffffc0200a7e <exception_handler+0x164>
ffffffffc020092e:	00005717          	auipc	a4,0x5
ffffffffc0200932:	e6270713          	addi	a4,a4,-414 # ffffffffc0205790 <commands+0x6e8>
ffffffffc0200936:	078a                	slli	a5,a5,0x2
ffffffffc0200938:	97ba                	add	a5,a5,a4
ffffffffc020093a:	439c                	lw	a5,0(a5)
ffffffffc020093c:	97ba                	add	a5,a5,a4
ffffffffc020093e:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200940:	00005517          	auipc	a0,0x5
ffffffffc0200944:	e3850513          	addi	a0,a0,-456 # ffffffffc0205778 <commands+0x6d0>
ffffffffc0200948:	839ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020094c:	8522                	mv	a0,s0
ffffffffc020094e:	c7dff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200952:	84aa                	mv	s1,a0
ffffffffc0200954:	12051b63          	bnez	a0,ffffffffc0200a8a <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200958:	60e2                	ld	ra,24(sp)
ffffffffc020095a:	6442                	ld	s0,16(sp)
ffffffffc020095c:	64a2                	ld	s1,8(sp)
ffffffffc020095e:	6105                	addi	sp,sp,32
ffffffffc0200960:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	c7650513          	addi	a0,a0,-906 # ffffffffc02055d8 <commands+0x530>
}
ffffffffc020096a:	6442                	ld	s0,16(sp)
ffffffffc020096c:	60e2                	ld	ra,24(sp)
ffffffffc020096e:	64a2                	ld	s1,8(sp)
ffffffffc0200970:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200972:	80fff06f          	j	ffffffffc0200180 <cprintf>
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	c8250513          	addi	a0,a0,-894 # ffffffffc02055f8 <commands+0x550>
ffffffffc020097e:	b7f5                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	c9850513          	addi	a0,a0,-872 # ffffffffc0205618 <commands+0x570>
ffffffffc0200988:	b7cd                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc020098a:	00005517          	auipc	a0,0x5
ffffffffc020098e:	ca650513          	addi	a0,a0,-858 # ffffffffc0205630 <commands+0x588>
ffffffffc0200992:	bfe1                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc0200994:	00005517          	auipc	a0,0x5
ffffffffc0200998:	cac50513          	addi	a0,a0,-852 # ffffffffc0205640 <commands+0x598>
ffffffffc020099c:	b7f9                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc020099e:	00005517          	auipc	a0,0x5
ffffffffc02009a2:	cc250513          	addi	a0,a0,-830 # ffffffffc0205660 <commands+0x5b8>
ffffffffc02009a6:	fdaff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009aa:	8522                	mv	a0,s0
ffffffffc02009ac:	c1fff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009b0:	84aa                	mv	s1,a0
ffffffffc02009b2:	d15d                	beqz	a0,ffffffffc0200958 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009b4:	8522                	mv	a0,s0
ffffffffc02009b6:	e6bff0ef          	jal	ra,ffffffffc0200820 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ba:	86a6                	mv	a3,s1
ffffffffc02009bc:	00005617          	auipc	a2,0x5
ffffffffc02009c0:	cbc60613          	addi	a2,a2,-836 # ffffffffc0205678 <commands+0x5d0>
ffffffffc02009c4:	0b300593          	li	a1,179
ffffffffc02009c8:	00004517          	auipc	a0,0x4
ffffffffc02009cc:	7a050513          	addi	a0,a0,1952 # ffffffffc0205168 <commands+0xc0>
ffffffffc02009d0:	a77ff0ef          	jal	ra,ffffffffc0200446 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009d4:	00005517          	auipc	a0,0x5
ffffffffc02009d8:	cc450513          	addi	a0,a0,-828 # ffffffffc0205698 <commands+0x5f0>
ffffffffc02009dc:	b779                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	cd250513          	addi	a0,a0,-814 # ffffffffc02056b0 <commands+0x608>
ffffffffc02009e6:	f9aff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ea:	8522                	mv	a0,s0
ffffffffc02009ec:	bdfff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009f0:	84aa                	mv	s1,a0
ffffffffc02009f2:	d13d                	beqz	a0,ffffffffc0200958 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009f4:	8522                	mv	a0,s0
ffffffffc02009f6:	e2bff0ef          	jal	ra,ffffffffc0200820 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009fa:	86a6                	mv	a3,s1
ffffffffc02009fc:	00005617          	auipc	a2,0x5
ffffffffc0200a00:	c7c60613          	addi	a2,a2,-900 # ffffffffc0205678 <commands+0x5d0>
ffffffffc0200a04:	0bd00593          	li	a1,189
ffffffffc0200a08:	00004517          	auipc	a0,0x4
ffffffffc0200a0c:	76050513          	addi	a0,a0,1888 # ffffffffc0205168 <commands+0xc0>
ffffffffc0200a10:	a37ff0ef          	jal	ra,ffffffffc0200446 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a14:	00005517          	auipc	a0,0x5
ffffffffc0200a18:	cb450513          	addi	a0,a0,-844 # ffffffffc02056c8 <commands+0x620>
ffffffffc0200a1c:	b7b9                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	cca50513          	addi	a0,a0,-822 # ffffffffc02056e8 <commands+0x640>
ffffffffc0200a26:	b791                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a28:	00005517          	auipc	a0,0x5
ffffffffc0200a2c:	ce050513          	addi	a0,a0,-800 # ffffffffc0205708 <commands+0x660>
ffffffffc0200a30:	bf2d                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a32:	00005517          	auipc	a0,0x5
ffffffffc0200a36:	cf650513          	addi	a0,a0,-778 # ffffffffc0205728 <commands+0x680>
ffffffffc0200a3a:	bf05                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a3c:	00005517          	auipc	a0,0x5
ffffffffc0200a40:	d0c50513          	addi	a0,a0,-756 # ffffffffc0205748 <commands+0x6a0>
ffffffffc0200a44:	b71d                	j	ffffffffc020096a <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a46:	00005517          	auipc	a0,0x5
ffffffffc0200a4a:	d1a50513          	addi	a0,a0,-742 # ffffffffc0205760 <commands+0x6b8>
ffffffffc0200a4e:	f32ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a52:	8522                	mv	a0,s0
ffffffffc0200a54:	b77ff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200a58:	84aa                	mv	s1,a0
ffffffffc0200a5a:	ee050fe3          	beqz	a0,ffffffffc0200958 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a5e:	8522                	mv	a0,s0
ffffffffc0200a60:	dc1ff0ef          	jal	ra,ffffffffc0200820 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a64:	86a6                	mv	a3,s1
ffffffffc0200a66:	00005617          	auipc	a2,0x5
ffffffffc0200a6a:	c1260613          	addi	a2,a2,-1006 # ffffffffc0205678 <commands+0x5d0>
ffffffffc0200a6e:	0d300593          	li	a1,211
ffffffffc0200a72:	00004517          	auipc	a0,0x4
ffffffffc0200a76:	6f650513          	addi	a0,a0,1782 # ffffffffc0205168 <commands+0xc0>
ffffffffc0200a7a:	9cdff0ef          	jal	ra,ffffffffc0200446 <__panic>
            print_trapframe(tf);
ffffffffc0200a7e:	8522                	mv	a0,s0
}
ffffffffc0200a80:	6442                	ld	s0,16(sp)
ffffffffc0200a82:	60e2                	ld	ra,24(sp)
ffffffffc0200a84:	64a2                	ld	s1,8(sp)
ffffffffc0200a86:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200a88:	bb61                	j	ffffffffc0200820 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200a8a:	8522                	mv	a0,s0
ffffffffc0200a8c:	d95ff0ef          	jal	ra,ffffffffc0200820 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a90:	86a6                	mv	a3,s1
ffffffffc0200a92:	00005617          	auipc	a2,0x5
ffffffffc0200a96:	be660613          	addi	a2,a2,-1050 # ffffffffc0205678 <commands+0x5d0>
ffffffffc0200a9a:	0da00593          	li	a1,218
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	6ca50513          	addi	a0,a0,1738 # ffffffffc0205168 <commands+0xc0>
ffffffffc0200aa6:	9a1ff0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0200aaa <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200aaa:	11853783          	ld	a5,280(a0)
ffffffffc0200aae:	0007c363          	bltz	a5,ffffffffc0200ab4 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200ab2:	b5a5                	j	ffffffffc020091a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ab4:	b3f9                	j	ffffffffc0200882 <interrupt_handler>
	...

ffffffffc0200ab8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ab8:	14011073          	csrw	sscratch,sp
ffffffffc0200abc:	712d                	addi	sp,sp,-288
ffffffffc0200abe:	e406                	sd	ra,8(sp)
ffffffffc0200ac0:	ec0e                	sd	gp,24(sp)
ffffffffc0200ac2:	f012                	sd	tp,32(sp)
ffffffffc0200ac4:	f416                	sd	t0,40(sp)
ffffffffc0200ac6:	f81a                	sd	t1,48(sp)
ffffffffc0200ac8:	fc1e                	sd	t2,56(sp)
ffffffffc0200aca:	e0a2                	sd	s0,64(sp)
ffffffffc0200acc:	e4a6                	sd	s1,72(sp)
ffffffffc0200ace:	e8aa                	sd	a0,80(sp)
ffffffffc0200ad0:	ecae                	sd	a1,88(sp)
ffffffffc0200ad2:	f0b2                	sd	a2,96(sp)
ffffffffc0200ad4:	f4b6                	sd	a3,104(sp)
ffffffffc0200ad6:	f8ba                	sd	a4,112(sp)
ffffffffc0200ad8:	fcbe                	sd	a5,120(sp)
ffffffffc0200ada:	e142                	sd	a6,128(sp)
ffffffffc0200adc:	e546                	sd	a7,136(sp)
ffffffffc0200ade:	e94a                	sd	s2,144(sp)
ffffffffc0200ae0:	ed4e                	sd	s3,152(sp)
ffffffffc0200ae2:	f152                	sd	s4,160(sp)
ffffffffc0200ae4:	f556                	sd	s5,168(sp)
ffffffffc0200ae6:	f95a                	sd	s6,176(sp)
ffffffffc0200ae8:	fd5e                	sd	s7,184(sp)
ffffffffc0200aea:	e1e2                	sd	s8,192(sp)
ffffffffc0200aec:	e5e6                	sd	s9,200(sp)
ffffffffc0200aee:	e9ea                	sd	s10,208(sp)
ffffffffc0200af0:	edee                	sd	s11,216(sp)
ffffffffc0200af2:	f1f2                	sd	t3,224(sp)
ffffffffc0200af4:	f5f6                	sd	t4,232(sp)
ffffffffc0200af6:	f9fa                	sd	t5,240(sp)
ffffffffc0200af8:	fdfe                	sd	t6,248(sp)
ffffffffc0200afa:	14002473          	csrr	s0,sscratch
ffffffffc0200afe:	100024f3          	csrr	s1,sstatus
ffffffffc0200b02:	14102973          	csrr	s2,sepc
ffffffffc0200b06:	143029f3          	csrr	s3,stval
ffffffffc0200b0a:	14202a73          	csrr	s4,scause
ffffffffc0200b0e:	e822                	sd	s0,16(sp)
ffffffffc0200b10:	e226                	sd	s1,256(sp)
ffffffffc0200b12:	e64a                	sd	s2,264(sp)
ffffffffc0200b14:	ea4e                	sd	s3,272(sp)
ffffffffc0200b16:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b18:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b1a:	f91ff0ef          	jal	ra,ffffffffc0200aaa <trap>

ffffffffc0200b1e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b1e:	6492                	ld	s1,256(sp)
ffffffffc0200b20:	6932                	ld	s2,264(sp)
ffffffffc0200b22:	10049073          	csrw	sstatus,s1
ffffffffc0200b26:	14191073          	csrw	sepc,s2
ffffffffc0200b2a:	60a2                	ld	ra,8(sp)
ffffffffc0200b2c:	61e2                	ld	gp,24(sp)
ffffffffc0200b2e:	7202                	ld	tp,32(sp)
ffffffffc0200b30:	72a2                	ld	t0,40(sp)
ffffffffc0200b32:	7342                	ld	t1,48(sp)
ffffffffc0200b34:	73e2                	ld	t2,56(sp)
ffffffffc0200b36:	6406                	ld	s0,64(sp)
ffffffffc0200b38:	64a6                	ld	s1,72(sp)
ffffffffc0200b3a:	6546                	ld	a0,80(sp)
ffffffffc0200b3c:	65e6                	ld	a1,88(sp)
ffffffffc0200b3e:	7606                	ld	a2,96(sp)
ffffffffc0200b40:	76a6                	ld	a3,104(sp)
ffffffffc0200b42:	7746                	ld	a4,112(sp)
ffffffffc0200b44:	77e6                	ld	a5,120(sp)
ffffffffc0200b46:	680a                	ld	a6,128(sp)
ffffffffc0200b48:	68aa                	ld	a7,136(sp)
ffffffffc0200b4a:	694a                	ld	s2,144(sp)
ffffffffc0200b4c:	69ea                	ld	s3,152(sp)
ffffffffc0200b4e:	7a0a                	ld	s4,160(sp)
ffffffffc0200b50:	7aaa                	ld	s5,168(sp)
ffffffffc0200b52:	7b4a                	ld	s6,176(sp)
ffffffffc0200b54:	7bea                	ld	s7,184(sp)
ffffffffc0200b56:	6c0e                	ld	s8,192(sp)
ffffffffc0200b58:	6cae                	ld	s9,200(sp)
ffffffffc0200b5a:	6d4e                	ld	s10,208(sp)
ffffffffc0200b5c:	6dee                	ld	s11,216(sp)
ffffffffc0200b5e:	7e0e                	ld	t3,224(sp)
ffffffffc0200b60:	7eae                	ld	t4,232(sp)
ffffffffc0200b62:	7f4e                	ld	t5,240(sp)
ffffffffc0200b64:	7fee                	ld	t6,248(sp)
ffffffffc0200b66:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b68:	10200073          	sret

ffffffffc0200b6c <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b6c:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b6e:	bf45                	j	ffffffffc0200b1e <__trapret>
	...

ffffffffc0200b72 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b72:	00011797          	auipc	a5,0x11
ffffffffc0200b76:	8ee78793          	addi	a5,a5,-1810 # ffffffffc0211460 <free_area>
ffffffffc0200b7a:	e79c                	sd	a5,8(a5)
ffffffffc0200b7c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b7e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b82:	8082                	ret

ffffffffc0200b84 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b84:	00011517          	auipc	a0,0x11
ffffffffc0200b88:	8ec56503          	lwu	a0,-1812(a0) # ffffffffc0211470 <free_area+0x10>
ffffffffc0200b8c:	8082                	ret

ffffffffc0200b8e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200b8e:	715d                	addi	sp,sp,-80
ffffffffc0200b90:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b92:	00011417          	auipc	s0,0x11
ffffffffc0200b96:	8ce40413          	addi	s0,s0,-1842 # ffffffffc0211460 <free_area>
ffffffffc0200b9a:	641c                	ld	a5,8(s0)
ffffffffc0200b9c:	e486                	sd	ra,72(sp)
ffffffffc0200b9e:	fc26                	sd	s1,56(sp)
ffffffffc0200ba0:	f84a                	sd	s2,48(sp)
ffffffffc0200ba2:	f44e                	sd	s3,40(sp)
ffffffffc0200ba4:	f052                	sd	s4,32(sp)
ffffffffc0200ba6:	ec56                	sd	s5,24(sp)
ffffffffc0200ba8:	e85a                	sd	s6,16(sp)
ffffffffc0200baa:	e45e                	sd	s7,8(sp)
ffffffffc0200bac:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bae:	2a878d63          	beq	a5,s0,ffffffffc0200e68 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200bb2:	4481                	li	s1,0
ffffffffc0200bb4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200bb6:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200bba:	8b09                	andi	a4,a4,2
ffffffffc0200bbc:	2a070a63          	beqz	a4,ffffffffc0200e70 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200bc0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bc4:	679c                	ld	a5,8(a5)
ffffffffc0200bc6:	2905                	addiw	s2,s2,1
ffffffffc0200bc8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bca:	fe8796e3          	bne	a5,s0,ffffffffc0200bb6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200bce:	89a6                	mv	s3,s1
ffffffffc0200bd0:	725000ef          	jal	ra,ffffffffc0201af4 <nr_free_pages>
ffffffffc0200bd4:	6f351e63          	bne	a0,s3,ffffffffc02012d0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bd8:	4505                	li	a0,1
ffffffffc0200bda:	649000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200bde:	8aaa                	mv	s5,a0
ffffffffc0200be0:	42050863          	beqz	a0,ffffffffc0201010 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200be4:	4505                	li	a0,1
ffffffffc0200be6:	63d000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200bea:	89aa                	mv	s3,a0
ffffffffc0200bec:	70050263          	beqz	a0,ffffffffc02012f0 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200bf0:	4505                	li	a0,1
ffffffffc0200bf2:	631000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200bf6:	8a2a                	mv	s4,a0
ffffffffc0200bf8:	48050c63          	beqz	a0,ffffffffc0201090 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200bfc:	293a8a63          	beq	s5,s3,ffffffffc0200e90 <default_check+0x302>
ffffffffc0200c00:	28aa8863          	beq	s5,a0,ffffffffc0200e90 <default_check+0x302>
ffffffffc0200c04:	28a98663          	beq	s3,a0,ffffffffc0200e90 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c08:	000aa783          	lw	a5,0(s5)
ffffffffc0200c0c:	2a079263          	bnez	a5,ffffffffc0200eb0 <default_check+0x322>
ffffffffc0200c10:	0009a783          	lw	a5,0(s3)
ffffffffc0200c14:	28079e63          	bnez	a5,ffffffffc0200eb0 <default_check+0x322>
ffffffffc0200c18:	411c                	lw	a5,0(a0)
ffffffffc0200c1a:	28079b63          	bnez	a5,ffffffffc0200eb0 <default_check+0x322>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200c1e:	00015797          	auipc	a5,0x15
ffffffffc0200c22:	9527b783          	ld	a5,-1710(a5) # ffffffffc0215570 <pages>
ffffffffc0200c26:	40fa8733          	sub	a4,s5,a5
ffffffffc0200c2a:	00006617          	auipc	a2,0x6
ffffffffc0200c2e:	2be63603          	ld	a2,702(a2) # ffffffffc0206ee8 <nbase>
ffffffffc0200c32:	8719                	srai	a4,a4,0x6
ffffffffc0200c34:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c36:	00015697          	auipc	a3,0x15
ffffffffc0200c3a:	9326b683          	ld	a3,-1742(a3) # ffffffffc0215568 <npage>
ffffffffc0200c3e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c40:	0732                	slli	a4,a4,0xc
ffffffffc0200c42:	28d77763          	bgeu	a4,a3,ffffffffc0200ed0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200c46:	40f98733          	sub	a4,s3,a5
ffffffffc0200c4a:	8719                	srai	a4,a4,0x6
ffffffffc0200c4c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c4e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c50:	4cd77063          	bgeu	a4,a3,ffffffffc0201110 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200c54:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c58:	8799                	srai	a5,a5,0x6
ffffffffc0200c5a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c5c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c5e:	30d7f963          	bgeu	a5,a3,ffffffffc0200f70 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200c62:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c64:	00043c03          	ld	s8,0(s0)
ffffffffc0200c68:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200c6c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200c70:	e400                	sd	s0,8(s0)
ffffffffc0200c72:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200c74:	00010797          	auipc	a5,0x10
ffffffffc0200c78:	7e07ae23          	sw	zero,2044(a5) # ffffffffc0211470 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c7c:	5a7000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200c80:	2c051863          	bnez	a0,ffffffffc0200f50 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200c84:	4585                	li	a1,1
ffffffffc0200c86:	8556                	mv	a0,s5
ffffffffc0200c88:	62d000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_page(p1);
ffffffffc0200c8c:	4585                	li	a1,1
ffffffffc0200c8e:	854e                	mv	a0,s3
ffffffffc0200c90:	625000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_page(p2);
ffffffffc0200c94:	4585                	li	a1,1
ffffffffc0200c96:	8552                	mv	a0,s4
ffffffffc0200c98:	61d000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c9c:	4818                	lw	a4,16(s0)
ffffffffc0200c9e:	478d                	li	a5,3
ffffffffc0200ca0:	28f71863          	bne	a4,a5,ffffffffc0200f30 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ca4:	4505                	li	a0,1
ffffffffc0200ca6:	57d000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200caa:	89aa                	mv	s3,a0
ffffffffc0200cac:	26050263          	beqz	a0,ffffffffc0200f10 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cb0:	4505                	li	a0,1
ffffffffc0200cb2:	571000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200cb6:	8aaa                	mv	s5,a0
ffffffffc0200cb8:	3a050c63          	beqz	a0,ffffffffc0201070 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cbc:	4505                	li	a0,1
ffffffffc0200cbe:	565000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200cc2:	8a2a                	mv	s4,a0
ffffffffc0200cc4:	38050663          	beqz	a0,ffffffffc0201050 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200cc8:	4505                	li	a0,1
ffffffffc0200cca:	559000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200cce:	36051163          	bnez	a0,ffffffffc0201030 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200cd2:	4585                	li	a1,1
ffffffffc0200cd4:	854e                	mv	a0,s3
ffffffffc0200cd6:	5df000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200cda:	641c                	ld	a5,8(s0)
ffffffffc0200cdc:	20878a63          	beq	a5,s0,ffffffffc0200ef0 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200ce0:	4505                	li	a0,1
ffffffffc0200ce2:	541000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200ce6:	30a99563          	bne	s3,a0,ffffffffc0200ff0 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200cea:	4505                	li	a0,1
ffffffffc0200cec:	537000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200cf0:	2e051063          	bnez	a0,ffffffffc0200fd0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200cf4:	481c                	lw	a5,16(s0)
ffffffffc0200cf6:	2a079d63          	bnez	a5,ffffffffc0200fb0 <default_check+0x422>
    free_page(p);
ffffffffc0200cfa:	854e                	mv	a0,s3
ffffffffc0200cfc:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200cfe:	01843023          	sd	s8,0(s0)
ffffffffc0200d02:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200d06:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200d0a:	5ab000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_page(p1);
ffffffffc0200d0e:	4585                	li	a1,1
ffffffffc0200d10:	8556                	mv	a0,s5
ffffffffc0200d12:	5a3000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_page(p2);
ffffffffc0200d16:	4585                	li	a1,1
ffffffffc0200d18:	8552                	mv	a0,s4
ffffffffc0200d1a:	59b000ef          	jal	ra,ffffffffc0201ab4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200d1e:	4515                	li	a0,5
ffffffffc0200d20:	503000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200d24:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d26:	26050563          	beqz	a0,ffffffffc0200f90 <default_check+0x402>
ffffffffc0200d2a:	651c                	ld	a5,8(a0)
ffffffffc0200d2c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200d2e:	8b85                	andi	a5,a5,1
ffffffffc0200d30:	54079063          	bnez	a5,ffffffffc0201270 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200d34:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d36:	00043b03          	ld	s6,0(s0)
ffffffffc0200d3a:	00843a83          	ld	s5,8(s0)
ffffffffc0200d3e:	e000                	sd	s0,0(s0)
ffffffffc0200d40:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200d42:	4e1000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200d46:	50051563          	bnez	a0,ffffffffc0201250 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200d4a:	08098a13          	addi	s4,s3,128
ffffffffc0200d4e:	8552                	mv	a0,s4
ffffffffc0200d50:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d52:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200d56:	00010797          	auipc	a5,0x10
ffffffffc0200d5a:	7007ad23          	sw	zero,1818(a5) # ffffffffc0211470 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d5e:	557000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d62:	4511                	li	a0,4
ffffffffc0200d64:	4bf000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200d68:	4c051463          	bnez	a0,ffffffffc0201230 <default_check+0x6a2>
ffffffffc0200d6c:	0889b783          	ld	a5,136(s3)
ffffffffc0200d70:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d72:	8b85                	andi	a5,a5,1
ffffffffc0200d74:	48078e63          	beqz	a5,ffffffffc0201210 <default_check+0x682>
ffffffffc0200d78:	0909a703          	lw	a4,144(s3)
ffffffffc0200d7c:	478d                	li	a5,3
ffffffffc0200d7e:	48f71963          	bne	a4,a5,ffffffffc0201210 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d82:	450d                	li	a0,3
ffffffffc0200d84:	49f000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200d88:	8c2a                	mv	s8,a0
ffffffffc0200d8a:	46050363          	beqz	a0,ffffffffc02011f0 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200d8e:	4505                	li	a0,1
ffffffffc0200d90:	493000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200d94:	42051e63          	bnez	a0,ffffffffc02011d0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200d98:	418a1c63          	bne	s4,s8,ffffffffc02011b0 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d9c:	4585                	li	a1,1
ffffffffc0200d9e:	854e                	mv	a0,s3
ffffffffc0200da0:	515000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_pages(p1, 3);
ffffffffc0200da4:	458d                	li	a1,3
ffffffffc0200da6:	8552                	mv	a0,s4
ffffffffc0200da8:	50d000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
ffffffffc0200dac:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200db0:	04098c13          	addi	s8,s3,64
ffffffffc0200db4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200db6:	8b85                	andi	a5,a5,1
ffffffffc0200db8:	3c078c63          	beqz	a5,ffffffffc0201190 <default_check+0x602>
ffffffffc0200dbc:	0109a703          	lw	a4,16(s3)
ffffffffc0200dc0:	4785                	li	a5,1
ffffffffc0200dc2:	3cf71763          	bne	a4,a5,ffffffffc0201190 <default_check+0x602>
ffffffffc0200dc6:	008a3783          	ld	a5,8(s4)
ffffffffc0200dca:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200dcc:	8b85                	andi	a5,a5,1
ffffffffc0200dce:	3a078163          	beqz	a5,ffffffffc0201170 <default_check+0x5e2>
ffffffffc0200dd2:	010a2703          	lw	a4,16(s4)
ffffffffc0200dd6:	478d                	li	a5,3
ffffffffc0200dd8:	38f71c63          	bne	a4,a5,ffffffffc0201170 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ddc:	4505                	li	a0,1
ffffffffc0200dde:	445000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200de2:	36a99763          	bne	s3,a0,ffffffffc0201150 <default_check+0x5c2>
    free_page(p0);
ffffffffc0200de6:	4585                	li	a1,1
ffffffffc0200de8:	4cd000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200dec:	4509                	li	a0,2
ffffffffc0200dee:	435000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200df2:	32aa1f63          	bne	s4,a0,ffffffffc0201130 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0200df6:	4589                	li	a1,2
ffffffffc0200df8:	4bd000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    free_page(p2);
ffffffffc0200dfc:	4585                	li	a1,1
ffffffffc0200dfe:	8562                	mv	a0,s8
ffffffffc0200e00:	4b5000ef          	jal	ra,ffffffffc0201ab4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e04:	4515                	li	a0,5
ffffffffc0200e06:	41d000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200e0a:	89aa                	mv	s3,a0
ffffffffc0200e0c:	48050263          	beqz	a0,ffffffffc0201290 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0200e10:	4505                	li	a0,1
ffffffffc0200e12:	411000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0200e16:	2c051d63          	bnez	a0,ffffffffc02010f0 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0200e1a:	481c                	lw	a5,16(s0)
ffffffffc0200e1c:	2a079a63          	bnez	a5,ffffffffc02010d0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e20:	4595                	li	a1,5
ffffffffc0200e22:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e24:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200e28:	01643023          	sd	s6,0(s0)
ffffffffc0200e2c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200e30:	485000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    return listelm->next;
ffffffffc0200e34:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e36:	00878963          	beq	a5,s0,ffffffffc0200e48 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200e3a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e3e:	679c                	ld	a5,8(a5)
ffffffffc0200e40:	397d                	addiw	s2,s2,-1
ffffffffc0200e42:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e44:	fe879be3          	bne	a5,s0,ffffffffc0200e3a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0200e48:	26091463          	bnez	s2,ffffffffc02010b0 <default_check+0x522>
    assert(total == 0);
ffffffffc0200e4c:	46049263          	bnez	s1,ffffffffc02012b0 <default_check+0x722>
}
ffffffffc0200e50:	60a6                	ld	ra,72(sp)
ffffffffc0200e52:	6406                	ld	s0,64(sp)
ffffffffc0200e54:	74e2                	ld	s1,56(sp)
ffffffffc0200e56:	7942                	ld	s2,48(sp)
ffffffffc0200e58:	79a2                	ld	s3,40(sp)
ffffffffc0200e5a:	7a02                	ld	s4,32(sp)
ffffffffc0200e5c:	6ae2                	ld	s5,24(sp)
ffffffffc0200e5e:	6b42                	ld	s6,16(sp)
ffffffffc0200e60:	6ba2                	ld	s7,8(sp)
ffffffffc0200e62:	6c02                	ld	s8,0(sp)
ffffffffc0200e64:	6161                	addi	sp,sp,80
ffffffffc0200e66:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e68:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e6a:	4481                	li	s1,0
ffffffffc0200e6c:	4901                	li	s2,0
ffffffffc0200e6e:	b38d                	j	ffffffffc0200bd0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200e70:	00005697          	auipc	a3,0x5
ffffffffc0200e74:	96068693          	addi	a3,a3,-1696 # ffffffffc02057d0 <commands+0x728>
ffffffffc0200e78:	00005617          	auipc	a2,0x5
ffffffffc0200e7c:	96860613          	addi	a2,a2,-1688 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200e80:	0f000593          	li	a1,240
ffffffffc0200e84:	00005517          	auipc	a0,0x5
ffffffffc0200e88:	97450513          	addi	a0,a0,-1676 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200e8c:	dbaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e90:	00005697          	auipc	a3,0x5
ffffffffc0200e94:	a0068693          	addi	a3,a3,-1536 # ffffffffc0205890 <commands+0x7e8>
ffffffffc0200e98:	00005617          	auipc	a2,0x5
ffffffffc0200e9c:	94860613          	addi	a2,a2,-1720 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200ea0:	0bd00593          	li	a1,189
ffffffffc0200ea4:	00005517          	auipc	a0,0x5
ffffffffc0200ea8:	95450513          	addi	a0,a0,-1708 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200eac:	d9aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200eb0:	00005697          	auipc	a3,0x5
ffffffffc0200eb4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02058b8 <commands+0x810>
ffffffffc0200eb8:	00005617          	auipc	a2,0x5
ffffffffc0200ebc:	92860613          	addi	a2,a2,-1752 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200ec0:	0be00593          	li	a1,190
ffffffffc0200ec4:	00005517          	auipc	a0,0x5
ffffffffc0200ec8:	93450513          	addi	a0,a0,-1740 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200ecc:	d7aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ed0:	00005697          	auipc	a3,0x5
ffffffffc0200ed4:	a2868693          	addi	a3,a3,-1496 # ffffffffc02058f8 <commands+0x850>
ffffffffc0200ed8:	00005617          	auipc	a2,0x5
ffffffffc0200edc:	90860613          	addi	a2,a2,-1784 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200ee0:	0c000593          	li	a1,192
ffffffffc0200ee4:	00005517          	auipc	a0,0x5
ffffffffc0200ee8:	91450513          	addi	a0,a0,-1772 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200eec:	d5aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200ef0:	00005697          	auipc	a3,0x5
ffffffffc0200ef4:	a9068693          	addi	a3,a3,-1392 # ffffffffc0205980 <commands+0x8d8>
ffffffffc0200ef8:	00005617          	auipc	a2,0x5
ffffffffc0200efc:	8e860613          	addi	a2,a2,-1816 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200f00:	0d900593          	li	a1,217
ffffffffc0200f04:	00005517          	auipc	a0,0x5
ffffffffc0200f08:	8f450513          	addi	a0,a0,-1804 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200f0c:	d3aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f10:	00005697          	auipc	a3,0x5
ffffffffc0200f14:	92068693          	addi	a3,a3,-1760 # ffffffffc0205830 <commands+0x788>
ffffffffc0200f18:	00005617          	auipc	a2,0x5
ffffffffc0200f1c:	8c860613          	addi	a2,a2,-1848 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200f20:	0d200593          	li	a1,210
ffffffffc0200f24:	00005517          	auipc	a0,0x5
ffffffffc0200f28:	8d450513          	addi	a0,a0,-1836 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200f2c:	d1aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0200f30:	00005697          	auipc	a3,0x5
ffffffffc0200f34:	a4068693          	addi	a3,a3,-1472 # ffffffffc0205970 <commands+0x8c8>
ffffffffc0200f38:	00005617          	auipc	a2,0x5
ffffffffc0200f3c:	8a860613          	addi	a2,a2,-1880 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200f40:	0d000593          	li	a1,208
ffffffffc0200f44:	00005517          	auipc	a0,0x5
ffffffffc0200f48:	8b450513          	addi	a0,a0,-1868 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200f4c:	cfaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f50:	00005697          	auipc	a3,0x5
ffffffffc0200f54:	a0868693          	addi	a3,a3,-1528 # ffffffffc0205958 <commands+0x8b0>
ffffffffc0200f58:	00005617          	auipc	a2,0x5
ffffffffc0200f5c:	88860613          	addi	a2,a2,-1912 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200f60:	0cb00593          	li	a1,203
ffffffffc0200f64:	00005517          	auipc	a0,0x5
ffffffffc0200f68:	89450513          	addi	a0,a0,-1900 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200f6c:	cdaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f70:	00005697          	auipc	a3,0x5
ffffffffc0200f74:	9c868693          	addi	a3,a3,-1592 # ffffffffc0205938 <commands+0x890>
ffffffffc0200f78:	00005617          	auipc	a2,0x5
ffffffffc0200f7c:	86860613          	addi	a2,a2,-1944 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200f80:	0c200593          	li	a1,194
ffffffffc0200f84:	00005517          	auipc	a0,0x5
ffffffffc0200f88:	87450513          	addi	a0,a0,-1932 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200f8c:	cbaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc0200f90:	00005697          	auipc	a3,0x5
ffffffffc0200f94:	a3868693          	addi	a3,a3,-1480 # ffffffffc02059c8 <commands+0x920>
ffffffffc0200f98:	00005617          	auipc	a2,0x5
ffffffffc0200f9c:	84860613          	addi	a2,a2,-1976 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200fa0:	0f800593          	li	a1,248
ffffffffc0200fa4:	00005517          	auipc	a0,0x5
ffffffffc0200fa8:	85450513          	addi	a0,a0,-1964 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200fac:	c9aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc0200fb0:	00005697          	auipc	a3,0x5
ffffffffc0200fb4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02059b8 <commands+0x910>
ffffffffc0200fb8:	00005617          	auipc	a2,0x5
ffffffffc0200fbc:	82860613          	addi	a2,a2,-2008 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200fc0:	0df00593          	li	a1,223
ffffffffc0200fc4:	00005517          	auipc	a0,0x5
ffffffffc0200fc8:	83450513          	addi	a0,a0,-1996 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200fcc:	c7aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fd0:	00005697          	auipc	a3,0x5
ffffffffc0200fd4:	98868693          	addi	a3,a3,-1656 # ffffffffc0205958 <commands+0x8b0>
ffffffffc0200fd8:	00005617          	auipc	a2,0x5
ffffffffc0200fdc:	80860613          	addi	a2,a2,-2040 # ffffffffc02057e0 <commands+0x738>
ffffffffc0200fe0:	0dd00593          	li	a1,221
ffffffffc0200fe4:	00005517          	auipc	a0,0x5
ffffffffc0200fe8:	81450513          	addi	a0,a0,-2028 # ffffffffc02057f8 <commands+0x750>
ffffffffc0200fec:	c5aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200ff0:	00005697          	auipc	a3,0x5
ffffffffc0200ff4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205998 <commands+0x8f0>
ffffffffc0200ff8:	00004617          	auipc	a2,0x4
ffffffffc0200ffc:	7e860613          	addi	a2,a2,2024 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201000:	0dc00593          	li	a1,220
ffffffffc0201004:	00004517          	auipc	a0,0x4
ffffffffc0201008:	7f450513          	addi	a0,a0,2036 # ffffffffc02057f8 <commands+0x750>
ffffffffc020100c:	c3aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201010:	00005697          	auipc	a3,0x5
ffffffffc0201014:	82068693          	addi	a3,a3,-2016 # ffffffffc0205830 <commands+0x788>
ffffffffc0201018:	00004617          	auipc	a2,0x4
ffffffffc020101c:	7c860613          	addi	a2,a2,1992 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201020:	0b900593          	li	a1,185
ffffffffc0201024:	00004517          	auipc	a0,0x4
ffffffffc0201028:	7d450513          	addi	a0,a0,2004 # ffffffffc02057f8 <commands+0x750>
ffffffffc020102c:	c1aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201030:	00005697          	auipc	a3,0x5
ffffffffc0201034:	92868693          	addi	a3,a3,-1752 # ffffffffc0205958 <commands+0x8b0>
ffffffffc0201038:	00004617          	auipc	a2,0x4
ffffffffc020103c:	7a860613          	addi	a2,a2,1960 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201040:	0d600593          	li	a1,214
ffffffffc0201044:	00004517          	auipc	a0,0x4
ffffffffc0201048:	7b450513          	addi	a0,a0,1972 # ffffffffc02057f8 <commands+0x750>
ffffffffc020104c:	bfaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201050:	00005697          	auipc	a3,0x5
ffffffffc0201054:	82068693          	addi	a3,a3,-2016 # ffffffffc0205870 <commands+0x7c8>
ffffffffc0201058:	00004617          	auipc	a2,0x4
ffffffffc020105c:	78860613          	addi	a2,a2,1928 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201060:	0d400593          	li	a1,212
ffffffffc0201064:	00004517          	auipc	a0,0x4
ffffffffc0201068:	79450513          	addi	a0,a0,1940 # ffffffffc02057f8 <commands+0x750>
ffffffffc020106c:	bdaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201070:	00004697          	auipc	a3,0x4
ffffffffc0201074:	7e068693          	addi	a3,a3,2016 # ffffffffc0205850 <commands+0x7a8>
ffffffffc0201078:	00004617          	auipc	a2,0x4
ffffffffc020107c:	76860613          	addi	a2,a2,1896 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201080:	0d300593          	li	a1,211
ffffffffc0201084:	00004517          	auipc	a0,0x4
ffffffffc0201088:	77450513          	addi	a0,a0,1908 # ffffffffc02057f8 <commands+0x750>
ffffffffc020108c:	bbaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201090:	00004697          	auipc	a3,0x4
ffffffffc0201094:	7e068693          	addi	a3,a3,2016 # ffffffffc0205870 <commands+0x7c8>
ffffffffc0201098:	00004617          	auipc	a2,0x4
ffffffffc020109c:	74860613          	addi	a2,a2,1864 # ffffffffc02057e0 <commands+0x738>
ffffffffc02010a0:	0bb00593          	li	a1,187
ffffffffc02010a4:	00004517          	auipc	a0,0x4
ffffffffc02010a8:	75450513          	addi	a0,a0,1876 # ffffffffc02057f8 <commands+0x750>
ffffffffc02010ac:	b9aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02010b0:	00005697          	auipc	a3,0x5
ffffffffc02010b4:	a6868693          	addi	a3,a3,-1432 # ffffffffc0205b18 <commands+0xa70>
ffffffffc02010b8:	00004617          	auipc	a2,0x4
ffffffffc02010bc:	72860613          	addi	a2,a2,1832 # ffffffffc02057e0 <commands+0x738>
ffffffffc02010c0:	12500593          	li	a1,293
ffffffffc02010c4:	00004517          	auipc	a0,0x4
ffffffffc02010c8:	73450513          	addi	a0,a0,1844 # ffffffffc02057f8 <commands+0x750>
ffffffffc02010cc:	b7aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02010d0:	00005697          	auipc	a3,0x5
ffffffffc02010d4:	8e868693          	addi	a3,a3,-1816 # ffffffffc02059b8 <commands+0x910>
ffffffffc02010d8:	00004617          	auipc	a2,0x4
ffffffffc02010dc:	70860613          	addi	a2,a2,1800 # ffffffffc02057e0 <commands+0x738>
ffffffffc02010e0:	11a00593          	li	a1,282
ffffffffc02010e4:	00004517          	auipc	a0,0x4
ffffffffc02010e8:	71450513          	addi	a0,a0,1812 # ffffffffc02057f8 <commands+0x750>
ffffffffc02010ec:	b5aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010f0:	00005697          	auipc	a3,0x5
ffffffffc02010f4:	86868693          	addi	a3,a3,-1944 # ffffffffc0205958 <commands+0x8b0>
ffffffffc02010f8:	00004617          	auipc	a2,0x4
ffffffffc02010fc:	6e860613          	addi	a2,a2,1768 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201100:	11800593          	li	a1,280
ffffffffc0201104:	00004517          	auipc	a0,0x4
ffffffffc0201108:	6f450513          	addi	a0,a0,1780 # ffffffffc02057f8 <commands+0x750>
ffffffffc020110c:	b3aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201110:	00005697          	auipc	a3,0x5
ffffffffc0201114:	80868693          	addi	a3,a3,-2040 # ffffffffc0205918 <commands+0x870>
ffffffffc0201118:	00004617          	auipc	a2,0x4
ffffffffc020111c:	6c860613          	addi	a2,a2,1736 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201120:	0c100593          	li	a1,193
ffffffffc0201124:	00004517          	auipc	a0,0x4
ffffffffc0201128:	6d450513          	addi	a0,a0,1748 # ffffffffc02057f8 <commands+0x750>
ffffffffc020112c:	b1aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201130:	00005697          	auipc	a3,0x5
ffffffffc0201134:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205ad8 <commands+0xa30>
ffffffffc0201138:	00004617          	auipc	a2,0x4
ffffffffc020113c:	6a860613          	addi	a2,a2,1704 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201140:	11200593          	li	a1,274
ffffffffc0201144:	00004517          	auipc	a0,0x4
ffffffffc0201148:	6b450513          	addi	a0,a0,1716 # ffffffffc02057f8 <commands+0x750>
ffffffffc020114c:	afaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201150:	00005697          	auipc	a3,0x5
ffffffffc0201154:	96868693          	addi	a3,a3,-1688 # ffffffffc0205ab8 <commands+0xa10>
ffffffffc0201158:	00004617          	auipc	a2,0x4
ffffffffc020115c:	68860613          	addi	a2,a2,1672 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201160:	11000593          	li	a1,272
ffffffffc0201164:	00004517          	auipc	a0,0x4
ffffffffc0201168:	69450513          	addi	a0,a0,1684 # ffffffffc02057f8 <commands+0x750>
ffffffffc020116c:	adaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201170:	00005697          	auipc	a3,0x5
ffffffffc0201174:	92068693          	addi	a3,a3,-1760 # ffffffffc0205a90 <commands+0x9e8>
ffffffffc0201178:	00004617          	auipc	a2,0x4
ffffffffc020117c:	66860613          	addi	a2,a2,1640 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201180:	10e00593          	li	a1,270
ffffffffc0201184:	00004517          	auipc	a0,0x4
ffffffffc0201188:	67450513          	addi	a0,a0,1652 # ffffffffc02057f8 <commands+0x750>
ffffffffc020118c:	abaff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201190:	00005697          	auipc	a3,0x5
ffffffffc0201194:	8d868693          	addi	a3,a3,-1832 # ffffffffc0205a68 <commands+0x9c0>
ffffffffc0201198:	00004617          	auipc	a2,0x4
ffffffffc020119c:	64860613          	addi	a2,a2,1608 # ffffffffc02057e0 <commands+0x738>
ffffffffc02011a0:	10d00593          	li	a1,269
ffffffffc02011a4:	00004517          	auipc	a0,0x4
ffffffffc02011a8:	65450513          	addi	a0,a0,1620 # ffffffffc02057f8 <commands+0x750>
ffffffffc02011ac:	a9aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02011b0:	00005697          	auipc	a3,0x5
ffffffffc02011b4:	8a868693          	addi	a3,a3,-1880 # ffffffffc0205a58 <commands+0x9b0>
ffffffffc02011b8:	00004617          	auipc	a2,0x4
ffffffffc02011bc:	62860613          	addi	a2,a2,1576 # ffffffffc02057e0 <commands+0x738>
ffffffffc02011c0:	10800593          	li	a1,264
ffffffffc02011c4:	00004517          	auipc	a0,0x4
ffffffffc02011c8:	63450513          	addi	a0,a0,1588 # ffffffffc02057f8 <commands+0x750>
ffffffffc02011cc:	a7aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011d0:	00004697          	auipc	a3,0x4
ffffffffc02011d4:	78868693          	addi	a3,a3,1928 # ffffffffc0205958 <commands+0x8b0>
ffffffffc02011d8:	00004617          	auipc	a2,0x4
ffffffffc02011dc:	60860613          	addi	a2,a2,1544 # ffffffffc02057e0 <commands+0x738>
ffffffffc02011e0:	10700593          	li	a1,263
ffffffffc02011e4:	00004517          	auipc	a0,0x4
ffffffffc02011e8:	61450513          	addi	a0,a0,1556 # ffffffffc02057f8 <commands+0x750>
ffffffffc02011ec:	a5aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011f0:	00005697          	auipc	a3,0x5
ffffffffc02011f4:	84868693          	addi	a3,a3,-1976 # ffffffffc0205a38 <commands+0x990>
ffffffffc02011f8:	00004617          	auipc	a2,0x4
ffffffffc02011fc:	5e860613          	addi	a2,a2,1512 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201200:	10600593          	li	a1,262
ffffffffc0201204:	00004517          	auipc	a0,0x4
ffffffffc0201208:	5f450513          	addi	a0,a0,1524 # ffffffffc02057f8 <commands+0x750>
ffffffffc020120c:	a3aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201210:	00004697          	auipc	a3,0x4
ffffffffc0201214:	7f868693          	addi	a3,a3,2040 # ffffffffc0205a08 <commands+0x960>
ffffffffc0201218:	00004617          	auipc	a2,0x4
ffffffffc020121c:	5c860613          	addi	a2,a2,1480 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201220:	10500593          	li	a1,261
ffffffffc0201224:	00004517          	auipc	a0,0x4
ffffffffc0201228:	5d450513          	addi	a0,a0,1492 # ffffffffc02057f8 <commands+0x750>
ffffffffc020122c:	a1aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201230:	00004697          	auipc	a3,0x4
ffffffffc0201234:	7c068693          	addi	a3,a3,1984 # ffffffffc02059f0 <commands+0x948>
ffffffffc0201238:	00004617          	auipc	a2,0x4
ffffffffc020123c:	5a860613          	addi	a2,a2,1448 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201240:	10400593          	li	a1,260
ffffffffc0201244:	00004517          	auipc	a0,0x4
ffffffffc0201248:	5b450513          	addi	a0,a0,1460 # ffffffffc02057f8 <commands+0x750>
ffffffffc020124c:	9faff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201250:	00004697          	auipc	a3,0x4
ffffffffc0201254:	70868693          	addi	a3,a3,1800 # ffffffffc0205958 <commands+0x8b0>
ffffffffc0201258:	00004617          	auipc	a2,0x4
ffffffffc020125c:	58860613          	addi	a2,a2,1416 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201260:	0fe00593          	li	a1,254
ffffffffc0201264:	00004517          	auipc	a0,0x4
ffffffffc0201268:	59450513          	addi	a0,a0,1428 # ffffffffc02057f8 <commands+0x750>
ffffffffc020126c:	9daff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201270:	00004697          	auipc	a3,0x4
ffffffffc0201274:	76868693          	addi	a3,a3,1896 # ffffffffc02059d8 <commands+0x930>
ffffffffc0201278:	00004617          	auipc	a2,0x4
ffffffffc020127c:	56860613          	addi	a2,a2,1384 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201280:	0f900593          	li	a1,249
ffffffffc0201284:	00004517          	auipc	a0,0x4
ffffffffc0201288:	57450513          	addi	a0,a0,1396 # ffffffffc02057f8 <commands+0x750>
ffffffffc020128c:	9baff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201290:	00005697          	auipc	a3,0x5
ffffffffc0201294:	86868693          	addi	a3,a3,-1944 # ffffffffc0205af8 <commands+0xa50>
ffffffffc0201298:	00004617          	auipc	a2,0x4
ffffffffc020129c:	54860613          	addi	a2,a2,1352 # ffffffffc02057e0 <commands+0x738>
ffffffffc02012a0:	11700593          	li	a1,279
ffffffffc02012a4:	00004517          	auipc	a0,0x4
ffffffffc02012a8:	55450513          	addi	a0,a0,1364 # ffffffffc02057f8 <commands+0x750>
ffffffffc02012ac:	99aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02012b0:	00005697          	auipc	a3,0x5
ffffffffc02012b4:	87868693          	addi	a3,a3,-1928 # ffffffffc0205b28 <commands+0xa80>
ffffffffc02012b8:	00004617          	auipc	a2,0x4
ffffffffc02012bc:	52860613          	addi	a2,a2,1320 # ffffffffc02057e0 <commands+0x738>
ffffffffc02012c0:	12600593          	li	a1,294
ffffffffc02012c4:	00004517          	auipc	a0,0x4
ffffffffc02012c8:	53450513          	addi	a0,a0,1332 # ffffffffc02057f8 <commands+0x750>
ffffffffc02012cc:	97aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02012d0:	00004697          	auipc	a3,0x4
ffffffffc02012d4:	54068693          	addi	a3,a3,1344 # ffffffffc0205810 <commands+0x768>
ffffffffc02012d8:	00004617          	auipc	a2,0x4
ffffffffc02012dc:	50860613          	addi	a2,a2,1288 # ffffffffc02057e0 <commands+0x738>
ffffffffc02012e0:	0f300593          	li	a1,243
ffffffffc02012e4:	00004517          	auipc	a0,0x4
ffffffffc02012e8:	51450513          	addi	a0,a0,1300 # ffffffffc02057f8 <commands+0x750>
ffffffffc02012ec:	95aff0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012f0:	00004697          	auipc	a3,0x4
ffffffffc02012f4:	56068693          	addi	a3,a3,1376 # ffffffffc0205850 <commands+0x7a8>
ffffffffc02012f8:	00004617          	auipc	a2,0x4
ffffffffc02012fc:	4e860613          	addi	a2,a2,1256 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201300:	0ba00593          	li	a1,186
ffffffffc0201304:	00004517          	auipc	a0,0x4
ffffffffc0201308:	4f450513          	addi	a0,a0,1268 # ffffffffc02057f8 <commands+0x750>
ffffffffc020130c:	93aff0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201310 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201310:	1141                	addi	sp,sp,-16
ffffffffc0201312:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201314:	12058f63          	beqz	a1,ffffffffc0201452 <default_free_pages+0x142>
    for (; p != base + n; p ++) {
ffffffffc0201318:	00659693          	slli	a3,a1,0x6
ffffffffc020131c:	96aa                	add	a3,a3,a0
ffffffffc020131e:	87aa                	mv	a5,a0
ffffffffc0201320:	02d50263          	beq	a0,a3,ffffffffc0201344 <default_free_pages+0x34>
ffffffffc0201324:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201326:	8b05                	andi	a4,a4,1
ffffffffc0201328:	10071563          	bnez	a4,ffffffffc0201432 <default_free_pages+0x122>
ffffffffc020132c:	6798                	ld	a4,8(a5)
ffffffffc020132e:	8b09                	andi	a4,a4,2
ffffffffc0201330:	10071163          	bnez	a4,ffffffffc0201432 <default_free_pages+0x122>
        p->flags = 0;
ffffffffc0201334:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201338:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020133c:	04078793          	addi	a5,a5,64
ffffffffc0201340:	fed792e3          	bne	a5,a3,ffffffffc0201324 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201344:	2581                	sext.w	a1,a1
ffffffffc0201346:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201348:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020134c:	4789                	li	a5,2
ffffffffc020134e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201352:	00010697          	auipc	a3,0x10
ffffffffc0201356:	10e68693          	addi	a3,a3,270 # ffffffffc0211460 <free_area>
ffffffffc020135a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020135c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020135e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201362:	9db9                	addw	a1,a1,a4
ffffffffc0201364:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201366:	08d78f63          	beq	a5,a3,ffffffffc0201404 <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc020136a:	fe878713          	addi	a4,a5,-24
ffffffffc020136e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201372:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201374:	00e56a63          	bltu	a0,a4,ffffffffc0201388 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201378:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020137a:	04d70a63          	beq	a4,a3,ffffffffc02013ce <default_free_pages+0xbe>
    for (; p != base + n; p ++) {
ffffffffc020137e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201380:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201384:	fee57ae3          	bgeu	a0,a4,ffffffffc0201378 <default_free_pages+0x68>
ffffffffc0201388:	c199                	beqz	a1,ffffffffc020138e <default_free_pages+0x7e>
ffffffffc020138a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020138e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201390:	e390                	sd	a2,0(a5)
ffffffffc0201392:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201394:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201396:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201398:	00d70c63          	beq	a4,a3,ffffffffc02013b0 <default_free_pages+0xa0>
        if (p + p->property == base) {
ffffffffc020139c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02013a0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02013a4:	02059793          	slli	a5,a1,0x20
ffffffffc02013a8:	83e9                	srli	a5,a5,0x1a
ffffffffc02013aa:	97b2                	add	a5,a5,a2
ffffffffc02013ac:	02f50b63          	beq	a0,a5,ffffffffc02013e2 <default_free_pages+0xd2>
    return listelm->next;
ffffffffc02013b0:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02013b2:	00d70b63          	beq	a4,a3,ffffffffc02013c8 <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc02013b6:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02013b8:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02013bc:	02061793          	slli	a5,a2,0x20
ffffffffc02013c0:	83e9                	srli	a5,a5,0x1a
ffffffffc02013c2:	97aa                	add	a5,a5,a0
ffffffffc02013c4:	04f68763          	beq	a3,a5,ffffffffc0201412 <default_free_pages+0x102>
}
ffffffffc02013c8:	60a2                	ld	ra,8(sp)
ffffffffc02013ca:	0141                	addi	sp,sp,16
ffffffffc02013cc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02013ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013d0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02013d2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013d4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013d6:	02d70463          	beq	a4,a3,ffffffffc02013fe <default_free_pages+0xee>
    prev->next = next->prev = elm;
ffffffffc02013da:	8832                	mv	a6,a2
ffffffffc02013dc:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02013de:	87ba                	mv	a5,a4
ffffffffc02013e0:	b745                	j	ffffffffc0201380 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02013e2:	491c                	lw	a5,16(a0)
ffffffffc02013e4:	9dbd                	addw	a1,a1,a5
ffffffffc02013e6:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013ea:	57f5                	li	a5,-3
ffffffffc02013ec:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013f0:	6d0c                	ld	a1,24(a0)
ffffffffc02013f2:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02013f4:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02013f6:	e59c                	sd	a5,8(a1)
    return listelm->next;
ffffffffc02013f8:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02013fa:	e38c                	sd	a1,0(a5)
ffffffffc02013fc:	bf5d                	j	ffffffffc02013b2 <default_free_pages+0xa2>
ffffffffc02013fe:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201400:	873e                	mv	a4,a5
ffffffffc0201402:	bf69                	j	ffffffffc020139c <default_free_pages+0x8c>
}
ffffffffc0201404:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201406:	e390                	sd	a2,0(a5)
ffffffffc0201408:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020140a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020140c:	ed1c                	sd	a5,24(a0)
ffffffffc020140e:	0141                	addi	sp,sp,16
ffffffffc0201410:	8082                	ret
            base->property += p->property;
ffffffffc0201412:	ff872783          	lw	a5,-8(a4)
ffffffffc0201416:	ff070693          	addi	a3,a4,-16
ffffffffc020141a:	9e3d                	addw	a2,a2,a5
ffffffffc020141c:	c910                	sw	a2,16(a0)
ffffffffc020141e:	57f5                	li	a5,-3
ffffffffc0201420:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201424:	6314                	ld	a3,0(a4)
ffffffffc0201426:	671c                	ld	a5,8(a4)
}
ffffffffc0201428:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020142a:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020142c:	e394                	sd	a3,0(a5)
ffffffffc020142e:	0141                	addi	sp,sp,16
ffffffffc0201430:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201432:	00004697          	auipc	a3,0x4
ffffffffc0201436:	70e68693          	addi	a3,a3,1806 # ffffffffc0205b40 <commands+0xa98>
ffffffffc020143a:	00004617          	auipc	a2,0x4
ffffffffc020143e:	3a660613          	addi	a2,a2,934 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201442:	08300593          	li	a1,131
ffffffffc0201446:	00004517          	auipc	a0,0x4
ffffffffc020144a:	3b250513          	addi	a0,a0,946 # ffffffffc02057f8 <commands+0x750>
ffffffffc020144e:	ff9fe0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201452:	00004697          	auipc	a3,0x4
ffffffffc0201456:	6e668693          	addi	a3,a3,1766 # ffffffffc0205b38 <commands+0xa90>
ffffffffc020145a:	00004617          	auipc	a2,0x4
ffffffffc020145e:	38660613          	addi	a2,a2,902 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201462:	08000593          	li	a1,128
ffffffffc0201466:	00004517          	auipc	a0,0x4
ffffffffc020146a:	39250513          	addi	a0,a0,914 # ffffffffc02057f8 <commands+0x750>
ffffffffc020146e:	fd9fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201472 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201472:	c941                	beqz	a0,ffffffffc0201502 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0201474:	00010597          	auipc	a1,0x10
ffffffffc0201478:	fec58593          	addi	a1,a1,-20 # ffffffffc0211460 <free_area>
ffffffffc020147c:	0105a803          	lw	a6,16(a1)
ffffffffc0201480:	872a                	mv	a4,a0
ffffffffc0201482:	02081793          	slli	a5,a6,0x20
ffffffffc0201486:	9381                	srli	a5,a5,0x20
ffffffffc0201488:	00a7ee63          	bltu	a5,a0,ffffffffc02014a4 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020148c:	87ae                	mv	a5,a1
ffffffffc020148e:	a801                	j	ffffffffc020149e <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201490:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201494:	02069613          	slli	a2,a3,0x20
ffffffffc0201498:	9201                	srli	a2,a2,0x20
ffffffffc020149a:	00e67763          	bgeu	a2,a4,ffffffffc02014a8 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020149e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014a0:	feb798e3          	bne	a5,a1,ffffffffc0201490 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02014a4:	4501                	li	a0,0
}
ffffffffc02014a6:	8082                	ret
    return listelm->prev;
ffffffffc02014a8:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ac:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02014b0:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02014b4:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02014b8:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02014bc:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02014c0:	02c77863          	bgeu	a4,a2,ffffffffc02014f0 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02014c4:	071a                	slli	a4,a4,0x6
ffffffffc02014c6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02014c8:	41c686bb          	subw	a3,a3,t3
ffffffffc02014cc:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014ce:	00870613          	addi	a2,a4,8
ffffffffc02014d2:	4689                	li	a3,2
ffffffffc02014d4:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014d8:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02014dc:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02014e0:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02014e4:	e290                	sd	a2,0(a3)
ffffffffc02014e6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02014ea:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02014ec:	01173c23          	sd	a7,24(a4)
ffffffffc02014f0:	41c8083b          	subw	a6,a6,t3
ffffffffc02014f4:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014f8:	5775                	li	a4,-3
ffffffffc02014fa:	17c1                	addi	a5,a5,-16
ffffffffc02014fc:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201500:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201502:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201504:	00004697          	auipc	a3,0x4
ffffffffc0201508:	63468693          	addi	a3,a3,1588 # ffffffffc0205b38 <commands+0xa90>
ffffffffc020150c:	00004617          	auipc	a2,0x4
ffffffffc0201510:	2d460613          	addi	a2,a2,724 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201514:	06200593          	li	a1,98
ffffffffc0201518:	00004517          	auipc	a0,0x4
ffffffffc020151c:	2e050513          	addi	a0,a0,736 # ffffffffc02057f8 <commands+0x750>
default_alloc_pages(size_t n) {
ffffffffc0201520:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201522:	f25fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201526 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201526:	1141                	addi	sp,sp,-16
ffffffffc0201528:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020152a:	c5f1                	beqz	a1,ffffffffc02015f6 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020152c:	00659693          	slli	a3,a1,0x6
ffffffffc0201530:	96aa                	add	a3,a3,a0
ffffffffc0201532:	87aa                	mv	a5,a0
ffffffffc0201534:	00d50f63          	beq	a0,a3,ffffffffc0201552 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201538:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020153a:	8b05                	andi	a4,a4,1
ffffffffc020153c:	cf49                	beqz	a4,ffffffffc02015d6 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020153e:	0007a823          	sw	zero,16(a5)
ffffffffc0201542:	0007b423          	sd	zero,8(a5)
ffffffffc0201546:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020154a:	04078793          	addi	a5,a5,64
ffffffffc020154e:	fed795e3          	bne	a5,a3,ffffffffc0201538 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201552:	2581                	sext.w	a1,a1
ffffffffc0201554:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201556:	4789                	li	a5,2
ffffffffc0201558:	00850713          	addi	a4,a0,8
ffffffffc020155c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201560:	00010697          	auipc	a3,0x10
ffffffffc0201564:	f0068693          	addi	a3,a3,-256 # ffffffffc0211460 <free_area>
ffffffffc0201568:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020156a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020156c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201570:	9db9                	addw	a1,a1,a4
ffffffffc0201572:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201574:	04d78a63          	beq	a5,a3,ffffffffc02015c8 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0201578:	fe878713          	addi	a4,a5,-24
ffffffffc020157c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201580:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201582:	00e56a63          	bltu	a0,a4,ffffffffc0201596 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201586:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201588:	02d70263          	beq	a4,a3,ffffffffc02015ac <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020158c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020158e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201592:	fee57ae3          	bgeu	a0,a4,ffffffffc0201586 <default_init_memmap+0x60>
ffffffffc0201596:	c199                	beqz	a1,ffffffffc020159c <default_init_memmap+0x76>
ffffffffc0201598:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020159c:	6398                	ld	a4,0(a5)
}
ffffffffc020159e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015a0:	e390                	sd	a2,0(a5)
ffffffffc02015a2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015a6:	ed18                	sd	a4,24(a0)
ffffffffc02015a8:	0141                	addi	sp,sp,16
ffffffffc02015aa:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015ac:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015ae:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015b0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015b2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015b4:	00d70663          	beq	a4,a3,ffffffffc02015c0 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02015b8:	8832                	mv	a6,a2
ffffffffc02015ba:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02015bc:	87ba                	mv	a5,a4
ffffffffc02015be:	bfc1                	j	ffffffffc020158e <default_init_memmap+0x68>
}
ffffffffc02015c0:	60a2                	ld	ra,8(sp)
ffffffffc02015c2:	e290                	sd	a2,0(a3)
ffffffffc02015c4:	0141                	addi	sp,sp,16
ffffffffc02015c6:	8082                	ret
ffffffffc02015c8:	60a2                	ld	ra,8(sp)
ffffffffc02015ca:	e390                	sd	a2,0(a5)
ffffffffc02015cc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015ce:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015d0:	ed1c                	sd	a5,24(a0)
ffffffffc02015d2:	0141                	addi	sp,sp,16
ffffffffc02015d4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02015d6:	00004697          	auipc	a3,0x4
ffffffffc02015da:	59268693          	addi	a3,a3,1426 # ffffffffc0205b68 <commands+0xac0>
ffffffffc02015de:	00004617          	auipc	a2,0x4
ffffffffc02015e2:	20260613          	addi	a2,a2,514 # ffffffffc02057e0 <commands+0x738>
ffffffffc02015e6:	04900593          	li	a1,73
ffffffffc02015ea:	00004517          	auipc	a0,0x4
ffffffffc02015ee:	20e50513          	addi	a0,a0,526 # ffffffffc02057f8 <commands+0x750>
ffffffffc02015f2:	e55fe0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc02015f6:	00004697          	auipc	a3,0x4
ffffffffc02015fa:	54268693          	addi	a3,a3,1346 # ffffffffc0205b38 <commands+0xa90>
ffffffffc02015fe:	00004617          	auipc	a2,0x4
ffffffffc0201602:	1e260613          	addi	a2,a2,482 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201606:	04600593          	li	a1,70
ffffffffc020160a:	00004517          	auipc	a0,0x4
ffffffffc020160e:	1ee50513          	addi	a0,a0,494 # ffffffffc02057f8 <commands+0x750>
ffffffffc0201612:	e35fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201616 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201616:	c94d                	beqz	a0,ffffffffc02016c8 <slob_free+0xb2>
{
ffffffffc0201618:	1141                	addi	sp,sp,-16
ffffffffc020161a:	e022                	sd	s0,0(sp)
ffffffffc020161c:	e406                	sd	ra,8(sp)
ffffffffc020161e:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201620:	e9c1                	bnez	a1,ffffffffc02016b0 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201622:	100027f3          	csrr	a5,sstatus
ffffffffc0201626:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201628:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020162a:	ebd9                	bnez	a5,ffffffffc02016c0 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020162c:	00009617          	auipc	a2,0x9
ffffffffc0201630:	a2460613          	addi	a2,a2,-1500 # ffffffffc020a050 <slobfree>
ffffffffc0201634:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201636:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201638:	679c                	ld	a5,8(a5)
ffffffffc020163a:	02877a63          	bgeu	a4,s0,ffffffffc020166e <slob_free+0x58>
ffffffffc020163e:	00f46463          	bltu	s0,a5,ffffffffc0201646 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201642:	fef76ae3          	bltu	a4,a5,ffffffffc0201636 <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201646:	400c                	lw	a1,0(s0)
ffffffffc0201648:	00459693          	slli	a3,a1,0x4
ffffffffc020164c:	96a2                	add	a3,a3,s0
ffffffffc020164e:	02d78a63          	beq	a5,a3,ffffffffc0201682 <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0201652:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201654:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201656:	00469793          	slli	a5,a3,0x4
ffffffffc020165a:	97ba                	add	a5,a5,a4
ffffffffc020165c:	02f40e63          	beq	s0,a5,ffffffffc0201698 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0201660:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201662:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0201664:	e129                	bnez	a0,ffffffffc02016a6 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201666:	60a2                	ld	ra,8(sp)
ffffffffc0201668:	6402                	ld	s0,0(sp)
ffffffffc020166a:	0141                	addi	sp,sp,16
ffffffffc020166c:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020166e:	fcf764e3          	bltu	a4,a5,ffffffffc0201636 <slob_free+0x20>
ffffffffc0201672:	fcf472e3          	bgeu	s0,a5,ffffffffc0201636 <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0201676:	400c                	lw	a1,0(s0)
ffffffffc0201678:	00459693          	slli	a3,a1,0x4
ffffffffc020167c:	96a2                	add	a3,a3,s0
ffffffffc020167e:	fcd79ae3          	bne	a5,a3,ffffffffc0201652 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201682:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201684:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201686:	9db5                	addw	a1,a1,a3
ffffffffc0201688:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc020168a:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020168c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc020168e:	00469793          	slli	a5,a3,0x4
ffffffffc0201692:	97ba                	add	a5,a5,a4
ffffffffc0201694:	fcf416e3          	bne	s0,a5,ffffffffc0201660 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201698:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc020169a:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020169c:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020169e:	9ebd                	addw	a3,a3,a5
ffffffffc02016a0:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02016a2:	e70c                	sd	a1,8(a4)
ffffffffc02016a4:	d169                	beqz	a0,ffffffffc0201666 <slob_free+0x50>
}
ffffffffc02016a6:	6402                	ld	s0,0(sp)
ffffffffc02016a8:	60a2                	ld	ra,8(sp)
ffffffffc02016aa:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02016ac:	f11fe06f          	j	ffffffffc02005bc <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02016b0:	25bd                	addiw	a1,a1,15
ffffffffc02016b2:	8191                	srli	a1,a1,0x4
ffffffffc02016b4:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016b6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ba:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02016bc:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016be:	d7bd                	beqz	a5,ffffffffc020162c <slob_free+0x16>
        intr_disable();
ffffffffc02016c0:	f03fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        return 1;
ffffffffc02016c4:	4505                	li	a0,1
ffffffffc02016c6:	b79d                	j	ffffffffc020162c <slob_free+0x16>
ffffffffc02016c8:	8082                	ret

ffffffffc02016ca <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016ca:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02016cc:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016ce:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02016d2:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016d4:	34e000ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
  if(!page)
ffffffffc02016d8:	c91d                	beqz	a0,ffffffffc020170e <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02016da:	00014697          	auipc	a3,0x14
ffffffffc02016de:	e966b683          	ld	a3,-362(a3) # ffffffffc0215570 <pages>
ffffffffc02016e2:	8d15                	sub	a0,a0,a3
ffffffffc02016e4:	8519                	srai	a0,a0,0x6
ffffffffc02016e6:	00006697          	auipc	a3,0x6
ffffffffc02016ea:	8026b683          	ld	a3,-2046(a3) # ffffffffc0206ee8 <nbase>
ffffffffc02016ee:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02016f0:	00c51793          	slli	a5,a0,0xc
ffffffffc02016f4:	83b1                	srli	a5,a5,0xc
ffffffffc02016f6:	00014717          	auipc	a4,0x14
ffffffffc02016fa:	e7273703          	ld	a4,-398(a4) # ffffffffc0215568 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02016fe:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201700:	00e7fa63          	bgeu	a5,a4,ffffffffc0201714 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201704:	00014697          	auipc	a3,0x14
ffffffffc0201708:	e7c6b683          	ld	a3,-388(a3) # ffffffffc0215580 <va_pa_offset>
ffffffffc020170c:	9536                	add	a0,a0,a3
}
ffffffffc020170e:	60a2                	ld	ra,8(sp)
ffffffffc0201710:	0141                	addi	sp,sp,16
ffffffffc0201712:	8082                	ret
ffffffffc0201714:	86aa                	mv	a3,a0
ffffffffc0201716:	00004617          	auipc	a2,0x4
ffffffffc020171a:	4b260613          	addi	a2,a2,1202 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc020171e:	06900593          	li	a1,105
ffffffffc0201722:	00004517          	auipc	a0,0x4
ffffffffc0201726:	4ce50513          	addi	a0,a0,1230 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc020172a:	d1dfe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020172e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020172e:	1101                	addi	sp,sp,-32
ffffffffc0201730:	ec06                	sd	ra,24(sp)
ffffffffc0201732:	e822                	sd	s0,16(sp)
ffffffffc0201734:	e426                	sd	s1,8(sp)
ffffffffc0201736:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201738:	01050713          	addi	a4,a0,16
ffffffffc020173c:	6785                	lui	a5,0x1
ffffffffc020173e:	0cf77363          	bgeu	a4,a5,ffffffffc0201804 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201742:	00f50493          	addi	s1,a0,15
ffffffffc0201746:	8091                	srli	s1,s1,0x4
ffffffffc0201748:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020174a:	10002673          	csrr	a2,sstatus
ffffffffc020174e:	8a09                	andi	a2,a2,2
ffffffffc0201750:	e25d                	bnez	a2,ffffffffc02017f6 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201752:	00009917          	auipc	s2,0x9
ffffffffc0201756:	8fe90913          	addi	s2,s2,-1794 # ffffffffc020a050 <slobfree>
ffffffffc020175a:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020175e:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201760:	4398                	lw	a4,0(a5)
ffffffffc0201762:	08975e63          	bge	a4,s1,ffffffffc02017fe <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0201766:	00d78b63          	beq	a5,a3,ffffffffc020177c <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020176a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020176c:	4018                	lw	a4,0(s0)
ffffffffc020176e:	02975a63          	bge	a4,s1,ffffffffc02017a2 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201772:	00093683          	ld	a3,0(s2)
ffffffffc0201776:	87a2                	mv	a5,s0
ffffffffc0201778:	fed799e3          	bne	a5,a3,ffffffffc020176a <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc020177c:	ee31                	bnez	a2,ffffffffc02017d8 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc020177e:	4501                	li	a0,0
ffffffffc0201780:	f4bff0ef          	jal	ra,ffffffffc02016ca <__slob_get_free_pages.constprop.0>
ffffffffc0201784:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201786:	cd05                	beqz	a0,ffffffffc02017be <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201788:	6585                	lui	a1,0x1
ffffffffc020178a:	e8dff0ef          	jal	ra,ffffffffc0201616 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020178e:	10002673          	csrr	a2,sstatus
ffffffffc0201792:	8a09                	andi	a2,a2,2
ffffffffc0201794:	ee05                	bnez	a2,ffffffffc02017cc <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201796:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020179a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020179c:	4018                	lw	a4,0(s0)
ffffffffc020179e:	fc974ae3          	blt	a4,s1,ffffffffc0201772 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc02017a2:	04e48763          	beq	s1,a4,ffffffffc02017f0 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02017a6:	00449693          	slli	a3,s1,0x4
ffffffffc02017aa:	96a2                	add	a3,a3,s0
ffffffffc02017ac:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02017ae:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02017b0:	9f05                	subw	a4,a4,s1
ffffffffc02017b2:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02017b4:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02017b6:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02017b8:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02017bc:	e20d                	bnez	a2,ffffffffc02017de <slob_alloc.constprop.0+0xb0>
}
ffffffffc02017be:	60e2                	ld	ra,24(sp)
ffffffffc02017c0:	8522                	mv	a0,s0
ffffffffc02017c2:	6442                	ld	s0,16(sp)
ffffffffc02017c4:	64a2                	ld	s1,8(sp)
ffffffffc02017c6:	6902                	ld	s2,0(sp)
ffffffffc02017c8:	6105                	addi	sp,sp,32
ffffffffc02017ca:	8082                	ret
        intr_disable();
ffffffffc02017cc:	df7fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
			cur = slobfree;
ffffffffc02017d0:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02017d4:	4605                	li	a2,1
ffffffffc02017d6:	b7d1                	j	ffffffffc020179a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02017d8:	de5fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02017dc:	b74d                	j	ffffffffc020177e <slob_alloc.constprop.0+0x50>
ffffffffc02017de:	ddffe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
}
ffffffffc02017e2:	60e2                	ld	ra,24(sp)
ffffffffc02017e4:	8522                	mv	a0,s0
ffffffffc02017e6:	6442                	ld	s0,16(sp)
ffffffffc02017e8:	64a2                	ld	s1,8(sp)
ffffffffc02017ea:	6902                	ld	s2,0(sp)
ffffffffc02017ec:	6105                	addi	sp,sp,32
ffffffffc02017ee:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02017f0:	6418                	ld	a4,8(s0)
ffffffffc02017f2:	e798                	sd	a4,8(a5)
ffffffffc02017f4:	b7d1                	j	ffffffffc02017b8 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02017f6:	dcdfe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        return 1;
ffffffffc02017fa:	4605                	li	a2,1
ffffffffc02017fc:	bf99                	j	ffffffffc0201752 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02017fe:	843e                	mv	s0,a5
ffffffffc0201800:	87b6                	mv	a5,a3
ffffffffc0201802:	b745                	j	ffffffffc02017a2 <slob_alloc.constprop.0+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201804:	00004697          	auipc	a3,0x4
ffffffffc0201808:	3fc68693          	addi	a3,a3,1020 # ffffffffc0205c00 <default_pmm_manager+0x70>
ffffffffc020180c:	00004617          	auipc	a2,0x4
ffffffffc0201810:	fd460613          	addi	a2,a2,-44 # ffffffffc02057e0 <commands+0x738>
ffffffffc0201814:	06300593          	li	a1,99
ffffffffc0201818:	00004517          	auipc	a0,0x4
ffffffffc020181c:	40850513          	addi	a0,a0,1032 # ffffffffc0205c20 <default_pmm_manager+0x90>
ffffffffc0201820:	c27fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201824 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201824:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201826:	00004517          	auipc	a0,0x4
ffffffffc020182a:	41250513          	addi	a0,a0,1042 # ffffffffc0205c38 <default_pmm_manager+0xa8>
kmalloc_init(void) {
ffffffffc020182e:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201830:	951fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201834:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201836:	00004517          	auipc	a0,0x4
ffffffffc020183a:	41a50513          	addi	a0,a0,1050 # ffffffffc0205c50 <default_pmm_manager+0xc0>
}
ffffffffc020183e:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201840:	941fe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201844 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201844:	1101                	addi	sp,sp,-32
ffffffffc0201846:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201848:	6905                	lui	s2,0x1
{
ffffffffc020184a:	e822                	sd	s0,16(sp)
ffffffffc020184c:	ec06                	sd	ra,24(sp)
ffffffffc020184e:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201850:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201854:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201856:	04a7f963          	bgeu	a5,a0,ffffffffc02018a8 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc020185a:	4561                	li	a0,24
ffffffffc020185c:	ed3ff0ef          	jal	ra,ffffffffc020172e <slob_alloc.constprop.0>
ffffffffc0201860:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201862:	c929                	beqz	a0,ffffffffc02018b4 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201864:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201868:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc020186a:	00f95763          	bge	s2,a5,ffffffffc0201878 <kmalloc+0x34>
ffffffffc020186e:	6705                	lui	a4,0x1
ffffffffc0201870:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201872:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201874:	fef74ee3          	blt	a4,a5,ffffffffc0201870 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201878:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc020187a:	e51ff0ef          	jal	ra,ffffffffc02016ca <__slob_get_free_pages.constprop.0>
ffffffffc020187e:	e488                	sd	a0,8(s1)
ffffffffc0201880:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201882:	c525                	beqz	a0,ffffffffc02018ea <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201884:	100027f3          	csrr	a5,sstatus
ffffffffc0201888:	8b89                	andi	a5,a5,2
ffffffffc020188a:	ef8d                	bnez	a5,ffffffffc02018c4 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc020188c:	00014797          	auipc	a5,0x14
ffffffffc0201890:	cc478793          	addi	a5,a5,-828 # ffffffffc0215550 <bigblocks>
ffffffffc0201894:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201896:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201898:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc020189a:	60e2                	ld	ra,24(sp)
ffffffffc020189c:	8522                	mv	a0,s0
ffffffffc020189e:	6442                	ld	s0,16(sp)
ffffffffc02018a0:	64a2                	ld	s1,8(sp)
ffffffffc02018a2:	6902                	ld	s2,0(sp)
ffffffffc02018a4:	6105                	addi	sp,sp,32
ffffffffc02018a6:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc02018a8:	0541                	addi	a0,a0,16
ffffffffc02018aa:	e85ff0ef          	jal	ra,ffffffffc020172e <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc02018ae:	01050413          	addi	s0,a0,16
ffffffffc02018b2:	f565                	bnez	a0,ffffffffc020189a <kmalloc+0x56>
ffffffffc02018b4:	4401                	li	s0,0
}
ffffffffc02018b6:	60e2                	ld	ra,24(sp)
ffffffffc02018b8:	8522                	mv	a0,s0
ffffffffc02018ba:	6442                	ld	s0,16(sp)
ffffffffc02018bc:	64a2                	ld	s1,8(sp)
ffffffffc02018be:	6902                	ld	s2,0(sp)
ffffffffc02018c0:	6105                	addi	sp,sp,32
ffffffffc02018c2:	8082                	ret
        intr_disable();
ffffffffc02018c4:	cfffe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
		bb->next = bigblocks;
ffffffffc02018c8:	00014797          	auipc	a5,0x14
ffffffffc02018cc:	c8878793          	addi	a5,a5,-888 # ffffffffc0215550 <bigblocks>
ffffffffc02018d0:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02018d2:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02018d4:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc02018d6:	ce7fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
		return bb->pages;
ffffffffc02018da:	6480                	ld	s0,8(s1)
}
ffffffffc02018dc:	60e2                	ld	ra,24(sp)
ffffffffc02018de:	64a2                	ld	s1,8(sp)
ffffffffc02018e0:	8522                	mv	a0,s0
ffffffffc02018e2:	6442                	ld	s0,16(sp)
ffffffffc02018e4:	6902                	ld	s2,0(sp)
ffffffffc02018e6:	6105                	addi	sp,sp,32
ffffffffc02018e8:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02018ea:	45e1                	li	a1,24
ffffffffc02018ec:	8526                	mv	a0,s1
ffffffffc02018ee:	d29ff0ef          	jal	ra,ffffffffc0201616 <slob_free>
  return __kmalloc(size, 0);
ffffffffc02018f2:	b765                	j	ffffffffc020189a <kmalloc+0x56>

ffffffffc02018f4 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc02018f4:	c169                	beqz	a0,ffffffffc02019b6 <kfree+0xc2>
{
ffffffffc02018f6:	1101                	addi	sp,sp,-32
ffffffffc02018f8:	e822                	sd	s0,16(sp)
ffffffffc02018fa:	ec06                	sd	ra,24(sp)
ffffffffc02018fc:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc02018fe:	03451793          	slli	a5,a0,0x34
ffffffffc0201902:	842a                	mv	s0,a0
ffffffffc0201904:	e3d9                	bnez	a5,ffffffffc020198a <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201906:	100027f3          	csrr	a5,sstatus
ffffffffc020190a:	8b89                	andi	a5,a5,2
ffffffffc020190c:	e7d9                	bnez	a5,ffffffffc020199a <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020190e:	00014797          	auipc	a5,0x14
ffffffffc0201912:	c427b783          	ld	a5,-958(a5) # ffffffffc0215550 <bigblocks>
    return 0;
ffffffffc0201916:	4601                	li	a2,0
ffffffffc0201918:	cbad                	beqz	a5,ffffffffc020198a <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc020191a:	00014697          	auipc	a3,0x14
ffffffffc020191e:	c3668693          	addi	a3,a3,-970 # ffffffffc0215550 <bigblocks>
ffffffffc0201922:	a021                	j	ffffffffc020192a <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201924:	01048693          	addi	a3,s1,16
ffffffffc0201928:	c3a5                	beqz	a5,ffffffffc0201988 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc020192a:	6798                	ld	a4,8(a5)
ffffffffc020192c:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc020192e:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201930:	fe871ae3          	bne	a4,s0,ffffffffc0201924 <kfree+0x30>
				*last = bb->next;
ffffffffc0201934:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201936:	ee2d                	bnez	a2,ffffffffc02019b0 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201938:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc020193c:	4098                	lw	a4,0(s1)
ffffffffc020193e:	08f46963          	bltu	s0,a5,ffffffffc02019d0 <kfree+0xdc>
ffffffffc0201942:	00014697          	auipc	a3,0x14
ffffffffc0201946:	c3e6b683          	ld	a3,-962(a3) # ffffffffc0215580 <va_pa_offset>
ffffffffc020194a:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc020194c:	8031                	srli	s0,s0,0xc
ffffffffc020194e:	00014797          	auipc	a5,0x14
ffffffffc0201952:	c1a7b783          	ld	a5,-998(a5) # ffffffffc0215568 <npage>
ffffffffc0201956:	06f47163          	bgeu	s0,a5,ffffffffc02019b8 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc020195a:	00005517          	auipc	a0,0x5
ffffffffc020195e:	58e53503          	ld	a0,1422(a0) # ffffffffc0206ee8 <nbase>
ffffffffc0201962:	8c09                	sub	s0,s0,a0
ffffffffc0201964:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201966:	00014517          	auipc	a0,0x14
ffffffffc020196a:	c0a53503          	ld	a0,-1014(a0) # ffffffffc0215570 <pages>
ffffffffc020196e:	4585                	li	a1,1
ffffffffc0201970:	9522                	add	a0,a0,s0
ffffffffc0201972:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201976:	13e000ef          	jal	ra,ffffffffc0201ab4 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc020197a:	6442                	ld	s0,16(sp)
ffffffffc020197c:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020197e:	8526                	mv	a0,s1
}
ffffffffc0201980:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201982:	45e1                	li	a1,24
}
ffffffffc0201984:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201986:	b941                	j	ffffffffc0201616 <slob_free>
ffffffffc0201988:	e20d                	bnez	a2,ffffffffc02019aa <kfree+0xb6>
ffffffffc020198a:	ff040513          	addi	a0,s0,-16
}
ffffffffc020198e:	6442                	ld	s0,16(sp)
ffffffffc0201990:	60e2                	ld	ra,24(sp)
ffffffffc0201992:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201994:	4581                	li	a1,0
}
ffffffffc0201996:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201998:	b9bd                	j	ffffffffc0201616 <slob_free>
        intr_disable();
ffffffffc020199a:	c29fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020199e:	00014797          	auipc	a5,0x14
ffffffffc02019a2:	bb27b783          	ld	a5,-1102(a5) # ffffffffc0215550 <bigblocks>
        return 1;
ffffffffc02019a6:	4605                	li	a2,1
ffffffffc02019a8:	fbad                	bnez	a5,ffffffffc020191a <kfree+0x26>
        intr_enable();
ffffffffc02019aa:	c13fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02019ae:	bff1                	j	ffffffffc020198a <kfree+0x96>
ffffffffc02019b0:	c0dfe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02019b4:	b751                	j	ffffffffc0201938 <kfree+0x44>
ffffffffc02019b6:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02019b8:	00004617          	auipc	a2,0x4
ffffffffc02019bc:	2e060613          	addi	a2,a2,736 # ffffffffc0205c98 <default_pmm_manager+0x108>
ffffffffc02019c0:	06200593          	li	a1,98
ffffffffc02019c4:	00004517          	auipc	a0,0x4
ffffffffc02019c8:	22c50513          	addi	a0,a0,556 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc02019cc:	a7bfe0ef          	jal	ra,ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02019d0:	86a2                	mv	a3,s0
ffffffffc02019d2:	00004617          	auipc	a2,0x4
ffffffffc02019d6:	29e60613          	addi	a2,a2,670 # ffffffffc0205c70 <default_pmm_manager+0xe0>
ffffffffc02019da:	06e00593          	li	a1,110
ffffffffc02019de:	00004517          	auipc	a0,0x4
ffffffffc02019e2:	21250513          	addi	a0,a0,530 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc02019e6:	a61fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc02019ea <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02019ea:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02019ec:	00004617          	auipc	a2,0x4
ffffffffc02019f0:	2ac60613          	addi	a2,a2,684 # ffffffffc0205c98 <default_pmm_manager+0x108>
ffffffffc02019f4:	06200593          	li	a1,98
ffffffffc02019f8:	00004517          	auipc	a0,0x4
ffffffffc02019fc:	1f850513          	addi	a0,a0,504 # ffffffffc0205bf0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc0201a00:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201a02:	a45fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201a06 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0201a06:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201a08:	00004617          	auipc	a2,0x4
ffffffffc0201a0c:	2b060613          	addi	a2,a2,688 # ffffffffc0205cb8 <default_pmm_manager+0x128>
ffffffffc0201a10:	07400593          	li	a1,116
ffffffffc0201a14:	00004517          	auipc	a0,0x4
ffffffffc0201a18:	1dc50513          	addi	a0,a0,476 # ffffffffc0205bf0 <default_pmm_manager+0x60>
pte2page(pte_t pte) {
ffffffffc0201a1c:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201a1e:	a29fe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201a22 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201a22:	7139                	addi	sp,sp,-64
ffffffffc0201a24:	f426                	sd	s1,40(sp)
ffffffffc0201a26:	f04a                	sd	s2,32(sp)
ffffffffc0201a28:	ec4e                	sd	s3,24(sp)
ffffffffc0201a2a:	e852                	sd	s4,16(sp)
ffffffffc0201a2c:	e456                	sd	s5,8(sp)
ffffffffc0201a2e:	e05a                	sd	s6,0(sp)
ffffffffc0201a30:	fc06                	sd	ra,56(sp)
ffffffffc0201a32:	f822                	sd	s0,48(sp)
ffffffffc0201a34:	84aa                	mv	s1,a0
ffffffffc0201a36:	00014917          	auipc	s2,0x14
ffffffffc0201a3a:	b4290913          	addi	s2,s2,-1214 # ffffffffc0215578 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a3e:	4a05                	li	s4,1
ffffffffc0201a40:	00014a97          	auipc	s5,0x14
ffffffffc0201a44:	b58a8a93          	addi	s5,s5,-1192 # ffffffffc0215598 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a48:	0005099b          	sext.w	s3,a0
ffffffffc0201a4c:	00014b17          	auipc	s6,0x14
ffffffffc0201a50:	b54b0b13          	addi	s6,s6,-1196 # ffffffffc02155a0 <check_mm_struct>
ffffffffc0201a54:	a01d                	j	ffffffffc0201a7a <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201a56:	00093783          	ld	a5,0(s2)
ffffffffc0201a5a:	6f9c                	ld	a5,24(a5)
ffffffffc0201a5c:	9782                	jalr	a5
ffffffffc0201a5e:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a60:	4601                	li	a2,0
ffffffffc0201a62:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a64:	ec0d                	bnez	s0,ffffffffc0201a9e <alloc_pages+0x7c>
ffffffffc0201a66:	029a6c63          	bltu	s4,s1,ffffffffc0201a9e <alloc_pages+0x7c>
ffffffffc0201a6a:	000aa783          	lw	a5,0(s5)
ffffffffc0201a6e:	2781                	sext.w	a5,a5
ffffffffc0201a70:	c79d                	beqz	a5,ffffffffc0201a9e <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a72:	000b3503          	ld	a0,0(s6)
ffffffffc0201a76:	037010ef          	jal	ra,ffffffffc02032ac <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a7a:	100027f3          	csrr	a5,sstatus
ffffffffc0201a7e:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201a80:	8526                	mv	a0,s1
ffffffffc0201a82:	dbf1                	beqz	a5,ffffffffc0201a56 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201a84:	b3ffe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc0201a88:	00093783          	ld	a5,0(s2)
ffffffffc0201a8c:	8526                	mv	a0,s1
ffffffffc0201a8e:	6f9c                	ld	a5,24(a5)
ffffffffc0201a90:	9782                	jalr	a5
ffffffffc0201a92:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201a94:	b29fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a98:	4601                	li	a2,0
ffffffffc0201a9a:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a9c:	d469                	beqz	s0,ffffffffc0201a66 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201a9e:	70e2                	ld	ra,56(sp)
ffffffffc0201aa0:	8522                	mv	a0,s0
ffffffffc0201aa2:	7442                	ld	s0,48(sp)
ffffffffc0201aa4:	74a2                	ld	s1,40(sp)
ffffffffc0201aa6:	7902                	ld	s2,32(sp)
ffffffffc0201aa8:	69e2                	ld	s3,24(sp)
ffffffffc0201aaa:	6a42                	ld	s4,16(sp)
ffffffffc0201aac:	6aa2                	ld	s5,8(sp)
ffffffffc0201aae:	6b02                	ld	s6,0(sp)
ffffffffc0201ab0:	6121                	addi	sp,sp,64
ffffffffc0201ab2:	8082                	ret

ffffffffc0201ab4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ab4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ab8:	8b89                	andi	a5,a5,2
ffffffffc0201aba:	e799                	bnez	a5,ffffffffc0201ac8 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201abc:	00014797          	auipc	a5,0x14
ffffffffc0201ac0:	abc7b783          	ld	a5,-1348(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201ac4:	739c                	ld	a5,32(a5)
ffffffffc0201ac6:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201ac8:	1101                	addi	sp,sp,-32
ffffffffc0201aca:	ec06                	sd	ra,24(sp)
ffffffffc0201acc:	e822                	sd	s0,16(sp)
ffffffffc0201ace:	e426                	sd	s1,8(sp)
ffffffffc0201ad0:	842a                	mv	s0,a0
ffffffffc0201ad2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ad4:	aeffe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ad8:	00014797          	auipc	a5,0x14
ffffffffc0201adc:	aa07b783          	ld	a5,-1376(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201ae0:	739c                	ld	a5,32(a5)
ffffffffc0201ae2:	85a6                	mv	a1,s1
ffffffffc0201ae4:	8522                	mv	a0,s0
ffffffffc0201ae6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ae8:	6442                	ld	s0,16(sp)
ffffffffc0201aea:	60e2                	ld	ra,24(sp)
ffffffffc0201aec:	64a2                	ld	s1,8(sp)
ffffffffc0201aee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201af0:	acdfe06f          	j	ffffffffc02005bc <intr_enable>

ffffffffc0201af4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201af4:	100027f3          	csrr	a5,sstatus
ffffffffc0201af8:	8b89                	andi	a5,a5,2
ffffffffc0201afa:	e799                	bnez	a5,ffffffffc0201b08 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201afc:	00014797          	auipc	a5,0x14
ffffffffc0201b00:	a7c7b783          	ld	a5,-1412(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201b04:	779c                	ld	a5,40(a5)
ffffffffc0201b06:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201b08:	1141                	addi	sp,sp,-16
ffffffffc0201b0a:	e406                	sd	ra,8(sp)
ffffffffc0201b0c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201b0e:	ab5fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201b12:	00014797          	auipc	a5,0x14
ffffffffc0201b16:	a667b783          	ld	a5,-1434(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201b1a:	779c                	ld	a5,40(a5)
ffffffffc0201b1c:	9782                	jalr	a5
ffffffffc0201b1e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201b20:	a9dfe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201b24:	60a2                	ld	ra,8(sp)
ffffffffc0201b26:	8522                	mv	a0,s0
ffffffffc0201b28:	6402                	ld	s0,0(sp)
ffffffffc0201b2a:	0141                	addi	sp,sp,16
ffffffffc0201b2c:	8082                	ret

ffffffffc0201b2e <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b2e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201b32:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b36:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b38:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b3a:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b3c:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b40:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b42:	f04a                	sd	s2,32(sp)
ffffffffc0201b44:	ec4e                	sd	s3,24(sp)
ffffffffc0201b46:	e852                	sd	s4,16(sp)
ffffffffc0201b48:	fc06                	sd	ra,56(sp)
ffffffffc0201b4a:	f822                	sd	s0,48(sp)
ffffffffc0201b4c:	e456                	sd	s5,8(sp)
ffffffffc0201b4e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b50:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b54:	892e                	mv	s2,a1
ffffffffc0201b56:	89b2                	mv	s3,a2
ffffffffc0201b58:	00014a17          	auipc	s4,0x14
ffffffffc0201b5c:	a10a0a13          	addi	s4,s4,-1520 # ffffffffc0215568 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b60:	e7b5                	bnez	a5,ffffffffc0201bcc <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201b62:	12060b63          	beqz	a2,ffffffffc0201c98 <get_pte+0x16a>
ffffffffc0201b66:	4505                	li	a0,1
ffffffffc0201b68:	ebbff0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0201b6c:	842a                	mv	s0,a0
ffffffffc0201b6e:	12050563          	beqz	a0,ffffffffc0201c98 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201b72:	00014b17          	auipc	s6,0x14
ffffffffc0201b76:	9feb0b13          	addi	s6,s6,-1538 # ffffffffc0215570 <pages>
ffffffffc0201b7a:	000b3503          	ld	a0,0(s6)
ffffffffc0201b7e:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201b82:	00014a17          	auipc	s4,0x14
ffffffffc0201b86:	9e6a0a13          	addi	s4,s4,-1562 # ffffffffc0215568 <npage>
ffffffffc0201b8a:	40a40533          	sub	a0,s0,a0
ffffffffc0201b8e:	8519                	srai	a0,a0,0x6
ffffffffc0201b90:	9556                	add	a0,a0,s5
ffffffffc0201b92:	000a3703          	ld	a4,0(s4)
ffffffffc0201b96:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201b9a:	4685                	li	a3,1
ffffffffc0201b9c:	c014                	sw	a3,0(s0)
ffffffffc0201b9e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ba0:	0532                	slli	a0,a0,0xc
ffffffffc0201ba2:	14e7f263          	bgeu	a5,a4,ffffffffc0201ce6 <get_pte+0x1b8>
ffffffffc0201ba6:	00014797          	auipc	a5,0x14
ffffffffc0201baa:	9da7b783          	ld	a5,-1574(a5) # ffffffffc0215580 <va_pa_offset>
ffffffffc0201bae:	6605                	lui	a2,0x1
ffffffffc0201bb0:	4581                	li	a1,0
ffffffffc0201bb2:	953e                	add	a0,a0,a5
ffffffffc0201bb4:	23a030ef          	jal	ra,ffffffffc0204dee <memset>
    return page - pages + nbase;
ffffffffc0201bb8:	000b3683          	ld	a3,0(s6)
ffffffffc0201bbc:	40d406b3          	sub	a3,s0,a3
ffffffffc0201bc0:	8699                	srai	a3,a3,0x6
ffffffffc0201bc2:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201bc4:	06aa                	slli	a3,a3,0xa
ffffffffc0201bc6:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201bca:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201bcc:	77fd                	lui	a5,0xfffff
ffffffffc0201bce:	068a                	slli	a3,a3,0x2
ffffffffc0201bd0:	000a3703          	ld	a4,0(s4)
ffffffffc0201bd4:	8efd                	and	a3,a3,a5
ffffffffc0201bd6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201bda:	0ce7f163          	bgeu	a5,a4,ffffffffc0201c9c <get_pte+0x16e>
ffffffffc0201bde:	00014a97          	auipc	s5,0x14
ffffffffc0201be2:	9a2a8a93          	addi	s5,s5,-1630 # ffffffffc0215580 <va_pa_offset>
ffffffffc0201be6:	000ab403          	ld	s0,0(s5)
ffffffffc0201bea:	01595793          	srli	a5,s2,0x15
ffffffffc0201bee:	1ff7f793          	andi	a5,a5,511
ffffffffc0201bf2:	96a2                	add	a3,a3,s0
ffffffffc0201bf4:	00379413          	slli	s0,a5,0x3
ffffffffc0201bf8:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201bfa:	6014                	ld	a3,0(s0)
ffffffffc0201bfc:	0016f793          	andi	a5,a3,1
ffffffffc0201c00:	e3ad                	bnez	a5,ffffffffc0201c62 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201c02:	08098b63          	beqz	s3,ffffffffc0201c98 <get_pte+0x16a>
ffffffffc0201c06:	4505                	li	a0,1
ffffffffc0201c08:	e1bff0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0201c0c:	84aa                	mv	s1,a0
ffffffffc0201c0e:	c549                	beqz	a0,ffffffffc0201c98 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201c10:	00014b17          	auipc	s6,0x14
ffffffffc0201c14:	960b0b13          	addi	s6,s6,-1696 # ffffffffc0215570 <pages>
ffffffffc0201c18:	000b3503          	ld	a0,0(s6)
ffffffffc0201c1c:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201c20:	000a3703          	ld	a4,0(s4)
ffffffffc0201c24:	40a48533          	sub	a0,s1,a0
ffffffffc0201c28:	8519                	srai	a0,a0,0x6
ffffffffc0201c2a:	954e                	add	a0,a0,s3
ffffffffc0201c2c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201c30:	4685                	li	a3,1
ffffffffc0201c32:	c094                	sw	a3,0(s1)
ffffffffc0201c34:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c36:	0532                	slli	a0,a0,0xc
ffffffffc0201c38:	08e7fa63          	bgeu	a5,a4,ffffffffc0201ccc <get_pte+0x19e>
ffffffffc0201c3c:	000ab783          	ld	a5,0(s5)
ffffffffc0201c40:	6605                	lui	a2,0x1
ffffffffc0201c42:	4581                	li	a1,0
ffffffffc0201c44:	953e                	add	a0,a0,a5
ffffffffc0201c46:	1a8030ef          	jal	ra,ffffffffc0204dee <memset>
    return page - pages + nbase;
ffffffffc0201c4a:	000b3683          	ld	a3,0(s6)
ffffffffc0201c4e:	40d486b3          	sub	a3,s1,a3
ffffffffc0201c52:	8699                	srai	a3,a3,0x6
ffffffffc0201c54:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201c56:	06aa                	slli	a3,a3,0xa
ffffffffc0201c58:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201c5c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201c5e:	000a3703          	ld	a4,0(s4)
ffffffffc0201c62:	068a                	slli	a3,a3,0x2
ffffffffc0201c64:	757d                	lui	a0,0xfffff
ffffffffc0201c66:	8ee9                	and	a3,a3,a0
ffffffffc0201c68:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201c6c:	04e7f463          	bgeu	a5,a4,ffffffffc0201cb4 <get_pte+0x186>
ffffffffc0201c70:	000ab503          	ld	a0,0(s5)
ffffffffc0201c74:	00c95913          	srli	s2,s2,0xc
ffffffffc0201c78:	1ff97913          	andi	s2,s2,511
ffffffffc0201c7c:	96aa                	add	a3,a3,a0
ffffffffc0201c7e:	00391513          	slli	a0,s2,0x3
ffffffffc0201c82:	9536                	add	a0,a0,a3
}
ffffffffc0201c84:	70e2                	ld	ra,56(sp)
ffffffffc0201c86:	7442                	ld	s0,48(sp)
ffffffffc0201c88:	74a2                	ld	s1,40(sp)
ffffffffc0201c8a:	7902                	ld	s2,32(sp)
ffffffffc0201c8c:	69e2                	ld	s3,24(sp)
ffffffffc0201c8e:	6a42                	ld	s4,16(sp)
ffffffffc0201c90:	6aa2                	ld	s5,8(sp)
ffffffffc0201c92:	6b02                	ld	s6,0(sp)
ffffffffc0201c94:	6121                	addi	sp,sp,64
ffffffffc0201c96:	8082                	ret
            return NULL;
ffffffffc0201c98:	4501                	li	a0,0
ffffffffc0201c9a:	b7ed                	j	ffffffffc0201c84 <get_pte+0x156>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201c9c:	00004617          	auipc	a2,0x4
ffffffffc0201ca0:	f2c60613          	addi	a2,a2,-212 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0201ca4:	0e400593          	li	a1,228
ffffffffc0201ca8:	00004517          	auipc	a0,0x4
ffffffffc0201cac:	03850513          	addi	a0,a0,56 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0201cb0:	f96fe0ef          	jal	ra,ffffffffc0200446 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201cb4:	00004617          	auipc	a2,0x4
ffffffffc0201cb8:	f1460613          	addi	a2,a2,-236 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0201cbc:	0ef00593          	li	a1,239
ffffffffc0201cc0:	00004517          	auipc	a0,0x4
ffffffffc0201cc4:	02050513          	addi	a0,a0,32 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0201cc8:	f7efe0ef          	jal	ra,ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ccc:	86aa                	mv	a3,a0
ffffffffc0201cce:	00004617          	auipc	a2,0x4
ffffffffc0201cd2:	efa60613          	addi	a2,a2,-262 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0201cd6:	0ec00593          	li	a1,236
ffffffffc0201cda:	00004517          	auipc	a0,0x4
ffffffffc0201cde:	00650513          	addi	a0,a0,6 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0201ce2:	f64fe0ef          	jal	ra,ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ce6:	86aa                	mv	a3,a0
ffffffffc0201ce8:	00004617          	auipc	a2,0x4
ffffffffc0201cec:	ee060613          	addi	a2,a2,-288 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0201cf0:	0e100593          	li	a1,225
ffffffffc0201cf4:	00004517          	auipc	a0,0x4
ffffffffc0201cf8:	fec50513          	addi	a0,a0,-20 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0201cfc:	f4afe0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0201d00 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201d00:	1141                	addi	sp,sp,-16
ffffffffc0201d02:	e022                	sd	s0,0(sp)
ffffffffc0201d04:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d06:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201d08:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d0a:	e25ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201d0e:	c011                	beqz	s0,ffffffffc0201d12 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201d10:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201d12:	c511                	beqz	a0,ffffffffc0201d1e <get_page+0x1e>
ffffffffc0201d14:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201d16:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201d18:	0017f713          	andi	a4,a5,1
ffffffffc0201d1c:	e709                	bnez	a4,ffffffffc0201d26 <get_page+0x26>
}
ffffffffc0201d1e:	60a2                	ld	ra,8(sp)
ffffffffc0201d20:	6402                	ld	s0,0(sp)
ffffffffc0201d22:	0141                	addi	sp,sp,16
ffffffffc0201d24:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d26:	078a                	slli	a5,a5,0x2
ffffffffc0201d28:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d2a:	00014717          	auipc	a4,0x14
ffffffffc0201d2e:	83e73703          	ld	a4,-1986(a4) # ffffffffc0215568 <npage>
ffffffffc0201d32:	00e7ff63          	bgeu	a5,a4,ffffffffc0201d50 <get_page+0x50>
ffffffffc0201d36:	60a2                	ld	ra,8(sp)
ffffffffc0201d38:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201d3a:	fff80537          	lui	a0,0xfff80
ffffffffc0201d3e:	97aa                	add	a5,a5,a0
ffffffffc0201d40:	079a                	slli	a5,a5,0x6
ffffffffc0201d42:	00014517          	auipc	a0,0x14
ffffffffc0201d46:	82e53503          	ld	a0,-2002(a0) # ffffffffc0215570 <pages>
ffffffffc0201d4a:	953e                	add	a0,a0,a5
ffffffffc0201d4c:	0141                	addi	sp,sp,16
ffffffffc0201d4e:	8082                	ret
ffffffffc0201d50:	c9bff0ef          	jal	ra,ffffffffc02019ea <pa2page.part.0>

ffffffffc0201d54 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201d54:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d56:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201d58:	ec26                	sd	s1,24(sp)
ffffffffc0201d5a:	f406                	sd	ra,40(sp)
ffffffffc0201d5c:	f022                	sd	s0,32(sp)
ffffffffc0201d5e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d60:	dcfff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
    if (ptep != NULL) {
ffffffffc0201d64:	c511                	beqz	a0,ffffffffc0201d70 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201d66:	611c                	ld	a5,0(a0)
ffffffffc0201d68:	842a                	mv	s0,a0
ffffffffc0201d6a:	0017f713          	andi	a4,a5,1
ffffffffc0201d6e:	e711                	bnez	a4,ffffffffc0201d7a <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201d70:	70a2                	ld	ra,40(sp)
ffffffffc0201d72:	7402                	ld	s0,32(sp)
ffffffffc0201d74:	64e2                	ld	s1,24(sp)
ffffffffc0201d76:	6145                	addi	sp,sp,48
ffffffffc0201d78:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d7a:	078a                	slli	a5,a5,0x2
ffffffffc0201d7c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d7e:	00013717          	auipc	a4,0x13
ffffffffc0201d82:	7ea73703          	ld	a4,2026(a4) # ffffffffc0215568 <npage>
ffffffffc0201d86:	06e7f363          	bgeu	a5,a4,ffffffffc0201dec <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d8a:	fff80537          	lui	a0,0xfff80
ffffffffc0201d8e:	97aa                	add	a5,a5,a0
ffffffffc0201d90:	079a                	slli	a5,a5,0x6
ffffffffc0201d92:	00013517          	auipc	a0,0x13
ffffffffc0201d96:	7de53503          	ld	a0,2014(a0) # ffffffffc0215570 <pages>
ffffffffc0201d9a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201d9c:	411c                	lw	a5,0(a0)
ffffffffc0201d9e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201da2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201da4:	cb11                	beqz	a4,ffffffffc0201db8 <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201da6:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201daa:	12048073          	sfence.vma	s1
}
ffffffffc0201dae:	70a2                	ld	ra,40(sp)
ffffffffc0201db0:	7402                	ld	s0,32(sp)
ffffffffc0201db2:	64e2                	ld	s1,24(sp)
ffffffffc0201db4:	6145                	addi	sp,sp,48
ffffffffc0201db6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201db8:	100027f3          	csrr	a5,sstatus
ffffffffc0201dbc:	8b89                	andi	a5,a5,2
ffffffffc0201dbe:	eb89                	bnez	a5,ffffffffc0201dd0 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201dc0:	00013797          	auipc	a5,0x13
ffffffffc0201dc4:	7b87b783          	ld	a5,1976(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201dc8:	739c                	ld	a5,32(a5)
ffffffffc0201dca:	4585                	li	a1,1
ffffffffc0201dcc:	9782                	jalr	a5
    if (flag) {
ffffffffc0201dce:	bfe1                	j	ffffffffc0201da6 <page_remove+0x52>
        intr_disable();
ffffffffc0201dd0:	e42a                	sd	a0,8(sp)
ffffffffc0201dd2:	ff0fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc0201dd6:	00013797          	auipc	a5,0x13
ffffffffc0201dda:	7a27b783          	ld	a5,1954(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201dde:	739c                	ld	a5,32(a5)
ffffffffc0201de0:	6522                	ld	a0,8(sp)
ffffffffc0201de2:	4585                	li	a1,1
ffffffffc0201de4:	9782                	jalr	a5
        intr_enable();
ffffffffc0201de6:	fd6fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0201dea:	bf75                	j	ffffffffc0201da6 <page_remove+0x52>
ffffffffc0201dec:	bffff0ef          	jal	ra,ffffffffc02019ea <pa2page.part.0>

ffffffffc0201df0 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201df0:	7139                	addi	sp,sp,-64
ffffffffc0201df2:	e852                	sd	s4,16(sp)
ffffffffc0201df4:	8a32                	mv	s4,a2
ffffffffc0201df6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201df8:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201dfa:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201dfc:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201dfe:	f426                	sd	s1,40(sp)
ffffffffc0201e00:	fc06                	sd	ra,56(sp)
ffffffffc0201e02:	f04a                	sd	s2,32(sp)
ffffffffc0201e04:	ec4e                	sd	s3,24(sp)
ffffffffc0201e06:	e456                	sd	s5,8(sp)
ffffffffc0201e08:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201e0a:	d25ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
    if (ptep == NULL) {
ffffffffc0201e0e:	c961                	beqz	a0,ffffffffc0201ede <page_insert+0xee>
    page->ref += 1;
ffffffffc0201e10:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0201e12:	611c                	ld	a5,0(a0)
ffffffffc0201e14:	89aa                	mv	s3,a0
ffffffffc0201e16:	0016871b          	addiw	a4,a3,1
ffffffffc0201e1a:	c018                	sw	a4,0(s0)
ffffffffc0201e1c:	0017f713          	andi	a4,a5,1
ffffffffc0201e20:	ef05                	bnez	a4,ffffffffc0201e58 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201e22:	00013717          	auipc	a4,0x13
ffffffffc0201e26:	74e73703          	ld	a4,1870(a4) # ffffffffc0215570 <pages>
ffffffffc0201e2a:	8c19                	sub	s0,s0,a4
ffffffffc0201e2c:	000807b7          	lui	a5,0x80
ffffffffc0201e30:	8419                	srai	s0,s0,0x6
ffffffffc0201e32:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e34:	042a                	slli	s0,s0,0xa
ffffffffc0201e36:	8cc1                	or	s1,s1,s0
ffffffffc0201e38:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201e3c:	0099b023          	sd	s1,0(s3) # 80000 <kern_entry-0xffffffffc0180000>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201e40:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201e44:	4501                	li	a0,0
}
ffffffffc0201e46:	70e2                	ld	ra,56(sp)
ffffffffc0201e48:	7442                	ld	s0,48(sp)
ffffffffc0201e4a:	74a2                	ld	s1,40(sp)
ffffffffc0201e4c:	7902                	ld	s2,32(sp)
ffffffffc0201e4e:	69e2                	ld	s3,24(sp)
ffffffffc0201e50:	6a42                	ld	s4,16(sp)
ffffffffc0201e52:	6aa2                	ld	s5,8(sp)
ffffffffc0201e54:	6121                	addi	sp,sp,64
ffffffffc0201e56:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201e58:	078a                	slli	a5,a5,0x2
ffffffffc0201e5a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e5c:	00013717          	auipc	a4,0x13
ffffffffc0201e60:	70c73703          	ld	a4,1804(a4) # ffffffffc0215568 <npage>
ffffffffc0201e64:	06e7ff63          	bgeu	a5,a4,ffffffffc0201ee2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e68:	00013a97          	auipc	s5,0x13
ffffffffc0201e6c:	708a8a93          	addi	s5,s5,1800 # ffffffffc0215570 <pages>
ffffffffc0201e70:	000ab703          	ld	a4,0(s5)
ffffffffc0201e74:	fff80937          	lui	s2,0xfff80
ffffffffc0201e78:	993e                	add	s2,s2,a5
ffffffffc0201e7a:	091a                	slli	s2,s2,0x6
ffffffffc0201e7c:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201e7e:	01240c63          	beq	s0,s2,ffffffffc0201e96 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201e82:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd6aa34>
ffffffffc0201e86:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201e8a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0201e8e:	c691                	beqz	a3,ffffffffc0201e9a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201e90:	120a0073          	sfence.vma	s4
}
ffffffffc0201e94:	bf59                	j	ffffffffc0201e2a <page_insert+0x3a>
ffffffffc0201e96:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201e98:	bf49                	j	ffffffffc0201e2a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201e9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9e:	8b89                	andi	a5,a5,2
ffffffffc0201ea0:	ef91                	bnez	a5,ffffffffc0201ebc <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0201ea2:	00013797          	auipc	a5,0x13
ffffffffc0201ea6:	6d67b783          	ld	a5,1750(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201eaa:	739c                	ld	a5,32(a5)
ffffffffc0201eac:	4585                	li	a1,1
ffffffffc0201eae:	854a                	mv	a0,s2
ffffffffc0201eb0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0201eb2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201eb6:	120a0073          	sfence.vma	s4
ffffffffc0201eba:	bf85                	j	ffffffffc0201e2a <page_insert+0x3a>
        intr_disable();
ffffffffc0201ebc:	f06fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ec0:	00013797          	auipc	a5,0x13
ffffffffc0201ec4:	6b87b783          	ld	a5,1720(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0201ec8:	739c                	ld	a5,32(a5)
ffffffffc0201eca:	4585                	li	a1,1
ffffffffc0201ecc:	854a                	mv	a0,s2
ffffffffc0201ece:	9782                	jalr	a5
        intr_enable();
ffffffffc0201ed0:	eecfe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0201ed4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201ed8:	120a0073          	sfence.vma	s4
ffffffffc0201edc:	b7b9                	j	ffffffffc0201e2a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0201ede:	5571                	li	a0,-4
ffffffffc0201ee0:	b79d                	j	ffffffffc0201e46 <page_insert+0x56>
ffffffffc0201ee2:	b09ff0ef          	jal	ra,ffffffffc02019ea <pa2page.part.0>

ffffffffc0201ee6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201ee6:	00004797          	auipc	a5,0x4
ffffffffc0201eea:	caa78793          	addi	a5,a5,-854 # ffffffffc0205b90 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201eee:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201ef0:	711d                	addi	sp,sp,-96
ffffffffc0201ef2:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201ef4:	00004517          	auipc	a0,0x4
ffffffffc0201ef8:	dfc50513          	addi	a0,a0,-516 # ffffffffc0205cf0 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc0201efc:	00013b97          	auipc	s7,0x13
ffffffffc0201f00:	67cb8b93          	addi	s7,s7,1660 # ffffffffc0215578 <pmm_manager>
void pmm_init(void) {
ffffffffc0201f04:	ec86                	sd	ra,88(sp)
ffffffffc0201f06:	e4a6                	sd	s1,72(sp)
ffffffffc0201f08:	fc4e                	sd	s3,56(sp)
ffffffffc0201f0a:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201f0c:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0201f10:	e8a2                	sd	s0,80(sp)
ffffffffc0201f12:	e0ca                	sd	s2,64(sp)
ffffffffc0201f14:	f852                	sd	s4,48(sp)
ffffffffc0201f16:	f456                	sd	s5,40(sp)
ffffffffc0201f18:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201f1a:	a66fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc0201f1e:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f22:	00013997          	auipc	s3,0x13
ffffffffc0201f26:	65e98993          	addi	s3,s3,1630 # ffffffffc0215580 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0201f2a:	00013497          	auipc	s1,0x13
ffffffffc0201f2e:	63e48493          	addi	s1,s1,1598 # ffffffffc0215568 <npage>
    pmm_manager->init();
ffffffffc0201f32:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f34:	00013b17          	auipc	s6,0x13
ffffffffc0201f38:	63cb0b13          	addi	s6,s6,1596 # ffffffffc0215570 <pages>
    pmm_manager->init();
ffffffffc0201f3c:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f3e:	57f5                	li	a5,-3
ffffffffc0201f40:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201f42:	00004517          	auipc	a0,0x4
ffffffffc0201f46:	dc650513          	addi	a0,a0,-570 # ffffffffc0205d08 <default_pmm_manager+0x178>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f4a:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc0201f4e:	a32fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201f52:	46c5                	li	a3,17
ffffffffc0201f54:	06ee                	slli	a3,a3,0x1b
ffffffffc0201f56:	40100613          	li	a2,1025
ffffffffc0201f5a:	07e005b7          	lui	a1,0x7e00
ffffffffc0201f5e:	16fd                	addi	a3,a3,-1
ffffffffc0201f60:	0656                	slli	a2,a2,0x15
ffffffffc0201f62:	00004517          	auipc	a0,0x4
ffffffffc0201f66:	dbe50513          	addi	a0,a0,-578 # ffffffffc0205d20 <default_pmm_manager+0x190>
ffffffffc0201f6a:	a16fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f6e:	777d                	lui	a4,0xfffff
ffffffffc0201f70:	00014797          	auipc	a5,0x14
ffffffffc0201f74:	65b78793          	addi	a5,a5,1627 # ffffffffc02165cb <end+0xfff>
ffffffffc0201f78:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201f7a:	00088737          	lui	a4,0x88
ffffffffc0201f7e:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f80:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201f84:	4701                	li	a4,0
ffffffffc0201f86:	4585                	li	a1,1
ffffffffc0201f88:	fff80837          	lui	a6,0xfff80
ffffffffc0201f8c:	a019                	j	ffffffffc0201f92 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0201f8e:	000b3783          	ld	a5,0(s6)
ffffffffc0201f92:	00671693          	slli	a3,a4,0x6
ffffffffc0201f96:	97b6                	add	a5,a5,a3
ffffffffc0201f98:	07a1                	addi	a5,a5,8
ffffffffc0201f9a:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201f9e:	6090                	ld	a2,0(s1)
ffffffffc0201fa0:	0705                	addi	a4,a4,1
ffffffffc0201fa2:	010607b3          	add	a5,a2,a6
ffffffffc0201fa6:	fef764e3          	bltu	a4,a5,ffffffffc0201f8e <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201faa:	000b3503          	ld	a0,0(s6)
ffffffffc0201fae:	079a                	slli	a5,a5,0x6
ffffffffc0201fb0:	c0200737          	lui	a4,0xc0200
ffffffffc0201fb4:	00f506b3          	add	a3,a0,a5
ffffffffc0201fb8:	60e6e563          	bltu	a3,a4,ffffffffc02025c2 <pmm_init+0x6dc>
ffffffffc0201fbc:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0201fc0:	4745                	li	a4,17
ffffffffc0201fc2:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201fc4:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0201fc6:	4ae6e563          	bltu	a3,a4,ffffffffc0202470 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201fca:	00004517          	auipc	a0,0x4
ffffffffc0201fce:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205d48 <default_pmm_manager+0x1b8>
ffffffffc0201fd2:	9aefe0ef          	jal	ra,ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201fd6:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201fda:	00013917          	auipc	s2,0x13
ffffffffc0201fde:	58690913          	addi	s2,s2,1414 # ffffffffc0215560 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201fe2:	7b9c                	ld	a5,48(a5)
ffffffffc0201fe4:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201fe6:	00004517          	auipc	a0,0x4
ffffffffc0201fea:	d7a50513          	addi	a0,a0,-646 # ffffffffc0205d60 <default_pmm_manager+0x1d0>
ffffffffc0201fee:	992fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201ff2:	00007697          	auipc	a3,0x7
ffffffffc0201ff6:	00e68693          	addi	a3,a3,14 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201ffa:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201ffe:	c02007b7          	lui	a5,0xc0200
ffffffffc0202002:	5cf6ec63          	bltu	a3,a5,ffffffffc02025da <pmm_init+0x6f4>
ffffffffc0202006:	0009b783          	ld	a5,0(s3)
ffffffffc020200a:	8e9d                	sub	a3,a3,a5
ffffffffc020200c:	00013797          	auipc	a5,0x13
ffffffffc0202010:	54d7b623          	sd	a3,1356(a5) # ffffffffc0215558 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202014:	100027f3          	csrr	a5,sstatus
ffffffffc0202018:	8b89                	andi	a5,a5,2
ffffffffc020201a:	48079263          	bnez	a5,ffffffffc020249e <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc020201e:	000bb783          	ld	a5,0(s7)
ffffffffc0202022:	779c                	ld	a5,40(a5)
ffffffffc0202024:	9782                	jalr	a5
ffffffffc0202026:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202028:	6098                	ld	a4,0(s1)
ffffffffc020202a:	c80007b7          	lui	a5,0xc8000
ffffffffc020202e:	83b1                	srli	a5,a5,0xc
ffffffffc0202030:	5ee7e163          	bltu	a5,a4,ffffffffc0202612 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202034:	00093503          	ld	a0,0(s2)
ffffffffc0202038:	5a050d63          	beqz	a0,ffffffffc02025f2 <pmm_init+0x70c>
ffffffffc020203c:	03451793          	slli	a5,a0,0x34
ffffffffc0202040:	5a079963          	bnez	a5,ffffffffc02025f2 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202044:	4601                	li	a2,0
ffffffffc0202046:	4581                	li	a1,0
ffffffffc0202048:	cb9ff0ef          	jal	ra,ffffffffc0201d00 <get_page>
ffffffffc020204c:	62051563          	bnez	a0,ffffffffc0202676 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0202050:	4505                	li	a0,1
ffffffffc0202052:	9d1ff0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0202056:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202058:	00093503          	ld	a0,0(s2)
ffffffffc020205c:	4681                	li	a3,0
ffffffffc020205e:	4601                	li	a2,0
ffffffffc0202060:	85d2                	mv	a1,s4
ffffffffc0202062:	d8fff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc0202066:	5e051863          	bnez	a0,ffffffffc0202656 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020206a:	00093503          	ld	a0,0(s2)
ffffffffc020206e:	4601                	li	a2,0
ffffffffc0202070:	4581                	li	a1,0
ffffffffc0202072:	abdff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc0202076:	5c050063          	beqz	a0,ffffffffc0202636 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc020207a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020207c:	0017f713          	andi	a4,a5,1
ffffffffc0202080:	5a070963          	beqz	a4,ffffffffc0202632 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0202084:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202086:	078a                	slli	a5,a5,0x2
ffffffffc0202088:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020208a:	52e7fa63          	bgeu	a5,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020208e:	000b3683          	ld	a3,0(s6)
ffffffffc0202092:	fff80637          	lui	a2,0xfff80
ffffffffc0202096:	97b2                	add	a5,a5,a2
ffffffffc0202098:	079a                	slli	a5,a5,0x6
ffffffffc020209a:	97b6                	add	a5,a5,a3
ffffffffc020209c:	10fa16e3          	bne	s4,a5,ffffffffc02029a8 <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc02020a0:	000a2683          	lw	a3,0(s4)
ffffffffc02020a4:	4785                	li	a5,1
ffffffffc02020a6:	12f69de3          	bne	a3,a5,ffffffffc02029e0 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02020aa:	00093503          	ld	a0,0(s2)
ffffffffc02020ae:	77fd                	lui	a5,0xfffff
ffffffffc02020b0:	6114                	ld	a3,0(a0)
ffffffffc02020b2:	068a                	slli	a3,a3,0x2
ffffffffc02020b4:	8efd                	and	a3,a3,a5
ffffffffc02020b6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02020ba:	10e677e3          	bgeu	a2,a4,ffffffffc02029c8 <pmm_init+0xae2>
ffffffffc02020be:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020c2:	96e2                	add	a3,a3,s8
ffffffffc02020c4:	0006ba83          	ld	s5,0(a3)
ffffffffc02020c8:	0a8a                	slli	s5,s5,0x2
ffffffffc02020ca:	00fafab3          	and	s5,s5,a5
ffffffffc02020ce:	00cad793          	srli	a5,s5,0xc
ffffffffc02020d2:	62e7f263          	bgeu	a5,a4,ffffffffc02026f6 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020d6:	4601                	li	a2,0
ffffffffc02020d8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020da:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020dc:	a53ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020e0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020e2:	5f551a63          	bne	a0,s5,ffffffffc02026d6 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc02020e6:	4505                	li	a0,1
ffffffffc02020e8:	93bff0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc02020ec:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02020ee:	00093503          	ld	a0,0(s2)
ffffffffc02020f2:	46d1                	li	a3,20
ffffffffc02020f4:	6605                	lui	a2,0x1
ffffffffc02020f6:	85d6                	mv	a1,s5
ffffffffc02020f8:	cf9ff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc02020fc:	58051d63          	bnez	a0,ffffffffc0202696 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202100:	00093503          	ld	a0,0(s2)
ffffffffc0202104:	4601                	li	a2,0
ffffffffc0202106:	6585                	lui	a1,0x1
ffffffffc0202108:	a27ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc020210c:	0e050ae3          	beqz	a0,ffffffffc0202a00 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0202110:	611c                	ld	a5,0(a0)
ffffffffc0202112:	0107f713          	andi	a4,a5,16
ffffffffc0202116:	6e070d63          	beqz	a4,ffffffffc0202810 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc020211a:	8b91                	andi	a5,a5,4
ffffffffc020211c:	6a078a63          	beqz	a5,ffffffffc02027d0 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202120:	00093503          	ld	a0,0(s2)
ffffffffc0202124:	611c                	ld	a5,0(a0)
ffffffffc0202126:	8bc1                	andi	a5,a5,16
ffffffffc0202128:	68078463          	beqz	a5,ffffffffc02027b0 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc020212c:	000aa703          	lw	a4,0(s5)
ffffffffc0202130:	4785                	li	a5,1
ffffffffc0202132:	58f71263          	bne	a4,a5,ffffffffc02026b6 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202136:	4681                	li	a3,0
ffffffffc0202138:	6605                	lui	a2,0x1
ffffffffc020213a:	85d2                	mv	a1,s4
ffffffffc020213c:	cb5ff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc0202140:	62051863          	bnez	a0,ffffffffc0202770 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc0202144:	000a2703          	lw	a4,0(s4)
ffffffffc0202148:	4789                	li	a5,2
ffffffffc020214a:	60f71363          	bne	a4,a5,ffffffffc0202750 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc020214e:	000aa783          	lw	a5,0(s5)
ffffffffc0202152:	5c079f63          	bnez	a5,ffffffffc0202730 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202156:	00093503          	ld	a0,0(s2)
ffffffffc020215a:	4601                	li	a2,0
ffffffffc020215c:	6585                	lui	a1,0x1
ffffffffc020215e:	9d1ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc0202162:	5a050763          	beqz	a0,ffffffffc0202710 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202166:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202168:	00177793          	andi	a5,a4,1
ffffffffc020216c:	4c078363          	beqz	a5,ffffffffc0202632 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0202170:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202172:	00271793          	slli	a5,a4,0x2
ffffffffc0202176:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202178:	44d7f363          	bgeu	a5,a3,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020217c:	000b3683          	ld	a3,0(s6)
ffffffffc0202180:	fff80637          	lui	a2,0xfff80
ffffffffc0202184:	97b2                	add	a5,a5,a2
ffffffffc0202186:	079a                	slli	a5,a5,0x6
ffffffffc0202188:	97b6                	add	a5,a5,a3
ffffffffc020218a:	6efa1363          	bne	s4,a5,ffffffffc0202870 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc020218e:	8b41                	andi	a4,a4,16
ffffffffc0202190:	6c071063          	bnez	a4,ffffffffc0202850 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202194:	00093503          	ld	a0,0(s2)
ffffffffc0202198:	4581                	li	a1,0
ffffffffc020219a:	bbbff0ef          	jal	ra,ffffffffc0201d54 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020219e:	000a2703          	lw	a4,0(s4)
ffffffffc02021a2:	4785                	li	a5,1
ffffffffc02021a4:	68f71663          	bne	a4,a5,ffffffffc0202830 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc02021a8:	000aa783          	lw	a5,0(s5)
ffffffffc02021ac:	74079e63          	bnez	a5,ffffffffc0202908 <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc02021b0:	00093503          	ld	a0,0(s2)
ffffffffc02021b4:	6585                	lui	a1,0x1
ffffffffc02021b6:	b9fff0ef          	jal	ra,ffffffffc0201d54 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02021ba:	000a2783          	lw	a5,0(s4)
ffffffffc02021be:	72079563          	bnez	a5,ffffffffc02028e8 <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc02021c2:	000aa783          	lw	a5,0(s5)
ffffffffc02021c6:	70079163          	bnez	a5,ffffffffc02028c8 <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02021ca:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02021ce:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021d0:	000a3683          	ld	a3,0(s4)
ffffffffc02021d4:	068a                	slli	a3,a3,0x2
ffffffffc02021d6:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021d8:	3ee6f363          	bgeu	a3,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02021dc:	fff807b7          	lui	a5,0xfff80
ffffffffc02021e0:	000b3503          	ld	a0,0(s6)
ffffffffc02021e4:	96be                	add	a3,a3,a5
ffffffffc02021e6:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02021e8:	00d507b3          	add	a5,a0,a3
ffffffffc02021ec:	4390                	lw	a2,0(a5)
ffffffffc02021ee:	4785                	li	a5,1
ffffffffc02021f0:	6af61c63          	bne	a2,a5,ffffffffc02028a8 <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc02021f4:	8699                	srai	a3,a3,0x6
ffffffffc02021f6:	000805b7          	lui	a1,0x80
ffffffffc02021fa:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02021fc:	00c69613          	slli	a2,a3,0xc
ffffffffc0202200:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202202:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202204:	68e67663          	bgeu	a2,a4,ffffffffc0202890 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202208:	0009b603          	ld	a2,0(s3)
ffffffffc020220c:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc020220e:	629c                	ld	a5,0(a3)
ffffffffc0202210:	078a                	slli	a5,a5,0x2
ffffffffc0202212:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202214:	3ae7f563          	bgeu	a5,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202218:	8f8d                	sub	a5,a5,a1
ffffffffc020221a:	079a                	slli	a5,a5,0x6
ffffffffc020221c:	953e                	add	a0,a0,a5
ffffffffc020221e:	100027f3          	csrr	a5,sstatus
ffffffffc0202222:	8b89                	andi	a5,a5,2
ffffffffc0202224:	2c079763          	bnez	a5,ffffffffc02024f2 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc0202228:	000bb783          	ld	a5,0(s7)
ffffffffc020222c:	4585                	li	a1,1
ffffffffc020222e:	739c                	ld	a5,32(a5)
ffffffffc0202230:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202232:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202236:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202238:	078a                	slli	a5,a5,0x2
ffffffffc020223a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020223c:	38e7f163          	bgeu	a5,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202240:	000b3503          	ld	a0,0(s6)
ffffffffc0202244:	fff80737          	lui	a4,0xfff80
ffffffffc0202248:	97ba                	add	a5,a5,a4
ffffffffc020224a:	079a                	slli	a5,a5,0x6
ffffffffc020224c:	953e                	add	a0,a0,a5
ffffffffc020224e:	100027f3          	csrr	a5,sstatus
ffffffffc0202252:	8b89                	andi	a5,a5,2
ffffffffc0202254:	28079363          	bnez	a5,ffffffffc02024da <pmm_init+0x5f4>
ffffffffc0202258:	000bb783          	ld	a5,0(s7)
ffffffffc020225c:	4585                	li	a1,1
ffffffffc020225e:	739c                	ld	a5,32(a5)
ffffffffc0202260:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202262:	00093783          	ld	a5,0(s2)
ffffffffc0202266:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd6aa34>
  asm volatile("sfence.vma");
ffffffffc020226a:	12000073          	sfence.vma
ffffffffc020226e:	100027f3          	csrr	a5,sstatus
ffffffffc0202272:	8b89                	andi	a5,a5,2
ffffffffc0202274:	24079963          	bnez	a5,ffffffffc02024c6 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202278:	000bb783          	ld	a5,0(s7)
ffffffffc020227c:	779c                	ld	a5,40(a5)
ffffffffc020227e:	9782                	jalr	a5
ffffffffc0202280:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202282:	71441363          	bne	s0,s4,ffffffffc0202988 <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202286:	00004517          	auipc	a0,0x4
ffffffffc020228a:	dc250513          	addi	a0,a0,-574 # ffffffffc0206048 <default_pmm_manager+0x4b8>
ffffffffc020228e:	ef3fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0202292:	100027f3          	csrr	a5,sstatus
ffffffffc0202296:	8b89                	andi	a5,a5,2
ffffffffc0202298:	20079d63          	bnez	a5,ffffffffc02024b2 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc020229c:	000bb783          	ld	a5,0(s7)
ffffffffc02022a0:	779c                	ld	a5,40(a5)
ffffffffc02022a2:	9782                	jalr	a5
ffffffffc02022a4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02022a6:	6098                	ld	a4,0(s1)
ffffffffc02022a8:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02022ac:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02022ae:	00c71793          	slli	a5,a4,0xc
ffffffffc02022b2:	6a05                	lui	s4,0x1
ffffffffc02022b4:	02f47c63          	bgeu	s0,a5,ffffffffc02022ec <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02022b8:	00c45793          	srli	a5,s0,0xc
ffffffffc02022bc:	00093503          	ld	a0,0(s2)
ffffffffc02022c0:	2ee7f263          	bgeu	a5,a4,ffffffffc02025a4 <pmm_init+0x6be>
ffffffffc02022c4:	0009b583          	ld	a1,0(s3)
ffffffffc02022c8:	4601                	li	a2,0
ffffffffc02022ca:	95a2                	add	a1,a1,s0
ffffffffc02022cc:	863ff0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc02022d0:	2a050a63          	beqz	a0,ffffffffc0202584 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02022d4:	611c                	ld	a5,0(a0)
ffffffffc02022d6:	078a                	slli	a5,a5,0x2
ffffffffc02022d8:	0157f7b3          	and	a5,a5,s5
ffffffffc02022dc:	28879463          	bne	a5,s0,ffffffffc0202564 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02022e0:	6098                	ld	a4,0(s1)
ffffffffc02022e2:	9452                	add	s0,s0,s4
ffffffffc02022e4:	00c71793          	slli	a5,a4,0xc
ffffffffc02022e8:	fcf468e3          	bltu	s0,a5,ffffffffc02022b8 <pmm_init+0x3d2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc02022ec:	00093783          	ld	a5,0(s2)
ffffffffc02022f0:	639c                	ld	a5,0(a5)
ffffffffc02022f2:	66079b63          	bnez	a5,ffffffffc0202968 <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc02022f6:	4505                	li	a0,1
ffffffffc02022f8:	f2aff0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc02022fc:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02022fe:	00093503          	ld	a0,0(s2)
ffffffffc0202302:	4699                	li	a3,6
ffffffffc0202304:	10000613          	li	a2,256
ffffffffc0202308:	85d6                	mv	a1,s5
ffffffffc020230a:	ae7ff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc020230e:	62051d63          	bnez	a0,ffffffffc0202948 <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc0202312:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fde9a34>
ffffffffc0202316:	4785                	li	a5,1
ffffffffc0202318:	60f71863          	bne	a4,a5,ffffffffc0202928 <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020231c:	00093503          	ld	a0,0(s2)
ffffffffc0202320:	6405                	lui	s0,0x1
ffffffffc0202322:	4699                	li	a3,6
ffffffffc0202324:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0202328:	85d6                	mv	a1,s5
ffffffffc020232a:	ac7ff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc020232e:	46051163          	bnez	a0,ffffffffc0202790 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc0202332:	000aa703          	lw	a4,0(s5)
ffffffffc0202336:	4789                	li	a5,2
ffffffffc0202338:	72f71463          	bne	a4,a5,ffffffffc0202a60 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020233c:	00004597          	auipc	a1,0x4
ffffffffc0202340:	e4458593          	addi	a1,a1,-444 # ffffffffc0206180 <default_pmm_manager+0x5f0>
ffffffffc0202344:	10000513          	li	a0,256
ffffffffc0202348:	261020ef          	jal	ra,ffffffffc0204da8 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020234c:	10040593          	addi	a1,s0,256
ffffffffc0202350:	10000513          	li	a0,256
ffffffffc0202354:	267020ef          	jal	ra,ffffffffc0204dba <strcmp>
ffffffffc0202358:	6e051463          	bnez	a0,ffffffffc0202a40 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc020235c:	000b3683          	ld	a3,0(s6)
ffffffffc0202360:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202364:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202366:	40da86b3          	sub	a3,s5,a3
ffffffffc020236a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020236c:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc020236e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202370:	8031                	srli	s0,s0,0xc
ffffffffc0202372:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202376:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202378:	50f77c63          	bgeu	a4,a5,ffffffffc0202890 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020237c:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202380:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202384:	96be                	add	a3,a3,a5
ffffffffc0202386:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020238a:	1e9020ef          	jal	ra,ffffffffc0204d72 <strlen>
ffffffffc020238e:	68051963          	bnez	a0,ffffffffc0202a20 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202392:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202396:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202398:	000a3683          	ld	a3,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020239c:	068a                	slli	a3,a3,0x2
ffffffffc020239e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023a0:	20f6ff63          	bgeu	a3,a5,ffffffffc02025be <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc02023a4:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02023a6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023a8:	4ef47463          	bgeu	s0,a5,ffffffffc0202890 <pmm_init+0x9aa>
ffffffffc02023ac:	0009b403          	ld	s0,0(s3)
ffffffffc02023b0:	9436                	add	s0,s0,a3
ffffffffc02023b2:	100027f3          	csrr	a5,sstatus
ffffffffc02023b6:	8b89                	andi	a5,a5,2
ffffffffc02023b8:	18079b63          	bnez	a5,ffffffffc020254e <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc02023bc:	000bb783          	ld	a5,0(s7)
ffffffffc02023c0:	4585                	li	a1,1
ffffffffc02023c2:	8556                	mv	a0,s5
ffffffffc02023c4:	739c                	ld	a5,32(a5)
ffffffffc02023c6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02023c8:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02023ca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023cc:	078a                	slli	a5,a5,0x2
ffffffffc02023ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023d0:	1ee7f763          	bgeu	a5,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02023d4:	000b3503          	ld	a0,0(s6)
ffffffffc02023d8:	fff80737          	lui	a4,0xfff80
ffffffffc02023dc:	97ba                	add	a5,a5,a4
ffffffffc02023de:	079a                	slli	a5,a5,0x6
ffffffffc02023e0:	953e                	add	a0,a0,a5
ffffffffc02023e2:	100027f3          	csrr	a5,sstatus
ffffffffc02023e6:	8b89                	andi	a5,a5,2
ffffffffc02023e8:	14079763          	bnez	a5,ffffffffc0202536 <pmm_init+0x650>
ffffffffc02023ec:	000bb783          	ld	a5,0(s7)
ffffffffc02023f0:	4585                	li	a1,1
ffffffffc02023f2:	739c                	ld	a5,32(a5)
ffffffffc02023f4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02023f6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02023fa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023fc:	078a                	slli	a5,a5,0x2
ffffffffc02023fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202400:	1ae7ff63          	bgeu	a5,a4,ffffffffc02025be <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202404:	000b3503          	ld	a0,0(s6)
ffffffffc0202408:	fff80737          	lui	a4,0xfff80
ffffffffc020240c:	97ba                	add	a5,a5,a4
ffffffffc020240e:	079a                	slli	a5,a5,0x6
ffffffffc0202410:	953e                	add	a0,a0,a5
ffffffffc0202412:	100027f3          	csrr	a5,sstatus
ffffffffc0202416:	8b89                	andi	a5,a5,2
ffffffffc0202418:	10079363          	bnez	a5,ffffffffc020251e <pmm_init+0x638>
ffffffffc020241c:	000bb783          	ld	a5,0(s7)
ffffffffc0202420:	4585                	li	a1,1
ffffffffc0202422:	739c                	ld	a5,32(a5)
ffffffffc0202424:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202426:	00093783          	ld	a5,0(s2)
ffffffffc020242a:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc020242e:	12000073          	sfence.vma
ffffffffc0202432:	100027f3          	csrr	a5,sstatus
ffffffffc0202436:	8b89                	andi	a5,a5,2
ffffffffc0202438:	0c079963          	bnez	a5,ffffffffc020250a <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc020243c:	000bb783          	ld	a5,0(s7)
ffffffffc0202440:	779c                	ld	a5,40(a5)
ffffffffc0202442:	9782                	jalr	a5
ffffffffc0202444:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202446:	3a8c1563          	bne	s8,s0,ffffffffc02027f0 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020244a:	00004517          	auipc	a0,0x4
ffffffffc020244e:	dae50513          	addi	a0,a0,-594 # ffffffffc02061f8 <default_pmm_manager+0x668>
ffffffffc0202452:	d2ffd0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0202456:	6446                	ld	s0,80(sp)
ffffffffc0202458:	60e6                	ld	ra,88(sp)
ffffffffc020245a:	64a6                	ld	s1,72(sp)
ffffffffc020245c:	6906                	ld	s2,64(sp)
ffffffffc020245e:	79e2                	ld	s3,56(sp)
ffffffffc0202460:	7a42                	ld	s4,48(sp)
ffffffffc0202462:	7aa2                	ld	s5,40(sp)
ffffffffc0202464:	7b02                	ld	s6,32(sp)
ffffffffc0202466:	6be2                	ld	s7,24(sp)
ffffffffc0202468:	6c42                	ld	s8,16(sp)
ffffffffc020246a:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc020246c:	bb8ff06f          	j	ffffffffc0201824 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202470:	6785                	lui	a5,0x1
ffffffffc0202472:	17fd                	addi	a5,a5,-1
ffffffffc0202474:	96be                	add	a3,a3,a5
ffffffffc0202476:	77fd                	lui	a5,0xfffff
ffffffffc0202478:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc020247a:	00c7d693          	srli	a3,a5,0xc
ffffffffc020247e:	14c6f063          	bgeu	a3,a2,ffffffffc02025be <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0202482:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202486:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202488:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc020248c:	6a10                	ld	a2,16(a2)
ffffffffc020248e:	069a                	slli	a3,a3,0x6
ffffffffc0202490:	00c7d593          	srli	a1,a5,0xc
ffffffffc0202494:	9536                	add	a0,a0,a3
ffffffffc0202496:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202498:	0009b583          	ld	a1,0(s3)
}
ffffffffc020249c:	b63d                	j	ffffffffc0201fca <pmm_init+0xe4>
        intr_disable();
ffffffffc020249e:	924fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024a2:	000bb783          	ld	a5,0(s7)
ffffffffc02024a6:	779c                	ld	a5,40(a5)
ffffffffc02024a8:	9782                	jalr	a5
ffffffffc02024aa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02024ac:	910fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02024b0:	bea5                	j	ffffffffc0202028 <pmm_init+0x142>
        intr_disable();
ffffffffc02024b2:	910fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc02024b6:	000bb783          	ld	a5,0(s7)
ffffffffc02024ba:	779c                	ld	a5,40(a5)
ffffffffc02024bc:	9782                	jalr	a5
ffffffffc02024be:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02024c0:	8fcfe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02024c4:	b3cd                	j	ffffffffc02022a6 <pmm_init+0x3c0>
        intr_disable();
ffffffffc02024c6:	8fcfe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc02024ca:	000bb783          	ld	a5,0(s7)
ffffffffc02024ce:	779c                	ld	a5,40(a5)
ffffffffc02024d0:	9782                	jalr	a5
ffffffffc02024d2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02024d4:	8e8fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02024d8:	b36d                	j	ffffffffc0202282 <pmm_init+0x39c>
ffffffffc02024da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02024dc:	8e6fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024e0:	000bb783          	ld	a5,0(s7)
ffffffffc02024e4:	6522                	ld	a0,8(sp)
ffffffffc02024e6:	4585                	li	a1,1
ffffffffc02024e8:	739c                	ld	a5,32(a5)
ffffffffc02024ea:	9782                	jalr	a5
        intr_enable();
ffffffffc02024ec:	8d0fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc02024f0:	bb8d                	j	ffffffffc0202262 <pmm_init+0x37c>
ffffffffc02024f2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02024f4:	8cefe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc02024f8:	000bb783          	ld	a5,0(s7)
ffffffffc02024fc:	6522                	ld	a0,8(sp)
ffffffffc02024fe:	4585                	li	a1,1
ffffffffc0202500:	739c                	ld	a5,32(a5)
ffffffffc0202502:	9782                	jalr	a5
        intr_enable();
ffffffffc0202504:	8b8fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0202508:	b32d                	j	ffffffffc0202232 <pmm_init+0x34c>
        intr_disable();
ffffffffc020250a:	8b8fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020250e:	000bb783          	ld	a5,0(s7)
ffffffffc0202512:	779c                	ld	a5,40(a5)
ffffffffc0202514:	9782                	jalr	a5
ffffffffc0202516:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202518:	8a4fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc020251c:	b72d                	j	ffffffffc0202446 <pmm_init+0x560>
ffffffffc020251e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202520:	8a2fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202524:	000bb783          	ld	a5,0(s7)
ffffffffc0202528:	6522                	ld	a0,8(sp)
ffffffffc020252a:	4585                	li	a1,1
ffffffffc020252c:	739c                	ld	a5,32(a5)
ffffffffc020252e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202530:	88cfe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0202534:	bdcd                	j	ffffffffc0202426 <pmm_init+0x540>
ffffffffc0202536:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202538:	88afe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc020253c:	000bb783          	ld	a5,0(s7)
ffffffffc0202540:	6522                	ld	a0,8(sp)
ffffffffc0202542:	4585                	li	a1,1
ffffffffc0202544:	739c                	ld	a5,32(a5)
ffffffffc0202546:	9782                	jalr	a5
        intr_enable();
ffffffffc0202548:	874fe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc020254c:	b56d                	j	ffffffffc02023f6 <pmm_init+0x510>
        intr_disable();
ffffffffc020254e:	874fe0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
ffffffffc0202552:	000bb783          	ld	a5,0(s7)
ffffffffc0202556:	4585                	li	a1,1
ffffffffc0202558:	8556                	mv	a0,s5
ffffffffc020255a:	739c                	ld	a5,32(a5)
ffffffffc020255c:	9782                	jalr	a5
        intr_enable();
ffffffffc020255e:	85efe0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0202562:	b59d                	j	ffffffffc02023c8 <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202564:	00004697          	auipc	a3,0x4
ffffffffc0202568:	b4468693          	addi	a3,a3,-1212 # ffffffffc02060a8 <default_pmm_manager+0x518>
ffffffffc020256c:	00003617          	auipc	a2,0x3
ffffffffc0202570:	27460613          	addi	a2,a2,628 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202574:	19e00593          	li	a1,414
ffffffffc0202578:	00003517          	auipc	a0,0x3
ffffffffc020257c:	76850513          	addi	a0,a0,1896 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202580:	ec7fd0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202584:	00004697          	auipc	a3,0x4
ffffffffc0202588:	ae468693          	addi	a3,a3,-1308 # ffffffffc0206068 <default_pmm_manager+0x4d8>
ffffffffc020258c:	00003617          	auipc	a2,0x3
ffffffffc0202590:	25460613          	addi	a2,a2,596 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202594:	19d00593          	li	a1,413
ffffffffc0202598:	00003517          	auipc	a0,0x3
ffffffffc020259c:	74850513          	addi	a0,a0,1864 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02025a0:	ea7fd0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc02025a4:	86a2                	mv	a3,s0
ffffffffc02025a6:	00003617          	auipc	a2,0x3
ffffffffc02025aa:	62260613          	addi	a2,a2,1570 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc02025ae:	19d00593          	li	a1,413
ffffffffc02025b2:	00003517          	auipc	a0,0x3
ffffffffc02025b6:	72e50513          	addi	a0,a0,1838 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02025ba:	e8dfd0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc02025be:	c2cff0ef          	jal	ra,ffffffffc02019ea <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02025c2:	00003617          	auipc	a2,0x3
ffffffffc02025c6:	6ae60613          	addi	a2,a2,1710 # ffffffffc0205c70 <default_pmm_manager+0xe0>
ffffffffc02025ca:	07f00593          	li	a1,127
ffffffffc02025ce:	00003517          	auipc	a0,0x3
ffffffffc02025d2:	71250513          	addi	a0,a0,1810 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02025d6:	e71fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02025da:	00003617          	auipc	a2,0x3
ffffffffc02025de:	69660613          	addi	a2,a2,1686 # ffffffffc0205c70 <default_pmm_manager+0xe0>
ffffffffc02025e2:	0c300593          	li	a1,195
ffffffffc02025e6:	00003517          	auipc	a0,0x3
ffffffffc02025ea:	6fa50513          	addi	a0,a0,1786 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02025ee:	e59fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02025f2:	00003697          	auipc	a3,0x3
ffffffffc02025f6:	7ae68693          	addi	a3,a3,1966 # ffffffffc0205da0 <default_pmm_manager+0x210>
ffffffffc02025fa:	00003617          	auipc	a2,0x3
ffffffffc02025fe:	1e660613          	addi	a2,a2,486 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202602:	16100593          	li	a1,353
ffffffffc0202606:	00003517          	auipc	a0,0x3
ffffffffc020260a:	6da50513          	addi	a0,a0,1754 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020260e:	e39fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202612:	00003697          	auipc	a3,0x3
ffffffffc0202616:	76e68693          	addi	a3,a3,1902 # ffffffffc0205d80 <default_pmm_manager+0x1f0>
ffffffffc020261a:	00003617          	auipc	a2,0x3
ffffffffc020261e:	1c660613          	addi	a2,a2,454 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202622:	16000593          	li	a1,352
ffffffffc0202626:	00003517          	auipc	a0,0x3
ffffffffc020262a:	6ba50513          	addi	a0,a0,1722 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020262e:	e19fd0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc0202632:	bd4ff0ef          	jal	ra,ffffffffc0201a06 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202636:	00003697          	auipc	a3,0x3
ffffffffc020263a:	7fa68693          	addi	a3,a3,2042 # ffffffffc0205e30 <default_pmm_manager+0x2a0>
ffffffffc020263e:	00003617          	auipc	a2,0x3
ffffffffc0202642:	1a260613          	addi	a2,a2,418 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202646:	16900593          	li	a1,361
ffffffffc020264a:	00003517          	auipc	a0,0x3
ffffffffc020264e:	69650513          	addi	a0,a0,1686 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202652:	df5fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202656:	00003697          	auipc	a3,0x3
ffffffffc020265a:	7aa68693          	addi	a3,a3,1962 # ffffffffc0205e00 <default_pmm_manager+0x270>
ffffffffc020265e:	00003617          	auipc	a2,0x3
ffffffffc0202662:	18260613          	addi	a2,a2,386 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202666:	16600593          	li	a1,358
ffffffffc020266a:	00003517          	auipc	a0,0x3
ffffffffc020266e:	67650513          	addi	a0,a0,1654 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202672:	dd5fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202676:	00003697          	auipc	a3,0x3
ffffffffc020267a:	76268693          	addi	a3,a3,1890 # ffffffffc0205dd8 <default_pmm_manager+0x248>
ffffffffc020267e:	00003617          	auipc	a2,0x3
ffffffffc0202682:	16260613          	addi	a2,a2,354 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202686:	16200593          	li	a1,354
ffffffffc020268a:	00003517          	auipc	a0,0x3
ffffffffc020268e:	65650513          	addi	a0,a0,1622 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202692:	db5fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202696:	00004697          	auipc	a3,0x4
ffffffffc020269a:	82268693          	addi	a3,a3,-2014 # ffffffffc0205eb8 <default_pmm_manager+0x328>
ffffffffc020269e:	00003617          	auipc	a2,0x3
ffffffffc02026a2:	14260613          	addi	a2,a2,322 # ffffffffc02057e0 <commands+0x738>
ffffffffc02026a6:	17200593          	li	a1,370
ffffffffc02026aa:	00003517          	auipc	a0,0x3
ffffffffc02026ae:	63650513          	addi	a0,a0,1590 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02026b2:	d95fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02026b6:	00004697          	auipc	a3,0x4
ffffffffc02026ba:	8a268693          	addi	a3,a3,-1886 # ffffffffc0205f58 <default_pmm_manager+0x3c8>
ffffffffc02026be:	00003617          	auipc	a2,0x3
ffffffffc02026c2:	12260613          	addi	a2,a2,290 # ffffffffc02057e0 <commands+0x738>
ffffffffc02026c6:	17700593          	li	a1,375
ffffffffc02026ca:	00003517          	auipc	a0,0x3
ffffffffc02026ce:	61650513          	addi	a0,a0,1558 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02026d2:	d75fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02026d6:	00003697          	auipc	a3,0x3
ffffffffc02026da:	7ba68693          	addi	a3,a3,1978 # ffffffffc0205e90 <default_pmm_manager+0x300>
ffffffffc02026de:	00003617          	auipc	a2,0x3
ffffffffc02026e2:	10260613          	addi	a2,a2,258 # ffffffffc02057e0 <commands+0x738>
ffffffffc02026e6:	16f00593          	li	a1,367
ffffffffc02026ea:	00003517          	auipc	a0,0x3
ffffffffc02026ee:	5f650513          	addi	a0,a0,1526 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02026f2:	d55fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02026f6:	86d6                	mv	a3,s5
ffffffffc02026f8:	00003617          	auipc	a2,0x3
ffffffffc02026fc:	4d060613          	addi	a2,a2,1232 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0202700:	16e00593          	li	a1,366
ffffffffc0202704:	00003517          	auipc	a0,0x3
ffffffffc0202708:	5dc50513          	addi	a0,a0,1500 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020270c:	d3bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202710:	00003697          	auipc	a3,0x3
ffffffffc0202714:	7e068693          	addi	a3,a3,2016 # ffffffffc0205ef0 <default_pmm_manager+0x360>
ffffffffc0202718:	00003617          	auipc	a2,0x3
ffffffffc020271c:	0c860613          	addi	a2,a2,200 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202720:	17c00593          	li	a1,380
ffffffffc0202724:	00003517          	auipc	a0,0x3
ffffffffc0202728:	5bc50513          	addi	a0,a0,1468 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020272c:	d1bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202730:	00004697          	auipc	a3,0x4
ffffffffc0202734:	88868693          	addi	a3,a3,-1912 # ffffffffc0205fb8 <default_pmm_manager+0x428>
ffffffffc0202738:	00003617          	auipc	a2,0x3
ffffffffc020273c:	0a860613          	addi	a2,a2,168 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202740:	17b00593          	li	a1,379
ffffffffc0202744:	00003517          	auipc	a0,0x3
ffffffffc0202748:	59c50513          	addi	a0,a0,1436 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020274c:	cfbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202750:	00004697          	auipc	a3,0x4
ffffffffc0202754:	85068693          	addi	a3,a3,-1968 # ffffffffc0205fa0 <default_pmm_manager+0x410>
ffffffffc0202758:	00003617          	auipc	a2,0x3
ffffffffc020275c:	08860613          	addi	a2,a2,136 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202760:	17a00593          	li	a1,378
ffffffffc0202764:	00003517          	auipc	a0,0x3
ffffffffc0202768:	57c50513          	addi	a0,a0,1404 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020276c:	cdbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202770:	00004697          	auipc	a3,0x4
ffffffffc0202774:	80068693          	addi	a3,a3,-2048 # ffffffffc0205f70 <default_pmm_manager+0x3e0>
ffffffffc0202778:	00003617          	auipc	a2,0x3
ffffffffc020277c:	06860613          	addi	a2,a2,104 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202780:	17900593          	li	a1,377
ffffffffc0202784:	00003517          	auipc	a0,0x3
ffffffffc0202788:	55c50513          	addi	a0,a0,1372 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020278c:	cbbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202790:	00004697          	auipc	a3,0x4
ffffffffc0202794:	99868693          	addi	a3,a3,-1640 # ffffffffc0206128 <default_pmm_manager+0x598>
ffffffffc0202798:	00003617          	auipc	a2,0x3
ffffffffc020279c:	04860613          	addi	a2,a2,72 # ffffffffc02057e0 <commands+0x738>
ffffffffc02027a0:	1a700593          	li	a1,423
ffffffffc02027a4:	00003517          	auipc	a0,0x3
ffffffffc02027a8:	53c50513          	addi	a0,a0,1340 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02027ac:	c9bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02027b0:	00003697          	auipc	a3,0x3
ffffffffc02027b4:	79068693          	addi	a3,a3,1936 # ffffffffc0205f40 <default_pmm_manager+0x3b0>
ffffffffc02027b8:	00003617          	auipc	a2,0x3
ffffffffc02027bc:	02860613          	addi	a2,a2,40 # ffffffffc02057e0 <commands+0x738>
ffffffffc02027c0:	17600593          	li	a1,374
ffffffffc02027c4:	00003517          	auipc	a0,0x3
ffffffffc02027c8:	51c50513          	addi	a0,a0,1308 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02027cc:	c7bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02027d0:	00003697          	auipc	a3,0x3
ffffffffc02027d4:	76068693          	addi	a3,a3,1888 # ffffffffc0205f30 <default_pmm_manager+0x3a0>
ffffffffc02027d8:	00003617          	auipc	a2,0x3
ffffffffc02027dc:	00860613          	addi	a2,a2,8 # ffffffffc02057e0 <commands+0x738>
ffffffffc02027e0:	17500593          	li	a1,373
ffffffffc02027e4:	00003517          	auipc	a0,0x3
ffffffffc02027e8:	4fc50513          	addi	a0,a0,1276 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02027ec:	c5bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02027f0:	00004697          	auipc	a3,0x4
ffffffffc02027f4:	83868693          	addi	a3,a3,-1992 # ffffffffc0206028 <default_pmm_manager+0x498>
ffffffffc02027f8:	00003617          	auipc	a2,0x3
ffffffffc02027fc:	fe860613          	addi	a2,a2,-24 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202800:	1b800593          	li	a1,440
ffffffffc0202804:	00003517          	auipc	a0,0x3
ffffffffc0202808:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020280c:	c3bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202810:	00003697          	auipc	a3,0x3
ffffffffc0202814:	71068693          	addi	a3,a3,1808 # ffffffffc0205f20 <default_pmm_manager+0x390>
ffffffffc0202818:	00003617          	auipc	a2,0x3
ffffffffc020281c:	fc860613          	addi	a2,a2,-56 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202820:	17400593          	li	a1,372
ffffffffc0202824:	00003517          	auipc	a0,0x3
ffffffffc0202828:	4bc50513          	addi	a0,a0,1212 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020282c:	c1bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202830:	00003697          	auipc	a3,0x3
ffffffffc0202834:	64868693          	addi	a3,a3,1608 # ffffffffc0205e78 <default_pmm_manager+0x2e8>
ffffffffc0202838:	00003617          	auipc	a2,0x3
ffffffffc020283c:	fa860613          	addi	a2,a2,-88 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202840:	18100593          	li	a1,385
ffffffffc0202844:	00003517          	auipc	a0,0x3
ffffffffc0202848:	49c50513          	addi	a0,a0,1180 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020284c:	bfbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202850:	00003697          	auipc	a3,0x3
ffffffffc0202854:	78068693          	addi	a3,a3,1920 # ffffffffc0205fd0 <default_pmm_manager+0x440>
ffffffffc0202858:	00003617          	auipc	a2,0x3
ffffffffc020285c:	f8860613          	addi	a2,a2,-120 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202860:	17e00593          	li	a1,382
ffffffffc0202864:	00003517          	auipc	a0,0x3
ffffffffc0202868:	47c50513          	addi	a0,a0,1148 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020286c:	bdbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202870:	00003697          	auipc	a3,0x3
ffffffffc0202874:	5f068693          	addi	a3,a3,1520 # ffffffffc0205e60 <default_pmm_manager+0x2d0>
ffffffffc0202878:	00003617          	auipc	a2,0x3
ffffffffc020287c:	f6860613          	addi	a2,a2,-152 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202880:	17d00593          	li	a1,381
ffffffffc0202884:	00003517          	auipc	a0,0x3
ffffffffc0202888:	45c50513          	addi	a0,a0,1116 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc020288c:	bbbfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202890:	00003617          	auipc	a2,0x3
ffffffffc0202894:	33860613          	addi	a2,a2,824 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0202898:	06900593          	li	a1,105
ffffffffc020289c:	00003517          	auipc	a0,0x3
ffffffffc02028a0:	35450513          	addi	a0,a0,852 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc02028a4:	ba3fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02028a8:	00003697          	auipc	a3,0x3
ffffffffc02028ac:	75868693          	addi	a3,a3,1880 # ffffffffc0206000 <default_pmm_manager+0x470>
ffffffffc02028b0:	00003617          	auipc	a2,0x3
ffffffffc02028b4:	f3060613          	addi	a2,a2,-208 # ffffffffc02057e0 <commands+0x738>
ffffffffc02028b8:	18800593          	li	a1,392
ffffffffc02028bc:	00003517          	auipc	a0,0x3
ffffffffc02028c0:	42450513          	addi	a0,a0,1060 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02028c4:	b83fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02028c8:	00003697          	auipc	a3,0x3
ffffffffc02028cc:	6f068693          	addi	a3,a3,1776 # ffffffffc0205fb8 <default_pmm_manager+0x428>
ffffffffc02028d0:	00003617          	auipc	a2,0x3
ffffffffc02028d4:	f1060613          	addi	a2,a2,-240 # ffffffffc02057e0 <commands+0x738>
ffffffffc02028d8:	18600593          	li	a1,390
ffffffffc02028dc:	00003517          	auipc	a0,0x3
ffffffffc02028e0:	40450513          	addi	a0,a0,1028 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02028e4:	b63fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02028e8:	00003697          	auipc	a3,0x3
ffffffffc02028ec:	70068693          	addi	a3,a3,1792 # ffffffffc0205fe8 <default_pmm_manager+0x458>
ffffffffc02028f0:	00003617          	auipc	a2,0x3
ffffffffc02028f4:	ef060613          	addi	a2,a2,-272 # ffffffffc02057e0 <commands+0x738>
ffffffffc02028f8:	18500593          	li	a1,389
ffffffffc02028fc:	00003517          	auipc	a0,0x3
ffffffffc0202900:	3e450513          	addi	a0,a0,996 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202904:	b43fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202908:	00003697          	auipc	a3,0x3
ffffffffc020290c:	6b068693          	addi	a3,a3,1712 # ffffffffc0205fb8 <default_pmm_manager+0x428>
ffffffffc0202910:	00003617          	auipc	a2,0x3
ffffffffc0202914:	ed060613          	addi	a2,a2,-304 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202918:	18200593          	li	a1,386
ffffffffc020291c:	00003517          	auipc	a0,0x3
ffffffffc0202920:	3c450513          	addi	a0,a0,964 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202924:	b23fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202928:	00003697          	auipc	a3,0x3
ffffffffc020292c:	7e868693          	addi	a3,a3,2024 # ffffffffc0206110 <default_pmm_manager+0x580>
ffffffffc0202930:	00003617          	auipc	a2,0x3
ffffffffc0202934:	eb060613          	addi	a2,a2,-336 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202938:	1a600593          	li	a1,422
ffffffffc020293c:	00003517          	auipc	a0,0x3
ffffffffc0202940:	3a450513          	addi	a0,a0,932 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202944:	b03fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202948:	00003697          	auipc	a3,0x3
ffffffffc020294c:	79068693          	addi	a3,a3,1936 # ffffffffc02060d8 <default_pmm_manager+0x548>
ffffffffc0202950:	00003617          	auipc	a2,0x3
ffffffffc0202954:	e9060613          	addi	a2,a2,-368 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202958:	1a500593          	li	a1,421
ffffffffc020295c:	00003517          	auipc	a0,0x3
ffffffffc0202960:	38450513          	addi	a0,a0,900 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202964:	ae3fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202968:	00003697          	auipc	a3,0x3
ffffffffc020296c:	75868693          	addi	a3,a3,1880 # ffffffffc02060c0 <default_pmm_manager+0x530>
ffffffffc0202970:	00003617          	auipc	a2,0x3
ffffffffc0202974:	e7060613          	addi	a2,a2,-400 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202978:	1a100593          	li	a1,417
ffffffffc020297c:	00003517          	auipc	a0,0x3
ffffffffc0202980:	36450513          	addi	a0,a0,868 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202984:	ac3fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202988:	00003697          	auipc	a3,0x3
ffffffffc020298c:	6a068693          	addi	a3,a3,1696 # ffffffffc0206028 <default_pmm_manager+0x498>
ffffffffc0202990:	00003617          	auipc	a2,0x3
ffffffffc0202994:	e5060613          	addi	a2,a2,-432 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202998:	19000593          	li	a1,400
ffffffffc020299c:	00003517          	auipc	a0,0x3
ffffffffc02029a0:	34450513          	addi	a0,a0,836 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02029a4:	aa3fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02029a8:	00003697          	auipc	a3,0x3
ffffffffc02029ac:	4b868693          	addi	a3,a3,1208 # ffffffffc0205e60 <default_pmm_manager+0x2d0>
ffffffffc02029b0:	00003617          	auipc	a2,0x3
ffffffffc02029b4:	e3060613          	addi	a2,a2,-464 # ffffffffc02057e0 <commands+0x738>
ffffffffc02029b8:	16a00593          	li	a1,362
ffffffffc02029bc:	00003517          	auipc	a0,0x3
ffffffffc02029c0:	32450513          	addi	a0,a0,804 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02029c4:	a83fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02029c8:	00003617          	auipc	a2,0x3
ffffffffc02029cc:	20060613          	addi	a2,a2,512 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc02029d0:	16d00593          	li	a1,365
ffffffffc02029d4:	00003517          	auipc	a0,0x3
ffffffffc02029d8:	30c50513          	addi	a0,a0,780 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02029dc:	a6bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02029e0:	00003697          	auipc	a3,0x3
ffffffffc02029e4:	49868693          	addi	a3,a3,1176 # ffffffffc0205e78 <default_pmm_manager+0x2e8>
ffffffffc02029e8:	00003617          	auipc	a2,0x3
ffffffffc02029ec:	df860613          	addi	a2,a2,-520 # ffffffffc02057e0 <commands+0x738>
ffffffffc02029f0:	16b00593          	li	a1,363
ffffffffc02029f4:	00003517          	auipc	a0,0x3
ffffffffc02029f8:	2ec50513          	addi	a0,a0,748 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc02029fc:	a4bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202a00:	00003697          	auipc	a3,0x3
ffffffffc0202a04:	4f068693          	addi	a3,a3,1264 # ffffffffc0205ef0 <default_pmm_manager+0x360>
ffffffffc0202a08:	00003617          	auipc	a2,0x3
ffffffffc0202a0c:	dd860613          	addi	a2,a2,-552 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202a10:	17300593          	li	a1,371
ffffffffc0202a14:	00003517          	auipc	a0,0x3
ffffffffc0202a18:	2cc50513          	addi	a0,a0,716 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202a1c:	a2bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a20:	00003697          	auipc	a3,0x3
ffffffffc0202a24:	7b068693          	addi	a3,a3,1968 # ffffffffc02061d0 <default_pmm_manager+0x640>
ffffffffc0202a28:	00003617          	auipc	a2,0x3
ffffffffc0202a2c:	db860613          	addi	a2,a2,-584 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202a30:	1af00593          	li	a1,431
ffffffffc0202a34:	00003517          	auipc	a0,0x3
ffffffffc0202a38:	2ac50513          	addi	a0,a0,684 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202a3c:	a0bfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a40:	00003697          	auipc	a3,0x3
ffffffffc0202a44:	75868693          	addi	a3,a3,1880 # ffffffffc0206198 <default_pmm_manager+0x608>
ffffffffc0202a48:	00003617          	auipc	a2,0x3
ffffffffc0202a4c:	d9860613          	addi	a2,a2,-616 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202a50:	1ac00593          	li	a1,428
ffffffffc0202a54:	00003517          	auipc	a0,0x3
ffffffffc0202a58:	28c50513          	addi	a0,a0,652 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202a5c:	9ebfd0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202a60:	00003697          	auipc	a3,0x3
ffffffffc0202a64:	70868693          	addi	a3,a3,1800 # ffffffffc0206168 <default_pmm_manager+0x5d8>
ffffffffc0202a68:	00003617          	auipc	a2,0x3
ffffffffc0202a6c:	d7860613          	addi	a2,a2,-648 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202a70:	1a800593          	li	a1,424
ffffffffc0202a74:	00003517          	auipc	a0,0x3
ffffffffc0202a78:	26c50513          	addi	a0,a0,620 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202a7c:	9cbfd0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0202a80 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202a80:	12058073          	sfence.vma	a1
}
ffffffffc0202a84:	8082                	ret

ffffffffc0202a86 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202a86:	7179                	addi	sp,sp,-48
ffffffffc0202a88:	e84a                	sd	s2,16(sp)
ffffffffc0202a8a:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202a8c:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202a8e:	f022                	sd	s0,32(sp)
ffffffffc0202a90:	ec26                	sd	s1,24(sp)
ffffffffc0202a92:	e44e                	sd	s3,8(sp)
ffffffffc0202a94:	f406                	sd	ra,40(sp)
ffffffffc0202a96:	84ae                	mv	s1,a1
ffffffffc0202a98:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202a9a:	f89fe0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0202a9e:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0202aa0:	cd09                	beqz	a0,ffffffffc0202aba <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0202aa2:	85aa                	mv	a1,a0
ffffffffc0202aa4:	86ce                	mv	a3,s3
ffffffffc0202aa6:	8626                	mv	a2,s1
ffffffffc0202aa8:	854a                	mv	a0,s2
ffffffffc0202aaa:	b46ff0ef          	jal	ra,ffffffffc0201df0 <page_insert>
ffffffffc0202aae:	ed21                	bnez	a0,ffffffffc0202b06 <pgdir_alloc_page+0x80>
        if (swap_init_ok) {
ffffffffc0202ab0:	00013797          	auipc	a5,0x13
ffffffffc0202ab4:	ae87a783          	lw	a5,-1304(a5) # ffffffffc0215598 <swap_init_ok>
ffffffffc0202ab8:	eb89                	bnez	a5,ffffffffc0202aca <pgdir_alloc_page+0x44>
}
ffffffffc0202aba:	70a2                	ld	ra,40(sp)
ffffffffc0202abc:	8522                	mv	a0,s0
ffffffffc0202abe:	7402                	ld	s0,32(sp)
ffffffffc0202ac0:	64e2                	ld	s1,24(sp)
ffffffffc0202ac2:	6942                	ld	s2,16(sp)
ffffffffc0202ac4:	69a2                	ld	s3,8(sp)
ffffffffc0202ac6:	6145                	addi	sp,sp,48
ffffffffc0202ac8:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202aca:	4681                	li	a3,0
ffffffffc0202acc:	8622                	mv	a2,s0
ffffffffc0202ace:	85a6                	mv	a1,s1
ffffffffc0202ad0:	00013517          	auipc	a0,0x13
ffffffffc0202ad4:	ad053503          	ld	a0,-1328(a0) # ffffffffc02155a0 <check_mm_struct>
ffffffffc0202ad8:	7c8000ef          	jal	ra,ffffffffc02032a0 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202adc:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202ade:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0202ae0:	4785                	li	a5,1
ffffffffc0202ae2:	fcf70ce3          	beq	a4,a5,ffffffffc0202aba <pgdir_alloc_page+0x34>
ffffffffc0202ae6:	00003697          	auipc	a3,0x3
ffffffffc0202aea:	73268693          	addi	a3,a3,1842 # ffffffffc0206218 <default_pmm_manager+0x688>
ffffffffc0202aee:	00003617          	auipc	a2,0x3
ffffffffc0202af2:	cf260613          	addi	a2,a2,-782 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202af6:	14800593          	li	a1,328
ffffffffc0202afa:	00003517          	auipc	a0,0x3
ffffffffc0202afe:	1e650513          	addi	a0,a0,486 # ffffffffc0205ce0 <default_pmm_manager+0x150>
ffffffffc0202b02:	945fd0ef          	jal	ra,ffffffffc0200446 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202b06:	100027f3          	csrr	a5,sstatus
ffffffffc0202b0a:	8b89                	andi	a5,a5,2
ffffffffc0202b0c:	eb99                	bnez	a5,ffffffffc0202b22 <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n);
ffffffffc0202b0e:	00013797          	auipc	a5,0x13
ffffffffc0202b12:	a6a7b783          	ld	a5,-1430(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0202b16:	739c                	ld	a5,32(a5)
ffffffffc0202b18:	8522                	mv	a0,s0
ffffffffc0202b1a:	4585                	li	a1,1
ffffffffc0202b1c:	9782                	jalr	a5
            return NULL;
ffffffffc0202b1e:	4401                	li	s0,0
ffffffffc0202b20:	bf69                	j	ffffffffc0202aba <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc0202b22:	aa1fd0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b26:	00013797          	auipc	a5,0x13
ffffffffc0202b2a:	a527b783          	ld	a5,-1454(a5) # ffffffffc0215578 <pmm_manager>
ffffffffc0202b2e:	739c                	ld	a5,32(a5)
ffffffffc0202b30:	8522                	mv	a0,s0
ffffffffc0202b32:	4585                	li	a1,1
ffffffffc0202b34:	9782                	jalr	a5
            return NULL;
ffffffffc0202b36:	4401                	li	s0,0
        intr_enable();
ffffffffc0202b38:	a85fd0ef          	jal	ra,ffffffffc02005bc <intr_enable>
ffffffffc0202b3c:	bfbd                	j	ffffffffc0202aba <pgdir_alloc_page+0x34>

ffffffffc0202b3e <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0202b3e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202b40:	00003617          	auipc	a2,0x3
ffffffffc0202b44:	15860613          	addi	a2,a2,344 # ffffffffc0205c98 <default_pmm_manager+0x108>
ffffffffc0202b48:	06200593          	li	a1,98
ffffffffc0202b4c:	00003517          	auipc	a0,0x3
ffffffffc0202b50:	0a450513          	addi	a0,a0,164 # ffffffffc0205bf0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc0202b54:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0202b56:	8f1fd0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0202b5a <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0202b5a:	7135                	addi	sp,sp,-160
ffffffffc0202b5c:	ed06                	sd	ra,152(sp)
ffffffffc0202b5e:	e922                	sd	s0,144(sp)
ffffffffc0202b60:	e526                	sd	s1,136(sp)
ffffffffc0202b62:	e14a                	sd	s2,128(sp)
ffffffffc0202b64:	fcce                	sd	s3,120(sp)
ffffffffc0202b66:	f8d2                	sd	s4,112(sp)
ffffffffc0202b68:	f4d6                	sd	s5,104(sp)
ffffffffc0202b6a:	f0da                	sd	s6,96(sp)
ffffffffc0202b6c:	ecde                	sd	s7,88(sp)
ffffffffc0202b6e:	e8e2                	sd	s8,80(sp)
ffffffffc0202b70:	e4e6                	sd	s9,72(sp)
ffffffffc0202b72:	e0ea                	sd	s10,64(sp)
ffffffffc0202b74:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202b76:	560010ef          	jal	ra,ffffffffc02040d6 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0202b7a:	00013697          	auipc	a3,0x13
ffffffffc0202b7e:	a0e6b683          	ld	a3,-1522(a3) # ffffffffc0215588 <max_swap_offset>
ffffffffc0202b82:	010007b7          	lui	a5,0x1000
ffffffffc0202b86:	ff968713          	addi	a4,a3,-7
ffffffffc0202b8a:	17e1                	addi	a5,a5,-8
ffffffffc0202b8c:	42e7e063          	bltu	a5,a4,ffffffffc0202fac <swap_init+0x452>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo;
ffffffffc0202b90:	00007797          	auipc	a5,0x7
ffffffffc0202b94:	48078793          	addi	a5,a5,1152 # ffffffffc020a010 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0202b98:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0202b9a:	00013b97          	auipc	s7,0x13
ffffffffc0202b9e:	9f6b8b93          	addi	s7,s7,-1546 # ffffffffc0215590 <sm>
ffffffffc0202ba2:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc0202ba6:	9702                	jalr	a4
ffffffffc0202ba8:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0202baa:	c10d                	beqz	a0,ffffffffc0202bcc <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202bac:	60ea                	ld	ra,152(sp)
ffffffffc0202bae:	644a                	ld	s0,144(sp)
ffffffffc0202bb0:	64aa                	ld	s1,136(sp)
ffffffffc0202bb2:	79e6                	ld	s3,120(sp)
ffffffffc0202bb4:	7a46                	ld	s4,112(sp)
ffffffffc0202bb6:	7aa6                	ld	s5,104(sp)
ffffffffc0202bb8:	7b06                	ld	s6,96(sp)
ffffffffc0202bba:	6be6                	ld	s7,88(sp)
ffffffffc0202bbc:	6c46                	ld	s8,80(sp)
ffffffffc0202bbe:	6ca6                	ld	s9,72(sp)
ffffffffc0202bc0:	6d06                	ld	s10,64(sp)
ffffffffc0202bc2:	7de2                	ld	s11,56(sp)
ffffffffc0202bc4:	854a                	mv	a0,s2
ffffffffc0202bc6:	690a                	ld	s2,128(sp)
ffffffffc0202bc8:	610d                	addi	sp,sp,160
ffffffffc0202bca:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202bcc:	000bb783          	ld	a5,0(s7)
ffffffffc0202bd0:	00003517          	auipc	a0,0x3
ffffffffc0202bd4:	69050513          	addi	a0,a0,1680 # ffffffffc0206260 <default_pmm_manager+0x6d0>
    return listelm->next;
ffffffffc0202bd8:	0000f417          	auipc	s0,0xf
ffffffffc0202bdc:	88840413          	addi	s0,s0,-1912 # ffffffffc0211460 <free_area>
ffffffffc0202be0:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202be2:	4785                	li	a5,1
ffffffffc0202be4:	00013717          	auipc	a4,0x13
ffffffffc0202be8:	9af72a23          	sw	a5,-1612(a4) # ffffffffc0215598 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202bec:	d94fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0202bf0:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202bf2:	4d01                	li	s10,0
ffffffffc0202bf4:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202bf6:	32878b63          	beq	a5,s0,ffffffffc0202f2c <swap_init+0x3d2>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202bfa:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202bfe:	8b09                	andi	a4,a4,2
ffffffffc0202c00:	32070863          	beqz	a4,ffffffffc0202f30 <swap_init+0x3d6>
        count ++, total += p->property;
ffffffffc0202c04:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202c08:	679c                	ld	a5,8(a5)
ffffffffc0202c0a:	2d85                	addiw	s11,s11,1
ffffffffc0202c0c:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c10:	fe8795e3          	bne	a5,s0,ffffffffc0202bfa <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc0202c14:	84ea                	mv	s1,s10
ffffffffc0202c16:	edffe0ef          	jal	ra,ffffffffc0201af4 <nr_free_pages>
ffffffffc0202c1a:	42951163          	bne	a0,s1,ffffffffc020303c <swap_init+0x4e2>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202c1e:	866a                	mv	a2,s10
ffffffffc0202c20:	85ee                	mv	a1,s11
ffffffffc0202c22:	00003517          	auipc	a0,0x3
ffffffffc0202c26:	65650513          	addi	a0,a0,1622 # ffffffffc0206278 <default_pmm_manager+0x6e8>
ffffffffc0202c2a:	d56fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202c2e:	41f000ef          	jal	ra,ffffffffc020384c <mm_create>
ffffffffc0202c32:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc0202c34:	46050463          	beqz	a0,ffffffffc020309c <swap_init+0x542>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202c38:	00013797          	auipc	a5,0x13
ffffffffc0202c3c:	96878793          	addi	a5,a5,-1688 # ffffffffc02155a0 <check_mm_struct>
ffffffffc0202c40:	6398                	ld	a4,0(a5)
ffffffffc0202c42:	3c071d63          	bnez	a4,ffffffffc020301c <swap_init+0x4c2>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202c46:	00013717          	auipc	a4,0x13
ffffffffc0202c4a:	91a70713          	addi	a4,a4,-1766 # ffffffffc0215560 <boot_pgdir>
ffffffffc0202c4e:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0202c52:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0202c54:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202c58:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202c5c:	42079063          	bnez	a5,ffffffffc020307c <swap_init+0x522>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202c60:	6599                	lui	a1,0x6
ffffffffc0202c62:	460d                	li	a2,3
ffffffffc0202c64:	6505                	lui	a0,0x1
ffffffffc0202c66:	42f000ef          	jal	ra,ffffffffc0203894 <vma_create>
ffffffffc0202c6a:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202c6c:	52050463          	beqz	a0,ffffffffc0203194 <swap_init+0x63a>

     insert_vma_struct(mm, vma);
ffffffffc0202c70:	8556                	mv	a0,s5
ffffffffc0202c72:	491000ef          	jal	ra,ffffffffc0203902 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202c76:	00003517          	auipc	a0,0x3
ffffffffc0202c7a:	67250513          	addi	a0,a0,1650 # ffffffffc02062e8 <default_pmm_manager+0x758>
ffffffffc0202c7e:	d02fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202c82:	018ab503          	ld	a0,24(s5)
ffffffffc0202c86:	4605                	li	a2,1
ffffffffc0202c88:	6585                	lui	a1,0x1
ffffffffc0202c8a:	ea5fe0ef          	jal	ra,ffffffffc0201b2e <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202c8e:	4c050363          	beqz	a0,ffffffffc0203154 <swap_init+0x5fa>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202c92:	00003517          	auipc	a0,0x3
ffffffffc0202c96:	6a650513          	addi	a0,a0,1702 # ffffffffc0206338 <default_pmm_manager+0x7a8>
ffffffffc0202c9a:	0000e497          	auipc	s1,0xe
ffffffffc0202c9e:	7fe48493          	addi	s1,s1,2046 # ffffffffc0211498 <check_rp>
ffffffffc0202ca2:	cdefd0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ca6:	0000f997          	auipc	s3,0xf
ffffffffc0202caa:	81298993          	addi	s3,s3,-2030 # ffffffffc02114b8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202cae:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0202cb0:	4505                	li	a0,1
ffffffffc0202cb2:	d71fe0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
ffffffffc0202cb6:	00aa3023          	sd	a0,0(s4)
          assert(check_rp[i] != NULL );
ffffffffc0202cba:	2c050963          	beqz	a0,ffffffffc0202f8c <swap_init+0x432>
ffffffffc0202cbe:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202cc0:	8b89                	andi	a5,a5,2
ffffffffc0202cc2:	32079d63          	bnez	a5,ffffffffc0202ffc <swap_init+0x4a2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cc6:	0a21                	addi	s4,s4,8
ffffffffc0202cc8:	ff3a14e3          	bne	s4,s3,ffffffffc0202cb0 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202ccc:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202cce:	0000ea17          	auipc	s4,0xe
ffffffffc0202cd2:	7caa0a13          	addi	s4,s4,1994 # ffffffffc0211498 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0202cd6:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0202cd8:	ec3e                	sd	a5,24(sp)
ffffffffc0202cda:	641c                	ld	a5,8(s0)
ffffffffc0202cdc:	e400                	sd	s0,8(s0)
ffffffffc0202cde:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202ce0:	481c                	lw	a5,16(s0)
ffffffffc0202ce2:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0202ce4:	0000e797          	auipc	a5,0xe
ffffffffc0202ce8:	7807a623          	sw	zero,1932(a5) # ffffffffc0211470 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202cec:	000a3503          	ld	a0,0(s4)
ffffffffc0202cf0:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cf2:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0202cf4:	dc1fe0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cf8:	ff3a1ae3          	bne	s4,s3,ffffffffc0202cec <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202cfc:	01042a03          	lw	s4,16(s0)
ffffffffc0202d00:	4791                	li	a5,4
ffffffffc0202d02:	42fa1963          	bne	s4,a5,ffffffffc0203134 <swap_init+0x5da>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202d06:	00003517          	auipc	a0,0x3
ffffffffc0202d0a:	6ba50513          	addi	a0,a0,1722 # ffffffffc02063c0 <default_pmm_manager+0x830>
ffffffffc0202d0e:	c72fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202d12:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202d14:	00013797          	auipc	a5,0x13
ffffffffc0202d18:	8807aa23          	sw	zero,-1900(a5) # ffffffffc02155a8 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202d1c:	4629                	li	a2,10
ffffffffc0202d1e:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202d22:	00013697          	auipc	a3,0x13
ffffffffc0202d26:	8866a683          	lw	a3,-1914(a3) # ffffffffc02155a8 <pgfault_num>
ffffffffc0202d2a:	4585                	li	a1,1
ffffffffc0202d2c:	00013797          	auipc	a5,0x13
ffffffffc0202d30:	87c78793          	addi	a5,a5,-1924 # ffffffffc02155a8 <pgfault_num>
ffffffffc0202d34:	54b69063          	bne	a3,a1,ffffffffc0203274 <swap_init+0x71a>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202d38:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0202d3c:	4398                	lw	a4,0(a5)
ffffffffc0202d3e:	2701                	sext.w	a4,a4
ffffffffc0202d40:	3cd71a63          	bne	a4,a3,ffffffffc0203114 <swap_init+0x5ba>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202d44:	6689                	lui	a3,0x2
ffffffffc0202d46:	462d                	li	a2,11
ffffffffc0202d48:	00c68023          	sb	a2,0(a3) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202d4c:	4398                	lw	a4,0(a5)
ffffffffc0202d4e:	4589                	li	a1,2
ffffffffc0202d50:	2701                	sext.w	a4,a4
ffffffffc0202d52:	4ab71163          	bne	a4,a1,ffffffffc02031f4 <swap_init+0x69a>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202d56:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0202d5a:	4394                	lw	a3,0(a5)
ffffffffc0202d5c:	2681                	sext.w	a3,a3
ffffffffc0202d5e:	4ae69b63          	bne	a3,a4,ffffffffc0203214 <swap_init+0x6ba>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202d62:	668d                	lui	a3,0x3
ffffffffc0202d64:	4631                	li	a2,12
ffffffffc0202d66:	00c68023          	sb	a2,0(a3) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202d6a:	4398                	lw	a4,0(a5)
ffffffffc0202d6c:	458d                	li	a1,3
ffffffffc0202d6e:	2701                	sext.w	a4,a4
ffffffffc0202d70:	4cb71263          	bne	a4,a1,ffffffffc0203234 <swap_init+0x6da>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202d74:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0202d78:	4394                	lw	a3,0(a5)
ffffffffc0202d7a:	2681                	sext.w	a3,a3
ffffffffc0202d7c:	4ce69c63          	bne	a3,a4,ffffffffc0203254 <swap_init+0x6fa>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202d80:	6691                	lui	a3,0x4
ffffffffc0202d82:	4635                	li	a2,13
ffffffffc0202d84:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202d88:	4398                	lw	a4,0(a5)
ffffffffc0202d8a:	2701                	sext.w	a4,a4
ffffffffc0202d8c:	43471463          	bne	a4,s4,ffffffffc02031b4 <swap_init+0x65a>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202d90:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0202d94:	439c                	lw	a5,0(a5)
ffffffffc0202d96:	2781                	sext.w	a5,a5
ffffffffc0202d98:	42e79e63          	bne	a5,a4,ffffffffc02031d4 <swap_init+0x67a>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202d9c:	481c                	lw	a5,16(s0)
ffffffffc0202d9e:	2a079f63          	bnez	a5,ffffffffc020305c <swap_init+0x502>
ffffffffc0202da2:	0000e797          	auipc	a5,0xe
ffffffffc0202da6:	71678793          	addi	a5,a5,1814 # ffffffffc02114b8 <swap_in_seq_no>
ffffffffc0202daa:	0000e717          	auipc	a4,0xe
ffffffffc0202dae:	73670713          	addi	a4,a4,1846 # ffffffffc02114e0 <swap_out_seq_no>
ffffffffc0202db2:	0000e617          	auipc	a2,0xe
ffffffffc0202db6:	72e60613          	addi	a2,a2,1838 # ffffffffc02114e0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202dba:	56fd                	li	a3,-1
ffffffffc0202dbc:	c394                	sw	a3,0(a5)
ffffffffc0202dbe:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202dc0:	0791                	addi	a5,a5,4
ffffffffc0202dc2:	0711                	addi	a4,a4,4
ffffffffc0202dc4:	fec79ce3          	bne	a5,a2,ffffffffc0202dbc <swap_init+0x262>
ffffffffc0202dc8:	0000e717          	auipc	a4,0xe
ffffffffc0202dcc:	6b070713          	addi	a4,a4,1712 # ffffffffc0211478 <check_ptep>
ffffffffc0202dd0:	0000e697          	auipc	a3,0xe
ffffffffc0202dd4:	6c868693          	addi	a3,a3,1736 # ffffffffc0211498 <check_rp>
ffffffffc0202dd8:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202dda:	00012c17          	auipc	s8,0x12
ffffffffc0202dde:	78ec0c13          	addi	s8,s8,1934 # ffffffffc0215568 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202de2:	00012c97          	auipc	s9,0x12
ffffffffc0202de6:	78ec8c93          	addi	s9,s9,1934 # ffffffffc0215570 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0202dea:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202dee:	4601                	li	a2,0
ffffffffc0202df0:	855a                	mv	a0,s6
ffffffffc0202df2:	e836                	sd	a3,16(sp)
ffffffffc0202df4:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0202df6:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202df8:	d37fe0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc0202dfc:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202dfe:	65a2                	ld	a1,8(sp)
ffffffffc0202e00:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202e02:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0202e04:	1c050063          	beqz	a0,ffffffffc0202fc4 <swap_init+0x46a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202e08:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202e0a:	0017f613          	andi	a2,a5,1
ffffffffc0202e0e:	1c060b63          	beqz	a2,ffffffffc0202fe4 <swap_init+0x48a>
    if (PPN(pa) >= npage) {
ffffffffc0202e12:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202e16:	078a                	slli	a5,a5,0x2
ffffffffc0202e18:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e1a:	12c7fd63          	bgeu	a5,a2,ffffffffc0202f54 <swap_init+0x3fa>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e1e:	00004617          	auipc	a2,0x4
ffffffffc0202e22:	0ca60613          	addi	a2,a2,202 # ffffffffc0206ee8 <nbase>
ffffffffc0202e26:	00063a03          	ld	s4,0(a2)
ffffffffc0202e2a:	000cb603          	ld	a2,0(s9)
ffffffffc0202e2e:	6288                	ld	a0,0(a3)
ffffffffc0202e30:	414787b3          	sub	a5,a5,s4
ffffffffc0202e34:	079a                	slli	a5,a5,0x6
ffffffffc0202e36:	97b2                	add	a5,a5,a2
ffffffffc0202e38:	12f51a63          	bne	a0,a5,ffffffffc0202f6c <swap_init+0x412>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e3c:	6785                	lui	a5,0x1
ffffffffc0202e3e:	95be                	add	a1,a1,a5
ffffffffc0202e40:	6795                	lui	a5,0x5
ffffffffc0202e42:	0721                	addi	a4,a4,8
ffffffffc0202e44:	06a1                	addi	a3,a3,8
ffffffffc0202e46:	faf592e3          	bne	a1,a5,ffffffffc0202dea <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202e4a:	00003517          	auipc	a0,0x3
ffffffffc0202e4e:	61e50513          	addi	a0,a0,1566 # ffffffffc0206468 <default_pmm_manager+0x8d8>
ffffffffc0202e52:	b2efd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc0202e56:	000bb783          	ld	a5,0(s7)
ffffffffc0202e5a:	7f9c                	ld	a5,56(a5)
ffffffffc0202e5c:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202e5e:	30051b63          	bnez	a0,ffffffffc0203174 <swap_init+0x61a>

     nr_free = nr_free_store;
ffffffffc0202e62:	77a2                	ld	a5,40(sp)
ffffffffc0202e64:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0202e66:	67e2                	ld	a5,24(sp)
ffffffffc0202e68:	e01c                	sd	a5,0(s0)
ffffffffc0202e6a:	7782                	ld	a5,32(sp)
ffffffffc0202e6c:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202e6e:	6088                	ld	a0,0(s1)
ffffffffc0202e70:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e72:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0202e74:	c41fe0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e78:	ff349be3          	bne	s1,s3,ffffffffc0202e6e <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202e7c:	8556                	mv	a0,s5
ffffffffc0202e7e:	355000ef          	jal	ra,ffffffffc02039d2 <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202e82:	00012797          	auipc	a5,0x12
ffffffffc0202e86:	6de78793          	addi	a5,a5,1758 # ffffffffc0215560 <boot_pgdir>
ffffffffc0202e8a:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202e8c:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e90:	639c                	ld	a5,0(a5)
ffffffffc0202e92:	078a                	slli	a5,a5,0x2
ffffffffc0202e94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e96:	0ae7fd63          	bgeu	a5,a4,ffffffffc0202f50 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e9a:	414786b3          	sub	a3,a5,s4
ffffffffc0202e9e:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202ea0:	8699                	srai	a3,a3,0x6
ffffffffc0202ea2:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0202ea4:	00c69793          	slli	a5,a3,0xc
ffffffffc0202ea8:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202eaa:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202eae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202eb0:	22e7f663          	bgeu	a5,a4,ffffffffc02030dc <swap_init+0x582>
     free_page(pde2page(pd0[0]));
ffffffffc0202eb4:	00012797          	auipc	a5,0x12
ffffffffc0202eb8:	6cc7b783          	ld	a5,1740(a5) # ffffffffc0215580 <va_pa_offset>
ffffffffc0202ebc:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ebe:	629c                	ld	a5,0(a3)
ffffffffc0202ec0:	078a                	slli	a5,a5,0x2
ffffffffc0202ec2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ec4:	08e7f663          	bgeu	a5,a4,ffffffffc0202f50 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ec8:	414787b3          	sub	a5,a5,s4
ffffffffc0202ecc:	079a                	slli	a5,a5,0x6
ffffffffc0202ece:	953e                	add	a0,a0,a5
ffffffffc0202ed0:	4585                	li	a1,1
ffffffffc0202ed2:	be3fe0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ed6:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0202eda:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ede:	078a                	slli	a5,a5,0x2
ffffffffc0202ee0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ee2:	06e7f763          	bgeu	a5,a4,ffffffffc0202f50 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ee6:	000cb503          	ld	a0,0(s9)
ffffffffc0202eea:	414787b3          	sub	a5,a5,s4
ffffffffc0202eee:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0202ef0:	4585                	li	a1,1
ffffffffc0202ef2:	953e                	add	a0,a0,a5
ffffffffc0202ef4:	bc1fe0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
     pgdir[0] = 0;
ffffffffc0202ef8:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0202efc:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0202f00:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f02:	00878a63          	beq	a5,s0,ffffffffc0202f16 <swap_init+0x3bc>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202f06:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202f0a:	679c                	ld	a5,8(a5)
ffffffffc0202f0c:	3dfd                	addiw	s11,s11,-1
ffffffffc0202f0e:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f12:	fe879ae3          	bne	a5,s0,ffffffffc0202f06 <swap_init+0x3ac>
     }
     assert(count==0);
ffffffffc0202f16:	1c0d9f63          	bnez	s11,ffffffffc02030f4 <swap_init+0x59a>
     assert(total==0);
ffffffffc0202f1a:	1a0d1163          	bnez	s10,ffffffffc02030bc <swap_init+0x562>

     cprintf("check_swap() succeeded!\n");
ffffffffc0202f1e:	00003517          	auipc	a0,0x3
ffffffffc0202f22:	59a50513          	addi	a0,a0,1434 # ffffffffc02064b8 <default_pmm_manager+0x928>
ffffffffc0202f26:	a5afd0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0202f2a:	b149                	j	ffffffffc0202bac <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f2c:	4481                	li	s1,0
ffffffffc0202f2e:	b1e5                	j	ffffffffc0202c16 <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0202f30:	00003697          	auipc	a3,0x3
ffffffffc0202f34:	8a068693          	addi	a3,a3,-1888 # ffffffffc02057d0 <commands+0x728>
ffffffffc0202f38:	00003617          	auipc	a2,0x3
ffffffffc0202f3c:	8a860613          	addi	a2,a2,-1880 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202f40:	0bd00593          	li	a1,189
ffffffffc0202f44:	00003517          	auipc	a0,0x3
ffffffffc0202f48:	30c50513          	addi	a0,a0,780 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0202f4c:	cfafd0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc0202f50:	befff0ef          	jal	ra,ffffffffc0202b3e <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0202f54:	00003617          	auipc	a2,0x3
ffffffffc0202f58:	d4460613          	addi	a2,a2,-700 # ffffffffc0205c98 <default_pmm_manager+0x108>
ffffffffc0202f5c:	06200593          	li	a1,98
ffffffffc0202f60:	00003517          	auipc	a0,0x3
ffffffffc0202f64:	c9050513          	addi	a0,a0,-880 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0202f68:	cdefd0ef          	jal	ra,ffffffffc0200446 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202f6c:	00003697          	auipc	a3,0x3
ffffffffc0202f70:	4d468693          	addi	a3,a3,1236 # ffffffffc0206440 <default_pmm_manager+0x8b0>
ffffffffc0202f74:	00003617          	auipc	a2,0x3
ffffffffc0202f78:	86c60613          	addi	a2,a2,-1940 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202f7c:	0fd00593          	li	a1,253
ffffffffc0202f80:	00003517          	auipc	a0,0x3
ffffffffc0202f84:	2d050513          	addi	a0,a0,720 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0202f88:	cbefd0ef          	jal	ra,ffffffffc0200446 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202f8c:	00003697          	auipc	a3,0x3
ffffffffc0202f90:	3d468693          	addi	a3,a3,980 # ffffffffc0206360 <default_pmm_manager+0x7d0>
ffffffffc0202f94:	00003617          	auipc	a2,0x3
ffffffffc0202f98:	84c60613          	addi	a2,a2,-1972 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202f9c:	0dd00593          	li	a1,221
ffffffffc0202fa0:	00003517          	auipc	a0,0x3
ffffffffc0202fa4:	2b050513          	addi	a0,a0,688 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0202fa8:	c9efd0ef          	jal	ra,ffffffffc0200446 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202fac:	00003617          	auipc	a2,0x3
ffffffffc0202fb0:	28460613          	addi	a2,a2,644 # ffffffffc0206230 <default_pmm_manager+0x6a0>
ffffffffc0202fb4:	02a00593          	li	a1,42
ffffffffc0202fb8:	00003517          	auipc	a0,0x3
ffffffffc0202fbc:	29850513          	addi	a0,a0,664 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0202fc0:	c86fd0ef          	jal	ra,ffffffffc0200446 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202fc4:	00003697          	auipc	a3,0x3
ffffffffc0202fc8:	46468693          	addi	a3,a3,1124 # ffffffffc0206428 <default_pmm_manager+0x898>
ffffffffc0202fcc:	00003617          	auipc	a2,0x3
ffffffffc0202fd0:	81460613          	addi	a2,a2,-2028 # ffffffffc02057e0 <commands+0x738>
ffffffffc0202fd4:	0fc00593          	li	a1,252
ffffffffc0202fd8:	00003517          	auipc	a0,0x3
ffffffffc0202fdc:	27850513          	addi	a0,a0,632 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0202fe0:	c66fd0ef          	jal	ra,ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202fe4:	00003617          	auipc	a2,0x3
ffffffffc0202fe8:	cd460613          	addi	a2,a2,-812 # ffffffffc0205cb8 <default_pmm_manager+0x128>
ffffffffc0202fec:	07400593          	li	a1,116
ffffffffc0202ff0:	00003517          	auipc	a0,0x3
ffffffffc0202ff4:	c0050513          	addi	a0,a0,-1024 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0202ff8:	c4efd0ef          	jal	ra,ffffffffc0200446 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202ffc:	00003697          	auipc	a3,0x3
ffffffffc0203000:	37c68693          	addi	a3,a3,892 # ffffffffc0206378 <default_pmm_manager+0x7e8>
ffffffffc0203004:	00002617          	auipc	a2,0x2
ffffffffc0203008:	7dc60613          	addi	a2,a2,2012 # ffffffffc02057e0 <commands+0x738>
ffffffffc020300c:	0de00593          	li	a1,222
ffffffffc0203010:	00003517          	auipc	a0,0x3
ffffffffc0203014:	24050513          	addi	a0,a0,576 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203018:	c2efd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020301c:	00003697          	auipc	a3,0x3
ffffffffc0203020:	29468693          	addi	a3,a3,660 # ffffffffc02062b0 <default_pmm_manager+0x720>
ffffffffc0203024:	00002617          	auipc	a2,0x2
ffffffffc0203028:	7bc60613          	addi	a2,a2,1980 # ffffffffc02057e0 <commands+0x738>
ffffffffc020302c:	0c800593          	li	a1,200
ffffffffc0203030:	00003517          	auipc	a0,0x3
ffffffffc0203034:	22050513          	addi	a0,a0,544 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203038:	c0efd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(total == nr_free_pages());
ffffffffc020303c:	00002697          	auipc	a3,0x2
ffffffffc0203040:	7d468693          	addi	a3,a3,2004 # ffffffffc0205810 <commands+0x768>
ffffffffc0203044:	00002617          	auipc	a2,0x2
ffffffffc0203048:	79c60613          	addi	a2,a2,1948 # ffffffffc02057e0 <commands+0x738>
ffffffffc020304c:	0c000593          	li	a1,192
ffffffffc0203050:	00003517          	auipc	a0,0x3
ffffffffc0203054:	20050513          	addi	a0,a0,512 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203058:	beefd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert( nr_free == 0);         
ffffffffc020305c:	00003697          	auipc	a3,0x3
ffffffffc0203060:	95c68693          	addi	a3,a3,-1700 # ffffffffc02059b8 <commands+0x910>
ffffffffc0203064:	00002617          	auipc	a2,0x2
ffffffffc0203068:	77c60613          	addi	a2,a2,1916 # ffffffffc02057e0 <commands+0x738>
ffffffffc020306c:	0f400593          	li	a1,244
ffffffffc0203070:	00003517          	auipc	a0,0x3
ffffffffc0203074:	1e050513          	addi	a0,a0,480 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203078:	bcefd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgdir[0] == 0);
ffffffffc020307c:	00003697          	auipc	a3,0x3
ffffffffc0203080:	24c68693          	addi	a3,a3,588 # ffffffffc02062c8 <default_pmm_manager+0x738>
ffffffffc0203084:	00002617          	auipc	a2,0x2
ffffffffc0203088:	75c60613          	addi	a2,a2,1884 # ffffffffc02057e0 <commands+0x738>
ffffffffc020308c:	0cd00593          	li	a1,205
ffffffffc0203090:	00003517          	auipc	a0,0x3
ffffffffc0203094:	1c050513          	addi	a0,a0,448 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203098:	baefd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(mm != NULL);
ffffffffc020309c:	00003697          	auipc	a3,0x3
ffffffffc02030a0:	20468693          	addi	a3,a3,516 # ffffffffc02062a0 <default_pmm_manager+0x710>
ffffffffc02030a4:	00002617          	auipc	a2,0x2
ffffffffc02030a8:	73c60613          	addi	a2,a2,1852 # ffffffffc02057e0 <commands+0x738>
ffffffffc02030ac:	0c500593          	li	a1,197
ffffffffc02030b0:	00003517          	auipc	a0,0x3
ffffffffc02030b4:	1a050513          	addi	a0,a0,416 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02030b8:	b8efd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(total==0);
ffffffffc02030bc:	00003697          	auipc	a3,0x3
ffffffffc02030c0:	3ec68693          	addi	a3,a3,1004 # ffffffffc02064a8 <default_pmm_manager+0x918>
ffffffffc02030c4:	00002617          	auipc	a2,0x2
ffffffffc02030c8:	71c60613          	addi	a2,a2,1820 # ffffffffc02057e0 <commands+0x738>
ffffffffc02030cc:	11d00593          	li	a1,285
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	18050513          	addi	a0,a0,384 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02030d8:	b6efd0ef          	jal	ra,ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02030dc:	00003617          	auipc	a2,0x3
ffffffffc02030e0:	aec60613          	addi	a2,a2,-1300 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc02030e4:	06900593          	li	a1,105
ffffffffc02030e8:	00003517          	auipc	a0,0x3
ffffffffc02030ec:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc02030f0:	b56fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(count==0);
ffffffffc02030f4:	00003697          	auipc	a3,0x3
ffffffffc02030f8:	3a468693          	addi	a3,a3,932 # ffffffffc0206498 <default_pmm_manager+0x908>
ffffffffc02030fc:	00002617          	auipc	a2,0x2
ffffffffc0203100:	6e460613          	addi	a2,a2,1764 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203104:	11c00593          	li	a1,284
ffffffffc0203108:	00003517          	auipc	a0,0x3
ffffffffc020310c:	14850513          	addi	a0,a0,328 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203110:	b36fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==1);
ffffffffc0203114:	00003697          	auipc	a3,0x3
ffffffffc0203118:	2d468693          	addi	a3,a3,724 # ffffffffc02063e8 <default_pmm_manager+0x858>
ffffffffc020311c:	00002617          	auipc	a2,0x2
ffffffffc0203120:	6c460613          	addi	a2,a2,1732 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203124:	09600593          	li	a1,150
ffffffffc0203128:	00003517          	auipc	a0,0x3
ffffffffc020312c:	12850513          	addi	a0,a0,296 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203130:	b16fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203134:	00003697          	auipc	a3,0x3
ffffffffc0203138:	26468693          	addi	a3,a3,612 # ffffffffc0206398 <default_pmm_manager+0x808>
ffffffffc020313c:	00002617          	auipc	a2,0x2
ffffffffc0203140:	6a460613          	addi	a2,a2,1700 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203144:	0eb00593          	li	a1,235
ffffffffc0203148:	00003517          	auipc	a0,0x3
ffffffffc020314c:	10850513          	addi	a0,a0,264 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203150:	af6fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203154:	00003697          	auipc	a3,0x3
ffffffffc0203158:	1cc68693          	addi	a3,a3,460 # ffffffffc0206320 <default_pmm_manager+0x790>
ffffffffc020315c:	00002617          	auipc	a2,0x2
ffffffffc0203160:	68460613          	addi	a2,a2,1668 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203164:	0d800593          	li	a1,216
ffffffffc0203168:	00003517          	auipc	a0,0x3
ffffffffc020316c:	0e850513          	addi	a0,a0,232 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203170:	ad6fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(ret==0);
ffffffffc0203174:	00003697          	auipc	a3,0x3
ffffffffc0203178:	31c68693          	addi	a3,a3,796 # ffffffffc0206490 <default_pmm_manager+0x900>
ffffffffc020317c:	00002617          	auipc	a2,0x2
ffffffffc0203180:	66460613          	addi	a2,a2,1636 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203184:	10300593          	li	a1,259
ffffffffc0203188:	00003517          	auipc	a0,0x3
ffffffffc020318c:	0c850513          	addi	a0,a0,200 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203190:	ab6fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(vma != NULL);
ffffffffc0203194:	00003697          	auipc	a3,0x3
ffffffffc0203198:	14468693          	addi	a3,a3,324 # ffffffffc02062d8 <default_pmm_manager+0x748>
ffffffffc020319c:	00002617          	auipc	a2,0x2
ffffffffc02031a0:	64460613          	addi	a2,a2,1604 # ffffffffc02057e0 <commands+0x738>
ffffffffc02031a4:	0d000593          	li	a1,208
ffffffffc02031a8:	00003517          	auipc	a0,0x3
ffffffffc02031ac:	0a850513          	addi	a0,a0,168 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02031b0:	a96fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==4);
ffffffffc02031b4:	00003697          	auipc	a3,0x3
ffffffffc02031b8:	26468693          	addi	a3,a3,612 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc02031bc:	00002617          	auipc	a2,0x2
ffffffffc02031c0:	62460613          	addi	a2,a2,1572 # ffffffffc02057e0 <commands+0x738>
ffffffffc02031c4:	0a000593          	li	a1,160
ffffffffc02031c8:	00003517          	auipc	a0,0x3
ffffffffc02031cc:	08850513          	addi	a0,a0,136 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02031d0:	a76fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==4);
ffffffffc02031d4:	00003697          	auipc	a3,0x3
ffffffffc02031d8:	24468693          	addi	a3,a3,580 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc02031dc:	00002617          	auipc	a2,0x2
ffffffffc02031e0:	60460613          	addi	a2,a2,1540 # ffffffffc02057e0 <commands+0x738>
ffffffffc02031e4:	0a200593          	li	a1,162
ffffffffc02031e8:	00003517          	auipc	a0,0x3
ffffffffc02031ec:	06850513          	addi	a0,a0,104 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02031f0:	a56fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==2);
ffffffffc02031f4:	00003697          	auipc	a3,0x3
ffffffffc02031f8:	20468693          	addi	a3,a3,516 # ffffffffc02063f8 <default_pmm_manager+0x868>
ffffffffc02031fc:	00002617          	auipc	a2,0x2
ffffffffc0203200:	5e460613          	addi	a2,a2,1508 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203204:	09800593          	li	a1,152
ffffffffc0203208:	00003517          	auipc	a0,0x3
ffffffffc020320c:	04850513          	addi	a0,a0,72 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203210:	a36fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==2);
ffffffffc0203214:	00003697          	auipc	a3,0x3
ffffffffc0203218:	1e468693          	addi	a3,a3,484 # ffffffffc02063f8 <default_pmm_manager+0x868>
ffffffffc020321c:	00002617          	auipc	a2,0x2
ffffffffc0203220:	5c460613          	addi	a2,a2,1476 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203224:	09a00593          	li	a1,154
ffffffffc0203228:	00003517          	auipc	a0,0x3
ffffffffc020322c:	02850513          	addi	a0,a0,40 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203230:	a16fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==3);
ffffffffc0203234:	00003697          	auipc	a3,0x3
ffffffffc0203238:	1d468693          	addi	a3,a3,468 # ffffffffc0206408 <default_pmm_manager+0x878>
ffffffffc020323c:	00002617          	auipc	a2,0x2
ffffffffc0203240:	5a460613          	addi	a2,a2,1444 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203244:	09c00593          	li	a1,156
ffffffffc0203248:	00003517          	auipc	a0,0x3
ffffffffc020324c:	00850513          	addi	a0,a0,8 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203250:	9f6fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==3);
ffffffffc0203254:	00003697          	auipc	a3,0x3
ffffffffc0203258:	1b468693          	addi	a3,a3,436 # ffffffffc0206408 <default_pmm_manager+0x878>
ffffffffc020325c:	00002617          	auipc	a2,0x2
ffffffffc0203260:	58460613          	addi	a2,a2,1412 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203264:	09e00593          	li	a1,158
ffffffffc0203268:	00003517          	auipc	a0,0x3
ffffffffc020326c:	fe850513          	addi	a0,a0,-24 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203270:	9d6fd0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(pgfault_num==1);
ffffffffc0203274:	00003697          	auipc	a3,0x3
ffffffffc0203278:	17468693          	addi	a3,a3,372 # ffffffffc02063e8 <default_pmm_manager+0x858>
ffffffffc020327c:	00002617          	auipc	a2,0x2
ffffffffc0203280:	56460613          	addi	a2,a2,1380 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203284:	09400593          	li	a1,148
ffffffffc0203288:	00003517          	auipc	a0,0x3
ffffffffc020328c:	fc850513          	addi	a0,a0,-56 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203290:	9b6fd0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0203294 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203294:	00012797          	auipc	a5,0x12
ffffffffc0203298:	2fc7b783          	ld	a5,764(a5) # ffffffffc0215590 <sm>
ffffffffc020329c:	6b9c                	ld	a5,16(a5)
ffffffffc020329e:	8782                	jr	a5

ffffffffc02032a0 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc02032a0:	00012797          	auipc	a5,0x12
ffffffffc02032a4:	2f07b783          	ld	a5,752(a5) # ffffffffc0215590 <sm>
ffffffffc02032a8:	739c                	ld	a5,32(a5)
ffffffffc02032aa:	8782                	jr	a5

ffffffffc02032ac <swap_out>:
{
ffffffffc02032ac:	711d                	addi	sp,sp,-96
ffffffffc02032ae:	ec86                	sd	ra,88(sp)
ffffffffc02032b0:	e8a2                	sd	s0,80(sp)
ffffffffc02032b2:	e4a6                	sd	s1,72(sp)
ffffffffc02032b4:	e0ca                	sd	s2,64(sp)
ffffffffc02032b6:	fc4e                	sd	s3,56(sp)
ffffffffc02032b8:	f852                	sd	s4,48(sp)
ffffffffc02032ba:	f456                	sd	s5,40(sp)
ffffffffc02032bc:	f05a                	sd	s6,32(sp)
ffffffffc02032be:	ec5e                	sd	s7,24(sp)
ffffffffc02032c0:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc02032c2:	cde9                	beqz	a1,ffffffffc020339c <swap_out+0xf0>
ffffffffc02032c4:	8a2e                	mv	s4,a1
ffffffffc02032c6:	892a                	mv	s2,a0
ffffffffc02032c8:	8ab2                	mv	s5,a2
ffffffffc02032ca:	4401                	li	s0,0
ffffffffc02032cc:	00012997          	auipc	s3,0x12
ffffffffc02032d0:	2c498993          	addi	s3,s3,708 # ffffffffc0215590 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032d4:	00003b17          	auipc	s6,0x3
ffffffffc02032d8:	264b0b13          	addi	s6,s6,612 # ffffffffc0206538 <default_pmm_manager+0x9a8>
                    cprintf("SWAP: failed to save\n");
ffffffffc02032dc:	00003b97          	auipc	s7,0x3
ffffffffc02032e0:	244b8b93          	addi	s7,s7,580 # ffffffffc0206520 <default_pmm_manager+0x990>
ffffffffc02032e4:	a825                	j	ffffffffc020331c <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032e6:	67a2                	ld	a5,8(sp)
ffffffffc02032e8:	8626                	mv	a2,s1
ffffffffc02032ea:	85a2                	mv	a1,s0
ffffffffc02032ec:	7f94                	ld	a3,56(a5)
ffffffffc02032ee:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc02032f0:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032f2:	82b1                	srli	a3,a3,0xc
ffffffffc02032f4:	0685                	addi	a3,a3,1
ffffffffc02032f6:	e8bfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02032fa:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc02032fc:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02032fe:	7d1c                	ld	a5,56(a0)
ffffffffc0203300:	83b1                	srli	a5,a5,0xc
ffffffffc0203302:	0785                	addi	a5,a5,1
ffffffffc0203304:	07a2                	slli	a5,a5,0x8
ffffffffc0203306:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc020330a:	faafe0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020330e:	01893503          	ld	a0,24(s2)
ffffffffc0203312:	85a6                	mv	a1,s1
ffffffffc0203314:	f6cff0ef          	jal	ra,ffffffffc0202a80 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203318:	048a0d63          	beq	s4,s0,ffffffffc0203372 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc020331c:	0009b783          	ld	a5,0(s3)
ffffffffc0203320:	8656                	mv	a2,s5
ffffffffc0203322:	002c                	addi	a1,sp,8
ffffffffc0203324:	7b9c                	ld	a5,48(a5)
ffffffffc0203326:	854a                	mv	a0,s2
ffffffffc0203328:	9782                	jalr	a5
          if (r != 0) {
ffffffffc020332a:	e12d                	bnez	a0,ffffffffc020338c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc020332c:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020332e:	01893503          	ld	a0,24(s2)
ffffffffc0203332:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203334:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203336:	85a6                	mv	a1,s1
ffffffffc0203338:	ff6fe0ef          	jal	ra,ffffffffc0201b2e <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc020333c:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020333e:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203340:	8b85                	andi	a5,a5,1
ffffffffc0203342:	cfb9                	beqz	a5,ffffffffc02033a0 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203344:	65a2                	ld	a1,8(sp)
ffffffffc0203346:	7d9c                	ld	a5,56(a1)
ffffffffc0203348:	83b1                	srli	a5,a5,0xc
ffffffffc020334a:	0785                	addi	a5,a5,1
ffffffffc020334c:	00879513          	slli	a0,a5,0x8
ffffffffc0203350:	64d000ef          	jal	ra,ffffffffc020419c <swapfs_write>
ffffffffc0203354:	d949                	beqz	a0,ffffffffc02032e6 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203356:	855e                	mv	a0,s7
ffffffffc0203358:	e29fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc020335c:	0009b783          	ld	a5,0(s3)
ffffffffc0203360:	6622                	ld	a2,8(sp)
ffffffffc0203362:	4681                	li	a3,0
ffffffffc0203364:	739c                	ld	a5,32(a5)
ffffffffc0203366:	85a6                	mv	a1,s1
ffffffffc0203368:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc020336a:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc020336c:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020336e:	fa8a17e3          	bne	s4,s0,ffffffffc020331c <swap_out+0x70>
}
ffffffffc0203372:	60e6                	ld	ra,88(sp)
ffffffffc0203374:	8522                	mv	a0,s0
ffffffffc0203376:	6446                	ld	s0,80(sp)
ffffffffc0203378:	64a6                	ld	s1,72(sp)
ffffffffc020337a:	6906                	ld	s2,64(sp)
ffffffffc020337c:	79e2                	ld	s3,56(sp)
ffffffffc020337e:	7a42                	ld	s4,48(sp)
ffffffffc0203380:	7aa2                	ld	s5,40(sp)
ffffffffc0203382:	7b02                	ld	s6,32(sp)
ffffffffc0203384:	6be2                	ld	s7,24(sp)
ffffffffc0203386:	6c42                	ld	s8,16(sp)
ffffffffc0203388:	6125                	addi	sp,sp,96
ffffffffc020338a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc020338c:	85a2                	mv	a1,s0
ffffffffc020338e:	00003517          	auipc	a0,0x3
ffffffffc0203392:	14a50513          	addi	a0,a0,330 # ffffffffc02064d8 <default_pmm_manager+0x948>
ffffffffc0203396:	debfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                  break;
ffffffffc020339a:	bfe1                	j	ffffffffc0203372 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc020339c:	4401                	li	s0,0
ffffffffc020339e:	bfd1                	j	ffffffffc0203372 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc02033a0:	00003697          	auipc	a3,0x3
ffffffffc02033a4:	16868693          	addi	a3,a3,360 # ffffffffc0206508 <default_pmm_manager+0x978>
ffffffffc02033a8:	00002617          	auipc	a2,0x2
ffffffffc02033ac:	43860613          	addi	a2,a2,1080 # ffffffffc02057e0 <commands+0x738>
ffffffffc02033b0:	06900593          	li	a1,105
ffffffffc02033b4:	00003517          	auipc	a0,0x3
ffffffffc02033b8:	e9c50513          	addi	a0,a0,-356 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc02033bc:	88afd0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc02033c0 <swap_in>:
{
ffffffffc02033c0:	7179                	addi	sp,sp,-48
ffffffffc02033c2:	e84a                	sd	s2,16(sp)
ffffffffc02033c4:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc02033c6:	4505                	li	a0,1
{
ffffffffc02033c8:	ec26                	sd	s1,24(sp)
ffffffffc02033ca:	e44e                	sd	s3,8(sp)
ffffffffc02033cc:	f406                	sd	ra,40(sp)
ffffffffc02033ce:	f022                	sd	s0,32(sp)
ffffffffc02033d0:	84ae                	mv	s1,a1
ffffffffc02033d2:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc02033d4:	e4efe0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
     assert(result!=NULL);
ffffffffc02033d8:	c129                	beqz	a0,ffffffffc020341a <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02033da:	842a                	mv	s0,a0
ffffffffc02033dc:	01893503          	ld	a0,24(s2)
ffffffffc02033e0:	4601                	li	a2,0
ffffffffc02033e2:	85a6                	mv	a1,s1
ffffffffc02033e4:	f4afe0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc02033e8:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc02033ea:	6108                	ld	a0,0(a0)
ffffffffc02033ec:	85a2                	mv	a1,s0
ffffffffc02033ee:	521000ef          	jal	ra,ffffffffc020410e <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc02033f2:	00093583          	ld	a1,0(s2)
ffffffffc02033f6:	8626                	mv	a2,s1
ffffffffc02033f8:	00003517          	auipc	a0,0x3
ffffffffc02033fc:	19050513          	addi	a0,a0,400 # ffffffffc0206588 <default_pmm_manager+0x9f8>
ffffffffc0203400:	81a1                	srli	a1,a1,0x8
ffffffffc0203402:	d7ffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0203406:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203408:	0089b023          	sd	s0,0(s3)
}
ffffffffc020340c:	7402                	ld	s0,32(sp)
ffffffffc020340e:	64e2                	ld	s1,24(sp)
ffffffffc0203410:	6942                	ld	s2,16(sp)
ffffffffc0203412:	69a2                	ld	s3,8(sp)
ffffffffc0203414:	4501                	li	a0,0
ffffffffc0203416:	6145                	addi	sp,sp,48
ffffffffc0203418:	8082                	ret
     assert(result!=NULL);
ffffffffc020341a:	00003697          	auipc	a3,0x3
ffffffffc020341e:	15e68693          	addi	a3,a3,350 # ffffffffc0206578 <default_pmm_manager+0x9e8>
ffffffffc0203422:	00002617          	auipc	a2,0x2
ffffffffc0203426:	3be60613          	addi	a2,a2,958 # ffffffffc02057e0 <commands+0x738>
ffffffffc020342a:	07f00593          	li	a1,127
ffffffffc020342e:	00003517          	auipc	a0,0x3
ffffffffc0203432:	e2250513          	addi	a0,a0,-478 # ffffffffc0206250 <default_pmm_manager+0x6c0>
ffffffffc0203436:	810fd0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020343a <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc020343a:	0000e797          	auipc	a5,0xe
ffffffffc020343e:	0ce78793          	addi	a5,a5,206 # ffffffffc0211508 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203442:	f51c                	sd	a5,40(a0)
ffffffffc0203444:	e79c                	sd	a5,8(a5)
ffffffffc0203446:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203448:	4501                	li	a0,0
ffffffffc020344a:	8082                	ret

ffffffffc020344c <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc020344c:	4501                	li	a0,0
ffffffffc020344e:	8082                	ret

ffffffffc0203450 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203450:	4501                	li	a0,0
ffffffffc0203452:	8082                	ret

ffffffffc0203454 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203454:	4501                	li	a0,0
ffffffffc0203456:	8082                	ret

ffffffffc0203458 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203458:	711d                	addi	sp,sp,-96
ffffffffc020345a:	fc4e                	sd	s3,56(sp)
ffffffffc020345c:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020345e:	00003517          	auipc	a0,0x3
ffffffffc0203462:	16a50513          	addi	a0,a0,362 # ffffffffc02065c8 <default_pmm_manager+0xa38>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203466:	698d                	lui	s3,0x3
ffffffffc0203468:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc020346a:	e0ca                	sd	s2,64(sp)
ffffffffc020346c:	ec86                	sd	ra,88(sp)
ffffffffc020346e:	e8a2                	sd	s0,80(sp)
ffffffffc0203470:	e4a6                	sd	s1,72(sp)
ffffffffc0203472:	f456                	sd	s5,40(sp)
ffffffffc0203474:	f05a                	sd	s6,32(sp)
ffffffffc0203476:	ec5e                	sd	s7,24(sp)
ffffffffc0203478:	e862                	sd	s8,16(sp)
ffffffffc020347a:	e466                	sd	s9,8(sp)
ffffffffc020347c:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020347e:	d03fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203482:	01498023          	sb	s4,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203486:	00012917          	auipc	s2,0x12
ffffffffc020348a:	12292903          	lw	s2,290(s2) # ffffffffc02155a8 <pgfault_num>
ffffffffc020348e:	4791                	li	a5,4
ffffffffc0203490:	14f91e63          	bne	s2,a5,ffffffffc02035ec <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203494:	00003517          	auipc	a0,0x3
ffffffffc0203498:	17450513          	addi	a0,a0,372 # ffffffffc0206608 <default_pmm_manager+0xa78>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020349c:	6a85                	lui	s5,0x1
ffffffffc020349e:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02034a0:	ce1fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02034a4:	00012417          	auipc	s0,0x12
ffffffffc02034a8:	10440413          	addi	s0,s0,260 # ffffffffc02155a8 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02034ac:	016a8023          	sb	s6,0(s5) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc02034b0:	4004                	lw	s1,0(s0)
ffffffffc02034b2:	2481                	sext.w	s1,s1
ffffffffc02034b4:	2b249c63          	bne	s1,s2,ffffffffc020376c <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02034b8:	00003517          	auipc	a0,0x3
ffffffffc02034bc:	17850513          	addi	a0,a0,376 # ffffffffc0206630 <default_pmm_manager+0xaa0>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02034c0:	6b91                	lui	s7,0x4
ffffffffc02034c2:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02034c4:	cbdfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02034c8:	018b8023          	sb	s8,0(s7) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02034cc:	00042903          	lw	s2,0(s0)
ffffffffc02034d0:	2901                	sext.w	s2,s2
ffffffffc02034d2:	26991d63          	bne	s2,s1,ffffffffc020374c <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02034d6:	00003517          	auipc	a0,0x3
ffffffffc02034da:	18250513          	addi	a0,a0,386 # ffffffffc0206658 <default_pmm_manager+0xac8>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02034de:	6c89                	lui	s9,0x2
ffffffffc02034e0:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02034e2:	c9ffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02034e6:	01ac8023          	sb	s10,0(s9) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02034ea:	401c                	lw	a5,0(s0)
ffffffffc02034ec:	2781                	sext.w	a5,a5
ffffffffc02034ee:	23279f63          	bne	a5,s2,ffffffffc020372c <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02034f2:	00003517          	auipc	a0,0x3
ffffffffc02034f6:	18e50513          	addi	a0,a0,398 # ffffffffc0206680 <default_pmm_manager+0xaf0>
ffffffffc02034fa:	c87fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02034fe:	6795                	lui	a5,0x5
ffffffffc0203500:	4739                	li	a4,14
ffffffffc0203502:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0203506:	4004                	lw	s1,0(s0)
ffffffffc0203508:	4795                	li	a5,5
ffffffffc020350a:	2481                	sext.w	s1,s1
ffffffffc020350c:	20f49063          	bne	s1,a5,ffffffffc020370c <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203510:	00003517          	auipc	a0,0x3
ffffffffc0203514:	14850513          	addi	a0,a0,328 # ffffffffc0206658 <default_pmm_manager+0xac8>
ffffffffc0203518:	c69fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020351c:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc0203520:	401c                	lw	a5,0(s0)
ffffffffc0203522:	2781                	sext.w	a5,a5
ffffffffc0203524:	1c979463          	bne	a5,s1,ffffffffc02036ec <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203528:	00003517          	auipc	a0,0x3
ffffffffc020352c:	0e050513          	addi	a0,a0,224 # ffffffffc0206608 <default_pmm_manager+0xa78>
ffffffffc0203530:	c51fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203534:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203538:	401c                	lw	a5,0(s0)
ffffffffc020353a:	4719                	li	a4,6
ffffffffc020353c:	2781                	sext.w	a5,a5
ffffffffc020353e:	18e79763          	bne	a5,a4,ffffffffc02036cc <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203542:	00003517          	auipc	a0,0x3
ffffffffc0203546:	11650513          	addi	a0,a0,278 # ffffffffc0206658 <default_pmm_manager+0xac8>
ffffffffc020354a:	c37fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020354e:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc0203552:	401c                	lw	a5,0(s0)
ffffffffc0203554:	471d                	li	a4,7
ffffffffc0203556:	2781                	sext.w	a5,a5
ffffffffc0203558:	14e79a63          	bne	a5,a4,ffffffffc02036ac <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020355c:	00003517          	auipc	a0,0x3
ffffffffc0203560:	06c50513          	addi	a0,a0,108 # ffffffffc02065c8 <default_pmm_manager+0xa38>
ffffffffc0203564:	c1dfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203568:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc020356c:	401c                	lw	a5,0(s0)
ffffffffc020356e:	4721                	li	a4,8
ffffffffc0203570:	2781                	sext.w	a5,a5
ffffffffc0203572:	10e79d63          	bne	a5,a4,ffffffffc020368c <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203576:	00003517          	auipc	a0,0x3
ffffffffc020357a:	0ba50513          	addi	a0,a0,186 # ffffffffc0206630 <default_pmm_manager+0xaa0>
ffffffffc020357e:	c03fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203582:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203586:	401c                	lw	a5,0(s0)
ffffffffc0203588:	4725                	li	a4,9
ffffffffc020358a:	2781                	sext.w	a5,a5
ffffffffc020358c:	0ee79063          	bne	a5,a4,ffffffffc020366c <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203590:	00003517          	auipc	a0,0x3
ffffffffc0203594:	0f050513          	addi	a0,a0,240 # ffffffffc0206680 <default_pmm_manager+0xaf0>
ffffffffc0203598:	be9fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020359c:	6795                	lui	a5,0x5
ffffffffc020359e:	4739                	li	a4,14
ffffffffc02035a0:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc02035a4:	4004                	lw	s1,0(s0)
ffffffffc02035a6:	47a9                	li	a5,10
ffffffffc02035a8:	2481                	sext.w	s1,s1
ffffffffc02035aa:	0af49163          	bne	s1,a5,ffffffffc020364c <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02035ae:	00003517          	auipc	a0,0x3
ffffffffc02035b2:	05a50513          	addi	a0,a0,90 # ffffffffc0206608 <default_pmm_manager+0xa78>
ffffffffc02035b6:	bcbfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02035ba:	6785                	lui	a5,0x1
ffffffffc02035bc:	0007c783          	lbu	a5,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02035c0:	06979663          	bne	a5,s1,ffffffffc020362c <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc02035c4:	401c                	lw	a5,0(s0)
ffffffffc02035c6:	472d                	li	a4,11
ffffffffc02035c8:	2781                	sext.w	a5,a5
ffffffffc02035ca:	04e79163          	bne	a5,a4,ffffffffc020360c <_fifo_check_swap+0x1b4>
}
ffffffffc02035ce:	60e6                	ld	ra,88(sp)
ffffffffc02035d0:	6446                	ld	s0,80(sp)
ffffffffc02035d2:	64a6                	ld	s1,72(sp)
ffffffffc02035d4:	6906                	ld	s2,64(sp)
ffffffffc02035d6:	79e2                	ld	s3,56(sp)
ffffffffc02035d8:	7a42                	ld	s4,48(sp)
ffffffffc02035da:	7aa2                	ld	s5,40(sp)
ffffffffc02035dc:	7b02                	ld	s6,32(sp)
ffffffffc02035de:	6be2                	ld	s7,24(sp)
ffffffffc02035e0:	6c42                	ld	s8,16(sp)
ffffffffc02035e2:	6ca2                	ld	s9,8(sp)
ffffffffc02035e4:	6d02                	ld	s10,0(sp)
ffffffffc02035e6:	4501                	li	a0,0
ffffffffc02035e8:	6125                	addi	sp,sp,96
ffffffffc02035ea:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02035ec:	00003697          	auipc	a3,0x3
ffffffffc02035f0:	e2c68693          	addi	a3,a3,-468 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc02035f4:	00002617          	auipc	a2,0x2
ffffffffc02035f8:	1ec60613          	addi	a2,a2,492 # ffffffffc02057e0 <commands+0x738>
ffffffffc02035fc:	05100593          	li	a1,81
ffffffffc0203600:	00003517          	auipc	a0,0x3
ffffffffc0203604:	ff050513          	addi	a0,a0,-16 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203608:	e3ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==11);
ffffffffc020360c:	00003697          	auipc	a3,0x3
ffffffffc0203610:	12468693          	addi	a3,a3,292 # ffffffffc0206730 <default_pmm_manager+0xba0>
ffffffffc0203614:	00002617          	auipc	a2,0x2
ffffffffc0203618:	1cc60613          	addi	a2,a2,460 # ffffffffc02057e0 <commands+0x738>
ffffffffc020361c:	07300593          	li	a1,115
ffffffffc0203620:	00003517          	auipc	a0,0x3
ffffffffc0203624:	fd050513          	addi	a0,a0,-48 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203628:	e1ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020362c:	00003697          	auipc	a3,0x3
ffffffffc0203630:	0dc68693          	addi	a3,a3,220 # ffffffffc0206708 <default_pmm_manager+0xb78>
ffffffffc0203634:	00002617          	auipc	a2,0x2
ffffffffc0203638:	1ac60613          	addi	a2,a2,428 # ffffffffc02057e0 <commands+0x738>
ffffffffc020363c:	07100593          	li	a1,113
ffffffffc0203640:	00003517          	auipc	a0,0x3
ffffffffc0203644:	fb050513          	addi	a0,a0,-80 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203648:	dfffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==10);
ffffffffc020364c:	00003697          	auipc	a3,0x3
ffffffffc0203650:	0ac68693          	addi	a3,a3,172 # ffffffffc02066f8 <default_pmm_manager+0xb68>
ffffffffc0203654:	00002617          	auipc	a2,0x2
ffffffffc0203658:	18c60613          	addi	a2,a2,396 # ffffffffc02057e0 <commands+0x738>
ffffffffc020365c:	06f00593          	li	a1,111
ffffffffc0203660:	00003517          	auipc	a0,0x3
ffffffffc0203664:	f9050513          	addi	a0,a0,-112 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203668:	ddffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==9);
ffffffffc020366c:	00003697          	auipc	a3,0x3
ffffffffc0203670:	07c68693          	addi	a3,a3,124 # ffffffffc02066e8 <default_pmm_manager+0xb58>
ffffffffc0203674:	00002617          	auipc	a2,0x2
ffffffffc0203678:	16c60613          	addi	a2,a2,364 # ffffffffc02057e0 <commands+0x738>
ffffffffc020367c:	06c00593          	li	a1,108
ffffffffc0203680:	00003517          	auipc	a0,0x3
ffffffffc0203684:	f7050513          	addi	a0,a0,-144 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203688:	dbffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==8);
ffffffffc020368c:	00003697          	auipc	a3,0x3
ffffffffc0203690:	04c68693          	addi	a3,a3,76 # ffffffffc02066d8 <default_pmm_manager+0xb48>
ffffffffc0203694:	00002617          	auipc	a2,0x2
ffffffffc0203698:	14c60613          	addi	a2,a2,332 # ffffffffc02057e0 <commands+0x738>
ffffffffc020369c:	06900593          	li	a1,105
ffffffffc02036a0:	00003517          	auipc	a0,0x3
ffffffffc02036a4:	f5050513          	addi	a0,a0,-176 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc02036a8:	d9ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==7);
ffffffffc02036ac:	00003697          	auipc	a3,0x3
ffffffffc02036b0:	01c68693          	addi	a3,a3,28 # ffffffffc02066c8 <default_pmm_manager+0xb38>
ffffffffc02036b4:	00002617          	auipc	a2,0x2
ffffffffc02036b8:	12c60613          	addi	a2,a2,300 # ffffffffc02057e0 <commands+0x738>
ffffffffc02036bc:	06600593          	li	a1,102
ffffffffc02036c0:	00003517          	auipc	a0,0x3
ffffffffc02036c4:	f3050513          	addi	a0,a0,-208 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc02036c8:	d7ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==6);
ffffffffc02036cc:	00003697          	auipc	a3,0x3
ffffffffc02036d0:	fec68693          	addi	a3,a3,-20 # ffffffffc02066b8 <default_pmm_manager+0xb28>
ffffffffc02036d4:	00002617          	auipc	a2,0x2
ffffffffc02036d8:	10c60613          	addi	a2,a2,268 # ffffffffc02057e0 <commands+0x738>
ffffffffc02036dc:	06300593          	li	a1,99
ffffffffc02036e0:	00003517          	auipc	a0,0x3
ffffffffc02036e4:	f1050513          	addi	a0,a0,-240 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc02036e8:	d5ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==5);
ffffffffc02036ec:	00003697          	auipc	a3,0x3
ffffffffc02036f0:	fbc68693          	addi	a3,a3,-68 # ffffffffc02066a8 <default_pmm_manager+0xb18>
ffffffffc02036f4:	00002617          	auipc	a2,0x2
ffffffffc02036f8:	0ec60613          	addi	a2,a2,236 # ffffffffc02057e0 <commands+0x738>
ffffffffc02036fc:	06000593          	li	a1,96
ffffffffc0203700:	00003517          	auipc	a0,0x3
ffffffffc0203704:	ef050513          	addi	a0,a0,-272 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203708:	d3ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==5);
ffffffffc020370c:	00003697          	auipc	a3,0x3
ffffffffc0203710:	f9c68693          	addi	a3,a3,-100 # ffffffffc02066a8 <default_pmm_manager+0xb18>
ffffffffc0203714:	00002617          	auipc	a2,0x2
ffffffffc0203718:	0cc60613          	addi	a2,a2,204 # ffffffffc02057e0 <commands+0x738>
ffffffffc020371c:	05d00593          	li	a1,93
ffffffffc0203720:	00003517          	auipc	a0,0x3
ffffffffc0203724:	ed050513          	addi	a0,a0,-304 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203728:	d1ffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==4);
ffffffffc020372c:	00003697          	auipc	a3,0x3
ffffffffc0203730:	cec68693          	addi	a3,a3,-788 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc0203734:	00002617          	auipc	a2,0x2
ffffffffc0203738:	0ac60613          	addi	a2,a2,172 # ffffffffc02057e0 <commands+0x738>
ffffffffc020373c:	05a00593          	li	a1,90
ffffffffc0203740:	00003517          	auipc	a0,0x3
ffffffffc0203744:	eb050513          	addi	a0,a0,-336 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203748:	cfffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==4);
ffffffffc020374c:	00003697          	auipc	a3,0x3
ffffffffc0203750:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc0203754:	00002617          	auipc	a2,0x2
ffffffffc0203758:	08c60613          	addi	a2,a2,140 # ffffffffc02057e0 <commands+0x738>
ffffffffc020375c:	05700593          	li	a1,87
ffffffffc0203760:	00003517          	auipc	a0,0x3
ffffffffc0203764:	e9050513          	addi	a0,a0,-368 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203768:	cdffc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgfault_num==4);
ffffffffc020376c:	00003697          	auipc	a3,0x3
ffffffffc0203770:	cac68693          	addi	a3,a3,-852 # ffffffffc0206418 <default_pmm_manager+0x888>
ffffffffc0203774:	00002617          	auipc	a2,0x2
ffffffffc0203778:	06c60613          	addi	a2,a2,108 # ffffffffc02057e0 <commands+0x738>
ffffffffc020377c:	05400593          	li	a1,84
ffffffffc0203780:	00003517          	auipc	a0,0x3
ffffffffc0203784:	e7050513          	addi	a0,a0,-400 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc0203788:	cbffc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020378c <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020378c:	751c                	ld	a5,40(a0)
{
ffffffffc020378e:	1141                	addi	sp,sp,-16
ffffffffc0203790:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0203792:	cf91                	beqz	a5,ffffffffc02037ae <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0203794:	ee0d                	bnez	a2,ffffffffc02037ce <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0203796:	679c                	ld	a5,8(a5)
}
ffffffffc0203798:	60a2                	ld	ra,8(sp)
ffffffffc020379a:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc020379c:	6394                	ld	a3,0(a5)
ffffffffc020379e:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc02037a0:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc02037a4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02037a6:	e314                	sd	a3,0(a4)
ffffffffc02037a8:	e19c                	sd	a5,0(a1)
}
ffffffffc02037aa:	0141                	addi	sp,sp,16
ffffffffc02037ac:	8082                	ret
         assert(head != NULL);
ffffffffc02037ae:	00003697          	auipc	a3,0x3
ffffffffc02037b2:	f9268693          	addi	a3,a3,-110 # ffffffffc0206740 <default_pmm_manager+0xbb0>
ffffffffc02037b6:	00002617          	auipc	a2,0x2
ffffffffc02037ba:	02a60613          	addi	a2,a2,42 # ffffffffc02057e0 <commands+0x738>
ffffffffc02037be:	04100593          	li	a1,65
ffffffffc02037c2:	00003517          	auipc	a0,0x3
ffffffffc02037c6:	e2e50513          	addi	a0,a0,-466 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc02037ca:	c7dfc0ef          	jal	ra,ffffffffc0200446 <__panic>
     assert(in_tick==0);
ffffffffc02037ce:	00003697          	auipc	a3,0x3
ffffffffc02037d2:	f8268693          	addi	a3,a3,-126 # ffffffffc0206750 <default_pmm_manager+0xbc0>
ffffffffc02037d6:	00002617          	auipc	a2,0x2
ffffffffc02037da:	00a60613          	addi	a2,a2,10 # ffffffffc02057e0 <commands+0x738>
ffffffffc02037de:	04200593          	li	a1,66
ffffffffc02037e2:	00003517          	auipc	a0,0x3
ffffffffc02037e6:	e0e50513          	addi	a0,a0,-498 # ffffffffc02065f0 <default_pmm_manager+0xa60>
ffffffffc02037ea:	c5dfc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc02037ee <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02037ee:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02037f0:	cb91                	beqz	a5,ffffffffc0203804 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02037f2:	6394                	ld	a3,0(a5)
ffffffffc02037f4:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02037f8:	e398                	sd	a4,0(a5)
ffffffffc02037fa:	e698                	sd	a4,8(a3)
}
ffffffffc02037fc:	4501                	li	a0,0
    elm->next = next;
ffffffffc02037fe:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0203800:	f614                	sd	a3,40(a2)
ffffffffc0203802:	8082                	ret
{
ffffffffc0203804:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0203806:	00003697          	auipc	a3,0x3
ffffffffc020380a:	f5a68693          	addi	a3,a3,-166 # ffffffffc0206760 <default_pmm_manager+0xbd0>
ffffffffc020380e:	00002617          	auipc	a2,0x2
ffffffffc0203812:	fd260613          	addi	a2,a2,-46 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203816:	03200593          	li	a1,50
ffffffffc020381a:	00003517          	auipc	a0,0x3
ffffffffc020381e:	dd650513          	addi	a0,a0,-554 # ffffffffc02065f0 <default_pmm_manager+0xa60>
{
ffffffffc0203822:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203824:	c23fc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0203828 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203828:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020382a:	00003697          	auipc	a3,0x3
ffffffffc020382e:	f6e68693          	addi	a3,a3,-146 # ffffffffc0206798 <default_pmm_manager+0xc08>
ffffffffc0203832:	00002617          	auipc	a2,0x2
ffffffffc0203836:	fae60613          	addi	a2,a2,-82 # ffffffffc02057e0 <commands+0x738>
ffffffffc020383a:	07e00593          	li	a1,126
ffffffffc020383e:	00003517          	auipc	a0,0x3
ffffffffc0203842:	f7a50513          	addi	a0,a0,-134 # ffffffffc02067b8 <default_pmm_manager+0xc28>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203846:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203848:	bfffc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020384c <mm_create>:
mm_create(void) {
ffffffffc020384c:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020384e:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0203852:	e022                	sd	s0,0(sp)
ffffffffc0203854:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203856:	feffd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc020385a:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020385c:	c105                	beqz	a0,ffffffffc020387c <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc020385e:	e408                	sd	a0,8(s0)
ffffffffc0203860:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0203862:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203866:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020386a:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020386e:	00012797          	auipc	a5,0x12
ffffffffc0203872:	d2a7a783          	lw	a5,-726(a5) # ffffffffc0215598 <swap_init_ok>
ffffffffc0203876:	eb81                	bnez	a5,ffffffffc0203886 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc0203878:	02053423          	sd	zero,40(a0)
}
ffffffffc020387c:	60a2                	ld	ra,8(sp)
ffffffffc020387e:	8522                	mv	a0,s0
ffffffffc0203880:	6402                	ld	s0,0(sp)
ffffffffc0203882:	0141                	addi	sp,sp,16
ffffffffc0203884:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203886:	a0fff0ef          	jal	ra,ffffffffc0203294 <swap_init_mm>
}
ffffffffc020388a:	60a2                	ld	ra,8(sp)
ffffffffc020388c:	8522                	mv	a0,s0
ffffffffc020388e:	6402                	ld	s0,0(sp)
ffffffffc0203890:	0141                	addi	sp,sp,16
ffffffffc0203892:	8082                	ret

ffffffffc0203894 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0203894:	1101                	addi	sp,sp,-32
ffffffffc0203896:	e04a                	sd	s2,0(sp)
ffffffffc0203898:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020389a:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020389e:	e822                	sd	s0,16(sp)
ffffffffc02038a0:	e426                	sd	s1,8(sp)
ffffffffc02038a2:	ec06                	sd	ra,24(sp)
ffffffffc02038a4:	84ae                	mv	s1,a1
ffffffffc02038a6:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038a8:	f9dfd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
    if (vma != NULL) {
ffffffffc02038ac:	c509                	beqz	a0,ffffffffc02038b6 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02038ae:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02038b2:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038b4:	cd00                	sw	s0,24(a0)
}
ffffffffc02038b6:	60e2                	ld	ra,24(sp)
ffffffffc02038b8:	6442                	ld	s0,16(sp)
ffffffffc02038ba:	64a2                	ld	s1,8(sp)
ffffffffc02038bc:	6902                	ld	s2,0(sp)
ffffffffc02038be:	6105                	addi	sp,sp,32
ffffffffc02038c0:	8082                	ret

ffffffffc02038c2 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02038c2:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02038c4:	c505                	beqz	a0,ffffffffc02038ec <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02038c6:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02038c8:	c501                	beqz	a0,ffffffffc02038d0 <find_vma+0xe>
ffffffffc02038ca:	651c                	ld	a5,8(a0)
ffffffffc02038cc:	02f5f263          	bgeu	a1,a5,ffffffffc02038f0 <find_vma+0x2e>
    return listelm->next;
ffffffffc02038d0:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc02038d2:	00f68d63          	beq	a3,a5,ffffffffc02038ec <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02038d6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02038da:	00e5e663          	bltu	a1,a4,ffffffffc02038e6 <find_vma+0x24>
ffffffffc02038de:	ff07b703          	ld	a4,-16(a5)
ffffffffc02038e2:	00e5ec63          	bltu	a1,a4,ffffffffc02038fa <find_vma+0x38>
ffffffffc02038e6:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02038e8:	fef697e3          	bne	a3,a5,ffffffffc02038d6 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02038ec:	4501                	li	a0,0
}
ffffffffc02038ee:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02038f0:	691c                	ld	a5,16(a0)
ffffffffc02038f2:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02038d0 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02038f6:	ea88                	sd	a0,16(a3)
ffffffffc02038f8:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02038fa:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02038fe:	ea88                	sd	a0,16(a3)
ffffffffc0203900:	8082                	ret

ffffffffc0203902 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203902:	6590                	ld	a2,8(a1)
ffffffffc0203904:	0105b803          	ld	a6,16(a1) # 1010 <kern_entry-0xffffffffc01feff0>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0203908:	1141                	addi	sp,sp,-16
ffffffffc020390a:	e406                	sd	ra,8(sp)
ffffffffc020390c:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020390e:	01066763          	bltu	a2,a6,ffffffffc020391c <insert_vma_struct+0x1a>
ffffffffc0203912:	a085                	j	ffffffffc0203972 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0203914:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203918:	04e66863          	bltu	a2,a4,ffffffffc0203968 <insert_vma_struct+0x66>
ffffffffc020391c:	86be                	mv	a3,a5
ffffffffc020391e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0203920:	fef51ae3          	bne	a0,a5,ffffffffc0203914 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0203924:	02a68463          	beq	a3,a0,ffffffffc020394c <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203928:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020392c:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203930:	08e8f163          	bgeu	a7,a4,ffffffffc02039b2 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203934:	04e66f63          	bltu	a2,a4,ffffffffc0203992 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0203938:	00f50a63          	beq	a0,a5,ffffffffc020394c <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc020393c:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203940:	05076963          	bltu	a4,a6,ffffffffc0203992 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203944:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203948:	02c77363          	bgeu	a4,a2,ffffffffc020396e <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020394c:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020394e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203950:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203954:	e390                	sd	a2,0(a5)
ffffffffc0203956:	e690                	sd	a2,8(a3)
}
ffffffffc0203958:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020395a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020395c:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc020395e:	0017079b          	addiw	a5,a4,1
ffffffffc0203962:	d11c                	sw	a5,32(a0)
}
ffffffffc0203964:	0141                	addi	sp,sp,16
ffffffffc0203966:	8082                	ret
    if (le_prev != list) {
ffffffffc0203968:	fca690e3          	bne	a3,a0,ffffffffc0203928 <insert_vma_struct+0x26>
ffffffffc020396c:	bfd1                	j	ffffffffc0203940 <insert_vma_struct+0x3e>
ffffffffc020396e:	ebbff0ef          	jal	ra,ffffffffc0203828 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203972:	00003697          	auipc	a3,0x3
ffffffffc0203976:	e5668693          	addi	a3,a3,-426 # ffffffffc02067c8 <default_pmm_manager+0xc38>
ffffffffc020397a:	00002617          	auipc	a2,0x2
ffffffffc020397e:	e6660613          	addi	a2,a2,-410 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203982:	08500593          	li	a1,133
ffffffffc0203986:	00003517          	auipc	a0,0x3
ffffffffc020398a:	e3250513          	addi	a0,a0,-462 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc020398e:	ab9fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203992:	00003697          	auipc	a3,0x3
ffffffffc0203996:	e7668693          	addi	a3,a3,-394 # ffffffffc0206808 <default_pmm_manager+0xc78>
ffffffffc020399a:	00002617          	auipc	a2,0x2
ffffffffc020399e:	e4660613          	addi	a2,a2,-442 # ffffffffc02057e0 <commands+0x738>
ffffffffc02039a2:	07d00593          	li	a1,125
ffffffffc02039a6:	00003517          	auipc	a0,0x3
ffffffffc02039aa:	e1250513          	addi	a0,a0,-494 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc02039ae:	a99fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039b2:	00003697          	auipc	a3,0x3
ffffffffc02039b6:	e3668693          	addi	a3,a3,-458 # ffffffffc02067e8 <default_pmm_manager+0xc58>
ffffffffc02039ba:	00002617          	auipc	a2,0x2
ffffffffc02039be:	e2660613          	addi	a2,a2,-474 # ffffffffc02057e0 <commands+0x738>
ffffffffc02039c2:	07c00593          	li	a1,124
ffffffffc02039c6:	00003517          	auipc	a0,0x3
ffffffffc02039ca:	df250513          	addi	a0,a0,-526 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc02039ce:	a79fc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc02039d2 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc02039d2:	1141                	addi	sp,sp,-16
ffffffffc02039d4:	e022                	sd	s0,0(sp)
ffffffffc02039d6:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02039d8:	6508                	ld	a0,8(a0)
ffffffffc02039da:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02039dc:	00a40c63          	beq	s0,a0,ffffffffc02039f4 <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc02039e0:	6118                	ld	a4,0(a0)
ffffffffc02039e2:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02039e4:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02039e6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02039e8:	e398                	sd	a4,0(a5)
ffffffffc02039ea:	f0bfd0ef          	jal	ra,ffffffffc02018f4 <kfree>
    return listelm->next;
ffffffffc02039ee:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02039f0:	fea418e3          	bne	s0,a0,ffffffffc02039e0 <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
ffffffffc02039f4:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02039f6:	6402                	ld	s0,0(sp)
ffffffffc02039f8:	60a2                	ld	ra,8(sp)
ffffffffc02039fa:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02039fc:	ef9fd06f          	j	ffffffffc02018f4 <kfree>

ffffffffc0203a00 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203a00:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a02:	03000513          	li	a0,48
vmm_init(void) {
ffffffffc0203a06:	fc06                	sd	ra,56(sp)
ffffffffc0203a08:	f822                	sd	s0,48(sp)
ffffffffc0203a0a:	f426                	sd	s1,40(sp)
ffffffffc0203a0c:	f04a                	sd	s2,32(sp)
ffffffffc0203a0e:	ec4e                	sd	s3,24(sp)
ffffffffc0203a10:	e852                	sd	s4,16(sp)
ffffffffc0203a12:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a14:	e31fd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
    if (mm != NULL) {
ffffffffc0203a18:	58050e63          	beqz	a0,ffffffffc0203fb4 <vmm_init+0x5b4>
    elm->prev = elm->next = elm;
ffffffffc0203a1c:	e508                	sd	a0,8(a0)
ffffffffc0203a1e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a20:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a24:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a28:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a2c:	00012797          	auipc	a5,0x12
ffffffffc0203a30:	b6c7a783          	lw	a5,-1172(a5) # ffffffffc0215598 <swap_init_ok>
ffffffffc0203a34:	84aa                	mv	s1,a0
ffffffffc0203a36:	e7b9                	bnez	a5,ffffffffc0203a84 <vmm_init+0x84>
        else mm->sm_priv = NULL;
ffffffffc0203a38:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0203a3c:	03200413          	li	s0,50
ffffffffc0203a40:	a811                	j	ffffffffc0203a54 <vmm_init+0x54>
        vma->vm_start = vm_start;
ffffffffc0203a42:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a44:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a46:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0203a4a:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a4c:	8526                	mv	a0,s1
ffffffffc0203a4e:	eb5ff0ef          	jal	ra,ffffffffc0203902 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0203a52:	cc05                	beqz	s0,ffffffffc0203a8a <vmm_init+0x8a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a54:	03000513          	li	a0,48
ffffffffc0203a58:	dedfd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc0203a5c:	85aa                	mv	a1,a0
ffffffffc0203a5e:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0203a62:	f165                	bnez	a0,ffffffffc0203a42 <vmm_init+0x42>
        assert(vma != NULL);
ffffffffc0203a64:	00003697          	auipc	a3,0x3
ffffffffc0203a68:	87468693          	addi	a3,a3,-1932 # ffffffffc02062d8 <default_pmm_manager+0x748>
ffffffffc0203a6c:	00002617          	auipc	a2,0x2
ffffffffc0203a70:	d7460613          	addi	a2,a2,-652 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203a74:	0c900593          	li	a1,201
ffffffffc0203a78:	00003517          	auipc	a0,0x3
ffffffffc0203a7c:	d4050513          	addi	a0,a0,-704 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203a80:	9c7fc0ef          	jal	ra,ffffffffc0200446 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a84:	811ff0ef          	jal	ra,ffffffffc0203294 <swap_init_mm>
ffffffffc0203a88:	bf55                	j	ffffffffc0203a3c <vmm_init+0x3c>
ffffffffc0203a8a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203a8e:	1f900913          	li	s2,505
ffffffffc0203a92:	a819                	j	ffffffffc0203aa8 <vmm_init+0xa8>
        vma->vm_start = vm_start;
ffffffffc0203a94:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a96:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a98:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203a9c:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a9e:	8526                	mv	a0,s1
ffffffffc0203aa0:	e63ff0ef          	jal	ra,ffffffffc0203902 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203aa4:	03240a63          	beq	s0,s2,ffffffffc0203ad8 <vmm_init+0xd8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aa8:	03000513          	li	a0,48
ffffffffc0203aac:	d99fd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc0203ab0:	85aa                	mv	a1,a0
ffffffffc0203ab2:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0203ab6:	fd79                	bnez	a0,ffffffffc0203a94 <vmm_init+0x94>
        assert(vma != NULL);
ffffffffc0203ab8:	00003697          	auipc	a3,0x3
ffffffffc0203abc:	82068693          	addi	a3,a3,-2016 # ffffffffc02062d8 <default_pmm_manager+0x748>
ffffffffc0203ac0:	00002617          	auipc	a2,0x2
ffffffffc0203ac4:	d2060613          	addi	a2,a2,-736 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203ac8:	0cf00593          	li	a1,207
ffffffffc0203acc:	00003517          	auipc	a0,0x3
ffffffffc0203ad0:	cec50513          	addi	a0,a0,-788 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203ad4:	973fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    return listelm->next;
ffffffffc0203ad8:	649c                	ld	a5,8(s1)
ffffffffc0203ada:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0203adc:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0203ae0:	30f48e63          	beq	s1,a5,ffffffffc0203dfc <vmm_init+0x3fc>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ae4:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203ae8:	ffe70613          	addi	a2,a4,-2
ffffffffc0203aec:	2ad61863          	bne	a2,a3,ffffffffc0203d9c <vmm_init+0x39c>
ffffffffc0203af0:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203af4:	2ae69463          	bne	a3,a4,ffffffffc0203d9c <vmm_init+0x39c>
    for (i = 1; i <= step2; i ++) {
ffffffffc0203af8:	0715                	addi	a4,a4,5
ffffffffc0203afa:	679c                	ld	a5,8(a5)
ffffffffc0203afc:	feb712e3          	bne	a4,a1,ffffffffc0203ae0 <vmm_init+0xe0>
ffffffffc0203b00:	4a1d                	li	s4,7
ffffffffc0203b02:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203b04:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b08:	85a2                	mv	a1,s0
ffffffffc0203b0a:	8526                	mv	a0,s1
ffffffffc0203b0c:	db7ff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
ffffffffc0203b10:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203b12:	34050563          	beqz	a0,ffffffffc0203e5c <vmm_init+0x45c>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203b16:	00140593          	addi	a1,s0,1
ffffffffc0203b1a:	8526                	mv	a0,s1
ffffffffc0203b1c:	da7ff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
ffffffffc0203b20:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b22:	34050d63          	beqz	a0,ffffffffc0203e7c <vmm_init+0x47c>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203b26:	85d2                	mv	a1,s4
ffffffffc0203b28:	8526                	mv	a0,s1
ffffffffc0203b2a:	d99ff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b2e:	36051763          	bnez	a0,ffffffffc0203e9c <vmm_init+0x49c>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203b32:	00340593          	addi	a1,s0,3
ffffffffc0203b36:	8526                	mv	a0,s1
ffffffffc0203b38:	d8bff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b3c:	2e051063          	bnez	a0,ffffffffc0203e1c <vmm_init+0x41c>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0203b40:	00440593          	addi	a1,s0,4
ffffffffc0203b44:	8526                	mv	a0,s1
ffffffffc0203b46:	d7dff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b4a:	2e051963          	bnez	a0,ffffffffc0203e3c <vmm_init+0x43c>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203b4e:	00893783          	ld	a5,8(s2)
ffffffffc0203b52:	26879563          	bne	a5,s0,ffffffffc0203dbc <vmm_init+0x3bc>
ffffffffc0203b56:	01093783          	ld	a5,16(s2)
ffffffffc0203b5a:	27479163          	bne	a5,s4,ffffffffc0203dbc <vmm_init+0x3bc>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203b5e:	0089b783          	ld	a5,8(s3)
ffffffffc0203b62:	26879d63          	bne	a5,s0,ffffffffc0203ddc <vmm_init+0x3dc>
ffffffffc0203b66:	0109b783          	ld	a5,16(s3)
ffffffffc0203b6a:	27479963          	bne	a5,s4,ffffffffc0203ddc <vmm_init+0x3dc>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203b6e:	0415                	addi	s0,s0,5
ffffffffc0203b70:	0a15                	addi	s4,s4,5
ffffffffc0203b72:	f9541be3          	bne	s0,s5,ffffffffc0203b08 <vmm_init+0x108>
ffffffffc0203b76:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0203b78:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0203b7a:	85a2                	mv	a1,s0
ffffffffc0203b7c:	8526                	mv	a0,s1
ffffffffc0203b7e:	d45ff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
ffffffffc0203b82:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0203b86:	c90d                	beqz	a0,ffffffffc0203bb8 <vmm_init+0x1b8>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203b88:	6914                	ld	a3,16(a0)
ffffffffc0203b8a:	6510                	ld	a2,8(a0)
ffffffffc0203b8c:	00003517          	auipc	a0,0x3
ffffffffc0203b90:	d9c50513          	addi	a0,a0,-612 # ffffffffc0206928 <default_pmm_manager+0xd98>
ffffffffc0203b94:	decfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b98:	00003697          	auipc	a3,0x3
ffffffffc0203b9c:	db868693          	addi	a3,a3,-584 # ffffffffc0206950 <default_pmm_manager+0xdc0>
ffffffffc0203ba0:	00002617          	auipc	a2,0x2
ffffffffc0203ba4:	c4060613          	addi	a2,a2,-960 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203ba8:	0f100593          	li	a1,241
ffffffffc0203bac:	00003517          	auipc	a0,0x3
ffffffffc0203bb0:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203bb4:	893fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0203bb8:	147d                	addi	s0,s0,-1
ffffffffc0203bba:	fd2410e3          	bne	s0,s2,ffffffffc0203b7a <vmm_init+0x17a>
ffffffffc0203bbe:	a801                	j	ffffffffc0203bce <vmm_init+0x1ce>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203bc0:	6118                	ld	a4,0(a0)
ffffffffc0203bc2:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0203bc4:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203bc6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203bc8:	e398                	sd	a4,0(a5)
ffffffffc0203bca:	d2bfd0ef          	jal	ra,ffffffffc02018f4 <kfree>
    return listelm->next;
ffffffffc0203bce:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc0203bd0:	fea498e3          	bne	s1,a0,ffffffffc0203bc0 <vmm_init+0x1c0>
    kfree(mm); //kfree mm
ffffffffc0203bd4:	8526                	mv	a0,s1
ffffffffc0203bd6:	d1ffd0ef          	jal	ra,ffffffffc02018f4 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bda:	00003517          	auipc	a0,0x3
ffffffffc0203bde:	d8e50513          	addi	a0,a0,-626 # ffffffffc0206968 <default_pmm_manager+0xdd8>
ffffffffc0203be2:	d9efc0ef          	jal	ra,ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203be6:	f0ffd0ef          	jal	ra,ffffffffc0201af4 <nr_free_pages>
ffffffffc0203bea:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203bec:	03000513          	li	a0,48
ffffffffc0203bf0:	c55fd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc0203bf4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203bf6:	2c050363          	beqz	a0,ffffffffc0203ebc <vmm_init+0x4bc>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203bfa:	00012797          	auipc	a5,0x12
ffffffffc0203bfe:	99e7a783          	lw	a5,-1634(a5) # ffffffffc0215598 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0203c02:	e508                	sd	a0,8(a0)
ffffffffc0203c04:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203c06:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203c0a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203c0e:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203c12:	18079263          	bnez	a5,ffffffffc0203d96 <vmm_init+0x396>
        else mm->sm_priv = NULL;
ffffffffc0203c16:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203c1a:	00012917          	auipc	s2,0x12
ffffffffc0203c1e:	94693903          	ld	s2,-1722(s2) # ffffffffc0215560 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0203c22:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0203c26:	00012717          	auipc	a4,0x12
ffffffffc0203c2a:	96873d23          	sd	s0,-1670(a4) # ffffffffc02155a0 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203c2e:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0203c32:	36079163          	bnez	a5,ffffffffc0203f94 <vmm_init+0x594>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c36:	03000513          	li	a0,48
ffffffffc0203c3a:	c0bfd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc0203c3e:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0203c40:	2a050263          	beqz	a0,ffffffffc0203ee4 <vmm_init+0x4e4>
        vma->vm_end = vm_end;
ffffffffc0203c44:	002007b7          	lui	a5,0x200
ffffffffc0203c48:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc0203c4c:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203c4e:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0203c50:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0203c54:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0203c56:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0203c5a:	ca9ff0ef          	jal	ra,ffffffffc0203902 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203c5e:	10000593          	li	a1,256
ffffffffc0203c62:	8522                	mv	a0,s0
ffffffffc0203c64:	c5fff0ef          	jal	ra,ffffffffc02038c2 <find_vma>
ffffffffc0203c68:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0203c6c:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203c70:	28a99a63          	bne	s3,a0,ffffffffc0203f04 <vmm_init+0x504>
        *(char *)(addr + i) = i;
ffffffffc0203c74:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0203c78:	0785                	addi	a5,a5,1
ffffffffc0203c7a:	fee79de3          	bne	a5,a4,ffffffffc0203c74 <vmm_init+0x274>
        sum += i;
ffffffffc0203c7e:	6705                	lui	a4,0x1
ffffffffc0203c80:	10000793          	li	a5,256
ffffffffc0203c84:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0203c88:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0203c8c:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0203c90:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0203c92:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0203c94:	fec79ce3          	bne	a5,a2,ffffffffc0203c8c <vmm_init+0x28c>
    }
    assert(sum == 0);
ffffffffc0203c98:	28071663          	bnez	a4,ffffffffc0203f24 <vmm_init+0x524>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c9c:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203ca0:	00012a97          	auipc	s5,0x12
ffffffffc0203ca4:	8c8a8a93          	addi	s5,s5,-1848 # ffffffffc0215568 <npage>
ffffffffc0203ca8:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203cac:	078a                	slli	a5,a5,0x2
ffffffffc0203cae:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203cb0:	28c7fa63          	bgeu	a5,a2,ffffffffc0203f44 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0203cb4:	00003a17          	auipc	s4,0x3
ffffffffc0203cb8:	234a3a03          	ld	s4,564(s4) # ffffffffc0206ee8 <nbase>
ffffffffc0203cbc:	414787b3          	sub	a5,a5,s4
ffffffffc0203cc0:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0203cc2:	8799                	srai	a5,a5,0x6
ffffffffc0203cc4:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0203cc6:	00c79713          	slli	a4,a5,0xc
ffffffffc0203cca:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203ccc:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203cd0:	28c77663          	bgeu	a4,a2,ffffffffc0203f5c <vmm_init+0x55c>
ffffffffc0203cd4:	00012997          	auipc	s3,0x12
ffffffffc0203cd8:	8ac9b983          	ld	s3,-1876(s3) # ffffffffc0215580 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0203cdc:	4581                	li	a1,0
ffffffffc0203cde:	854a                	mv	a0,s2
ffffffffc0203ce0:	99b6                	add	s3,s3,a3
ffffffffc0203ce2:	872fe0ef          	jal	ra,ffffffffc0201d54 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203ce6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0203cea:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203cee:	078a                	slli	a5,a5,0x2
ffffffffc0203cf0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203cf2:	24e7f963          	bgeu	a5,a4,ffffffffc0203f44 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0203cf6:	00012997          	auipc	s3,0x12
ffffffffc0203cfa:	87a98993          	addi	s3,s3,-1926 # ffffffffc0215570 <pages>
ffffffffc0203cfe:	0009b503          	ld	a0,0(s3)
ffffffffc0203d02:	414787b3          	sub	a5,a5,s4
ffffffffc0203d06:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0203d08:	953e                	add	a0,a0,a5
ffffffffc0203d0a:	4585                	li	a1,1
ffffffffc0203d0c:	da9fd0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d10:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203d14:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203d18:	078a                	slli	a5,a5,0x2
ffffffffc0203d1a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203d1c:	22e7f463          	bgeu	a5,a4,ffffffffc0203f44 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d20:	0009b503          	ld	a0,0(s3)
ffffffffc0203d24:	414787b3          	sub	a5,a5,s4
ffffffffc0203d28:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0203d2a:	4585                	li	a1,1
ffffffffc0203d2c:	953e                	add	a0,a0,a5
ffffffffc0203d2e:	d87fd0ef          	jal	ra,ffffffffc0201ab4 <free_pages>
    pgdir[0] = 0;
ffffffffc0203d32:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0203d36:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203d3a:	6408                	ld	a0,8(s0)
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0203d3c:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203d40:	00a40c63          	beq	s0,a0,ffffffffc0203d58 <vmm_init+0x358>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203d44:	6118                	ld	a4,0(a0)
ffffffffc0203d46:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0203d48:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203d4a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203d4c:	e398                	sd	a4,0(a5)
ffffffffc0203d4e:	ba7fd0ef          	jal	ra,ffffffffc02018f4 <kfree>
    return listelm->next;
ffffffffc0203d52:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203d54:	fea418e3          	bne	s0,a0,ffffffffc0203d44 <vmm_init+0x344>
    kfree(mm); //kfree mm
ffffffffc0203d58:	8522                	mv	a0,s0
ffffffffc0203d5a:	b9bfd0ef          	jal	ra,ffffffffc02018f4 <kfree>
    mm_destroy(mm);
    check_mm_struct = NULL;
ffffffffc0203d5e:	00012797          	auipc	a5,0x12
ffffffffc0203d62:	8407b123          	sd	zero,-1982(a5) # ffffffffc02155a0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203d66:	d8ffd0ef          	jal	ra,ffffffffc0201af4 <nr_free_pages>
ffffffffc0203d6a:	20a49563          	bne	s1,a0,ffffffffc0203f74 <vmm_init+0x574>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203d6e:	00003517          	auipc	a0,0x3
ffffffffc0203d72:	c7250513          	addi	a0,a0,-910 # ffffffffc02069e0 <default_pmm_manager+0xe50>
ffffffffc0203d76:	c0afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0203d7a:	7442                	ld	s0,48(sp)
ffffffffc0203d7c:	70e2                	ld	ra,56(sp)
ffffffffc0203d7e:	74a2                	ld	s1,40(sp)
ffffffffc0203d80:	7902                	ld	s2,32(sp)
ffffffffc0203d82:	69e2                	ld	s3,24(sp)
ffffffffc0203d84:	6a42                	ld	s4,16(sp)
ffffffffc0203d86:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d88:	00003517          	auipc	a0,0x3
ffffffffc0203d8c:	c7850513          	addi	a0,a0,-904 # ffffffffc0206a00 <default_pmm_manager+0xe70>
}
ffffffffc0203d90:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d92:	beefc06f          	j	ffffffffc0200180 <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203d96:	cfeff0ef          	jal	ra,ffffffffc0203294 <swap_init_mm>
ffffffffc0203d9a:	b541                	j	ffffffffc0203c1a <vmm_init+0x21a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d9c:	00003697          	auipc	a3,0x3
ffffffffc0203da0:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206840 <default_pmm_manager+0xcb0>
ffffffffc0203da4:	00002617          	auipc	a2,0x2
ffffffffc0203da8:	a3c60613          	addi	a2,a2,-1476 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203dac:	0d800593          	li	a1,216
ffffffffc0203db0:	00003517          	auipc	a0,0x3
ffffffffc0203db4:	a0850513          	addi	a0,a0,-1528 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203db8:	e8efc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203dbc:	00003697          	auipc	a3,0x3
ffffffffc0203dc0:	b0c68693          	addi	a3,a3,-1268 # ffffffffc02068c8 <default_pmm_manager+0xd38>
ffffffffc0203dc4:	00002617          	auipc	a2,0x2
ffffffffc0203dc8:	a1c60613          	addi	a2,a2,-1508 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203dcc:	0e800593          	li	a1,232
ffffffffc0203dd0:	00003517          	auipc	a0,0x3
ffffffffc0203dd4:	9e850513          	addi	a0,a0,-1560 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203dd8:	e6efc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203ddc:	00003697          	auipc	a3,0x3
ffffffffc0203de0:	b1c68693          	addi	a3,a3,-1252 # ffffffffc02068f8 <default_pmm_manager+0xd68>
ffffffffc0203de4:	00002617          	auipc	a2,0x2
ffffffffc0203de8:	9fc60613          	addi	a2,a2,-1540 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203dec:	0e900593          	li	a1,233
ffffffffc0203df0:	00003517          	auipc	a0,0x3
ffffffffc0203df4:	9c850513          	addi	a0,a0,-1592 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203df8:	e4efc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203dfc:	00003697          	auipc	a3,0x3
ffffffffc0203e00:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0206828 <default_pmm_manager+0xc98>
ffffffffc0203e04:	00002617          	auipc	a2,0x2
ffffffffc0203e08:	9dc60613          	addi	a2,a2,-1572 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203e0c:	0d600593          	li	a1,214
ffffffffc0203e10:	00003517          	auipc	a0,0x3
ffffffffc0203e14:	9a850513          	addi	a0,a0,-1624 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203e18:	e2efc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203e1c:	00003697          	auipc	a3,0x3
ffffffffc0203e20:	a8c68693          	addi	a3,a3,-1396 # ffffffffc02068a8 <default_pmm_manager+0xd18>
ffffffffc0203e24:	00002617          	auipc	a2,0x2
ffffffffc0203e28:	9bc60613          	addi	a2,a2,-1604 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203e2c:	0e400593          	li	a1,228
ffffffffc0203e30:	00003517          	auipc	a0,0x3
ffffffffc0203e34:	98850513          	addi	a0,a0,-1656 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203e38:	e0efc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203e3c:	00003697          	auipc	a3,0x3
ffffffffc0203e40:	a7c68693          	addi	a3,a3,-1412 # ffffffffc02068b8 <default_pmm_manager+0xd28>
ffffffffc0203e44:	00002617          	auipc	a2,0x2
ffffffffc0203e48:	99c60613          	addi	a2,a2,-1636 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203e4c:	0e600593          	li	a1,230
ffffffffc0203e50:	00003517          	auipc	a0,0x3
ffffffffc0203e54:	96850513          	addi	a0,a0,-1688 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203e58:	deefc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203e5c:	00003697          	auipc	a3,0x3
ffffffffc0203e60:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206878 <default_pmm_manager+0xce8>
ffffffffc0203e64:	00002617          	auipc	a2,0x2
ffffffffc0203e68:	97c60613          	addi	a2,a2,-1668 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203e6c:	0de00593          	li	a1,222
ffffffffc0203e70:	00003517          	auipc	a0,0x3
ffffffffc0203e74:	94850513          	addi	a0,a0,-1720 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203e78:	dcefc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203e7c:	00003697          	auipc	a3,0x3
ffffffffc0203e80:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0206888 <default_pmm_manager+0xcf8>
ffffffffc0203e84:	00002617          	auipc	a2,0x2
ffffffffc0203e88:	95c60613          	addi	a2,a2,-1700 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203e8c:	0e000593          	li	a1,224
ffffffffc0203e90:	00003517          	auipc	a0,0x3
ffffffffc0203e94:	92850513          	addi	a0,a0,-1752 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203e98:	daefc0ef          	jal	ra,ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203e9c:	00003697          	auipc	a3,0x3
ffffffffc0203ea0:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0206898 <default_pmm_manager+0xd08>
ffffffffc0203ea4:	00002617          	auipc	a2,0x2
ffffffffc0203ea8:	93c60613          	addi	a2,a2,-1732 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203eac:	0e200593          	li	a1,226
ffffffffc0203eb0:	00003517          	auipc	a0,0x3
ffffffffc0203eb4:	90850513          	addi	a0,a0,-1784 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203eb8:	d8efc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203ebc:	00003697          	auipc	a3,0x3
ffffffffc0203ec0:	b5c68693          	addi	a3,a3,-1188 # ffffffffc0206a18 <default_pmm_manager+0xe88>
ffffffffc0203ec4:	00002617          	auipc	a2,0x2
ffffffffc0203ec8:	91c60613          	addi	a2,a2,-1764 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203ecc:	10100593          	li	a1,257
ffffffffc0203ed0:	00003517          	auipc	a0,0x3
ffffffffc0203ed4:	8e850513          	addi	a0,a0,-1816 # ffffffffc02067b8 <default_pmm_manager+0xc28>
    check_mm_struct = mm_create();
ffffffffc0203ed8:	00011797          	auipc	a5,0x11
ffffffffc0203edc:	6c07b423          	sd	zero,1736(a5) # ffffffffc02155a0 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc0203ee0:	d66fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(vma != NULL);
ffffffffc0203ee4:	00002697          	auipc	a3,0x2
ffffffffc0203ee8:	3f468693          	addi	a3,a3,1012 # ffffffffc02062d8 <default_pmm_manager+0x748>
ffffffffc0203eec:	00002617          	auipc	a2,0x2
ffffffffc0203ef0:	8f460613          	addi	a2,a2,-1804 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203ef4:	10800593          	li	a1,264
ffffffffc0203ef8:	00003517          	auipc	a0,0x3
ffffffffc0203efc:	8c050513          	addi	a0,a0,-1856 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203f00:	d46fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f04:	00003697          	auipc	a3,0x3
ffffffffc0203f08:	a8468693          	addi	a3,a3,-1404 # ffffffffc0206988 <default_pmm_manager+0xdf8>
ffffffffc0203f0c:	00002617          	auipc	a2,0x2
ffffffffc0203f10:	8d460613          	addi	a2,a2,-1836 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203f14:	10d00593          	li	a1,269
ffffffffc0203f18:	00003517          	auipc	a0,0x3
ffffffffc0203f1c:	8a050513          	addi	a0,a0,-1888 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203f20:	d26fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(sum == 0);
ffffffffc0203f24:	00003697          	auipc	a3,0x3
ffffffffc0203f28:	a8468693          	addi	a3,a3,-1404 # ffffffffc02069a8 <default_pmm_manager+0xe18>
ffffffffc0203f2c:	00002617          	auipc	a2,0x2
ffffffffc0203f30:	8b460613          	addi	a2,a2,-1868 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203f34:	11700593          	li	a1,279
ffffffffc0203f38:	00003517          	auipc	a0,0x3
ffffffffc0203f3c:	88050513          	addi	a0,a0,-1920 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203f40:	d06fc0ef          	jal	ra,ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f44:	00002617          	auipc	a2,0x2
ffffffffc0203f48:	d5460613          	addi	a2,a2,-684 # ffffffffc0205c98 <default_pmm_manager+0x108>
ffffffffc0203f4c:	06200593          	li	a1,98
ffffffffc0203f50:	00002517          	auipc	a0,0x2
ffffffffc0203f54:	ca050513          	addi	a0,a0,-864 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0203f58:	ceefc0ef          	jal	ra,ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203f5c:	00002617          	auipc	a2,0x2
ffffffffc0203f60:	c6c60613          	addi	a2,a2,-916 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0203f64:	06900593          	li	a1,105
ffffffffc0203f68:	00002517          	auipc	a0,0x2
ffffffffc0203f6c:	c8850513          	addi	a0,a0,-888 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0203f70:	cd6fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203f74:	00003697          	auipc	a3,0x3
ffffffffc0203f78:	a4468693          	addi	a3,a3,-1468 # ffffffffc02069b8 <default_pmm_manager+0xe28>
ffffffffc0203f7c:	00002617          	auipc	a2,0x2
ffffffffc0203f80:	86460613          	addi	a2,a2,-1948 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203f84:	12400593          	li	a1,292
ffffffffc0203f88:	00003517          	auipc	a0,0x3
ffffffffc0203f8c:	83050513          	addi	a0,a0,-2000 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203f90:	cb6fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203f94:	00002697          	auipc	a3,0x2
ffffffffc0203f98:	33468693          	addi	a3,a3,820 # ffffffffc02062c8 <default_pmm_manager+0x738>
ffffffffc0203f9c:	00002617          	auipc	a2,0x2
ffffffffc0203fa0:	84460613          	addi	a2,a2,-1980 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203fa4:	10500593          	li	a1,261
ffffffffc0203fa8:	00003517          	auipc	a0,0x3
ffffffffc0203fac:	81050513          	addi	a0,a0,-2032 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203fb0:	c96fc0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203fb4:	00002697          	auipc	a3,0x2
ffffffffc0203fb8:	2ec68693          	addi	a3,a3,748 # ffffffffc02062a0 <default_pmm_manager+0x710>
ffffffffc0203fbc:	00002617          	auipc	a2,0x2
ffffffffc0203fc0:	82460613          	addi	a2,a2,-2012 # ffffffffc02057e0 <commands+0x738>
ffffffffc0203fc4:	0c200593          	li	a1,194
ffffffffc0203fc8:	00002517          	auipc	a0,0x2
ffffffffc0203fcc:	7f050513          	addi	a0,a0,2032 # ffffffffc02067b8 <default_pmm_manager+0xc28>
ffffffffc0203fd0:	c76fc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0203fd4 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203fd4:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203fd6:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203fd8:	f822                	sd	s0,48(sp)
ffffffffc0203fda:	f426                	sd	s1,40(sp)
ffffffffc0203fdc:	fc06                	sd	ra,56(sp)
ffffffffc0203fde:	f04a                	sd	s2,32(sp)
ffffffffc0203fe0:	ec4e                	sd	s3,24(sp)
ffffffffc0203fe2:	8432                	mv	s0,a2
ffffffffc0203fe4:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203fe6:	8ddff0ef          	jal	ra,ffffffffc02038c2 <find_vma>

    pgfault_num++;
ffffffffc0203fea:	00011797          	auipc	a5,0x11
ffffffffc0203fee:	5be7a783          	lw	a5,1470(a5) # ffffffffc02155a8 <pgfault_num>
ffffffffc0203ff2:	2785                	addiw	a5,a5,1
ffffffffc0203ff4:	00011717          	auipc	a4,0x11
ffffffffc0203ff8:	5af72a23          	sw	a5,1460(a4) # ffffffffc02155a8 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203ffc:	c545                	beqz	a0,ffffffffc02040a4 <do_pgfault+0xd0>
ffffffffc0203ffe:	651c                	ld	a5,8(a0)
ffffffffc0204000:	0af46263          	bltu	s0,a5,ffffffffc02040a4 <do_pgfault+0xd0>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204004:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0204006:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204008:	8b89                	andi	a5,a5,2
ffffffffc020400a:	efb1                	bnez	a5,ffffffffc0204066 <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020400c:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020400e:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204010:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204012:	4605                	li	a2,1
ffffffffc0204014:	85a2                	mv	a1,s0
ffffffffc0204016:	b19fd0ef          	jal	ra,ffffffffc0201b2e <get_pte>
ffffffffc020401a:	c555                	beqz	a0,ffffffffc02040c6 <do_pgfault+0xf2>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc020401c:	610c                	ld	a1,0(a0)
ffffffffc020401e:	c5a5                	beqz	a1,ffffffffc0204086 <do_pgfault+0xb2>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0204020:	00011797          	auipc	a5,0x11
ffffffffc0204024:	5787a783          	lw	a5,1400(a5) # ffffffffc0215598 <swap_init_ok>
ffffffffc0204028:	c7d9                	beqz	a5,ffffffffc02040b6 <do_pgfault+0xe2>
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try to load the content of right disk page into the memory which page managed.
            // 将物理页换入到内存中
            ret = swap_in(mm, addr, &page);
ffffffffc020402a:	0030                	addi	a2,sp,8
ffffffffc020402c:	85a2                	mv	a1,s0
ffffffffc020402e:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204030:	e402                	sd	zero,8(sp)
            ret = swap_in(mm, addr, &page);
ffffffffc0204032:	b8eff0ef          	jal	ra,ffffffffc02033c0 <swap_in>
ffffffffc0204036:	892a                	mv	s2,a0
            if (ret != 0) {
ffffffffc0204038:	e90d                	bnez	a0,ffffffffc020406a <do_pgfault+0x96>
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }
            //(2) According to the mm,addr AND page, setup the map of phy addr <---> logical addr
            // 将物理页与虚拟页建立映射关系
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc020403a:	65a2                	ld	a1,8(sp)
ffffffffc020403c:	6c88                	ld	a0,24(s1)
ffffffffc020403e:	86ce                	mv	a3,s3
ffffffffc0204040:	8622                	mv	a2,s0
ffffffffc0204042:	daffd0ef          	jal	ra,ffffffffc0201df0 <page_insert>
            //(3) make the page swappable.
            // 设置当前的物理页为可交换页
            swap_map_swappable(mm,addr,page,1);
ffffffffc0204046:	6622                	ld	a2,8(sp)
ffffffffc0204048:	4685                	li	a3,1
ffffffffc020404a:	85a2                	mv	a1,s0
ffffffffc020404c:	8526                	mv	a0,s1
ffffffffc020404e:	a52ff0ef          	jal	ra,ffffffffc02032a0 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204052:	67a2                	ld	a5,8(sp)
ffffffffc0204054:	ff80                	sd	s0,56(a5)
   }

   ret = 0;
failed:
    return ret;
}
ffffffffc0204056:	70e2                	ld	ra,56(sp)
ffffffffc0204058:	7442                	ld	s0,48(sp)
ffffffffc020405a:	74a2                	ld	s1,40(sp)
ffffffffc020405c:	69e2                	ld	s3,24(sp)
ffffffffc020405e:	854a                	mv	a0,s2
ffffffffc0204060:	7902                	ld	s2,32(sp)
ffffffffc0204062:	6121                	addi	sp,sp,64
ffffffffc0204064:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204066:	49dd                	li	s3,23
ffffffffc0204068:	b755                	j	ffffffffc020400c <do_pgfault+0x38>
                cprintf("swap_in in do_pgfault failed\n");
ffffffffc020406a:	00003517          	auipc	a0,0x3
ffffffffc020406e:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0206aa8 <default_pmm_manager+0xf18>
ffffffffc0204072:	90efc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0204076:	70e2                	ld	ra,56(sp)
ffffffffc0204078:	7442                	ld	s0,48(sp)
ffffffffc020407a:	74a2                	ld	s1,40(sp)
ffffffffc020407c:	69e2                	ld	s3,24(sp)
ffffffffc020407e:	854a                	mv	a0,s2
ffffffffc0204080:	7902                	ld	s2,32(sp)
ffffffffc0204082:	6121                	addi	sp,sp,64
ffffffffc0204084:	8082                	ret
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204086:	6c88                	ld	a0,24(s1)
ffffffffc0204088:	864e                	mv	a2,s3
ffffffffc020408a:	85a2                	mv	a1,s0
ffffffffc020408c:	9fbfe0ef          	jal	ra,ffffffffc0202a86 <pgdir_alloc_page>
   ret = 0;
ffffffffc0204090:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204092:	f171                	bnez	a0,ffffffffc0204056 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204094:	00003517          	auipc	a0,0x3
ffffffffc0204098:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0206a80 <default_pmm_manager+0xef0>
ffffffffc020409c:	8e4fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040a0:	5971                	li	s2,-4
            goto failed;
ffffffffc02040a2:	bf55                	j	ffffffffc0204056 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02040a4:	85a2                	mv	a1,s0
ffffffffc02040a6:	00003517          	auipc	a0,0x3
ffffffffc02040aa:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206a30 <default_pmm_manager+0xea0>
ffffffffc02040ae:	8d2fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc02040b2:	5975                	li	s2,-3
        goto failed;
ffffffffc02040b4:	b74d                	j	ffffffffc0204056 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02040b6:	00003517          	auipc	a0,0x3
ffffffffc02040ba:	a1250513          	addi	a0,a0,-1518 # ffffffffc0206ac8 <default_pmm_manager+0xf38>
ffffffffc02040be:	8c2fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040c2:	5971                	li	s2,-4
            goto failed;
ffffffffc02040c4:	bf49                	j	ffffffffc0204056 <do_pgfault+0x82>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc02040c6:	00003517          	auipc	a0,0x3
ffffffffc02040ca:	99a50513          	addi	a0,a0,-1638 # ffffffffc0206a60 <default_pmm_manager+0xed0>
ffffffffc02040ce:	8b2fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02040d2:	5971                	li	s2,-4
        goto failed;
ffffffffc02040d4:	b749                	j	ffffffffc0204056 <do_pgfault+0x82>

ffffffffc02040d6 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc02040d6:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040d8:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc02040da:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040dc:	c8cfc0ef          	jal	ra,ffffffffc0200568 <ide_device_valid>
ffffffffc02040e0:	cd01                	beqz	a0,ffffffffc02040f8 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040e2:	4505                	li	a0,1
ffffffffc02040e4:	c8afc0ef          	jal	ra,ffffffffc020056e <ide_device_size>
}
ffffffffc02040e8:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040ea:	810d                	srli	a0,a0,0x3
ffffffffc02040ec:	00011797          	auipc	a5,0x11
ffffffffc02040f0:	48a7be23          	sd	a0,1180(a5) # ffffffffc0215588 <max_swap_offset>
}
ffffffffc02040f4:	0141                	addi	sp,sp,16
ffffffffc02040f6:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc02040f8:	00003617          	auipc	a2,0x3
ffffffffc02040fc:	9f860613          	addi	a2,a2,-1544 # ffffffffc0206af0 <default_pmm_manager+0xf60>
ffffffffc0204100:	45b5                	li	a1,13
ffffffffc0204102:	00003517          	auipc	a0,0x3
ffffffffc0204106:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0206b10 <default_pmm_manager+0xf80>
ffffffffc020410a:	b3cfc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020410e <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc020410e:	1141                	addi	sp,sp,-16
ffffffffc0204110:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204112:	00855793          	srli	a5,a0,0x8
ffffffffc0204116:	cbb1                	beqz	a5,ffffffffc020416a <swapfs_read+0x5c>
ffffffffc0204118:	00011717          	auipc	a4,0x11
ffffffffc020411c:	47073703          	ld	a4,1136(a4) # ffffffffc0215588 <max_swap_offset>
ffffffffc0204120:	04e7f563          	bgeu	a5,a4,ffffffffc020416a <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204124:	00011617          	auipc	a2,0x11
ffffffffc0204128:	44c63603          	ld	a2,1100(a2) # ffffffffc0215570 <pages>
ffffffffc020412c:	8d91                	sub	a1,a1,a2
ffffffffc020412e:	4065d613          	srai	a2,a1,0x6
ffffffffc0204132:	00003717          	auipc	a4,0x3
ffffffffc0204136:	db673703          	ld	a4,-586(a4) # ffffffffc0206ee8 <nbase>
ffffffffc020413a:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc020413c:	00c61713          	slli	a4,a2,0xc
ffffffffc0204140:	8331                	srli	a4,a4,0xc
ffffffffc0204142:	00011697          	auipc	a3,0x11
ffffffffc0204146:	4266b683          	ld	a3,1062(a3) # ffffffffc0215568 <npage>
ffffffffc020414a:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc020414e:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204150:	02d77963          	bgeu	a4,a3,ffffffffc0204182 <swapfs_read+0x74>
}
ffffffffc0204154:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204156:	00011797          	auipc	a5,0x11
ffffffffc020415a:	42a7b783          	ld	a5,1066(a5) # ffffffffc0215580 <va_pa_offset>
ffffffffc020415e:	46a1                	li	a3,8
ffffffffc0204160:	963e                	add	a2,a2,a5
ffffffffc0204162:	4505                	li	a0,1
}
ffffffffc0204164:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204166:	c0efc06f          	j	ffffffffc0200574 <ide_read_secs>
ffffffffc020416a:	86aa                	mv	a3,a0
ffffffffc020416c:	00003617          	auipc	a2,0x3
ffffffffc0204170:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0206b28 <default_pmm_manager+0xf98>
ffffffffc0204174:	45d1                	li	a1,20
ffffffffc0204176:	00003517          	auipc	a0,0x3
ffffffffc020417a:	99a50513          	addi	a0,a0,-1638 # ffffffffc0206b10 <default_pmm_manager+0xf80>
ffffffffc020417e:	ac8fc0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc0204182:	86b2                	mv	a3,a2
ffffffffc0204184:	06900593          	li	a1,105
ffffffffc0204188:	00002617          	auipc	a2,0x2
ffffffffc020418c:	a4060613          	addi	a2,a2,-1472 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc0204190:	00002517          	auipc	a0,0x2
ffffffffc0204194:	a6050513          	addi	a0,a0,-1440 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0204198:	aaefc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020419c <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc020419c:	1141                	addi	sp,sp,-16
ffffffffc020419e:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041a0:	00855793          	srli	a5,a0,0x8
ffffffffc02041a4:	cbb1                	beqz	a5,ffffffffc02041f8 <swapfs_write+0x5c>
ffffffffc02041a6:	00011717          	auipc	a4,0x11
ffffffffc02041aa:	3e273703          	ld	a4,994(a4) # ffffffffc0215588 <max_swap_offset>
ffffffffc02041ae:	04e7f563          	bgeu	a5,a4,ffffffffc02041f8 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc02041b2:	00011617          	auipc	a2,0x11
ffffffffc02041b6:	3be63603          	ld	a2,958(a2) # ffffffffc0215570 <pages>
ffffffffc02041ba:	8d91                	sub	a1,a1,a2
ffffffffc02041bc:	4065d613          	srai	a2,a1,0x6
ffffffffc02041c0:	00003717          	auipc	a4,0x3
ffffffffc02041c4:	d2873703          	ld	a4,-728(a4) # ffffffffc0206ee8 <nbase>
ffffffffc02041c8:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc02041ca:	00c61713          	slli	a4,a2,0xc
ffffffffc02041ce:	8331                	srli	a4,a4,0xc
ffffffffc02041d0:	00011697          	auipc	a3,0x11
ffffffffc02041d4:	3986b683          	ld	a3,920(a3) # ffffffffc0215568 <npage>
ffffffffc02041d8:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041dc:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02041de:	02d77963          	bgeu	a4,a3,ffffffffc0204210 <swapfs_write+0x74>
}
ffffffffc02041e2:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041e4:	00011797          	auipc	a5,0x11
ffffffffc02041e8:	39c7b783          	ld	a5,924(a5) # ffffffffc0215580 <va_pa_offset>
ffffffffc02041ec:	46a1                	li	a3,8
ffffffffc02041ee:	963e                	add	a2,a2,a5
ffffffffc02041f0:	4505                	li	a0,1
}
ffffffffc02041f2:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041f4:	ba4fc06f          	j	ffffffffc0200598 <ide_write_secs>
ffffffffc02041f8:	86aa                	mv	a3,a0
ffffffffc02041fa:	00003617          	auipc	a2,0x3
ffffffffc02041fe:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206b28 <default_pmm_manager+0xf98>
ffffffffc0204202:	45e5                	li	a1,25
ffffffffc0204204:	00003517          	auipc	a0,0x3
ffffffffc0204208:	90c50513          	addi	a0,a0,-1780 # ffffffffc0206b10 <default_pmm_manager+0xf80>
ffffffffc020420c:	a3afc0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc0204210:	86b2                	mv	a3,a2
ffffffffc0204212:	06900593          	li	a1,105
ffffffffc0204216:	00002617          	auipc	a2,0x2
ffffffffc020421a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc020421e:	00002517          	auipc	a0,0x2
ffffffffc0204222:	9d250513          	addi	a0,a0,-1582 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0204226:	a20fc0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020422a <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc020422a:	8526                	mv	a0,s1
	jalr s0
ffffffffc020422c:	9402                	jalr	s0

	jal do_exit
ffffffffc020422e:	3be000ef          	jal	ra,ffffffffc02045ec <do_exit>

ffffffffc0204232 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204232:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204234:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc0204238:	e022                	sd	s0,0(sp)
ffffffffc020423a:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020423c:	e08fd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
ffffffffc0204240:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204242:	c521                	beqz	a0,ffffffffc020428a <alloc_proc+0x58>
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state = PROC_UNINIT;
ffffffffc0204244:	57fd                	li	a5,-1
ffffffffc0204246:	1782                	slli	a5,a5,0x20
ffffffffc0204248:	e11c                	sd	a5,0(a0)
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0;
    proc->parent=NULL;
    proc->mm = NULL;
    memset(&(proc->context),0,sizeof(struct context));
ffffffffc020424a:	07000613          	li	a2,112
ffffffffc020424e:	4581                	li	a1,0
    proc->runs = 0;
ffffffffc0204250:	00052423          	sw	zero,8(a0)
    proc->kstack = 0;
ffffffffc0204254:	00053823          	sd	zero,16(a0)
    proc->need_resched = 0;
ffffffffc0204258:	00052c23          	sw	zero,24(a0)
    proc->parent=NULL;
ffffffffc020425c:	02053023          	sd	zero,32(a0)
    proc->mm = NULL;
ffffffffc0204260:	02053423          	sd	zero,40(a0)
    memset(&(proc->context),0,sizeof(struct context));
ffffffffc0204264:	03050513          	addi	a0,a0,48
ffffffffc0204268:	387000ef          	jal	ra,ffffffffc0204dee <memset>
    proc->tf = NULL;
    proc->cr3 = boot_cr3;
ffffffffc020426c:	00011797          	auipc	a5,0x11
ffffffffc0204270:	2ec7b783          	ld	a5,748(a5) # ffffffffc0215558 <boot_cr3>
    proc->tf = NULL;
ffffffffc0204274:	0a043023          	sd	zero,160(s0)
    proc->cr3 = boot_cr3;
ffffffffc0204278:	f45c                	sd	a5,168(s0)
    proc->flags = 0;
ffffffffc020427a:	0a042823          	sw	zero,176(s0)
    memset(proc->name,0,PROC_NAME_LEN);
ffffffffc020427e:	463d                	li	a2,15
ffffffffc0204280:	4581                	li	a1,0
ffffffffc0204282:	0b440513          	addi	a0,s0,180
ffffffffc0204286:	369000ef          	jal	ra,ffffffffc0204dee <memset>
    }
    return proc;
}
ffffffffc020428a:	60a2                	ld	ra,8(sp)
ffffffffc020428c:	8522                	mv	a0,s0
ffffffffc020428e:	6402                	ld	s0,0(sp)
ffffffffc0204290:	0141                	addi	sp,sp,16
ffffffffc0204292:	8082                	ret

ffffffffc0204294 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204294:	00011797          	auipc	a5,0x11
ffffffffc0204298:	31c7b783          	ld	a5,796(a5) # ffffffffc02155b0 <current>
ffffffffc020429c:	73c8                	ld	a0,160(a5)
ffffffffc020429e:	8cffc06f          	j	ffffffffc0200b6c <forkrets>

ffffffffc02042a2 <init_main>:
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc02042a2:	7179                	addi	sp,sp,-48
ffffffffc02042a4:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02042a6:	00011497          	auipc	s1,0x11
ffffffffc02042aa:	27248493          	addi	s1,s1,626 # ffffffffc0215518 <name.2>
init_main(void *arg) {
ffffffffc02042ae:	f022                	sd	s0,32(sp)
ffffffffc02042b0:	e84a                	sd	s2,16(sp)
ffffffffc02042b2:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02042b4:	00011917          	auipc	s2,0x11
ffffffffc02042b8:	2fc93903          	ld	s2,764(s2) # ffffffffc02155b0 <current>
    memset(name, 0, sizeof(name));
ffffffffc02042bc:	4641                	li	a2,16
ffffffffc02042be:	4581                	li	a1,0
ffffffffc02042c0:	8526                	mv	a0,s1
init_main(void *arg) {
ffffffffc02042c2:	f406                	sd	ra,40(sp)
ffffffffc02042c4:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02042c6:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02042ca:	325000ef          	jal	ra,ffffffffc0204dee <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02042ce:	0b490593          	addi	a1,s2,180
ffffffffc02042d2:	463d                	li	a2,15
ffffffffc02042d4:	8526                	mv	a0,s1
ffffffffc02042d6:	32b000ef          	jal	ra,ffffffffc0204e00 <memcpy>
ffffffffc02042da:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02042dc:	85ce                	mv	a1,s3
ffffffffc02042de:	00003517          	auipc	a0,0x3
ffffffffc02042e2:	86a50513          	addi	a0,a0,-1942 # ffffffffc0206b48 <default_pmm_manager+0xfb8>
ffffffffc02042e6:	e9bfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02042ea:	85a2                	mv	a1,s0
ffffffffc02042ec:	00003517          	auipc	a0,0x3
ffffffffc02042f0:	88450513          	addi	a0,a0,-1916 # ffffffffc0206b70 <default_pmm_manager+0xfe0>
ffffffffc02042f4:	e8dfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02042f8:	00003517          	auipc	a0,0x3
ffffffffc02042fc:	88850513          	addi	a0,a0,-1912 # ffffffffc0206b80 <default_pmm_manager+0xff0>
ffffffffc0204300:	e81fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc0204304:	70a2                	ld	ra,40(sp)
ffffffffc0204306:	7402                	ld	s0,32(sp)
ffffffffc0204308:	64e2                	ld	s1,24(sp)
ffffffffc020430a:	6942                	ld	s2,16(sp)
ffffffffc020430c:	69a2                	ld	s3,8(sp)
ffffffffc020430e:	4501                	li	a0,0
ffffffffc0204310:	6145                	addi	sp,sp,48
ffffffffc0204312:	8082                	ret

ffffffffc0204314 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204314:	7179                	addi	sp,sp,-48
ffffffffc0204316:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204318:	00011497          	auipc	s1,0x11
ffffffffc020431c:	29848493          	addi	s1,s1,664 # ffffffffc02155b0 <current>
ffffffffc0204320:	6098                	ld	a4,0(s1)
proc_run(struct proc_struct *proc) {
ffffffffc0204322:	f406                	sd	ra,40(sp)
ffffffffc0204324:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204326:	02a70863          	beq	a4,a0,ffffffffc0204356 <proc_run+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020432a:	100027f3          	csrr	a5,sstatus
ffffffffc020432e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204330:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204332:	ef8d                	bnez	a5,ffffffffc020436c <proc_run+0x58>
        lcr3(proc->cr3);    // 切换到下一个进程的页表
ffffffffc0204334:	755c                	ld	a5,168(a0)

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204336:	800006b7          	lui	a3,0x80000
        current = proc; // 将当前进程设置为下一个进程
ffffffffc020433a:	e088                	sd	a0,0(s1)
ffffffffc020433c:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0204340:	8fd5                	or	a5,a5,a3
ffffffffc0204342:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(next->context));  // 进行上下文切换
ffffffffc0204346:	03050593          	addi	a1,a0,48
ffffffffc020434a:	03070513          	addi	a0,a4,48
ffffffffc020434e:	522000ef          	jal	ra,ffffffffc0204870 <switch_to>
    if (flag) {
ffffffffc0204352:	00091763          	bnez	s2,ffffffffc0204360 <proc_run+0x4c>
}
ffffffffc0204356:	70a2                	ld	ra,40(sp)
ffffffffc0204358:	7482                	ld	s1,32(sp)
ffffffffc020435a:	6962                	ld	s2,24(sp)
ffffffffc020435c:	6145                	addi	sp,sp,48
ffffffffc020435e:	8082                	ret
ffffffffc0204360:	70a2                	ld	ra,40(sp)
ffffffffc0204362:	7482                	ld	s1,32(sp)
ffffffffc0204364:	6962                	ld	s2,24(sp)
ffffffffc0204366:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204368:	a54fc06f          	j	ffffffffc02005bc <intr_enable>
ffffffffc020436c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020436e:	a54fc0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        struct proc_struct *prev = current; // 保存当前进程
ffffffffc0204372:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0204374:	6522                	ld	a0,8(sp)
ffffffffc0204376:	4905                	li	s2,1
ffffffffc0204378:	bf75                	j	ffffffffc0204334 <proc_run+0x20>

ffffffffc020437a <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc020437a:	7179                	addi	sp,sp,-48
ffffffffc020437c:	e84a                	sd	s2,16(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc020437e:	00011917          	auipc	s2,0x11
ffffffffc0204382:	24a90913          	addi	s2,s2,586 # ffffffffc02155c8 <nr_process>
ffffffffc0204386:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc020438a:	f406                	sd	ra,40(sp)
ffffffffc020438c:	f022                	sd	s0,32(sp)
ffffffffc020438e:	ec26                	sd	s1,24(sp)
ffffffffc0204390:	e44e                	sd	s3,8(sp)
ffffffffc0204392:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204394:	6785                	lui	a5,0x1
ffffffffc0204396:	1cf75263          	bge	a4,a5,ffffffffc020455a <do_fork+0x1e0>
ffffffffc020439a:	84ae                	mv	s1,a1
ffffffffc020439c:	8a32                	mv	s4,a2
    proc->parent = current;
ffffffffc020439e:	00011997          	auipc	s3,0x11
ffffffffc02043a2:	21298993          	addi	s3,s3,530 # ffffffffc02155b0 <current>
    proc = alloc_proc();
ffffffffc02043a6:	e8dff0ef          	jal	ra,ffffffffc0204232 <alloc_proc>
    proc->parent = current;
ffffffffc02043aa:	0009b783          	ld	a5,0(s3)
    proc = alloc_proc();
ffffffffc02043ae:	842a                	mv	s0,a0
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02043b0:	4509                	li	a0,2
    proc->parent = current;
ffffffffc02043b2:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02043b4:	e6efd0ef          	jal	ra,ffffffffc0201a22 <alloc_pages>
    if (page != NULL) {
ffffffffc02043b8:	cd0d                	beqz	a0,ffffffffc02043f2 <do_fork+0x78>
    return page - pages + nbase;
ffffffffc02043ba:	00011697          	auipc	a3,0x11
ffffffffc02043be:	1b66b683          	ld	a3,438(a3) # ffffffffc0215570 <pages>
ffffffffc02043c2:	40d506b3          	sub	a3,a0,a3
ffffffffc02043c6:	8699                	srai	a3,a3,0x6
ffffffffc02043c8:	00003517          	auipc	a0,0x3
ffffffffc02043cc:	b2053503          	ld	a0,-1248(a0) # ffffffffc0206ee8 <nbase>
ffffffffc02043d0:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02043d2:	00c69793          	slli	a5,a3,0xc
ffffffffc02043d6:	83b1                	srli	a5,a5,0xc
ffffffffc02043d8:	00011717          	auipc	a4,0x11
ffffffffc02043dc:	19073703          	ld	a4,400(a4) # ffffffffc0215568 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02043e0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043e2:	1ae7f163          	bgeu	a5,a4,ffffffffc0204584 <do_fork+0x20a>
ffffffffc02043e6:	00011797          	auipc	a5,0x11
ffffffffc02043ea:	19a7b783          	ld	a5,410(a5) # ffffffffc0215580 <va_pa_offset>
ffffffffc02043ee:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02043f0:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc02043f2:	0009b783          	ld	a5,0(s3)
ffffffffc02043f6:	779c                	ld	a5,40(a5)
ffffffffc02043f8:	16079663          	bnez	a5,ffffffffc0204564 <do_fork+0x1ea>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02043fc:	6818                	ld	a4,16(s0)
ffffffffc02043fe:	6789                	lui	a5,0x2
ffffffffc0204400:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0204404:	973e                	add	a4,a4,a5
    *(proc->tf) = *tf;
ffffffffc0204406:	8652                	mv	a2,s4
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204408:	f058                	sd	a4,160(s0)
    *(proc->tf) = *tf;
ffffffffc020440a:	87ba                	mv	a5,a4
ffffffffc020440c:	120a0593          	addi	a1,s4,288
ffffffffc0204410:	00063883          	ld	a7,0(a2)
ffffffffc0204414:	00863803          	ld	a6,8(a2)
ffffffffc0204418:	6a08                	ld	a0,16(a2)
ffffffffc020441a:	6e14                	ld	a3,24(a2)
ffffffffc020441c:	0117b023          	sd	a7,0(a5)
ffffffffc0204420:	0107b423          	sd	a6,8(a5)
ffffffffc0204424:	eb88                	sd	a0,16(a5)
ffffffffc0204426:	ef94                	sd	a3,24(a5)
ffffffffc0204428:	02060613          	addi	a2,a2,32
ffffffffc020442c:	02078793          	addi	a5,a5,32
ffffffffc0204430:	feb610e3          	bne	a2,a1,ffffffffc0204410 <do_fork+0x96>
    proc->tf->gpr.a0 = 0;
ffffffffc0204434:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204438:	10048563          	beqz	s1,ffffffffc0204542 <do_fork+0x1c8>
    if (++ last_pid >= MAX_PID) {
ffffffffc020443c:	00006817          	auipc	a6,0x6
ffffffffc0204440:	c1c80813          	addi	a6,a6,-996 # ffffffffc020a058 <last_pid.1>
ffffffffc0204444:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204448:	eb04                	sd	s1,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020444a:	00000697          	auipc	a3,0x0
ffffffffc020444e:	e4a68693          	addi	a3,a3,-438 # ffffffffc0204294 <forkret>
    if (++ last_pid >= MAX_PID) {
ffffffffc0204452:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204456:	f814                	sd	a3,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204458:	fc18                	sd	a4,56(s0)
    if (++ last_pid >= MAX_PID) {
ffffffffc020445a:	00a82023          	sw	a0,0(a6)
ffffffffc020445e:	6789                	lui	a5,0x2
ffffffffc0204460:	06f55a63          	bge	a0,a5,ffffffffc02044d4 <do_fork+0x15a>
    if (last_pid >= next_safe) {
ffffffffc0204464:	00006317          	auipc	t1,0x6
ffffffffc0204468:	bf830313          	addi	t1,t1,-1032 # ffffffffc020a05c <next_safe.0>
ffffffffc020446c:	00032783          	lw	a5,0(t1)
ffffffffc0204470:	00011497          	auipc	s1,0x11
ffffffffc0204474:	0b848493          	addi	s1,s1,184 # ffffffffc0215528 <proc_list>
ffffffffc0204478:	06f55663          	bge	a0,a5,ffffffffc02044e4 <do_fork+0x16a>
    proc->pid = pid;
ffffffffc020447c:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020447e:	45a9                	li	a1,10
ffffffffc0204480:	2501                	sext.w	a0,a0
ffffffffc0204482:	4ec000ef          	jal	ra,ffffffffc020496e <hash32>
ffffffffc0204486:	02051793          	slli	a5,a0,0x20
ffffffffc020448a:	0000d717          	auipc	a4,0xd
ffffffffc020448e:	08e70713          	addi	a4,a4,142 # ffffffffc0211518 <hash_list>
ffffffffc0204492:	83f1                	srli	a5,a5,0x1c
ffffffffc0204494:	97ba                	add	a5,a5,a4
    __list_add(elm, listelm, listelm->next);
ffffffffc0204496:	678c                	ld	a1,8(a5)
ffffffffc0204498:	0d840713          	addi	a4,s0,216
ffffffffc020449c:	6494                	ld	a3,8(s1)
    prev->next = next->prev = elm;
ffffffffc020449e:	e198                	sd	a4,0(a1)
ffffffffc02044a0:	e798                	sd	a4,8(a5)
    nr_process++;
ffffffffc02044a2:	00092703          	lw	a4,0(s2)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02044a6:	0c840613          	addi	a2,s0,200
    elm->prev = prev;
ffffffffc02044aa:	ec7c                	sd	a5,216(s0)
    elm->next = next;
ffffffffc02044ac:	f06c                	sd	a1,224(s0)
    prev->next = next->prev = elm;
ffffffffc02044ae:	e290                	sd	a2,0(a3)
    nr_process++;
ffffffffc02044b0:	0017079b          	addiw	a5,a4,1
    ret = proc->pid;
ffffffffc02044b4:	4048                	lw	a0,4(s0)
ffffffffc02044b6:	e490                	sd	a2,8(s1)
    nr_process++;
ffffffffc02044b8:	00f92023          	sw	a5,0(s2)
    proc->state = PROC_RUNNABLE;
ffffffffc02044bc:	4789                	li	a5,2
    elm->next = next;
ffffffffc02044be:	e874                	sd	a3,208(s0)
    elm->prev = prev;
ffffffffc02044c0:	e464                	sd	s1,200(s0)
ffffffffc02044c2:	c01c                	sw	a5,0(s0)
}
ffffffffc02044c4:	70a2                	ld	ra,40(sp)
ffffffffc02044c6:	7402                	ld	s0,32(sp)
ffffffffc02044c8:	64e2                	ld	s1,24(sp)
ffffffffc02044ca:	6942                	ld	s2,16(sp)
ffffffffc02044cc:	69a2                	ld	s3,8(sp)
ffffffffc02044ce:	6a02                	ld	s4,0(sp)
ffffffffc02044d0:	6145                	addi	sp,sp,48
ffffffffc02044d2:	8082                	ret
        last_pid = 1;
ffffffffc02044d4:	4785                	li	a5,1
ffffffffc02044d6:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02044da:	4505                	li	a0,1
ffffffffc02044dc:	00006317          	auipc	t1,0x6
ffffffffc02044e0:	b8030313          	addi	t1,t1,-1152 # ffffffffc020a05c <next_safe.0>
    return listelm->next;
ffffffffc02044e4:	00011497          	auipc	s1,0x11
ffffffffc02044e8:	04448493          	addi	s1,s1,68 # ffffffffc0215528 <proc_list>
ffffffffc02044ec:	0084be03          	ld	t3,8(s1)
        next_safe = MAX_PID;
ffffffffc02044f0:	6789                	lui	a5,0x2
ffffffffc02044f2:	00f32023          	sw	a5,0(t1)
ffffffffc02044f6:	86aa                	mv	a3,a0
ffffffffc02044f8:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc02044fa:	6e89                	lui	t4,0x2
ffffffffc02044fc:	049e0a63          	beq	t3,s1,ffffffffc0204550 <do_fork+0x1d6>
ffffffffc0204500:	88ae                	mv	a7,a1
ffffffffc0204502:	87f2                	mv	a5,t3
ffffffffc0204504:	6609                	lui	a2,0x2
ffffffffc0204506:	a811                	j	ffffffffc020451a <do_fork+0x1a0>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0204508:	00e6d663          	bge	a3,a4,ffffffffc0204514 <do_fork+0x19a>
ffffffffc020450c:	00c75463          	bge	a4,a2,ffffffffc0204514 <do_fork+0x19a>
ffffffffc0204510:	863a                	mv	a2,a4
ffffffffc0204512:	4885                	li	a7,1
ffffffffc0204514:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204516:	00978d63          	beq	a5,s1,ffffffffc0204530 <do_fork+0x1b6>
            if (proc->pid == last_pid) {
ffffffffc020451a:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc020451e:	fed715e3          	bne	a4,a3,ffffffffc0204508 <do_fork+0x18e>
                if (++ last_pid >= next_safe) {
ffffffffc0204522:	2685                	addiw	a3,a3,1
ffffffffc0204524:	02c6d163          	bge	a3,a2,ffffffffc0204546 <do_fork+0x1cc>
ffffffffc0204528:	679c                	ld	a5,8(a5)
ffffffffc020452a:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc020452c:	fe9797e3          	bne	a5,s1,ffffffffc020451a <do_fork+0x1a0>
ffffffffc0204530:	c581                	beqz	a1,ffffffffc0204538 <do_fork+0x1be>
ffffffffc0204532:	00d82023          	sw	a3,0(a6)
ffffffffc0204536:	8536                	mv	a0,a3
ffffffffc0204538:	f40882e3          	beqz	a7,ffffffffc020447c <do_fork+0x102>
ffffffffc020453c:	00c32023          	sw	a2,0(t1)
ffffffffc0204540:	bf35                	j	ffffffffc020447c <do_fork+0x102>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204542:	84ba                	mv	s1,a4
ffffffffc0204544:	bde5                	j	ffffffffc020443c <do_fork+0xc2>
                    if (last_pid >= MAX_PID) {
ffffffffc0204546:	01d6c363          	blt	a3,t4,ffffffffc020454c <do_fork+0x1d2>
                        last_pid = 1;
ffffffffc020454a:	4685                	li	a3,1
                    goto repeat;
ffffffffc020454c:	4585                	li	a1,1
ffffffffc020454e:	b77d                	j	ffffffffc02044fc <do_fork+0x182>
ffffffffc0204550:	c599                	beqz	a1,ffffffffc020455e <do_fork+0x1e4>
ffffffffc0204552:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204556:	8536                	mv	a0,a3
ffffffffc0204558:	b715                	j	ffffffffc020447c <do_fork+0x102>
    int ret = -E_NO_FREE_PROC;
ffffffffc020455a:	556d                	li	a0,-5
    return ret;
ffffffffc020455c:	b7a5                	j	ffffffffc02044c4 <do_fork+0x14a>
    return last_pid;
ffffffffc020455e:	00082503          	lw	a0,0(a6)
ffffffffc0204562:	bf29                	j	ffffffffc020447c <do_fork+0x102>
    assert(current->mm == NULL);
ffffffffc0204564:	00002697          	auipc	a3,0x2
ffffffffc0204568:	63c68693          	addi	a3,a3,1596 # ffffffffc0206ba0 <default_pmm_manager+0x1010>
ffffffffc020456c:	00001617          	auipc	a2,0x1
ffffffffc0204570:	27460613          	addi	a2,a2,628 # ffffffffc02057e0 <commands+0x738>
ffffffffc0204574:	10900593          	li	a1,265
ffffffffc0204578:	00002517          	auipc	a0,0x2
ffffffffc020457c:	64050513          	addi	a0,a0,1600 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
ffffffffc0204580:	ec7fb0ef          	jal	ra,ffffffffc0200446 <__panic>
ffffffffc0204584:	00001617          	auipc	a2,0x1
ffffffffc0204588:	64460613          	addi	a2,a2,1604 # ffffffffc0205bc8 <default_pmm_manager+0x38>
ffffffffc020458c:	06900593          	li	a1,105
ffffffffc0204590:	00001517          	auipc	a0,0x1
ffffffffc0204594:	66050513          	addi	a0,a0,1632 # ffffffffc0205bf0 <default_pmm_manager+0x60>
ffffffffc0204598:	eaffb0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc020459c <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020459c:	7129                	addi	sp,sp,-320
ffffffffc020459e:	fa22                	sd	s0,304(sp)
ffffffffc02045a0:	f626                	sd	s1,296(sp)
ffffffffc02045a2:	f24a                	sd	s2,288(sp)
ffffffffc02045a4:	84ae                	mv	s1,a1
ffffffffc02045a6:	892a                	mv	s2,a0
ffffffffc02045a8:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02045aa:	4581                	li	a1,0
ffffffffc02045ac:	12000613          	li	a2,288
ffffffffc02045b0:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02045b2:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02045b4:	03b000ef          	jal	ra,ffffffffc0204dee <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02045b8:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02045ba:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02045bc:	100027f3          	csrr	a5,sstatus
ffffffffc02045c0:	edd7f793          	andi	a5,a5,-291
ffffffffc02045c4:	1207e793          	ori	a5,a5,288
ffffffffc02045c8:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045ca:	860a                	mv	a2,sp
ffffffffc02045cc:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045d0:	00000797          	auipc	a5,0x0
ffffffffc02045d4:	c5a78793          	addi	a5,a5,-934 # ffffffffc020422a <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045d8:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045da:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045dc:	d9fff0ef          	jal	ra,ffffffffc020437a <do_fork>
}
ffffffffc02045e0:	70f2                	ld	ra,312(sp)
ffffffffc02045e2:	7452                	ld	s0,304(sp)
ffffffffc02045e4:	74b2                	ld	s1,296(sp)
ffffffffc02045e6:	7912                	ld	s2,288(sp)
ffffffffc02045e8:	6131                	addi	sp,sp,320
ffffffffc02045ea:	8082                	ret

ffffffffc02045ec <do_exit>:
do_exit(int error_code) {
ffffffffc02045ec:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02045ee:	00002617          	auipc	a2,0x2
ffffffffc02045f2:	5e260613          	addi	a2,a2,1506 # ffffffffc0206bd0 <default_pmm_manager+0x1040>
ffffffffc02045f6:	16b00593          	li	a1,363
ffffffffc02045fa:	00002517          	auipc	a0,0x2
ffffffffc02045fe:	5be50513          	addi	a0,a0,1470 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
do_exit(int error_code) {
ffffffffc0204602:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0204604:	e43fb0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0204608 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0204608:	7179                	addi	sp,sp,-48
ffffffffc020460a:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc020460c:	00011797          	auipc	a5,0x11
ffffffffc0204610:	f1c78793          	addi	a5,a5,-228 # ffffffffc0215528 <proc_list>
ffffffffc0204614:	f406                	sd	ra,40(sp)
ffffffffc0204616:	f022                	sd	s0,32(sp)
ffffffffc0204618:	e84a                	sd	s2,16(sp)
ffffffffc020461a:	e44e                	sd	s3,8(sp)
ffffffffc020461c:	0000d497          	auipc	s1,0xd
ffffffffc0204620:	efc48493          	addi	s1,s1,-260 # ffffffffc0211518 <hash_list>
ffffffffc0204624:	e79c                	sd	a5,8(a5)
ffffffffc0204626:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0204628:	00011717          	auipc	a4,0x11
ffffffffc020462c:	ef070713          	addi	a4,a4,-272 # ffffffffc0215518 <name.2>
ffffffffc0204630:	87a6                	mv	a5,s1
ffffffffc0204632:	e79c                	sd	a5,8(a5)
ffffffffc0204634:	e39c                	sd	a5,0(a5)
ffffffffc0204636:	07c1                	addi	a5,a5,16
ffffffffc0204638:	fef71de3          	bne	a4,a5,ffffffffc0204632 <proc_init+0x2a>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc020463c:	bf7ff0ef          	jal	ra,ffffffffc0204232 <alloc_proc>
ffffffffc0204640:	00011917          	auipc	s2,0x11
ffffffffc0204644:	f7890913          	addi	s2,s2,-136 # ffffffffc02155b8 <idleproc>
ffffffffc0204648:	00a93023          	sd	a0,0(s2)
ffffffffc020464c:	18050c63          	beqz	a0,ffffffffc02047e4 <proc_init+0x1dc>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204650:	07000513          	li	a0,112
ffffffffc0204654:	9f0fd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204658:	07000613          	li	a2,112
ffffffffc020465c:	4581                	li	a1,0
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc020465e:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204660:	78e000ef          	jal	ra,ffffffffc0204dee <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0204664:	00093503          	ld	a0,0(s2)
ffffffffc0204668:	85a2                	mv	a1,s0
ffffffffc020466a:	07000613          	li	a2,112
ffffffffc020466e:	03050513          	addi	a0,a0,48
ffffffffc0204672:	7a6000ef          	jal	ra,ffffffffc0204e18 <memcmp>
ffffffffc0204676:	89aa                	mv	s3,a0

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc0204678:	453d                	li	a0,15
ffffffffc020467a:	9cafd0ef          	jal	ra,ffffffffc0201844 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020467e:	463d                	li	a2,15
ffffffffc0204680:	4581                	li	a1,0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc0204682:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204684:	76a000ef          	jal	ra,ffffffffc0204dee <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0204688:	00093503          	ld	a0,0(s2)
ffffffffc020468c:	463d                	li	a2,15
ffffffffc020468e:	85a2                	mv	a1,s0
ffffffffc0204690:	0b450513          	addi	a0,a0,180
ffffffffc0204694:	784000ef          	jal	ra,ffffffffc0204e18 <memcmp>

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc0204698:	00093783          	ld	a5,0(s2)
ffffffffc020469c:	00011717          	auipc	a4,0x11
ffffffffc02046a0:	ebc73703          	ld	a4,-324(a4) # ffffffffc0215558 <boot_cr3>
ffffffffc02046a4:	77d4                	ld	a3,168(a5)
ffffffffc02046a6:	0ee68363          	beq	a3,a4,ffffffffc020478c <proc_init+0x184>
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02046aa:	4709                	li	a4,2
ffffffffc02046ac:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02046ae:	00003717          	auipc	a4,0x3
ffffffffc02046b2:	95270713          	addi	a4,a4,-1710 # ffffffffc0207000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02046b6:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02046ba:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02046bc:	4705                	li	a4,1
ffffffffc02046be:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02046c0:	4641                	li	a2,16
ffffffffc02046c2:	4581                	li	a1,0
ffffffffc02046c4:	8522                	mv	a0,s0
ffffffffc02046c6:	728000ef          	jal	ra,ffffffffc0204dee <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02046ca:	463d                	li	a2,15
ffffffffc02046cc:	00002597          	auipc	a1,0x2
ffffffffc02046d0:	54c58593          	addi	a1,a1,1356 # ffffffffc0206c18 <default_pmm_manager+0x1088>
ffffffffc02046d4:	8522                	mv	a0,s0
ffffffffc02046d6:	72a000ef          	jal	ra,ffffffffc0204e00 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc02046da:	00011717          	auipc	a4,0x11
ffffffffc02046de:	eee70713          	addi	a4,a4,-274 # ffffffffc02155c8 <nr_process>
ffffffffc02046e2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02046e4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02046e8:	4601                	li	a2,0
    nr_process ++;
ffffffffc02046ea:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02046ec:	00002597          	auipc	a1,0x2
ffffffffc02046f0:	53458593          	addi	a1,a1,1332 # ffffffffc0206c20 <default_pmm_manager+0x1090>
ffffffffc02046f4:	00000517          	auipc	a0,0x0
ffffffffc02046f8:	bae50513          	addi	a0,a0,-1106 # ffffffffc02042a2 <init_main>
    nr_process ++;
ffffffffc02046fc:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02046fe:	00011797          	auipc	a5,0x11
ffffffffc0204702:	ead7b923          	sd	a3,-334(a5) # ffffffffc02155b0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0204706:	e97ff0ef          	jal	ra,ffffffffc020459c <kernel_thread>
ffffffffc020470a:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc020470c:	0ea05863          	blez	a0,ffffffffc02047fc <proc_init+0x1f4>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0204710:	6789                	lui	a5,0x2
ffffffffc0204712:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204716:	17f9                	addi	a5,a5,-2
ffffffffc0204718:	2501                	sext.w	a0,a0
ffffffffc020471a:	02e7e263          	bltu	a5,a4,ffffffffc020473e <proc_init+0x136>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020471e:	45a9                	li	a1,10
ffffffffc0204720:	24e000ef          	jal	ra,ffffffffc020496e <hash32>
ffffffffc0204724:	02051693          	slli	a3,a0,0x20
ffffffffc0204728:	82f1                	srli	a3,a3,0x1c
ffffffffc020472a:	96a6                	add	a3,a3,s1
ffffffffc020472c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc020472e:	a029                	j	ffffffffc0204738 <proc_init+0x130>
            if (proc->pid == pid) {
ffffffffc0204730:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0204734:	0a870563          	beq	a4,s0,ffffffffc02047de <proc_init+0x1d6>
    return listelm->next;
ffffffffc0204738:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020473a:	fef69be3          	bne	a3,a5,ffffffffc0204730 <proc_init+0x128>
    return NULL;
ffffffffc020473e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204740:	0b478493          	addi	s1,a5,180
ffffffffc0204744:	4641                	li	a2,16
ffffffffc0204746:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204748:	00011417          	auipc	s0,0x11
ffffffffc020474c:	e7840413          	addi	s0,s0,-392 # ffffffffc02155c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204750:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204752:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204754:	69a000ef          	jal	ra,ffffffffc0204dee <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204758:	463d                	li	a2,15
ffffffffc020475a:	00002597          	auipc	a1,0x2
ffffffffc020475e:	4f658593          	addi	a1,a1,1270 # ffffffffc0206c50 <default_pmm_manager+0x10c0>
ffffffffc0204762:	8526                	mv	a0,s1
ffffffffc0204764:	69c000ef          	jal	ra,ffffffffc0204e00 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204768:	00093783          	ld	a5,0(s2)
ffffffffc020476c:	c7e1                	beqz	a5,ffffffffc0204834 <proc_init+0x22c>
ffffffffc020476e:	43dc                	lw	a5,4(a5)
ffffffffc0204770:	e3f1                	bnez	a5,ffffffffc0204834 <proc_init+0x22c>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204772:	601c                	ld	a5,0(s0)
ffffffffc0204774:	c3c5                	beqz	a5,ffffffffc0204814 <proc_init+0x20c>
ffffffffc0204776:	43d8                	lw	a4,4(a5)
ffffffffc0204778:	4785                	li	a5,1
ffffffffc020477a:	08f71d63          	bne	a4,a5,ffffffffc0204814 <proc_init+0x20c>
}
ffffffffc020477e:	70a2                	ld	ra,40(sp)
ffffffffc0204780:	7402                	ld	s0,32(sp)
ffffffffc0204782:	64e2                	ld	s1,24(sp)
ffffffffc0204784:	6942                	ld	s2,16(sp)
ffffffffc0204786:	69a2                	ld	s3,8(sp)
ffffffffc0204788:	6145                	addi	sp,sp,48
ffffffffc020478a:	8082                	ret
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc020478c:	73d8                	ld	a4,160(a5)
ffffffffc020478e:	ff11                	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
ffffffffc0204790:	f0099de3          	bnez	s3,ffffffffc02046aa <proc_init+0xa2>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc0204794:	6394                	ld	a3,0(a5)
ffffffffc0204796:	577d                	li	a4,-1
ffffffffc0204798:	1702                	slli	a4,a4,0x20
ffffffffc020479a:	f0e698e3          	bne	a3,a4,ffffffffc02046aa <proc_init+0xa2>
ffffffffc020479e:	4798                	lw	a4,8(a5)
ffffffffc02047a0:	f00715e3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc02047a4:	6b98                	ld	a4,16(a5)
ffffffffc02047a6:	f00712e3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
ffffffffc02047aa:	4f98                	lw	a4,24(a5)
ffffffffc02047ac:	2701                	sext.w	a4,a4
ffffffffc02047ae:	ee071ee3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
ffffffffc02047b2:	7398                	ld	a4,32(a5)
ffffffffc02047b4:	ee071be3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
ffffffffc02047b8:	7798                	ld	a4,40(a5)
ffffffffc02047ba:	ee0718e3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
ffffffffc02047be:	0b07a703          	lw	a4,176(a5)
ffffffffc02047c2:	8d59                	or	a0,a0,a4
ffffffffc02047c4:	0005071b          	sext.w	a4,a0
ffffffffc02047c8:	ee0711e3          	bnez	a4,ffffffffc02046aa <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02047cc:	00002517          	auipc	a0,0x2
ffffffffc02047d0:	43450513          	addi	a0,a0,1076 # ffffffffc0206c00 <default_pmm_manager+0x1070>
ffffffffc02047d4:	9adfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    idleproc->pid = 0;
ffffffffc02047d8:	00093783          	ld	a5,0(s2)
ffffffffc02047dc:	b5f9                	j	ffffffffc02046aa <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02047de:	f2878793          	addi	a5,a5,-216
ffffffffc02047e2:	bfb9                	j	ffffffffc0204740 <proc_init+0x138>
        panic("cannot alloc idleproc.\n");
ffffffffc02047e4:	00002617          	auipc	a2,0x2
ffffffffc02047e8:	40460613          	addi	a2,a2,1028 # ffffffffc0206be8 <default_pmm_manager+0x1058>
ffffffffc02047ec:	18300593          	li	a1,387
ffffffffc02047f0:	00002517          	auipc	a0,0x2
ffffffffc02047f4:	3c850513          	addi	a0,a0,968 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
ffffffffc02047f8:	c4ffb0ef          	jal	ra,ffffffffc0200446 <__panic>
        panic("create init_main failed.\n");
ffffffffc02047fc:	00002617          	auipc	a2,0x2
ffffffffc0204800:	43460613          	addi	a2,a2,1076 # ffffffffc0206c30 <default_pmm_manager+0x10a0>
ffffffffc0204804:	1a300593          	li	a1,419
ffffffffc0204808:	00002517          	auipc	a0,0x2
ffffffffc020480c:	3b050513          	addi	a0,a0,944 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
ffffffffc0204810:	c37fb0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204814:	00002697          	auipc	a3,0x2
ffffffffc0204818:	46c68693          	addi	a3,a3,1132 # ffffffffc0206c80 <default_pmm_manager+0x10f0>
ffffffffc020481c:	00001617          	auipc	a2,0x1
ffffffffc0204820:	fc460613          	addi	a2,a2,-60 # ffffffffc02057e0 <commands+0x738>
ffffffffc0204824:	1aa00593          	li	a1,426
ffffffffc0204828:	00002517          	auipc	a0,0x2
ffffffffc020482c:	39050513          	addi	a0,a0,912 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
ffffffffc0204830:	c17fb0ef          	jal	ra,ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204834:	00002697          	auipc	a3,0x2
ffffffffc0204838:	42468693          	addi	a3,a3,1060 # ffffffffc0206c58 <default_pmm_manager+0x10c8>
ffffffffc020483c:	00001617          	auipc	a2,0x1
ffffffffc0204840:	fa460613          	addi	a2,a2,-92 # ffffffffc02057e0 <commands+0x738>
ffffffffc0204844:	1a900593          	li	a1,425
ffffffffc0204848:	00002517          	auipc	a0,0x2
ffffffffc020484c:	37050513          	addi	a0,a0,880 # ffffffffc0206bb8 <default_pmm_manager+0x1028>
ffffffffc0204850:	bf7fb0ef          	jal	ra,ffffffffc0200446 <__panic>

ffffffffc0204854 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0204854:	1141                	addi	sp,sp,-16
ffffffffc0204856:	e022                	sd	s0,0(sp)
ffffffffc0204858:	e406                	sd	ra,8(sp)
ffffffffc020485a:	00011417          	auipc	s0,0x11
ffffffffc020485e:	d5640413          	addi	s0,s0,-682 # ffffffffc02155b0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0204862:	6018                	ld	a4,0(s0)
ffffffffc0204864:	4f1c                	lw	a5,24(a4)
ffffffffc0204866:	2781                	sext.w	a5,a5
ffffffffc0204868:	dff5                	beqz	a5,ffffffffc0204864 <cpu_idle+0x10>
            schedule();
ffffffffc020486a:	070000ef          	jal	ra,ffffffffc02048da <schedule>
ffffffffc020486e:	bfd5                	j	ffffffffc0204862 <cpu_idle+0xe>

ffffffffc0204870 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204870:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204874:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204878:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020487a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020487c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204880:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204884:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204888:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020488c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204890:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204894:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204898:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020489c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02048a0:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02048a4:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02048a8:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02048ac:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02048ae:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02048b0:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02048b4:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02048b8:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02048bc:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02048c0:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02048c4:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02048c8:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02048cc:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02048d0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02048d4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02048d8:	8082                	ret

ffffffffc02048da <schedule>:
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
ffffffffc02048da:	1141                	addi	sp,sp,-16
ffffffffc02048dc:	e406                	sd	ra,8(sp)
ffffffffc02048de:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02048e0:	100027f3          	csrr	a5,sstatus
ffffffffc02048e4:	8b89                	andi	a5,a5,2
ffffffffc02048e6:	4401                	li	s0,0
ffffffffc02048e8:	efbd                	bnez	a5,ffffffffc0204966 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02048ea:	00011897          	auipc	a7,0x11
ffffffffc02048ee:	cc68b883          	ld	a7,-826(a7) # ffffffffc02155b0 <current>
ffffffffc02048f2:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02048f6:	00011517          	auipc	a0,0x11
ffffffffc02048fa:	cc253503          	ld	a0,-830(a0) # ffffffffc02155b8 <idleproc>
ffffffffc02048fe:	04a88e63          	beq	a7,a0,ffffffffc020495a <schedule+0x80>
ffffffffc0204902:	0c888693          	addi	a3,a7,200
ffffffffc0204906:	00011617          	auipc	a2,0x11
ffffffffc020490a:	c2260613          	addi	a2,a2,-990 # ffffffffc0215528 <proc_list>
        le = last;
ffffffffc020490e:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0204910:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204912:	4809                	li	a6,2
ffffffffc0204914:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0204916:	00c78863          	beq	a5,a2,ffffffffc0204926 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020491a:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020491e:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204922:	03070163          	beq	a4,a6,ffffffffc0204944 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204926:	fef697e3          	bne	a3,a5,ffffffffc0204914 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020492a:	ed89                	bnez	a1,ffffffffc0204944 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020492c:	451c                	lw	a5,8(a0)
ffffffffc020492e:	2785                	addiw	a5,a5,1
ffffffffc0204930:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204932:	00a88463          	beq	a7,a0,ffffffffc020493a <schedule+0x60>
            proc_run(next);
ffffffffc0204936:	9dfff0ef          	jal	ra,ffffffffc0204314 <proc_run>
    if (flag) {
ffffffffc020493a:	e819                	bnez	s0,ffffffffc0204950 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020493c:	60a2                	ld	ra,8(sp)
ffffffffc020493e:	6402                	ld	s0,0(sp)
ffffffffc0204940:	0141                	addi	sp,sp,16
ffffffffc0204942:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204944:	4198                	lw	a4,0(a1)
ffffffffc0204946:	4789                	li	a5,2
ffffffffc0204948:	fef712e3          	bne	a4,a5,ffffffffc020492c <schedule+0x52>
ffffffffc020494c:	852e                	mv	a0,a1
ffffffffc020494e:	bff9                	j	ffffffffc020492c <schedule+0x52>
}
ffffffffc0204950:	6402                	ld	s0,0(sp)
ffffffffc0204952:	60a2                	ld	ra,8(sp)
ffffffffc0204954:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0204956:	c67fb06f          	j	ffffffffc02005bc <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020495a:	00011617          	auipc	a2,0x11
ffffffffc020495e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0215528 <proc_list>
ffffffffc0204962:	86b2                	mv	a3,a2
ffffffffc0204964:	b76d                	j	ffffffffc020490e <schedule+0x34>
        intr_disable();
ffffffffc0204966:	c5dfb0ef          	jal	ra,ffffffffc02005c2 <intr_disable>
        return 1;
ffffffffc020496a:	4405                	li	s0,1
ffffffffc020496c:	bfbd                	j	ffffffffc02048ea <schedule+0x10>

ffffffffc020496e <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020496e:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204972:	2785                	addiw	a5,a5,1
ffffffffc0204974:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0204978:	02000793          	li	a5,32
ffffffffc020497c:	9f8d                	subw	a5,a5,a1
}
ffffffffc020497e:	00f5553b          	srlw	a0,a0,a5
ffffffffc0204982:	8082                	ret

ffffffffc0204984 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204984:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204988:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020498a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020498e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204990:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204994:	f022                	sd	s0,32(sp)
ffffffffc0204996:	ec26                	sd	s1,24(sp)
ffffffffc0204998:	e84a                	sd	s2,16(sp)
ffffffffc020499a:	f406                	sd	ra,40(sp)
ffffffffc020499c:	e44e                	sd	s3,8(sp)
ffffffffc020499e:	84aa                	mv	s1,a0
ffffffffc02049a0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02049a2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02049a6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02049a8:	03067e63          	bgeu	a2,a6,ffffffffc02049e4 <printnum+0x60>
ffffffffc02049ac:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02049ae:	00805763          	blez	s0,ffffffffc02049bc <printnum+0x38>
ffffffffc02049b2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02049b4:	85ca                	mv	a1,s2
ffffffffc02049b6:	854e                	mv	a0,s3
ffffffffc02049b8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02049ba:	fc65                	bnez	s0,ffffffffc02049b2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02049bc:	1a02                	slli	s4,s4,0x20
ffffffffc02049be:	00002797          	auipc	a5,0x2
ffffffffc02049c2:	2ea78793          	addi	a5,a5,746 # ffffffffc0206ca8 <default_pmm_manager+0x1118>
ffffffffc02049c6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02049ca:	9a3e                	add	s4,s4,a5
}
ffffffffc02049cc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02049ce:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02049d2:	70a2                	ld	ra,40(sp)
ffffffffc02049d4:	69a2                	ld	s3,8(sp)
ffffffffc02049d6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02049d8:	85ca                	mv	a1,s2
ffffffffc02049da:	87a6                	mv	a5,s1
}
ffffffffc02049dc:	6942                	ld	s2,16(sp)
ffffffffc02049de:	64e2                	ld	s1,24(sp)
ffffffffc02049e0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02049e2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02049e4:	03065633          	divu	a2,a2,a6
ffffffffc02049e8:	8722                	mv	a4,s0
ffffffffc02049ea:	f9bff0ef          	jal	ra,ffffffffc0204984 <printnum>
ffffffffc02049ee:	b7f9                	j	ffffffffc02049bc <printnum+0x38>

ffffffffc02049f0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02049f0:	7119                	addi	sp,sp,-128
ffffffffc02049f2:	f4a6                	sd	s1,104(sp)
ffffffffc02049f4:	f0ca                	sd	s2,96(sp)
ffffffffc02049f6:	ecce                	sd	s3,88(sp)
ffffffffc02049f8:	e8d2                	sd	s4,80(sp)
ffffffffc02049fa:	e4d6                	sd	s5,72(sp)
ffffffffc02049fc:	e0da                	sd	s6,64(sp)
ffffffffc02049fe:	fc5e                	sd	s7,56(sp)
ffffffffc0204a00:	f06a                	sd	s10,32(sp)
ffffffffc0204a02:	fc86                	sd	ra,120(sp)
ffffffffc0204a04:	f8a2                	sd	s0,112(sp)
ffffffffc0204a06:	f862                	sd	s8,48(sp)
ffffffffc0204a08:	f466                	sd	s9,40(sp)
ffffffffc0204a0a:	ec6e                	sd	s11,24(sp)
ffffffffc0204a0c:	892a                	mv	s2,a0
ffffffffc0204a0e:	84ae                	mv	s1,a1
ffffffffc0204a10:	8d32                	mv	s10,a2
ffffffffc0204a12:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204a14:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204a18:	5b7d                	li	s6,-1
ffffffffc0204a1a:	00002a97          	auipc	s5,0x2
ffffffffc0204a1e:	2baa8a93          	addi	s5,s5,698 # ffffffffc0206cd4 <default_pmm_manager+0x1144>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204a22:	00002b97          	auipc	s7,0x2
ffffffffc0204a26:	48eb8b93          	addi	s7,s7,1166 # ffffffffc0206eb0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204a2a:	000d4503          	lbu	a0,0(s10)
ffffffffc0204a2e:	001d0413          	addi	s0,s10,1
ffffffffc0204a32:	01350a63          	beq	a0,s3,ffffffffc0204a46 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0204a36:	c121                	beqz	a0,ffffffffc0204a76 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0204a38:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204a3a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204a3c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204a3e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204a42:	ff351ae3          	bne	a0,s3,ffffffffc0204a36 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204a46:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204a4a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204a4e:	4c81                	li	s9,0
ffffffffc0204a50:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204a52:	5c7d                	li	s8,-1
ffffffffc0204a54:	5dfd                	li	s11,-1
ffffffffc0204a56:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0204a5a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204a5c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204a60:	0ff5f593          	andi	a1,a1,255
ffffffffc0204a64:	00140d13          	addi	s10,s0,1
ffffffffc0204a68:	04b56263          	bltu	a0,a1,ffffffffc0204aac <vprintfmt+0xbc>
ffffffffc0204a6c:	058a                	slli	a1,a1,0x2
ffffffffc0204a6e:	95d6                	add	a1,a1,s5
ffffffffc0204a70:	4194                	lw	a3,0(a1)
ffffffffc0204a72:	96d6                	add	a3,a3,s5
ffffffffc0204a74:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204a76:	70e6                	ld	ra,120(sp)
ffffffffc0204a78:	7446                	ld	s0,112(sp)
ffffffffc0204a7a:	74a6                	ld	s1,104(sp)
ffffffffc0204a7c:	7906                	ld	s2,96(sp)
ffffffffc0204a7e:	69e6                	ld	s3,88(sp)
ffffffffc0204a80:	6a46                	ld	s4,80(sp)
ffffffffc0204a82:	6aa6                	ld	s5,72(sp)
ffffffffc0204a84:	6b06                	ld	s6,64(sp)
ffffffffc0204a86:	7be2                	ld	s7,56(sp)
ffffffffc0204a88:	7c42                	ld	s8,48(sp)
ffffffffc0204a8a:	7ca2                	ld	s9,40(sp)
ffffffffc0204a8c:	7d02                	ld	s10,32(sp)
ffffffffc0204a8e:	6de2                	ld	s11,24(sp)
ffffffffc0204a90:	6109                	addi	sp,sp,128
ffffffffc0204a92:	8082                	ret
            padc = '0';
ffffffffc0204a94:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204a96:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204a9a:	846a                	mv	s0,s10
ffffffffc0204a9c:	00140d13          	addi	s10,s0,1
ffffffffc0204aa0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204aa4:	0ff5f593          	andi	a1,a1,255
ffffffffc0204aa8:	fcb572e3          	bgeu	a0,a1,ffffffffc0204a6c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0204aac:	85a6                	mv	a1,s1
ffffffffc0204aae:	02500513          	li	a0,37
ffffffffc0204ab2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204ab4:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204ab8:	8d22                	mv	s10,s0
ffffffffc0204aba:	f73788e3          	beq	a5,s3,ffffffffc0204a2a <vprintfmt+0x3a>
ffffffffc0204abe:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204ac2:	1d7d                	addi	s10,s10,-1
ffffffffc0204ac4:	ff379de3          	bne	a5,s3,ffffffffc0204abe <vprintfmt+0xce>
ffffffffc0204ac8:	b78d                	j	ffffffffc0204a2a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204aca:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0204ace:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204ad2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204ad4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204ad8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204adc:	02d86463          	bltu	a6,a3,ffffffffc0204b04 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0204ae0:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204ae4:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204ae8:	0186873b          	addw	a4,a3,s8
ffffffffc0204aec:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204af0:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204af2:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204af6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204af8:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0204afc:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204b00:	fed870e3          	bgeu	a6,a3,ffffffffc0204ae0 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0204b04:	f40ddce3          	bgez	s11,ffffffffc0204a5c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0204b08:	8de2                	mv	s11,s8
ffffffffc0204b0a:	5c7d                	li	s8,-1
ffffffffc0204b0c:	bf81                	j	ffffffffc0204a5c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204b0e:	fffdc693          	not	a3,s11
ffffffffc0204b12:	96fd                	srai	a3,a3,0x3f
ffffffffc0204b14:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b18:	00144603          	lbu	a2,1(s0)
ffffffffc0204b1c:	2d81                	sext.w	s11,s11
ffffffffc0204b1e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204b20:	bf35                	j	ffffffffc0204a5c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204b22:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b26:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204b2a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b2c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204b2e:	bfd9                	j	ffffffffc0204b04 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204b30:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204b32:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204b36:	01174463          	blt	a4,a7,ffffffffc0204b3e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0204b3a:	1a088e63          	beqz	a7,ffffffffc0204cf6 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0204b3e:	000a3603          	ld	a2,0(s4)
ffffffffc0204b42:	46c1                	li	a3,16
ffffffffc0204b44:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204b46:	2781                	sext.w	a5,a5
ffffffffc0204b48:	876e                	mv	a4,s11
ffffffffc0204b4a:	85a6                	mv	a1,s1
ffffffffc0204b4c:	854a                	mv	a0,s2
ffffffffc0204b4e:	e37ff0ef          	jal	ra,ffffffffc0204984 <printnum>
            break;
ffffffffc0204b52:	bde1                	j	ffffffffc0204a2a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204b54:	000a2503          	lw	a0,0(s4)
ffffffffc0204b58:	85a6                	mv	a1,s1
ffffffffc0204b5a:	0a21                	addi	s4,s4,8
ffffffffc0204b5c:	9902                	jalr	s2
            break;
ffffffffc0204b5e:	b5f1                	j	ffffffffc0204a2a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204b60:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204b62:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204b66:	01174463          	blt	a4,a7,ffffffffc0204b6e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0204b6a:	18088163          	beqz	a7,ffffffffc0204cec <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0204b6e:	000a3603          	ld	a2,0(s4)
ffffffffc0204b72:	46a9                	li	a3,10
ffffffffc0204b74:	8a2e                	mv	s4,a1
ffffffffc0204b76:	bfc1                	j	ffffffffc0204b46 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b78:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204b7c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b7e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204b80:	bdf1                	j	ffffffffc0204a5c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204b82:	85a6                	mv	a1,s1
ffffffffc0204b84:	02500513          	li	a0,37
ffffffffc0204b88:	9902                	jalr	s2
            break;
ffffffffc0204b8a:	b545                	j	ffffffffc0204a2a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b8c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0204b90:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b92:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204b94:	b5e1                	j	ffffffffc0204a5c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204b96:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204b98:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204b9c:	01174463          	blt	a4,a7,ffffffffc0204ba4 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204ba0:	14088163          	beqz	a7,ffffffffc0204ce2 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204ba4:	000a3603          	ld	a2,0(s4)
ffffffffc0204ba8:	46a1                	li	a3,8
ffffffffc0204baa:	8a2e                	mv	s4,a1
ffffffffc0204bac:	bf69                	j	ffffffffc0204b46 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0204bae:	03000513          	li	a0,48
ffffffffc0204bb2:	85a6                	mv	a1,s1
ffffffffc0204bb4:	e03e                	sd	a5,0(sp)
ffffffffc0204bb6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204bb8:	85a6                	mv	a1,s1
ffffffffc0204bba:	07800513          	li	a0,120
ffffffffc0204bbe:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204bc0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204bc2:	6782                	ld	a5,0(sp)
ffffffffc0204bc4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204bc6:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204bca:	bfb5                	j	ffffffffc0204b46 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204bcc:	000a3403          	ld	s0,0(s4)
ffffffffc0204bd0:	008a0713          	addi	a4,s4,8
ffffffffc0204bd4:	e03a                	sd	a4,0(sp)
ffffffffc0204bd6:	14040263          	beqz	s0,ffffffffc0204d1a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204bda:	0fb05763          	blez	s11,ffffffffc0204cc8 <vprintfmt+0x2d8>
ffffffffc0204bde:	02d00693          	li	a3,45
ffffffffc0204be2:	0cd79163          	bne	a5,a3,ffffffffc0204ca4 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204be6:	00044783          	lbu	a5,0(s0)
ffffffffc0204bea:	0007851b          	sext.w	a0,a5
ffffffffc0204bee:	cf85                	beqz	a5,ffffffffc0204c26 <vprintfmt+0x236>
ffffffffc0204bf0:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204bf4:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204bf8:	000c4563          	bltz	s8,ffffffffc0204c02 <vprintfmt+0x212>
ffffffffc0204bfc:	3c7d                	addiw	s8,s8,-1
ffffffffc0204bfe:	036c0263          	beq	s8,s6,ffffffffc0204c22 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204c02:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204c04:	0e0c8e63          	beqz	s9,ffffffffc0204d00 <vprintfmt+0x310>
ffffffffc0204c08:	3781                	addiw	a5,a5,-32
ffffffffc0204c0a:	0ef47b63          	bgeu	s0,a5,ffffffffc0204d00 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204c0e:	03f00513          	li	a0,63
ffffffffc0204c12:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204c14:	000a4783          	lbu	a5,0(s4)
ffffffffc0204c18:	3dfd                	addiw	s11,s11,-1
ffffffffc0204c1a:	0a05                	addi	s4,s4,1
ffffffffc0204c1c:	0007851b          	sext.w	a0,a5
ffffffffc0204c20:	ffe1                	bnez	a5,ffffffffc0204bf8 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204c22:	01b05963          	blez	s11,ffffffffc0204c34 <vprintfmt+0x244>
ffffffffc0204c26:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204c28:	85a6                	mv	a1,s1
ffffffffc0204c2a:	02000513          	li	a0,32
ffffffffc0204c2e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204c30:	fe0d9be3          	bnez	s11,ffffffffc0204c26 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204c34:	6a02                	ld	s4,0(sp)
ffffffffc0204c36:	bbd5                	j	ffffffffc0204a2a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204c38:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204c3a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0204c3e:	01174463          	blt	a4,a7,ffffffffc0204c46 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0204c42:	08088d63          	beqz	a7,ffffffffc0204cdc <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0204c46:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204c4a:	0a044d63          	bltz	s0,ffffffffc0204d04 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0204c4e:	8622                	mv	a2,s0
ffffffffc0204c50:	8a66                	mv	s4,s9
ffffffffc0204c52:	46a9                	li	a3,10
ffffffffc0204c54:	bdcd                	j	ffffffffc0204b46 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204c56:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204c5a:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204c5c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0204c5e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204c62:	8fb5                	xor	a5,a5,a3
ffffffffc0204c64:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204c68:	02d74163          	blt	a4,a3,ffffffffc0204c8a <vprintfmt+0x29a>
ffffffffc0204c6c:	00369793          	slli	a5,a3,0x3
ffffffffc0204c70:	97de                	add	a5,a5,s7
ffffffffc0204c72:	639c                	ld	a5,0(a5)
ffffffffc0204c74:	cb99                	beqz	a5,ffffffffc0204c8a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204c76:	86be                	mv	a3,a5
ffffffffc0204c78:	00000617          	auipc	a2,0x0
ffffffffc0204c7c:	1f060613          	addi	a2,a2,496 # ffffffffc0204e68 <etext+0x2c>
ffffffffc0204c80:	85a6                	mv	a1,s1
ffffffffc0204c82:	854a                	mv	a0,s2
ffffffffc0204c84:	0ce000ef          	jal	ra,ffffffffc0204d52 <printfmt>
ffffffffc0204c88:	b34d                	j	ffffffffc0204a2a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204c8a:	00002617          	auipc	a2,0x2
ffffffffc0204c8e:	03e60613          	addi	a2,a2,62 # ffffffffc0206cc8 <default_pmm_manager+0x1138>
ffffffffc0204c92:	85a6                	mv	a1,s1
ffffffffc0204c94:	854a                	mv	a0,s2
ffffffffc0204c96:	0bc000ef          	jal	ra,ffffffffc0204d52 <printfmt>
ffffffffc0204c9a:	bb41                	j	ffffffffc0204a2a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204c9c:	00002417          	auipc	s0,0x2
ffffffffc0204ca0:	02440413          	addi	s0,s0,36 # ffffffffc0206cc0 <default_pmm_manager+0x1130>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204ca4:	85e2                	mv	a1,s8
ffffffffc0204ca6:	8522                	mv	a0,s0
ffffffffc0204ca8:	e43e                	sd	a5,8(sp)
ffffffffc0204caa:	0e2000ef          	jal	ra,ffffffffc0204d8c <strnlen>
ffffffffc0204cae:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204cb2:	01b05b63          	blez	s11,ffffffffc0204cc8 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204cb6:	67a2                	ld	a5,8(sp)
ffffffffc0204cb8:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204cbc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204cbe:	85a6                	mv	a1,s1
ffffffffc0204cc0:	8552                	mv	a0,s4
ffffffffc0204cc2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204cc4:	fe0d9ce3          	bnez	s11,ffffffffc0204cbc <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cc8:	00044783          	lbu	a5,0(s0)
ffffffffc0204ccc:	00140a13          	addi	s4,s0,1
ffffffffc0204cd0:	0007851b          	sext.w	a0,a5
ffffffffc0204cd4:	d3a5                	beqz	a5,ffffffffc0204c34 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204cd6:	05e00413          	li	s0,94
ffffffffc0204cda:	bf39                	j	ffffffffc0204bf8 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0204cdc:	000a2403          	lw	s0,0(s4)
ffffffffc0204ce0:	b7ad                	j	ffffffffc0204c4a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204ce2:	000a6603          	lwu	a2,0(s4)
ffffffffc0204ce6:	46a1                	li	a3,8
ffffffffc0204ce8:	8a2e                	mv	s4,a1
ffffffffc0204cea:	bdb1                	j	ffffffffc0204b46 <vprintfmt+0x156>
ffffffffc0204cec:	000a6603          	lwu	a2,0(s4)
ffffffffc0204cf0:	46a9                	li	a3,10
ffffffffc0204cf2:	8a2e                	mv	s4,a1
ffffffffc0204cf4:	bd89                	j	ffffffffc0204b46 <vprintfmt+0x156>
ffffffffc0204cf6:	000a6603          	lwu	a2,0(s4)
ffffffffc0204cfa:	46c1                	li	a3,16
ffffffffc0204cfc:	8a2e                	mv	s4,a1
ffffffffc0204cfe:	b5a1                	j	ffffffffc0204b46 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0204d00:	9902                	jalr	s2
ffffffffc0204d02:	bf09                	j	ffffffffc0204c14 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0204d04:	85a6                	mv	a1,s1
ffffffffc0204d06:	02d00513          	li	a0,45
ffffffffc0204d0a:	e03e                	sd	a5,0(sp)
ffffffffc0204d0c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204d0e:	6782                	ld	a5,0(sp)
ffffffffc0204d10:	8a66                	mv	s4,s9
ffffffffc0204d12:	40800633          	neg	a2,s0
ffffffffc0204d16:	46a9                	li	a3,10
ffffffffc0204d18:	b53d                	j	ffffffffc0204b46 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204d1a:	03b05163          	blez	s11,ffffffffc0204d3c <vprintfmt+0x34c>
ffffffffc0204d1e:	02d00693          	li	a3,45
ffffffffc0204d22:	f6d79de3          	bne	a5,a3,ffffffffc0204c9c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0204d26:	00002417          	auipc	s0,0x2
ffffffffc0204d2a:	f9a40413          	addi	s0,s0,-102 # ffffffffc0206cc0 <default_pmm_manager+0x1130>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d2e:	02800793          	li	a5,40
ffffffffc0204d32:	02800513          	li	a0,40
ffffffffc0204d36:	00140a13          	addi	s4,s0,1
ffffffffc0204d3a:	bd6d                	j	ffffffffc0204bf4 <vprintfmt+0x204>
ffffffffc0204d3c:	00002a17          	auipc	s4,0x2
ffffffffc0204d40:	f85a0a13          	addi	s4,s4,-123 # ffffffffc0206cc1 <default_pmm_manager+0x1131>
ffffffffc0204d44:	02800513          	li	a0,40
ffffffffc0204d48:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204d4c:	05e00413          	li	s0,94
ffffffffc0204d50:	b565                	j	ffffffffc0204bf8 <vprintfmt+0x208>

ffffffffc0204d52 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204d52:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204d54:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204d58:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204d5a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204d5c:	ec06                	sd	ra,24(sp)
ffffffffc0204d5e:	f83a                	sd	a4,48(sp)
ffffffffc0204d60:	fc3e                	sd	a5,56(sp)
ffffffffc0204d62:	e0c2                	sd	a6,64(sp)
ffffffffc0204d64:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204d66:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204d68:	c89ff0ef          	jal	ra,ffffffffc02049f0 <vprintfmt>
}
ffffffffc0204d6c:	60e2                	ld	ra,24(sp)
ffffffffc0204d6e:	6161                	addi	sp,sp,80
ffffffffc0204d70:	8082                	ret

ffffffffc0204d72 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204d72:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204d76:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204d78:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204d7a:	cb81                	beqz	a5,ffffffffc0204d8a <strlen+0x18>
        cnt ++;
ffffffffc0204d7c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204d7e:	00a707b3          	add	a5,a4,a0
ffffffffc0204d82:	0007c783          	lbu	a5,0(a5)
ffffffffc0204d86:	fbfd                	bnez	a5,ffffffffc0204d7c <strlen+0xa>
ffffffffc0204d88:	8082                	ret
    }
    return cnt;
}
ffffffffc0204d8a:	8082                	ret

ffffffffc0204d8c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204d8c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204d8e:	e589                	bnez	a1,ffffffffc0204d98 <strnlen+0xc>
ffffffffc0204d90:	a811                	j	ffffffffc0204da4 <strnlen+0x18>
        cnt ++;
ffffffffc0204d92:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204d94:	00f58863          	beq	a1,a5,ffffffffc0204da4 <strnlen+0x18>
ffffffffc0204d98:	00f50733          	add	a4,a0,a5
ffffffffc0204d9c:	00074703          	lbu	a4,0(a4)
ffffffffc0204da0:	fb6d                	bnez	a4,ffffffffc0204d92 <strnlen+0x6>
ffffffffc0204da2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204da4:	852e                	mv	a0,a1
ffffffffc0204da6:	8082                	ret

ffffffffc0204da8 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204da8:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204daa:	0005c703          	lbu	a4,0(a1)
ffffffffc0204dae:	0785                	addi	a5,a5,1
ffffffffc0204db0:	0585                	addi	a1,a1,1
ffffffffc0204db2:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204db6:	fb75                	bnez	a4,ffffffffc0204daa <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204db8:	8082                	ret

ffffffffc0204dba <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204dba:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204dbe:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204dc2:	cb89                	beqz	a5,ffffffffc0204dd4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0204dc4:	0505                	addi	a0,a0,1
ffffffffc0204dc6:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204dc8:	fee789e3          	beq	a5,a4,ffffffffc0204dba <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204dcc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204dd0:	9d19                	subw	a0,a0,a4
ffffffffc0204dd2:	8082                	ret
ffffffffc0204dd4:	4501                	li	a0,0
ffffffffc0204dd6:	bfed                	j	ffffffffc0204dd0 <strcmp+0x16>

ffffffffc0204dd8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204dd8:	00054783          	lbu	a5,0(a0)
ffffffffc0204ddc:	c799                	beqz	a5,ffffffffc0204dea <strchr+0x12>
        if (*s == c) {
ffffffffc0204dde:	00f58763          	beq	a1,a5,ffffffffc0204dec <strchr+0x14>
    while (*s != '\0') {
ffffffffc0204de2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204de6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204de8:	fbfd                	bnez	a5,ffffffffc0204dde <strchr+0x6>
    }
    return NULL;
ffffffffc0204dea:	4501                	li	a0,0
}
ffffffffc0204dec:	8082                	ret

ffffffffc0204dee <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204dee:	ca01                	beqz	a2,ffffffffc0204dfe <memset+0x10>
ffffffffc0204df0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204df2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204df4:	0785                	addi	a5,a5,1
ffffffffc0204df6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204dfa:	fec79de3          	bne	a5,a2,ffffffffc0204df4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204dfe:	8082                	ret

ffffffffc0204e00 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204e00:	ca19                	beqz	a2,ffffffffc0204e16 <memcpy+0x16>
ffffffffc0204e02:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204e04:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204e06:	0005c703          	lbu	a4,0(a1)
ffffffffc0204e0a:	0585                	addi	a1,a1,1
ffffffffc0204e0c:	0785                	addi	a5,a5,1
ffffffffc0204e0e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204e12:	fec59ae3          	bne	a1,a2,ffffffffc0204e06 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204e16:	8082                	ret

ffffffffc0204e18 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204e18:	c205                	beqz	a2,ffffffffc0204e38 <memcmp+0x20>
ffffffffc0204e1a:	962e                	add	a2,a2,a1
ffffffffc0204e1c:	a019                	j	ffffffffc0204e22 <memcmp+0xa>
ffffffffc0204e1e:	00c58d63          	beq	a1,a2,ffffffffc0204e38 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204e22:	00054783          	lbu	a5,0(a0)
ffffffffc0204e26:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204e2a:	0505                	addi	a0,a0,1
ffffffffc0204e2c:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204e2e:	fee788e3          	beq	a5,a4,ffffffffc0204e1e <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204e32:	40e7853b          	subw	a0,a5,a4
ffffffffc0204e36:	8082                	ret
    }
    return 0;
ffffffffc0204e38:	4501                	li	a0,0
}
ffffffffc0204e3a:	8082                	ret
