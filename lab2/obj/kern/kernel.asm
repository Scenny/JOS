
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 39 11 f0       	mov    $0xf0113970,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 33 11 f0 	movl   $0xf0113300,(%esp)
f0100063:	e8 8d 18 00 00       	call   f01018f5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f010007c:	e8 1d 0c 00 00       	call   f0100c9e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 61 0a 00 00       	call   f0100ae7 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 d0 08 00 00       	call   f0100962 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 5b 1e 10 f0 	movl   $0xf0101e5b,(%esp)
f01000c8:	e8 d1 0b 00 00       	call   f0100c9e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 92 0b 00 00       	call   f0100c6b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 97 1e 10 f0 	movl   $0xf0101e97,(%esp)
f01000e0:	e8 b9 0b 00 00       	call   f0100c9e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 71 08 00 00       	call   f0100962 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 73 1e 10 f0 	movl   $0xf0101e73,(%esp)
f0100112:	e8 87 0b 00 00       	call   f0100c9e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 45 0b 00 00       	call   f0100c6b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 97 1e 10 f0 	movl   $0xf0101e97,(%esp)
f010012d:	e8 6c 0b 00 00       	call   f0100c9e <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100157:	a8 01                	test   $0x1,%al
f0100159:	74 08                	je     f0100163 <serial_proc_data+0x15>
f010015b:	b2 f8                	mov    $0xf8,%dl
f010015d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010015e:	0f b6 c0             	movzbl %al,%eax
f0100161:	eb 05                	jmp    f0100168 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 26                	jmp    f010019b <cons_intr+0x31>
		if (c == 0)
f0100175:	85 d2                	test   %edx,%edx
f0100177:	74 22                	je     f010019b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	a1 24 35 11 f0       	mov    0xf0113524,%eax
f010017e:	88 90 20 33 11 f0    	mov    %dl,-0xfeecce0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019b:	ff d3                	call   *%ebx
f010019d:	89 c2                	mov    %eax,%edx
f010019f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a2:	75 d1                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a4:	83 c4 04             	add    $0x4,%esp
f01001a7:	5b                   	pop    %ebx
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	57                   	push   %edi
f01001ae:	56                   	push   %esi
f01001af:	53                   	push   %ebx
f01001b0:	83 ec 1c             	sub    $0x1c,%esp
f01001b3:	89 c7                	mov    %eax,%edi
f01001b5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001ba:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001bb:	a8 20                	test   $0x20,%al
f01001bd:	75 1b                	jne    f01001da <cons_putc+0x30>
f01001bf:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c4:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c9:	e8 72 ff ff ff       	call   f0100140 <delay>
f01001ce:	89 f2                	mov    %esi,%edx
f01001d0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001d1:	a8 20                	test   $0x20,%al
f01001d3:	75 05                	jne    f01001da <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d5:	83 eb 01             	sub    $0x1,%ebx
f01001d8:	75 ef                	jne    f01001c9 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001da:	81 e7 ff 00 00 00    	and    $0xff,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001e0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e5:	89 f8                	mov    %edi,%eax
f01001e7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e8:	b2 79                	mov    $0x79,%dl
f01001ea:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001eb:	84 c0                	test   %al,%al
f01001ed:	78 1b                	js     f010020a <cons_putc+0x60>
f01001ef:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f4:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f9:	e8 42 ff ff ff       	call   f0100140 <delay>
f01001fe:	89 f2                	mov    %esi,%edx
f0100200:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100201:	84 c0                	test   %al,%al
f0100203:	78 05                	js     f010020a <cons_putc+0x60>
f0100205:	83 eb 01             	sub    $0x1,%ebx
f0100208:	75 ef                	jne    f01001f9 <cons_putc+0x4f>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010020a:	ba 78 03 00 00       	mov    $0x378,%edx
f010020f:	89 f8                	mov    %edi,%eax
f0100211:	ee                   	out    %al,(%dx)
f0100212:	b2 7a                	mov    $0x7a,%dl
f0100214:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100219:	ee                   	out    %al,(%dx)
f010021a:	b8 08 00 00 00       	mov    $0x8,%eax
f010021f:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c &= 0xFF;
	c |= ftcolor << 8;
f0100220:	a1 38 35 11 f0       	mov    0xf0113538,%eax
f0100225:	c1 e0 08             	shl    $0x8,%eax
f0100228:	89 fb                	mov    %edi,%ebx
f010022a:	09 c3                	or     %eax,%ebx
	if (!(c & ~0xFF))
f010022c:	89 da                	mov    %ebx,%edx
f010022e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100234:	89 d8                	mov    %ebx,%eax
f0100236:	80 cc 07             	or     $0x7,%ah
f0100239:	85 d2                	test   %edx,%edx
f010023b:	0f 44 d8             	cmove  %eax,%ebx

	switch (c & 0xff) {
f010023e:	0f b6 c3             	movzbl %bl,%eax
f0100241:	83 f8 09             	cmp    $0x9,%eax
f0100244:	74 7b                	je     f01002c1 <cons_putc+0x117>
f0100246:	83 f8 09             	cmp    $0x9,%eax
f0100249:	7f 0b                	jg     f0100256 <cons_putc+0xac>
f010024b:	83 f8 08             	cmp    $0x8,%eax
f010024e:	0f 85 a1 00 00 00    	jne    f01002f5 <cons_putc+0x14b>
f0100254:	eb 12                	jmp    f0100268 <cons_putc+0xbe>
f0100256:	83 f8 0a             	cmp    $0xa,%eax
f0100259:	74 40                	je     f010029b <cons_putc+0xf1>
f010025b:	83 f8 0d             	cmp    $0xd,%eax
f010025e:	66 90                	xchg   %ax,%ax
f0100260:	0f 85 8f 00 00 00    	jne    f01002f5 <cons_putc+0x14b>
f0100266:	eb 3b                	jmp    f01002a3 <cons_putc+0xf9>
	case '\b':
		if (crt_pos > 0) {
f0100268:	0f b7 05 34 35 11 f0 	movzwl 0xf0113534,%eax
f010026f:	66 85 c0             	test   %ax,%ax
f0100272:	0f 84 e7 00 00 00    	je     f010035f <cons_putc+0x1b5>
			crt_pos--;
f0100278:	83 e8 01             	sub    $0x1,%eax
f010027b:	66 a3 34 35 11 f0    	mov    %ax,0xf0113534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100281:	0f b7 c0             	movzwl %ax,%eax
f0100284:	89 df                	mov    %ebx,%edi
f0100286:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f010028c:	83 cf 20             	or     $0x20,%edi
f010028f:	8b 15 30 35 11 f0    	mov    0xf0113530,%edx
f0100295:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100299:	eb 77                	jmp    f0100312 <cons_putc+0x168>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010029b:	66 83 05 34 35 11 f0 	addw   $0x50,0xf0113534
f01002a2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002a3:	0f b7 05 34 35 11 f0 	movzwl 0xf0113534,%eax
f01002aa:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002b0:	c1 e8 16             	shr    $0x16,%eax
f01002b3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002b6:	c1 e0 04             	shl    $0x4,%eax
f01002b9:	66 a3 34 35 11 f0    	mov    %ax,0xf0113534
f01002bf:	eb 51                	jmp    f0100312 <cons_putc+0x168>
		break;
	case '\t':
		cons_putc(' ');
f01002c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c6:	e8 df fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d0:	e8 d5 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01002da:	e8 cb fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002df:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e4:	e8 c1 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002e9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ee:	e8 b7 fe ff ff       	call   f01001aa <cons_putc>
f01002f3:	eb 1d                	jmp    f0100312 <cons_putc+0x168>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002f5:	0f b7 05 34 35 11 f0 	movzwl 0xf0113534,%eax
f01002fc:	0f b7 c8             	movzwl %ax,%ecx
f01002ff:	8b 15 30 35 11 f0    	mov    0xf0113530,%edx
f0100305:	66 89 1c 4a          	mov    %bx,(%edx,%ecx,2)
f0100309:	83 c0 01             	add    $0x1,%eax
f010030c:	66 a3 34 35 11 f0    	mov    %ax,0xf0113534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100312:	66 81 3d 34 35 11 f0 	cmpw   $0x7cf,0xf0113534
f0100319:	cf 07 
f010031b:	76 42                	jbe    f010035f <cons_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010031d:	a1 30 35 11 f0       	mov    0xf0113530,%eax
f0100322:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100329:	00 
f010032a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100330:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100334:	89 04 24             	mov    %eax,(%esp)
f0100337:	e8 17 16 00 00       	call   f0101953 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010033c:	8b 15 30 35 11 f0    	mov    0xf0113530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100342:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100347:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010034d:	83 c0 01             	add    $0x1,%eax
f0100350:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100355:	75 f0                	jne    f0100347 <cons_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100357:	66 83 2d 34 35 11 f0 	subw   $0x50,0xf0113534
f010035e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010035f:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f0100365:	b8 0e 00 00 00       	mov    $0xe,%eax
f010036a:	89 ca                	mov    %ecx,%edx
f010036c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010036d:	0f b7 1d 34 35 11 f0 	movzwl 0xf0113534,%ebx
f0100374:	8d 71 01             	lea    0x1(%ecx),%esi
f0100377:	89 d8                	mov    %ebx,%eax
f0100379:	66 c1 e8 08          	shr    $0x8,%ax
f010037d:	89 f2                	mov    %esi,%edx
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100385:	89 ca                	mov    %ecx,%edx
f0100387:	ee                   	out    %al,(%dx)
f0100388:	89 d8                	mov    %ebx,%eax
f010038a:	89 f2                	mov    %esi,%edx
f010038c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010038d:	83 c4 1c             	add    $0x1c,%esp
f0100390:	5b                   	pop    %ebx
f0100391:	5e                   	pop    %esi
f0100392:	5f                   	pop    %edi
f0100393:	5d                   	pop    %ebp
f0100394:	c3                   	ret    

f0100395 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100395:	55                   	push   %ebp
f0100396:	89 e5                	mov    %esp,%ebp
f0100398:	53                   	push   %ebx
f0100399:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010039c:	ba 64 00 00 00       	mov    $0x64,%edx
f01003a1:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003a2:	a8 01                	test   $0x1,%al
f01003a4:	0f 84 e5 00 00 00    	je     f010048f <kbd_proc_data+0xfa>
f01003aa:	b2 60                	mov    $0x60,%dl
f01003ac:	ec                   	in     (%dx),%al
f01003ad:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003af:	3c e0                	cmp    $0xe0,%al
f01003b1:	75 11                	jne    f01003c4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01003b3:	83 0d 28 35 11 f0 40 	orl    $0x40,0xf0113528
		return 0;
f01003ba:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bf:	e9 d0 00 00 00       	jmp    f0100494 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003c4:	84 c0                	test   %al,%al
f01003c6:	79 37                	jns    f01003ff <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c8:	8b 0d 28 35 11 f0    	mov    0xf0113528,%ecx
f01003ce:	89 cb                	mov    %ecx,%ebx
f01003d0:	83 e3 40             	and    $0x40,%ebx
f01003d3:	83 e0 7f             	and    $0x7f,%eax
f01003d6:	85 db                	test   %ebx,%ebx
f01003d8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003db:	0f b6 d2             	movzbl %dl,%edx
f01003de:	0f b6 82 c0 1e 10 f0 	movzbl -0xfefe140(%edx),%eax
f01003e5:	83 c8 40             	or     $0x40,%eax
f01003e8:	0f b6 c0             	movzbl %al,%eax
f01003eb:	f7 d0                	not    %eax
f01003ed:	21 c1                	and    %eax,%ecx
f01003ef:	89 0d 28 35 11 f0    	mov    %ecx,0xf0113528
		return 0;
f01003f5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003fa:	e9 95 00 00 00       	jmp    f0100494 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003ff:	8b 0d 28 35 11 f0    	mov    0xf0113528,%ecx
f0100405:	f6 c1 40             	test   $0x40,%cl
f0100408:	74 0e                	je     f0100418 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010040a:	89 c2                	mov    %eax,%edx
f010040c:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040f:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100412:	89 0d 28 35 11 f0    	mov    %ecx,0xf0113528
	}

	shift |= shiftcode[data];
f0100418:	0f b6 d2             	movzbl %dl,%edx
f010041b:	0f b6 82 c0 1e 10 f0 	movzbl -0xfefe140(%edx),%eax
f0100422:	0b 05 28 35 11 f0    	or     0xf0113528,%eax
	shift ^= togglecode[data];
f0100428:	0f b6 8a c0 1f 10 f0 	movzbl -0xfefe040(%edx),%ecx
f010042f:	31 c8                	xor    %ecx,%eax
f0100431:	a3 28 35 11 f0       	mov    %eax,0xf0113528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100436:	89 c1                	mov    %eax,%ecx
f0100438:	83 e1 03             	and    $0x3,%ecx
f010043b:	8b 0c 8d c0 20 10 f0 	mov    -0xfefdf40(,%ecx,4),%ecx
f0100442:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100446:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100449:	a8 08                	test   $0x8,%al
f010044b:	74 1b                	je     f0100468 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010044d:	89 da                	mov    %ebx,%edx
f010044f:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100452:	83 f9 19             	cmp    $0x19,%ecx
f0100455:	77 05                	ja     f010045c <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f0100457:	83 eb 20             	sub    $0x20,%ebx
f010045a:	eb 0c                	jmp    f0100468 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f010045c:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010045f:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100462:	83 fa 19             	cmp    $0x19,%edx
f0100465:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100468:	f7 d0                	not    %eax
f010046a:	a8 06                	test   $0x6,%al
f010046c:	75 26                	jne    f0100494 <kbd_proc_data+0xff>
f010046e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100474:	75 1e                	jne    f0100494 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f0100476:	c7 04 24 8d 1e 10 f0 	movl   $0xf0101e8d,(%esp)
f010047d:	e8 1c 08 00 00       	call   f0100c9e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100482:	ba 92 00 00 00       	mov    $0x92,%edx
f0100487:	b8 03 00 00 00       	mov    $0x3,%eax
f010048c:	ee                   	out    %al,(%dx)
f010048d:	eb 05                	jmp    f0100494 <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010048f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100494:	89 d8                	mov    %ebx,%eax
f0100496:	83 c4 14             	add    $0x14,%esp
f0100499:	5b                   	pop    %ebx
f010049a:	5d                   	pop    %ebp
f010049b:	c3                   	ret    

f010049c <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010049c:	80 3d 00 33 11 f0 00 	cmpb   $0x0,0xf0113300
f01004a3:	74 11                	je     f01004b6 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004a5:	55                   	push   %ebp
f01004a6:	89 e5                	mov    %esp,%ebp
f01004a8:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ab:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004b0:	e8 b5 fc ff ff       	call   f010016a <cons_intr>
}
f01004b5:	c9                   	leave  
f01004b6:	f3 c3                	repz ret 

