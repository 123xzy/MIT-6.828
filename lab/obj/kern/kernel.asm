
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
f010000b:	e4                   	.byte 0xe4

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
f010004e:	c7 04 24 c0 19 10 f0 	movl   $0xf01019c0,(%esp)
f0100055:	e8 be 09 00 00       	call   f0100a18 <cprintf>
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
f0100082:	e8 24 07 00 00       	call   f01007ab <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 19 10 f0 	movl   $0xf01019dc,(%esp)
f0100092:	e8 81 09 00 00       	call   f0100a18 <cprintf>
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
f01000c0:	e8 52 14 00 00       	call   f0101517 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 19 10 f0 	movl   $0xf01019f7,(%esp)
f01000d9:	e8 3a 09 00 00       	call   f0100a18 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 a9 07 00 00       	call   f010089f <monitor>
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
f0100125:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f010012c:	e8 e7 08 00 00       	call   f0100a18 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 a8 08 00 00       	call   f01009e5 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100144:	e8 cf 08 00 00       	call   f0100a18 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 4a 07 00 00       	call   f010089f <monitor>
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
f010016f:	c7 04 24 2a 1a 10 f0 	movl   $0xf0101a2a,(%esp)
f0100176:	e8 9d 08 00 00       	call   f0100a18 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 5b 08 00 00       	call   f01009e5 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100191:	e8 82 08 00 00       	call   f0100a18 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100223:	c3                   	ret    
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a a0 1a 10 f0 	movzbl -0xfefe560(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300
	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f01002e9:	e8 2a 07 00 00       	call   f0100a18 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 d6 10 00 00       	call   f0101564 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 50 1a 10 f0 	movl   $0xf0101a50,(%esp)
f0100644:	e8 cf 03 00 00       	call   f0100a18 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 a0 1c 10 	movl   $0xf0101ca0,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f010069d:	e8 76 03 00 00       	call   f0100a18 <cprintf>
f01006a2:	c7 44 24 08 7c 1d 10 	movl   $0xf0101d7c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 cc 1c 10 	movl   $0xf0101ccc,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006b9:	e8 5a 03 00 00       	call   f0100a18 <cprintf>
f01006be:	c7 44 24 08 a4 1d 10 	movl   $0xf0101da4,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 d5 1c 10 	movl   $0xf0101cd5,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006d5:	e8 3e 03 00 00       	call   f0100a18 <cprintf>
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 e0 1c 10 f0 	movl   $0xf0101ce0,(%esp)
f01006ee:	e8 25 03 00 00       	call   f0100a18 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fa:	00 
f01006fb:	c7 04 24 cc 1d 10 f0 	movl   $0xf0101dcc,(%esp)
f0100702:	e8 11 03 00 00       	call   f0100a18 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 f4 1d 10 f0 	movl   $0xf0101df4,(%esp)
f010071e:	e8 f5 02 00 00       	call   f0100a18 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 a7 19 10 	movl   $0x1019a7,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 a7 19 10 	movl   $0xf01019a7,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 18 1e 10 f0 	movl   $0xf0101e18,(%esp)
f010073a:	e8 d9 02 00 00       	call   f0100a18 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 3c 1e 10 f0 	movl   $0xf0101e3c,(%esp)
f0100756:	e8 bd 02 00 00       	call   f0100a18 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f0100772:	e8 a1 02 00 00       	call   f0100a18 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100777:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100781:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100786:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010078c:	85 c0                	test   %eax,%eax
f010078e:	0f 48 c2             	cmovs  %edx,%eax
f0100791:	c1 f8 0a             	sar    $0xa,%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f010079f:	e8 74 02 00 00       	call   f0100a18 <cprintf>
	return 0;
}
f01007a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	57                   	push   %edi
f01007af:	56                   	push   %esi
f01007b0:	53                   	push   %ebx
f01007b1:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007b4:	89 e8                	mov    %ebp,%eax
f01007b6:	89 c6                	mov    %eax,%esi
	// Your code here.
	int j;
    	uint32_t ebp = read_ebp();
    	uint32_t eip = *((uint32_t *)ebp+1);
f01007b8:	8b 40 04             	mov    0x4(%eax),%eax
f01007bb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 
	struct Eipdebuginfo info;
	
	cprintf("Stack backtrace:\n");
f01007be:	c7 04 24 f9 1c 10 f0 	movl   $0xf0101cf9,(%esp)
f01007c5:	e8 4e 02 00 00       	call   f0100a18 <cprintf>
    	while ((int)ebp != 0)
f01007ca:	e9 bb 00 00 00       	jmp    f010088a <mon_backtrace+0xdf>
    	{
        	cprintf("  ebp 0x%08x eip 0x%08x args ", ebp, eip);
f01007cf:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007da:	c7 04 24 0b 1d 10 f0 	movl   $0xf0101d0b,(%esp)
f01007e1:	e8 32 02 00 00       	call   f0100a18 <cprintf>
f01007e6:	8d 7e 1c             	lea    0x1c(%esi),%edi
        	uint32_t *args = (uint32_t *)ebp + 2;
f01007e9:	8d 5e 08             	lea    0x8(%esi),%ebx
        	for (j = 0; j < 5; j ++) {
            		cprintf("%08x ", args[j]);
f01007ec:	8b 03                	mov    (%ebx),%eax
f01007ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f2:	c7 04 24 29 1d 10 f0 	movl   $0xf0101d29,(%esp)
f01007f9:	e8 1a 02 00 00       	call   f0100a18 <cprintf>
f01007fe:	83 c3 04             	add    $0x4,%ebx
        	for (j = 0; j < 5; j ++) {
f0100801:	39 fb                	cmp    %edi,%ebx
f0100803:	75 e7                	jne    f01007ec <mon_backtrace+0x41>
        	}
        	cprintf("\n");
f0100805:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f010080c:	e8 07 02 00 00       	call   f0100a18 <cprintf>

		memset(&info,0,sizeof(struct Eipdebuginfo));
f0100811:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
f0100818:	00 
f0100819:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100820:	00 
f0100821:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100824:	89 04 24             	mov    %eax,(%esp)
f0100827:	e8 eb 0c 00 00       	call   f0101517 <memset>

		if(!debuginfo_eip(eip,&info))
f010082c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010082f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100833:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100836:	89 04 24             	mov    %eax,(%esp)
f0100839:	e8 d1 02 00 00       	call   f0100b0f <debuginfo_eip>
f010083e:	85 c0                	test   %eax,%eax
f0100840:	75 2d                	jne    f010086f <mon_backtrace+0xc4>
			cprintf("\t%s:%d:%s+%u\n",info.eip_file,info.eip_line,info.eip_fn_name,eip-info.eip_fn_addr);
f0100842:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100845:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100848:	89 44 24 10          	mov    %eax,0x10(%esp)
f010084c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010084f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100853:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100856:	89 44 24 08          	mov    %eax,0x8(%esp)
f010085a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010085d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100861:	c7 04 24 2f 1d 10 f0 	movl   $0xf0101d2f,(%esp)
f0100868:	e8 ab 01 00 00       	call   f0100a18 <cprintf>
f010086d:	eb 13                	jmp    f0100882 <mon_backtrace+0xd7>
		else
			cprintf("failed to get debufinfo for eip %x\n",eip);
f010086f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100872:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100876:	c7 04 24 b0 1e 10 f0 	movl   $0xf0101eb0,(%esp)
f010087d:	e8 96 01 00 00       	call   f0100a18 <cprintf>

        	eip = ((uint32_t *)ebp)[1];
f0100882:	8b 46 04             	mov    0x4(%esi),%eax
f0100885:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        	ebp = ((uint32_t *)ebp)[0];
f0100888:	8b 36                	mov    (%esi),%esi
    	while ((int)ebp != 0)
f010088a:	85 f6                	test   %esi,%esi
f010088c:	0f 85 3d ff ff ff    	jne    f01007cf <mon_backtrace+0x24>
    	}
	return 0;
}
f0100892:	b8 00 00 00 00       	mov    $0x0,%eax
f0100897:	83 c4 4c             	add    $0x4c,%esp
f010089a:	5b                   	pop    %ebx
f010089b:	5e                   	pop    %esi
f010089c:	5f                   	pop    %edi
f010089d:	5d                   	pop    %ebp
f010089e:	c3                   	ret    

f010089f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010089f:	55                   	push   %ebp
f01008a0:	89 e5                	mov    %esp,%ebp
f01008a2:	57                   	push   %edi
f01008a3:	56                   	push   %esi
f01008a4:	53                   	push   %ebx
f01008a5:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008a8:	c7 04 24 d4 1e 10 f0 	movl   $0xf0101ed4,(%esp)
f01008af:	e8 64 01 00 00       	call   f0100a18 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008b4:	c7 04 24 f8 1e 10 f0 	movl   $0xf0101ef8,(%esp)
f01008bb:	e8 58 01 00 00       	call   f0100a18 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008c0:	c7 04 24 3d 1d 10 f0 	movl   $0xf0101d3d,(%esp)
f01008c7:	e8 f4 09 00 00       	call   f01012c0 <readline>
f01008cc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	74 ee                	je     f01008c0 <monitor+0x21>
	argv[argc] = 0;
f01008d2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008d9:	be 00 00 00 00       	mov    $0x0,%esi
f01008de:	eb 0a                	jmp    f01008ea <monitor+0x4b>
			*buf++ = 0;
f01008e0:	c6 03 00             	movb   $0x0,(%ebx)
f01008e3:	89 f7                	mov    %esi,%edi
f01008e5:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008e8:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01008ea:	0f b6 03             	movzbl (%ebx),%eax
f01008ed:	84 c0                	test   %al,%al
f01008ef:	74 63                	je     f0100954 <monitor+0xb5>
f01008f1:	0f be c0             	movsbl %al,%eax
f01008f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f8:	c7 04 24 41 1d 10 f0 	movl   $0xf0101d41,(%esp)
f01008ff:	e8 d6 0b 00 00       	call   f01014da <strchr>
f0100904:	85 c0                	test   %eax,%eax
f0100906:	75 d8                	jne    f01008e0 <monitor+0x41>
		if (*buf == 0)
