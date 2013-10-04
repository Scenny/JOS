
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f0100055:	e8 08 0b 00 00       	call   f0100b62 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 78 08 00 00       	call   f01008ff <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 1c 1d 10 f0 	movl   $0xf0101d1c,(%esp)
f0100092:	e8 cb 0a 00 00       	call   f0100b62 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 f0 16 00 00       	call   f01017b5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 37 1d 10 f0 	movl   $0xf0101d37,(%esp)
f01000d9:	e8 84 0a 00 00       	call   f0100b62 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 cc 08 00 00       	call   f01009c2 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 52 1d 10 f0 	movl   $0xf0101d52,(%esp)
f010012c:	e8 31 0a 00 00       	call   f0100b62 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 f2 09 00 00       	call   f0100b2f <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 8e 1d 10 f0 	movl   $0xf0101d8e,(%esp)
f0100144:	e8 19 0a 00 00       	call   f0100b62 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 6d 08 00 00       	call   f01009c2 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 6a 1d 10 f0 	movl   $0xf0101d6a,(%esp)
f0100176:	e8 e7 09 00 00       	call   f0100b62 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 a5 09 00 00       	call   f0100b2f <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 8e 1d 10 f0 	movl   $0xf0101d8e,(%esp)
f0100191:	e8 cc 09 00 00       	call   f0100b62 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 1c             	sub    $0x1c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010021b:	a8 20                	test   $0x20,%al
f010021d:	75 1b                	jne    f010023a <cons_putc+0x30>
f010021f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100224:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100229:	e8 72 ff ff ff       	call   f01001a0 <delay>
f010022e:	89 f2                	mov    %esi,%edx
f0100230:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100231:	a8 20                	test   $0x20,%al
f0100233:	75 05                	jne    f010023a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100235:	83 eb 01             	sub    $0x1,%ebx
f0100238:	75 ef                	jne    f0100229 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010023a:	81 e7 ff 00 00 00    	and    $0xff,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100240:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100245:	89 f8                	mov    %edi,%eax
f0100247:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100248:	b2 79                	mov    $0x79,%dl
f010024a:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024b:	84 c0                	test   %al,%al
f010024d:	78 1b                	js     f010026a <cons_putc+0x60>
f010024f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100254:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100259:	e8 42 ff ff ff       	call   f01001a0 <delay>
f010025e:	89 f2                	mov    %esi,%edx
f0100260:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100261:	84 c0                	test   %al,%al
f0100263:	78 05                	js     f010026a <cons_putc+0x60>
f0100265:	83 eb 01             	sub    $0x1,%ebx
f0100268:	75 ef                	jne    f0100259 <cons_putc+0x4f>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 78 03 00 00       	mov    $0x378,%edx
f010026f:	89 f8                	mov    %edi,%eax
f0100271:	ee                   	out    %al,(%dx)
f0100272:	b2 7a                	mov    $0x7a,%dl
f0100274:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100279:	ee                   	out    %al,(%dx)
f010027a:	b8 08 00 00 00       	mov    $0x8,%eax
f010027f:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c &= 0xFF;
	c |= ftcolor << 8;
f0100280:	a1 38 25 11 f0       	mov    0xf0112538,%eax
f0100285:	c1 e0 08             	shl    $0x8,%eax
f0100288:	89 fb                	mov    %edi,%ebx
f010028a:	09 c3                	or     %eax,%ebx
	if (!(c & ~0xFF))
f010028c:	89 da                	mov    %ebx,%edx
f010028e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100294:	89 d8                	mov    %ebx,%eax
f0100296:	80 cc 07             	or     $0x7,%ah
f0100299:	85 d2                	test   %edx,%edx
f010029b:	0f 44 d8             	cmove  %eax,%ebx

	switch (c & 0xff) {
f010029e:	0f b6 c3             	movzbl %bl,%eax
f01002a1:	83 f8 09             	cmp    $0x9,%eax
f01002a4:	74 7b                	je     f0100321 <cons_putc+0x117>
f01002a6:	83 f8 09             	cmp    $0x9,%eax
f01002a9:	7f 0b                	jg     f01002b6 <cons_putc+0xac>
f01002ab:	83 f8 08             	cmp    $0x8,%eax
f01002ae:	0f 85 a1 00 00 00    	jne    f0100355 <cons_putc+0x14b>
f01002b4:	eb 12                	jmp    f01002c8 <cons_putc+0xbe>
f01002b6:	83 f8 0a             	cmp    $0xa,%eax
f01002b9:	74 40                	je     f01002fb <cons_putc+0xf1>
f01002bb:	83 f8 0d             	cmp    $0xd,%eax
f01002be:	66 90                	xchg   %ax,%ax
f01002c0:	0f 85 8f 00 00 00    	jne    f0100355 <cons_putc+0x14b>
f01002c6:	eb 3b                	jmp    f0100303 <cons_putc+0xf9>
	case '\b':
		if (crt_pos > 0) {
f01002c8:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002cf:	66 85 c0             	test   %ax,%ax
f01002d2:	0f 84 e7 00 00 00    	je     f01003bf <cons_putc+0x1b5>
			crt_pos--;
f01002d8:	83 e8 01             	sub    $0x1,%eax
f01002db:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002e1:	0f b7 c0             	movzwl %ax,%eax
f01002e4:	89 df                	mov    %ebx,%edi
f01002e6:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002ec:	83 cf 20             	or     $0x20,%edi
f01002ef:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002f5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f9:	eb 77                	jmp    f0100372 <cons_putc+0x168>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002fb:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f0100302:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100303:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f010030a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100310:	c1 e8 16             	shr    $0x16,%eax
f0100313:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100316:	c1 e0 04             	shl    $0x4,%eax
f0100319:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f010031f:	eb 51                	jmp    f0100372 <cons_putc+0x168>
		break;
	case '\t':
		cons_putc(' ');
f0100321:	b8 20 00 00 00       	mov    $0x20,%eax
f0100326:	e8 df fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100330:	e8 d5 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100335:	b8 20 00 00 00       	mov    $0x20,%eax
f010033a:	e8 cb fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010033f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100344:	e8 c1 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100349:	b8 20 00 00 00       	mov    $0x20,%eax
f010034e:	e8 b7 fe ff ff       	call   f010020a <cons_putc>
f0100353:	eb 1d                	jmp    f0100372 <cons_putc+0x168>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100355:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f010035c:	0f b7 c8             	movzwl %ax,%ecx
f010035f:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f0100365:	66 89 1c 4a          	mov    %bx,(%edx,%ecx,2)
f0100369:	83 c0 01             	add    $0x1,%eax
f010036c:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100372:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100379:	cf 07 
f010037b:	76 42                	jbe    f01003bf <cons_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010037d:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100382:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100389:	00 
f010038a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100390:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100394:	89 04 24             	mov    %eax,(%esp)
f0100397:	e8 77 14 00 00       	call   f0101813 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010039c:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a2:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01003a7:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003ad:	83 c0 01             	add    $0x1,%eax
f01003b0:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003b5:	75 f0                	jne    f01003a7 <cons_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003b7:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003be:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003bf:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003c5:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003ca:	89 ca                	mov    %ecx,%edx
f01003cc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003cd:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003d4:	8d 71 01             	lea    0x1(%ecx),%esi
f01003d7:	89 d8                	mov    %ebx,%eax
f01003d9:	66 c1 e8 08          	shr    $0x8,%ax
f01003dd:	89 f2                	mov    %esi,%edx
f01003df:	ee                   	out    %al,(%dx)
f01003e0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003e5:	89 ca                	mov    %ecx,%edx
f01003e7:	ee                   	out    %al,(%dx)
f01003e8:	89 d8                	mov    %ebx,%eax
f01003ea:	89 f2                	mov    %esi,%edx
f01003ec:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003ed:	83 c4 1c             	add    $0x1c,%esp
f01003f0:	5b                   	pop    %ebx
f01003f1:	5e                   	pop    %esi
f01003f2:	5f                   	pop    %edi
f01003f3:	5d                   	pop    %ebp
f01003f4:	c3                   	ret    

f01003f5 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003f5:	55                   	push   %ebp
f01003f6:	89 e5                	mov    %esp,%ebp
f01003f8:	53                   	push   %ebx
f01003f9:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003fc:	ba 64 00 00 00       	mov    $0x64,%edx
f0100401:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100402:	a8 01                	test   $0x1,%al
f0100404:	0f 84 e5 00 00 00    	je     f01004ef <kbd_proc_data+0xfa>
f010040a:	b2 60                	mov    $0x60,%dl
f010040c:	ec                   	in     (%dx),%al
f010040d:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040f:	3c e0                	cmp    $0xe0,%al
f0100411:	75 11                	jne    f0100424 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f0100413:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f010041a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041f:	e9 d0 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f0100424:	84 c0                	test   %al,%al
f0100426:	79 37                	jns    f010045f <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100428:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010042e:	89 cb                	mov    %ecx,%ebx
f0100430:	83 e3 40             	and    $0x40,%ebx
f0100433:	83 e0 7f             	and    $0x7f,%eax
f0100436:	85 db                	test   %ebx,%ebx
f0100438:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010043b:	0f b6 d2             	movzbl %dl,%edx
f010043e:	0f b6 82 c0 1d 10 f0 	movzbl -0xfefe240(%edx),%eax
f0100445:	83 c8 40             	or     $0x40,%eax
f0100448:	0f b6 c0             	movzbl %al,%eax
f010044b:	f7 d0                	not    %eax
f010044d:	21 c1                	and    %eax,%ecx
f010044f:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100455:	bb 00 00 00 00       	mov    $0x0,%ebx
f010045a:	e9 95 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f010045f:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100465:	f6 c1 40             	test   $0x40,%cl
f0100468:	74 0e                	je     f0100478 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010046a:	89 c2                	mov    %eax,%edx
f010046c:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046f:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100472:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100478:	0f b6 d2             	movzbl %dl,%edx
f010047b:	0f b6 82 c0 1d 10 f0 	movzbl -0xfefe240(%edx),%eax
f0100482:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100488:	0f b6 8a c0 1e 10 f0 	movzbl -0xfefe140(%edx),%ecx
f010048f:	31 c8                	xor    %ecx,%eax
f0100491:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100496:	89 c1                	mov    %eax,%ecx
f0100498:	83 e1 03             	and    $0x3,%ecx
f010049b:	8b 0c 8d c0 1f 10 f0 	mov    -0xfefe040(,%ecx,4),%ecx
f01004a2:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01004a6:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01004a9:	a8 08                	test   $0x8,%al
f01004ab:	74 1b                	je     f01004c8 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004ad:	89 da                	mov    %ebx,%edx
f01004af:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004b2:	83 f9 19             	cmp    $0x19,%ecx
f01004b5:	77 05                	ja     f01004bc <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004b7:	83 eb 20             	sub    $0x20,%ebx
f01004ba:	eb 0c                	jmp    f01004c8 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004bc:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004bf:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004c2:	83 fa 19             	cmp    $0x19,%edx
f01004c5:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004c8:	f7 d0                	not    %eax
f01004ca:	a8 06                	test   $0x6,%al
f01004cc:	75 26                	jne    f01004f4 <kbd_proc_data+0xff>
f01004ce:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004d4:	75 1e                	jne    f01004f4 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f01004d6:	c7 04 24 84 1d 10 f0 	movl   $0xf0101d84,(%esp)
f01004dd:	e8 80 06 00 00       	call   f0100b62 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004e2:	ba 92 00 00 00       	mov    $0x92,%edx
f01004e7:	b8 03 00 00 00       	mov    $0x3,%eax
f01004ec:	ee                   	out    %al,(%dx)
f01004ed:	eb 05                	jmp    f01004f4 <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004ef:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004f4:	89 d8                	mov    %ebx,%eax
f01004f6:	83 c4 14             	add    $0x14,%esp
f01004f9:	5b                   	pop    %ebx
f01004fa:	5d                   	pop    %ebp
f01004fb:	c3                   	ret    

f01004fc <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004fc:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f0100503:	74 11                	je     f0100516 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100505:	55                   	push   %ebp
f0100506:	89 e5                	mov    %esp,%ebp
f0100508:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010050b:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100510:	e8 b5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100515:	c9                   	leave  
f0100516:	f3 c3                	repz ret 

f0100518 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100518:	55                   	push   %ebp
f0100519:	89 e5                	mov    %esp,%ebp
f010051b:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010051e:	b8 f5 03 10 f0       	mov    $0xf01003f5,%eax
f0100523:	e8 a2 fc ff ff       	call   f01001ca <cons_intr>
}
f0100528:	c9                   	leave  
f0100529:	c3                   	ret    

f010052a <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010052a:	55                   	push   %ebp
f010052b:	89 e5                	mov    %esp,%ebp
f010052d:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100530:	e8 c7 ff ff ff       	call   f01004fc <serial_intr>
	kbd_intr();
f0100535:	e8 de ff ff ff       	call   f0100518 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010053a:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f0100540:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100546:	74 20                	je     f0100568 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100548:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f010054f:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100552:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100558:	b9 00 00 00 00       	mov    $0x0,%ecx
f010055d:	0f 44 d1             	cmove  %ecx,%edx
f0100560:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 90 1d 10 f0 	movl   $0xf0101d90,(%esp)
f0100654:	e8 09 05 00 00       	call   f0100b62 <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 9b fb ff ff       	call   f010020a <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 ae fe ff ff       	call   f010052a <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 d0 1f 10 f0 	movl   $0xf0101fd0,(%esp)
f010069d:	e8 c0 04 00 00       	call   f0100b62 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 f4 20 10 f0 	movl   $0xf01020f4,(%esp)
f01006b1:	e8 ac 04 00 00       	call   f0100b62 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 1c 21 10 f0 	movl   $0xf010211c,(%esp)
f01006cd:	e8 90 04 00 00       	call   f0100b62 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 ef 1c 10 	movl   $0x101cef,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 ef 1c 10 	movl   $0xf0101cef,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 40 21 10 f0 	movl   $0xf0102140,(%esp)
f01006e9:	e8 74 04 00 00       	call   f0100b62 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 64 21 10 f0 	movl   $0xf0102164,(%esp)
f0100705:	e8 58 04 00 00       	call   f0100b62 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 88 21 10 f0 	movl   $0xf0102188,(%esp)
f0100721:	e8 3c 04 00 00       	call   f0100b62 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 ac 21 10 f0 	movl   $0xf01021ac,(%esp)
f010074e:	e8 0f 04 00 00       	call   f0100b62 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	56                   	push   %esi
f010075e:	53                   	push   %ebx
f010075f:	83 ec 10             	sub    $0x10,%esp
f0100762:	bb e4 22 10 f0       	mov    $0xf01022e4,%ebx
	return 0;
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100767:	be 14 23 10 f0       	mov    $0xf0102314,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076c:	8b 03                	mov    (%ebx),%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100775:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100779:	c7 04 24 e9 1f 10 f0 	movl   $0xf0101fe9,(%esp)
f0100780:	e8 dd 03 00 00       	call   f0100b62 <cprintf>
f0100785:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100788:	39 f3                	cmp    %esi,%ebx
f010078a:	75 e0                	jne    f010076c <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010078c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100791:	83 c4 10             	add    $0x10,%esp
f0100794:	5b                   	pop    %ebx
f0100795:	5e                   	pop    %esi
f0100796:	5d                   	pop    %ebp
f0100797:	c3                   	ret    

f0100798 <mon_changecolor>:

int ftcolor = 0;

int 
mon_changecolor(int argc, char **argv, struct Trapframe *tf)
{
f0100798:	55                   	push   %ebp
f0100799:	89 e5                	mov    %esp,%ebp
f010079b:	53                   	push   %ebx
f010079c:	83 ec 14             	sub    $0x14,%esp
f010079f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc > 1) {
f01007a2:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f01007a6:	0f 8e 48 01 00 00    	jle    f01008f4 <mon_changecolor+0x15c>
		if (strcmp(argv[1], "ble") == 0) ftcolor = CLRBLE;
f01007ac:	c7 44 24 04 f2 1f 10 	movl   $0xf0101ff2,0x4(%esp)
f01007b3:	f0 
f01007b4:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b7:	89 04 24             	mov    %eax,(%esp)
f01007ba:	e8 12 0f 00 00       	call   f01016d1 <strcmp>
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	75 0f                	jne    f01007d2 <mon_changecolor+0x3a>
f01007c3:	c7 05 38 25 11 f0 01 	movl   $0x1,0xf0112538
f01007ca:	00 00 00 
f01007cd:	e9 22 01 00 00       	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "grn") == 0) ftcolor = CLRGRN;
f01007d2:	c7 44 24 04 f6 1f 10 	movl   $0xf0101ff6,0x4(%esp)
f01007d9:	f0 
f01007da:	8b 43 04             	mov    0x4(%ebx),%eax
f01007dd:	89 04 24             	mov    %eax,(%esp)
f01007e0:	e8 ec 0e 00 00       	call   f01016d1 <strcmp>
f01007e5:	85 c0                	test   %eax,%eax
f01007e7:	75 0f                	jne    f01007f8 <mon_changecolor+0x60>
f01007e9:	c7 05 38 25 11 f0 02 	movl   $0x2,0xf0112538
f01007f0:	00 00 00 
f01007f3:	e9 fc 00 00 00       	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "red") == 0) ftcolor = CLRRED;
f01007f8:	c7 44 24 04 fa 1f 10 	movl   $0xf0101ffa,0x4(%esp)
f01007ff:	f0 
f0100800:	8b 43 04             	mov    0x4(%ebx),%eax
f0100803:	89 04 24             	mov    %eax,(%esp)
f0100806:	e8 c6 0e 00 00       	call   f01016d1 <strcmp>
f010080b:	85 c0                	test   %eax,%eax
f010080d:	75 0f                	jne    f010081e <mon_changecolor+0x86>
f010080f:	c7 05 38 25 11 f0 04 	movl   $0x4,0xf0112538
f0100816:	00 00 00 
f0100819:	e9 d6 00 00 00       	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "pnk") == 0) ftcolor = CLRPNK;
f010081e:	c7 44 24 04 fe 1f 10 	movl   $0xf0101ffe,0x4(%esp)
f0100825:	f0 
f0100826:	8b 43 04             	mov    0x4(%ebx),%eax
f0100829:	89 04 24             	mov    %eax,(%esp)
f010082c:	e8 a0 0e 00 00       	call   f01016d1 <strcmp>
f0100831:	85 c0                	test   %eax,%eax
f0100833:	75 0f                	jne    f0100844 <mon_changecolor+0xac>
f0100835:	c7 05 38 25 11 f0 0c 	movl   $0xc,0xf0112538
f010083c:	00 00 00 
f010083f:	e9 b0 00 00 00       	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "wht") == 0) ftcolor = CLRWHT;
f0100844:	c7 44 24 04 02 20 10 	movl   $0xf0102002,0x4(%esp)
f010084b:	f0 
f010084c:	8b 43 04             	mov    0x4(%ebx),%eax
f010084f:	89 04 24             	mov    %eax,(%esp)
f0100852:	e8 7a 0e 00 00       	call   f01016d1 <strcmp>
f0100857:	85 c0                	test   %eax,%eax
f0100859:	75 0f                	jne    f010086a <mon_changecolor+0xd2>
f010085b:	c7 05 38 25 11 f0 07 	movl   $0x7,0xf0112538
f0100862:	00 00 00 
f0100865:	e9 8a 00 00 00       	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "gry") == 0) ftcolor = CLRGRY;
f010086a:	c7 44 24 04 06 20 10 	movl   $0xf0102006,0x4(%esp)
f0100871:	f0 
f0100872:	8b 43 04             	mov    0x4(%ebx),%eax
f0100875:	89 04 24             	mov    %eax,(%esp)
f0100878:	e8 54 0e 00 00       	call   f01016d1 <strcmp>
f010087d:	85 c0                	test   %eax,%eax
f010087f:	75 0c                	jne    f010088d <mon_changecolor+0xf5>
f0100881:	c7 05 38 25 11 f0 08 	movl   $0x8,0xf0112538
f0100888:	00 00 00 
f010088b:	eb 67                	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "ylw") == 0) ftcolor = CLRYLW;
f010088d:	c7 44 24 04 0a 20 10 	movl   $0xf010200a,0x4(%esp)
f0100894:	f0 
f0100895:	8b 43 04             	mov    0x4(%ebx),%eax
f0100898:	89 04 24             	mov    %eax,(%esp)
f010089b:	e8 31 0e 00 00       	call   f01016d1 <strcmp>
f01008a0:	85 c0                	test   %eax,%eax
f01008a2:	75 0c                	jne    f01008b0 <mon_changecolor+0x118>
f01008a4:	c7 05 38 25 11 f0 0e 	movl   $0xe,0xf0112538
f01008ab:	00 00 00 
f01008ae:	eb 44                	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "cyn") == 0) ftcolor = CLRCYN;
f01008b0:	c7 44 24 04 0e 20 10 	movl   $0xf010200e,0x4(%esp)
f01008b7:	f0 
f01008b8:	8b 43 04             	mov    0x4(%ebx),%eax
f01008bb:	89 04 24             	mov    %eax,(%esp)
f01008be:	e8 0e 0e 00 00       	call   f01016d1 <strcmp>
f01008c3:	85 c0                	test   %eax,%eax
f01008c5:	75 0c                	jne    f01008d3 <mon_changecolor+0x13b>
f01008c7:	c7 05 38 25 11 f0 0b 	movl   $0xb,0xf0112538
f01008ce:	00 00 00 
f01008d1:	eb 21                	jmp    f01008f4 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "org") == 0) ftcolor = CLRORG;
f01008d3:	c7 44 24 04 12 20 10 	movl   $0xf0102012,0x4(%esp)
f01008da:	f0 
f01008db:	8b 43 04             	mov    0x4(%ebx),%eax
f01008de:	89 04 24             	mov    %eax,(%esp)
f01008e1:	e8 eb 0d 00 00       	call   f01016d1 <strcmp>
f01008e6:	85 c0                	test   %eax,%eax
f01008e8:	75 0a                	jne    f01008f4 <mon_changecolor+0x15c>
f01008ea:	c7 05 38 25 11 f0 06 	movl   $0x6,0xf0112538
f01008f1:	00 00 00 
	}
	return 0;
}
f01008f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f9:	83 c4 14             	add    $0x14,%esp
f01008fc:	5b                   	pop    %ebx
f01008fd:	5d                   	pop    %ebp
f01008fe:	c3                   	ret    