f01004b8 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004be:	b8 95 03 10 f0       	mov    $0xf0100395,%eax
f01004c3:	e8 a2 fc ff ff       	call   f010016a <cons_intr>
}
f01004c8:	c9                   	leave  
f01004c9:	c3                   	ret    

f01004ca <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ca:	55                   	push   %ebp
f01004cb:	89 e5                	mov    %esp,%ebp
f01004cd:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004d0:	e8 c7 ff ff ff       	call   f010049c <serial_intr>
	kbd_intr();
f01004d5:	e8 de ff ff ff       	call   f01004b8 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004da:	8b 15 20 35 11 f0    	mov    0xf0113520,%edx
f01004e0:	3b 15 24 35 11 f0    	cmp    0xf0113524,%edx
f01004e6:	74 20                	je     f0100508 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004e8:	0f b6 82 20 33 11 f0 	movzbl -0xfeecce0(%edx),%eax
f01004ef:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f01004f8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004fd:	0f 44 d1             	cmove  %ecx,%edx
f0100500:	89 15 20 35 11 f0    	mov    %edx,0xf0113520
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100535:	c7 05 2c 35 11 f0 b4 	movl   $0x3b4,0xf011352c
f010053c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 2c 35 11 f0 d4 	movl   $0x3d4,0xf011352c
f0100554:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055c:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 30 35 11 f0    	mov    %edi,0xf0113530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010058c:	66 89 35 34 35 11 f0 	mov    %si,0xf0113534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 00 33 11 f0    	mov    %cl,0xf0113300
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 99 1e 10 f0 	movl   $0xf0101e99,(%esp)
f01005f4:	e8 a5 06 00 00       	call   f0100c9e <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 9b fb ff ff       	call   f01001aa <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 ae fe ff ff       	call   f01004ca <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100636:	c7 04 24 d0 20 10 f0 	movl   $0xf01020d0,(%esp)
f010063d:	e8 5c 06 00 00       	call   f0100c9e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 f4 21 10 f0 	movl   $0xf01021f4,(%esp)
f0100651:	e8 48 06 00 00       	call   f0100c9e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 1c 22 10 f0 	movl   $0xf010221c,(%esp)
f010066d:	e8 2c 06 00 00       	call   f0100c9e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 2f 1e 10 	movl   $0x101e2f,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 2f 1e 10 	movl   $0xf0101e2f,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 40 22 10 f0 	movl   $0xf0102240,(%esp)
f0100689:	e8 10 06 00 00       	call   f0100c9e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 00 33 11 	movl   $0x113300,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 00 33 11 	movl   $0xf0113300,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 64 22 10 f0 	movl   $0xf0102264,(%esp)
f01006a5:	e8 f4 05 00 00       	call   f0100c9e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 70 39 11 	movl   $0x113970,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 70 39 11 	movl   $0xf0113970,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 88 22 10 f0 	movl   $0xf0102288,(%esp)
f01006c1:	e8 d8 05 00 00       	call   f0100c9e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 6f 3d 11 f0       	mov    $0xf0113d6f,%eax
f01006cb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006d0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006d5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006db:	85 c0                	test   %eax,%eax
f01006dd:	0f 48 c2             	cmovs  %edx,%eax
f01006e0:	c1 f8 0a             	sar    $0xa,%eax
f01006e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006e7:	c7 04 24 ac 22 10 f0 	movl   $0xf01022ac,(%esp)
f01006ee:	e8 ab 05 00 00       	call   f0100c9e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f8:	c9                   	leave  
f01006f9:	c3                   	ret    

f01006fa <mon_help>:
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006fa:	55                   	push   %ebp
f01006fb:	89 e5                	mov    %esp,%ebp
f01006fd:	56                   	push   %esi
f01006fe:	53                   	push   %ebx
f01006ff:	83 ec 10             	sub    $0x10,%esp
f0100702:	bb e4 23 10 f0       	mov    $0xf01023e4,%ebx
	return 0;
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100707:	be 14 24 10 f0       	mov    $0xf0102414,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010070c:	8b 03                	mov    (%ebx),%eax
f010070e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100712:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100715:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100719:	c7 04 24 e9 20 10 f0 	movl   $0xf01020e9,(%esp)
f0100720:	e8 79 05 00 00       	call   f0100c9e <cprintf>
f0100725:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100728:	39 f3                	cmp    %esi,%ebx
f010072a:	75 e0                	jne    f010070c <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	83 c4 10             	add    $0x10,%esp
f0100734:	5b                   	pop    %ebx
f0100735:	5e                   	pop    %esi
f0100736:	5d                   	pop    %ebp
f0100737:	c3                   	ret    

f0100738 <mon_changecolor>:

int ftcolor = 0;

int 
mon_changecolor(int argc, char **argv, struct Trapframe *tf)
{
f0100738:	55                   	push   %ebp
f0100739:	89 e5                	mov    %esp,%ebp
f010073b:	53                   	push   %ebx
f010073c:	83 ec 14             	sub    $0x14,%esp
f010073f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc > 1) {
f0100742:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100746:	0f 8e 48 01 00 00    	jle    f0100894 <mon_changecolor+0x15c>
		if (strcmp(argv[1], "ble") == 0) ftcolor = CLRBLE;
f010074c:	c7 44 24 04 f2 20 10 	movl   $0xf01020f2,0x4(%esp)
f0100753:	f0 
f0100754:	8b 43 04             	mov    0x4(%ebx),%eax
f0100757:	89 04 24             	mov    %eax,(%esp)
f010075a:	e8 b2 10 00 00       	call   f0101811 <strcmp>
f010075f:	85 c0                	test   %eax,%eax
f0100761:	75 0f                	jne    f0100772 <mon_changecolor+0x3a>
f0100763:	c7 05 38 35 11 f0 01 	movl   $0x1,0xf0113538
f010076a:	00 00 00 
f010076d:	e9 22 01 00 00       	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "grn") == 0) ftcolor = CLRGRN;
f0100772:	c7 44 24 04 f6 20 10 	movl   $0xf01020f6,0x4(%esp)
f0100779:	f0 
f010077a:	8b 43 04             	mov    0x4(%ebx),%eax
f010077d:	89 04 24             	mov    %eax,(%esp)
f0100780:	e8 8c 10 00 00       	call   f0101811 <strcmp>
f0100785:	85 c0                	test   %eax,%eax
f0100787:	75 0f                	jne    f0100798 <mon_changecolor+0x60>
f0100789:	c7 05 38 35 11 f0 02 	movl   $0x2,0xf0113538
f0100790:	00 00 00 
f0100793:	e9 fc 00 00 00       	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "red") == 0) ftcolor = CLRRED;
f0100798:	c7 44 24 04 fa 20 10 	movl   $0xf01020fa,0x4(%esp)
f010079f:	f0 
f01007a0:	8b 43 04             	mov    0x4(%ebx),%eax
f01007a3:	89 04 24             	mov    %eax,(%esp)
f01007a6:	e8 66 10 00 00       	call   f0101811 <strcmp>
f01007ab:	85 c0                	test   %eax,%eax
f01007ad:	75 0f                	jne    f01007be <mon_changecolor+0x86>
f01007af:	c7 05 38 35 11 f0 04 	movl   $0x4,0xf0113538
f01007b6:	00 00 00 
f01007b9:	e9 d6 00 00 00       	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "pnk") == 0) ftcolor = CLRPNK;
f01007be:	c7 44 24 04 fe 20 10 	movl   $0xf01020fe,0x4(%esp)
f01007c5:	f0 
f01007c6:	8b 43 04             	mov    0x4(%ebx),%eax
f01007c9:	89 04 24             	mov    %eax,(%esp)
f01007cc:	e8 40 10 00 00       	call   f0101811 <strcmp>
f01007d1:	85 c0                	test   %eax,%eax
f01007d3:	75 0f                	jne    f01007e4 <mon_changecolor+0xac>
f01007d5:	c7 05 38 35 11 f0 0c 	movl   $0xc,0xf0113538
f01007dc:	00 00 00 
f01007df:	e9 b0 00 00 00       	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "wht") == 0) ftcolor = CLRWHT;
f01007e4:	c7 44 24 04 02 21 10 	movl   $0xf0102102,0x4(%esp)
f01007eb:	f0 
f01007ec:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ef:	89 04 24             	mov    %eax,(%esp)
f01007f2:	e8 1a 10 00 00       	call   f0101811 <strcmp>
f01007f7:	85 c0                	test   %eax,%eax
f01007f9:	75 0f                	jne    f010080a <mon_changecolor+0xd2>
f01007fb:	c7 05 38 35 11 f0 07 	movl   $0x7,0xf0113538
f0100802:	00 00 00 
f0100805:	e9 8a 00 00 00       	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "gry") == 0) ftcolor = CLRGRY;
f010080a:	c7 44 24 04 06 21 10 	movl   $0xf0102106,0x4(%esp)
f0100811:	f0 
f0100812:	8b 43 04             	mov    0x4(%ebx),%eax
f0100815:	89 04 24             	mov    %eax,(%esp)
f0100818:	e8 f4 0f 00 00       	call   f0101811 <strcmp>
f010081d:	85 c0                	test   %eax,%eax
f010081f:	75 0c                	jne    f010082d <mon_changecolor+0xf5>
f0100821:	c7 05 38 35 11 f0 08 	movl   $0x8,0xf0113538
f0100828:	00 00 00 
f010082b:	eb 67                	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "ylw") == 0) ftcolor = CLRYLW;
f010082d:	c7 44 24 04 0a 21 10 	movl   $0xf010210a,0x4(%esp)
f0100834:	f0 
f0100835:	8b 43 04             	mov    0x4(%ebx),%eax
f0100838:	89 04 24             	mov    %eax,(%esp)
f010083b:	e8 d1 0f 00 00       	call   f0101811 <strcmp>
f0100840:	85 c0                	test   %eax,%eax
f0100842:	75 0c                	jne    f0100850 <mon_changecolor+0x118>
f0100844:	c7 05 38 35 11 f0 0e 	movl   $0xe,0xf0113538
f010084b:	00 00 00 
f010084e:	eb 44                	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "cyn") == 0) ftcolor = CLRCYN;
f0100850:	c7 44 24 04 0e 21 10 	movl   $0xf010210e,0x4(%esp)
f0100857:	f0 
f0100858:	8b 43 04             	mov    0x4(%ebx),%eax
f010085b:	89 04 24             	mov    %eax,(%esp)
f010085e:	e8 ae 0f 00 00       	call   f0101811 <strcmp>
f0100863:	85 c0                	test   %eax,%eax
f0100865:	75 0c                	jne    f0100873 <mon_changecolor+0x13b>
f0100867:	c7 05 38 35 11 f0 0b 	movl   $0xb,0xf0113538
f010086e:	00 00 00 
f0100871:	eb 21                	jmp    f0100894 <mon_changecolor+0x15c>
		else
		if (strcmp(argv[1], "org") == 0) ftcolor = CLRORG;
f0100873:	c7 44 24 04 12 21 10 	movl   $0xf0102112,0x4(%esp)
f010087a:	f0 
f010087b:	8b 43 04             	mov    0x4(%ebx),%eax
f010087e:	89 04 24             	mov    %eax,(%esp)
f0100881:	e8 8b 0f 00 00       	call   f0101811 <strcmp>
f0100886:	85 c0                	test   %eax,%eax
f0100888:	75 0a                	jne    f0100894 <mon_changecolor+0x15c>
f010088a:	c7 05 38 35 11 f0 06 	movl   $0x6,0xf0113538
f0100891:	00 00 00 
	}
	return 0;
}
f0100894:	b8 00 00 00 00       	mov    $0x0,%eax
f0100899:	83 c4 14             	add    $0x14,%esp
f010089c:	5b                   	pop    %ebx
f010089d:	5d                   	pop    %ebp
f010089e:	c3                   	ret    

f010089f <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089f:	55                   	push   %ebp
f01008a0:	89 e5                	mov    %esp,%ebp
f01008a2:	57                   	push   %edi
f01008a3:	56                   	push   %esi
f01008a4:	53                   	push   %ebx
f01008a5:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a8:	89 ef                	mov    %ebp,%edi
	// Your code here.
	struct Eipdebuginfo info;
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
f01008aa:	8b 5f 04             	mov    0x4(%edi),%ebx
	cprintf("Stack backtrace:\n");
f01008ad:	c7 04 24 16 21 10 f0 	movl   $0xf0102116,(%esp)
f01008b4:	e8 e5 03 00 00       	call   f0100c9e <cprintf>
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
f01008b9:	85 ff                	test   %edi,%edi
f01008bb:	0f 84 94 00 00 00    	je     f0100955 <mon_backtrace+0xb6>
f01008c1:	89 fe                	mov    %edi,%esi
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for (i = 1; i <= 5; ++i) 
			cprintf(" %08x", *(ebp + 1 + i));
		cprintf("\n");
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
f01008c3:	8d 7d d0             	lea    -0x30(%ebp),%edi
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01008c6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01008ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01008ce:	c7 04 24 28 21 10 f0 	movl   $0xf0102128,(%esp)
f01008d5:	e8 c4 03 00 00       	call   f0100c9e <cprintf>
		for (i = 1; i <= 5; ++i) 
f01008da:	bb 01 00 00 00       	mov    $0x1,%ebx
			cprintf(" %08x", *(ebp + 1 + i));
f01008df:	8b 44 9e 04          	mov    0x4(%esi,%ebx,4),%eax
f01008e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e7:	c7 04 24 43 21 10 f0 	movl   $0xf0102143,(%esp)
f01008ee:	e8 ab 03 00 00       	call   f0100c9e <cprintf>
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for (i = 1; i <= 5; ++i) 
f01008f3:	83 c3 01             	add    $0x1,%ebx
f01008f6:	83 fb 06             	cmp    $0x6,%ebx
f01008f9:	75 e4                	jne    f01008df <mon_backtrace+0x40>
			cprintf(" %08x", *(ebp + 1 + i));
		cprintf("\n");