f0100908:	80 3b 00             	cmpb   $0x0,(%ebx)
f010090b:	74 47                	je     f0100954 <monitor+0xb5>
		if (argc == MAXARGS-1) {
f010090d:	83 fe 0f             	cmp    $0xf,%esi
f0100910:	75 16                	jne    f0100928 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100912:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100919:	00 
f010091a:	c7 04 24 46 1d 10 f0 	movl   $0xf0101d46,(%esp)
f0100921:	e8 f2 00 00 00       	call   f0100a18 <cprintf>
f0100926:	eb 98                	jmp    f01008c0 <monitor+0x21>
		argv[argc++] = buf;
f0100928:	8d 7e 01             	lea    0x1(%esi),%edi
f010092b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010092f:	eb 03                	jmp    f0100934 <monitor+0x95>
			buf++;
f0100931:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100934:	0f b6 03             	movzbl (%ebx),%eax
f0100937:	84 c0                	test   %al,%al
f0100939:	74 ad                	je     f01008e8 <monitor+0x49>
f010093b:	0f be c0             	movsbl %al,%eax
f010093e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100942:	c7 04 24 41 1d 10 f0 	movl   $0xf0101d41,(%esp)
f0100949:	e8 8c 0b 00 00       	call   f01014da <strchr>
f010094e:	85 c0                	test   %eax,%eax
f0100950:	74 df                	je     f0100931 <monitor+0x92>
f0100952:	eb 94                	jmp    f01008e8 <monitor+0x49>
	argv[argc] = 0;
f0100954:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010095b:	00 
	if (argc == 0)
f010095c:	85 f6                	test   %esi,%esi
f010095e:	0f 84 5c ff ff ff    	je     f01008c0 <monitor+0x21>
f0100964:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100969:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f010096c:	8b 04 85 20 1f 10 f0 	mov    -0xfefe0e0(,%eax,4),%eax
f0100973:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100977:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097a:	89 04 24             	mov    %eax,(%esp)
f010097d:	e8 fa 0a 00 00       	call   f010147c <strcmp>
f0100982:	85 c0                	test   %eax,%eax
f0100984:	75 24                	jne    f01009aa <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100986:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100989:	8b 55 08             	mov    0x8(%ebp),%edx
f010098c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100990:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100993:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100997:	89 34 24             	mov    %esi,(%esp)
f010099a:	ff 14 85 28 1f 10 f0 	call   *-0xfefe0d8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009a1:	85 c0                	test   %eax,%eax
f01009a3:	78 25                	js     f01009ca <monitor+0x12b>
f01009a5:	e9 16 ff ff ff       	jmp    f01008c0 <monitor+0x21>
	for (i = 0; i < NCOMMANDS; i++) {
f01009aa:	83 c3 01             	add    $0x1,%ebx
f01009ad:	83 fb 03             	cmp    $0x3,%ebx
f01009b0:	75 b7                	jne    f0100969 <monitor+0xca>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009b2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b9:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01009c0:	e8 53 00 00 00       	call   f0100a18 <cprintf>
f01009c5:	e9 f6 fe ff ff       	jmp    f01008c0 <monitor+0x21>
				break;
	}
}
f01009ca:	83 c4 5c             	add    $0x5c,%esp
f01009cd:	5b                   	pop    %ebx
f01009ce:	5e                   	pop    %esi
f01009cf:	5f                   	pop    %edi
f01009d0:	5d                   	pop    %ebp
f01009d1:	c3                   	ret    

f01009d2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009d2:	55                   	push   %ebp
f01009d3:	89 e5                	mov    %esp,%ebp
f01009d5:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01009db:	89 04 24             	mov    %eax,(%esp)
f01009de:	e8 6e fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01009e3:	c9                   	leave  
f01009e4:	c3                   	ret    

f01009e5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009e5:	55                   	push   %ebp
f01009e6:	89 e5                	mov    %esp,%ebp
f01009e8:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009eb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01009fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a00:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a07:	c7 04 24 d2 09 10 f0 	movl   $0xf01009d2,(%esp)
f0100a0e:	e8 4b 04 00 00       	call   f0100e5e <vprintfmt>
	return cnt;
}
f0100a13:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a16:	c9                   	leave  
f0100a17:	c3                   	ret    

f0100a18 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
f0100a1b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a1e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a25:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a28:	89 04 24             	mov    %eax,(%esp)
f0100a2b:	e8 b5 ff ff ff       	call   f01009e5 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a30:	c9                   	leave  
f0100a31:	c3                   	ret    

f0100a32 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a32:	55                   	push   %ebp
f0100a33:	89 e5                	mov    %esp,%ebp
f0100a35:	57                   	push   %edi
f0100a36:	56                   	push   %esi
f0100a37:	53                   	push   %ebx
f0100a38:	83 ec 10             	sub    $0x10,%esp
f0100a3b:	89 c6                	mov    %eax,%esi
f0100a3d:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a40:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a43:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a46:	8b 1a                	mov    (%edx),%ebx
f0100a48:	8b 01                	mov    (%ecx),%eax
f0100a4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a4d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a54:	eb 77                	jmp    f0100acd <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a56:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a59:	01 d8                	add    %ebx,%eax
f0100a5b:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a60:	99                   	cltd   
f0100a61:	f7 f9                	idiv   %ecx
f0100a63:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a65:	eb 01                	jmp    f0100a68 <stab_binsearch+0x36>
			m--;
f0100a67:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0100a68:	39 d9                	cmp    %ebx,%ecx
f0100a6a:	7c 1d                	jl     f0100a89 <stab_binsearch+0x57>
f0100a6c:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a6f:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a74:	39 fa                	cmp    %edi,%edx
f0100a76:	75 ef                	jne    f0100a67 <stab_binsearch+0x35>
f0100a78:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a7b:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a7e:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a82:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a85:	73 18                	jae    f0100a9f <stab_binsearch+0x6d>
f0100a87:	eb 05                	jmp    f0100a8e <stab_binsearch+0x5c>
			l = true_m + 1;
f0100a89:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a8c:	eb 3f                	jmp    f0100acd <stab_binsearch+0x9b>
			*region_left = m;
f0100a8e:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a91:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a93:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0100a96:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a9d:	eb 2e                	jmp    f0100acd <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0100a9f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100aa2:	73 15                	jae    f0100ab9 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100aa4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100aa7:	48                   	dec    %eax
f0100aa8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aae:	89 01                	mov    %eax,(%ecx)
		any_matches = 1;
f0100ab0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ab7:	eb 14                	jmp    f0100acd <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ab9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100abc:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100abf:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100ac1:	ff 45 0c             	incl   0xc(%ebp)
f0100ac4:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0100ac6:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0100acd:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ad0:	7e 84                	jle    f0100a56 <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0100ad2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ad6:	75 0d                	jne    f0100ae5 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ad8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100adb:	8b 00                	mov    (%eax),%eax
f0100add:	48                   	dec    %eax
f0100ade:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ae1:	89 07                	mov    %eax,(%edi)
f0100ae3:	eb 22                	jmp    f0100b07 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae8:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aea:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aed:	8b 0b                	mov    (%ebx),%ecx
		for (l = *region_right;
f0100aef:	eb 01                	jmp    f0100af2 <stab_binsearch+0xc0>
		     l--)
f0100af1:	48                   	dec    %eax
		for (l = *region_right;
f0100af2:	39 c1                	cmp    %eax,%ecx
f0100af4:	7d 0c                	jge    f0100b02 <stab_binsearch+0xd0>
f0100af6:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100af9:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100afe:	39 fa                	cmp    %edi,%edx
f0100b00:	75 ef                	jne    f0100af1 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0100b02:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100b05:	89 07                	mov    %eax,(%edi)
	}
}
f0100b07:	83 c4 10             	add    $0x10,%esp
f0100b0a:	5b                   	pop    %ebx
f0100b0b:	5e                   	pop    %esi
f0100b0c:	5f                   	pop    %edi
f0100b0d:	5d                   	pop    %ebp
f0100b0e:	c3                   	ret    

f0100b0f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b0f:	55                   	push   %ebp
f0100b10:	89 e5                	mov    %esp,%ebp
f0100b12:	57                   	push   %edi
f0100b13:	56                   	push   %esi
f0100b14:	53                   	push   %ebx
f0100b15:	83 ec 2c             	sub    $0x2c,%esp
f0100b18:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b1b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b1e:	c7 03 44 1f 10 f0    	movl   $0xf0101f44,(%ebx)
	info->eip_line = 0;
f0100b24:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b2b:	c7 43 08 44 1f 10 f0 	movl   $0xf0101f44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b32:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b39:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b3c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b43:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b49:	76 12                	jbe    f0100b5d <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b4b:	b8 b2 73 10 f0       	mov    $0xf01073b2,%eax
f0100b50:	3d b5 5a 10 f0       	cmp    $0xf0105ab5,%eax
f0100b55:	0f 86 6b 01 00 00    	jbe    f0100cc6 <debuginfo_eip+0x1b7>
f0100b5b:	eb 1c                	jmp    f0100b79 <debuginfo_eip+0x6a>
  	        panic("User address");
f0100b5d:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100b64:	f0 
f0100b65:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b6c:	00 
f0100b6d:	c7 04 24 5b 1f 10 f0 	movl   $0xf0101f5b,(%esp)
f0100b74:	e8 7f f5 ff ff       	call   f01000f8 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b79:	80 3d b1 73 10 f0 00 	cmpb   $0x0,0xf01073b1
f0100b80:	0f 85 47 01 00 00    	jne    f0100ccd <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b86:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b8d:	b8 b4 5a 10 f0       	mov    $0xf0105ab4,%eax
f0100b92:	2d 90 21 10 f0       	sub    $0xf0102190,%eax
f0100b97:	c1 f8 02             	sar    $0x2,%eax
f0100b9a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ba0:	83 e8 01             	sub    $0x1,%eax
f0100ba3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ba6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100baa:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bb1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bb4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bb7:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100bbc:	e8 71 fe ff ff       	call   f0100a32 <stab_binsearch>
	if (lfile == 0)