f01008ff <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008ff:	55                   	push   %ebp
f0100900:	89 e5                	mov    %esp,%ebp
f0100902:	57                   	push   %edi
f0100903:	56                   	push   %esi
f0100904:	53                   	push   %ebx
f0100905:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100908:	89 ef                	mov    %ebp,%edi
	// Your code here.
	struct Eipdebuginfo info;
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
f010090a:	8b 5f 04             	mov    0x4(%edi),%ebx
	cprintf("Stack backtrace:\n");
f010090d:	c7 04 24 16 20 10 f0 	movl   $0xf0102016,(%esp)
f0100914:	e8 49 02 00 00       	call   f0100b62 <cprintf>
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
f0100919:	85 ff                	test   %edi,%edi
f010091b:	0f 84 94 00 00 00    	je     f01009b5 <mon_backtrace+0xb6>
f0100921:	89 fe                	mov    %edi,%esi
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for (i = 1; i <= 5; ++i) 
			cprintf(" %08x", *(ebp + 1 + i));
		cprintf("\n");
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
f0100923:	8d 7d d0             	lea    -0x30(%ebp),%edi
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f0100926:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010092a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010092e:	c7 04 24 28 20 10 f0 	movl   $0xf0102028,(%esp)
f0100935:	e8 28 02 00 00       	call   f0100b62 <cprintf>
		for (i = 1; i <= 5; ++i) 
f010093a:	bb 01 00 00 00       	mov    $0x1,%ebx
			cprintf(" %08x", *(ebp + 1 + i));
f010093f:	8b 44 9e 04          	mov    0x4(%esi,%ebx,4),%eax
f0100943:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100947:	c7 04 24 43 20 10 f0 	movl   $0xf0102043,(%esp)
f010094e:	e8 0f 02 00 00       	call   f0100b62 <cprintf>
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for (i = 1; i <= 5; ++i) 
f0100953:	83 c3 01             	add    $0x1,%ebx
f0100956:	83 fb 06             	cmp    $0x6,%ebx
f0100959:	75 e4                	jne    f010093f <mon_backtrace+0x40>
			cprintf(" %08x", *(ebp + 1 + i));
		cprintf("\n");
f010095b:	c7 04 24 8e 1d 10 f0 	movl   $0xf0101d8e,(%esp)
f0100962:	e8 fb 01 00 00       	call   f0100b62 <cprintf>
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
f0100967:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010096b:	8b 46 04             	mov    0x4(%esi),%eax
f010096e:	89 04 24             	mov    %eax,(%esp)
f0100971:	e8 e7 02 00 00       	call   f0100c5d <debuginfo_eip>
		cprintf("         %s:%d: %.*s+%u\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (unsigned int)(*(ebp + 1) - info.eip_fn_addr));
f0100976:	8b 46 04             	mov    0x4(%esi),%eax
f0100979:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010097c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100980:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100983:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100987:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010098a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010098e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100991:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100995:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100998:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099c:	c7 04 24 49 20 10 f0 	movl   $0xf0102049,(%esp)
f01009a3:	e8 ba 01 00 00       	call   f0100b62 <cprintf>
	struct Eipdebuginfo info;
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
f01009a8:	8b 36                	mov    (%esi),%esi
f01009aa:	8b 5e 04             	mov    0x4(%esi),%ebx
f01009ad:	85 f6                	test   %esi,%esi
f01009af:	0f 85 71 ff ff ff    	jne    f0100926 <mon_backtrace+0x27>
		cprintf("\n");
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
		cprintf("         %s:%d: %.*s+%u\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (unsigned int)(*(ebp + 1) - info.eip_fn_addr));
	}
	return 0;
}
f01009b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01009ba:	83 c4 4c             	add    $0x4c,%esp
f01009bd:	5b                   	pop    %ebx
f01009be:	5e                   	pop    %esi
f01009bf:	5f                   	pop    %edi
f01009c0:	5d                   	pop    %ebp
f01009c1:	c3                   	ret    