f01008fb:	c7 04 24 97 1e 10 f0 	movl   $0xf0101e97,(%esp)
f0100902:	e8 97 03 00 00       	call   f0100c9e <cprintf>
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
f0100907:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010090b:	8b 46 04             	mov    0x4(%esi),%eax
f010090e:	89 04 24             	mov    %eax,(%esp)
f0100911:	e8 87 04 00 00       	call   f0100d9d <debuginfo_eip>
		cprintf("         %s:%d: %.*s+%u\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (unsigned int)(*(ebp + 1) - info.eip_fn_addr));
f0100916:	8b 46 04             	mov    0x4(%esi),%eax
f0100919:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010091c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100920:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100923:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100927:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010092a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010092e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100931:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100935:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100938:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093c:	c7 04 24 49 21 10 f0 	movl   $0xf0102149,(%esp)
f0100943:	e8 56 03 00 00       	call   f0100c9e <cprintf>
	struct Eipdebuginfo info;
	int i = 1;
	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = *(ebp + 1); // return address
	cprintf("Stack backtrace:\n");
	for (; ebp != 0; ebp = (uint32_t*)(*(ebp)), eip = *(ebp + 1)) {
f0100948:	8b 36                	mov    (%esi),%esi
f010094a:	8b 5e 04             	mov    0x4(%esi),%ebx
f010094d:	85 f6                	test   %esi,%esi
f010094f:	0f 85 71 ff ff ff    	jne    f01008c6 <mon_backtrace+0x27>
		cprintf("\n");
		debuginfo_eip((uintptr_t)(*(ebp + 1)), &info);
		cprintf("         %s:%d: %.*s+%u\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (unsigned int)(*(ebp + 1) - info.eip_fn_addr));
	}
	return 0;
}
f0100955:	b8 00 00 00 00       	mov    $0x0,%eax
f010095a:	83 c4 4c             	add    $0x4c,%esp
f010095d:	5b                   	pop    %ebx
f010095e:	5e                   	pop    %esi
f010095f:	5f                   	pop    %edi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    

f0100962 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	57                   	push   %edi
f0100966:	56                   	push   %esi
f0100967:	53                   	push   %ebx
f0100968:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010096b:	c7 04 24 d8 22 10 f0 	movl   $0xf01022d8,(%esp)
f0100972:	e8 27 03 00 00       	call   f0100c9e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100977:	c7 04 24 fc 22 10 f0 	movl   $0xf01022fc,(%esp)
f010097e:	e8 1b 03 00 00       	call   f0100c9e <cprintf>
	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f0100983:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010098a:	00 
f010098b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f0100992:	00 
f0100993:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010099a:	00 
f010099b:	c7 04 24 62 21 10 f0 	movl   $0xf0102162,(%esp)
f01009a2:	e8 f7 02 00 00       	call   f0100c9e <cprintf>

	while (1) {
		buf = readline("K> ");
f01009a7:	c7 04 24 74 21 10 f0 	movl   $0xf0102174,(%esp)
f01009ae:	e8 6d 0c 00 00       	call   f0101620 <readline>
f01009b3:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009b5:	85 c0                	test   %eax,%eax
f01009b7:	74 ee                	je     f01009a7 <monitor+0x45>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009b9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009c0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01009c5:	eb 06                	jmp    f01009cd <monitor+0x6b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009c7:	c6 06 00             	movb   $0x0,(%esi)
f01009ca:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009cd:	0f b6 06             	movzbl (%esi),%eax
f01009d0:	84 c0                	test   %al,%al
f01009d2:	74 6a                	je     f0100a3e <monitor+0xdc>
f01009d4:	0f be c0             	movsbl %al,%eax
f01009d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009db:	c7 04 24 78 21 10 f0 	movl   $0xf0102178,(%esp)
f01009e2:	e8 ae 0e 00 00       	call   f0101895 <strchr>
f01009e7:	85 c0                	test   %eax,%eax
f01009e9:	75 dc                	jne    f01009c7 <monitor+0x65>
			*buf++ = 0;
		if (*buf == 0)
f01009eb:	80 3e 00             	cmpb   $0x0,(%esi)
f01009ee:	74 4e                	je     f0100a3e <monitor+0xdc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009f0:	83 fb 0f             	cmp    $0xf,%ebx
f01009f3:	75 16                	jne    f0100a0b <monitor+0xa9>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009f5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01009fc:	00 
f01009fd:	c7 04 24 7d 21 10 f0 	movl   $0xf010217d,(%esp)
f0100a04:	e8 95 02 00 00       	call   f0100c9e <cprintf>
f0100a09:	eb 9c                	jmp    f01009a7 <monitor+0x45>
			return 0;
		}
		argv[argc++] = buf;
f0100a0b:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100a0f:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a12:	0f b6 06             	movzbl (%esi),%eax
f0100a15:	84 c0                	test   %al,%al
f0100a17:	75 0c                	jne    f0100a25 <monitor+0xc3>
f0100a19:	eb b2                	jmp    f01009cd <monitor+0x6b>
			buf++;
f0100a1b:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a1e:	0f b6 06             	movzbl (%esi),%eax
f0100a21:	84 c0                	test   %al,%al
f0100a23:	74 a8                	je     f01009cd <monitor+0x6b>
f0100a25:	0f be c0             	movsbl %al,%eax
f0100a28:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a2c:	c7 04 24 78 21 10 f0 	movl   $0xf0102178,(%esp)
f0100a33:	e8 5d 0e 00 00       	call   f0101895 <strchr>
f0100a38:	85 c0                	test   %eax,%eax
f0100a3a:	74 df                	je     f0100a1b <monitor+0xb9>
f0100a3c:	eb 8f                	jmp    f01009cd <monitor+0x6b>
			buf++;
	}
	argv[argc] = 0;
f0100a3e:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100a45:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a46:	85 db                	test   %ebx,%ebx
f0100a48:	0f 84 59 ff ff ff    	je     f01009a7 <monitor+0x45>
f0100a4e:	bf e0 23 10 f0       	mov    $0xf01023e0,%edi
f0100a53:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a58:	8b 07                	mov    (%edi),%eax
f0100a5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a5e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a61:	89 04 24             	mov    %eax,(%esp)
f0100a64:	e8 a8 0d 00 00       	call   f0101811 <strcmp>
f0100a69:	85 c0                	test   %eax,%eax
f0100a6b:	75 24                	jne    f0100a91 <monitor+0x12f>
			return commands[i].func(argc, argv, tf);
f0100a6d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a70:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a73:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a77:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a7a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a7e:	89 1c 24             	mov    %ebx,(%esp)
f0100a81:	ff 14 85 e8 23 10 f0 	call   *-0xfefdc18(,%eax,4)
	cprintf("x %d, y %x, z %d\n", x, y, z);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a88:	85 c0                	test   %eax,%eax
f0100a8a:	78 28                	js     f0100ab4 <monitor+0x152>
f0100a8c:	e9 16 ff ff ff       	jmp    f01009a7 <monitor+0x45>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a91:	83 c6 01             	add    $0x1,%esi
f0100a94:	83 c7 0c             	add    $0xc,%edi
f0100a97:	83 fe 04             	cmp    $0x4,%esi
f0100a9a:	75 bc                	jne    f0100a58 <monitor+0xf6>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a9c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a9f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aa3:	c7 04 24 9a 21 10 f0 	movl   $0xf010219a,(%esp)
f0100aaa:	e8 ef 01 00 00       	call   f0100c9e <cprintf>
f0100aaf:	e9 f3 fe ff ff       	jmp    f01009a7 <monitor+0x45>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ab4:	83 c4 5c             	add    $0x5c,%esp
f0100ab7:	5b                   	pop    %ebx
f0100ab8:	5e                   	pop    %esi
f0100ab9:	5f                   	pop    %edi
f0100aba:	5d                   	pop    %ebp
f0100abb:	c3                   	ret    

f0100abc <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100abc:	55                   	push   %ebp
f0100abd:	89 e5                	mov    %esp,%ebp
f0100abf:	56                   	push   %esi
f0100ac0:	53                   	push   %ebx
f0100ac1:	83 ec 10             	sub    $0x10,%esp
f0100ac4:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ac6:	89 04 24             	mov    %eax,(%esp)
f0100ac9:	e8 5e 01 00 00       	call   f0100c2c <mc146818_read>
f0100ace:	89 c6                	mov    %eax,%esi
f0100ad0:	83 c3 01             	add    $0x1,%ebx
f0100ad3:	89 1c 24             	mov    %ebx,(%esp)
f0100ad6:	e8 51 01 00 00       	call   f0100c2c <mc146818_read>
f0100adb:	c1 e0 08             	shl    $0x8,%eax
f0100ade:	09 f0                	or     %esi,%eax
}
f0100ae0:	83 c4 10             	add    $0x10,%esp
f0100ae3:	5b                   	pop    %ebx
f0100ae4:	5e                   	pop    %esi
f0100ae5:	5d                   	pop    %ebp
f0100ae6:	c3                   	ret    

f0100ae7 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ae7:	55                   	push   %ebp
f0100ae8:	89 e5                	mov    %esp,%ebp
f0100aea:	83 ec 18             	sub    $0x18,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100aed:	b8 15 00 00 00       	mov    $0x15,%eax
f0100af2:	e8 c5 ff ff ff       	call   f0100abc <nvram_read>
f0100af7:	c1 e0 0a             	shl    $0xa,%eax
f0100afa:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b00:	85 c0                	test   %eax,%eax
f0100b02:	0f 48 c2             	cmovs  %edx,%eax
f0100b05:	c1 f8 0c             	sar    $0xc,%eax
f0100b08:	a3 3c 35 11 f0       	mov    %eax,0xf011353c
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100b0d:	b8 17 00 00 00       	mov    $0x17,%eax
f0100b12:	e8 a5 ff ff ff       	call   f0100abc <nvram_read>
f0100b17:	c1 e0 0a             	shl    $0xa,%eax
f0100b1a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b20:	85 c0                	test   %eax,%eax
f0100b22:	0f 48 c2             	cmovs  %edx,%eax
f0100b25:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100b28:	85 c0                	test   %eax,%eax
f0100b2a:	74 0e                	je     f0100b3a <mem_init+0x53>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100b2c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100b32:	89 15 64 39 11 f0    	mov    %edx,0xf0113964
f0100b38:	eb 0c                	jmp    f0100b46 <mem_init+0x5f>
	else
		npages = npages_basemem;
f0100b3a:	8b 15 3c 35 11 f0    	mov    0xf011353c,%edx
f0100b40:	89 15 64 39 11 f0    	mov    %edx,0xf0113964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100b46:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b49:	c1 e8 0a             	shr    $0xa,%eax
f0100b4c:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100b50:	a1 3c 35 11 f0       	mov    0xf011353c,%eax
f0100b55:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b58:	c1 e8 0a             	shr    $0xa,%eax
f0100b5b:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100b5f:	a1 64 39 11 f0       	mov    0xf0113964,%eax
f0100b64:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b67:	c1 e8 0a             	shr    $0xa,%eax
f0100b6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b6e:	c7 04 24 10 24 10 f0 	movl   $0xf0102410,(%esp)
f0100b75:	e8 24 01 00 00       	call   f0100c9e <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100b7a:	c7 44 24 08 4c 24 10 	movl   $0xf010244c,0x8(%esp)
f0100b81:	f0 
f0100b82:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f0100b89:	00 
f0100b8a:	c7 04 24 78 24 10 f0 	movl   $0xf0102478,(%esp)
f0100b91:	e8 fe f4 ff ff       	call   f0100094 <_panic>

f0100b96 <page_init>:
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100b96:	83 3d 64 39 11 f0 00 	cmpl   $0x0,0xf0113964
f0100b9d:	74 41                	je     f0100be0 <page_init+0x4a>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100b9f:	55                   	push   %ebp
f0100ba0:	89 e5                	mov    %esp,%ebp
f0100ba2:	53                   	push   %ebx
f0100ba3:	8b 1d 40 35 11 f0    	mov    0xf0113540,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100ba9:	b8 00 00 00 00       	mov    $0x0,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100bae:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
		pages[i].pp_ref = 0;
f0100bb5:	8b 0d 6c 39 11 f0    	mov    0xf011396c,%ecx
f0100bbb:	01 d1                	add    %edx,%ecx
f0100bbd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100bc3:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100bc5:	8b 1d 6c 39 11 f0    	mov    0xf011396c,%ebx
f0100bcb:	01 d3                	add    %edx,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100bcd:	83 c0 01             	add    $0x1,%eax
f0100bd0:	39 05 64 39 11 f0    	cmp    %eax,0xf0113964
f0100bd6:	77 d6                	ja     f0100bae <page_init+0x18>
f0100bd8:	89 1d 40 35 11 f0    	mov    %ebx,0xf0113540
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100bde:	5b                   	pop    %ebx
f0100bdf:	5d                   	pop    %ebp
f0100be0:	f3 c3                	repz ret 

f0100be2 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100be2:	55                   	push   %ebp
f0100be3:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100be5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bea:	5d                   	pop    %ebp
f0100beb:	c3                   	ret    

f0100bec <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100bec:	55                   	push   %ebp
f0100bed:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100bef:	5d                   	pop    %ebp
f0100bf0:	c3                   	ret    

f0100bf1 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100bf1:	55                   	push   %ebp
f0100bf2:	89 e5                	mov    %esp,%ebp
f0100bf4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100bf7:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100bfc:	5d                   	pop    %ebp
f0100bfd:	c3                   	ret    

f0100bfe <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100bfe:	55                   	push   %ebp
f0100bff:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100c01:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c06:	5d                   	pop    %ebp
f0100c07:	c3                   	ret    

f0100c08 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100c08:	55                   	push   %ebp
f0100c09:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100c0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c10:	5d                   	pop    %ebp
f0100c11:	c3                   	ret    

f0100c12 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100c12:	55                   	push   %ebp
f0100c13:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100c15:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c1a:	5d                   	pop    %ebp
f0100c1b:	c3                   	ret    

f0100c1c <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100c1c:	55                   	push   %ebp
f0100c1d:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100c1f:	5d                   	pop    %ebp
f0100c20:	c3                   	ret    

f0100c21 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100c21:	55                   	push   %ebp
f0100c22:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100c24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c27:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100c2a:	5d                   	pop    %ebp
f0100c2b:	c3                   	ret    

f0100c2c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100c2c:	55                   	push   %ebp
f0100c2d:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100c2f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100c33:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c38:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100c39:	b2 71                	mov    $0x71,%dl
f0100c3b:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100c3c:	0f b6 c0             	movzbl %al,%eax
}
f0100c3f:	5d                   	pop    %ebp
f0100c40:	c3                   	ret    

f0100c41 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100c41:	55                   	push   %ebp
f0100c42:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100c44:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100c48:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c4d:	ee                   	out    %al,(%dx)
f0100c4e:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0100c52:	b2 71                	mov    $0x71,%dl
f0100c54:	ee                   	out    %al,(%dx)
f0100c55:	5d                   	pop    %ebp
f0100c56:	c3                   	ret    
f0100c57:	90                   	nop