f0100bc1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bc4:	85 c0                	test   %eax,%eax
f0100bc6:	0f 84 08 01 00 00    	je     f0100cd4 <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bcc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bd5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bd9:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100be0:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100be3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100be6:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100beb:	e8 42 fe ff ff       	call   f0100a32 <stab_binsearch>

	if (lfun <= rfun) {
f0100bf0:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100bf3:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100bf6:	7f 2e                	jg     f0100c26 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bf8:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bfb:	8d 90 90 21 10 f0    	lea    -0xfefde70(%eax),%edx
f0100c01:	8b 80 90 21 10 f0    	mov    -0xfefde70(%eax),%eax
f0100c07:	b9 b2 73 10 f0       	mov    $0xf01073b2,%ecx
f0100c0c:	81 e9 b5 5a 10 f0    	sub    $0xf0105ab5,%ecx
f0100c12:	39 c8                	cmp    %ecx,%eax
f0100c14:	73 08                	jae    f0100c1e <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c16:	05 b5 5a 10 f0       	add    $0xf0105ab5,%eax
f0100c1b:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c1e:	8b 42 08             	mov    0x8(%edx),%eax
f0100c21:	89 43 10             	mov    %eax,0x10(%ebx)
f0100c24:	eb 06                	jmp    f0100c2c <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c26:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c2c:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c33:	00 
f0100c34:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c37:	89 04 24             	mov    %eax,(%esp)
f0100c3a:	e8 bc 08 00 00       	call   f01014fb <strfind>
f0100c3f:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c42:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c45:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c48:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c4b:	05 90 21 10 f0       	add    $0xf0102190,%eax
f0100c50:	eb 06                	jmp    f0100c58 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c52:	83 ef 01             	sub    $0x1,%edi
f0100c55:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100c58:	39 cf                	cmp    %ecx,%edi
f0100c5a:	7c 33                	jl     f0100c8f <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100c5c:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c60:	80 fa 84             	cmp    $0x84,%dl
f0100c63:	74 0b                	je     f0100c70 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c65:	80 fa 64             	cmp    $0x64,%dl
f0100c68:	75 e8                	jne    f0100c52 <debuginfo_eip+0x143>
f0100c6a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c6e:	74 e2                	je     f0100c52 <debuginfo_eip+0x143>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c70:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c73:	8b 87 90 21 10 f0    	mov    -0xfefde70(%edi),%eax
f0100c79:	ba b2 73 10 f0       	mov    $0xf01073b2,%edx
f0100c7e:	81 ea b5 5a 10 f0    	sub    $0xf0105ab5,%edx
f0100c84:	39 d0                	cmp    %edx,%eax
f0100c86:	73 07                	jae    f0100c8f <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c88:	05 b5 5a 10 f0       	add    $0xf0105ab5,%eax
f0100c8d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c8f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c92:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c95:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100c9a:	39 f1                	cmp    %esi,%ecx
f0100c9c:	7d 42                	jge    f0100ce0 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100c9e:	8d 51 01             	lea    0x1(%ecx),%edx
f0100ca1:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100ca4:	05 90 21 10 f0       	add    $0xf0102190,%eax
f0100ca9:	eb 07                	jmp    f0100cb2 <debuginfo_eip+0x1a3>
			info->eip_fn_narg++;
f0100cab:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		     lline++)
f0100caf:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100cb2:	39 f2                	cmp    %esi,%edx
f0100cb4:	74 25                	je     f0100cdb <debuginfo_eip+0x1cc>
f0100cb6:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cb9:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100cbd:	74 ec                	je     f0100cab <debuginfo_eip+0x19c>
	return 0;
f0100cbf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc4:	eb 1a                	jmp    f0100ce0 <debuginfo_eip+0x1d1>
		return -1;
f0100cc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ccb:	eb 13                	jmp    f0100ce0 <debuginfo_eip+0x1d1>
f0100ccd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd2:	eb 0c                	jmp    f0100ce0 <debuginfo_eip+0x1d1>
		return -1;
f0100cd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd9:	eb 05                	jmp    f0100ce0 <debuginfo_eip+0x1d1>
	return 0;
f0100cdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ce0:	83 c4 2c             	add    $0x2c,%esp
f0100ce3:	5b                   	pop    %ebx
f0100ce4:	5e                   	pop    %esi
f0100ce5:	5f                   	pop    %edi
f0100ce6:	5d                   	pop    %ebp
f0100ce7:	c3                   	ret    
f0100ce8:	66 90                	xchg   %ax,%ax
f0100cea:	66 90                	xchg   %ax,%ax
f0100cec:	66 90                	xchg   %ax,%ax
f0100cee:	66 90                	xchg   %ax,%ax

f0100cf0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	57                   	push   %edi
f0100cf4:	56                   	push   %esi
f0100cf5:	53                   	push   %ebx
f0100cf6:	83 ec 3c             	sub    $0x3c,%esp
f0100cf9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cfc:	89 d7                	mov    %edx,%edi
f0100cfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d07:	89 c3                	mov    %eax,%ebx
f0100d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d0f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d12:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d17:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d1d:	39 d9                	cmp    %ebx,%ecx
f0100d1f:	72 05                	jb     f0100d26 <printnum+0x36>
f0100d21:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d24:	77 69                	ja     f0100d8f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d26:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d29:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d2d:	83 ee 01             	sub    $0x1,%esi
f0100d30:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d38:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d3c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d40:	89 c3                	mov    %eax,%ebx
f0100d42:	89 d6                	mov    %edx,%esi
f0100d44:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d47:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d4a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d4e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d52:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d55:	89 04 24             	mov    %eax,(%esp)
f0100d58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d5f:	e8 bc 09 00 00       	call   f0101720 <__udivdi3>
f0100d64:	89 d9                	mov    %ebx,%ecx
f0100d66:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d6a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d6e:	89 04 24             	mov    %eax,(%esp)
f0100d71:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d75:	89 fa                	mov    %edi,%edx
f0100d77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d7a:	e8 71 ff ff ff       	call   f0100cf0 <printnum>
f0100d7f:	eb 1b                	jmp    f0100d9c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d81:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d85:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d88:	89 04 24             	mov    %eax,(%esp)
f0100d8b:	ff d3                	call   *%ebx
f0100d8d:	eb 03                	jmp    f0100d92 <printnum+0xa2>
f0100d8f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f0100d92:	83 ee 01             	sub    $0x1,%esi
f0100d95:	85 f6                	test   %esi,%esi
f0100d97:	7f e8                	jg     f0100d81 <printnum+0x91>
f0100d99:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100da4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100da7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100daa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbf:	e8 8c 0a 00 00       	call   f0101850 <__umoddi3>
f0100dc4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc8:	0f be 80 69 1f 10 f0 	movsbl -0xfefe097(%eax),%eax
f0100dcf:	89 04 24             	mov    %eax,(%esp)
f0100dd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dd5:	ff d0                	call   *%eax
}
f0100dd7:	83 c4 3c             	add    $0x3c,%esp
f0100dda:	5b                   	pop    %ebx
f0100ddb:	5e                   	pop    %esi
f0100ddc:	5f                   	pop    %edi
f0100ddd:	5d                   	pop    %ebp
f0100dde:	c3                   	ret    

f0100ddf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ddf:	55                   	push   %ebp
f0100de0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100de2:	83 fa 01             	cmp    $0x1,%edx
f0100de5:	7e 0e                	jle    f0100df5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100de7:	8b 10                	mov    (%eax),%edx
f0100de9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dec:	89 08                	mov    %ecx,(%eax)
f0100dee:	8b 02                	mov    (%edx),%eax
f0100df0:	8b 52 04             	mov    0x4(%edx),%edx
f0100df3:	eb 22                	jmp    f0100e17 <getuint+0x38>
	else if (lflag)
f0100df5:	85 d2                	test   %edx,%edx
f0100df7:	74 10                	je     f0100e09 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100df9:	8b 10                	mov    (%eax),%edx
f0100dfb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dfe:	89 08                	mov    %ecx,(%eax)
f0100e00:	8b 02                	mov    (%edx),%eax
f0100e02:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e07:	eb 0e                	jmp    f0100e17 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e09:	8b 10                	mov    (%eax),%edx
f0100e0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e0e:	89 08                	mov    %ecx,(%eax)
f0100e10:	8b 02                	mov    (%edx),%eax
f0100e12:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e17:	5d                   	pop    %ebp
f0100e18:	c3                   	ret    

f0100e19 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e19:	55                   	push   %ebp
f0100e1a:	89 e5                	mov    %esp,%ebp
f0100e1c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e1f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e23:	8b 10                	mov    (%eax),%edx
f0100e25:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e28:	73 0a                	jae    f0100e34 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e2a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e2d:	89 08                	mov    %ecx,(%eax)
f0100e2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e32:	88 02                	mov    %al,(%edx)
}
f0100e34:	5d                   	pop    %ebp
f0100e35:	c3                   	ret    

f0100e36 <printfmt>:
{
f0100e36:	55                   	push   %ebp
f0100e37:	89 e5                	mov    %esp,%ebp
f0100e39:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0100e3c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e43:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e46:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e51:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e54:	89 04 24             	mov    %eax,(%esp)
f0100e57:	e8 02 00 00 00       	call   f0100e5e <vprintfmt>
}
f0100e5c:	c9                   	leave  
f0100e5d:	c3                   	ret    

f0100e5e <vprintfmt>:
{
f0100e5e:	55                   	push   %ebp
f0100e5f:	89 e5                	mov    %esp,%ebp
f0100e61:	57                   	push   %edi
f0100e62:	56                   	push   %esi
f0100e63:	53                   	push   %ebx
f0100e64:	83 ec 3c             	sub    $0x3c,%esp
f0100e67:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e6a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e6d:	eb 14                	jmp    f0100e83 <vprintfmt+0x25>
			if (ch == '\0')
f0100e6f:	85 c0                	test   %eax,%eax
f0100e71:	0f 84 b8 03 00 00    	je     f010122f <vprintfmt+0x3d1>
			putch(ch, putdat);
f0100e77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7b:	89 04 24             	mov    %eax,(%esp)
f0100e7e:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e81:	89 f3                	mov    %esi,%ebx
f0100e83:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e86:	0f b6 03             	movzbl (%ebx),%eax
f0100e89:	83 f8 25             	cmp    $0x25,%eax
f0100e8c:	75 e1                	jne    f0100e6f <vprintfmt+0x11>
f0100e8e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e92:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100e99:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ea0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ea7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eac:	eb 1d                	jmp    f0100ecb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0100eae:	89 de                	mov    %ebx,%esi
			padc = '-';
f0100eb0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100eb4:	eb 15                	jmp    f0100ecb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0100eb6:	89 de                	mov    %ebx,%esi
			padc = '0';
f0100eb8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100ebc:	eb 0d                	jmp    f0100ecb <vprintfmt+0x6d>
				width = precision, precision = -1;
f0100ebe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ec1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ec4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ecb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ece:	0f b6 0e             	movzbl (%esi),%ecx
f0100ed1:	0f b6 c1             	movzbl %cl,%eax
f0100ed4:	83 e9 23             	sub    $0x23,%ecx
f0100ed7:	80 f9 55             	cmp    $0x55,%cl
f0100eda:	0f 87 2f 03 00 00    	ja     f010120f <vprintfmt+0x3b1>
f0100ee0:	0f b6 c9             	movzbl %cl,%ecx
f0100ee3:	ff 24 8d 00 20 10 f0 	jmp    *-0xfefe000(,%ecx,4)
f0100eea:	89 de                	mov    %ebx,%esi
f0100eec:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f0100ef1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100ef4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100ef8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100efb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100efe:	83 fb 09             	cmp    $0x9,%ebx
f0100f01:	77 36                	ja     f0100f39 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0100f03:	83 c6 01             	add    $0x1,%esi
			}