f01009c2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009c2:	55                   	push   %ebp
f01009c3:	89 e5                	mov    %esp,%ebp
f01009c5:	57                   	push   %edi
f01009c6:	56                   	push   %esi
f01009c7:	53                   	push   %ebx
f01009c8:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009cb:	c7 04 24 d8 21 10 f0 	movl   $0xf01021d8,(%esp)
f01009d2:	e8 8b 01 00 00       	call   f0100b62 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009d7:	c7 04 24 fc 21 10 f0 	movl   $0xf01021fc,(%esp)
f01009de:	e8 7f 01 00 00       	call   f0100b62 <cprintf>
	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f01009e3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01009ea:	00 
f01009eb:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f01009f2:	00 
f01009f3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01009fa:	00 
f01009fb:	c7 04 24 62 20 10 f0 	movl   $0xf0102062,(%esp)
f0100a02:	e8 5b 01 00 00       	call   f0100b62 <cprintf>

	while (1) {
		buf = readline("K> ");
f0100a07:	c7 04 24 74 20 10 f0 	movl   $0xf0102074,(%esp)
f0100a0e:	e8 cd 0a 00 00       	call   f01014e0 <readline>
f0100a13:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100a15:	85 c0                	test   %eax,%eax
f0100a17:	74 ee                	je     f0100a07 <monitor+0x45>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a19:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a20:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a25:	eb 06                	jmp    f0100a2d <monitor+0x6b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a27:	c6 06 00             	movb   $0x0,(%esi)
f0100a2a:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a2d:	0f b6 06             	movzbl (%esi),%eax
f0100a30:	84 c0                	test   %al,%al
f0100a32:	74 6a                	je     f0100a9e <monitor+0xdc>
f0100a34:	0f be c0             	movsbl %al,%eax
f0100a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3b:	c7 04 24 78 20 10 f0 	movl   $0xf0102078,(%esp)
f0100a42:	e8 0e 0d 00 00       	call   f0101755 <strchr>
f0100a47:	85 c0                	test   %eax,%eax
f0100a49:	75 dc                	jne    f0100a27 <monitor+0x65>
			*buf++ = 0;
		if (*buf == 0)
f0100a4b:	80 3e 00             	cmpb   $0x0,(%esi)
f0100a4e:	74 4e                	je     f0100a9e <monitor+0xdc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a50:	83 fb 0f             	cmp    $0xf,%ebx
f0100a53:	75 16                	jne    f0100a6b <monitor+0xa9>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a55:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a5c:	00 
f0100a5d:	c7 04 24 7d 20 10 f0 	movl   $0xf010207d,(%esp)
f0100a64:	e8 f9 00 00 00       	call   f0100b62 <cprintf>
f0100a69:	eb 9c                	jmp    f0100a07 <monitor+0x45>
			return 0;
		}
		argv[argc++] = buf;
f0100a6b:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100a6f:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a72:	0f b6 06             	movzbl (%esi),%eax
f0100a75:	84 c0                	test   %al,%al
f0100a77:	75 0c                	jne    f0100a85 <monitor+0xc3>
f0100a79:	eb b2                	jmp    f0100a2d <monitor+0x6b>
			buf++;
f0100a7b:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a7e:	0f b6 06             	movzbl (%esi),%eax
f0100a81:	84 c0                	test   %al,%al
f0100a83:	74 a8                	je     f0100a2d <monitor+0x6b>
f0100a85:	0f be c0             	movsbl %al,%eax
f0100a88:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a8c:	c7 04 24 78 20 10 f0 	movl   $0xf0102078,(%esp)
f0100a93:	e8 bd 0c 00 00       	call   f0101755 <strchr>
f0100a98:	85 c0                	test   %eax,%eax
f0100a9a:	74 df                	je     f0100a7b <monitor+0xb9>
f0100a9c:	eb 8f                	jmp    f0100a2d <monitor+0x6b>
			buf++;
	}
	argv[argc] = 0;
f0100a9e:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100aa5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100aa6:	85 db                	test   %ebx,%ebx
f0100aa8:	0f 84 59 ff ff ff    	je     f0100a07 <monitor+0x45>
f0100aae:	bf e0 22 10 f0       	mov    $0xf01022e0,%edi
f0100ab3:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100ab8:	8b 07                	mov    (%edi),%eax
f0100aba:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100abe:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ac1:	89 04 24             	mov    %eax,(%esp)
f0100ac4:	e8 08 0c 00 00       	call   f01016d1 <strcmp>
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	75 24                	jne    f0100af1 <monitor+0x12f>
			return commands[i].func(argc, argv, tf);
f0100acd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100ad0:	8b 55 08             	mov    0x8(%ebp),%edx
f0100ad3:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ad7:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ada:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ade:	89 1c 24             	mov    %ebx,(%esp)
f0100ae1:	ff 14 85 e8 22 10 f0 	call   *-0xfefdd18(,%eax,4)
	cprintf("x %d, y %x, z %d\n", x, y, z);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ae8:	85 c0                	test   %eax,%eax
f0100aea:	78 28                	js     f0100b14 <monitor+0x152>
f0100aec:	e9 16 ff ff ff       	jmp    f0100a07 <monitor+0x45>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100af1:	83 c6 01             	add    $0x1,%esi
f0100af4:	83 c7 0c             	add    $0xc,%edi
f0100af7:	83 fe 04             	cmp    $0x4,%esi
f0100afa:	75 bc                	jne    f0100ab8 <monitor+0xf6>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100afc:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100aff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b03:	c7 04 24 9a 20 10 f0 	movl   $0xf010209a,(%esp)
f0100b0a:	e8 53 00 00 00       	call   f0100b62 <cprintf>
f0100b0f:	e9 f3 fe ff ff       	jmp    f0100a07 <monitor+0x45>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b14:	83 c4 5c             	add    $0x5c,%esp
f0100b17:	5b                   	pop    %ebx
f0100b18:	5e                   	pop    %esi
f0100b19:	5f                   	pop    %edi
f0100b1a:	5d                   	pop    %ebp
f0100b1b:	c3                   	ret    

f0100b1c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100b1c:	55                   	push   %ebp
f0100b1d:	89 e5                	mov    %esp,%ebp
f0100b1f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100b22:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b25:	89 04 24             	mov    %eax,(%esp)
f0100b28:	e8 34 fb ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100b2d:	c9                   	leave  
f0100b2e:	c3                   	ret    

f0100b2f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100b2f:	55                   	push   %ebp
f0100b30:	89 e5                	mov    %esp,%ebp
f0100b32:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100b35:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b43:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b46:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b4a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b51:	c7 04 24 1c 0b 10 f0 	movl   $0xf0100b1c,(%esp)
f0100b58:	e8 f5 04 00 00       	call   f0101052 <vprintfmt>
	return cnt;
}
f0100b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b60:	c9                   	leave  
f0100b61:	c3                   	ret    

f0100b62 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b62:	55                   	push   %ebp
f0100b63:	89 e5                	mov    %esp,%ebp
f0100b65:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b68:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b6b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b72:	89 04 24             	mov    %eax,(%esp)
f0100b75:	e8 b5 ff ff ff       	call   f0100b2f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b7a:	c9                   	leave  
f0100b7b:	c3                   	ret    
f0100b7c:	66 90                	xchg   %ax,%ax
f0100b7e:	66 90                	xchg   %ax,%ax

f0100b80 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b80:	55                   	push   %ebp
f0100b81:	89 e5                	mov    %esp,%ebp
f0100b83:	57                   	push   %edi
f0100b84:	56                   	push   %esi
f0100b85:	53                   	push   %ebx
f0100b86:	83 ec 10             	sub    $0x10,%esp
f0100b89:	89 c6                	mov    %eax,%esi
f0100b8b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100b8e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100b91:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b94:	8b 1a                	mov    (%edx),%ebx
f0100b96:	8b 09                	mov    (%ecx),%ecx
f0100b98:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100b9b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100ba2:	eb 77                	jmp    f0100c1b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100ba4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ba7:	01 d8                	add    %ebx,%eax
f0100ba9:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100bae:	99                   	cltd   
f0100baf:	f7 f9                	idiv   %ecx
f0100bb1:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100bb3:	eb 01                	jmp    f0100bb6 <stab_binsearch+0x36>
			m--;
f0100bb5:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100bb6:	39 d9                	cmp    %ebx,%ecx
f0100bb8:	7c 1d                	jl     f0100bd7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100bba:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100bbd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100bc2:	39 fa                	cmp    %edi,%edx
f0100bc4:	75 ef                	jne    f0100bb5 <stab_binsearch+0x35>
f0100bc6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100bc9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100bcc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100bd0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bd3:	73 18                	jae    f0100bed <stab_binsearch+0x6d>
f0100bd5:	eb 05                	jmp    f0100bdc <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100bd7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100bda:	eb 3f                	jmp    f0100c1b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100bdc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100bdf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100be1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100be4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100beb:	eb 2e                	jmp    f0100c1b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100bed:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100bf0:	73 15                	jae    f0100c07 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100bf2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bf5:	49                   	dec    %ecx
f0100bf6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100bf9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bfc:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100bfe:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100c05:	eb 14                	jmp    f0100c1b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100c07:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100c0a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100c0d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100c0f:	ff 45 0c             	incl   0xc(%ebp)
f0100c12:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100c14:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100c1b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100c1e:	7e 84                	jle    f0100ba4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100c20:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100c24:	75 0d                	jne    f0100c33 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100c26:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100c29:	8b 02                	mov    (%edx),%eax
f0100c2b:	48                   	dec    %eax
f0100c2c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c2f:	89 01                	mov    %eax,(%ecx)
f0100c31:	eb 22                	jmp    f0100c55 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c33:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c36:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c38:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100c3b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c3d:	eb 01                	jmp    f0100c40 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100c3f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c40:	39 c1                	cmp    %eax,%ecx
f0100c42:	7d 0c                	jge    f0100c50 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100c44:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100c47:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100c4c:	39 fa                	cmp    %edi,%edx
f0100c4e:	75 ef                	jne    f0100c3f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100c50:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100c53:	89 02                	mov    %eax,(%edx)
	}
}
f0100c55:	83 c4 10             	add    $0x10,%esp
f0100c58:	5b                   	pop    %ebx
f0100c59:	5e                   	pop    %esi
f0100c5a:	5f                   	pop    %edi
f0100c5b:	5d                   	pop    %ebp
f0100c5c:	c3                   	ret    

f0100c5d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c5d:	55                   	push   %ebp
f0100c5e:	89 e5                	mov    %esp,%ebp
f0100c60:	83 ec 58             	sub    $0x58,%esp
f0100c63:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100c66:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100c69:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100c6c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100c6f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c72:	c7 03 10 23 10 f0    	movl   $0xf0102310,(%ebx)
	info->eip_line = 0;
f0100c78:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100c7f:	c7 43 08 10 23 10 f0 	movl   $0xf0102310,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100c86:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100c8d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100c90:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c97:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100c9d:	76 12                	jbe    f0100cb1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c9f:	b8 90 7c 10 f0       	mov    $0xf0107c90,%eax
f0100ca4:	3d 29 63 10 f0       	cmp    $0xf0106329,%eax
f0100ca9:	0f 86 f5 01 00 00    	jbe    f0100ea4 <debuginfo_eip+0x247>
f0100caf:	eb 1c                	jmp    f0100ccd <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100cb1:	c7 44 24 08 1a 23 10 	movl   $0xf010231a,0x8(%esp)
f0100cb8:	f0 
f0100cb9:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100cc0:	00 
f0100cc1:	c7 04 24 27 23 10 f0 	movl   $0xf0102327,(%esp)
f0100cc8:	e8 2b f4 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ccd:	80 3d 8f 7c 10 f0 00 	cmpb   $0x0,0xf0107c8f
f0100cd4:	0f 85 d1 01 00 00    	jne    f0100eab <debuginfo_eip+0x24e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100cda:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ce1:	b8 28 63 10 f0       	mov    $0xf0106328,%eax
f0100ce6:	2d 48 25 10 f0       	sub    $0xf0102548,%eax
f0100ceb:	c1 f8 02             	sar    $0x2,%eax
f0100cee:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100cf4:	83 e8 01             	sub    $0x1,%eax
f0100cf7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100cfa:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cfe:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100d05:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100d08:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100d0b:	b8 48 25 10 f0       	mov    $0xf0102548,%eax
f0100d10:	e8 6b fe ff ff       	call   f0100b80 <stab_binsearch>
	if (lfile == 0)