f0100c58 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c58:	55                   	push   %ebp
f0100c59:	89 e5                	mov    %esp,%ebp
f0100c5b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c61:	89 04 24             	mov    %eax,(%esp)
f0100c64:	e8 98 f9 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0100c69:	c9                   	leave  
f0100c6a:	c3                   	ret    

f0100c6b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c6b:	55                   	push   %ebp
f0100c6c:	89 e5                	mov    %esp,%ebp
f0100c6e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100c71:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c78:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c7b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c7f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c82:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c86:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8d:	c7 04 24 58 0c 10 f0 	movl   $0xf0100c58,(%esp)
f0100c94:	e8 f9 04 00 00       	call   f0101192 <vprintfmt>
	return cnt;
}
f0100c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c9c:	c9                   	leave  
f0100c9d:	c3                   	ret    

f0100c9e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c9e:	55                   	push   %ebp
f0100c9f:	89 e5                	mov    %esp,%ebp
f0100ca1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ca4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ca7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cae:	89 04 24             	mov    %eax,(%esp)
f0100cb1:	e8 b5 ff ff ff       	call   f0100c6b <vcprintf>
	va_end(ap);

	return cnt;
}
f0100cb6:	c9                   	leave  
f0100cb7:	c3                   	ret    
f0100cb8:	66 90                	xchg   %ax,%ax
f0100cba:	66 90                	xchg   %ax,%ax
f0100cbc:	66 90                	xchg   %ax,%ax
f0100cbe:	66 90                	xchg   %ax,%ax

f0100cc0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100cc0:	55                   	push   %ebp
f0100cc1:	89 e5                	mov    %esp,%ebp
f0100cc3:	57                   	push   %edi
f0100cc4:	56                   	push   %esi
f0100cc5:	53                   	push   %ebx
f0100cc6:	83 ec 10             	sub    $0x10,%esp
f0100cc9:	89 c6                	mov    %eax,%esi
f0100ccb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100cce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100cd1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100cd4:	8b 1a                	mov    (%edx),%ebx
f0100cd6:	8b 09                	mov    (%ecx),%ecx
f0100cd8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100cdb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100ce2:	eb 77                	jmp    f0100d5b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100ce4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ce7:	01 d8                	add    %ebx,%eax
f0100ce9:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100cee:	99                   	cltd   
f0100cef:	f7 f9                	idiv   %ecx
f0100cf1:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cf3:	eb 01                	jmp    f0100cf6 <stab_binsearch+0x36>
			m--;
f0100cf5:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cf6:	39 d9                	cmp    %ebx,%ecx
f0100cf8:	7c 1d                	jl     f0100d17 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100cfa:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cfd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100d02:	39 fa                	cmp    %edi,%edx
f0100d04:	75 ef                	jne    f0100cf5 <stab_binsearch+0x35>
f0100d06:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100d09:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100d0c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100d10:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100d13:	73 18                	jae    f0100d2d <stab_binsearch+0x6d>
f0100d15:	eb 05                	jmp    f0100d1c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100d17:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100d1a:	eb 3f                	jmp    f0100d5b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100d1c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d1f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100d21:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d24:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d2b:	eb 2e                	jmp    f0100d5b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100d2d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100d30:	73 15                	jae    f0100d47 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100d32:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100d35:	49                   	dec    %ecx
f0100d36:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100d39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d3c:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d3e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d45:	eb 14                	jmp    f0100d5b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d47:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d4a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d4d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100d4f:	ff 45 0c             	incl   0xc(%ebp)
f0100d52:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d54:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100d5b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100d5e:	7e 84                	jle    f0100ce4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100d60:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100d64:	75 0d                	jne    f0100d73 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100d66:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d69:	8b 02                	mov    (%edx),%eax
f0100d6b:	48                   	dec    %eax
f0100d6c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d6f:	89 01                	mov    %eax,(%ecx)
f0100d71:	eb 22                	jmp    f0100d95 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d73:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d76:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d78:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d7b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d7d:	eb 01                	jmp    f0100d80 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100d7f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d80:	39 c1                	cmp    %eax,%ecx
f0100d82:	7d 0c                	jge    f0100d90 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d84:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100d87:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100d8c:	39 fa                	cmp    %edi,%edx
f0100d8e:	75 ef                	jne    f0100d7f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100d90:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d93:	89 02                	mov    %eax,(%edx)
	}
}
f0100d95:	83 c4 10             	add    $0x10,%esp
f0100d98:	5b                   	pop    %ebx
f0100d99:	5e                   	pop    %esi
f0100d9a:	5f                   	pop    %edi
f0100d9b:	5d                   	pop    %ebp
f0100d9c:	c3                   	ret    

f0100d9d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d9d:	55                   	push   %ebp
f0100d9e:	89 e5                	mov    %esp,%ebp
f0100da0:	83 ec 58             	sub    $0x58,%esp
f0100da3:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100da6:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100da9:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100dac:	8b 75 08             	mov    0x8(%ebp),%esi
f0100daf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100db2:	c7 03 84 24 10 f0    	movl   $0xf0102484,(%ebx)
	info->eip_line = 0;
f0100db8:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100dbf:	c7 43 08 84 24 10 f0 	movl   $0xf0102484,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100dc6:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100dcd:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100dd0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100dd7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ddd:	76 12                	jbe    f0100df1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ddf:	b8 fe 87 10 f0       	mov    $0xf01087fe,%eax
f0100de4:	3d f9 6b 10 f0       	cmp    $0xf0106bf9,%eax
f0100de9:	0f 86 f5 01 00 00    	jbe    f0100fe4 <debuginfo_eip+0x247>
f0100def:	eb 1c                	jmp    f0100e0d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100df1:	c7 44 24 08 8e 24 10 	movl   $0xf010248e,0x8(%esp)
f0100df8:	f0 
f0100df9:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100e00:	00 
f0100e01:	c7 04 24 9b 24 10 f0 	movl   $0xf010249b,(%esp)
f0100e08:	e8 87 f2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100e0d:	80 3d fd 87 10 f0 00 	cmpb   $0x0,0xf01087fd
f0100e14:	0f 85 d1 01 00 00    	jne    f0100feb <debuginfo_eip+0x24e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100e1a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100e21:	b8 f8 6b 10 f0       	mov    $0xf0106bf8,%eax
f0100e26:	2d bc 26 10 f0       	sub    $0xf01026bc,%eax
f0100e2b:	c1 f8 02             	sar    $0x2,%eax
f0100e2e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100e34:	83 e8 01             	sub    $0x1,%eax
f0100e37:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100e3a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e3e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100e45:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e48:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e4b:	b8 bc 26 10 f0       	mov    $0xf01026bc,%eax
f0100e50:	e8 6b fe ff ff       	call   f0100cc0 <stab_binsearch>
	if (lfile == 0)
f0100e55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e58:	85 c0                	test   %eax,%eax
f0100e5a:	0f 84 92 01 00 00    	je     f0100ff2 <debuginfo_eip+0x255>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e60:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100e63:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e66:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e69:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e6d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100e74:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e77:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e7a:	b8 bc 26 10 f0       	mov    $0xf01026bc,%eax
f0100e7f:	e8 3c fe ff ff       	call   f0100cc0 <stab_binsearch>

	if (lfun <= rfun) {
f0100e84:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e87:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e8a:	39 d0                	cmp    %edx,%eax
f0100e8c:	7f 3d                	jg     f0100ecb <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100e8e:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100e91:	8d b9 bc 26 10 f0    	lea    -0xfefd944(%ecx),%edi
f0100e97:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100e9a:	8b 89 bc 26 10 f0    	mov    -0xfefd944(%ecx),%ecx
f0100ea0:	bf fe 87 10 f0       	mov    $0xf01087fe,%edi
f0100ea5:	81 ef f9 6b 10 f0    	sub    $0xf0106bf9,%edi
f0100eab:	39 f9                	cmp    %edi,%ecx
f0100ead:	73 09                	jae    f0100eb8 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100eaf:	81 c1 f9 6b 10 f0    	add    $0xf0106bf9,%ecx
f0100eb5:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100eb8:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ebb:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ebe:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ec1:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ec3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ec6:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ec9:	eb 0f                	jmp    f0100eda <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ecb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ece:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ed1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ed4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ed7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100eda:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100ee1:	00 
f0100ee2:	8b 43 08             	mov    0x8(%ebx),%eax
f0100ee5:	89 04 24             	mov    %eax,(%esp)
f0100ee8:	e8 de 09 00 00       	call   f01018cb <strfind>
f0100eed:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ef0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ef3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ef7:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100efe:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100f01:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100f04:	b8 bc 26 10 f0       	mov    $0xf01026bc,%eax
f0100f09:	e8 b2 fd ff ff       	call   f0100cc0 <stab_binsearch>
	if (lline > rline)
f0100f0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f11:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100f14:	0f 8f df 00 00 00    	jg     f0100ff9 <debuginfo_eip+0x25c>
		return -1;
	else 
		info->eip_line = stabs[lline].n_desc;
f0100f1a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f1d:	0f b7 80 c2 26 10 f0 	movzwl -0xfefd93e(%eax),%eax
f0100f24:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f2a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f2d:	39 f0                	cmp    %esi,%eax
f0100f2f:	7c 63                	jl     f0100f94 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100f31:	6b f8 0c             	imul   $0xc,%eax,%edi
f0100f34:	81 c7 bc 26 10 f0    	add    $0xf01026bc,%edi
f0100f3a:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100f3e:	80 f9 84             	cmp    $0x84,%cl
f0100f41:	74 32                	je     f0100f75 <debuginfo_eip+0x1d8>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100f43:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100f46:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100f49:	81 c2 bc 26 10 f0    	add    $0xf01026bc,%edx
f0100f4f:	eb 15                	jmp    f0100f66 <debuginfo_eip+0x1c9>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100f51:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f54:	39 f0                	cmp    %esi,%eax
f0100f56:	7c 3c                	jl     f0100f94 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100f58:	89 d7                	mov    %edx,%edi
f0100f5a:	83 ea 0c             	sub    $0xc,%edx
f0100f5d:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0100f61:	80 f9 84             	cmp    $0x84,%cl
f0100f64:	74 0f                	je     f0100f75 <debuginfo_eip+0x1d8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f66:	80 f9 64             	cmp    $0x64,%cl
f0100f69:	75 e6                	jne    f0100f51 <debuginfo_eip+0x1b4>
f0100f6b:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100f6f:	74 e0                	je     f0100f51 <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f71:	39 c6                	cmp    %eax,%esi
f0100f73:	7f 1f                	jg     f0100f94 <debuginfo_eip+0x1f7>
f0100f75:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f78:	8b 80 bc 26 10 f0    	mov    -0xfefd944(%eax),%eax
f0100f7e:	ba fe 87 10 f0       	mov    $0xf01087fe,%edx
f0100f83:	81 ea f9 6b 10 f0    	sub    $0xf0106bf9,%edx
f0100f89:	39 d0                	cmp    %edx,%eax
f0100f8b:	73 07                	jae    f0100f94 <debuginfo_eip+0x1f7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100f8d:	05 f9 6b 10 f0       	add    $0xf0106bf9,%eax
f0100f92:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f94:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f97:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f9a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f9f:	39 ca                	cmp    %ecx,%edx
f0100fa1:	7d 70                	jge    f0101013 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
f0100fa3:	8d 42 01             	lea    0x1(%edx),%eax
f0100fa6:	39 c1                	cmp    %eax,%ecx
f0100fa8:	7e 56                	jle    f0101000 <debuginfo_eip+0x263>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100faa:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100fad:	80 b8 c0 26 10 f0 a0 	cmpb   $0xa0,-0xfefd940(%eax)
f0100fb4:	75 51                	jne    f0101007 <debuginfo_eip+0x26a>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100fb6:	8d 42 02             	lea    0x2(%edx),%eax
f0100fb9:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100fbc:	81 c2 bc 26 10 f0    	add    $0xf01026bc,%edx
f0100fc2:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100fc4:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100fc8:	39 f8                	cmp    %edi,%eax
f0100fca:	74 42                	je     f010100e <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fcc:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0100fd0:	83 c0 01             	add    $0x1,%eax
f0100fd3:	83 c2 0c             	add    $0xc,%edx
f0100fd6:	89 f1                	mov    %esi,%ecx
f0100fd8:	80 f9 a0             	cmp    $0xa0,%cl
f0100fdb:	74 e7                	je     f0100fc4 <debuginfo_eip+0x227>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fdd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe2:	eb 2f                	jmp    f0101013 <debuginfo_eip+0x276>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fe9:	eb 28                	jmp    f0101013 <debuginfo_eip+0x276>
f0100feb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ff0:	eb 21                	jmp    f0101013 <debuginfo_eip+0x276>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ff2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ff7:	eb 1a                	jmp    f0101013 <debuginfo_eip+0x276>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline)
		return -1;
f0100ff9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ffe:	eb 13                	jmp    f0101013 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101000:	b8 00 00 00 00       	mov    $0x0,%eax
f0101005:	eb 0c                	jmp    f0101013 <debuginfo_eip+0x276>
f0101007:	b8 00 00 00 00       	mov    $0x0,%eax
f010100c:	eb 05                	jmp    f0101013 <debuginfo_eip+0x276>
f010100e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101013:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101016:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101019:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010101c:	89 ec                	mov    %ebp,%esp
f010101e:	5d                   	pop    %ebp
f010101f:	c3                   	ret    