f0100f06:	eb e9                	jmp    f0100ef1 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0100f08:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f0e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f11:	8b 00                	mov    (%eax),%eax
f0100f13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f16:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0100f18:	eb 22                	jmp    f0100f3c <vprintfmt+0xde>
f0100f1a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f1d:	85 c9                	test   %ecx,%ecx
f0100f1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f24:	0f 49 c1             	cmovns %ecx,%eax
f0100f27:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f2a:	89 de                	mov    %ebx,%esi
f0100f2c:	eb 9d                	jmp    f0100ecb <vprintfmt+0x6d>
f0100f2e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0100f30:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f37:	eb 92                	jmp    f0100ecb <vprintfmt+0x6d>
f0100f39:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f0100f3c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f40:	79 89                	jns    f0100ecb <vprintfmt+0x6d>
f0100f42:	e9 77 ff ff ff       	jmp    f0100ebe <vprintfmt+0x60>
			lflag++;
f0100f47:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f0100f4a:	89 de                	mov    %ebx,%esi
			goto reswitch;
f0100f4c:	e9 7a ff ff ff       	jmp    f0100ecb <vprintfmt+0x6d>
			putch(va_arg(ap, int) + 0x1200, putdat);
f0100f51:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f54:	8d 50 04             	lea    0x4(%eax),%edx
f0100f57:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f5e:	8b 00                	mov    (%eax),%eax
f0100f60:	05 00 12 00 00       	add    $0x1200,%eax
f0100f65:	89 04 24             	mov    %eax,(%esp)
f0100f68:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f6b:	e9 13 ff ff ff       	jmp    f0100e83 <vprintfmt+0x25>
			err = va_arg(ap, int);
f0100f70:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f73:	8d 50 04             	lea    0x4(%eax),%edx
f0100f76:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f79:	8b 00                	mov    (%eax),%eax
f0100f7b:	99                   	cltd   
f0100f7c:	31 d0                	xor    %edx,%eax
f0100f7e:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f80:	83 f8 07             	cmp    $0x7,%eax
f0100f83:	7f 0b                	jg     f0100f90 <vprintfmt+0x132>
f0100f85:	8b 14 85 60 21 10 f0 	mov    -0xfefdea0(,%eax,4),%edx
f0100f8c:	85 d2                	test   %edx,%edx
f0100f8e:	75 20                	jne    f0100fb0 <vprintfmt+0x152>
				printfmt(putch, putdat, "error %d", err);
f0100f90:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f94:	c7 44 24 08 81 1f 10 	movl   $0xf0101f81,0x8(%esp)
f0100f9b:	f0 
f0100f9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fa3:	89 04 24             	mov    %eax,(%esp)
f0100fa6:	e8 8b fe ff ff       	call   f0100e36 <printfmt>
f0100fab:	e9 d3 fe ff ff       	jmp    f0100e83 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0100fb0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fb4:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100fbb:	f0 
f0100fbc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fc3:	89 04 24             	mov    %eax,(%esp)
f0100fc6:	e8 6b fe ff ff       	call   f0100e36 <printfmt>
f0100fcb:	e9 b3 fe ff ff       	jmp    f0100e83 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f0100fd0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fd3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fd6:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0100fd9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdc:	8d 50 04             	lea    0x4(%eax),%edx
f0100fdf:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe2:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100fe4:	85 f6                	test   %esi,%esi
f0100fe6:	b8 7a 1f 10 f0       	mov    $0xf0101f7a,%eax
f0100feb:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100fee:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100ff2:	0f 84 97 00 00 00    	je     f010108f <vprintfmt+0x231>
f0100ff8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100ffc:	0f 8e 9b 00 00 00    	jle    f010109d <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101002:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101006:	89 34 24             	mov    %esi,(%esp)
f0101009:	e8 9a 03 00 00       	call   f01013a8 <strnlen>
f010100e:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101011:	29 c2                	sub    %eax,%edx
f0101013:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101016:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010101a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010101d:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101020:	8b 75 08             	mov    0x8(%ebp),%esi
f0101023:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101026:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0101028:	eb 0f                	jmp    f0101039 <vprintfmt+0x1db>
					putch(padc, putdat);
f010102a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010102e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101031:	89 04 24             	mov    %eax,(%esp)
f0101034:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101036:	83 eb 01             	sub    $0x1,%ebx
f0101039:	85 db                	test   %ebx,%ebx
f010103b:	7f ed                	jg     f010102a <vprintfmt+0x1cc>
f010103d:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0101040:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101043:	85 d2                	test   %edx,%edx
f0101045:	b8 00 00 00 00       	mov    $0x0,%eax
f010104a:	0f 49 c2             	cmovns %edx,%eax
f010104d:	29 c2                	sub    %eax,%edx
f010104f:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101052:	89 d7                	mov    %edx,%edi
f0101054:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101057:	eb 50                	jmp    f01010a9 <vprintfmt+0x24b>
				if (altflag && (ch < ' ' || ch > '~'))
f0101059:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010105d:	74 1e                	je     f010107d <vprintfmt+0x21f>
f010105f:	0f be d2             	movsbl %dl,%edx
f0101062:	83 ea 20             	sub    $0x20,%edx
f0101065:	83 fa 5e             	cmp    $0x5e,%edx
f0101068:	76 13                	jbe    f010107d <vprintfmt+0x21f>
					putch('?', putdat);
f010106a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010106d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101071:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101078:	ff 55 08             	call   *0x8(%ebp)
f010107b:	eb 0d                	jmp    f010108a <vprintfmt+0x22c>
					putch(ch, putdat);
f010107d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101080:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101084:	89 04 24             	mov    %eax,(%esp)
f0101087:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010108a:	83 ef 01             	sub    $0x1,%edi
f010108d:	eb 1a                	jmp    f01010a9 <vprintfmt+0x24b>
f010108f:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101092:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101095:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101098:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010109b:	eb 0c                	jmp    f01010a9 <vprintfmt+0x24b>
f010109d:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010a0:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010a3:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010a6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010a9:	83 c6 01             	add    $0x1,%esi
f01010ac:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010b0:	0f be c2             	movsbl %dl,%eax
f01010b3:	85 c0                	test   %eax,%eax
f01010b5:	74 27                	je     f01010de <vprintfmt+0x280>
f01010b7:	85 db                	test   %ebx,%ebx
f01010b9:	78 9e                	js     f0101059 <vprintfmt+0x1fb>
f01010bb:	83 eb 01             	sub    $0x1,%ebx
f01010be:	79 99                	jns    f0101059 <vprintfmt+0x1fb>
f01010c0:	89 f8                	mov    %edi,%eax
f01010c2:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010c5:	8b 75 08             	mov    0x8(%ebp),%esi
f01010c8:	89 c3                	mov    %eax,%ebx
f01010ca:	eb 1a                	jmp    f01010e6 <vprintfmt+0x288>
				putch(' ', putdat);
f01010cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010d7:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01010d9:	83 eb 01             	sub    $0x1,%ebx
f01010dc:	eb 08                	jmp    f01010e6 <vprintfmt+0x288>
f01010de:	89 fb                	mov    %edi,%ebx
f01010e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010e6:	85 db                	test   %ebx,%ebx
f01010e8:	7f e2                	jg     f01010cc <vprintfmt+0x26e>
f01010ea:	89 75 08             	mov    %esi,0x8(%ebp)
f01010ed:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010f0:	e9 8e fd ff ff       	jmp    f0100e83 <vprintfmt+0x25>
	if (lflag >= 2)
f01010f5:	83 fa 01             	cmp    $0x1,%edx
f01010f8:	7e 16                	jle    f0101110 <vprintfmt+0x2b2>
		return va_arg(*ap, long long);
f01010fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fd:	8d 50 08             	lea    0x8(%eax),%edx
f0101100:	89 55 14             	mov    %edx,0x14(%ebp)
f0101103:	8b 50 04             	mov    0x4(%eax),%edx
f0101106:	8b 00                	mov    (%eax),%eax
f0101108:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010110b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010110e:	eb 32                	jmp    f0101142 <vprintfmt+0x2e4>
	else if (lflag)
f0101110:	85 d2                	test   %edx,%edx
f0101112:	74 18                	je     f010112c <vprintfmt+0x2ce>
		return va_arg(*ap, long);
f0101114:	8b 45 14             	mov    0x14(%ebp),%eax
f0101117:	8d 50 04             	lea    0x4(%eax),%edx
f010111a:	89 55 14             	mov    %edx,0x14(%ebp)
f010111d:	8b 30                	mov    (%eax),%esi
f010111f:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101122:	89 f0                	mov    %esi,%eax
f0101124:	c1 f8 1f             	sar    $0x1f,%eax
f0101127:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010112a:	eb 16                	jmp    f0101142 <vprintfmt+0x2e4>
		return va_arg(*ap, int);
f010112c:	8b 45 14             	mov    0x14(%ebp),%eax
f010112f:	8d 50 04             	lea    0x4(%eax),%edx
f0101132:	89 55 14             	mov    %edx,0x14(%ebp)
f0101135:	8b 30                	mov    (%eax),%esi
f0101137:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010113a:	89 f0                	mov    %esi,%eax
f010113c:	c1 f8 1f             	sar    $0x1f,%eax
f010113f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f0101142:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101145:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0101148:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f010114d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101151:	0f 89 80 00 00 00    	jns    f01011d7 <vprintfmt+0x379>
				putch('-', putdat);