f0100d15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d18:	85 c0                	test   %eax,%eax
f0100d1a:	0f 84 92 01 00 00    	je     f0100eb2 <debuginfo_eip+0x255>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100d20:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100d23:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d26:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100d29:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d2d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100d34:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100d37:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d3a:	b8 48 25 10 f0       	mov    $0xf0102548,%eax
f0100d3f:	e8 3c fe ff ff       	call   f0100b80 <stab_binsearch>

	if (lfun <= rfun) {
f0100d44:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d47:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d4a:	39 d0                	cmp    %edx,%eax
f0100d4c:	7f 3d                	jg     f0100d8b <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d4e:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100d51:	8d b9 48 25 10 f0    	lea    -0xfefdab8(%ecx),%edi
f0100d57:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100d5a:	8b 89 48 25 10 f0    	mov    -0xfefdab8(%ecx),%ecx
f0100d60:	bf 90 7c 10 f0       	mov    $0xf0107c90,%edi
f0100d65:	81 ef 29 63 10 f0    	sub    $0xf0106329,%edi
f0100d6b:	39 f9                	cmp    %edi,%ecx
f0100d6d:	73 09                	jae    f0100d78 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d6f:	81 c1 29 63 10 f0    	add    $0xf0106329,%ecx
f0100d75:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d78:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100d7b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100d7e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100d81:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d86:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100d89:	eb 0f                	jmp    f0100d9a <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100d8b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100d8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100d94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d97:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d9a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100da1:	00 
f0100da2:	8b 43 08             	mov    0x8(%ebx),%eax
f0100da5:	89 04 24             	mov    %eax,(%esp)
f0100da8:	e8 de 09 00 00       	call   f010178b <strfind>
f0100dad:	2b 43 08             	sub    0x8(%ebx),%eax
f0100db0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100db3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100db7:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100dbe:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100dc1:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100dc4:	b8 48 25 10 f0       	mov    $0xf0102548,%eax
f0100dc9:	e8 b2 fd ff ff       	call   f0100b80 <stab_binsearch>
	if (lline > rline)
f0100dce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dd1:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100dd4:	0f 8f df 00 00 00    	jg     f0100eb9 <debuginfo_eip+0x25c>
		return -1;
	else 
		info->eip_line = stabs[lline].n_desc;
f0100dda:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100ddd:	0f b7 80 4e 25 10 f0 	movzwl -0xfefdab2(%eax),%eax
f0100de4:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100de7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dea:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ded:	39 f0                	cmp    %esi,%eax
f0100def:	7c 63                	jl     f0100e54 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100df1:	6b f8 0c             	imul   $0xc,%eax,%edi
f0100df4:	81 c7 48 25 10 f0    	add    $0xf0102548,%edi
f0100dfa:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100dfe:	80 f9 84             	cmp    $0x84,%cl
f0100e01:	74 32                	je     f0100e35 <debuginfo_eip+0x1d8>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100e03:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100e06:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100e09:	81 c2 48 25 10 f0    	add    $0xf0102548,%edx
f0100e0f:	eb 15                	jmp    f0100e26 <debuginfo_eip+0x1c9>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100e11:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100e14:	39 f0                	cmp    %esi,%eax
f0100e16:	7c 3c                	jl     f0100e54 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100e18:	89 d7                	mov    %edx,%edi
f0100e1a:	83 ea 0c             	sub    $0xc,%edx
f0100e1d:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0100e21:	80 f9 84             	cmp    $0x84,%cl
f0100e24:	74 0f                	je     f0100e35 <debuginfo_eip+0x1d8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e26:	80 f9 64             	cmp    $0x64,%cl
f0100e29:	75 e6                	jne    f0100e11 <debuginfo_eip+0x1b4>
f0100e2b:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100e2f:	74 e0                	je     f0100e11 <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e31:	39 c6                	cmp    %eax,%esi
f0100e33:	7f 1f                	jg     f0100e54 <debuginfo_eip+0x1f7>
f0100e35:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100e38:	8b 80 48 25 10 f0    	mov    -0xfefdab8(%eax),%eax
f0100e3e:	ba 90 7c 10 f0       	mov    $0xf0107c90,%edx
f0100e43:	81 ea 29 63 10 f0    	sub    $0xf0106329,%edx
f0100e49:	39 d0                	cmp    %edx,%eax
f0100e4b:	73 07                	jae    f0100e54 <debuginfo_eip+0x1f7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e4d:	05 29 63 10 f0       	add    $0xf0106329,%eax
f0100e52:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e54:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e57:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e5a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e5f:	39 ca                	cmp    %ecx,%edx
f0100e61:	7d 70                	jge    f0100ed3 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
f0100e63:	8d 42 01             	lea    0x1(%edx),%eax
f0100e66:	39 c1                	cmp    %eax,%ecx
f0100e68:	7e 56                	jle    f0100ec0 <debuginfo_eip+0x263>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e6a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100e6d:	80 b8 4c 25 10 f0 a0 	cmpb   $0xa0,-0xfefdab4(%eax)
f0100e74:	75 51                	jne    f0100ec7 <debuginfo_eip+0x26a>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100e76:	8d 42 02             	lea    0x2(%edx),%eax
f0100e79:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100e7c:	81 c2 48 25 10 f0    	add    $0xf0102548,%edx
f0100e82:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100e84:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100e88:	39 f8                	cmp    %edi,%eax
f0100e8a:	74 42                	je     f0100ece <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e8c:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0100e90:	83 c0 01             	add    $0x1,%eax
f0100e93:	83 c2 0c             	add    $0xc,%edx
f0100e96:	89 f1                	mov    %esi,%ecx
f0100e98:	80 f9 a0             	cmp    $0xa0,%cl
f0100e9b:	74 e7                	je     f0100e84 <debuginfo_eip+0x227>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea2:	eb 2f                	jmp    f0100ed3 <debuginfo_eip+0x276>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ea9:	eb 28                	jmp    f0100ed3 <debuginfo_eip+0x276>
f0100eab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100eb0:	eb 21                	jmp    f0100ed3 <debuginfo_eip+0x276>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100eb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100eb7:	eb 1a                	jmp    f0100ed3 <debuginfo_eip+0x276>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline)
		return -1;
f0100eb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ebe:	eb 13                	jmp    f0100ed3 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ec0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec5:	eb 0c                	jmp    f0100ed3 <debuginfo_eip+0x276>
f0100ec7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ecc:	eb 05                	jmp    f0100ed3 <debuginfo_eip+0x276>
f0100ece:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ed3:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ed6:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100ed9:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100edc:	89 ec                	mov    %ebp,%esp
f0100ede:	5d                   	pop    %ebp
f0100edf:	c3                   	ret    

f0100ee0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ee0:	55                   	push   %ebp
f0100ee1:	89 e5                	mov    %esp,%ebp
f0100ee3:	57                   	push   %edi
f0100ee4:	56                   	push   %esi
f0100ee5:	53                   	push   %ebx
f0100ee6:	83 ec 4c             	sub    $0x4c,%esp
f0100ee9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100eec:	89 d7                	mov    %edx,%edi
f0100eee:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100ef1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100ef4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ef7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100efa:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eff:	39 d8                	cmp    %ebx,%eax
f0100f01:	72 17                	jb     f0100f1a <printnum+0x3a>
f0100f03:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100f06:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100f09:	76 0f                	jbe    f0100f1a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100f0b:	8b 75 14             	mov    0x14(%ebp),%esi
f0100f0e:	83 ee 01             	sub    $0x1,%esi
f0100f11:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100f14:	85 f6                	test   %esi,%esi
f0100f16:	7f 63                	jg     f0100f7b <printnum+0x9b>
f0100f18:	eb 75                	jmp    f0100f8f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100f1a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100f1d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100f21:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f24:	83 e8 01             	sub    $0x1,%eax
f0100f27:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f2b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100f2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100f32:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100f36:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100f3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f3d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100f40:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100f47:	00 
f0100f48:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100f4b:	89 1c 24             	mov    %ebx,(%esp)
f0100f4e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f51:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f55:	e8 b6 0a 00 00       	call   f0101a10 <__udivdi3>
f0100f5a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f5d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f60:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100f64:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100f68:	89 04 24             	mov    %eax,(%esp)
f0100f6b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f6f:	89 fa                	mov    %edi,%edx
f0100f71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f74:	e8 67 ff ff ff       	call   f0100ee0 <printnum>
f0100f79:	eb 14                	jmp    f0100f8f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f7b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f7f:	8b 45 18             	mov    0x18(%ebp),%eax
f0100f82:	89 04 24             	mov    %eax,(%esp)
f0100f85:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100f87:	83 ee 01             	sub    $0x1,%esi
f0100f8a:	75 ef                	jne    f0100f7b <printnum+0x9b>
f0100f8c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f8f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f93:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100f97:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100f9a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100f9e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100fa5:	00 
f0100fa6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100fa9:	89 1c 24             	mov    %ebx,(%esp)
f0100fac:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100faf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fb3:	e8 a8 0b 00 00       	call   f0101b60 <__umoddi3>
f0100fb8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbc:	0f be 80 35 23 10 f0 	movsbl -0xfefdccb(%eax),%eax
f0100fc3:	89 04 24             	mov    %eax,(%esp)
f0100fc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fc9:	ff d0                	call   *%eax
}
f0100fcb:	83 c4 4c             	add    $0x4c,%esp
f0100fce:	5b                   	pop    %ebx
f0100fcf:	5e                   	pop    %esi
f0100fd0:	5f                   	pop    %edi
f0100fd1:	5d                   	pop    %ebp
f0100fd2:	c3                   	ret    

f0100fd3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100fd3:	55                   	push   %ebp
f0100fd4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100fd6:	83 fa 01             	cmp    $0x1,%edx
f0100fd9:	7e 0e                	jle    f0100fe9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100fdb:	8b 10                	mov    (%eax),%edx
f0100fdd:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100fe0:	89 08                	mov    %ecx,(%eax)
f0100fe2:	8b 02                	mov    (%edx),%eax
f0100fe4:	8b 52 04             	mov    0x4(%edx),%edx
f0100fe7:	eb 22                	jmp    f010100b <getuint+0x38>
	else if (lflag)
f0100fe9:	85 d2                	test   %edx,%edx
f0100feb:	74 10                	je     f0100ffd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100fed:	8b 10                	mov    (%eax),%edx
f0100fef:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ff2:	89 08                	mov    %ecx,(%eax)
f0100ff4:	8b 02                	mov    (%edx),%eax
f0100ff6:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ffb:	eb 0e                	jmp    f010100b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ffd:	8b 10                	mov    (%eax),%edx
f0100fff:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101002:	89 08                	mov    %ecx,(%eax)
f0101004:	8b 02                	mov    (%edx),%eax
f0101006:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010100b:	5d                   	pop    %ebp
f010100c:	c3                   	ret    

f010100d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010100d:	55                   	push   %ebp
f010100e:	89 e5                	mov    %esp,%ebp
f0101010:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101013:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101017:	8b 10                	mov    (%eax),%edx
f0101019:	3b 50 04             	cmp    0x4(%eax),%edx
f010101c:	73 0a                	jae    f0101028 <sprintputch+0x1b>
		*b->buf++ = ch;
f010101e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101021:	88 0a                	mov    %cl,(%edx)
f0101023:	83 c2 01             	add    $0x1,%edx
f0101026:	89 10                	mov    %edx,(%eax)
}
f0101028:	5d                   	pop    %ebp
f0101029:	c3                   	ret    

f010102a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010102a:	55                   	push   %ebp
f010102b:	89 e5                	mov    %esp,%ebp
f010102d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101030:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101033:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101037:	8b 45 10             	mov    0x10(%ebp),%eax
f010103a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010103e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101041:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101045:	8b 45 08             	mov    0x8(%ebp),%eax
f0101048:	89 04 24             	mov    %eax,(%esp)
f010104b:	e8 02 00 00 00       	call   f0101052 <vprintfmt>
	va_end(ap);
}
f0101050:	c9                   	leave  
f0101051:	c3                   	ret    