f0101020 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101020:	55                   	push   %ebp
f0101021:	89 e5                	mov    %esp,%ebp
f0101023:	57                   	push   %edi
f0101024:	56                   	push   %esi
f0101025:	53                   	push   %ebx
f0101026:	83 ec 4c             	sub    $0x4c,%esp
f0101029:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010102c:	89 d7                	mov    %edx,%edi
f010102e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101031:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101034:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101037:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010103a:	b8 00 00 00 00       	mov    $0x0,%eax
f010103f:	39 d8                	cmp    %ebx,%eax
f0101041:	72 17                	jb     f010105a <printnum+0x3a>
f0101043:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101046:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0101049:	76 0f                	jbe    f010105a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010104b:	8b 75 14             	mov    0x14(%ebp),%esi
f010104e:	83 ee 01             	sub    $0x1,%esi
f0101051:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101054:	85 f6                	test   %esi,%esi
f0101056:	7f 63                	jg     f01010bb <printnum+0x9b>
f0101058:	eb 75                	jmp    f01010cf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010105a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010105d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0101061:	8b 45 14             	mov    0x14(%ebp),%eax
f0101064:	83 e8 01             	sub    $0x1,%eax
f0101067:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010106b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010106e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101072:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101076:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010107a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010107d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101080:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101087:	00 
f0101088:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010108b:	89 1c 24             	mov    %ebx,(%esp)
f010108e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101091:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101095:	e8 b6 0a 00 00       	call   f0101b50 <__udivdi3>
f010109a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010109d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01010a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01010a4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01010a8:	89 04 24             	mov    %eax,(%esp)
f01010ab:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010af:	89 fa                	mov    %edi,%edx
f01010b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010b4:	e8 67 ff ff ff       	call   f0101020 <printnum>
f01010b9:	eb 14                	jmp    f01010cf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01010bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010bf:	8b 45 18             	mov    0x18(%ebp),%eax
f01010c2:	89 04 24             	mov    %eax,(%esp)
f01010c5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01010c7:	83 ee 01             	sub    $0x1,%esi
f01010ca:	75 ef                	jne    f01010bb <printnum+0x9b>
f01010cc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01010cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01010d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010da:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01010de:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01010e5:	00 
f01010e6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010e9:	89 1c 24             	mov    %ebx,(%esp)
f01010ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01010ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010f3:	e8 a8 0b 00 00       	call   f0101ca0 <__umoddi3>
f01010f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010fc:	0f be 80 a9 24 10 f0 	movsbl -0xfefdb57(%eax),%eax
f0101103:	89 04 24             	mov    %eax,(%esp)
f0101106:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101109:	ff d0                	call   *%eax
}
f010110b:	83 c4 4c             	add    $0x4c,%esp
f010110e:	5b                   	pop    %ebx
f010110f:	5e                   	pop    %esi
f0101110:	5f                   	pop    %edi
f0101111:	5d                   	pop    %ebp
f0101112:	c3                   	ret    

f0101113 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101113:	55                   	push   %ebp
f0101114:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101116:	83 fa 01             	cmp    $0x1,%edx
f0101119:	7e 0e                	jle    f0101129 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010111b:	8b 10                	mov    (%eax),%edx
f010111d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101120:	89 08                	mov    %ecx,(%eax)
f0101122:	8b 02                	mov    (%edx),%eax
f0101124:	8b 52 04             	mov    0x4(%edx),%edx
f0101127:	eb 22                	jmp    f010114b <getuint+0x38>
	else if (lflag)
f0101129:	85 d2                	test   %edx,%edx
f010112b:	74 10                	je     f010113d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010112d:	8b 10                	mov    (%eax),%edx
f010112f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101132:	89 08                	mov    %ecx,(%eax)
f0101134:	8b 02                	mov    (%edx),%eax
f0101136:	ba 00 00 00 00       	mov    $0x0,%edx
f010113b:	eb 0e                	jmp    f010114b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010113d:	8b 10                	mov    (%eax),%edx
f010113f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101142:	89 08                	mov    %ecx,(%eax)
f0101144:	8b 02                	mov    (%edx),%eax
f0101146:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010114b:	5d                   	pop    %ebp
f010114c:	c3                   	ret    

f010114d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010114d:	55                   	push   %ebp
f010114e:	89 e5                	mov    %esp,%ebp
f0101150:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101153:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101157:	8b 10                	mov    (%eax),%edx
f0101159:	3b 50 04             	cmp    0x4(%eax),%edx
f010115c:	73 0a                	jae    f0101168 <sprintputch+0x1b>
		*b->buf++ = ch;
f010115e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101161:	88 0a                	mov    %cl,(%edx)
f0101163:	83 c2 01             	add    $0x1,%edx
f0101166:	89 10                	mov    %edx,(%eax)
}
f0101168:	5d                   	pop    %ebp
f0101169:	c3                   	ret    

f010116a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010116a:	55                   	push   %ebp
f010116b:	89 e5                	mov    %esp,%ebp
f010116d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101170:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101173:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101177:	8b 45 10             	mov    0x10(%ebp),%eax
f010117a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010117e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101181:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101185:	8b 45 08             	mov    0x8(%ebp),%eax
f0101188:	89 04 24             	mov    %eax,(%esp)
f010118b:	e8 02 00 00 00       	call   f0101192 <vprintfmt>
	va_end(ap);
}
f0101190:	c9                   	leave  
f0101191:	c3                   	ret    

f0101192 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101192:	55                   	push   %ebp
f0101193:	89 e5                	mov    %esp,%ebp
f0101195:	57                   	push   %edi
f0101196:	56                   	push   %esi
f0101197:	53                   	push   %ebx
f0101198:	83 ec 4c             	sub    $0x4c,%esp
f010119b:	8b 75 08             	mov    0x8(%ebp),%esi
f010119e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011a1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01011a4:	eb 11                	jmp    f01011b7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01011a6:	85 c0                	test   %eax,%eax
f01011a8:	0f 84 db 03 00 00    	je     f0101589 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f01011ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b2:	89 04 24             	mov    %eax,(%esp)
f01011b5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01011b7:	0f b6 07             	movzbl (%edi),%eax
f01011ba:	83 c7 01             	add    $0x1,%edi
f01011bd:	83 f8 25             	cmp    $0x25,%eax
f01011c0:	75 e4                	jne    f01011a6 <vprintfmt+0x14>
f01011c2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f01011c6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01011cd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01011d4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01011db:	ba 00 00 00 00       	mov    $0x0,%edx
f01011e0:	eb 2b                	jmp    f010120d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011e2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01011e5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f01011e9:	eb 22                	jmp    f010120d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01011ee:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f01011f2:	eb 19                	jmp    f010120d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01011f7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01011fe:	eb 0d                	jmp    f010120d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101200:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101203:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101206:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010120d:	0f b6 0f             	movzbl (%edi),%ecx
f0101210:	8d 47 01             	lea    0x1(%edi),%eax
f0101213:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101216:	0f b6 07             	movzbl (%edi),%eax
f0101219:	83 e8 23             	sub    $0x23,%eax
f010121c:	3c 55                	cmp    $0x55,%al
f010121e:	0f 87 40 03 00 00    	ja     f0101564 <vprintfmt+0x3d2>
f0101224:	0f b6 c0             	movzbl %al,%eax
f0101227:	ff 24 85 38 25 10 f0 	jmp    *-0xfefdac8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010122e:	83 e9 30             	sub    $0x30,%ecx
f0101231:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0101234:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0101238:	8d 48 d0             	lea    -0x30(%eax),%ecx
f010123b:	83 f9 09             	cmp    $0x9,%ecx
f010123e:	77 57                	ja     f0101297 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101240:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101243:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101246:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101249:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010124c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010124f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0101253:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0101256:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101259:	83 f9 09             	cmp    $0x9,%ecx
f010125c:	76 eb                	jbe    f0101249 <vprintfmt+0xb7>
f010125e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101261:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101264:	eb 34                	jmp    f010129a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101266:	8b 45 14             	mov    0x14(%ebp),%eax
f0101269:	8d 48 04             	lea    0x4(%eax),%ecx
f010126c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010126f:	8b 00                	mov    (%eax),%eax
f0101271:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101274:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101277:	eb 21                	jmp    f010129a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0101279:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010127d:	0f 88 71 ff ff ff    	js     f01011f4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101283:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101286:	eb 85                	jmp    f010120d <vprintfmt+0x7b>
f0101288:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010128b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101292:	e9 76 ff ff ff       	jmp    f010120d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101297:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010129a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010129e:	0f 89 69 ff ff ff    	jns    f010120d <vprintfmt+0x7b>
f01012a4:	e9 57 ff ff ff       	jmp    f0101200 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01012a9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01012af:	e9 59 ff ff ff       	jmp    f010120d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01012b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b7:	8d 50 04             	lea    0x4(%eax),%edx
f01012ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01012bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c1:	8b 00                	mov    (%eax),%eax
f01012c3:	89 04 24             	mov    %eax,(%esp)
f01012c6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012c8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01012cb:	e9 e7 fe ff ff       	jmp    f01011b7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01012d0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d3:	8d 50 04             	lea    0x4(%eax),%edx
f01012d6:	89 55 14             	mov    %edx,0x14(%ebp)
f01012d9:	8b 00                	mov    (%eax),%eax
f01012db:	89 c2                	mov    %eax,%edx
f01012dd:	c1 fa 1f             	sar    $0x1f,%edx
f01012e0:	31 d0                	xor    %edx,%eax
f01012e2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01012e4:	83 f8 06             	cmp    $0x6,%eax
f01012e7:	7f 0b                	jg     f01012f4 <vprintfmt+0x162>
f01012e9:	8b 14 85 90 26 10 f0 	mov    -0xfefd970(,%eax,4),%edx
f01012f0:	85 d2                	test   %edx,%edx
f01012f2:	75 20                	jne    f0101314 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f01012f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012f8:	c7 44 24 08 c1 24 10 	movl   $0xf01024c1,0x8(%esp)
f01012ff:	f0 
f0101300:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101304:	89 34 24             	mov    %esi,(%esp)
f0101307:	e8 5e fe ff ff       	call   f010116a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010130c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010130f:	e9 a3 fe ff ff       	jmp    f01011b7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101314:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101318:	c7 44 24 08 ca 24 10 	movl   $0xf01024ca,0x8(%esp)
f010131f:	f0 
f0101320:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101324:	89 34 24             	mov    %esi,(%esp)
f0101327:	e8 3e fe ff ff       	call   f010116a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010132c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010132f:	e9 83 fe ff ff       	jmp    f01011b7 <vprintfmt+0x25>
f0101334:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101337:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010133a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010133d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101340:	8d 50 04             	lea    0x4(%eax),%edx
f0101343:	89 55 14             	mov    %edx,0x14(%ebp)
f0101346:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101348:	85 ff                	test   %edi,%edi
f010134a:	b8 ba 24 10 f0       	mov    $0xf01024ba,%eax
f010134f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101352:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0101356:	74 06                	je     f010135e <vprintfmt+0x1cc>
f0101358:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010135c:	7f 16                	jg     f0101374 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010135e:	0f b6 17             	movzbl (%edi),%edx
f0101361:	0f be c2             	movsbl %dl,%eax
f0101364:	83 c7 01             	add    $0x1,%edi
f0101367:	85 c0                	test   %eax,%eax
f0101369:	0f 85 9f 00 00 00    	jne    f010140e <vprintfmt+0x27c>
f010136f:	e9 8b 00 00 00       	jmp    f01013ff <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101374:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101378:	89 3c 24             	mov    %edi,(%esp)
f010137b:	e8 92 03 00 00       	call   f0101712 <strnlen>
f0101380:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101383:	29 c2                	sub    %eax,%edx
f0101385:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101388:	85 d2                	test   %edx,%edx
f010138a:	7e d2                	jle    f010135e <vprintfmt+0x1cc>
					putch(padc, putdat);
f010138c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0101390:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101393:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101396:	89 d7                	mov    %edx,%edi
f0101398:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010139c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010139f:	89 04 24             	mov    %eax,(%esp)
f01013a2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01013a4:	83 ef 01             	sub    $0x1,%edi
f01013a7:	75 ef                	jne    f0101398 <vprintfmt+0x206>
f01013a9:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01013ac:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01013af:	eb ad                	jmp    f010135e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01013b1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01013b5:	74 20                	je     f01013d7 <vprintfmt+0x245>
f01013b7:	0f be d2             	movsbl %dl,%edx
f01013ba:	83 ea 20             	sub    $0x20,%edx
f01013bd:	83 fa 5e             	cmp    $0x5e,%edx
f01013c0:	76 15                	jbe    f01013d7 <vprintfmt+0x245>
					putch('?', putdat);
f01013c2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01013c5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013c9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01013d0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01013d3:	ff d1                	call   *%ecx
f01013d5:	eb 0f                	jmp    f01013e6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f01013d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01013da:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013de:	89 04 24             	mov    %eax,(%esp)
f01013e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01013e4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013e6:	83 eb 01             	sub    $0x1,%ebx
f01013e9:	0f b6 17             	movzbl (%edi),%edx
f01013ec:	0f be c2             	movsbl %dl,%eax
f01013ef:	83 c7 01             	add    $0x1,%edi
f01013f2:	85 c0                	test   %eax,%eax
f01013f4:	75 24                	jne    f010141a <vprintfmt+0x288>
f01013f6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01013f9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013fc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013ff:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101402:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101406:	0f 8e ab fd ff ff    	jle    f01011b7 <vprintfmt+0x25>
f010140c:	eb 20                	jmp    f010142e <vprintfmt+0x29c>
f010140e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101411:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101414:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101417:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010141a:	85 f6                	test   %esi,%esi
f010141c:	78 93                	js     f01013b1 <vprintfmt+0x21f>
f010141e:	83 ee 01             	sub    $0x1,%esi
f0101421:	79 8e                	jns    f01013b1 <vprintfmt+0x21f>
f0101423:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101426:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101429:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010142c:	eb d1                	jmp    f01013ff <vprintfmt+0x26d>
f010142e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101431:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101435:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010143c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010143e:	83 ef 01             	sub    $0x1,%edi
f0101441:	75 ee                	jne    f0101431 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101443:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101446:	e9 6c fd ff ff       	jmp    f01011b7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010144b:	83 fa 01             	cmp    $0x1,%edx
f010144e:	66 90                	xchg   %ax,%ax
f0101450:	7e 16                	jle    f0101468 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0101452:	8b 45 14             	mov    0x14(%ebp),%eax
f0101455:	8d 50 08             	lea    0x8(%eax),%edx
f0101458:	89 55 14             	mov    %edx,0x14(%ebp)
f010145b:	8b 10                	mov    (%eax),%edx
f010145d:	8b 48 04             	mov    0x4(%eax),%ecx
f0101460:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101463:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101466:	eb 32                	jmp    f010149a <vprintfmt+0x308>
	else if (lflag)
f0101468:	85 d2                	test   %edx,%edx
f010146a:	74 18                	je     f0101484 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010146c:	8b 45 14             	mov    0x14(%ebp),%eax
f010146f:	8d 50 04             	lea    0x4(%eax),%edx
f0101472:	89 55 14             	mov    %edx,0x14(%ebp)
f0101475:	8b 00                	mov    (%eax),%eax
f0101477:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010147a:	89 c1                	mov    %eax,%ecx
f010147c:	c1 f9 1f             	sar    $0x1f,%ecx
f010147f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101482:	eb 16                	jmp    f010149a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0101484:	8b 45 14             	mov    0x14(%ebp),%eax
f0101487:	8d 50 04             	lea    0x4(%eax),%edx
f010148a:	89 55 14             	mov    %edx,0x14(%ebp)
f010148d:	8b 00                	mov    (%eax),%eax
f010148f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101492:	89 c7                	mov    %eax,%edi
f0101494:	c1 ff 1f             	sar    $0x1f,%edi
f0101497:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010149a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010149d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01014a0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01014a5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01014a9:	79 7d                	jns    f0101528 <vprintfmt+0x396>
				putch('-', putdat);