f0101157:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010115b:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101162:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101165:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101168:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010116b:	f7 d8                	neg    %eax
f010116d:	83 d2 00             	adc    $0x0,%edx
f0101170:	f7 da                	neg    %edx
			base = 10;
f0101172:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101177:	eb 5e                	jmp    f01011d7 <vprintfmt+0x379>
			num = getuint(&ap, lflag);
f0101179:	8d 45 14             	lea    0x14(%ebp),%eax
f010117c:	e8 5e fc ff ff       	call   f0100ddf <getuint>
			base = 10;
f0101181:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101186:	eb 4f                	jmp    f01011d7 <vprintfmt+0x379>
			num = getuint(&ap,lflag);
f0101188:	8d 45 14             	lea    0x14(%ebp),%eax
f010118b:	e8 4f fc ff ff       	call   f0100ddf <getuint>
			base = 8;
f0101190:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101195:	eb 40                	jmp    f01011d7 <vprintfmt+0x379>
			putch('0', putdat);
f0101197:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010119b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011a2:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a9:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011b0:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f01011b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b6:	8d 50 04             	lea    0x4(%eax),%edx
f01011b9:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01011bc:	8b 00                	mov    (%eax),%eax
f01011be:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01011c3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011c8:	eb 0d                	jmp    f01011d7 <vprintfmt+0x379>
			num = getuint(&ap, lflag);
f01011ca:	8d 45 14             	lea    0x14(%ebp),%eax
f01011cd:	e8 0d fc ff ff       	call   f0100ddf <getuint>
			base = 16;
f01011d2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01011d7:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01011db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011df:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01011e2:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011ea:	89 04 24             	mov    %eax,(%esp)
f01011ed:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011f1:	89 fa                	mov    %edi,%edx
f01011f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f6:	e8 f5 fa ff ff       	call   f0100cf0 <printnum>
			break;
f01011fb:	e9 83 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>
			putch(ch, putdat);
f0101200:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101204:	89 04 24             	mov    %eax,(%esp)
f0101207:	ff 55 08             	call   *0x8(%ebp)
			break;
f010120a:	e9 74 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>
			putch('%', putdat);
f010120f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101213:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010121a:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010121d:	89 f3                	mov    %esi,%ebx
f010121f:	eb 03                	jmp    f0101224 <vprintfmt+0x3c6>
f0101221:	83 eb 01             	sub    $0x1,%ebx
f0101224:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101228:	75 f7                	jne    f0101221 <vprintfmt+0x3c3>
f010122a:	e9 54 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>
}
f010122f:	83 c4 3c             	add    $0x3c,%esp
f0101232:	5b                   	pop    %ebx
f0101233:	5e                   	pop    %esi
f0101234:	5f                   	pop    %edi
f0101235:	5d                   	pop    %ebp
f0101236:	c3                   	ret    

f0101237 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101237:	55                   	push   %ebp
f0101238:	89 e5                	mov    %esp,%ebp
f010123a:	83 ec 28             	sub    $0x28,%esp
f010123d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101240:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101243:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101246:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010124a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010124d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101254:	85 c0                	test   %eax,%eax
f0101256:	74 30                	je     f0101288 <vsnprintf+0x51>
f0101258:	85 d2                	test   %edx,%edx
f010125a:	7e 2c                	jle    f0101288 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010125c:	8b 45 14             	mov    0x14(%ebp),%eax
f010125f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101263:	8b 45 10             	mov    0x10(%ebp),%eax
f0101266:	89 44 24 08          	mov    %eax,0x8(%esp)
f010126a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010126d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101271:	c7 04 24 19 0e 10 f0 	movl   $0xf0100e19,(%esp)
f0101278:	e8 e1 fb ff ff       	call   f0100e5e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010127d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101280:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101283:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101286:	eb 05                	jmp    f010128d <vsnprintf+0x56>
		return -E_INVAL;
f0101288:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f010128d:	c9                   	leave  
f010128e:	c3                   	ret    

f010128f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010128f:	55                   	push   %ebp
f0101290:	89 e5                	mov    %esp,%ebp
f0101292:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101295:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101298:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010129c:	8b 45 10             	mov    0x10(%ebp),%eax
f010129f:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012a3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ad:	89 04 24             	mov    %eax,(%esp)
f01012b0:	e8 82 ff ff ff       	call   f0101237 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012b5:	c9                   	leave  
f01012b6:	c3                   	ret    
f01012b7:	66 90                	xchg   %ax,%ax
f01012b9:	66 90                	xchg   %ax,%ax
f01012bb:	66 90                	xchg   %ax,%ax
f01012bd:	66 90                	xchg   %ax,%ax
f01012bf:	90                   	nop

f01012c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	57                   	push   %edi
f01012c4:	56                   	push   %esi
f01012c5:	53                   	push   %ebx
f01012c6:	83 ec 1c             	sub    $0x1c,%esp
f01012c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012cc:	85 c0                	test   %eax,%eax
f01012ce:	74 10                	je     f01012e0 <readline+0x20>
		cprintf("%s", prompt);
f01012d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d4:	c7 04 24 8a 1f 10 f0 	movl   $0xf0101f8a,(%esp)
f01012db:	e8 38 f7 ff ff       	call   f0100a18 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012e7:	e8 86 f3 ff ff       	call   f0100672 <iscons>
f01012ec:	89 c7                	mov    %eax,%edi
	i = 0;
f01012ee:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01012f3:	e8 69 f3 ff ff       	call   f0100661 <getchar>
f01012f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012fa:	85 c0                	test   %eax,%eax
f01012fc:	79 17                	jns    f0101315 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101302:	c7 04 24 80 21 10 f0 	movl   $0xf0102180,(%esp)
f0101309:	e8 0a f7 ff ff       	call   f0100a18 <cprintf>
			return NULL;
f010130e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101313:	eb 6d                	jmp    f0101382 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101315:	83 f8 7f             	cmp    $0x7f,%eax
f0101318:	74 05                	je     f010131f <readline+0x5f>
f010131a:	83 f8 08             	cmp    $0x8,%eax
f010131d:	75 19                	jne    f0101338 <readline+0x78>
f010131f:	85 f6                	test   %esi,%esi
f0101321:	7e 15                	jle    f0101338 <readline+0x78>
			if (echoing)
f0101323:	85 ff                	test   %edi,%edi
f0101325:	74 0c                	je     f0101333 <readline+0x73>
				cputchar('\b');
f0101327:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010132e:	e8 1e f3 ff ff       	call   f0100651 <cputchar>
			i--;
f0101333:	83 ee 01             	sub    $0x1,%esi
f0101336:	eb bb                	jmp    f01012f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101338:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010133e:	7f 1c                	jg     f010135c <readline+0x9c>
f0101340:	83 fb 1f             	cmp    $0x1f,%ebx
f0101343:	7e 17                	jle    f010135c <readline+0x9c>
			if (echoing)
f0101345:	85 ff                	test   %edi,%edi
f0101347:	74 08                	je     f0101351 <readline+0x91>
				cputchar(c);
f0101349:	89 1c 24             	mov    %ebx,(%esp)
f010134c:	e8 00 f3 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101351:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101357:	8d 76 01             	lea    0x1(%esi),%esi
f010135a:	eb 97                	jmp    f01012f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010135c:	83 fb 0d             	cmp    $0xd,%ebx
f010135f:	74 05                	je     f0101366 <readline+0xa6>
f0101361:	83 fb 0a             	cmp    $0xa,%ebx
f0101364:	75 8d                	jne    f01012f3 <readline+0x33>
			if (echoing)
f0101366:	85 ff                	test   %edi,%edi
f0101368:	74 0c                	je     f0101376 <readline+0xb6>
				cputchar('\n');
f010136a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101371:	e8 db f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101376:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010137d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101382:	83 c4 1c             	add    $0x1c,%esp
f0101385:	5b                   	pop    %ebx
f0101386:	5e                   	pop    %esi
f0101387:	5f                   	pop    %edi
f0101388:	5d                   	pop    %ebp
f0101389:	c3                   	ret    
f010138a:	66 90                	xchg   %ax,%ax
f010138c:	66 90                	xchg   %ax,%ax
f010138e:	66 90                	xchg   %ax,%ax

f0101390 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101390:	55                   	push   %ebp
f0101391:	89 e5                	mov    %esp,%ebp
f0101393:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101396:	b8 00 00 00 00       	mov    $0x0,%eax
f010139b:	eb 03                	jmp    f01013a0 <strlen+0x10>
		n++;
f010139d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01013a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013a4:	75 f7                	jne    f010139d <strlen+0xd>
	return n;
}
f01013a6:	5d                   	pop    %ebp
f01013a7:	c3                   	ret    

f01013a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013a8:	55                   	push   %ebp
f01013a9:	89 e5                	mov    %esp,%ebp
f01013ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b6:	eb 03                	jmp    f01013bb <strnlen+0x13>
		n++;
f01013b8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013bb:	39 d0                	cmp    %edx,%eax
f01013bd:	74 06                	je     f01013c5 <strnlen+0x1d>
f01013bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013c3:	75 f3                	jne    f01013b8 <strnlen+0x10>
	return n;
}
f01013c5:	5d                   	pop    %ebp
f01013c6:	c3                   	ret    

f01013c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013c7:	55                   	push   %ebp
f01013c8:	89 e5                	mov    %esp,%ebp
f01013ca:	53                   	push   %ebx
f01013cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013d1:	89 c2                	mov    %eax,%edx
f01013d3:	83 c2 01             	add    $0x1,%edx
f01013d6:	83 c1 01             	add    $0x1,%ecx
f01013d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013e0:	84 db                	test   %bl,%bl
f01013e2:	75 ef                	jne    f01013d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013e4:	5b                   	pop    %ebx
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    

f01013e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013e7:	55                   	push   %ebp
f01013e8:	89 e5                	mov    %esp,%ebp
f01013ea:	53                   	push   %ebx
f01013eb:	83 ec 08             	sub    $0x8,%esp
f01013ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01013f1:	89 1c 24             	mov    %ebx,(%esp)
f01013f4:	e8 97 ff ff ff       	call   f0101390 <strlen>
	strcpy(dst + len, src);