f0101052 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101052:	55                   	push   %ebp
f0101053:	89 e5                	mov    %esp,%ebp
f0101055:	57                   	push   %edi
f0101056:	56                   	push   %esi
f0101057:	53                   	push   %ebx
f0101058:	83 ec 4c             	sub    $0x4c,%esp
f010105b:	8b 75 08             	mov    0x8(%ebp),%esi
f010105e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101061:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101064:	eb 11                	jmp    f0101077 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101066:	85 c0                	test   %eax,%eax
f0101068:	0f 84 db 03 00 00    	je     f0101449 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f010106e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101072:	89 04 24             	mov    %eax,(%esp)
f0101075:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101077:	0f b6 07             	movzbl (%edi),%eax
f010107a:	83 c7 01             	add    $0x1,%edi
f010107d:	83 f8 25             	cmp    $0x25,%eax
f0101080:	75 e4                	jne    f0101066 <vprintfmt+0x14>
f0101082:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0101086:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010108d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101094:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010109b:	ba 00 00 00 00       	mov    $0x0,%edx
f01010a0:	eb 2b                	jmp    f01010cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010a2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01010a5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f01010a9:	eb 22                	jmp    f01010cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01010ae:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f01010b2:	eb 19                	jmp    f01010cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010b4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01010b7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01010be:	eb 0d                	jmp    f01010cd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01010c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010c3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010cd:	0f b6 0f             	movzbl (%edi),%ecx
f01010d0:	8d 47 01             	lea    0x1(%edi),%eax
f01010d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010d6:	0f b6 07             	movzbl (%edi),%eax
f01010d9:	83 e8 23             	sub    $0x23,%eax
f01010dc:	3c 55                	cmp    $0x55,%al
f01010de:	0f 87 40 03 00 00    	ja     f0101424 <vprintfmt+0x3d2>
f01010e4:	0f b6 c0             	movzbl %al,%eax
f01010e7:	ff 24 85 c4 23 10 f0 	jmp    *-0xfefdc3c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01010ee:	83 e9 30             	sub    $0x30,%ecx
f01010f1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f01010f4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f01010f8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01010fb:	83 f9 09             	cmp    $0x9,%ecx
f01010fe:	77 57                	ja     f0101157 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101100:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101103:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101106:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101109:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010110c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010110f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0101113:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0101116:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101119:	83 f9 09             	cmp    $0x9,%ecx
f010111c:	76 eb                	jbe    f0101109 <vprintfmt+0xb7>
f010111e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101121:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101124:	eb 34                	jmp    f010115a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101126:	8b 45 14             	mov    0x14(%ebp),%eax
f0101129:	8d 48 04             	lea    0x4(%eax),%ecx
f010112c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010112f:	8b 00                	mov    (%eax),%eax
f0101131:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101134:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101137:	eb 21                	jmp    f010115a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0101139:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010113d:	0f 88 71 ff ff ff    	js     f01010b4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101143:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101146:	eb 85                	jmp    f01010cd <vprintfmt+0x7b>
f0101148:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010114b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101152:	e9 76 ff ff ff       	jmp    f01010cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101157:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010115a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010115e:	0f 89 69 ff ff ff    	jns    f01010cd <vprintfmt+0x7b>
f0101164:	e9 57 ff ff ff       	jmp    f01010c0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101169:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010116c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010116f:	e9 59 ff ff ff       	jmp    f01010cd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101174:	8b 45 14             	mov    0x14(%ebp),%eax
f0101177:	8d 50 04             	lea    0x4(%eax),%edx
f010117a:	89 55 14             	mov    %edx,0x14(%ebp)
f010117d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101181:	8b 00                	mov    (%eax),%eax
f0101183:	89 04 24             	mov    %eax,(%esp)
f0101186:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101188:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010118b:	e9 e7 fe ff ff       	jmp    f0101077 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101190:	8b 45 14             	mov    0x14(%ebp),%eax
f0101193:	8d 50 04             	lea    0x4(%eax),%edx
f0101196:	89 55 14             	mov    %edx,0x14(%ebp)
f0101199:	8b 00                	mov    (%eax),%eax
f010119b:	89 c2                	mov    %eax,%edx
f010119d:	c1 fa 1f             	sar    $0x1f,%edx
f01011a0:	31 d0                	xor    %edx,%eax
f01011a2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01011a4:	83 f8 06             	cmp    $0x6,%eax
f01011a7:	7f 0b                	jg     f01011b4 <vprintfmt+0x162>
f01011a9:	8b 14 85 1c 25 10 f0 	mov    -0xfefdae4(,%eax,4),%edx
f01011b0:	85 d2                	test   %edx,%edx
f01011b2:	75 20                	jne    f01011d4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f01011b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011b8:	c7 44 24 08 4d 23 10 	movl   $0xf010234d,0x8(%esp)
f01011bf:	f0 
f01011c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011c4:	89 34 24             	mov    %esi,(%esp)
f01011c7:	e8 5e fe ff ff       	call   f010102a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01011cf:	e9 a3 fe ff ff       	jmp    f0101077 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01011d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011d8:	c7 44 24 08 56 23 10 	movl   $0xf0102356,0x8(%esp)
f01011df:	f0 
f01011e0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011e4:	89 34 24             	mov    %esi,(%esp)
f01011e7:	e8 3e fe ff ff       	call   f010102a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011ef:	e9 83 fe ff ff       	jmp    f0101077 <vprintfmt+0x25>
f01011f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011f7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01011fa:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01011fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0101200:	8d 50 04             	lea    0x4(%eax),%edx
f0101203:	89 55 14             	mov    %edx,0x14(%ebp)
f0101206:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101208:	85 ff                	test   %edi,%edi
f010120a:	b8 46 23 10 f0       	mov    $0xf0102346,%eax
f010120f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101212:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0101216:	74 06                	je     f010121e <vprintfmt+0x1cc>
f0101218:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010121c:	7f 16                	jg     f0101234 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010121e:	0f b6 17             	movzbl (%edi),%edx
f0101221:	0f be c2             	movsbl %dl,%eax
f0101224:	83 c7 01             	add    $0x1,%edi
f0101227:	85 c0                	test   %eax,%eax
f0101229:	0f 85 9f 00 00 00    	jne    f01012ce <vprintfmt+0x27c>
f010122f:	e9 8b 00 00 00       	jmp    f01012bf <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101234:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101238:	89 3c 24             	mov    %edi,(%esp)
f010123b:	e8 92 03 00 00       	call   f01015d2 <strnlen>
f0101240:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101243:	29 c2                	sub    %eax,%edx
f0101245:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101248:	85 d2                	test   %edx,%edx
f010124a:	7e d2                	jle    f010121e <vprintfmt+0x1cc>
					putch(padc, putdat);
f010124c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0101250:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101253:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101256:	89 d7                	mov    %edx,%edi
f0101258:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010125c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010125f:	89 04 24             	mov    %eax,(%esp)
f0101262:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101264:	83 ef 01             	sub    $0x1,%edi
f0101267:	75 ef                	jne    f0101258 <vprintfmt+0x206>
f0101269:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010126c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010126f:	eb ad                	jmp    f010121e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101271:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101275:	74 20                	je     f0101297 <vprintfmt+0x245>
f0101277:	0f be d2             	movsbl %dl,%edx
f010127a:	83 ea 20             	sub    $0x20,%edx
f010127d:	83 fa 5e             	cmp    $0x5e,%edx
f0101280:	76 15                	jbe    f0101297 <vprintfmt+0x245>
					putch('?', putdat);
f0101282:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101285:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101289:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101290:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101293:	ff d1                	call   *%ecx
f0101295:	eb 0f                	jmp    f01012a6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0101297:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010129a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010129e:	89 04 24             	mov    %eax,(%esp)
f01012a1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01012a4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012a6:	83 eb 01             	sub    $0x1,%ebx
f01012a9:	0f b6 17             	movzbl (%edi),%edx
f01012ac:	0f be c2             	movsbl %dl,%eax
f01012af:	83 c7 01             	add    $0x1,%edi
f01012b2:	85 c0                	test   %eax,%eax
f01012b4:	75 24                	jne    f01012da <vprintfmt+0x288>
f01012b6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01012b9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01012bc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012bf:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01012c2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01012c6:	0f 8e ab fd ff ff    	jle    f0101077 <vprintfmt+0x25>
f01012cc:	eb 20                	jmp    f01012ee <vprintfmt+0x29c>
f01012ce:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01012d1:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01012d4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01012d7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012da:	85 f6                	test   %esi,%esi
f01012dc:	78 93                	js     f0101271 <vprintfmt+0x21f>
f01012de:	83 ee 01             	sub    $0x1,%esi
f01012e1:	79 8e                	jns    f0101271 <vprintfmt+0x21f>
f01012e3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01012e6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01012e9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01012ec:	eb d1                	jmp    f01012bf <vprintfmt+0x26d>
f01012ee:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01012f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012f5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01012fc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01012fe:	83 ef 01             	sub    $0x1,%edi
f0101301:	75 ee                	jne    f01012f1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101303:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101306:	e9 6c fd ff ff       	jmp    f0101077 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010130b:	83 fa 01             	cmp    $0x1,%edx
f010130e:	66 90                	xchg   %ax,%ax
f0101310:	7e 16                	jle    f0101328 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0101312:	8b 45 14             	mov    0x14(%ebp),%eax
f0101315:	8d 50 08             	lea    0x8(%eax),%edx
f0101318:	89 55 14             	mov    %edx,0x14(%ebp)
f010131b:	8b 10                	mov    (%eax),%edx
f010131d:	8b 48 04             	mov    0x4(%eax),%ecx
f0101320:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101323:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101326:	eb 32                	jmp    f010135a <vprintfmt+0x308>
	else if (lflag)
f0101328:	85 d2                	test   %edx,%edx
f010132a:	74 18                	je     f0101344 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010132c:	8b 45 14             	mov    0x14(%ebp),%eax
f010132f:	8d 50 04             	lea    0x4(%eax),%edx
f0101332:	89 55 14             	mov    %edx,0x14(%ebp)
f0101335:	8b 00                	mov    (%eax),%eax
f0101337:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010133a:	89 c1                	mov    %eax,%ecx
f010133c:	c1 f9 1f             	sar    $0x1f,%ecx
f010133f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101342:	eb 16                	jmp    f010135a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0101344:	8b 45 14             	mov    0x14(%ebp),%eax
f0101347:	8d 50 04             	lea    0x4(%eax),%edx
f010134a:	89 55 14             	mov    %edx,0x14(%ebp)
f010134d:	8b 00                	mov    (%eax),%eax
f010134f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101352:	89 c7                	mov    %eax,%edi
f0101354:	c1 ff 1f             	sar    $0x1f,%edi
f0101357:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010135a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010135d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101360:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101365:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101369:	79 7d                	jns    f01013e8 <vprintfmt+0x396>
				putch('-', putdat);
f010136b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010136f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101376:	ff d6                	call   *%esi
				num = -(long long) num;
f0101378:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010137b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010137e:	f7 d8                	neg    %eax
f0101380:	83 d2 00             	adc    $0x0,%edx
f0101383:	f7 da                	neg    %edx
			}
			base = 10;
f0101385:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010138a:	eb 5c                	jmp    f01013e8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010138c:	8d 45 14             	lea    0x14(%ebp),%eax
f010138f:	e8 3f fc ff ff       	call   f0100fd3 <getuint>
			base = 10;
f0101394:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101399:	eb 4d                	jmp    f01013e8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			//My code here
			num = getuint(&ap, lflag);
f010139b:	8d 45 14             	lea    0x14(%ebp),%eax
f010139e:	e8 30 fc ff ff       	call   f0100fd3 <getuint>
			base = 8;
f01013a3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;			
f01013a8:	eb 3e                	jmp    f01013e8 <vprintfmt+0x396>
		// pointer
		case 'p':
			putch('0', putdat);
f01013aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013ae:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01013b5:	ff d6                	call   *%esi
			putch('x', putdat);
f01013b7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013bb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01013c2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01013c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c7:	8d 50 04             	lea    0x4(%eax),%edx
f01013ca:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01013cd:	8b 00                	mov    (%eax),%eax
f01013cf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01013d4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01013d9:	eb 0d                	jmp    f01013e8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01013db:	8d 45 14             	lea    0x14(%ebp),%eax
f01013de:	e8 f0 fb ff ff       	call   f0100fd3 <getuint>
			base = 16;
f01013e3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01013e8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01013ec:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01013f0:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01013f3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01013f7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01013fb:	89 04 24             	mov    %eax,(%esp)
f01013fe:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101402:	89 da                	mov    %ebx,%edx
f0101404:	89 f0                	mov    %esi,%eax
f0101406:	e8 d5 fa ff ff       	call   f0100ee0 <printnum>
			break;
f010140b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010140e:	e9 64 fc ff ff       	jmp    f0101077 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101413:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101417:	89 0c 24             	mov    %ecx,(%esp)
f010141a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010141c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010141f:	e9 53 fc ff ff       	jmp    f0101077 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101424:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101428:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010142f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101431:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101435:	0f 84 3c fc ff ff    	je     f0101077 <vprintfmt+0x25>
f010143b:	83 ef 01             	sub    $0x1,%edi
f010143e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101442:	75 f7                	jne    f010143b <vprintfmt+0x3e9>
f0101444:	e9 2e fc ff ff       	jmp    f0101077 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101449:	83 c4 4c             	add    $0x4c,%esp
f010144c:	5b                   	pop    %ebx
f010144d:	5e                   	pop    %esi
f010144e:	5f                   	pop    %edi
f010144f:	5d                   	pop    %ebp
f0101450:	c3                   	ret    

f0101451 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101451:	55                   	push   %ebp
f0101452:	89 e5                	mov    %esp,%ebp
f0101454:	83 ec 28             	sub    $0x28,%esp
f0101457:	8b 45 08             	mov    0x8(%ebp),%eax
f010145a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010145d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101460:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101464:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101467:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010146e:	85 d2                	test   %edx,%edx
f0101470:	7e 30                	jle    f01014a2 <vsnprintf+0x51>
f0101472:	85 c0                	test   %eax,%eax
f0101474:	74 2c                	je     f01014a2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101476:	8b 45 14             	mov    0x14(%ebp),%eax
f0101479:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010147d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101480:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101484:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101487:	89 44 24 04          	mov    %eax,0x4(%esp)
f010148b:	c7 04 24 0d 10 10 f0 	movl   $0xf010100d,(%esp)
f0101492:	e8 bb fb ff ff       	call   f0101052 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101497:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010149a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010149d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014a0:	eb 05                	jmp    f01014a7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01014a2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01014a7:	c9                   	leave  
f01014a8:	c3                   	ret    