f01014ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014af:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01014b6:	ff d6                	call   *%esi
				num = -(long long) num;
f01014b8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014bb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01014be:	f7 d8                	neg    %eax
f01014c0:	83 d2 00             	adc    $0x0,%edx
f01014c3:	f7 da                	neg    %edx
			}
			base = 10;
f01014c5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01014ca:	eb 5c                	jmp    f0101528 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01014cc:	8d 45 14             	lea    0x14(%ebp),%eax
f01014cf:	e8 3f fc ff ff       	call   f0101113 <getuint>
			base = 10;
f01014d4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01014d9:	eb 4d                	jmp    f0101528 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			//My code here
			num = getuint(&ap, lflag);
f01014db:	8d 45 14             	lea    0x14(%ebp),%eax
f01014de:	e8 30 fc ff ff       	call   f0101113 <getuint>
			base = 8;
f01014e3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;			
f01014e8:	eb 3e                	jmp    f0101528 <vprintfmt+0x396>
		// pointer
		case 'p':
			putch('0', putdat);
f01014ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014ee:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01014f5:	ff d6                	call   *%esi
			putch('x', putdat);
f01014f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014fb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101502:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101504:	8b 45 14             	mov    0x14(%ebp),%eax
f0101507:	8d 50 04             	lea    0x4(%eax),%edx
f010150a:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010150d:	8b 00                	mov    (%eax),%eax
f010150f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101514:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101519:	eb 0d                	jmp    f0101528 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010151b:	8d 45 14             	lea    0x14(%ebp),%eax
f010151e:	e8 f0 fb ff ff       	call   f0101113 <getuint>
			base = 16;
f0101523:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101528:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010152c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101530:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101533:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101537:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010153b:	89 04 24             	mov    %eax,(%esp)
f010153e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101542:	89 da                	mov    %ebx,%edx
f0101544:	89 f0                	mov    %esi,%eax
f0101546:	e8 d5 fa ff ff       	call   f0101020 <printnum>
			break;
f010154b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010154e:	e9 64 fc ff ff       	jmp    f01011b7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101553:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101557:	89 0c 24             	mov    %ecx,(%esp)
f010155a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010155c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010155f:	e9 53 fc ff ff       	jmp    f01011b7 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101564:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101568:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010156f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101571:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101575:	0f 84 3c fc ff ff    	je     f01011b7 <vprintfmt+0x25>
f010157b:	83 ef 01             	sub    $0x1,%edi
f010157e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101582:	75 f7                	jne    f010157b <vprintfmt+0x3e9>
f0101584:	e9 2e fc ff ff       	jmp    f01011b7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101589:	83 c4 4c             	add    $0x4c,%esp
f010158c:	5b                   	pop    %ebx
f010158d:	5e                   	pop    %esi
f010158e:	5f                   	pop    %edi
f010158f:	5d                   	pop    %ebp
f0101590:	c3                   	ret    

f0101591 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101591:	55                   	push   %ebp
f0101592:	89 e5                	mov    %esp,%ebp
f0101594:	83 ec 28             	sub    $0x28,%esp
f0101597:	8b 45 08             	mov    0x8(%ebp),%eax
f010159a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010159d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01015a0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01015a4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01015a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01015ae:	85 d2                	test   %edx,%edx
f01015b0:	7e 30                	jle    f01015e2 <vsnprintf+0x51>
f01015b2:	85 c0                	test   %eax,%eax
f01015b4:	74 2c                	je     f01015e2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01015b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01015b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01015c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01015c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015cb:	c7 04 24 4d 11 10 f0 	movl   $0xf010114d,(%esp)
f01015d2:	e8 bb fb ff ff       	call   f0101192 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01015d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015da:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01015dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015e0:	eb 05                	jmp    f01015e7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01015e2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01015e7:	c9                   	leave  
f01015e8:	c3                   	ret    

f01015e9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01015e9:	55                   	push   %ebp
f01015ea:	89 e5                	mov    %esp,%ebp
f01015ec:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01015ef:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01015f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015f6:	8b 45 10             	mov    0x10(%ebp),%eax
f01015f9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101600:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101604:	8b 45 08             	mov    0x8(%ebp),%eax
f0101607:	89 04 24             	mov    %eax,(%esp)
f010160a:	e8 82 ff ff ff       	call   f0101591 <vsnprintf>
	va_end(ap);

	return rc;
}
f010160f:	c9                   	leave  
f0101610:	c3                   	ret    
f0101611:	66 90                	xchg   %ax,%ax
f0101613:	66 90                	xchg   %ax,%ax
f0101615:	66 90                	xchg   %ax,%ax
f0101617:	66 90                	xchg   %ax,%ax
f0101619:	66 90                	xchg   %ax,%ax
f010161b:	66 90                	xchg   %ax,%ax
f010161d:	66 90                	xchg   %ax,%ax
f010161f:	90                   	nop

f0101620 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101620:	55                   	push   %ebp
f0101621:	89 e5                	mov    %esp,%ebp
f0101623:	57                   	push   %edi
f0101624:	56                   	push   %esi
f0101625:	53                   	push   %ebx
f0101626:	83 ec 1c             	sub    $0x1c,%esp
f0101629:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010162c:	85 c0                	test   %eax,%eax
f010162e:	74 10                	je     f0101640 <readline+0x20>
		cprintf("%s", prompt);
f0101630:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101634:	c7 04 24 ca 24 10 f0 	movl   $0xf01024ca,(%esp)
f010163b:	e8 5e f6 ff ff       	call   f0100c9e <cprintf>

	i = 0;
	echoing = iscons(0);
f0101640:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101647:	e8 d6 ef ff ff       	call   f0100622 <iscons>
f010164c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010164e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101653:	e8 b9 ef ff ff       	call   f0100611 <getchar>
f0101658:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010165a:	85 c0                	test   %eax,%eax
f010165c:	79 17                	jns    f0101675 <readline+0x55>
			cprintf("read error: %e\n", c);
f010165e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101662:	c7 04 24 ac 26 10 f0 	movl   $0xf01026ac,(%esp)
f0101669:	e8 30 f6 ff ff       	call   f0100c9e <cprintf>
			return NULL;
f010166e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101673:	eb 6d                	jmp    f01016e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101675:	83 f8 7f             	cmp    $0x7f,%eax
f0101678:	74 05                	je     f010167f <readline+0x5f>
f010167a:	83 f8 08             	cmp    $0x8,%eax
f010167d:	75 19                	jne    f0101698 <readline+0x78>
f010167f:	85 f6                	test   %esi,%esi
f0101681:	7e 15                	jle    f0101698 <readline+0x78>
			if (echoing)
f0101683:	85 ff                	test   %edi,%edi
f0101685:	74 0c                	je     f0101693 <readline+0x73>
				cputchar('\b');
f0101687:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010168e:	e8 6e ef ff ff       	call   f0100601 <cputchar>
			i--;
f0101693:	83 ee 01             	sub    $0x1,%esi
f0101696:	eb bb                	jmp    f0101653 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101698:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010169e:	7f 1c                	jg     f01016bc <readline+0x9c>
f01016a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01016a3:	7e 17                	jle    f01016bc <readline+0x9c>
			if (echoing)
f01016a5:	85 ff                	test   %edi,%edi
f01016a7:	74 08                	je     f01016b1 <readline+0x91>
				cputchar(c);
f01016a9:	89 1c 24             	mov    %ebx,(%esp)
f01016ac:	e8 50 ef ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f01016b1:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f01016b7:	83 c6 01             	add    $0x1,%esi
f01016ba:	eb 97                	jmp    f0101653 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01016bc:	83 fb 0d             	cmp    $0xd,%ebx
f01016bf:	74 05                	je     f01016c6 <readline+0xa6>
f01016c1:	83 fb 0a             	cmp    $0xa,%ebx
f01016c4:	75 8d                	jne    f0101653 <readline+0x33>
			if (echoing)
f01016c6:	85 ff                	test   %edi,%edi
f01016c8:	74 0c                	je     f01016d6 <readline+0xb6>
				cputchar('\n');
f01016ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01016d1:	e8 2b ef ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f01016d6:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f01016dd:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f01016e2:	83 c4 1c             	add    $0x1c,%esp
f01016e5:	5b                   	pop    %ebx
f01016e6:	5e                   	pop    %esi
f01016e7:	5f                   	pop    %edi
f01016e8:	5d                   	pop    %ebp
f01016e9:	c3                   	ret    
f01016ea:	66 90                	xchg   %ax,%ax
f01016ec:	66 90                	xchg   %ax,%ax
f01016ee:	66 90                	xchg   %ax,%ax

f01016f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01016f0:	55                   	push   %ebp
f01016f1:	89 e5                	mov    %esp,%ebp
f01016f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01016f6:	80 3a 00             	cmpb   $0x0,(%edx)
f01016f9:	74 10                	je     f010170b <strlen+0x1b>
f01016fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101700:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101703:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101707:	75 f7                	jne    f0101700 <strlen+0x10>
f0101709:	eb 05                	jmp    f0101710 <strlen+0x20>
f010170b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    

f0101712 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101712:	55                   	push   %ebp
f0101713:	89 e5                	mov    %esp,%ebp
f0101715:	53                   	push   %ebx
f0101716:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101719:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010171c:	85 c9                	test   %ecx,%ecx
f010171e:	74 1c                	je     f010173c <strnlen+0x2a>
f0101720:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101723:	74 1e                	je     f0101743 <strnlen+0x31>
f0101725:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010172a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010172c:	39 ca                	cmp    %ecx,%edx
f010172e:	74 18                	je     f0101748 <strnlen+0x36>
f0101730:	83 c2 01             	add    $0x1,%edx
f0101733:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101738:	75 f0                	jne    f010172a <strnlen+0x18>
f010173a:	eb 0c                	jmp    f0101748 <strnlen+0x36>
f010173c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101741:	eb 05                	jmp    f0101748 <strnlen+0x36>
f0101743:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101748:	5b                   	pop    %ebx
f0101749:	5d                   	pop    %ebp
f010174a:	c3                   	ret    

f010174b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010174b:	55                   	push   %ebp
f010174c:	89 e5                	mov    %esp,%ebp
f010174e:	53                   	push   %ebx
f010174f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101752:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101755:	89 c2                	mov    %eax,%edx
f0101757:	0f b6 19             	movzbl (%ecx),%ebx
f010175a:	88 1a                	mov    %bl,(%edx)
f010175c:	83 c2 01             	add    $0x1,%edx
f010175f:	83 c1 01             	add    $0x1,%ecx
f0101762:	84 db                	test   %bl,%bl
f0101764:	75 f1                	jne    f0101757 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101766:	5b                   	pop    %ebx
f0101767:	5d                   	pop    %ebp
f0101768:	c3                   	ret    

f0101769 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101769:	55                   	push   %ebp
f010176a:	89 e5                	mov    %esp,%ebp
f010176c:	53                   	push   %ebx
f010176d:	83 ec 08             	sub    $0x8,%esp
f0101770:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101773:	89 1c 24             	mov    %ebx,(%esp)
f0101776:	e8 75 ff ff ff       	call   f01016f0 <strlen>
	strcpy(dst + len, src);
f010177b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010177e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101782:	01 d8                	add    %ebx,%eax
f0101784:	89 04 24             	mov    %eax,(%esp)
f0101787:	e8 bf ff ff ff       	call   f010174b <strcpy>
	return dst;
}
f010178c:	89 d8                	mov    %ebx,%eax
f010178e:	83 c4 08             	add    $0x8,%esp
f0101791:	5b                   	pop    %ebx
f0101792:	5d                   	pop    %ebp
f0101793:	c3                   	ret    

f0101794 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101794:	55                   	push   %ebp
f0101795:	89 e5                	mov    %esp,%ebp
f0101797:	56                   	push   %esi
f0101798:	53                   	push   %ebx
f0101799:	8b 75 08             	mov    0x8(%ebp),%esi
f010179c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010179f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01017a2:	85 db                	test   %ebx,%ebx
f01017a4:	74 16                	je     f01017bc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01017a6:	01 f3                	add    %esi,%ebx
f01017a8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01017aa:	0f b6 02             	movzbl (%edx),%eax
f01017ad:	88 01                	mov    %al,(%ecx)
f01017af:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01017b2:	80 3a 01             	cmpb   $0x1,(%edx)
f01017b5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01017b8:	39 d9                	cmp    %ebx,%ecx
f01017ba:	75 ee                	jne    f01017aa <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01017bc:	89 f0                	mov    %esi,%eax
f01017be:	5b                   	pop    %ebx
f01017bf:	5e                   	pop    %esi
f01017c0:	5d                   	pop    %ebp
f01017c1:	c3                   	ret    

f01017c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01017c2:	55                   	push   %ebp
f01017c3:	89 e5                	mov    %esp,%ebp
f01017c5:	57                   	push   %edi
f01017c6:	56                   	push   %esi
f01017c7:	53                   	push   %ebx
f01017c8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017ce:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01017d1:	89 f8                	mov    %edi,%eax
f01017d3:	85 f6                	test   %esi,%esi
f01017d5:	74 33                	je     f010180a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f01017d7:	83 fe 01             	cmp    $0x1,%esi
f01017da:	74 25                	je     f0101801 <strlcpy+0x3f>
f01017dc:	0f b6 0b             	movzbl (%ebx),%ecx
f01017df:	84 c9                	test   %cl,%cl
f01017e1:	74 22                	je     f0101805 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01017e3:	83 ee 02             	sub    $0x2,%esi
f01017e6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01017eb:	88 08                	mov    %cl,(%eax)
f01017ed:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01017f0:	39 f2                	cmp    %esi,%edx
f01017f2:	74 13                	je     f0101807 <strlcpy+0x45>
f01017f4:	83 c2 01             	add    $0x1,%edx
f01017f7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01017fb:	84 c9                	test   %cl,%cl
f01017fd:	75 ec                	jne    f01017eb <strlcpy+0x29>
f01017ff:	eb 06                	jmp    f0101807 <strlcpy+0x45>
f0101801:	89 f8                	mov    %edi,%eax
f0101803:	eb 02                	jmp    f0101807 <strlcpy+0x45>
f0101805:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101807:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010180a:	29 f8                	sub    %edi,%eax
}
f010180c:	5b                   	pop    %ebx
f010180d:	5e                   	pop    %esi
f010180e:	5f                   	pop    %edi
f010180f:	5d                   	pop    %ebp
f0101810:	c3                   	ret    