f01013f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101400:	01 d8                	add    %ebx,%eax
f0101402:	89 04 24             	mov    %eax,(%esp)
f0101405:	e8 bd ff ff ff       	call   f01013c7 <strcpy>
	return dst;
}
f010140a:	89 d8                	mov    %ebx,%eax
f010140c:	83 c4 08             	add    $0x8,%esp
f010140f:	5b                   	pop    %ebx
f0101410:	5d                   	pop    %ebp
f0101411:	c3                   	ret    

f0101412 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101412:	55                   	push   %ebp
f0101413:	89 e5                	mov    %esp,%ebp
f0101415:	56                   	push   %esi
f0101416:	53                   	push   %ebx
f0101417:	8b 75 08             	mov    0x8(%ebp),%esi
f010141a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010141d:	89 f3                	mov    %esi,%ebx
f010141f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101422:	89 f2                	mov    %esi,%edx
f0101424:	eb 0f                	jmp    f0101435 <strncpy+0x23>
		*dst++ = *src;
f0101426:	83 c2 01             	add    $0x1,%edx
f0101429:	0f b6 01             	movzbl (%ecx),%eax
f010142c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010142f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101432:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101435:	39 da                	cmp    %ebx,%edx
f0101437:	75 ed                	jne    f0101426 <strncpy+0x14>
	}
	return ret;
}
f0101439:	89 f0                	mov    %esi,%eax
f010143b:	5b                   	pop    %ebx
f010143c:	5e                   	pop    %esi
f010143d:	5d                   	pop    %ebp
f010143e:	c3                   	ret    

f010143f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010143f:	55                   	push   %ebp
f0101440:	89 e5                	mov    %esp,%ebp
f0101442:	56                   	push   %esi
f0101443:	53                   	push   %ebx
f0101444:	8b 75 08             	mov    0x8(%ebp),%esi
f0101447:	8b 55 0c             	mov    0xc(%ebp),%edx
f010144a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010144d:	89 f0                	mov    %esi,%eax
f010144f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101453:	85 c9                	test   %ecx,%ecx
f0101455:	75 0b                	jne    f0101462 <strlcpy+0x23>
f0101457:	eb 1d                	jmp    f0101476 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101459:	83 c0 01             	add    $0x1,%eax
f010145c:	83 c2 01             	add    $0x1,%edx
f010145f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101462:	39 d8                	cmp    %ebx,%eax
f0101464:	74 0b                	je     f0101471 <strlcpy+0x32>
f0101466:	0f b6 0a             	movzbl (%edx),%ecx
f0101469:	84 c9                	test   %cl,%cl
f010146b:	75 ec                	jne    f0101459 <strlcpy+0x1a>
f010146d:	89 c2                	mov    %eax,%edx
f010146f:	eb 02                	jmp    f0101473 <strlcpy+0x34>
f0101471:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0101473:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101476:	29 f0                	sub    %esi,%eax
}
f0101478:	5b                   	pop    %ebx
f0101479:	5e                   	pop    %esi
f010147a:	5d                   	pop    %ebp
f010147b:	c3                   	ret    

f010147c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010147c:	55                   	push   %ebp
f010147d:	89 e5                	mov    %esp,%ebp
f010147f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101482:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101485:	eb 06                	jmp    f010148d <strcmp+0x11>
		p++, q++;
f0101487:	83 c1 01             	add    $0x1,%ecx
f010148a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010148d:	0f b6 01             	movzbl (%ecx),%eax
f0101490:	84 c0                	test   %al,%al
f0101492:	74 04                	je     f0101498 <strcmp+0x1c>
f0101494:	3a 02                	cmp    (%edx),%al
f0101496:	74 ef                	je     f0101487 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101498:	0f b6 c0             	movzbl %al,%eax
f010149b:	0f b6 12             	movzbl (%edx),%edx
f010149e:	29 d0                	sub    %edx,%eax
}
f01014a0:	5d                   	pop    %ebp
f01014a1:	c3                   	ret    

f01014a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014a2:	55                   	push   %ebp
f01014a3:	89 e5                	mov    %esp,%ebp
f01014a5:	53                   	push   %ebx
f01014a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ac:	89 c3                	mov    %eax,%ebx
f01014ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014b1:	eb 06                	jmp    f01014b9 <strncmp+0x17>
		n--, p++, q++;
f01014b3:	83 c0 01             	add    $0x1,%eax
f01014b6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01014b9:	39 d8                	cmp    %ebx,%eax
f01014bb:	74 15                	je     f01014d2 <strncmp+0x30>
f01014bd:	0f b6 08             	movzbl (%eax),%ecx
f01014c0:	84 c9                	test   %cl,%cl
f01014c2:	74 04                	je     f01014c8 <strncmp+0x26>
f01014c4:	3a 0a                	cmp    (%edx),%cl
f01014c6:	74 eb                	je     f01014b3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014c8:	0f b6 00             	movzbl (%eax),%eax
f01014cb:	0f b6 12             	movzbl (%edx),%edx
f01014ce:	29 d0                	sub    %edx,%eax
f01014d0:	eb 05                	jmp    f01014d7 <strncmp+0x35>
		return 0;
f01014d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014d7:	5b                   	pop    %ebx
f01014d8:	5d                   	pop    %ebp
f01014d9:	c3                   	ret    

f01014da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014da:	55                   	push   %ebp
f01014db:	89 e5                	mov    %esp,%ebp
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014e4:	eb 07                	jmp    f01014ed <strchr+0x13>
		if (*s == c)
f01014e6:	38 ca                	cmp    %cl,%dl
f01014e8:	74 0f                	je     f01014f9 <strchr+0x1f>
	for (; *s; s++)
f01014ea:	83 c0 01             	add    $0x1,%eax
f01014ed:	0f b6 10             	movzbl (%eax),%edx
f01014f0:	84 d2                	test   %dl,%dl
f01014f2:	75 f2                	jne    f01014e6 <strchr+0xc>
			return (char *) s;
	return 0;
f01014f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f9:	5d                   	pop    %ebp
f01014fa:	c3                   	ret    

f01014fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014fb:	55                   	push   %ebp
f01014fc:	89 e5                	mov    %esp,%ebp
f01014fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101501:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101505:	eb 07                	jmp    f010150e <strfind+0x13>
		if (*s == c)
f0101507:	38 ca                	cmp    %cl,%dl
f0101509:	74 0a                	je     f0101515 <strfind+0x1a>
	for (; *s; s++)
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	0f b6 10             	movzbl (%eax),%edx
f0101511:	84 d2                	test   %dl,%dl
f0101513:	75 f2                	jne    f0101507 <strfind+0xc>
			break;
	return (char *) s;
}
f0101515:	5d                   	pop    %ebp
f0101516:	c3                   	ret    

f0101517 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101517:	55                   	push   %ebp
f0101518:	89 e5                	mov    %esp,%ebp
f010151a:	57                   	push   %edi
f010151b:	56                   	push   %esi
f010151c:	53                   	push   %ebx
f010151d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101520:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101523:	85 c9                	test   %ecx,%ecx
f0101525:	74 36                	je     f010155d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101527:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010152d:	75 28                	jne    f0101557 <memset+0x40>
f010152f:	f6 c1 03             	test   $0x3,%cl
f0101532:	75 23                	jne    f0101557 <memset+0x40>
		c &= 0xFF;
f0101534:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101538:	89 d3                	mov    %edx,%ebx
f010153a:	c1 e3 08             	shl    $0x8,%ebx
f010153d:	89 d6                	mov    %edx,%esi
f010153f:	c1 e6 18             	shl    $0x18,%esi
f0101542:	89 d0                	mov    %edx,%eax
f0101544:	c1 e0 10             	shl    $0x10,%eax
f0101547:	09 f0                	or     %esi,%eax
f0101549:	09 c2                	or     %eax,%edx
f010154b:	89 d0                	mov    %edx,%eax
f010154d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010154f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101552:	fc                   	cld    
f0101553:	f3 ab                	rep stos %eax,%es:(%edi)
f0101555:	eb 06                	jmp    f010155d <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101557:	8b 45 0c             	mov    0xc(%ebp),%eax
f010155a:	fc                   	cld    
f010155b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010155d:	89 f8                	mov    %edi,%eax
f010155f:	5b                   	pop    %ebx
f0101560:	5e                   	pop    %esi
f0101561:	5f                   	pop    %edi
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	57                   	push   %edi
f0101568:	56                   	push   %esi
f0101569:	8b 45 08             	mov    0x8(%ebp),%eax
f010156c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010156f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101572:	39 c6                	cmp    %eax,%esi
f0101574:	73 35                	jae    f01015ab <memmove+0x47>
f0101576:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101579:	39 d0                	cmp    %edx,%eax
f010157b:	73 2e                	jae    f01015ab <memmove+0x47>
		s += n;
		d += n;
f010157d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101580:	89 d6                	mov    %edx,%esi
f0101582:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101584:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010158a:	75 13                	jne    f010159f <memmove+0x3b>
f010158c:	f6 c1 03             	test   $0x3,%cl
f010158f:	75 0e                	jne    f010159f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101591:	83 ef 04             	sub    $0x4,%edi
f0101594:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101597:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010159a:	fd                   	std    
f010159b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010159d:	eb 09                	jmp    f01015a8 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010159f:	83 ef 01             	sub    $0x1,%edi
f01015a2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01015a5:	fd                   	std    
f01015a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015a8:	fc                   	cld    
f01015a9:	eb 1d                	jmp    f01015c8 <memmove+0x64>
f01015ab:	89 f2                	mov    %esi,%edx
f01015ad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015af:	f6 c2 03             	test   $0x3,%dl
f01015b2:	75 0f                	jne    f01015c3 <memmove+0x5f>
f01015b4:	f6 c1 03             	test   $0x3,%cl
f01015b7:	75 0a                	jne    f01015c3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015b9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01015bc:	89 c7                	mov    %eax,%edi
f01015be:	fc                   	cld    
f01015bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015c1:	eb 05                	jmp    f01015c8 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f01015c3:	89 c7                	mov    %eax,%edi
f01015c5:	fc                   	cld    
f01015c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015c8:	5e                   	pop    %esi
f01015c9:	5f                   	pop    %edi
f01015ca:	5d                   	pop    %ebp
f01015cb:	c3                   	ret    

f01015cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015cc:	55                   	push   %ebp
f01015cd:	89 e5                	mov    %esp,%ebp
f01015cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01015d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e3:	89 04 24             	mov    %eax,(%esp)
f01015e6:	e8 79 ff ff ff       	call   f0101564 <memmove>
}
f01015eb:	c9                   	leave  
f01015ec:	c3                   	ret    