f01014a9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01014a9:	55                   	push   %ebp
f01014aa:	89 e5                	mov    %esp,%ebp
f01014ac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01014af:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01014b2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014b6:	8b 45 10             	mov    0x10(%ebp),%eax
f01014b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c7:	89 04 24             	mov    %eax,(%esp)
f01014ca:	e8 82 ff ff ff       	call   f0101451 <vsnprintf>
	va_end(ap);

	return rc;
}
f01014cf:	c9                   	leave  
f01014d0:	c3                   	ret    
f01014d1:	66 90                	xchg   %ax,%ax
f01014d3:	66 90                	xchg   %ax,%ax
f01014d5:	66 90                	xchg   %ax,%ax
f01014d7:	66 90                	xchg   %ax,%ax
f01014d9:	66 90                	xchg   %ax,%ax
f01014db:	66 90                	xchg   %ax,%ax
f01014dd:	66 90                	xchg   %ax,%ax
f01014df:	90                   	nop

f01014e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01014e0:	55                   	push   %ebp
f01014e1:	89 e5                	mov    %esp,%ebp
f01014e3:	57                   	push   %edi
f01014e4:	56                   	push   %esi
f01014e5:	53                   	push   %ebx
f01014e6:	83 ec 1c             	sub    $0x1c,%esp
f01014e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014ec:	85 c0                	test   %eax,%eax
f01014ee:	74 10                	je     f0101500 <readline+0x20>
		cprintf("%s", prompt);
f01014f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014f4:	c7 04 24 56 23 10 f0 	movl   $0xf0102356,(%esp)
f01014fb:	e8 62 f6 ff ff       	call   f0100b62 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101500:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101507:	e8 76 f1 ff ff       	call   f0100682 <iscons>
f010150c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010150e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101513:	e8 59 f1 ff ff       	call   f0100671 <getchar>
f0101518:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010151a:	85 c0                	test   %eax,%eax
f010151c:	79 17                	jns    f0101535 <readline+0x55>
			cprintf("read error: %e\n", c);
f010151e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101522:	c7 04 24 38 25 10 f0 	movl   $0xf0102538,(%esp)
f0101529:	e8 34 f6 ff ff       	call   f0100b62 <cprintf>
			return NULL;
f010152e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101533:	eb 6d                	jmp    f01015a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101535:	83 f8 7f             	cmp    $0x7f,%eax
f0101538:	74 05                	je     f010153f <readline+0x5f>
f010153a:	83 f8 08             	cmp    $0x8,%eax
f010153d:	75 19                	jne    f0101558 <readline+0x78>
f010153f:	85 f6                	test   %esi,%esi
f0101541:	7e 15                	jle    f0101558 <readline+0x78>
			if (echoing)
f0101543:	85 ff                	test   %edi,%edi
f0101545:	74 0c                	je     f0101553 <readline+0x73>
				cputchar('\b');
f0101547:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010154e:	e8 0e f1 ff ff       	call   f0100661 <cputchar>
			i--;
f0101553:	83 ee 01             	sub    $0x1,%esi
f0101556:	eb bb                	jmp    f0101513 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101558:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010155e:	7f 1c                	jg     f010157c <readline+0x9c>
f0101560:	83 fb 1f             	cmp    $0x1f,%ebx
f0101563:	7e 17                	jle    f010157c <readline+0x9c>
			if (echoing)
f0101565:	85 ff                	test   %edi,%edi
f0101567:	74 08                	je     f0101571 <readline+0x91>
				cputchar(c);
f0101569:	89 1c 24             	mov    %ebx,(%esp)
f010156c:	e8 f0 f0 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101571:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101577:	83 c6 01             	add    $0x1,%esi
f010157a:	eb 97                	jmp    f0101513 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010157c:	83 fb 0d             	cmp    $0xd,%ebx
f010157f:	74 05                	je     f0101586 <readline+0xa6>
f0101581:	83 fb 0a             	cmp    $0xa,%ebx
f0101584:	75 8d                	jne    f0101513 <readline+0x33>
			if (echoing)
f0101586:	85 ff                	test   %edi,%edi
f0101588:	74 0c                	je     f0101596 <readline+0xb6>
				cputchar('\n');
f010158a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101591:	e8 cb f0 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101596:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010159d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01015a2:	83 c4 1c             	add    $0x1c,%esp
f01015a5:	5b                   	pop    %ebx
f01015a6:	5e                   	pop    %esi
f01015a7:	5f                   	pop    %edi
f01015a8:	5d                   	pop    %ebp
f01015a9:	c3                   	ret    
f01015aa:	66 90                	xchg   %ax,%ax
f01015ac:	66 90                	xchg   %ax,%ax
f01015ae:	66 90                	xchg   %ax,%ax

f01015b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015b6:	80 3a 00             	cmpb   $0x0,(%edx)
f01015b9:	74 10                	je     f01015cb <strlen+0x1b>
f01015bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01015c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01015c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015c7:	75 f7                	jne    f01015c0 <strlen+0x10>
f01015c9:	eb 05                	jmp    f01015d0 <strlen+0x20>
f01015cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01015d0:	5d                   	pop    %ebp
f01015d1:	c3                   	ret    

f01015d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015d2:	55                   	push   %ebp
f01015d3:	89 e5                	mov    %esp,%ebp
f01015d5:	53                   	push   %ebx
f01015d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015dc:	85 c9                	test   %ecx,%ecx
f01015de:	74 1c                	je     f01015fc <strnlen+0x2a>
f01015e0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01015e3:	74 1e                	je     f0101603 <strnlen+0x31>
f01015e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01015ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015ec:	39 ca                	cmp    %ecx,%edx
f01015ee:	74 18                	je     f0101608 <strnlen+0x36>
f01015f0:	83 c2 01             	add    $0x1,%edx
f01015f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01015f8:	75 f0                	jne    f01015ea <strnlen+0x18>
f01015fa:	eb 0c                	jmp    f0101608 <strnlen+0x36>
f01015fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101601:	eb 05                	jmp    f0101608 <strnlen+0x36>
f0101603:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101608:	5b                   	pop    %ebx
f0101609:	5d                   	pop    %ebp
f010160a:	c3                   	ret    

f010160b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010160b:	55                   	push   %ebp
f010160c:	89 e5                	mov    %esp,%ebp
f010160e:	53                   	push   %ebx
f010160f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101612:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101615:	89 c2                	mov    %eax,%edx
f0101617:	0f b6 19             	movzbl (%ecx),%ebx
f010161a:	88 1a                	mov    %bl,(%edx)
f010161c:	83 c2 01             	add    $0x1,%edx
f010161f:	83 c1 01             	add    $0x1,%ecx
f0101622:	84 db                	test   %bl,%bl
f0101624:	75 f1                	jne    f0101617 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101626:	5b                   	pop    %ebx
f0101627:	5d                   	pop    %ebp
f0101628:	c3                   	ret    

f0101629 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101629:	55                   	push   %ebp
f010162a:	89 e5                	mov    %esp,%ebp
f010162c:	53                   	push   %ebx
f010162d:	83 ec 08             	sub    $0x8,%esp
f0101630:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101633:	89 1c 24             	mov    %ebx,(%esp)
f0101636:	e8 75 ff ff ff       	call   f01015b0 <strlen>
	strcpy(dst + len, src);
f010163b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010163e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101642:	01 d8                	add    %ebx,%eax
f0101644:	89 04 24             	mov    %eax,(%esp)
f0101647:	e8 bf ff ff ff       	call   f010160b <strcpy>
	return dst;
}
f010164c:	89 d8                	mov    %ebx,%eax
f010164e:	83 c4 08             	add    $0x8,%esp
f0101651:	5b                   	pop    %ebx
f0101652:	5d                   	pop    %ebp
f0101653:	c3                   	ret    

f0101654 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101654:	55                   	push   %ebp
f0101655:	89 e5                	mov    %esp,%ebp
f0101657:	56                   	push   %esi
f0101658:	53                   	push   %ebx
f0101659:	8b 75 08             	mov    0x8(%ebp),%esi
f010165c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010165f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101662:	85 db                	test   %ebx,%ebx
f0101664:	74 16                	je     f010167c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0101666:	01 f3                	add    %esi,%ebx
f0101668:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f010166a:	0f b6 02             	movzbl (%edx),%eax
f010166d:	88 01                	mov    %al,(%ecx)
f010166f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101672:	80 3a 01             	cmpb   $0x1,(%edx)
f0101675:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101678:	39 d9                	cmp    %ebx,%ecx
f010167a:	75 ee                	jne    f010166a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010167c:	89 f0                	mov    %esi,%eax
f010167e:	5b                   	pop    %ebx
f010167f:	5e                   	pop    %esi
f0101680:	5d                   	pop    %ebp
f0101681:	c3                   	ret    

f0101682 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101682:	55                   	push   %ebp
f0101683:	89 e5                	mov    %esp,%ebp
f0101685:	57                   	push   %edi
f0101686:	56                   	push   %esi
f0101687:	53                   	push   %ebx
f0101688:	8b 7d 08             	mov    0x8(%ebp),%edi
f010168b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010168e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101691:	89 f8                	mov    %edi,%eax
f0101693:	85 f6                	test   %esi,%esi
f0101695:	74 33                	je     f01016ca <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0101697:	83 fe 01             	cmp    $0x1,%esi
f010169a:	74 25                	je     f01016c1 <strlcpy+0x3f>
f010169c:	0f b6 0b             	movzbl (%ebx),%ecx
f010169f:	84 c9                	test   %cl,%cl
f01016a1:	74 22                	je     f01016c5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01016a3:	83 ee 02             	sub    $0x2,%esi
f01016a6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01016ab:	88 08                	mov    %cl,(%eax)
f01016ad:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01016b0:	39 f2                	cmp    %esi,%edx
f01016b2:	74 13                	je     f01016c7 <strlcpy+0x45>
f01016b4:	83 c2 01             	add    $0x1,%edx
f01016b7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01016bb:	84 c9                	test   %cl,%cl
f01016bd:	75 ec                	jne    f01016ab <strlcpy+0x29>
f01016bf:	eb 06                	jmp    f01016c7 <strlcpy+0x45>
f01016c1:	89 f8                	mov    %edi,%eax
f01016c3:	eb 02                	jmp    f01016c7 <strlcpy+0x45>
f01016c5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01016c7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01016ca:	29 f8                	sub    %edi,%eax
}
f01016cc:	5b                   	pop    %ebx
f01016cd:	5e                   	pop    %esi
f01016ce:	5f                   	pop    %edi
f01016cf:	5d                   	pop    %ebp
f01016d0:	c3                   	ret    

f01016d1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01016d1:	55                   	push   %ebp
f01016d2:	89 e5                	mov    %esp,%ebp
f01016d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016d7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01016da:	0f b6 01             	movzbl (%ecx),%eax
f01016dd:	84 c0                	test   %al,%al
f01016df:	74 15                	je     f01016f6 <strcmp+0x25>
f01016e1:	3a 02                	cmp    (%edx),%al
f01016e3:	75 11                	jne    f01016f6 <strcmp+0x25>
		p++, q++;
f01016e5:	83 c1 01             	add    $0x1,%ecx
f01016e8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01016eb:	0f b6 01             	movzbl (%ecx),%eax
f01016ee:	84 c0                	test   %al,%al
f01016f0:	74 04                	je     f01016f6 <strcmp+0x25>
f01016f2:	3a 02                	cmp    (%edx),%al
f01016f4:	74 ef                	je     f01016e5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016f6:	0f b6 c0             	movzbl %al,%eax
f01016f9:	0f b6 12             	movzbl (%edx),%edx
f01016fc:	29 d0                	sub    %edx,%eax
}
f01016fe:	5d                   	pop    %ebp
f01016ff:	c3                   	ret    

f0101700 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101700:	55                   	push   %ebp
f0101701:	89 e5                	mov    %esp,%ebp
f0101703:	56                   	push   %esi
f0101704:	53                   	push   %ebx
f0101705:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101708:	8b 55 0c             	mov    0xc(%ebp),%edx
f010170b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f010170e:	85 f6                	test   %esi,%esi
f0101710:	74 29                	je     f010173b <strncmp+0x3b>
f0101712:	0f b6 03             	movzbl (%ebx),%eax
f0101715:	84 c0                	test   %al,%al
f0101717:	74 30                	je     f0101749 <strncmp+0x49>
f0101719:	3a 02                	cmp    (%edx),%al
f010171b:	75 2c                	jne    f0101749 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f010171d:	8d 43 01             	lea    0x1(%ebx),%eax
f0101720:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101722:	89 c3                	mov    %eax,%ebx
f0101724:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101727:	39 f0                	cmp    %esi,%eax
f0101729:	74 17                	je     f0101742 <strncmp+0x42>
f010172b:	0f b6 08             	movzbl (%eax),%ecx
f010172e:	84 c9                	test   %cl,%cl
f0101730:	74 17                	je     f0101749 <strncmp+0x49>
f0101732:	83 c0 01             	add    $0x1,%eax
f0101735:	3a 0a                	cmp    (%edx),%cl
f0101737:	74 e9                	je     f0101722 <strncmp+0x22>
f0101739:	eb 0e                	jmp    f0101749 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010173b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101740:	eb 0f                	jmp    f0101751 <strncmp+0x51>
f0101742:	b8 00 00 00 00       	mov    $0x0,%eax
f0101747:	eb 08                	jmp    f0101751 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101749:	0f b6 03             	movzbl (%ebx),%eax
f010174c:	0f b6 12             	movzbl (%edx),%edx
f010174f:	29 d0                	sub    %edx,%eax
}
f0101751:	5b                   	pop    %ebx
f0101752:	5e                   	pop    %esi
f0101753:	5d                   	pop    %ebp
f0101754:	c3                   	ret    