f0101811 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101811:	55                   	push   %ebp
f0101812:	89 e5                	mov    %esp,%ebp
f0101814:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101817:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010181a:	0f b6 01             	movzbl (%ecx),%eax
f010181d:	84 c0                	test   %al,%al
f010181f:	74 15                	je     f0101836 <strcmp+0x25>
f0101821:	3a 02                	cmp    (%edx),%al
f0101823:	75 11                	jne    f0101836 <strcmp+0x25>
		p++, q++;
f0101825:	83 c1 01             	add    $0x1,%ecx
f0101828:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010182b:	0f b6 01             	movzbl (%ecx),%eax
f010182e:	84 c0                	test   %al,%al
f0101830:	74 04                	je     f0101836 <strcmp+0x25>
f0101832:	3a 02                	cmp    (%edx),%al
f0101834:	74 ef                	je     f0101825 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101836:	0f b6 c0             	movzbl %al,%eax
f0101839:	0f b6 12             	movzbl (%edx),%edx
f010183c:	29 d0                	sub    %edx,%eax
}
f010183e:	5d                   	pop    %ebp
f010183f:	c3                   	ret    

f0101840 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101840:	55                   	push   %ebp
f0101841:	89 e5                	mov    %esp,%ebp
f0101843:	56                   	push   %esi
f0101844:	53                   	push   %ebx
f0101845:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101848:	8b 55 0c             	mov    0xc(%ebp),%edx
f010184b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f010184e:	85 f6                	test   %esi,%esi
f0101850:	74 29                	je     f010187b <strncmp+0x3b>
f0101852:	0f b6 03             	movzbl (%ebx),%eax
f0101855:	84 c0                	test   %al,%al
f0101857:	74 30                	je     f0101889 <strncmp+0x49>
f0101859:	3a 02                	cmp    (%edx),%al
f010185b:	75 2c                	jne    f0101889 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f010185d:	8d 43 01             	lea    0x1(%ebx),%eax
f0101860:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101862:	89 c3                	mov    %eax,%ebx
f0101864:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101867:	39 f0                	cmp    %esi,%eax
f0101869:	74 17                	je     f0101882 <strncmp+0x42>
f010186b:	0f b6 08             	movzbl (%eax),%ecx
f010186e:	84 c9                	test   %cl,%cl
f0101870:	74 17                	je     f0101889 <strncmp+0x49>
f0101872:	83 c0 01             	add    $0x1,%eax
f0101875:	3a 0a                	cmp    (%edx),%cl
f0101877:	74 e9                	je     f0101862 <strncmp+0x22>
f0101879:	eb 0e                	jmp    f0101889 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010187b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101880:	eb 0f                	jmp    f0101891 <strncmp+0x51>
f0101882:	b8 00 00 00 00       	mov    $0x0,%eax
f0101887:	eb 08                	jmp    f0101891 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101889:	0f b6 03             	movzbl (%ebx),%eax
f010188c:	0f b6 12             	movzbl (%edx),%edx
f010188f:	29 d0                	sub    %edx,%eax
}
f0101891:	5b                   	pop    %ebx
f0101892:	5e                   	pop    %esi
f0101893:	5d                   	pop    %ebp
f0101894:	c3                   	ret    

f0101895 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101895:	55                   	push   %ebp
f0101896:	89 e5                	mov    %esp,%ebp
f0101898:	53                   	push   %ebx
f0101899:	8b 45 08             	mov    0x8(%ebp),%eax
f010189c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010189f:	0f b6 18             	movzbl (%eax),%ebx
f01018a2:	84 db                	test   %bl,%bl
f01018a4:	74 1d                	je     f01018c3 <strchr+0x2e>
f01018a6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01018a8:	38 d3                	cmp    %dl,%bl
f01018aa:	75 06                	jne    f01018b2 <strchr+0x1d>
f01018ac:	eb 1a                	jmp    f01018c8 <strchr+0x33>
f01018ae:	38 ca                	cmp    %cl,%dl
f01018b0:	74 16                	je     f01018c8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01018b2:	83 c0 01             	add    $0x1,%eax
f01018b5:	0f b6 10             	movzbl (%eax),%edx
f01018b8:	84 d2                	test   %dl,%dl
f01018ba:	75 f2                	jne    f01018ae <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01018bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01018c1:	eb 05                	jmp    f01018c8 <strchr+0x33>
f01018c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018c8:	5b                   	pop    %ebx
f01018c9:	5d                   	pop    %ebp
f01018ca:	c3                   	ret    

f01018cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01018cb:	55                   	push   %ebp
f01018cc:	89 e5                	mov    %esp,%ebp
f01018ce:	53                   	push   %ebx
f01018cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01018d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01018d5:	0f b6 18             	movzbl (%eax),%ebx
f01018d8:	84 db                	test   %bl,%bl
f01018da:	74 16                	je     f01018f2 <strfind+0x27>
f01018dc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01018de:	38 d3                	cmp    %dl,%bl
f01018e0:	75 06                	jne    f01018e8 <strfind+0x1d>
f01018e2:	eb 0e                	jmp    f01018f2 <strfind+0x27>
f01018e4:	38 ca                	cmp    %cl,%dl
f01018e6:	74 0a                	je     f01018f2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01018e8:	83 c0 01             	add    $0x1,%eax
f01018eb:	0f b6 10             	movzbl (%eax),%edx
f01018ee:	84 d2                	test   %dl,%dl
f01018f0:	75 f2                	jne    f01018e4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01018f2:	5b                   	pop    %ebx
f01018f3:	5d                   	pop    %ebp
f01018f4:	c3                   	ret    

f01018f5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01018f5:	55                   	push   %ebp
f01018f6:	89 e5                	mov    %esp,%ebp
f01018f8:	83 ec 0c             	sub    $0xc,%esp
f01018fb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01018fe:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101901:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101904:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101907:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010190a:	85 c9                	test   %ecx,%ecx
f010190c:	74 36                	je     f0101944 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010190e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101914:	75 28                	jne    f010193e <memset+0x49>
f0101916:	f6 c1 03             	test   $0x3,%cl
f0101919:	75 23                	jne    f010193e <memset+0x49>
		c &= 0xFF;
f010191b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010191f:	89 d3                	mov    %edx,%ebx
f0101921:	c1 e3 08             	shl    $0x8,%ebx
f0101924:	89 d6                	mov    %edx,%esi
f0101926:	c1 e6 18             	shl    $0x18,%esi
f0101929:	89 d0                	mov    %edx,%eax
f010192b:	c1 e0 10             	shl    $0x10,%eax
f010192e:	09 f0                	or     %esi,%eax
f0101930:	09 c2                	or     %eax,%edx
f0101932:	89 d0                	mov    %edx,%eax
f0101934:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101936:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101939:	fc                   	cld    
f010193a:	f3 ab                	rep stos %eax,%es:(%edi)
f010193c:	eb 06                	jmp    f0101944 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010193e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101941:	fc                   	cld    
f0101942:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101944:	89 f8                	mov    %edi,%eax
f0101946:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101949:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010194c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010194f:	89 ec                	mov    %ebp,%esp
f0101951:	5d                   	pop    %ebp
f0101952:	c3                   	ret    

f0101953 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101953:	55                   	push   %ebp
f0101954:	89 e5                	mov    %esp,%ebp
f0101956:	83 ec 08             	sub    $0x8,%esp
f0101959:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010195c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010195f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101962:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101965:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101968:	39 c6                	cmp    %eax,%esi
f010196a:	73 36                	jae    f01019a2 <memmove+0x4f>
f010196c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010196f:	39 d0                	cmp    %edx,%eax
f0101971:	73 2f                	jae    f01019a2 <memmove+0x4f>
		s += n;
		d += n;
f0101973:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101976:	f6 c2 03             	test   $0x3,%dl
f0101979:	75 1b                	jne    f0101996 <memmove+0x43>
f010197b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101981:	75 13                	jne    f0101996 <memmove+0x43>
f0101983:	f6 c1 03             	test   $0x3,%cl
f0101986:	75 0e                	jne    f0101996 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101988:	83 ef 04             	sub    $0x4,%edi
f010198b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010198e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101991:	fd                   	std    
f0101992:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101994:	eb 09                	jmp    f010199f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101996:	83 ef 01             	sub    $0x1,%edi
f0101999:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010199c:	fd                   	std    
f010199d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010199f:	fc                   	cld    
f01019a0:	eb 20                	jmp    f01019c2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01019a2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01019a8:	75 13                	jne    f01019bd <memmove+0x6a>
f01019aa:	a8 03                	test   $0x3,%al
f01019ac:	75 0f                	jne    f01019bd <memmove+0x6a>
f01019ae:	f6 c1 03             	test   $0x3,%cl
f01019b1:	75 0a                	jne    f01019bd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01019b3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01019b6:	89 c7                	mov    %eax,%edi
f01019b8:	fc                   	cld    
f01019b9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01019bb:	eb 05                	jmp    f01019c2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01019bd:	89 c7                	mov    %eax,%edi
f01019bf:	fc                   	cld    
f01019c0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01019c2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01019c5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01019c8:	89 ec                	mov    %ebp,%esp
f01019ca:	5d                   	pop    %ebp
f01019cb:	c3                   	ret    

f01019cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01019cc:	55                   	push   %ebp
f01019cd:	89 e5                	mov    %esp,%ebp
f01019cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01019d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01019d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01019e3:	89 04 24             	mov    %eax,(%esp)
f01019e6:	e8 68 ff ff ff       	call   f0101953 <memmove>
}
f01019eb:	c9                   	leave  
f01019ec:	c3                   	ret    

f01019ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01019ed:	55                   	push   %ebp
f01019ee:	89 e5                	mov    %esp,%ebp
f01019f0:	57                   	push   %edi
f01019f1:	56                   	push   %esi
f01019f2:	53                   	push   %ebx
f01019f3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01019f6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019f9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01019fc:	8d 78 ff             	lea    -0x1(%eax),%edi
f01019ff:	85 c0                	test   %eax,%eax
f0101a01:	74 36                	je     f0101a39 <memcmp+0x4c>
		if (*s1 != *s2)
f0101a03:	0f b6 03             	movzbl (%ebx),%eax
f0101a06:	0f b6 0e             	movzbl (%esi),%ecx
f0101a09:	38 c8                	cmp    %cl,%al
f0101a0b:	75 17                	jne    f0101a24 <memcmp+0x37>
f0101a0d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a12:	eb 1a                	jmp    f0101a2e <memcmp+0x41>
f0101a14:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101a19:	83 c2 01             	add    $0x1,%edx
f0101a1c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101a20:	38 c8                	cmp    %cl,%al
f0101a22:	74 0a                	je     f0101a2e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101a24:	0f b6 c0             	movzbl %al,%eax
f0101a27:	0f b6 c9             	movzbl %cl,%ecx
f0101a2a:	29 c8                	sub    %ecx,%eax
f0101a2c:	eb 10                	jmp    f0101a3e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a2e:	39 fa                	cmp    %edi,%edx
f0101a30:	75 e2                	jne    f0101a14 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101a32:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a37:	eb 05                	jmp    f0101a3e <memcmp+0x51>
f0101a39:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101a3e:	5b                   	pop    %ebx
f0101a3f:	5e                   	pop    %esi
f0101a40:	5f                   	pop    %edi
f0101a41:	5d                   	pop    %ebp
f0101a42:	c3                   	ret    

f0101a43 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101a43:	55                   	push   %ebp
f0101a44:	89 e5                	mov    %esp,%ebp
f0101a46:	53                   	push   %ebx
f0101a47:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0101a4d:	89 c2                	mov    %eax,%edx
f0101a4f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101a52:	39 d0                	cmp    %edx,%eax
f0101a54:	73 13                	jae    f0101a69 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101a56:	89 d9                	mov    %ebx,%ecx
f0101a58:	38 18                	cmp    %bl,(%eax)
f0101a5a:	75 06                	jne    f0101a62 <memfind+0x1f>
f0101a5c:	eb 0b                	jmp    f0101a69 <memfind+0x26>
f0101a5e:	38 08                	cmp    %cl,(%eax)
f0101a60:	74 07                	je     f0101a69 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101a62:	83 c0 01             	add    $0x1,%eax
f0101a65:	39 d0                	cmp    %edx,%eax
f0101a67:	75 f5                	jne    f0101a5e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101a69:	5b                   	pop    %ebx
f0101a6a:	5d                   	pop    %ebp
f0101a6b:	c3                   	ret    

f0101a6c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101a6c:	55                   	push   %ebp
f0101a6d:	89 e5                	mov    %esp,%ebp
f0101a6f:	57                   	push   %edi
f0101a70:	56                   	push   %esi
f0101a71:	53                   	push   %ebx
f0101a72:	83 ec 04             	sub    $0x4,%esp
f0101a75:	8b 55 08             	mov    0x8(%ebp),%edx
f0101a78:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101a7b:	0f b6 02             	movzbl (%edx),%eax
f0101a7e:	3c 09                	cmp    $0x9,%al
f0101a80:	74 04                	je     f0101a86 <strtol+0x1a>
f0101a82:	3c 20                	cmp    $0x20,%al
f0101a84:	75 0e                	jne    f0101a94 <strtol+0x28>
		s++;
f0101a86:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101a89:	0f b6 02             	movzbl (%edx),%eax
f0101a8c:	3c 09                	cmp    $0x9,%al
f0101a8e:	74 f6                	je     f0101a86 <strtol+0x1a>
f0101a90:	3c 20                	cmp    $0x20,%al
f0101a92:	74 f2                	je     f0101a86 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101a94:	3c 2b                	cmp    $0x2b,%al
f0101a96:	75 0a                	jne    f0101aa2 <strtol+0x36>
		s++;
f0101a98:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101a9b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101aa0:	eb 10                	jmp    f0101ab2 <strtol+0x46>
f0101aa2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101aa7:	3c 2d                	cmp    $0x2d,%al
f0101aa9:	75 07                	jne    f0101ab2 <strtol+0x46>
		s++, neg = 1;
f0101aab:	83 c2 01             	add    $0x1,%edx
f0101aae:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101ab2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101ab8:	75 15                	jne    f0101acf <strtol+0x63>
f0101aba:	80 3a 30             	cmpb   $0x30,(%edx)
f0101abd:	75 10                	jne    f0101acf <strtol+0x63>
f0101abf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101ac3:	75 0a                	jne    f0101acf <strtol+0x63>
		s += 2, base = 16;
f0101ac5:	83 c2 02             	add    $0x2,%edx
f0101ac8:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101acd:	eb 10                	jmp    f0101adf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0101acf:	85 db                	test   %ebx,%ebx
f0101ad1:	75 0c                	jne    f0101adf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101ad3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101ad5:	80 3a 30             	cmpb   $0x30,(%edx)
f0101ad8:	75 05                	jne    f0101adf <strtol+0x73>
		s++, base = 8;