f01015ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015ed:	55                   	push   %ebp
f01015ee:	89 e5                	mov    %esp,%ebp
f01015f0:	56                   	push   %esi
f01015f1:	53                   	push   %ebx
f01015f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01015f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015f8:	89 d6                	mov    %edx,%esi
f01015fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015fd:	eb 1a                	jmp    f0101619 <memcmp+0x2c>
		if (*s1 != *s2)
f01015ff:	0f b6 02             	movzbl (%edx),%eax
f0101602:	0f b6 19             	movzbl (%ecx),%ebx
f0101605:	38 d8                	cmp    %bl,%al
f0101607:	74 0a                	je     f0101613 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101609:	0f b6 c0             	movzbl %al,%eax
f010160c:	0f b6 db             	movzbl %bl,%ebx
f010160f:	29 d8                	sub    %ebx,%eax
f0101611:	eb 0f                	jmp    f0101622 <memcmp+0x35>
		s1++, s2++;
f0101613:	83 c2 01             	add    $0x1,%edx
f0101616:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0101619:	39 f2                	cmp    %esi,%edx
f010161b:	75 e2                	jne    f01015ff <memcmp+0x12>
	}

	return 0;
f010161d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101622:	5b                   	pop    %ebx
f0101623:	5e                   	pop    %esi
f0101624:	5d                   	pop    %ebp
f0101625:	c3                   	ret    

f0101626 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101626:	55                   	push   %ebp
f0101627:	89 e5                	mov    %esp,%ebp
f0101629:	8b 45 08             	mov    0x8(%ebp),%eax
f010162c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010162f:	89 c2                	mov    %eax,%edx
f0101631:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101634:	eb 07                	jmp    f010163d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101636:	38 08                	cmp    %cl,(%eax)
f0101638:	74 07                	je     f0101641 <memfind+0x1b>
	for (; s < ends; s++)
f010163a:	83 c0 01             	add    $0x1,%eax
f010163d:	39 d0                	cmp    %edx,%eax
f010163f:	72 f5                	jb     f0101636 <memfind+0x10>
			break;
	return (void *) s;
}
f0101641:	5d                   	pop    %ebp
f0101642:	c3                   	ret    

f0101643 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101643:	55                   	push   %ebp
f0101644:	89 e5                	mov    %esp,%ebp
f0101646:	57                   	push   %edi
f0101647:	56                   	push   %esi
f0101648:	53                   	push   %ebx
f0101649:	8b 55 08             	mov    0x8(%ebp),%edx
f010164c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010164f:	eb 03                	jmp    f0101654 <strtol+0x11>
		s++;
f0101651:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101654:	0f b6 0a             	movzbl (%edx),%ecx
f0101657:	80 f9 09             	cmp    $0x9,%cl
f010165a:	74 f5                	je     f0101651 <strtol+0xe>
f010165c:	80 f9 20             	cmp    $0x20,%cl
f010165f:	74 f0                	je     f0101651 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101661:	80 f9 2b             	cmp    $0x2b,%cl
f0101664:	75 0a                	jne    f0101670 <strtol+0x2d>
		s++;
f0101666:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0101669:	bf 00 00 00 00       	mov    $0x0,%edi
f010166e:	eb 11                	jmp    f0101681 <strtol+0x3e>
f0101670:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0101675:	80 f9 2d             	cmp    $0x2d,%cl
f0101678:	75 07                	jne    f0101681 <strtol+0x3e>
		s++, neg = 1;
f010167a:	8d 52 01             	lea    0x1(%edx),%edx
f010167d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101681:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101686:	75 15                	jne    f010169d <strtol+0x5a>
f0101688:	80 3a 30             	cmpb   $0x30,(%edx)
f010168b:	75 10                	jne    f010169d <strtol+0x5a>
f010168d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101691:	75 0a                	jne    f010169d <strtol+0x5a>
		s += 2, base = 16;
f0101693:	83 c2 02             	add    $0x2,%edx
f0101696:	b8 10 00 00 00       	mov    $0x10,%eax
f010169b:	eb 10                	jmp    f01016ad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010169d:	85 c0                	test   %eax,%eax
f010169f:	75 0c                	jne    f01016ad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016a1:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f01016a3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016a6:	75 05                	jne    f01016ad <strtol+0x6a>
		s++, base = 8;
f01016a8:	83 c2 01             	add    $0x1,%edx
f01016ab:	b0 08                	mov    $0x8,%al
		base = 10;
f01016ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016b2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016b5:	0f b6 0a             	movzbl (%edx),%ecx
f01016b8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016bb:	89 f0                	mov    %esi,%eax
f01016bd:	3c 09                	cmp    $0x9,%al
f01016bf:	77 08                	ja     f01016c9 <strtol+0x86>
			dig = *s - '0';
f01016c1:	0f be c9             	movsbl %cl,%ecx
f01016c4:	83 e9 30             	sub    $0x30,%ecx
f01016c7:	eb 20                	jmp    f01016e9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016c9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016cc:	89 f0                	mov    %esi,%eax
f01016ce:	3c 19                	cmp    $0x19,%al
f01016d0:	77 08                	ja     f01016da <strtol+0x97>
			dig = *s - 'a' + 10;
f01016d2:	0f be c9             	movsbl %cl,%ecx
f01016d5:	83 e9 57             	sub    $0x57,%ecx
f01016d8:	eb 0f                	jmp    f01016e9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01016da:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01016dd:	89 f0                	mov    %esi,%eax
f01016df:	3c 19                	cmp    $0x19,%al
f01016e1:	77 16                	ja     f01016f9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01016e3:	0f be c9             	movsbl %cl,%ecx
f01016e6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016e9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01016ec:	7d 0f                	jge    f01016fd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01016ee:	83 c2 01             	add    $0x1,%edx
f01016f1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01016f5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01016f7:	eb bc                	jmp    f01016b5 <strtol+0x72>
f01016f9:	89 d8                	mov    %ebx,%eax
f01016fb:	eb 02                	jmp    f01016ff <strtol+0xbc>
f01016fd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01016ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101703:	74 05                	je     f010170a <strtol+0xc7>
		*endptr = (char *) s;
f0101705:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101708:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010170a:	f7 d8                	neg    %eax
f010170c:	85 ff                	test   %edi,%edi
f010170e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101711:	5b                   	pop    %ebx
f0101712:	5e                   	pop    %esi
f0101713:	5f                   	pop    %edi
f0101714:	5d                   	pop    %ebp
f0101715:	c3                   	ret    
f0101716:	66 90                	xchg   %ax,%ax
f0101718:	66 90                	xchg   %ax,%ax
f010171a:	66 90                	xchg   %ax,%ax
f010171c:	66 90                	xchg   %ax,%ax
f010171e:	66 90                	xchg   %ax,%ax

f0101720 <__udivdi3>:
f0101720:	55                   	push   %ebp
f0101721:	57                   	push   %edi
f0101722:	56                   	push   %esi
f0101723:	83 ec 0c             	sub    $0xc,%esp
f0101726:	8b 44 24 28          	mov    0x28(%esp),%eax
f010172a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010172e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101732:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101736:	85 c0                	test   %eax,%eax
f0101738:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010173c:	89 ea                	mov    %ebp,%edx
f010173e:	89 0c 24             	mov    %ecx,(%esp)
f0101741:	75 2d                	jne    f0101770 <__udivdi3+0x50>
f0101743:	39 e9                	cmp    %ebp,%ecx
f0101745:	77 61                	ja     f01017a8 <__udivdi3+0x88>
f0101747:	85 c9                	test   %ecx,%ecx
f0101749:	89 ce                	mov    %ecx,%esi
f010174b:	75 0b                	jne    f0101758 <__udivdi3+0x38>
f010174d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101752:	31 d2                	xor    %edx,%edx
f0101754:	f7 f1                	div    %ecx
f0101756:	89 c6                	mov    %eax,%esi
f0101758:	31 d2                	xor    %edx,%edx
f010175a:	89 e8                	mov    %ebp,%eax
f010175c:	f7 f6                	div    %esi
f010175e:	89 c5                	mov    %eax,%ebp
f0101760:	89 f8                	mov    %edi,%eax
f0101762:	f7 f6                	div    %esi
f0101764:	89 ea                	mov    %ebp,%edx
f0101766:	83 c4 0c             	add    $0xc,%esp
f0101769:	5e                   	pop    %esi
f010176a:	5f                   	pop    %edi
f010176b:	5d                   	pop    %ebp
f010176c:	c3                   	ret    
f010176d:	8d 76 00             	lea    0x0(%esi),%esi
f0101770:	39 e8                	cmp    %ebp,%eax
f0101772:	77 24                	ja     f0101798 <__udivdi3+0x78>
f0101774:	0f bd e8             	bsr    %eax,%ebp
f0101777:	83 f5 1f             	xor    $0x1f,%ebp
f010177a:	75 3c                	jne    f01017b8 <__udivdi3+0x98>
f010177c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101780:	39 34 24             	cmp    %esi,(%esp)
f0101783:	0f 86 9f 00 00 00    	jbe    f0101828 <__udivdi3+0x108>
f0101789:	39 d0                	cmp    %edx,%eax
f010178b:	0f 82 97 00 00 00    	jb     f0101828 <__udivdi3+0x108>
f0101791:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101798:	31 d2                	xor    %edx,%edx
f010179a:	31 c0                	xor    %eax,%eax
f010179c:	83 c4 0c             	add    $0xc,%esp
f010179f:	5e                   	pop    %esi
f01017a0:	5f                   	pop    %edi
f01017a1:	5d                   	pop    %ebp
f01017a2:	c3                   	ret    
f01017a3:	90                   	nop
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	89 f8                	mov    %edi,%eax
f01017aa:	f7 f1                	div    %ecx
f01017ac:	31 d2                	xor    %edx,%edx
f01017ae:	83 c4 0c             	add    $0xc,%esp
f01017b1:	5e                   	pop    %esi
f01017b2:	5f                   	pop    %edi
f01017b3:	5d                   	pop    %ebp
f01017b4:	c3                   	ret    
f01017b5:	8d 76 00             	lea    0x0(%esi),%esi
f01017b8:	89 e9                	mov    %ebp,%ecx
f01017ba:	8b 3c 24             	mov    (%esp),%edi
f01017bd:	d3 e0                	shl    %cl,%eax
f01017bf:	89 c6                	mov    %eax,%esi
f01017c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017c6:	29 e8                	sub    %ebp,%eax
f01017c8:	89 c1                	mov    %eax,%ecx
f01017ca:	d3 ef                	shr    %cl,%edi
f01017cc:	89 e9                	mov    %ebp,%ecx
f01017ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017d2:	8b 3c 24             	mov    (%esp),%edi
f01017d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01017d9:	89 d6                	mov    %edx,%esi
f01017db:	d3 e7                	shl    %cl,%edi
f01017dd:	89 c1                	mov    %eax,%ecx
f01017df:	89 3c 24             	mov    %edi,(%esp)
f01017e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017e6:	d3 ee                	shr    %cl,%esi
f01017e8:	89 e9                	mov    %ebp,%ecx
f01017ea:	d3 e2                	shl    %cl,%edx
f01017ec:	89 c1                	mov    %eax,%ecx
f01017ee:	d3 ef                	shr    %cl,%edi
f01017f0:	09 d7                	or     %edx,%edi
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	89 f8                	mov    %edi,%eax
f01017f6:	f7 74 24 08          	divl   0x8(%esp)
f01017fa:	89 d6                	mov    %edx,%esi
f01017fc:	89 c7                	mov    %eax,%edi
f01017fe:	f7 24 24             	mull   (%esp)
f0101801:	39 d6                	cmp    %edx,%esi
f0101803:	89 14 24             	mov    %edx,(%esp)
f0101806:	72 30                	jb     f0101838 <__udivdi3+0x118>
f0101808:	8b 54 24 04          	mov    0x4(%esp),%edx
f010180c:	89 e9                	mov    %ebp,%ecx
f010180e:	d3 e2                	shl    %cl,%edx
f0101810:	39 c2                	cmp    %eax,%edx
f0101812:	73 05                	jae    f0101819 <__udivdi3+0xf9>
f0101814:	3b 34 24             	cmp    (%esp),%esi
f0101817:	74 1f                	je     f0101838 <__udivdi3+0x118>
f0101819:	89 f8                	mov    %edi,%eax
f010181b:	31 d2                	xor    %edx,%edx
f010181d:	e9 7a ff ff ff       	jmp    f010179c <__udivdi3+0x7c>
f0101822:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101828:	31 d2                	xor    %edx,%edx
f010182a:	b8 01 00 00 00       	mov    $0x1,%eax
f010182f:	e9 68 ff ff ff       	jmp    f010179c <__udivdi3+0x7c>
f0101834:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101838:	8d 47 ff             	lea    -0x1(%edi),%eax
f010183b:	31 d2                	xor    %edx,%edx
f010183d:	83 c4 0c             	add    $0xc,%esp
f0101840:	5e                   	pop    %esi
f0101841:	5f                   	pop    %edi
f0101842:	5d                   	pop    %ebp
f0101843:	c3                   	ret    
f0101844:	66 90                	xchg   %ax,%ax
f0101846:	66 90                	xchg   %ax,%ax
f0101848:	66 90                	xchg   %ax,%ax
f010184a:	66 90                	xchg   %ax,%ax
f010184c:	66 90                	xchg   %ax,%ax
f010184e:	66 90                	xchg   %ax,%ax