f0101755 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101755:	55                   	push   %ebp
f0101756:	89 e5                	mov    %esp,%ebp
f0101758:	53                   	push   %ebx
f0101759:	8b 45 08             	mov    0x8(%ebp),%eax
f010175c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010175f:	0f b6 18             	movzbl (%eax),%ebx
f0101762:	84 db                	test   %bl,%bl
f0101764:	74 1d                	je     f0101783 <strchr+0x2e>
f0101766:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101768:	38 d3                	cmp    %dl,%bl
f010176a:	75 06                	jne    f0101772 <strchr+0x1d>
f010176c:	eb 1a                	jmp    f0101788 <strchr+0x33>
f010176e:	38 ca                	cmp    %cl,%dl
f0101770:	74 16                	je     f0101788 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101772:	83 c0 01             	add    $0x1,%eax
f0101775:	0f b6 10             	movzbl (%eax),%edx
f0101778:	84 d2                	test   %dl,%dl
f010177a:	75 f2                	jne    f010176e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f010177c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101781:	eb 05                	jmp    f0101788 <strchr+0x33>
f0101783:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101788:	5b                   	pop    %ebx
f0101789:	5d                   	pop    %ebp
f010178a:	c3                   	ret    

f010178b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010178b:	55                   	push   %ebp
f010178c:	89 e5                	mov    %esp,%ebp
f010178e:	53                   	push   %ebx
f010178f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101792:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101795:	0f b6 18             	movzbl (%eax),%ebx
f0101798:	84 db                	test   %bl,%bl
f010179a:	74 16                	je     f01017b2 <strfind+0x27>
f010179c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f010179e:	38 d3                	cmp    %dl,%bl
f01017a0:	75 06                	jne    f01017a8 <strfind+0x1d>
f01017a2:	eb 0e                	jmp    f01017b2 <strfind+0x27>
f01017a4:	38 ca                	cmp    %cl,%dl
f01017a6:	74 0a                	je     f01017b2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01017a8:	83 c0 01             	add    $0x1,%eax
f01017ab:	0f b6 10             	movzbl (%eax),%edx
f01017ae:	84 d2                	test   %dl,%dl
f01017b0:	75 f2                	jne    f01017a4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01017b2:	5b                   	pop    %ebx
f01017b3:	5d                   	pop    %ebp
f01017b4:	c3                   	ret    

f01017b5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01017b5:	55                   	push   %ebp
f01017b6:	89 e5                	mov    %esp,%ebp
f01017b8:	83 ec 0c             	sub    $0xc,%esp
f01017bb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01017be:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01017c1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01017c4:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017c7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01017ca:	85 c9                	test   %ecx,%ecx
f01017cc:	74 36                	je     f0101804 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01017ce:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01017d4:	75 28                	jne    f01017fe <memset+0x49>
f01017d6:	f6 c1 03             	test   $0x3,%cl
f01017d9:	75 23                	jne    f01017fe <memset+0x49>
		c &= 0xFF;
f01017db:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01017df:	89 d3                	mov    %edx,%ebx
f01017e1:	c1 e3 08             	shl    $0x8,%ebx
f01017e4:	89 d6                	mov    %edx,%esi
f01017e6:	c1 e6 18             	shl    $0x18,%esi
f01017e9:	89 d0                	mov    %edx,%eax
f01017eb:	c1 e0 10             	shl    $0x10,%eax
f01017ee:	09 f0                	or     %esi,%eax
f01017f0:	09 c2                	or     %eax,%edx
f01017f2:	89 d0                	mov    %edx,%eax
f01017f4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01017f6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01017f9:	fc                   	cld    
f01017fa:	f3 ab                	rep stos %eax,%es:(%edi)
f01017fc:	eb 06                	jmp    f0101804 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01017fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101801:	fc                   	cld    
f0101802:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101804:	89 f8                	mov    %edi,%eax
f0101806:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101809:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010180c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010180f:	89 ec                	mov    %ebp,%esp
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    

f0101813 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101813:	55                   	push   %ebp
f0101814:	89 e5                	mov    %esp,%ebp
f0101816:	83 ec 08             	sub    $0x8,%esp
f0101819:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010181c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010181f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101822:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101825:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101828:	39 c6                	cmp    %eax,%esi
f010182a:	73 36                	jae    f0101862 <memmove+0x4f>
f010182c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010182f:	39 d0                	cmp    %edx,%eax
f0101831:	73 2f                	jae    f0101862 <memmove+0x4f>
		s += n;
		d += n;
f0101833:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101836:	f6 c2 03             	test   $0x3,%dl
f0101839:	75 1b                	jne    f0101856 <memmove+0x43>
f010183b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101841:	75 13                	jne    f0101856 <memmove+0x43>
f0101843:	f6 c1 03             	test   $0x3,%cl
f0101846:	75 0e                	jne    f0101856 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101848:	83 ef 04             	sub    $0x4,%edi
f010184b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010184e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101851:	fd                   	std    
f0101852:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101854:	eb 09                	jmp    f010185f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101856:	83 ef 01             	sub    $0x1,%edi
f0101859:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010185c:	fd                   	std    
f010185d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010185f:	fc                   	cld    
f0101860:	eb 20                	jmp    f0101882 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101862:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101868:	75 13                	jne    f010187d <memmove+0x6a>
f010186a:	a8 03                	test   $0x3,%al
f010186c:	75 0f                	jne    f010187d <memmove+0x6a>
f010186e:	f6 c1 03             	test   $0x3,%cl
f0101871:	75 0a                	jne    f010187d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101873:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101876:	89 c7                	mov    %eax,%edi
f0101878:	fc                   	cld    
f0101879:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010187b:	eb 05                	jmp    f0101882 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010187d:	89 c7                	mov    %eax,%edi
f010187f:	fc                   	cld    
f0101880:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101882:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101885:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101888:	89 ec                	mov    %ebp,%esp
f010188a:	5d                   	pop    %ebp
f010188b:	c3                   	ret    

f010188c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010188c:	55                   	push   %ebp
f010188d:	89 e5                	mov    %esp,%ebp
f010188f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101892:	8b 45 10             	mov    0x10(%ebp),%eax
f0101895:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101899:	8b 45 0c             	mov    0xc(%ebp),%eax
f010189c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01018a3:	89 04 24             	mov    %eax,(%esp)
f01018a6:	e8 68 ff ff ff       	call   f0101813 <memmove>
}
f01018ab:	c9                   	leave  
f01018ac:	c3                   	ret    

f01018ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01018ad:	55                   	push   %ebp
f01018ae:	89 e5                	mov    %esp,%ebp
f01018b0:	57                   	push   %edi
f01018b1:	56                   	push   %esi
f01018b2:	53                   	push   %ebx
f01018b3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01018b6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018b9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01018bc:	8d 78 ff             	lea    -0x1(%eax),%edi
f01018bf:	85 c0                	test   %eax,%eax
f01018c1:	74 36                	je     f01018f9 <memcmp+0x4c>
		if (*s1 != *s2)
f01018c3:	0f b6 03             	movzbl (%ebx),%eax
f01018c6:	0f b6 0e             	movzbl (%esi),%ecx
f01018c9:	38 c8                	cmp    %cl,%al
f01018cb:	75 17                	jne    f01018e4 <memcmp+0x37>
f01018cd:	ba 00 00 00 00       	mov    $0x0,%edx
f01018d2:	eb 1a                	jmp    f01018ee <memcmp+0x41>
f01018d4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01018d9:	83 c2 01             	add    $0x1,%edx
f01018dc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01018e0:	38 c8                	cmp    %cl,%al
f01018e2:	74 0a                	je     f01018ee <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01018e4:	0f b6 c0             	movzbl %al,%eax
f01018e7:	0f b6 c9             	movzbl %cl,%ecx
f01018ea:	29 c8                	sub    %ecx,%eax
f01018ec:	eb 10                	jmp    f01018fe <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01018ee:	39 fa                	cmp    %edi,%edx
f01018f0:	75 e2                	jne    f01018d4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01018f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01018f7:	eb 05                	jmp    f01018fe <memcmp+0x51>
f01018f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018fe:	5b                   	pop    %ebx
f01018ff:	5e                   	pop    %esi
f0101900:	5f                   	pop    %edi
f0101901:	5d                   	pop    %ebp
f0101902:	c3                   	ret    

f0101903 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101903:	55                   	push   %ebp
f0101904:	89 e5                	mov    %esp,%ebp
f0101906:	53                   	push   %ebx
f0101907:	8b 45 08             	mov    0x8(%ebp),%eax
f010190a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f010190d:	89 c2                	mov    %eax,%edx
f010190f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101912:	39 d0                	cmp    %edx,%eax
f0101914:	73 13                	jae    f0101929 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101916:	89 d9                	mov    %ebx,%ecx
f0101918:	38 18                	cmp    %bl,(%eax)
f010191a:	75 06                	jne    f0101922 <memfind+0x1f>
f010191c:	eb 0b                	jmp    f0101929 <memfind+0x26>
f010191e:	38 08                	cmp    %cl,(%eax)
f0101920:	74 07                	je     f0101929 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101922:	83 c0 01             	add    $0x1,%eax
f0101925:	39 d0                	cmp    %edx,%eax
f0101927:	75 f5                	jne    f010191e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101929:	5b                   	pop    %ebx
f010192a:	5d                   	pop    %ebp
f010192b:	c3                   	ret    

f010192c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010192c:	55                   	push   %ebp
f010192d:	89 e5                	mov    %esp,%ebp
f010192f:	57                   	push   %edi
f0101930:	56                   	push   %esi
f0101931:	53                   	push   %ebx
f0101932:	83 ec 04             	sub    $0x4,%esp
f0101935:	8b 55 08             	mov    0x8(%ebp),%edx
f0101938:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010193b:	0f b6 02             	movzbl (%edx),%eax
f010193e:	3c 09                	cmp    $0x9,%al
f0101940:	74 04                	je     f0101946 <strtol+0x1a>
f0101942:	3c 20                	cmp    $0x20,%al
f0101944:	75 0e                	jne    f0101954 <strtol+0x28>
		s++;
f0101946:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101949:	0f b6 02             	movzbl (%edx),%eax
f010194c:	3c 09                	cmp    $0x9,%al
f010194e:	74 f6                	je     f0101946 <strtol+0x1a>
f0101950:	3c 20                	cmp    $0x20,%al
f0101952:	74 f2                	je     f0101946 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101954:	3c 2b                	cmp    $0x2b,%al
f0101956:	75 0a                	jne    f0101962 <strtol+0x36>
		s++;
f0101958:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010195b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101960:	eb 10                	jmp    f0101972 <strtol+0x46>
f0101962:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101967:	3c 2d                	cmp    $0x2d,%al
f0101969:	75 07                	jne    f0101972 <strtol+0x46>
		s++, neg = 1;
f010196b:	83 c2 01             	add    $0x1,%edx
f010196e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101972:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101978:	75 15                	jne    f010198f <strtol+0x63>
f010197a:	80 3a 30             	cmpb   $0x30,(%edx)
f010197d:	75 10                	jne    f010198f <strtol+0x63>
f010197f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101983:	75 0a                	jne    f010198f <strtol+0x63>
		s += 2, base = 16;
f0101985:	83 c2 02             	add    $0x2,%edx
f0101988:	bb 10 00 00 00       	mov    $0x10,%ebx
f010198d:	eb 10                	jmp    f010199f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f010198f:	85 db                	test   %ebx,%ebx
f0101991:	75 0c                	jne    f010199f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101993:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101995:	80 3a 30             	cmpb   $0x30,(%edx)
f0101998:	75 05                	jne    f010199f <strtol+0x73>
		s++, base = 8;
f010199a:	83 c2 01             	add    $0x1,%edx
f010199d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010199f:	b8 00 00 00 00       	mov    $0x0,%eax
f01019a4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01019a7:	0f b6 0a             	movzbl (%edx),%ecx
f01019aa:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01019ad:	89 f3                	mov    %esi,%ebx
f01019af:	80 fb 09             	cmp    $0x9,%bl
f01019b2:	77 08                	ja     f01019bc <strtol+0x90>
			dig = *s - '0';
f01019b4:	0f be c9             	movsbl %cl,%ecx
f01019b7:	83 e9 30             	sub    $0x30,%ecx
f01019ba:	eb 22                	jmp    f01019de <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f01019bc:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01019bf:	89 f3                	mov    %esi,%ebx
f01019c1:	80 fb 19             	cmp    $0x19,%bl
f01019c4:	77 08                	ja     f01019ce <strtol+0xa2>
			dig = *s - 'a' + 10;
f01019c6:	0f be c9             	movsbl %cl,%ecx
f01019c9:	83 e9 57             	sub    $0x57,%ecx
f01019cc:	eb 10                	jmp    f01019de <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f01019ce:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01019d1:	89 f3                	mov    %esi,%ebx
f01019d3:	80 fb 19             	cmp    $0x19,%bl
f01019d6:	77 16                	ja     f01019ee <strtol+0xc2>
			dig = *s - 'A' + 10;