f0101ada:	83 c2 01             	add    $0x1,%edx
f0101add:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101adf:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ae4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101ae7:	0f b6 0a             	movzbl (%edx),%ecx
f0101aea:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101aed:	89 f3                	mov    %esi,%ebx
f0101aef:	80 fb 09             	cmp    $0x9,%bl
f0101af2:	77 08                	ja     f0101afc <strtol+0x90>
			dig = *s - '0';
f0101af4:	0f be c9             	movsbl %cl,%ecx
f0101af7:	83 e9 30             	sub    $0x30,%ecx
f0101afa:	eb 22                	jmp    f0101b1e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0101afc:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101aff:	89 f3                	mov    %esi,%ebx
f0101b01:	80 fb 19             	cmp    $0x19,%bl
f0101b04:	77 08                	ja     f0101b0e <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101b06:	0f be c9             	movsbl %cl,%ecx
f0101b09:	83 e9 57             	sub    $0x57,%ecx
f0101b0c:	eb 10                	jmp    f0101b1e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0101b0e:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101b11:	89 f3                	mov    %esi,%ebx
f0101b13:	80 fb 19             	cmp    $0x19,%bl
f0101b16:	77 16                	ja     f0101b2e <strtol+0xc2>
			dig = *s - 'A' + 10;
f0101b18:	0f be c9             	movsbl %cl,%ecx
f0101b1b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101b1e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0101b21:	7d 0f                	jge    f0101b32 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101b23:	83 c2 01             	add    $0x1,%edx
f0101b26:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101b2a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101b2c:	eb b9                	jmp    f0101ae7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101b2e:	89 c1                	mov    %eax,%ecx
f0101b30:	eb 02                	jmp    f0101b34 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101b32:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101b34:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101b38:	74 05                	je     f0101b3f <strtol+0xd3>
		*endptr = (char *) s;
f0101b3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b3d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101b3f:	89 ca                	mov    %ecx,%edx
f0101b41:	f7 da                	neg    %edx
f0101b43:	85 ff                	test   %edi,%edi
f0101b45:	0f 45 c2             	cmovne %edx,%eax
}
f0101b48:	83 c4 04             	add    $0x4,%esp
f0101b4b:	5b                   	pop    %ebx
f0101b4c:	5e                   	pop    %esi
f0101b4d:	5f                   	pop    %edi
f0101b4e:	5d                   	pop    %ebp
f0101b4f:	c3                   	ret    

f0101b50 <__udivdi3>:
f0101b50:	83 ec 1c             	sub    $0x1c,%esp
f0101b53:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101b57:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101b5b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101b5f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101b63:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101b67:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0101b6b:	85 c0                	test   %eax,%eax
f0101b6d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101b71:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101b75:	89 ea                	mov    %ebp,%edx
f0101b77:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b7b:	75 33                	jne    f0101bb0 <__udivdi3+0x60>
f0101b7d:	39 e9                	cmp    %ebp,%ecx
f0101b7f:	77 6f                	ja     f0101bf0 <__udivdi3+0xa0>
f0101b81:	85 c9                	test   %ecx,%ecx
f0101b83:	89 ce                	mov    %ecx,%esi
f0101b85:	75 0b                	jne    f0101b92 <__udivdi3+0x42>
f0101b87:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b8c:	31 d2                	xor    %edx,%edx
f0101b8e:	f7 f1                	div    %ecx
f0101b90:	89 c6                	mov    %eax,%esi
f0101b92:	31 d2                	xor    %edx,%edx
f0101b94:	89 e8                	mov    %ebp,%eax
f0101b96:	f7 f6                	div    %esi
f0101b98:	89 c5                	mov    %eax,%ebp
f0101b9a:	89 f8                	mov    %edi,%eax
f0101b9c:	f7 f6                	div    %esi
f0101b9e:	89 ea                	mov    %ebp,%edx
f0101ba0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ba4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ba8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101bac:	83 c4 1c             	add    $0x1c,%esp
f0101baf:	c3                   	ret    
f0101bb0:	39 e8                	cmp    %ebp,%eax
f0101bb2:	77 24                	ja     f0101bd8 <__udivdi3+0x88>
f0101bb4:	0f bd c8             	bsr    %eax,%ecx
f0101bb7:	83 f1 1f             	xor    $0x1f,%ecx
f0101bba:	89 0c 24             	mov    %ecx,(%esp)
f0101bbd:	75 49                	jne    f0101c08 <__udivdi3+0xb8>
f0101bbf:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101bc3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0101bc7:	0f 86 ab 00 00 00    	jbe    f0101c78 <__udivdi3+0x128>
f0101bcd:	39 e8                	cmp    %ebp,%eax
f0101bcf:	0f 82 a3 00 00 00    	jb     f0101c78 <__udivdi3+0x128>
f0101bd5:	8d 76 00             	lea    0x0(%esi),%esi
f0101bd8:	31 d2                	xor    %edx,%edx
f0101bda:	31 c0                	xor    %eax,%eax
f0101bdc:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101be0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101be4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101be8:	83 c4 1c             	add    $0x1c,%esp
f0101beb:	c3                   	ret    
f0101bec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101bf0:	89 f8                	mov    %edi,%eax
f0101bf2:	f7 f1                	div    %ecx
f0101bf4:	31 d2                	xor    %edx,%edx
f0101bf6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101bfa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bfe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c02:	83 c4 1c             	add    $0x1c,%esp
f0101c05:	c3                   	ret    
f0101c06:	66 90                	xchg   %ax,%ax
f0101c08:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101c0c:	89 c6                	mov    %eax,%esi
f0101c0e:	b8 20 00 00 00       	mov    $0x20,%eax
f0101c13:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101c17:	2b 04 24             	sub    (%esp),%eax
f0101c1a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101c1e:	d3 e6                	shl    %cl,%esi
f0101c20:	89 c1                	mov    %eax,%ecx
f0101c22:	d3 ed                	shr    %cl,%ebp
f0101c24:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101c28:	09 f5                	or     %esi,%ebp
f0101c2a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101c2e:	d3 e6                	shl    %cl,%esi
f0101c30:	89 c1                	mov    %eax,%ecx
f0101c32:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c36:	89 d6                	mov    %edx,%esi
f0101c38:	d3 ee                	shr    %cl,%esi
f0101c3a:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101c3e:	d3 e2                	shl    %cl,%edx
f0101c40:	89 c1                	mov    %eax,%ecx
f0101c42:	d3 ef                	shr    %cl,%edi
f0101c44:	09 d7                	or     %edx,%edi
f0101c46:	89 f2                	mov    %esi,%edx
f0101c48:	89 f8                	mov    %edi,%eax
f0101c4a:	f7 f5                	div    %ebp
f0101c4c:	89 d6                	mov    %edx,%esi
f0101c4e:	89 c7                	mov    %eax,%edi
f0101c50:	f7 64 24 04          	mull   0x4(%esp)
f0101c54:	39 d6                	cmp    %edx,%esi
f0101c56:	72 30                	jb     f0101c88 <__udivdi3+0x138>
f0101c58:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101c5c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101c60:	d3 e5                	shl    %cl,%ebp
f0101c62:	39 c5                	cmp    %eax,%ebp
f0101c64:	73 04                	jae    f0101c6a <__udivdi3+0x11a>
f0101c66:	39 d6                	cmp    %edx,%esi
f0101c68:	74 1e                	je     f0101c88 <__udivdi3+0x138>
f0101c6a:	89 f8                	mov    %edi,%eax
f0101c6c:	31 d2                	xor    %edx,%edx
f0101c6e:	e9 69 ff ff ff       	jmp    f0101bdc <__udivdi3+0x8c>
f0101c73:	90                   	nop
f0101c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c78:	31 d2                	xor    %edx,%edx
f0101c7a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c7f:	e9 58 ff ff ff       	jmp    f0101bdc <__udivdi3+0x8c>
f0101c84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c88:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101c8b:	31 d2                	xor    %edx,%edx
f0101c8d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c91:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c95:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c99:	83 c4 1c             	add    $0x1c,%esp
f0101c9c:	c3                   	ret    
f0101c9d:	66 90                	xchg   %ax,%ax
f0101c9f:	90                   	nop

f0101ca0 <__umoddi3>:
f0101ca0:	83 ec 2c             	sub    $0x2c,%esp
f0101ca3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101ca7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101cab:	89 74 24 20          	mov    %esi,0x20(%esp)
f0101caf:	8b 74 24 38          	mov    0x38(%esp),%esi
f0101cb3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0101cb7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	89 c2                	mov    %eax,%edx
f0101cbf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0101cc3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101cc7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ccb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101ccf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101cd3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101cd7:	75 1f                	jne    f0101cf8 <__umoddi3+0x58>
f0101cd9:	39 fe                	cmp    %edi,%esi
f0101cdb:	76 63                	jbe    f0101d40 <__umoddi3+0xa0>
f0101cdd:	89 c8                	mov    %ecx,%eax
f0101cdf:	89 fa                	mov    %edi,%edx
f0101ce1:	f7 f6                	div    %esi
f0101ce3:	89 d0                	mov    %edx,%eax
f0101ce5:	31 d2                	xor    %edx,%edx
f0101ce7:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101ceb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101cef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101cf3:	83 c4 2c             	add    $0x2c,%esp
f0101cf6:	c3                   	ret    
f0101cf7:	90                   	nop
f0101cf8:	39 f8                	cmp    %edi,%eax
f0101cfa:	77 64                	ja     f0101d60 <__umoddi3+0xc0>
f0101cfc:	0f bd e8             	bsr    %eax,%ebp
f0101cff:	83 f5 1f             	xor    $0x1f,%ebp
f0101d02:	75 74                	jne    f0101d78 <__umoddi3+0xd8>
f0101d04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d08:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0101d0c:	0f 87 0e 01 00 00    	ja     f0101e20 <__umoddi3+0x180>
f0101d12:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101d16:	29 f1                	sub    %esi,%ecx
f0101d18:	19 c7                	sbb    %eax,%edi
f0101d1a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101d1e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101d22:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101d26:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101d2a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101d2e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101d32:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101d36:	83 c4 2c             	add    $0x2c,%esp
f0101d39:	c3                   	ret    
f0101d3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101d40:	85 f6                	test   %esi,%esi
f0101d42:	89 f5                	mov    %esi,%ebp
f0101d44:	75 0b                	jne    f0101d51 <__umoddi3+0xb1>
f0101d46:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d4b:	31 d2                	xor    %edx,%edx
f0101d4d:	f7 f6                	div    %esi
f0101d4f:	89 c5                	mov    %eax,%ebp
f0101d51:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101d55:	31 d2                	xor    %edx,%edx
f0101d57:	f7 f5                	div    %ebp
f0101d59:	89 c8                	mov    %ecx,%eax
f0101d5b:	f7 f5                	div    %ebp
f0101d5d:	eb 84                	jmp    f0101ce3 <__umoddi3+0x43>
f0101d5f:	90                   	nop
f0101d60:	89 c8                	mov    %ecx,%eax
f0101d62:	89 fa                	mov    %edi,%edx
f0101d64:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101d68:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101d6c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101d70:	83 c4 2c             	add    $0x2c,%esp
f0101d73:	c3                   	ret    
f0101d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d78:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101d7c:	be 20 00 00 00       	mov    $0x20,%esi
f0101d81:	89 e9                	mov    %ebp,%ecx
f0101d83:	29 ee                	sub    %ebp,%esi
f0101d85:	d3 e2                	shl    %cl,%edx
f0101d87:	89 f1                	mov    %esi,%ecx
f0101d89:	d3 e8                	shr    %cl,%eax
f0101d8b:	89 e9                	mov    %ebp,%ecx
f0101d8d:	09 d0                	or     %edx,%eax
f0101d8f:	89 fa                	mov    %edi,%edx
f0101d91:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d95:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101d99:	d3 e0                	shl    %cl,%eax
f0101d9b:	89 f1                	mov    %esi,%ecx
f0101d9d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101da1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101da5:	d3 ea                	shr    %cl,%edx
f0101da7:	89 e9                	mov    %ebp,%ecx
f0101da9:	d3 e7                	shl    %cl,%edi
f0101dab:	89 f1                	mov    %esi,%ecx
f0101dad:	d3 e8                	shr    %cl,%eax
f0101daf:	89 e9                	mov    %ebp,%ecx
f0101db1:	09 f8                	or     %edi,%eax
f0101db3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101db7:	f7 74 24 0c          	divl   0xc(%esp)
f0101dbb:	d3 e7                	shl    %cl,%edi
f0101dbd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101dc1:	89 d7                	mov    %edx,%edi
f0101dc3:	f7 64 24 10          	mull   0x10(%esp)
f0101dc7:	39 d7                	cmp    %edx,%edi
f0101dc9:	89 c1                	mov    %eax,%ecx
f0101dcb:	89 54 24 14          	mov    %edx,0x14(%esp)
f0101dcf:	72 3b                	jb     f0101e0c <__umoddi3+0x16c>
f0101dd1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0101dd5:	72 31                	jb     f0101e08 <__umoddi3+0x168>
f0101dd7:	8b 44 24 18          	mov    0x18(%esp),%eax
f0101ddb:	29 c8                	sub    %ecx,%eax
f0101ddd:	19 d7                	sbb    %edx,%edi
f0101ddf:	89 e9                	mov    %ebp,%ecx
f0101de1:	89 fa                	mov    %edi,%edx
f0101de3:	d3 e8                	shr    %cl,%eax
f0101de5:	89 f1                	mov    %esi,%ecx
f0101de7:	d3 e2                	shl    %cl,%edx
f0101de9:	89 e9                	mov    %ebp,%ecx
f0101deb:	09 d0                	or     %edx,%eax
f0101ded:	89 fa                	mov    %edi,%edx
f0101def:	d3 ea                	shr    %cl,%edx
f0101df1:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101df5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101df9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101dfd:	83 c4 2c             	add    $0x2c,%esp
f0101e00:	c3                   	ret    
f0101e01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e08:	39 d7                	cmp    %edx,%edi
f0101e0a:	75 cb                	jne    f0101dd7 <__umoddi3+0x137>
f0101e0c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101e10:	89 c1                	mov    %eax,%ecx
f0101e12:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101e16:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101e1a:	eb bb                	jmp    f0101dd7 <__umoddi3+0x137>
f0101e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e20:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101e24:	0f 82 e8 fe ff ff    	jb     f0101d12 <__umoddi3+0x72>
f0101e2a:	e9 f3 fe ff ff       	jmp    f0101d22 <__umoddi3+0x82>