f0101850 <__umoddi3>:
f0101850:	55                   	push   %ebp
f0101851:	57                   	push   %edi
f0101852:	56                   	push   %esi
f0101853:	83 ec 14             	sub    $0x14,%esp
f0101856:	8b 44 24 28          	mov    0x28(%esp),%eax
f010185a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010185e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101862:	89 c7                	mov    %eax,%edi
f0101864:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101868:	8b 44 24 30          	mov    0x30(%esp),%eax
f010186c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101870:	89 34 24             	mov    %esi,(%esp)
f0101873:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101877:	85 c0                	test   %eax,%eax
f0101879:	89 c2                	mov    %eax,%edx
f010187b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010187f:	75 17                	jne    f0101898 <__umoddi3+0x48>
f0101881:	39 fe                	cmp    %edi,%esi
f0101883:	76 4b                	jbe    f01018d0 <__umoddi3+0x80>
f0101885:	89 c8                	mov    %ecx,%eax
f0101887:	89 fa                	mov    %edi,%edx
f0101889:	f7 f6                	div    %esi
f010188b:	89 d0                	mov    %edx,%eax
f010188d:	31 d2                	xor    %edx,%edx
f010188f:	83 c4 14             	add    $0x14,%esp
f0101892:	5e                   	pop    %esi
f0101893:	5f                   	pop    %edi
f0101894:	5d                   	pop    %ebp
f0101895:	c3                   	ret    
f0101896:	66 90                	xchg   %ax,%ax
f0101898:	39 f8                	cmp    %edi,%eax
f010189a:	77 54                	ja     f01018f0 <__umoddi3+0xa0>
f010189c:	0f bd e8             	bsr    %eax,%ebp
f010189f:	83 f5 1f             	xor    $0x1f,%ebp
f01018a2:	75 5c                	jne    f0101900 <__umoddi3+0xb0>
f01018a4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018a8:	39 3c 24             	cmp    %edi,(%esp)
f01018ab:	0f 87 e7 00 00 00    	ja     f0101998 <__umoddi3+0x148>
f01018b1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018b5:	29 f1                	sub    %esi,%ecx
f01018b7:	19 c7                	sbb    %eax,%edi
f01018b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018bd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018c1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018c5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018c9:	83 c4 14             	add    $0x14,%esp
f01018cc:	5e                   	pop    %esi
f01018cd:	5f                   	pop    %edi
f01018ce:	5d                   	pop    %ebp
f01018cf:	c3                   	ret    
f01018d0:	85 f6                	test   %esi,%esi
f01018d2:	89 f5                	mov    %esi,%ebp
f01018d4:	75 0b                	jne    f01018e1 <__umoddi3+0x91>
f01018d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018db:	31 d2                	xor    %edx,%edx
f01018dd:	f7 f6                	div    %esi
f01018df:	89 c5                	mov    %eax,%ebp
f01018e1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018e5:	31 d2                	xor    %edx,%edx
f01018e7:	f7 f5                	div    %ebp
f01018e9:	89 c8                	mov    %ecx,%eax
f01018eb:	f7 f5                	div    %ebp
f01018ed:	eb 9c                	jmp    f010188b <__umoddi3+0x3b>
f01018ef:	90                   	nop
f01018f0:	89 c8                	mov    %ecx,%eax
f01018f2:	89 fa                	mov    %edi,%edx
f01018f4:	83 c4 14             	add    $0x14,%esp
f01018f7:	5e                   	pop    %esi
f01018f8:	5f                   	pop    %edi
f01018f9:	5d                   	pop    %ebp
f01018fa:	c3                   	ret    
f01018fb:	90                   	nop
f01018fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101900:	8b 04 24             	mov    (%esp),%eax
f0101903:	be 20 00 00 00       	mov    $0x20,%esi
f0101908:	89 e9                	mov    %ebp,%ecx
f010190a:	29 ee                	sub    %ebp,%esi
f010190c:	d3 e2                	shl    %cl,%edx
f010190e:	89 f1                	mov    %esi,%ecx
f0101910:	d3 e8                	shr    %cl,%eax
f0101912:	89 e9                	mov    %ebp,%ecx
f0101914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101918:	8b 04 24             	mov    (%esp),%eax
f010191b:	09 54 24 04          	or     %edx,0x4(%esp)
f010191f:	89 fa                	mov    %edi,%edx
f0101921:	d3 e0                	shl    %cl,%eax
f0101923:	89 f1                	mov    %esi,%ecx
f0101925:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101929:	8b 44 24 10          	mov    0x10(%esp),%eax
f010192d:	d3 ea                	shr    %cl,%edx
f010192f:	89 e9                	mov    %ebp,%ecx
f0101931:	d3 e7                	shl    %cl,%edi
f0101933:	89 f1                	mov    %esi,%ecx
f0101935:	d3 e8                	shr    %cl,%eax
f0101937:	89 e9                	mov    %ebp,%ecx
f0101939:	09 f8                	or     %edi,%eax
f010193b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010193f:	f7 74 24 04          	divl   0x4(%esp)
f0101943:	d3 e7                	shl    %cl,%edi
f0101945:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101949:	89 d7                	mov    %edx,%edi
f010194b:	f7 64 24 08          	mull   0x8(%esp)
f010194f:	39 d7                	cmp    %edx,%edi
f0101951:	89 c1                	mov    %eax,%ecx
f0101953:	89 14 24             	mov    %edx,(%esp)
f0101956:	72 2c                	jb     f0101984 <__umoddi3+0x134>
f0101958:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010195c:	72 22                	jb     f0101980 <__umoddi3+0x130>
f010195e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101962:	29 c8                	sub    %ecx,%eax
f0101964:	19 d7                	sbb    %edx,%edi
f0101966:	89 e9                	mov    %ebp,%ecx
f0101968:	89 fa                	mov    %edi,%edx
f010196a:	d3 e8                	shr    %cl,%eax
f010196c:	89 f1                	mov    %esi,%ecx
f010196e:	d3 e2                	shl    %cl,%edx
f0101970:	89 e9                	mov    %ebp,%ecx
f0101972:	d3 ef                	shr    %cl,%edi
f0101974:	09 d0                	or     %edx,%eax
f0101976:	89 fa                	mov    %edi,%edx
f0101978:	83 c4 14             	add    $0x14,%esp
f010197b:	5e                   	pop    %esi
f010197c:	5f                   	pop    %edi
f010197d:	5d                   	pop    %ebp
f010197e:	c3                   	ret    
f010197f:	90                   	nop
f0101980:	39 d7                	cmp    %edx,%edi
f0101982:	75 da                	jne    f010195e <__umoddi3+0x10e>
f0101984:	8b 14 24             	mov    (%esp),%edx
f0101987:	89 c1                	mov    %eax,%ecx
f0101989:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010198d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101991:	eb cb                	jmp    f010195e <__umoddi3+0x10e>
f0101993:	90                   	nop
f0101994:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101998:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010199c:	0f 82 0f ff ff ff    	jb     f01018b1 <__umoddi3+0x61>
f01019a2:	e9 1a ff ff ff       	jmp    f01018c1 <__umoddi3+0x71>