f01019d8:	0f be c9             	movsbl %cl,%ecx
f01019db:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01019de:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01019e1:	7d 0f                	jge    f01019f2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f01019e3:	83 c2 01             	add    $0x1,%edx
f01019e6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f01019ea:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01019ec:	eb b9                	jmp    f01019a7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01019ee:	89 c1                	mov    %eax,%ecx
f01019f0:	eb 02                	jmp    f01019f4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01019f2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01019f4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01019f8:	74 05                	je     f01019ff <strtol+0xd3>
		*endptr = (char *) s;
f01019fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01019fd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01019ff:	89 ca                	mov    %ecx,%edx
f0101a01:	f7 da                	neg    %edx
f0101a03:	85 ff                	test   %edi,%edi
f0101a05:	0f 45 c2             	cmovne %edx,%eax
}
f0101a08:	83 c4 04             	add    $0x4,%esp
f0101a0b:	5b                   	pop    %ebx
f0101a0c:	5e                   	pop    %esi
f0101a0d:	5f                   	pop    %edi
f0101a0e:	5d                   	pop    %ebp
f0101a0f:	c3                   	ret    

f0101a10 <__udivdi3>:
f0101a10:	83 ec 1c             	sub    $0x1c,%esp
f0101a13:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101a17:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101a1b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101a1f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101a23:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101a27:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0101a2b:	85 c0                	test   %eax,%eax
f0101a2d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a31:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101a35:	89 ea                	mov    %ebp,%edx
f0101a37:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a3b:	75 33                	jne    f0101a70 <__udivdi3+0x60>
f0101a3d:	39 e9                	cmp    %ebp,%ecx
f0101a3f:	77 6f                	ja     f0101ab0 <__udivdi3+0xa0>
f0101a41:	85 c9                	test   %ecx,%ecx
f0101a43:	89 ce                	mov    %ecx,%esi
f0101a45:	75 0b                	jne    f0101a52 <__udivdi3+0x42>
f0101a47:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a4c:	31 d2                	xor    %edx,%edx
f0101a4e:	f7 f1                	div    %ecx
f0101a50:	89 c6                	mov    %eax,%esi
f0101a52:	31 d2                	xor    %edx,%edx
f0101a54:	89 e8                	mov    %ebp,%eax
f0101a56:	f7 f6                	div    %esi
f0101a58:	89 c5                	mov    %eax,%ebp
f0101a5a:	89 f8                	mov    %edi,%eax
f0101a5c:	f7 f6                	div    %esi
f0101a5e:	89 ea                	mov    %ebp,%edx
f0101a60:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a64:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a68:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a6c:	83 c4 1c             	add    $0x1c,%esp
f0101a6f:	c3                   	ret    
f0101a70:	39 e8                	cmp    %ebp,%eax
f0101a72:	77 24                	ja     f0101a98 <__udivdi3+0x88>
f0101a74:	0f bd c8             	bsr    %eax,%ecx
f0101a77:	83 f1 1f             	xor    $0x1f,%ecx
f0101a7a:	89 0c 24             	mov    %ecx,(%esp)
f0101a7d:	75 49                	jne    f0101ac8 <__udivdi3+0xb8>
f0101a7f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101a83:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0101a87:	0f 86 ab 00 00 00    	jbe    f0101b38 <__udivdi3+0x128>
f0101a8d:	39 e8                	cmp    %ebp,%eax
f0101a8f:	0f 82 a3 00 00 00    	jb     f0101b38 <__udivdi3+0x128>
f0101a95:	8d 76 00             	lea    0x0(%esi),%esi
f0101a98:	31 d2                	xor    %edx,%edx
f0101a9a:	31 c0                	xor    %eax,%eax
f0101a9c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101aa0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101aa4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101aa8:	83 c4 1c             	add    $0x1c,%esp
f0101aab:	c3                   	ret    
f0101aac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ab0:	89 f8                	mov    %edi,%eax
f0101ab2:	f7 f1                	div    %ecx
f0101ab4:	31 d2                	xor    %edx,%edx
f0101ab6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101aba:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101abe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ac2:	83 c4 1c             	add    $0x1c,%esp
f0101ac5:	c3                   	ret    
f0101ac6:	66 90                	xchg   %ax,%ax
f0101ac8:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101acc:	89 c6                	mov    %eax,%esi
f0101ace:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ad3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101ad7:	2b 04 24             	sub    (%esp),%eax
f0101ada:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101ade:	d3 e6                	shl    %cl,%esi
f0101ae0:	89 c1                	mov    %eax,%ecx
f0101ae2:	d3 ed                	shr    %cl,%ebp
f0101ae4:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101ae8:	09 f5                	or     %esi,%ebp
f0101aea:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101aee:	d3 e6                	shl    %cl,%esi
f0101af0:	89 c1                	mov    %eax,%ecx
f0101af2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101af6:	89 d6                	mov    %edx,%esi
f0101af8:	d3 ee                	shr    %cl,%esi
f0101afa:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101afe:	d3 e2                	shl    %cl,%edx
f0101b00:	89 c1                	mov    %eax,%ecx
f0101b02:	d3 ef                	shr    %cl,%edi
f0101b04:	09 d7                	or     %edx,%edi
f0101b06:	89 f2                	mov    %esi,%edx
f0101b08:	89 f8                	mov    %edi,%eax
f0101b0a:	f7 f5                	div    %ebp
f0101b0c:	89 d6                	mov    %edx,%esi
f0101b0e:	89 c7                	mov    %eax,%edi
f0101b10:	f7 64 24 04          	mull   0x4(%esp)
f0101b14:	39 d6                	cmp    %edx,%esi
f0101b16:	72 30                	jb     f0101b48 <__udivdi3+0x138>
f0101b18:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101b1c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101b20:	d3 e5                	shl    %cl,%ebp
f0101b22:	39 c5                	cmp    %eax,%ebp
f0101b24:	73 04                	jae    f0101b2a <__udivdi3+0x11a>
f0101b26:	39 d6                	cmp    %edx,%esi
f0101b28:	74 1e                	je     f0101b48 <__udivdi3+0x138>
f0101b2a:	89 f8                	mov    %edi,%eax
f0101b2c:	31 d2                	xor    %edx,%edx
f0101b2e:	e9 69 ff ff ff       	jmp    f0101a9c <__udivdi3+0x8c>
f0101b33:	90                   	nop
f0101b34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b38:	31 d2                	xor    %edx,%edx
f0101b3a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b3f:	e9 58 ff ff ff       	jmp    f0101a9c <__udivdi3+0x8c>
f0101b44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b48:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101b4b:	31 d2                	xor    %edx,%edx
f0101b4d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b51:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b55:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b59:	83 c4 1c             	add    $0x1c,%esp
f0101b5c:	c3                   	ret    
f0101b5d:	66 90                	xchg   %ax,%ax
f0101b5f:	90                   	nop

f0101b60 <__umoddi3>:
f0101b60:	83 ec 2c             	sub    $0x2c,%esp
f0101b63:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101b67:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101b6b:	89 74 24 20          	mov    %esi,0x20(%esp)
f0101b6f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0101b73:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0101b77:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0101b7b:	85 c0                	test   %eax,%eax
f0101b7d:	89 c2                	mov    %eax,%edx
f0101b7f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0101b83:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101b87:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b8b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101b8f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101b93:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101b97:	75 1f                	jne    f0101bb8 <__umoddi3+0x58>
f0101b99:	39 fe                	cmp    %edi,%esi
f0101b9b:	76 63                	jbe    f0101c00 <__umoddi3+0xa0>
f0101b9d:	89 c8                	mov    %ecx,%eax
f0101b9f:	89 fa                	mov    %edi,%edx
f0101ba1:	f7 f6                	div    %esi
f0101ba3:	89 d0                	mov    %edx,%eax
f0101ba5:	31 d2                	xor    %edx,%edx
f0101ba7:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101bab:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101baf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101bb3:	83 c4 2c             	add    $0x2c,%esp
f0101bb6:	c3                   	ret    
f0101bb7:	90                   	nop
f0101bb8:	39 f8                	cmp    %edi,%eax
f0101bba:	77 64                	ja     f0101c20 <__umoddi3+0xc0>
f0101bbc:	0f bd e8             	bsr    %eax,%ebp
f0101bbf:	83 f5 1f             	xor    $0x1f,%ebp
f0101bc2:	75 74                	jne    f0101c38 <__umoddi3+0xd8>
f0101bc4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bc8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0101bcc:	0f 87 0e 01 00 00    	ja     f0101ce0 <__umoddi3+0x180>
f0101bd2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101bd6:	29 f1                	sub    %esi,%ecx
f0101bd8:	19 c7                	sbb    %eax,%edi
f0101bda:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101bde:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101be2:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101be6:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101bea:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101bee:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101bf2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101bf6:	83 c4 2c             	add    $0x2c,%esp
f0101bf9:	c3                   	ret    
f0101bfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101c00:	85 f6                	test   %esi,%esi
f0101c02:	89 f5                	mov    %esi,%ebp
f0101c04:	75 0b                	jne    f0101c11 <__umoddi3+0xb1>
f0101c06:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c0b:	31 d2                	xor    %edx,%edx
f0101c0d:	f7 f6                	div    %esi
f0101c0f:	89 c5                	mov    %eax,%ebp
f0101c11:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101c15:	31 d2                	xor    %edx,%edx
f0101c17:	f7 f5                	div    %ebp
f0101c19:	89 c8                	mov    %ecx,%eax
f0101c1b:	f7 f5                	div    %ebp
f0101c1d:	eb 84                	jmp    f0101ba3 <__umoddi3+0x43>
f0101c1f:	90                   	nop
f0101c20:	89 c8                	mov    %ecx,%eax
f0101c22:	89 fa                	mov    %edi,%edx
f0101c24:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101c28:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101c2c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101c30:	83 c4 2c             	add    $0x2c,%esp
f0101c33:	c3                   	ret    
f0101c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c38:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101c3c:	be 20 00 00 00       	mov    $0x20,%esi
f0101c41:	89 e9                	mov    %ebp,%ecx
f0101c43:	29 ee                	sub    %ebp,%esi
f0101c45:	d3 e2                	shl    %cl,%edx
f0101c47:	89 f1                	mov    %esi,%ecx
f0101c49:	d3 e8                	shr    %cl,%eax
f0101c4b:	89 e9                	mov    %ebp,%ecx
f0101c4d:	09 d0                	or     %edx,%eax
f0101c4f:	89 fa                	mov    %edi,%edx
f0101c51:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c55:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101c59:	d3 e0                	shl    %cl,%eax
f0101c5b:	89 f1                	mov    %esi,%ecx
f0101c5d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101c61:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101c65:	d3 ea                	shr    %cl,%edx
f0101c67:	89 e9                	mov    %ebp,%ecx
f0101c69:	d3 e7                	shl    %cl,%edi
f0101c6b:	89 f1                	mov    %esi,%ecx
f0101c6d:	d3 e8                	shr    %cl,%eax
f0101c6f:	89 e9                	mov    %ebp,%ecx
f0101c71:	09 f8                	or     %edi,%eax
f0101c73:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101c77:	f7 74 24 0c          	divl   0xc(%esp)
f0101c7b:	d3 e7                	shl    %cl,%edi
f0101c7d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101c81:	89 d7                	mov    %edx,%edi
f0101c83:	f7 64 24 10          	mull   0x10(%esp)
f0101c87:	39 d7                	cmp    %edx,%edi
f0101c89:	89 c1                	mov    %eax,%ecx
f0101c8b:	89 54 24 14          	mov    %edx,0x14(%esp)
f0101c8f:	72 3b                	jb     f0101ccc <__umoddi3+0x16c>
f0101c91:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0101c95:	72 31                	jb     f0101cc8 <__umoddi3+0x168>
f0101c97:	8b 44 24 18          	mov    0x18(%esp),%eax
f0101c9b:	29 c8                	sub    %ecx,%eax
f0101c9d:	19 d7                	sbb    %edx,%edi
f0101c9f:	89 e9                	mov    %ebp,%ecx
f0101ca1:	89 fa                	mov    %edi,%edx
f0101ca3:	d3 e8                	shr    %cl,%eax
f0101ca5:	89 f1                	mov    %esi,%ecx
f0101ca7:	d3 e2                	shl    %cl,%edx
f0101ca9:	89 e9                	mov    %ebp,%ecx
f0101cab:	09 d0                	or     %edx,%eax
f0101cad:	89 fa                	mov    %edi,%edx
f0101caf:	d3 ea                	shr    %cl,%edx
f0101cb1:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101cb5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101cb9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101cbd:	83 c4 2c             	add    $0x2c,%esp
f0101cc0:	c3                   	ret    
f0101cc1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101cc8:	39 d7                	cmp    %edx,%edi
f0101cca:	75 cb                	jne    f0101c97 <__umoddi3+0x137>
f0101ccc:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101cd0:	89 c1                	mov    %eax,%ecx
f0101cd2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101cd6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101cda:	eb bb                	jmp    f0101c97 <__umoddi3+0x137>
f0101cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ce0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101ce4:	0f 82 e8 fe ff ff    	jb     f0101bd2 <__umoddi3+0x72>
f0101cea:	e9 f3 fe ff ff       	jmp    f0101be2 <__umoddi3+0x82>
