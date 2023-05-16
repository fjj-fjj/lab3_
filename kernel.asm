
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	e8478793          	addi	a5,a5,-380 # 80005ee0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	692080e7          	jalr	1682(ra) # 800027b8 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	914080e7          	jalr	-1772(ra) # 80001ade <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	32e080e7          	jalr	814(ra) # 80002508 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	54c080e7          	jalr	1356(ra) # 80002762 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	518080e7          	jalr	1304(ra) # 8000280e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	23e080e7          	jalr	574(ra) # 80002688 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	73478793          	addi	a5,a5,1844 # 80021bb0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	de6080e7          	jalr	-538(ra) # 80002688 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	bcc080e7          	jalr	-1076(ra) # 80002508 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00026797          	auipc	a5,0x26
    80000a2a:	5fa78793          	addi	a5,a5,1530 # 80027020 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00026517          	auipc	a0,0x26
    80000afa:	52a50513          	addi	a0,a0,1322 # 80027020 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	f2a080e7          	jalr	-214(ra) # 80001ac2 <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	ef8080e7          	jalr	-264(ra) # 80001ac2 <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	eec080e7          	jalr	-276(ra) # 80001ac2 <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	ed4080e7          	jalr	-300(ra) # 80001ac2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e94080e7          	jalr	-364(ra) # 80001ac2 <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	42e50513          	addi	a0,a0,1070 # 80008070 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	e68080e7          	jalr	-408(ra) # 80001ac2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3e650513          	addi	a0,a0,998 # 80008078 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3ee50513          	addi	a0,a0,1006 # 80008090 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	3ae50513          	addi	a0,a0,942 # 80008098 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	c02080e7          	jalr	-1022(ra) # 80001ab2 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	be6080e7          	jalr	-1050(ra) # 80001ab2 <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	1e250513          	addi	a0,a0,482 # 800080b8 <digits+0x78>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	1d8080e7          	jalr	472(ra) # 800010be <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00002097          	auipc	ra,0x2
    80000ef2:	a60080e7          	jalr	-1440(ra) # 8000294e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	02a080e7          	jalr	42(ra) # 80005f20 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	314080e7          	jalr	788(ra) # 80002212 <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    statsinit();
    80000f0e:	00005097          	auipc	ra,0x5
    80000f12:	7b4080e7          	jalr	1972(ra) # 800066c2 <statsinit>
    printfinit();
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	856080e7          	jalr	-1962(ra) # 8000076c <printfinit>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	1aa50513          	addi	a0,a0,426 # 800080c8 <digits+0x88>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	666080e7          	jalr	1638(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	17250513          	addi	a0,a0,370 # 800080a0 <digits+0x60>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	656080e7          	jalr	1622(ra) # 8000058c <printf>
    printf("\n");
    80000f3e:	00007517          	auipc	a0,0x7
    80000f42:	18a50513          	addi	a0,a0,394 # 800080c8 <digits+0x88>
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	646080e7          	jalr	1606(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	b84080e7          	jalr	-1148(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	38a080e7          	jalr	906(ra) # 800012e0 <kvminit>
    kvminithart();   // turn on paging
    80000f5e:	00000097          	auipc	ra,0x0
    80000f62:	160080e7          	jalr	352(ra) # 800010be <kvminithart>
    procinit();      // process table
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	aec080e7          	jalr	-1300(ra) # 80001a52 <procinit>
    trapinit();      // trap vectors
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	9b8080e7          	jalr	-1608(ra) # 80002926 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	9d8080e7          	jalr	-1576(ra) # 8000294e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	f8c080e7          	jalr	-116(ra) # 80005f0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	f9a080e7          	jalr	-102(ra) # 80005f20 <plicinithart>
    binit();         // buffer cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	100080e7          	jalr	256(ra) # 8000308e <binit>
    iinit();         // inode cache
    80000f96:	00002097          	auipc	ra,0x2
    80000f9a:	790080e7          	jalr	1936(ra) # 80003726 <iinit>
    fileinit();      // file table
    80000f9e:	00003097          	auipc	ra,0x3
    80000fa2:	72a080e7          	jalr	1834(ra) # 800046c8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa6:	00005097          	auipc	ra,0x5
    80000faa:	082080e7          	jalr	130(ra) # 80006028 <virtio_disk_init>
    userinit();      // first user process
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	f36080e7          	jalr	-202(ra) # 80001ee4 <userinit>
    __sync_synchronize();
    80000fb6:	0ff0000f          	fence
    started = 1;
    80000fba:	4785                	li	a5,1
    80000fbc:	00008717          	auipc	a4,0x8
    80000fc0:	04f72823          	sw	a5,80(a4) # 8000900c <started>
    80000fc4:	bf2d                	j	80000efe <main+0x56>

0000000080000fc6 <vmprint_helper>:

/*
 * create a direct-map page table for the kernel.
 */
void vmprint_helper(pagetable_t pgtbl,int level)
{
    80000fc6:	7159                	addi	sp,sp,-112
    80000fc8:	f486                	sd	ra,104(sp)
    80000fca:	f0a2                	sd	s0,96(sp)
    80000fcc:	eca6                	sd	s1,88(sp)
    80000fce:	e8ca                	sd	s2,80(sp)
    80000fd0:	e4ce                	sd	s3,72(sp)
    80000fd2:	e0d2                	sd	s4,64(sp)
    80000fd4:	fc56                	sd	s5,56(sp)
    80000fd6:	f85a                	sd	s6,48(sp)
    80000fd8:	f45e                	sd	s7,40(sp)
    80000fda:	f062                	sd	s8,32(sp)
    80000fdc:	ec66                	sd	s9,24(sp)
    80000fde:	e86a                	sd	s10,16(sp)
    80000fe0:	e46e                	sd	s11,8(sp)
    80000fe2:	1880                	addi	s0,sp,112
    80000fe4:	8aae                	mv	s5,a1
    for(int i=0;i<512;i++)
    80000fe6:	89aa                	mv	s3,a0
    80000fe8:	4901                	li	s2,0
    {
      pte_t pte=pgtbl[i];
      if(pte & PTE_V)
      {
	printf("..");
    80000fea:	00007d17          	auipc	s10,0x7
    80000fee:	0e6d0d13          	addi	s10,s10,230 # 800080d0 <digits+0x90>
	for(int j=1;j<level;j++)
    80000ff2:	4c05                	li	s8,1
          printf(" ..");
	printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    80000ff4:	00007c97          	auipc	s9,0x7
    80000ff8:	0ecc8c93          	addi	s9,s9,236 # 800080e0 <digits+0xa0>
	if((pte&(PTE_R|PTE_W|PTE_X))==0)
        {
	  pagetable_t child=(pagetable_t)PTE2PA(pte);
	  vmprint_helper(child,level+1);
    80000ffc:	00158d9b          	addiw	s11,a1,1
          printf(" ..");
    80001000:	00007b17          	auipc	s6,0x7
    80001004:	0d8b0b13          	addi	s6,s6,216 # 800080d8 <digits+0x98>
    for(int i=0;i<512;i++)
    80001008:	20000b93          	li	s7,512
    8000100c:	a029                	j	80001016 <vmprint_helper+0x50>
    8000100e:	2905                	addiw	s2,s2,1
    80001010:	09a1                	addi	s3,s3,8
    80001012:	05790d63          	beq	s2,s7,8000106c <vmprint_helper+0xa6>
      pte_t pte=pgtbl[i];
    80001016:	0009ba03          	ld	s4,0(s3) # 1000 <_entry-0x7ffff000>
      if(pte & PTE_V)
    8000101a:	001a7793          	andi	a5,s4,1
    8000101e:	dbe5                	beqz	a5,8000100e <vmprint_helper+0x48>
	printf("..");
    80001020:	856a                	mv	a0,s10
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	56a080e7          	jalr	1386(ra) # 8000058c <printf>
	for(int j=1;j<level;j++)
    8000102a:	015c5b63          	bge	s8,s5,80001040 <vmprint_helper+0x7a>
    8000102e:	84e2                	mv	s1,s8
          printf(" ..");
    80001030:	855a                	mv	a0,s6
    80001032:	fffff097          	auipc	ra,0xfffff
    80001036:	55a080e7          	jalr	1370(ra) # 8000058c <printf>
	for(int j=1;j<level;j++)
    8000103a:	2485                	addiw	s1,s1,1
    8000103c:	fe9a9ae3          	bne	s5,s1,80001030 <vmprint_helper+0x6a>
	printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    80001040:	00aa5493          	srli	s1,s4,0xa
    80001044:	04b2                	slli	s1,s1,0xc
    80001046:	86a6                	mv	a3,s1
    80001048:	8652                	mv	a2,s4
    8000104a:	85ca                	mv	a1,s2
    8000104c:	8566                	mv	a0,s9
    8000104e:	fffff097          	auipc	ra,0xfffff
    80001052:	53e080e7          	jalr	1342(ra) # 8000058c <printf>
	if((pte&(PTE_R|PTE_W|PTE_X))==0)
    80001056:	00ea7a13          	andi	s4,s4,14
    8000105a:	fa0a1ae3          	bnez	s4,8000100e <vmprint_helper+0x48>
	  vmprint_helper(child,level+1);
    8000105e:	85ee                	mv	a1,s11
    80001060:	8526                	mv	a0,s1
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f64080e7          	jalr	-156(ra) # 80000fc6 <vmprint_helper>
    8000106a:	b755                	j	8000100e <vmprint_helper+0x48>
	}
      }
    }
}
    8000106c:	70a6                	ld	ra,104(sp)
    8000106e:	7406                	ld	s0,96(sp)
    80001070:	64e6                	ld	s1,88(sp)
    80001072:	6946                	ld	s2,80(sp)
    80001074:	69a6                	ld	s3,72(sp)
    80001076:	6a06                	ld	s4,64(sp)
    80001078:	7ae2                	ld	s5,56(sp)
    8000107a:	7b42                	ld	s6,48(sp)
    8000107c:	7ba2                	ld	s7,40(sp)
    8000107e:	7c02                	ld	s8,32(sp)
    80001080:	6ce2                	ld	s9,24(sp)
    80001082:	6d42                	ld	s10,16(sp)
    80001084:	6da2                	ld	s11,8(sp)
    80001086:	6165                	addi	sp,sp,112
    80001088:	8082                	ret

000000008000108a <vmprint>:

void vmprint(pagetable_t pgtbl)
{
    8000108a:	1101                	addi	sp,sp,-32
    8000108c:	ec06                	sd	ra,24(sp)
    8000108e:	e822                	sd	s0,16(sp)
    80001090:	e426                	sd	s1,8(sp)
    80001092:	1000                	addi	s0,sp,32
    80001094:	84aa                	mv	s1,a0
  printf("page table %p\n",pgtbl);
    80001096:	85aa                	mv	a1,a0
    80001098:	00007517          	auipc	a0,0x7
    8000109c:	06050513          	addi	a0,a0,96 # 800080f8 <digits+0xb8>
    800010a0:	fffff097          	auipc	ra,0xfffff
    800010a4:	4ec080e7          	jalr	1260(ra) # 8000058c <printf>
  vmprint_helper(pgtbl,1);
    800010a8:	4585                	li	a1,1
    800010aa:	8526                	mv	a0,s1
    800010ac:	00000097          	auipc	ra,0x0
    800010b0:	f1a080e7          	jalr	-230(ra) # 80000fc6 <vmprint_helper>
}
    800010b4:	60e2                	ld	ra,24(sp)
    800010b6:	6442                	ld	s0,16(sp)
    800010b8:	64a2                	ld	s1,8(sp)
    800010ba:	6105                	addi	sp,sp,32
    800010bc:	8082                	ret

00000000800010be <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010be:	1141                	addi	sp,sp,-16
    800010c0:	e422                	sd	s0,8(sp)
    800010c2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010c4:	00008797          	auipc	a5,0x8
    800010c8:	f4c7b783          	ld	a5,-180(a5) # 80009010 <kernel_pagetable>
    800010cc:	83b1                	srli	a5,a5,0xc
    800010ce:	577d                	li	a4,-1
    800010d0:	177e                	slli	a4,a4,0x3f
    800010d2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010d4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010d8:	12000073          	sfence.vma
  sfence_vma();
}
    800010dc:	6422                	ld	s0,8(sp)
    800010de:	0141                	addi	sp,sp,16
    800010e0:	8082                	ret

00000000800010e2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010e2:	7139                	addi	sp,sp,-64
    800010e4:	fc06                	sd	ra,56(sp)
    800010e6:	f822                	sd	s0,48(sp)
    800010e8:	f426                	sd	s1,40(sp)
    800010ea:	f04a                	sd	s2,32(sp)
    800010ec:	ec4e                	sd	s3,24(sp)
    800010ee:	e852                	sd	s4,16(sp)
    800010f0:	e456                	sd	s5,8(sp)
    800010f2:	e05a                	sd	s6,0(sp)
    800010f4:	0080                	addi	s0,sp,64
    800010f6:	84aa                	mv	s1,a0
    800010f8:	89ae                	mv	s3,a1
    800010fa:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010fc:	57fd                	li	a5,-1
    800010fe:	83e9                	srli	a5,a5,0x1a
    80001100:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001102:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001104:	04b7f263          	bgeu	a5,a1,80001148 <walk+0x66>
    panic("walk");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	00050513          	mv	a0,a0
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	432080e7          	jalr	1074(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001118:	060a8663          	beqz	s5,80001184 <walk+0xa2>
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	9f2080e7          	jalr	-1550(ra) # 80000b0e <kalloc>
    80001124:	84aa                	mv	s1,a0
    80001126:	c529                	beqz	a0,80001170 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001128:	6605                	lui	a2,0x1
    8000112a:	4581                	li	a1,0
    8000112c:	00000097          	auipc	ra,0x0
    80001130:	bce080e7          	jalr	-1074(ra) # 80000cfa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001134:	00c4d793          	srli	a5,s1,0xc
    80001138:	07aa                	slli	a5,a5,0xa
    8000113a:	0017e793          	ori	a5,a5,1
    8000113e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001142:	3a5d                	addiw	s4,s4,-9
    80001144:	036a0063          	beq	s4,s6,80001164 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001148:	0149d933          	srl	s2,s3,s4
    8000114c:	1ff97913          	andi	s2,s2,511
    80001150:	090e                	slli	s2,s2,0x3
    80001152:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001154:	00093483          	ld	s1,0(s2)
    80001158:	0014f793          	andi	a5,s1,1
    8000115c:	dfd5                	beqz	a5,80001118 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000115e:	80a9                	srli	s1,s1,0xa
    80001160:	04b2                	slli	s1,s1,0xc
    80001162:	b7c5                	j	80001142 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001164:	00c9d513          	srli	a0,s3,0xc
    80001168:	1ff57513          	andi	a0,a0,511
    8000116c:	050e                	slli	a0,a0,0x3
    8000116e:	9526                	add	a0,a0,s1
}
    80001170:	70e2                	ld	ra,56(sp)
    80001172:	7442                	ld	s0,48(sp)
    80001174:	74a2                	ld	s1,40(sp)
    80001176:	7902                	ld	s2,32(sp)
    80001178:	69e2                	ld	s3,24(sp)
    8000117a:	6a42                	ld	s4,16(sp)
    8000117c:	6aa2                	ld	s5,8(sp)
    8000117e:	6b02                	ld	s6,0(sp)
    80001180:	6121                	addi	sp,sp,64
    80001182:	8082                	ret
        return 0;
    80001184:	4501                	li	a0,0
    80001186:	b7ed                	j	80001170 <walk+0x8e>

0000000080001188 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001188:	57fd                	li	a5,-1
    8000118a:	83e9                	srli	a5,a5,0x1a
    8000118c:	00b7f463          	bgeu	a5,a1,80001194 <walkaddr+0xc>
    return 0;
    80001190:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001192:	8082                	ret
{
    80001194:	1141                	addi	sp,sp,-16
    80001196:	e406                	sd	ra,8(sp)
    80001198:	e022                	sd	s0,0(sp)
    8000119a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000119c:	4601                	li	a2,0
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	f44080e7          	jalr	-188(ra) # 800010e2 <walk>
  if(pte == 0)
    800011a6:	c105                	beqz	a0,800011c6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011a8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011aa:	0117f693          	andi	a3,a5,17
    800011ae:	4745                	li	a4,17
    return 0;
    800011b0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011b2:	00e68663          	beq	a3,a4,800011be <walkaddr+0x36>
}
    800011b6:	60a2                	ld	ra,8(sp)
    800011b8:	6402                	ld	s0,0(sp)
    800011ba:	0141                	addi	sp,sp,16
    800011bc:	8082                	ret
  pa = PTE2PA(*pte);
    800011be:	00a7d513          	srli	a0,a5,0xa
    800011c2:	0532                	slli	a0,a0,0xc
  return pa;
    800011c4:	bfcd                	j	800011b6 <walkaddr+0x2e>
    return 0;
    800011c6:	4501                	li	a0,0
    800011c8:	b7fd                	j	800011b6 <walkaddr+0x2e>

00000000800011ca <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011ca:	1101                	addi	sp,sp,-32
    800011cc:	ec06                	sd	ra,24(sp)
    800011ce:	e822                	sd	s0,16(sp)
    800011d0:	e426                	sd	s1,8(sp)
    800011d2:	e04a                	sd	s2,0(sp)
    800011d4:	1000                	addi	s0,sp,32
    800011d6:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800011d8:	1552                	slli	a0,a0,0x34
    800011da:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  //pte = walk(kernel_pagetable, va, 0);
  struct proc *p=myproc();
    800011de:	00001097          	auipc	ra,0x1
    800011e2:	900080e7          	jalr	-1792(ra) # 80001ade <myproc>
  pte=walk(p->kpagetable,va,0);
    800011e6:	4601                	li	a2,0
    800011e8:	85a6                	mv	a1,s1
    800011ea:	6d28                	ld	a0,88(a0)
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	ef6080e7          	jalr	-266(ra) # 800010e2 <walk>
  if(pte == 0)
    800011f4:	cd11                	beqz	a0,80001210 <kvmpa+0x46>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011f6:	6108                	ld	a0,0(a0)
    800011f8:	00157793          	andi	a5,a0,1
    800011fc:	c395                	beqz	a5,80001220 <kvmpa+0x56>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011fe:	8129                	srli	a0,a0,0xa
    80001200:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001202:	954a                	add	a0,a0,s2
    80001204:	60e2                	ld	ra,24(sp)
    80001206:	6442                	ld	s0,16(sp)
    80001208:	64a2                	ld	s1,8(sp)
    8000120a:	6902                	ld	s2,0(sp)
    8000120c:	6105                	addi	sp,sp,32
    8000120e:	8082                	ret
    panic("kvmpa");
    80001210:	00007517          	auipc	a0,0x7
    80001214:	f0050513          	addi	a0,a0,-256 # 80008110 <digits+0xd0>
    80001218:	fffff097          	auipc	ra,0xfffff
    8000121c:	32a080e7          	jalr	810(ra) # 80000542 <panic>
    panic("kvmpa");
    80001220:	00007517          	auipc	a0,0x7
    80001224:	ef050513          	addi	a0,a0,-272 # 80008110 <digits+0xd0>
    80001228:	fffff097          	auipc	ra,0xfffff
    8000122c:	31a080e7          	jalr	794(ra) # 80000542 <panic>

0000000080001230 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001230:	715d                	addi	sp,sp,-80
    80001232:	e486                	sd	ra,72(sp)
    80001234:	e0a2                	sd	s0,64(sp)
    80001236:	fc26                	sd	s1,56(sp)
    80001238:	f84a                	sd	s2,48(sp)
    8000123a:	f44e                	sd	s3,40(sp)
    8000123c:	f052                	sd	s4,32(sp)
    8000123e:	ec56                	sd	s5,24(sp)
    80001240:	e85a                	sd	s6,16(sp)
    80001242:	e45e                	sd	s7,8(sp)
    80001244:	0880                	addi	s0,sp,80
    80001246:	8aaa                	mv	s5,a0
    80001248:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000124a:	777d                	lui	a4,0xfffff
    8000124c:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001250:	167d                	addi	a2,a2,-1
    80001252:	00b609b3          	add	s3,a2,a1
    80001256:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000125a:	893e                	mv	s2,a5
    8000125c:	40f68a33          	sub	s4,a3,a5
    //if(*pte & PTE_V)
      //panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001260:	6b85                	lui	s7,0x1
    80001262:	a011                	j	80001266 <mappages+0x36>
    80001264:	995e                	add	s2,s2,s7
  for(;;){
    80001266:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000126a:	4605                	li	a2,1
    8000126c:	85ca                	mv	a1,s2
    8000126e:	8556                	mv	a0,s5
    80001270:	00000097          	auipc	ra,0x0
    80001274:	e72080e7          	jalr	-398(ra) # 800010e2 <walk>
    80001278:	cd01                	beqz	a0,80001290 <mappages+0x60>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000127a:	80b1                	srli	s1,s1,0xc
    8000127c:	04aa                	slli	s1,s1,0xa
    8000127e:	0164e4b3          	or	s1,s1,s6
    80001282:	0014e493          	ori	s1,s1,1
    80001286:	e104                	sd	s1,0(a0)
    if(a == last)
    80001288:	fd391ee3          	bne	s2,s3,80001264 <mappages+0x34>
    pa += PGSIZE;
  }
  return 0;
    8000128c:	4501                	li	a0,0
    8000128e:	a011                	j	80001292 <mappages+0x62>
      return -1;
    80001290:	557d                	li	a0,-1
}
    80001292:	60a6                	ld	ra,72(sp)
    80001294:	6406                	ld	s0,64(sp)
    80001296:	74e2                	ld	s1,56(sp)
    80001298:	7942                	ld	s2,48(sp)
    8000129a:	79a2                	ld	s3,40(sp)
    8000129c:	7a02                	ld	s4,32(sp)
    8000129e:	6ae2                	ld	s5,24(sp)
    800012a0:	6b42                	ld	s6,16(sp)
    800012a2:	6ba2                	ld	s7,8(sp)
    800012a4:	6161                	addi	sp,sp,80
    800012a6:	8082                	ret

00000000800012a8 <kvmmap>:
{
    800012a8:	1141                	addi	sp,sp,-16
    800012aa:	e406                	sd	ra,8(sp)
    800012ac:	e022                	sd	s0,0(sp)
    800012ae:	0800                	addi	s0,sp,16
    800012b0:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012b2:	86ae                	mv	a3,a1
    800012b4:	85aa                	mv	a1,a0
    800012b6:	00008517          	auipc	a0,0x8
    800012ba:	d5a53503          	ld	a0,-678(a0) # 80009010 <kernel_pagetable>
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f72080e7          	jalr	-142(ra) # 80001230 <mappages>
    800012c6:	e509                	bnez	a0,800012d0 <kvmmap+0x28>
}
    800012c8:	60a2                	ld	ra,8(sp)
    800012ca:	6402                	ld	s0,0(sp)
    800012cc:	0141                	addi	sp,sp,16
    800012ce:	8082                	ret
    panic("kvmmap");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e4850513          	addi	a0,a0,-440 # 80008118 <digits+0xd8>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	26a080e7          	jalr	618(ra) # 80000542 <panic>

00000000800012e0 <kvminit>:
{
    800012e0:	1101                	addi	sp,sp,-32
    800012e2:	ec06                	sd	ra,24(sp)
    800012e4:	e822                	sd	s0,16(sp)
    800012e6:	e426                	sd	s1,8(sp)
    800012e8:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	824080e7          	jalr	-2012(ra) # 80000b0e <kalloc>
    800012f2:	00008797          	auipc	a5,0x8
    800012f6:	d0a7bf23          	sd	a0,-738(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012fa:	6605                	lui	a2,0x1
    800012fc:	4581                	li	a1,0
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	9fc080e7          	jalr	-1540(ra) # 80000cfa <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001306:	4699                	li	a3,6
    80001308:	6605                	lui	a2,0x1
    8000130a:	100005b7          	lui	a1,0x10000
    8000130e:	10000537          	lui	a0,0x10000
    80001312:	00000097          	auipc	ra,0x0
    80001316:	f96080e7          	jalr	-106(ra) # 800012a8 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000131a:	4699                	li	a3,6
    8000131c:	6605                	lui	a2,0x1
    8000131e:	100015b7          	lui	a1,0x10001
    80001322:	10001537          	lui	a0,0x10001
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f82080e7          	jalr	-126(ra) # 800012a8 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000132e:	4699                	li	a3,6
    80001330:	6641                	lui	a2,0x10
    80001332:	020005b7          	lui	a1,0x2000
    80001336:	02000537          	lui	a0,0x2000
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f6e080e7          	jalr	-146(ra) # 800012a8 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001342:	4699                	li	a3,6
    80001344:	00400637          	lui	a2,0x400
    80001348:	0c0005b7          	lui	a1,0xc000
    8000134c:	0c000537          	lui	a0,0xc000
    80001350:	00000097          	auipc	ra,0x0
    80001354:	f58080e7          	jalr	-168(ra) # 800012a8 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001358:	00007497          	auipc	s1,0x7
    8000135c:	ca848493          	addi	s1,s1,-856 # 80008000 <etext>
    80001360:	46a9                	li	a3,10
    80001362:	80007617          	auipc	a2,0x80007
    80001366:	c9e60613          	addi	a2,a2,-866 # 8000 <_entry-0x7fff8000>
    8000136a:	4585                	li	a1,1
    8000136c:	05fe                	slli	a1,a1,0x1f
    8000136e:	852e                	mv	a0,a1
    80001370:	00000097          	auipc	ra,0x0
    80001374:	f38080e7          	jalr	-200(ra) # 800012a8 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001378:	4699                	li	a3,6
    8000137a:	4645                	li	a2,17
    8000137c:	066e                	slli	a2,a2,0x1b
    8000137e:	8e05                	sub	a2,a2,s1
    80001380:	85a6                	mv	a1,s1
    80001382:	8526                	mv	a0,s1
    80001384:	00000097          	auipc	ra,0x0
    80001388:	f24080e7          	jalr	-220(ra) # 800012a8 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000138c:	46a9                	li	a3,10
    8000138e:	6605                	lui	a2,0x1
    80001390:	00006597          	auipc	a1,0x6
    80001394:	c7058593          	addi	a1,a1,-912 # 80007000 <_trampoline>
    80001398:	04000537          	lui	a0,0x4000
    8000139c:	157d                	addi	a0,a0,-1
    8000139e:	0532                	slli	a0,a0,0xc
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	f08080e7          	jalr	-248(ra) # 800012a8 <kvmmap>
}
    800013a8:	60e2                	ld	ra,24(sp)
    800013aa:	6442                	ld	s0,16(sp)
    800013ac:	64a2                	ld	s1,8(sp)
    800013ae:	6105                	addi	sp,sp,32
    800013b0:	8082                	ret

00000000800013b2 <ukvmmap>:
{
    800013b2:	1141                	addi	sp,sp,-16
    800013b4:	e406                	sd	ra,8(sp)
    800013b6:	e022                	sd	s0,0(sp)
    800013b8:	0800                	addi	s0,sp,16
    800013ba:	87b6                	mv	a5,a3
  if(mappages(kpgtbl,va,sz,pa,perm)!=0)
    800013bc:	86b2                	mv	a3,a2
    800013be:	863e                	mv	a2,a5
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	e70080e7          	jalr	-400(ra) # 80001230 <mappages>
    800013c8:	e509                	bnez	a0,800013d2 <ukvmmap+0x20>
}
    800013ca:	60a2                	ld	ra,8(sp)
    800013cc:	6402                	ld	s0,0(sp)
    800013ce:	0141                	addi	sp,sp,16
    800013d0:	8082                	ret
    panic("ukvmmap");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d4e50513          	addi	a0,a0,-690 # 80008120 <digits+0xe0>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	168080e7          	jalr	360(ra) # 80000542 <panic>

00000000800013e2 <ukvminit>:
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	e04a                	sd	s2,0(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t kpgtbl=(pagetable_t)kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	720080e7          	jalr	1824(ra) # 80000b0e <kalloc>
    800013f6:	84aa                	mv	s1,a0
  memset(kpgtbl,0,PGSIZE);
    800013f8:	6605                	lui	a2,0x1
    800013fa:	4581                	li	a1,0
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	8fe080e7          	jalr	-1794(ra) # 80000cfa <memset>
  ukvmmap(kpgtbl,UART0,UART0,PGSIZE,PTE_R|PTE_W);
    80001404:	4719                	li	a4,6
    80001406:	6685                	lui	a3,0x1
    80001408:	10000637          	lui	a2,0x10000
    8000140c:	100005b7          	lui	a1,0x10000
    80001410:	8526                	mv	a0,s1
    80001412:	00000097          	auipc	ra,0x0
    80001416:	fa0080e7          	jalr	-96(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,VIRTIO0,VIRTIO0,PGSIZE,PTE_R|PTE_W);
    8000141a:	4719                	li	a4,6
    8000141c:	6685                	lui	a3,0x1
    8000141e:	10001637          	lui	a2,0x10001
    80001422:	100015b7          	lui	a1,0x10001
    80001426:	8526                	mv	a0,s1
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	f8a080e7          	jalr	-118(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,CLINT,CLINT,0x10000,PTE_R|PTE_W);
    80001430:	4719                	li	a4,6
    80001432:	66c1                	lui	a3,0x10
    80001434:	02000637          	lui	a2,0x2000
    80001438:	020005b7          	lui	a1,0x2000
    8000143c:	8526                	mv	a0,s1
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	f74080e7          	jalr	-140(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,PLIC,PLIC,0X400000,PTE_R|PTE_W);
    80001446:	4719                	li	a4,6
    80001448:	004006b7          	lui	a3,0x400
    8000144c:	0c000637          	lui	a2,0xc000
    80001450:	0c0005b7          	lui	a1,0xc000
    80001454:	8526                	mv	a0,s1
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	f5c080e7          	jalr	-164(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,KERNBASE,KERNBASE,(uint64)etext-KERNBASE,PTE_R|PTE_X);
    8000145e:	00007917          	auipc	s2,0x7
    80001462:	ba290913          	addi	s2,s2,-1118 # 80008000 <etext>
    80001466:	4729                	li	a4,10
    80001468:	80007697          	auipc	a3,0x80007
    8000146c:	b9868693          	addi	a3,a3,-1128 # 8000 <_entry-0x7fff8000>
    80001470:	4605                	li	a2,1
    80001472:	067e                	slli	a2,a2,0x1f
    80001474:	85b2                	mv	a1,a2
    80001476:	8526                	mv	a0,s1
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	f3a080e7          	jalr	-198(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,(uint64)etext,(uint64)etext,PHYSTOP-(uint64)etext,PTE_R|PTE_W);
    80001480:	4719                	li	a4,6
    80001482:	46c5                	li	a3,17
    80001484:	06ee                	slli	a3,a3,0x1b
    80001486:	412686b3          	sub	a3,a3,s2
    8000148a:	864a                	mv	a2,s2
    8000148c:	85ca                	mv	a1,s2
    8000148e:	8526                	mv	a0,s1
    80001490:	00000097          	auipc	ra,0x0
    80001494:	f22080e7          	jalr	-222(ra) # 800013b2 <ukvmmap>
  ukvmmap(kpgtbl,TRAMPOLINE,(uint64)trampoline,PGSIZE,PTE_R|PTE_X);
    80001498:	4729                	li	a4,10
    8000149a:	6685                	lui	a3,0x1
    8000149c:	00006617          	auipc	a2,0x6
    800014a0:	b6460613          	addi	a2,a2,-1180 # 80007000 <_trampoline>
    800014a4:	040005b7          	lui	a1,0x4000
    800014a8:	15fd                	addi	a1,a1,-1
    800014aa:	05b2                	slli	a1,a1,0xc
    800014ac:	8526                	mv	a0,s1
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f04080e7          	jalr	-252(ra) # 800013b2 <ukvmmap>
}
    800014b6:	8526                	mv	a0,s1
    800014b8:	60e2                	ld	ra,24(sp)
    800014ba:	6442                	ld	s0,16(sp)
    800014bc:	64a2                	ld	s1,8(sp)
    800014be:	6902                	ld	s2,0(sp)
    800014c0:	6105                	addi	sp,sp,32
    800014c2:	8082                	ret

00000000800014c4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014c4:	715d                	addi	sp,sp,-80
    800014c6:	e486                	sd	ra,72(sp)
    800014c8:	e0a2                	sd	s0,64(sp)
    800014ca:	fc26                	sd	s1,56(sp)
    800014cc:	f84a                	sd	s2,48(sp)
    800014ce:	f44e                	sd	s3,40(sp)
    800014d0:	f052                	sd	s4,32(sp)
    800014d2:	ec56                	sd	s5,24(sp)
    800014d4:	e85a                	sd	s6,16(sp)
    800014d6:	e45e                	sd	s7,8(sp)
    800014d8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800014da:	03459793          	slli	a5,a1,0x34
    800014de:	e795                	bnez	a5,8000150a <uvmunmap+0x46>
    800014e0:	8a2a                	mv	s4,a0
    800014e2:	892e                	mv	s2,a1
    800014e4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014e6:	0632                	slli	a2,a2,0xc
    800014e8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800014ec:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014ee:	6b05                	lui	s6,0x1
    800014f0:	0535e463          	bltu	a1,s3,80001538 <uvmunmap+0x74>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800014f4:	60a6                	ld	ra,72(sp)
    800014f6:	6406                	ld	s0,64(sp)
    800014f8:	74e2                	ld	s1,56(sp)
    800014fa:	7942                	ld	s2,48(sp)
    800014fc:	79a2                	ld	s3,40(sp)
    800014fe:	7a02                	ld	s4,32(sp)
    80001500:	6ae2                	ld	s5,24(sp)
    80001502:	6b42                	ld	s6,16(sp)
    80001504:	6ba2                	ld	s7,8(sp)
    80001506:	6161                	addi	sp,sp,80
    80001508:	8082                	ret
    panic("uvmunmap: not aligned");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c1e50513          	addi	a0,a0,-994 # 80008128 <digits+0xe8>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	030080e7          	jalr	48(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c2650513          	addi	a0,a0,-986 # 80008140 <digits+0x100>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	020080e7          	jalr	32(ra) # 80000542 <panic>
    if(do_free){
    8000152a:	040a9063          	bnez	s5,8000156a <uvmunmap+0xa6>
    *pte = 0;
    8000152e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001532:	995a                	add	s2,s2,s6
    80001534:	fd3970e3          	bgeu	s2,s3,800014f4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001538:	4601                	li	a2,0
    8000153a:	85ca                	mv	a1,s2
    8000153c:	8552                	mv	a0,s4
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	ba4080e7          	jalr	-1116(ra) # 800010e2 <walk>
    80001546:	84aa                	mv	s1,a0
    80001548:	d969                	beqz	a0,8000151a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000154a:	611c                	ld	a5,0(a0)
    8000154c:	0017f713          	andi	a4,a5,1
    80001550:	ff69                	bnez	a4,8000152a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001552:	3ff7f713          	andi	a4,a5,1023
    80001556:	fd771ae3          	bne	a4,s7,8000152a <uvmunmap+0x66>
      panic("uvmunmap: not a leaf");
    8000155a:	00007517          	auipc	a0,0x7
    8000155e:	bf650513          	addi	a0,a0,-1034 # 80008150 <digits+0x110>
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	fe0080e7          	jalr	-32(ra) # 80000542 <panic>
      uint64 pa = PTE2PA(*pte);
    8000156a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000156c:	00c79513          	slli	a0,a5,0xc
    80001570:	fffff097          	auipc	ra,0xfffff
    80001574:	4a2080e7          	jalr	1186(ra) # 80000a12 <kfree>
    80001578:	bf5d                	j	8000152e <uvmunmap+0x6a>

000000008000157a <upg2ukpg>:
{
    8000157a:	7139                	addi	sp,sp,-64
    8000157c:	fc06                	sd	ra,56(sp)
    8000157e:	f822                	sd	s0,48(sp)
    80001580:	f426                	sd	s1,40(sp)
    80001582:	f04a                	sd	s2,32(sp)
    80001584:	ec4e                	sd	s3,24(sp)
    80001586:	e852                	sd	s4,16(sp)
    80001588:	e456                	sd	s5,8(sp)
    8000158a:	0080                	addi	s0,sp,64
  uint64 start_page=PGROUNDUP(start);
    8000158c:	6a05                	lui	s4,0x1
    8000158e:	1a7d                	addi	s4,s4,-1
    80001590:	9652                	add	a2,a2,s4
    80001592:	7a7d                	lui	s4,0xfffff
    80001594:	01467a33          	and	s4,a2,s4
  for(i=start_page;i<end;i+=PGSIZE)
    80001598:	08da7863          	bgeu	s4,a3,80001628 <upg2ukpg+0xae>
    8000159c:	8aaa                	mv	s5,a0
    8000159e:	89ae                	mv	s3,a1
    800015a0:	8936                	mv	s2,a3
    800015a2:	84d2                	mv	s1,s4
    if((pte=walk(pagetable,i,0))==0)
    800015a4:	4601                	li	a2,0
    800015a6:	85a6                	mv	a1,s1
    800015a8:	8556                	mv	a0,s5
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	b38080e7          	jalr	-1224(ra) # 800010e2 <walk>
    800015b2:	c51d                	beqz	a0,800015e0 <upg2ukpg+0x66>
    if((*pte & PTE_V)==0)
    800015b4:	6118                	ld	a4,0(a0)
    800015b6:	00177793          	andi	a5,a4,1
    800015ba:	cb9d                	beqz	a5,800015f0 <upg2ukpg+0x76>
    pa=PTE2PA(*pte);
    800015bc:	00a75693          	srli	a3,a4,0xa
    if(mappages(kpagetable,i,PGSIZE,pa,flags)!=0)
    800015c0:	3ef77713          	andi	a4,a4,1007
    800015c4:	06b2                	slli	a3,a3,0xc
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85a6                	mv	a1,s1
    800015ca:	854e                	mv	a0,s3
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	c64080e7          	jalr	-924(ra) # 80001230 <mappages>
    800015d4:	e515                	bnez	a0,80001600 <upg2ukpg+0x86>
  for(i=start_page;i<end;i+=PGSIZE)
    800015d6:	6785                	lui	a5,0x1
    800015d8:	94be                	add	s1,s1,a5
    800015da:	fd24e5e3          	bltu	s1,s2,800015a4 <upg2ukpg+0x2a>
    800015de:	a825                	j	80001616 <upg2ukpg+0x9c>
       panic("upg2ukpg: pte should exist");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	b8850513          	addi	a0,a0,-1144 # 80008168 <digits+0x128>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f5a080e7          	jalr	-166(ra) # 80000542 <panic>
       panic("upg2ukpg: page not present");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f4a080e7          	jalr	-182(ra) # 80000542 <panic>
  uvmunmap(kpagetable,start_page,(i-start_page)/PGSIZE,0);
    80001600:	41448633          	sub	a2,s1,s4
    80001604:	4681                	li	a3,0
    80001606:	8231                	srli	a2,a2,0xc
    80001608:	85d2                	mv	a1,s4
    8000160a:	854e                	mv	a0,s3
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	eb8080e7          	jalr	-328(ra) # 800014c4 <uvmunmap>
  return -1;
    80001614:	557d                	li	a0,-1
}
    80001616:	70e2                	ld	ra,56(sp)
    80001618:	7442                	ld	s0,48(sp)
    8000161a:	74a2                	ld	s1,40(sp)
    8000161c:	7902                	ld	s2,32(sp)
    8000161e:	69e2                	ld	s3,24(sp)
    80001620:	6a42                	ld	s4,16(sp)
    80001622:	6aa2                	ld	s5,8(sp)
    80001624:	6121                	addi	sp,sp,64
    80001626:	8082                	ret
  return 0;
    80001628:	4501                	li	a0,0
    8000162a:	b7f5                	j	80001616 <upg2ukpg+0x9c>

000000008000162c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000162c:	1101                	addi	sp,sp,-32
    8000162e:	ec06                	sd	ra,24(sp)
    80001630:	e822                	sd	s0,16(sp)
    80001632:	e426                	sd	s1,8(sp)
    80001634:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	4d8080e7          	jalr	1240(ra) # 80000b0e <kalloc>
    8000163e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001640:	c519                	beqz	a0,8000164e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001642:	6605                	lui	a2,0x1
    80001644:	4581                	li	a1,0
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	6b4080e7          	jalr	1716(ra) # 80000cfa <memset>
  return pagetable;
}
    8000164e:	8526                	mv	a0,s1
    80001650:	60e2                	ld	ra,24(sp)
    80001652:	6442                	ld	s0,16(sp)
    80001654:	64a2                	ld	s1,8(sp)
    80001656:	6105                	addi	sp,sp,32
    80001658:	8082                	ret

000000008000165a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000165a:	7179                	addi	sp,sp,-48
    8000165c:	f406                	sd	ra,40(sp)
    8000165e:	f022                	sd	s0,32(sp)
    80001660:	ec26                	sd	s1,24(sp)
    80001662:	e84a                	sd	s2,16(sp)
    80001664:	e44e                	sd	s3,8(sp)
    80001666:	e052                	sd	s4,0(sp)
    80001668:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000166a:	6785                	lui	a5,0x1
    8000166c:	04f67863          	bgeu	a2,a5,800016bc <uvminit+0x62>
    80001670:	8a2a                	mv	s4,a0
    80001672:	89ae                	mv	s3,a1
    80001674:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	498080e7          	jalr	1176(ra) # 80000b0e <kalloc>
    8000167e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001680:	6605                	lui	a2,0x1
    80001682:	4581                	li	a1,0
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	676080e7          	jalr	1654(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000168c:	4779                	li	a4,30
    8000168e:	86ca                	mv	a3,s2
    80001690:	6605                	lui	a2,0x1
    80001692:	4581                	li	a1,0
    80001694:	8552                	mv	a0,s4
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	b9a080e7          	jalr	-1126(ra) # 80001230 <mappages>
  memmove(mem, src, sz);
    8000169e:	8626                	mv	a2,s1
    800016a0:	85ce                	mv	a1,s3
    800016a2:	854a                	mv	a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	6b2080e7          	jalr	1714(ra) # 80000d56 <memmove>
}
    800016ac:	70a2                	ld	ra,40(sp)
    800016ae:	7402                	ld	s0,32(sp)
    800016b0:	64e2                	ld	s1,24(sp)
    800016b2:	6942                	ld	s2,16(sp)
    800016b4:	69a2                	ld	s3,8(sp)
    800016b6:	6a02                	ld	s4,0(sp)
    800016b8:	6145                	addi	sp,sp,48
    800016ba:	8082                	ret
    panic("inituvm: more than a page");
    800016bc:	00007517          	auipc	a0,0x7
    800016c0:	aec50513          	addi	a0,a0,-1300 # 800081a8 <digits+0x168>
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	e7e080e7          	jalr	-386(ra) # 80000542 <panic>

00000000800016cc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800016cc:	1101                	addi	sp,sp,-32
    800016ce:	ec06                	sd	ra,24(sp)
    800016d0:	e822                	sd	s0,16(sp)
    800016d2:	e426                	sd	s1,8(sp)
    800016d4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800016d6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800016d8:	00b67d63          	bgeu	a2,a1,800016f2 <uvmdealloc+0x26>
    800016dc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800016de:	6785                	lui	a5,0x1
    800016e0:	17fd                	addi	a5,a5,-1
    800016e2:	00f60733          	add	a4,a2,a5
    800016e6:	767d                	lui	a2,0xfffff
    800016e8:	8f71                	and	a4,a4,a2
    800016ea:	97ae                	add	a5,a5,a1
    800016ec:	8ff1                	and	a5,a5,a2
    800016ee:	00f76863          	bltu	a4,a5,800016fe <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800016f2:	8526                	mv	a0,s1
    800016f4:	60e2                	ld	ra,24(sp)
    800016f6:	6442                	ld	s0,16(sp)
    800016f8:	64a2                	ld	s1,8(sp)
    800016fa:	6105                	addi	sp,sp,32
    800016fc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800016fe:	8f99                	sub	a5,a5,a4
    80001700:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001702:	4685                	li	a3,1
    80001704:	0007861b          	sext.w	a2,a5
    80001708:	85ba                	mv	a1,a4
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	dba080e7          	jalr	-582(ra) # 800014c4 <uvmunmap>
    80001712:	b7c5                	j	800016f2 <uvmdealloc+0x26>

0000000080001714 <uvmalloc>:
  if(newsz < oldsz)
    80001714:	0ab66163          	bltu	a2,a1,800017b6 <uvmalloc+0xa2>
{
    80001718:	7139                	addi	sp,sp,-64
    8000171a:	fc06                	sd	ra,56(sp)
    8000171c:	f822                	sd	s0,48(sp)
    8000171e:	f426                	sd	s1,40(sp)
    80001720:	f04a                	sd	s2,32(sp)
    80001722:	ec4e                	sd	s3,24(sp)
    80001724:	e852                	sd	s4,16(sp)
    80001726:	e456                	sd	s5,8(sp)
    80001728:	0080                	addi	s0,sp,64
    8000172a:	8aaa                	mv	s5,a0
    8000172c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000172e:	6985                	lui	s3,0x1
    80001730:	19fd                	addi	s3,s3,-1
    80001732:	95ce                	add	a1,a1,s3
    80001734:	79fd                	lui	s3,0xfffff
    80001736:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000173a:	08c9f063          	bgeu	s3,a2,800017ba <uvmalloc+0xa6>
    8000173e:	894e                	mv	s2,s3
    mem = kalloc();
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	3ce080e7          	jalr	974(ra) # 80000b0e <kalloc>
    80001748:	84aa                	mv	s1,a0
    if(mem == 0){
    8000174a:	c51d                	beqz	a0,80001778 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000174c:	6605                	lui	a2,0x1
    8000174e:	4581                	li	a1,0
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	5aa080e7          	jalr	1450(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001758:	4779                	li	a4,30
    8000175a:	86a6                	mv	a3,s1
    8000175c:	6605                	lui	a2,0x1
    8000175e:	85ca                	mv	a1,s2
    80001760:	8556                	mv	a0,s5
    80001762:	00000097          	auipc	ra,0x0
    80001766:	ace080e7          	jalr	-1330(ra) # 80001230 <mappages>
    8000176a:	e905                	bnez	a0,8000179a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000176c:	6785                	lui	a5,0x1
    8000176e:	993e                	add	s2,s2,a5
    80001770:	fd4968e3          	bltu	s2,s4,80001740 <uvmalloc+0x2c>
  return newsz;
    80001774:	8552                	mv	a0,s4
    80001776:	a809                	j	80001788 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001778:	864e                	mv	a2,s3
    8000177a:	85ca                	mv	a1,s2
    8000177c:	8556                	mv	a0,s5
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	f4e080e7          	jalr	-178(ra) # 800016cc <uvmdealloc>
      return 0;
    80001786:	4501                	li	a0,0
}
    80001788:	70e2                	ld	ra,56(sp)
    8000178a:	7442                	ld	s0,48(sp)
    8000178c:	74a2                	ld	s1,40(sp)
    8000178e:	7902                	ld	s2,32(sp)
    80001790:	69e2                	ld	s3,24(sp)
    80001792:	6a42                	ld	s4,16(sp)
    80001794:	6aa2                	ld	s5,8(sp)
    80001796:	6121                	addi	sp,sp,64
    80001798:	8082                	ret
      kfree(mem);
    8000179a:	8526                	mv	a0,s1
    8000179c:	fffff097          	auipc	ra,0xfffff
    800017a0:	276080e7          	jalr	630(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800017a4:	864e                	mv	a2,s3
    800017a6:	85ca                	mv	a1,s2
    800017a8:	8556                	mv	a0,s5
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	f22080e7          	jalr	-222(ra) # 800016cc <uvmdealloc>
      return 0;
    800017b2:	4501                	li	a0,0
    800017b4:	bfd1                	j	80001788 <uvmalloc+0x74>
    return oldsz;
    800017b6:	852e                	mv	a0,a1
}
    800017b8:	8082                	ret
  return newsz;
    800017ba:	8532                	mv	a0,a2
    800017bc:	b7f1                	j	80001788 <uvmalloc+0x74>

00000000800017be <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800017be:	7179                	addi	sp,sp,-48
    800017c0:	f406                	sd	ra,40(sp)
    800017c2:	f022                	sd	s0,32(sp)
    800017c4:	ec26                	sd	s1,24(sp)
    800017c6:	e84a                	sd	s2,16(sp)
    800017c8:	e44e                	sd	s3,8(sp)
    800017ca:	e052                	sd	s4,0(sp)
    800017cc:	1800                	addi	s0,sp,48
    800017ce:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800017d0:	84aa                	mv	s1,a0
    800017d2:	6905                	lui	s2,0x1
    800017d4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800017d6:	4985                	li	s3,1
    800017d8:	a021                	j	800017e0 <freewalk+0x22>
  for(int i = 0; i < 512; i++){
    800017da:	04a1                	addi	s1,s1,8
    800017dc:	03248063          	beq	s1,s2,800017fc <freewalk+0x3e>
    pte_t pte = pagetable[i];
    800017e0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800017e2:	00f57793          	andi	a5,a0,15
    800017e6:	ff379ae3          	bne	a5,s3,800017da <freewalk+0x1c>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800017ea:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800017ec:	0532                	slli	a0,a0,0xc
    800017ee:	00000097          	auipc	ra,0x0
    800017f2:	fd0080e7          	jalr	-48(ra) # 800017be <freewalk>
      pagetable[i] = 0;
    800017f6:	0004b023          	sd	zero,0(s1)
    800017fa:	b7c5                	j	800017da <freewalk+0x1c>
    } else if(pte & PTE_V){
      //panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
    800017fc:	8552                	mv	a0,s4
    800017fe:	fffff097          	auipc	ra,0xfffff
    80001802:	214080e7          	jalr	532(ra) # 80000a12 <kfree>
}
    80001806:	70a2                	ld	ra,40(sp)
    80001808:	7402                	ld	s0,32(sp)
    8000180a:	64e2                	ld	s1,24(sp)
    8000180c:	6942                	ld	s2,16(sp)
    8000180e:	69a2                	ld	s3,8(sp)
    80001810:	6a02                	ld	s4,0(sp)
    80001812:	6145                	addi	sp,sp,48
    80001814:	8082                	ret

0000000080001816 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001816:	1101                	addi	sp,sp,-32
    80001818:	ec06                	sd	ra,24(sp)
    8000181a:	e822                	sd	s0,16(sp)
    8000181c:	e426                	sd	s1,8(sp)
    8000181e:	1000                	addi	s0,sp,32
    80001820:	84aa                	mv	s1,a0
  if(sz > 0)
    80001822:	e999                	bnez	a1,80001838 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001824:	8526                	mv	a0,s1
    80001826:	00000097          	auipc	ra,0x0
    8000182a:	f98080e7          	jalr	-104(ra) # 800017be <freewalk>
}
    8000182e:	60e2                	ld	ra,24(sp)
    80001830:	6442                	ld	s0,16(sp)
    80001832:	64a2                	ld	s1,8(sp)
    80001834:	6105                	addi	sp,sp,32
    80001836:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001838:	6605                	lui	a2,0x1
    8000183a:	167d                	addi	a2,a2,-1
    8000183c:	962e                	add	a2,a2,a1
    8000183e:	4685                	li	a3,1
    80001840:	8231                	srli	a2,a2,0xc
    80001842:	4581                	li	a1,0
    80001844:	00000097          	auipc	ra,0x0
    80001848:	c80080e7          	jalr	-896(ra) # 800014c4 <uvmunmap>
    8000184c:	bfe1                	j	80001824 <uvmfree+0xe>

000000008000184e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000184e:	c679                	beqz	a2,8000191c <uvmcopy+0xce>
{
    80001850:	715d                	addi	sp,sp,-80
    80001852:	e486                	sd	ra,72(sp)
    80001854:	e0a2                	sd	s0,64(sp)
    80001856:	fc26                	sd	s1,56(sp)
    80001858:	f84a                	sd	s2,48(sp)
    8000185a:	f44e                	sd	s3,40(sp)
    8000185c:	f052                	sd	s4,32(sp)
    8000185e:	ec56                	sd	s5,24(sp)
    80001860:	e85a                	sd	s6,16(sp)
    80001862:	e45e                	sd	s7,8(sp)
    80001864:	0880                	addi	s0,sp,80
    80001866:	8b2a                	mv	s6,a0
    80001868:	8aae                	mv	s5,a1
    8000186a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000186c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000186e:	4601                	li	a2,0
    80001870:	85ce                	mv	a1,s3
    80001872:	855a                	mv	a0,s6
    80001874:	00000097          	auipc	ra,0x0
    80001878:	86e080e7          	jalr	-1938(ra) # 800010e2 <walk>
    8000187c:	c531                	beqz	a0,800018c8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000187e:	6118                	ld	a4,0(a0)
    80001880:	00177793          	andi	a5,a4,1
    80001884:	cbb1                	beqz	a5,800018d8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001886:	00a75593          	srli	a1,a4,0xa
    8000188a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000188e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	27c080e7          	jalr	636(ra) # 80000b0e <kalloc>
    8000189a:	892a                	mv	s2,a0
    8000189c:	c939                	beqz	a0,800018f2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000189e:	6605                	lui	a2,0x1
    800018a0:	85de                	mv	a1,s7
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	4b4080e7          	jalr	1204(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800018aa:	8726                	mv	a4,s1
    800018ac:	86ca                	mv	a3,s2
    800018ae:	6605                	lui	a2,0x1
    800018b0:	85ce                	mv	a1,s3
    800018b2:	8556                	mv	a0,s5
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	97c080e7          	jalr	-1668(ra) # 80001230 <mappages>
    800018bc:	e515                	bnez	a0,800018e8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800018be:	6785                	lui	a5,0x1
    800018c0:	99be                	add	s3,s3,a5
    800018c2:	fb49e6e3          	bltu	s3,s4,8000186e <uvmcopy+0x20>
    800018c6:	a081                	j	80001906 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800018c8:	00007517          	auipc	a0,0x7
    800018cc:	90050513          	addi	a0,a0,-1792 # 800081c8 <digits+0x188>
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	c72080e7          	jalr	-910(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    800018d8:	00007517          	auipc	a0,0x7
    800018dc:	91050513          	addi	a0,a0,-1776 # 800081e8 <digits+0x1a8>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	c62080e7          	jalr	-926(ra) # 80000542 <panic>
      kfree(mem);
    800018e8:	854a                	mv	a0,s2
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	128080e7          	jalr	296(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800018f2:	4685                	li	a3,1
    800018f4:	00c9d613          	srli	a2,s3,0xc
    800018f8:	4581                	li	a1,0
    800018fa:	8556                	mv	a0,s5
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	bc8080e7          	jalr	-1080(ra) # 800014c4 <uvmunmap>
  return -1;
    80001904:	557d                	li	a0,-1
}
    80001906:	60a6                	ld	ra,72(sp)
    80001908:	6406                	ld	s0,64(sp)
    8000190a:	74e2                	ld	s1,56(sp)
    8000190c:	7942                	ld	s2,48(sp)
    8000190e:	79a2                	ld	s3,40(sp)
    80001910:	7a02                	ld	s4,32(sp)
    80001912:	6ae2                	ld	s5,24(sp)
    80001914:	6b42                	ld	s6,16(sp)
    80001916:	6ba2                	ld	s7,8(sp)
    80001918:	6161                	addi	sp,sp,80
    8000191a:	8082                	ret
  return 0;
    8000191c:	4501                	li	a0,0
}
    8000191e:	8082                	ret

0000000080001920 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001920:	1141                	addi	sp,sp,-16
    80001922:	e406                	sd	ra,8(sp)
    80001924:	e022                	sd	s0,0(sp)
    80001926:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001928:	4601                	li	a2,0
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	7b8080e7          	jalr	1976(ra) # 800010e2 <walk>
  if(pte == 0)
    80001932:	c901                	beqz	a0,80001942 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001934:	611c                	ld	a5,0(a0)
    80001936:	9bbd                	andi	a5,a5,-17
    80001938:	e11c                	sd	a5,0(a0)
}
    8000193a:	60a2                	ld	ra,8(sp)
    8000193c:	6402                	ld	s0,0(sp)
    8000193e:	0141                	addi	sp,sp,16
    80001940:	8082                	ret
    panic("uvmclear");
    80001942:	00007517          	auipc	a0,0x7
    80001946:	8c650513          	addi	a0,a0,-1850 # 80008208 <digits+0x1c8>
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	bf8080e7          	jalr	-1032(ra) # 80000542 <panic>

0000000080001952 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001952:	c6bd                	beqz	a3,800019c0 <copyout+0x6e>
{
    80001954:	715d                	addi	sp,sp,-80
    80001956:	e486                	sd	ra,72(sp)
    80001958:	e0a2                	sd	s0,64(sp)
    8000195a:	fc26                	sd	s1,56(sp)
    8000195c:	f84a                	sd	s2,48(sp)
    8000195e:	f44e                	sd	s3,40(sp)
    80001960:	f052                	sd	s4,32(sp)
    80001962:	ec56                	sd	s5,24(sp)
    80001964:	e85a                	sd	s6,16(sp)
    80001966:	e45e                	sd	s7,8(sp)
    80001968:	e062                	sd	s8,0(sp)
    8000196a:	0880                	addi	s0,sp,80
    8000196c:	8b2a                	mv	s6,a0
    8000196e:	8c2e                	mv	s8,a1
    80001970:	8a32                	mv	s4,a2
    80001972:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001974:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001976:	6a85                	lui	s5,0x1
    80001978:	a015                	j	8000199c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000197a:	9562                	add	a0,a0,s8
    8000197c:	0004861b          	sext.w	a2,s1
    80001980:	85d2                	mv	a1,s4
    80001982:	41250533          	sub	a0,a0,s2
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	3d0080e7          	jalr	976(ra) # 80000d56 <memmove>

    len -= n;
    8000198e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001992:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001994:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001998:	02098263          	beqz	s3,800019bc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000199c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019a0:	85ca                	mv	a1,s2
    800019a2:	855a                	mv	a0,s6
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	7e4080e7          	jalr	2020(ra) # 80001188 <walkaddr>
    if(pa0 == 0)
    800019ac:	cd01                	beqz	a0,800019c4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800019ae:	418904b3          	sub	s1,s2,s8
    800019b2:	94d6                	add	s1,s1,s5
    if(n > len)
    800019b4:	fc99f3e3          	bgeu	s3,s1,8000197a <copyout+0x28>
    800019b8:	84ce                	mv	s1,s3
    800019ba:	b7c1                	j	8000197a <copyout+0x28>
  }
  return 0;
    800019bc:	4501                	li	a0,0
    800019be:	a021                	j	800019c6 <copyout+0x74>
    800019c0:	4501                	li	a0,0
}
    800019c2:	8082                	ret
      return -1;
    800019c4:	557d                	li	a0,-1
}
    800019c6:	60a6                	ld	ra,72(sp)
    800019c8:	6406                	ld	s0,64(sp)
    800019ca:	74e2                	ld	s1,56(sp)
    800019cc:	7942                	ld	s2,48(sp)
    800019ce:	79a2                	ld	s3,40(sp)
    800019d0:	7a02                	ld	s4,32(sp)
    800019d2:	6ae2                	ld	s5,24(sp)
    800019d4:	6b42                	ld	s6,16(sp)
    800019d6:	6ba2                	ld	s7,8(sp)
    800019d8:	6c02                	ld	s8,0(sp)
    800019da:	6161                	addi	sp,sp,80
    800019dc:	8082                	ret

00000000800019de <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;*/
  return copyin_new(pagetable,dst,srcva,len);
    800019e6:	00005097          	auipc	ra,0x5
    800019ea:	b2a080e7          	jalr	-1238(ra) # 80006510 <copyin_new>
}
    800019ee:	60a2                	ld	ra,8(sp)
    800019f0:	6402                	ld	s0,0(sp)
    800019f2:	0141                	addi	sp,sp,16
    800019f4:	8082                	ret

00000000800019f6 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800019f6:	1141                	addi	sp,sp,-16
    800019f8:	e406                	sd	ra,8(sp)
    800019fa:	e022                	sd	s0,0(sp)
    800019fc:	0800                	addi	s0,sp,16
  if(got_null){
    return 0;
  } else {
    return -1;
  }*/
  return copyinstr_new(pagetable,dst,srcva,max);
    800019fe:	00005097          	auipc	ra,0x5
    80001a02:	b7a080e7          	jalr	-1158(ra) # 80006578 <copyinstr_new>
}
    80001a06:	60a2                	ld	ra,8(sp)
    80001a08:	6402                	ld	s0,0(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
    80001a18:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	16a080e7          	jalr	362(ra) # 80000b84 <holding>
    80001a22:	c909                	beqz	a0,80001a34 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a24:	749c                	ld	a5,40(s1)
    80001a26:	00978f63          	beq	a5,s1,80001a44 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a2a:	60e2                	ld	ra,24(sp)
    80001a2c:	6442                	ld	s0,16(sp)
    80001a2e:	64a2                	ld	s1,8(sp)
    80001a30:	6105                	addi	sp,sp,32
    80001a32:	8082                	ret
    panic("wakeup1");
    80001a34:	00006517          	auipc	a0,0x6
    80001a38:	7e450513          	addi	a0,a0,2020 # 80008218 <digits+0x1d8>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b06080e7          	jalr	-1274(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a44:	4c98                	lw	a4,24(s1)
    80001a46:	4785                	li	a5,1
    80001a48:	fef711e3          	bne	a4,a5,80001a2a <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a4c:	4789                	li	a5,2
    80001a4e:	cc9c                	sw	a5,24(s1)
}
    80001a50:	bfe9                	j	80001a2a <wakeup1+0x1c>

0000000080001a52 <procinit>:
{
    80001a52:	7179                	addi	sp,sp,-48
    80001a54:	f406                	sd	ra,40(sp)
    80001a56:	f022                	sd	s0,32(sp)
    80001a58:	ec26                	sd	s1,24(sp)
    80001a5a:	e84a                	sd	s2,16(sp)
    80001a5c:	e44e                	sd	s3,8(sp)
    80001a5e:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001a60:	00006597          	auipc	a1,0x6
    80001a64:	7c058593          	addi	a1,a1,1984 # 80008220 <digits+0x1e0>
    80001a68:	00010517          	auipc	a0,0x10
    80001a6c:	ee850513          	addi	a0,a0,-280 # 80011950 <pid_lock>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	0fe080e7          	jalr	254(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a78:	00010497          	auipc	s1,0x10
    80001a7c:	2f048493          	addi	s1,s1,752 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a80:	00006997          	auipc	s3,0x6
    80001a84:	7a898993          	addi	s3,s3,1960 # 80008228 <digits+0x1e8>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a88:	00016917          	auipc	s2,0x16
    80001a8c:	ee090913          	addi	s2,s2,-288 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001a90:	85ce                	mv	a1,s3
    80001a92:	8526                	mv	a0,s1
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	0da080e7          	jalr	218(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9c:	17048493          	addi	s1,s1,368
    80001aa0:	ff2498e3          	bne	s1,s2,80001a90 <procinit+0x3e>
}
    80001aa4:	70a2                	ld	ra,40(sp)
    80001aa6:	7402                	ld	s0,32(sp)
    80001aa8:	64e2                	ld	s1,24(sp)
    80001aaa:	6942                	ld	s2,16(sp)
    80001aac:	69a2                	ld	s3,8(sp)
    80001aae:	6145                	addi	sp,sp,48
    80001ab0:	8082                	ret

0000000080001ab2 <cpuid>:
{
    80001ab2:	1141                	addi	sp,sp,-16
    80001ab4:	e422                	sd	s0,8(sp)
    80001ab6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab8:	8512                	mv	a0,tp
}
    80001aba:	2501                	sext.w	a0,a0
    80001abc:	6422                	ld	s0,8(sp)
    80001abe:	0141                	addi	sp,sp,16
    80001ac0:	8082                	ret

0000000080001ac2 <mycpu>:
mycpu(void) {
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e422                	sd	s0,8(sp)
    80001ac6:	0800                	addi	s0,sp,16
    80001ac8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aca:	2781                	sext.w	a5,a5
    80001acc:	079e                	slli	a5,a5,0x7
}
    80001ace:	00010517          	auipc	a0,0x10
    80001ad2:	e9a50513          	addi	a0,a0,-358 # 80011968 <cpus>
    80001ad6:	953e                	add	a0,a0,a5
    80001ad8:	6422                	ld	s0,8(sp)
    80001ada:	0141                	addi	sp,sp,16
    80001adc:	8082                	ret

0000000080001ade <myproc>:
myproc(void) {
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	1000                	addi	s0,sp,32
  push_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	0ca080e7          	jalr	202(ra) # 80000bb2 <push_off>
    80001af0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001af2:	2781                	sext.w	a5,a5
    80001af4:	079e                	slli	a5,a5,0x7
    80001af6:	00010717          	auipc	a4,0x10
    80001afa:	e5a70713          	addi	a4,a4,-422 # 80011950 <pid_lock>
    80001afe:	97ba                	add	a5,a5,a4
    80001b00:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	150080e7          	jalr	336(ra) # 80000c52 <pop_off>
}
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	60e2                	ld	ra,24(sp)
    80001b0e:	6442                	ld	s0,16(sp)
    80001b10:	64a2                	ld	s1,8(sp)
    80001b12:	6105                	addi	sp,sp,32
    80001b14:	8082                	ret

0000000080001b16 <forkret>:
{
    80001b16:	1141                	addi	sp,sp,-16
    80001b18:	e406                	sd	ra,8(sp)
    80001b1a:	e022                	sd	s0,0(sp)
    80001b1c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	fc0080e7          	jalr	-64(ra) # 80001ade <myproc>
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	18c080e7          	jalr	396(ra) # 80000cb2 <release>
  if (first) {
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	d727a783          	lw	a5,-654(a5) # 800088a0 <first.1>
    80001b36:	eb89                	bnez	a5,80001b48 <forkret+0x32>
  usertrapret();
    80001b38:	00001097          	auipc	ra,0x1
    80001b3c:	e2e080e7          	jalr	-466(ra) # 80002966 <usertrapret>
}
    80001b40:	60a2                	ld	ra,8(sp)
    80001b42:	6402                	ld	s0,0(sp)
    80001b44:	0141                	addi	sp,sp,16
    80001b46:	8082                	ret
    first = 0;
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	d407ac23          	sw	zero,-680(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001b50:	4505                	li	a0,1
    80001b52:	00002097          	auipc	ra,0x2
    80001b56:	b54080e7          	jalr	-1196(ra) # 800036a6 <fsinit>
    80001b5a:	bff9                	j	80001b38 <forkret+0x22>

0000000080001b5c <allocpid>:
allocpid() {
    80001b5c:	1101                	addi	sp,sp,-32
    80001b5e:	ec06                	sd	ra,24(sp)
    80001b60:	e822                	sd	s0,16(sp)
    80001b62:	e426                	sd	s1,8(sp)
    80001b64:	e04a                	sd	s2,0(sp)
    80001b66:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b68:	00010917          	auipc	s2,0x10
    80001b6c:	de890913          	addi	s2,s2,-536 # 80011950 <pid_lock>
    80001b70:	854a                	mv	a0,s2
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	08c080e7          	jalr	140(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001b7a:	00007797          	auipc	a5,0x7
    80001b7e:	d2a78793          	addi	a5,a5,-726 # 800088a4 <nextpid>
    80001b82:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b84:	0014871b          	addiw	a4,s1,1
    80001b88:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	126080e7          	jalr	294(ra) # 80000cb2 <release>
}
    80001b94:	8526                	mv	a0,s1
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6902                	ld	s2,0(sp)
    80001b9e:	6105                	addi	sp,sp,32
    80001ba0:	8082                	ret

0000000080001ba2 <proc_pagetable>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	a7c080e7          	jalr	-1412(ra) # 8000162c <uvmcreate>
    80001bb8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bba:	c121                	beqz	a0,80001bfa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bbc:	4729                	li	a4,10
    80001bbe:	00005697          	auipc	a3,0x5
    80001bc2:	44268693          	addi	a3,a3,1090 # 80007000 <_trampoline>
    80001bc6:	6605                	lui	a2,0x1
    80001bc8:	040005b7          	lui	a1,0x4000
    80001bcc:	15fd                	addi	a1,a1,-1
    80001bce:	05b2                	slli	a1,a1,0xc
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	660080e7          	jalr	1632(ra) # 80001230 <mappages>
    80001bd8:	02054863          	bltz	a0,80001c08 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bdc:	4719                	li	a4,6
    80001bde:	06093683          	ld	a3,96(s2)
    80001be2:	6605                	lui	a2,0x1
    80001be4:	020005b7          	lui	a1,0x2000
    80001be8:	15fd                	addi	a1,a1,-1
    80001bea:	05b6                	slli	a1,a1,0xd
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	642080e7          	jalr	1602(ra) # 80001230 <mappages>
    80001bf6:	02054163          	bltz	a0,80001c18 <proc_pagetable+0x76>
}
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	60e2                	ld	ra,24(sp)
    80001bfe:	6442                	ld	s0,16(sp)
    80001c00:	64a2                	ld	s1,8(sp)
    80001c02:	6902                	ld	s2,0(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret
    uvmfree(pagetable, 0);
    80001c08:	4581                	li	a1,0
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	c0a080e7          	jalr	-1014(ra) # 80001816 <uvmfree>
    return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	b7d5                	j	80001bfa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c18:	4681                	li	a3,0
    80001c1a:	4605                	li	a2,1
    80001c1c:	040005b7          	lui	a1,0x4000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b2                	slli	a1,a1,0xc
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	89e080e7          	jalr	-1890(ra) # 800014c4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c2e:	4581                	li	a1,0
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	be4080e7          	jalr	-1052(ra) # 80001816 <uvmfree>
    return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	bf7d                	j	80001bfa <proc_pagetable+0x58>

0000000080001c3e <proc_freekpagetable>:
{
    80001c3e:	1101                	addi	sp,sp,-32
    80001c40:	ec06                	sd	ra,24(sp)
    80001c42:	e822                	sd	s0,16(sp)
    80001c44:	e426                	sd	s1,8(sp)
    80001c46:	1000                	addi	s0,sp,32
    80001c48:	84aa                	mv	s1,a0
  uvmunmap(pg,UART0,1,0);
    80001c4a:	4681                	li	a3,0
    80001c4c:	4605                	li	a2,1
    80001c4e:	100005b7          	lui	a1,0x10000
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	872080e7          	jalr	-1934(ra) # 800014c4 <uvmunmap>
  uvmunmap(pg,VIRTIO0,1,0);
    80001c5a:	4681                	li	a3,0
    80001c5c:	4605                	li	a2,1
    80001c5e:	100015b7          	lui	a1,0x10001
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	860080e7          	jalr	-1952(ra) # 800014c4 <uvmunmap>
  uvmunmap(pg,CLINT,0x10000/PGSIZE,0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4641                	li	a2,16
    80001c70:	020005b7          	lui	a1,0x2000
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	84e080e7          	jalr	-1970(ra) # 800014c4 <uvmunmap>
  uvmunmap(pg,PLIC,0x400000/PGSIZE,0);
    80001c7e:	4681                	li	a3,0
    80001c80:	40000613          	li	a2,1024
    80001c84:	0c0005b7          	lui	a1,0xc000
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	83a080e7          	jalr	-1990(ra) # 800014c4 <uvmunmap>
  uvmunmap(pg,KERNBASE,(PHYSTOP-KERNBASE)/PGSIZE,0);
    80001c92:	4681                	li	a3,0
    80001c94:	6621                	lui	a2,0x8
    80001c96:	4585                	li	a1,1
    80001c98:	05fe                	slli	a1,a1,0x1f
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	828080e7          	jalr	-2008(ra) # 800014c4 <uvmunmap>
  uvmunmap(pg,TRAMPOLINE,1,0);
    80001ca4:	4681                	li	a3,0
    80001ca6:	4605                	li	a2,1
    80001ca8:	040005b7          	lui	a1,0x4000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b2                	slli	a1,a1,0xc
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	812080e7          	jalr	-2030(ra) # 800014c4 <uvmunmap>
  uvmfree(pg,0);
    80001cba:	4581                	li	a1,0
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	b58080e7          	jalr	-1192(ra) # 80001816 <uvmfree>
}
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6105                	addi	sp,sp,32
    80001cce:	8082                	ret

0000000080001cd0 <proc_freepagetable>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	e04a                	sd	s2,0(sp)
    80001cda:	1000                	addi	s0,sp,32
    80001cdc:	84aa                	mv	s1,a0
    80001cde:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce0:	4681                	li	a3,0
    80001ce2:	4605                	li	a2,1
    80001ce4:	040005b7          	lui	a1,0x4000
    80001ce8:	15fd                	addi	a1,a1,-1
    80001cea:	05b2                	slli	a1,a1,0xc
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	7d8080e7          	jalr	2008(ra) # 800014c4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cf4:	4681                	li	a3,0
    80001cf6:	4605                	li	a2,1
    80001cf8:	020005b7          	lui	a1,0x2000
    80001cfc:	15fd                	addi	a1,a1,-1
    80001cfe:	05b6                	slli	a1,a1,0xd
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	7c2080e7          	jalr	1986(ra) # 800014c4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d0a:	85ca                	mv	a1,s2
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	b08080e7          	jalr	-1272(ra) # 80001816 <uvmfree>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6902                	ld	s2,0(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret

0000000080001d22 <freeproc>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d2e:	7128                	ld	a0,96(a0)
    80001d30:	c509                	beqz	a0,80001d3a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	ce0080e7          	jalr	-800(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001d3a:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001d3e:	68a8                	ld	a0,80(s1)
    80001d40:	c511                	beqz	a0,80001d4c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d42:	64ac                	ld	a1,72(s1)
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	f8c080e7          	jalr	-116(ra) # 80001cd0 <proc_freepagetable>
  p->pagetable = 0;
    80001d4c:	0404b823          	sd	zero,80(s1)
  if(p->kstack)
    80001d50:	60ac                	ld	a1,64(s1)
    80001d52:	e1a1                	bnez	a1,80001d92 <freeproc+0x70>
  p->kstack=0;
    80001d54:	0404b023          	sd	zero,64(s1)
  if(p->kpagetable)
    80001d58:	6ca8                	ld	a0,88(s1)
    80001d5a:	c509                	beqz	a0,80001d64 <freeproc+0x42>
    proc_freekpagetable(p->kpagetable);
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	ee2080e7          	jalr	-286(ra) # 80001c3e <proc_freekpagetable>
  p->kpagetable=0;
    80001d64:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001d68:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d6c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d70:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d74:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001d78:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d7c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d80:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d84:	0004ac23          	sw	zero,24(s1)
}
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6105                	addi	sp,sp,32
    80001d90:	8082                	ret
    uvmunmap(p->kpagetable,p->kstack,1,1);
    80001d92:	4685                	li	a3,1
    80001d94:	4605                	li	a2,1
    80001d96:	6ca8                	ld	a0,88(s1)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	72c080e7          	jalr	1836(ra) # 800014c4 <uvmunmap>
    80001da0:	bf55                	j	80001d54 <freeproc+0x32>

0000000080001da2 <allocproc>:
{
    80001da2:	1101                	addi	sp,sp,-32
    80001da4:	ec06                	sd	ra,24(sp)
    80001da6:	e822                	sd	s0,16(sp)
    80001da8:	e426                	sd	s1,8(sp)
    80001daa:	e04a                	sd	s2,0(sp)
    80001dac:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dae:	00010497          	auipc	s1,0x10
    80001db2:	fba48493          	addi	s1,s1,-70 # 80011d68 <proc>
    80001db6:	00016917          	auipc	s2,0x16
    80001dba:	bb290913          	addi	s2,s2,-1102 # 80017968 <tickslock>
    acquire(&p->lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	e3e080e7          	jalr	-450(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001dc8:	4c9c                	lw	a5,24(s1)
    80001dca:	cf81                	beqz	a5,80001de2 <allocproc+0x40>
      release(&p->lock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	ee4080e7          	jalr	-284(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dd6:	17048493          	addi	s1,s1,368
    80001dda:	ff2492e3          	bne	s1,s2,80001dbe <allocproc+0x1c>
  return 0;
    80001dde:	4481                	li	s1,0
    80001de0:	a065                	j	80001e88 <allocproc+0xe6>
  p->pid = allocpid();
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	d7a080e7          	jalr	-646(ra) # 80001b5c <allocpid>
    80001dea:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	d22080e7          	jalr	-734(ra) # 80000b0e <kalloc>
    80001df4:	892a                	mv	s2,a0
    80001df6:	f0a8                	sd	a0,96(s1)
    80001df8:	cd59                	beqz	a0,80001e96 <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001dfa:	8526                	mv	a0,s1
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	da6080e7          	jalr	-602(ra) # 80001ba2 <proc_pagetable>
    80001e04:	892a                	mv	s2,a0
    80001e06:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e08:	cd51                	beqz	a0,80001ea4 <allocproc+0x102>
  p->kpagetable=ukvminit();
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	5d8080e7          	jalr	1496(ra) # 800013e2 <ukvminit>
    80001e12:	892a                	mv	s2,a0
    80001e14:	eca8                	sd	a0,88(s1)
  if(p->kpagetable==0)
    80001e16:	c15d                	beqz	a0,80001ebc <allocproc+0x11a>
  char *pa=kalloc();
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	cf6080e7          	jalr	-778(ra) # 80000b0e <kalloc>
    80001e20:	862a                	mv	a2,a0
  if(pa==0)
    80001e22:	c94d                	beqz	a0,80001ed4 <allocproc+0x132>
  uint64 va=KSTACK((int)(p-proc));
    80001e24:	00010797          	auipc	a5,0x10
    80001e28:	f4478793          	addi	a5,a5,-188 # 80011d68 <proc>
    80001e2c:	40f487b3          	sub	a5,s1,a5
    80001e30:	8791                	srai	a5,a5,0x4
    80001e32:	00006717          	auipc	a4,0x6
    80001e36:	1ce73703          	ld	a4,462(a4) # 80008000 <etext>
    80001e3a:	02e787b3          	mul	a5,a5,a4
    80001e3e:	2785                	addiw	a5,a5,1
    80001e40:	00d7979b          	slliw	a5,a5,0xd
    80001e44:	04000937          	lui	s2,0x4000
    80001e48:	197d                	addi	s2,s2,-1
    80001e4a:	0932                	slli	s2,s2,0xc
    80001e4c:	40f90933          	sub	s2,s2,a5
  ukvmmap(p->kpagetable,va,(uint64)pa,PGSIZE,PTE_R|PTE_W);
    80001e50:	4719                	li	a4,6
    80001e52:	6685                	lui	a3,0x1
    80001e54:	85ca                	mv	a1,s2
    80001e56:	6ca8                	ld	a0,88(s1)
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	55a080e7          	jalr	1370(ra) # 800013b2 <ukvmmap>
  p->kstack=va;
    80001e60:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001e64:	07000613          	li	a2,112
    80001e68:	4581                	li	a1,0
    80001e6a:	06848513          	addi	a0,s1,104
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e8c080e7          	jalr	-372(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001e76:	00000797          	auipc	a5,0x0
    80001e7a:	ca078793          	addi	a5,a5,-864 # 80001b16 <forkret>
    80001e7e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e80:	60bc                	ld	a5,64(s1)
    80001e82:	6705                	lui	a4,0x1
    80001e84:	97ba                	add	a5,a5,a4
    80001e86:	f8bc                	sd	a5,112(s1)
}
    80001e88:	8526                	mv	a0,s1
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret
    release(&p->lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	e1a080e7          	jalr	-486(ra) # 80000cb2 <release>
    return 0;
    80001ea0:	84ca                	mv	s1,s2
    80001ea2:	b7dd                	j	80001e88 <allocproc+0xe6>
    freeproc(p);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	00000097          	auipc	ra,0x0
    80001eaa:	e7c080e7          	jalr	-388(ra) # 80001d22 <freeproc>
    release(&p->lock);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	e02080e7          	jalr	-510(ra) # 80000cb2 <release>
    return 0;
    80001eb8:	84ca                	mv	s1,s2
    80001eba:	b7f9                	j	80001e88 <allocproc+0xe6>
    freeproc(p);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	e64080e7          	jalr	-412(ra) # 80001d22 <freeproc>
    release(&p->lock);
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dea080e7          	jalr	-534(ra) # 80000cb2 <release>
    return 0;
    80001ed0:	84ca                	mv	s1,s2
    80001ed2:	bf5d                	j	80001e88 <allocproc+0xe6>
    panic("kalloc");
    80001ed4:	00006517          	auipc	a0,0x6
    80001ed8:	35c50513          	addi	a0,a0,860 # 80008230 <digits+0x1f0>
    80001edc:	ffffe097          	auipc	ra,0xffffe
    80001ee0:	666080e7          	jalr	1638(ra) # 80000542 <panic>

0000000080001ee4 <userinit>:
{
    80001ee4:	1101                	addi	sp,sp,-32
    80001ee6:	ec06                	sd	ra,24(sp)
    80001ee8:	e822                	sd	s0,16(sp)
    80001eea:	e426                	sd	s1,8(sp)
    80001eec:	e04a                	sd	s2,0(sp)
    80001eee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	eb2080e7          	jalr	-334(ra) # 80001da2 <allocproc>
    80001ef8:	84aa                	mv	s1,a0
  initproc = p;
    80001efa:	00007797          	auipc	a5,0x7
    80001efe:	10a7bf23          	sd	a0,286(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f02:	03400613          	li	a2,52
    80001f06:	00007597          	auipc	a1,0x7
    80001f0a:	9aa58593          	addi	a1,a1,-1622 # 800088b0 <initcode>
    80001f0e:	6928                	ld	a0,80(a0)
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	74a080e7          	jalr	1866(ra) # 8000165a <uvminit>
  p->sz = PGSIZE;
    80001f18:	6905                	lui	s2,0x1
    80001f1a:	0524b423          	sd	s2,72(s1)
  upg2ukpg(p->pagetable,p->kpagetable,0,p->sz);
    80001f1e:	6685                	lui	a3,0x1
    80001f20:	4601                	li	a2,0
    80001f22:	6cac                	ld	a1,88(s1)
    80001f24:	68a8                	ld	a0,80(s1)
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	654080e7          	jalr	1620(ra) # 8000157a <upg2ukpg>
  p->trapframe->epc = 0;      // user program counter
    80001f2e:	70bc                	ld	a5,96(s1)
    80001f30:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f34:	70bc                	ld	a5,96(s1)
    80001f36:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f3a:	4641                	li	a2,16
    80001f3c:	00006597          	auipc	a1,0x6
    80001f40:	2fc58593          	addi	a1,a1,764 # 80008238 <digits+0x1f8>
    80001f44:	16048513          	addi	a0,s1,352
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	f04080e7          	jalr	-252(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001f50:	00006517          	auipc	a0,0x6
    80001f54:	2f850513          	addi	a0,a0,760 # 80008248 <digits+0x208>
    80001f58:	00002097          	auipc	ra,0x2
    80001f5c:	176080e7          	jalr	374(ra) # 800040ce <namei>
    80001f60:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001f64:	4789                	li	a5,2
    80001f66:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	d48080e7          	jalr	-696(ra) # 80000cb2 <release>
}
    80001f72:	60e2                	ld	ra,24(sp)
    80001f74:	6442                	ld	s0,16(sp)
    80001f76:	64a2                	ld	s1,8(sp)
    80001f78:	6902                	ld	s2,0(sp)
    80001f7a:	6105                	addi	sp,sp,32
    80001f7c:	8082                	ret

0000000080001f7e <growproc>:
{
    80001f7e:	7179                	addi	sp,sp,-48
    80001f80:	f406                	sd	ra,40(sp)
    80001f82:	f022                	sd	s0,32(sp)
    80001f84:	ec26                	sd	s1,24(sp)
    80001f86:	e84a                	sd	s2,16(sp)
    80001f88:	e44e                	sd	s3,8(sp)
    80001f8a:	1800                	addi	s0,sp,48
    80001f8c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	b50080e7          	jalr	-1200(ra) # 80001ade <myproc>
    80001f96:	89aa                	mv	s3,a0
  sz = p->sz;
    80001f98:	652c                	ld	a1,72(a0)
    80001f9a:	0005849b          	sext.w	s1,a1
  if(n > 0){
    80001f9e:	07205b63          	blez	s2,80002014 <growproc+0x96>
    if(sz+n > PLIC)
    80001fa2:	009904bb          	addw	s1,s2,s1
    80001fa6:	0004871b          	sext.w	a4,s1
    80001faa:	0c0007b7          	lui	a5,0xc000
    80001fae:	0ae7ea63          	bltu	a5,a4,80002062 <growproc+0xe4>
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fb2:	02049613          	slli	a2,s1,0x20
    80001fb6:	9201                	srli	a2,a2,0x20
    80001fb8:	1582                	slli	a1,a1,0x20
    80001fba:	9181                	srli	a1,a1,0x20
    80001fbc:	6928                	ld	a0,80(a0)
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	756080e7          	jalr	1878(ra) # 80001714 <uvmalloc>
    80001fc6:	0005049b          	sext.w	s1,a0
    80001fca:	ccd1                	beqz	s1,80002066 <growproc+0xe8>
    if(upg2ukpg(p->pagetable,p->kpagetable,PGROUNDUP(p->sz),PGROUNDUP(sz))<0)
    80001fcc:	6685                	lui	a3,0x1
    80001fce:	36fd                	addiw	a3,a3,-1
    80001fd0:	9ea5                	addw	a3,a3,s1
    80001fd2:	77fd                	lui	a5,0xfffff
    80001fd4:	8efd                	and	a3,a3,a5
    80001fd6:	1682                	slli	a3,a3,0x20
    80001fd8:	9281                	srli	a3,a3,0x20
    80001fda:	0489b783          	ld	a5,72(s3)
    80001fde:	6605                	lui	a2,0x1
    80001fe0:	167d                	addi	a2,a2,-1
    80001fe2:	97b2                	add	a5,a5,a2
    80001fe4:	767d                	lui	a2,0xfffff
    80001fe6:	8e7d                	and	a2,a2,a5
    80001fe8:	0589b583          	ld	a1,88(s3)
    80001fec:	0509b503          	ld	a0,80(s3)
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	58a080e7          	jalr	1418(ra) # 8000157a <upg2ukpg>
    80001ff8:	06054963          	bltz	a0,8000206a <growproc+0xec>
  p->sz = sz;
    80001ffc:	1482                	slli	s1,s1,0x20
    80001ffe:	9081                	srli	s1,s1,0x20
    80002000:	0499b423          	sd	s1,72(s3)
  return 0;
    80002004:	4501                	li	a0,0
}
    80002006:	70a2                	ld	ra,40(sp)
    80002008:	7402                	ld	s0,32(sp)
    8000200a:	64e2                	ld	s1,24(sp)
    8000200c:	6942                	ld	s2,16(sp)
    8000200e:	69a2                	ld	s3,8(sp)
    80002010:	6145                	addi	sp,sp,48
    80002012:	8082                	ret
  } else if(n < 0){
    80002014:	fe0954e3          	bgez	s2,80001ffc <growproc+0x7e>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002018:	0099063b          	addw	a2,s2,s1
    8000201c:	1602                	slli	a2,a2,0x20
    8000201e:	9201                	srli	a2,a2,0x20
    80002020:	1582                	slli	a1,a1,0x20
    80002022:	9181                	srli	a1,a1,0x20
    80002024:	6928                	ld	a0,80(a0)
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	6a6080e7          	jalr	1702(ra) # 800016cc <uvmdealloc>
    8000202e:	0005049b          	sext.w	s1,a0
    if(PGROUNDUP(p->sz)>PGROUNDUP(sz))
    80002032:	0489b603          	ld	a2,72(s3)
    80002036:	6585                	lui	a1,0x1
    80002038:	15fd                	addi	a1,a1,-1
    8000203a:	962e                	add	a2,a2,a1
    8000203c:	77fd                	lui	a5,0xfffff
    8000203e:	8e7d                	and	a2,a2,a5
    80002040:	9da9                	addw	a1,a1,a0
    80002042:	757d                	lui	a0,0xfffff
    80002044:	8de9                	and	a1,a1,a0
    80002046:	1582                	slli	a1,a1,0x20
    80002048:	9181                	srli	a1,a1,0x20
    8000204a:	fac5f9e3          	bgeu	a1,a2,80001ffc <growproc+0x7e>
      uvmunmap(p->kpagetable,PGROUNDUP(sz),(PGROUNDUP(p->sz)-PGROUNDUP(sz))/PGSIZE,0);
    8000204e:	8e0d                	sub	a2,a2,a1
    80002050:	4681                	li	a3,0
    80002052:	8231                	srli	a2,a2,0xc
    80002054:	0589b503          	ld	a0,88(s3)
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	46c080e7          	jalr	1132(ra) # 800014c4 <uvmunmap>
    80002060:	bf71                	j	80001ffc <growproc+0x7e>
      return -1;
    80002062:	557d                	li	a0,-1
    80002064:	b74d                	j	80002006 <growproc+0x88>
      return -1;
    80002066:	557d                	li	a0,-1
    80002068:	bf79                	j	80002006 <growproc+0x88>
      return -1;
    8000206a:	557d                	li	a0,-1
    8000206c:	bf69                	j	80002006 <growproc+0x88>

000000008000206e <fork>:
{
    8000206e:	7139                	addi	sp,sp,-64
    80002070:	fc06                	sd	ra,56(sp)
    80002072:	f822                	sd	s0,48(sp)
    80002074:	f426                	sd	s1,40(sp)
    80002076:	f04a                	sd	s2,32(sp)
    80002078:	ec4e                	sd	s3,24(sp)
    8000207a:	e852                	sd	s4,16(sp)
    8000207c:	e456                	sd	s5,8(sp)
    8000207e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002080:	00000097          	auipc	ra,0x0
    80002084:	a5e080e7          	jalr	-1442(ra) # 80001ade <myproc>
    80002088:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	d18080e7          	jalr	-744(ra) # 80001da2 <allocproc>
    80002092:	10050b63          	beqz	a0,800021a8 <fork+0x13a>
    80002096:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002098:	048ab603          	ld	a2,72(s5) # 1048 <_entry-0x7fffefb8>
    8000209c:	692c                	ld	a1,80(a0)
    8000209e:	050ab503          	ld	a0,80(s5)
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	7ac080e7          	jalr	1964(ra) # 8000184e <uvmcopy>
    800020aa:	06054563          	bltz	a0,80002114 <fork+0xa6>
  np->sz = p->sz;
    800020ae:	048ab683          	ld	a3,72(s5)
    800020b2:	04d9b423          	sd	a3,72(s3)
  if(upg2ukpg(np->pagetable,np->kpagetable,0,np->sz)<0)
    800020b6:	4601                	li	a2,0
    800020b8:	0589b583          	ld	a1,88(s3)
    800020bc:	0509b503          	ld	a0,80(s3)
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	4ba080e7          	jalr	1210(ra) # 8000157a <upg2ukpg>
    800020c8:	06054263          	bltz	a0,8000212c <fork+0xbe>
  np->parent = p;
    800020cc:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800020d0:	060ab683          	ld	a3,96(s5)
    800020d4:	87b6                	mv	a5,a3
    800020d6:	0609b703          	ld	a4,96(s3)
    800020da:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800020de:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    800020e2:	6788                	ld	a0,8(a5)
    800020e4:	6b8c                	ld	a1,16(a5)
    800020e6:	6f90                	ld	a2,24(a5)
    800020e8:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    800020ec:	e708                	sd	a0,8(a4)
    800020ee:	eb0c                	sd	a1,16(a4)
    800020f0:	ef10                	sd	a2,24(a4)
    800020f2:	02078793          	addi	a5,a5,32
    800020f6:	02070713          	addi	a4,a4,32
    800020fa:	fed792e3          	bne	a5,a3,800020de <fork+0x70>
  np->trapframe->a0 = 0;
    800020fe:	0609b783          	ld	a5,96(s3)
    80002102:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002106:	0d8a8493          	addi	s1,s5,216
    8000210a:	0d898913          	addi	s2,s3,216
    8000210e:	158a8a13          	addi	s4,s5,344
    80002112:	a82d                	j	8000214c <fork+0xde>
    freeproc(np);
    80002114:	854e                	mv	a0,s3
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	c0c080e7          	jalr	-1012(ra) # 80001d22 <freeproc>
    release(&np->lock);
    8000211e:	854e                	mv	a0,s3
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b92080e7          	jalr	-1134(ra) # 80000cb2 <release>
    return -1;
    80002128:	54fd                	li	s1,-1
    8000212a:	a0ad                	j	80002194 <fork+0x126>
    freeproc(np);
    8000212c:	854e                	mv	a0,s3
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	bf4080e7          	jalr	-1036(ra) # 80001d22 <freeproc>
    release(&np->lock);
    80002136:	854e                	mv	a0,s3
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b7a080e7          	jalr	-1158(ra) # 80000cb2 <release>
    return -1;
    80002140:	54fd                	li	s1,-1
    80002142:	a889                	j	80002194 <fork+0x126>
  for(i = 0; i < NOFILE; i++)
    80002144:	04a1                	addi	s1,s1,8
    80002146:	0921                	addi	s2,s2,8
    80002148:	01448b63          	beq	s1,s4,8000215e <fork+0xf0>
    if(p->ofile[i])
    8000214c:	6088                	ld	a0,0(s1)
    8000214e:	d97d                	beqz	a0,80002144 <fork+0xd6>
      np->ofile[i] = filedup(p->ofile[i]);
    80002150:	00002097          	auipc	ra,0x2
    80002154:	60a080e7          	jalr	1546(ra) # 8000475a <filedup>
    80002158:	00a93023          	sd	a0,0(s2) # 1000 <_entry-0x7ffff000>
    8000215c:	b7e5                	j	80002144 <fork+0xd6>
  np->cwd = idup(p->cwd);
    8000215e:	158ab503          	ld	a0,344(s5)
    80002162:	00001097          	auipc	ra,0x1
    80002166:	77e080e7          	jalr	1918(ra) # 800038e0 <idup>
    8000216a:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000216e:	4641                	li	a2,16
    80002170:	160a8593          	addi	a1,s5,352
    80002174:	16098513          	addi	a0,s3,352
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	cd4080e7          	jalr	-812(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80002180:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002184:	4789                	li	a5,2
    80002186:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000218a:	854e                	mv	a0,s3
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b26080e7          	jalr	-1242(ra) # 80000cb2 <release>
}
    80002194:	8526                	mv	a0,s1
    80002196:	70e2                	ld	ra,56(sp)
    80002198:	7442                	ld	s0,48(sp)
    8000219a:	74a2                	ld	s1,40(sp)
    8000219c:	7902                	ld	s2,32(sp)
    8000219e:	69e2                	ld	s3,24(sp)
    800021a0:	6a42                	ld	s4,16(sp)
    800021a2:	6aa2                	ld	s5,8(sp)
    800021a4:	6121                	addi	sp,sp,64
    800021a6:	8082                	ret
    return -1;
    800021a8:	54fd                	li	s1,-1
    800021aa:	b7ed                	j	80002194 <fork+0x126>

00000000800021ac <reparent>:
{
    800021ac:	7179                	addi	sp,sp,-48
    800021ae:	f406                	sd	ra,40(sp)
    800021b0:	f022                	sd	s0,32(sp)
    800021b2:	ec26                	sd	s1,24(sp)
    800021b4:	e84a                	sd	s2,16(sp)
    800021b6:	e44e                	sd	s3,8(sp)
    800021b8:	e052                	sd	s4,0(sp)
    800021ba:	1800                	addi	s0,sp,48
    800021bc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021be:	00010497          	auipc	s1,0x10
    800021c2:	baa48493          	addi	s1,s1,-1110 # 80011d68 <proc>
      pp->parent = initproc;
    800021c6:	00007a17          	auipc	s4,0x7
    800021ca:	e52a0a13          	addi	s4,s4,-430 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ce:	00015997          	auipc	s3,0x15
    800021d2:	79a98993          	addi	s3,s3,1946 # 80017968 <tickslock>
    800021d6:	a029                	j	800021e0 <reparent+0x34>
    800021d8:	17048493          	addi	s1,s1,368
    800021dc:	03348363          	beq	s1,s3,80002202 <reparent+0x56>
    if(pp->parent == p){
    800021e0:	709c                	ld	a5,32(s1)
    800021e2:	ff279be3          	bne	a5,s2,800021d8 <reparent+0x2c>
      acquire(&pp->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	a16080e7          	jalr	-1514(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    800021f0:	000a3783          	ld	a5,0(s4)
    800021f4:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aba080e7          	jalr	-1350(ra) # 80000cb2 <release>
    80002200:	bfe1                	j	800021d8 <reparent+0x2c>
}
    80002202:	70a2                	ld	ra,40(sp)
    80002204:	7402                	ld	s0,32(sp)
    80002206:	64e2                	ld	s1,24(sp)
    80002208:	6942                	ld	s2,16(sp)
    8000220a:	69a2                	ld	s3,8(sp)
    8000220c:	6a02                	ld	s4,0(sp)
    8000220e:	6145                	addi	sp,sp,48
    80002210:	8082                	ret

0000000080002212 <scheduler>:
{
    80002212:	715d                	addi	sp,sp,-80
    80002214:	e486                	sd	ra,72(sp)
    80002216:	e0a2                	sd	s0,64(sp)
    80002218:	fc26                	sd	s1,56(sp)
    8000221a:	f84a                	sd	s2,48(sp)
    8000221c:	f44e                	sd	s3,40(sp)
    8000221e:	f052                	sd	s4,32(sp)
    80002220:	ec56                	sd	s5,24(sp)
    80002222:	e85a                	sd	s6,16(sp)
    80002224:	e45e                	sd	s7,8(sp)
    80002226:	e062                	sd	s8,0(sp)
    80002228:	0880                	addi	s0,sp,80
    8000222a:	8792                	mv	a5,tp
  int id = r_tp();
    8000222c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000222e:	00779b13          	slli	s6,a5,0x7
    80002232:	0000f717          	auipc	a4,0xf
    80002236:	71e70713          	addi	a4,a4,1822 # 80011950 <pid_lock>
    8000223a:	975a                	add	a4,a4,s6
    8000223c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002240:	0000f717          	auipc	a4,0xf
    80002244:	73070713          	addi	a4,a4,1840 # 80011970 <cpus+0x8>
    80002248:	9b3a                	add	s6,s6,a4
        c->proc = p;
    8000224a:	079e                	slli	a5,a5,0x7
    8000224c:	0000fa17          	auipc	s4,0xf
    80002250:	704a0a13          	addi	s4,s4,1796 # 80011950 <pid_lock>
    80002254:	9a3e                	add	s4,s4,a5
	w_satp(MAKE_SATP(p->kpagetable));
    80002256:	5bfd                	li	s7,-1
    80002258:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    8000225a:	00015997          	auipc	s3,0x15
    8000225e:	70e98993          	addi	s3,s3,1806 # 80017968 <tickslock>
    80002262:	a0bd                	j	800022d0 <scheduler+0xbe>
      release(&p->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a4c080e7          	jalr	-1460(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000226e:	17048493          	addi	s1,s1,368
    80002272:	05348563          	beq	s1,s3,800022bc <scheduler+0xaa>
      acquire(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	986080e7          	jalr	-1658(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    80002280:	4c9c                	lw	a5,24(s1)
    80002282:	ff2791e3          	bne	a5,s2,80002264 <scheduler+0x52>
        p->state = RUNNING;
    80002286:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    8000228a:	009a3c23          	sd	s1,24(s4)
	w_satp(MAKE_SATP(p->kpagetable));
    8000228e:	6cbc                	ld	a5,88(s1)
    80002290:	83b1                	srli	a5,a5,0xc
    80002292:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002296:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000229a:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    8000229e:	06848593          	addi	a1,s1,104
    800022a2:	855a                	mv	a0,s6
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	618080e7          	jalr	1560(ra) # 800028bc <swtch>
        kvminithart();
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	e12080e7          	jalr	-494(ra) # 800010be <kvminithart>
        c->proc = 0;
    800022b4:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800022b8:	4c05                	li	s8,1
    800022ba:	b76d                	j	80002264 <scheduler+0x52>
    if(found == 0) {
    800022bc:	000c1a63          	bnez	s8,800022d0 <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022c4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022c8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022cc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022d8:	10079073          	csrw	sstatus,a5
    int found = 0;
    800022dc:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800022de:	00010497          	auipc	s1,0x10
    800022e2:	a8a48493          	addi	s1,s1,-1398 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800022e6:	4909                	li	s2,2
        p->state = RUNNING;
    800022e8:	4a8d                	li	s5,3
    800022ea:	b771                	j	80002276 <scheduler+0x64>

00000000800022ec <sched>:
{
    800022ec:	7179                	addi	sp,sp,-48
    800022ee:	f406                	sd	ra,40(sp)
    800022f0:	f022                	sd	s0,32(sp)
    800022f2:	ec26                	sd	s1,24(sp)
    800022f4:	e84a                	sd	s2,16(sp)
    800022f6:	e44e                	sd	s3,8(sp)
    800022f8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	7e4080e7          	jalr	2020(ra) # 80001ade <myproc>
    80002302:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	880080e7          	jalr	-1920(ra) # 80000b84 <holding>
    8000230c:	c93d                	beqz	a0,80002382 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000230e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002310:	2781                	sext.w	a5,a5
    80002312:	079e                	slli	a5,a5,0x7
    80002314:	0000f717          	auipc	a4,0xf
    80002318:	63c70713          	addi	a4,a4,1596 # 80011950 <pid_lock>
    8000231c:	97ba                	add	a5,a5,a4
    8000231e:	0907a703          	lw	a4,144(a5)
    80002322:	4785                	li	a5,1
    80002324:	06f71763          	bne	a4,a5,80002392 <sched+0xa6>
  if(p->state == RUNNING)
    80002328:	4c98                	lw	a4,24(s1)
    8000232a:	478d                	li	a5,3
    8000232c:	06f70b63          	beq	a4,a5,800023a2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002330:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002334:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002336:	efb5                	bnez	a5,800023b2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002338:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000233a:	0000f917          	auipc	s2,0xf
    8000233e:	61690913          	addi	s2,s2,1558 # 80011950 <pid_lock>
    80002342:	2781                	sext.w	a5,a5
    80002344:	079e                	slli	a5,a5,0x7
    80002346:	97ca                	add	a5,a5,s2
    80002348:	0947a983          	lw	s3,148(a5)
    8000234c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000234e:	2781                	sext.w	a5,a5
    80002350:	079e                	slli	a5,a5,0x7
    80002352:	0000f597          	auipc	a1,0xf
    80002356:	61e58593          	addi	a1,a1,1566 # 80011970 <cpus+0x8>
    8000235a:	95be                	add	a1,a1,a5
    8000235c:	06848513          	addi	a0,s1,104
    80002360:	00000097          	auipc	ra,0x0
    80002364:	55c080e7          	jalr	1372(ra) # 800028bc <swtch>
    80002368:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000236a:	2781                	sext.w	a5,a5
    8000236c:	079e                	slli	a5,a5,0x7
    8000236e:	97ca                	add	a5,a5,s2
    80002370:	0937aa23          	sw	s3,148(a5)
}
    80002374:	70a2                	ld	ra,40(sp)
    80002376:	7402                	ld	s0,32(sp)
    80002378:	64e2                	ld	s1,24(sp)
    8000237a:	6942                	ld	s2,16(sp)
    8000237c:	69a2                	ld	s3,8(sp)
    8000237e:	6145                	addi	sp,sp,48
    80002380:	8082                	ret
    panic("sched p->lock");
    80002382:	00006517          	auipc	a0,0x6
    80002386:	ece50513          	addi	a0,a0,-306 # 80008250 <digits+0x210>
    8000238a:	ffffe097          	auipc	ra,0xffffe
    8000238e:	1b8080e7          	jalr	440(ra) # 80000542 <panic>
    panic("sched locks");
    80002392:	00006517          	auipc	a0,0x6
    80002396:	ece50513          	addi	a0,a0,-306 # 80008260 <digits+0x220>
    8000239a:	ffffe097          	auipc	ra,0xffffe
    8000239e:	1a8080e7          	jalr	424(ra) # 80000542 <panic>
    panic("sched running");
    800023a2:	00006517          	auipc	a0,0x6
    800023a6:	ece50513          	addi	a0,a0,-306 # 80008270 <digits+0x230>
    800023aa:	ffffe097          	auipc	ra,0xffffe
    800023ae:	198080e7          	jalr	408(ra) # 80000542 <panic>
    panic("sched interruptible");
    800023b2:	00006517          	auipc	a0,0x6
    800023b6:	ece50513          	addi	a0,a0,-306 # 80008280 <digits+0x240>
    800023ba:	ffffe097          	auipc	ra,0xffffe
    800023be:	188080e7          	jalr	392(ra) # 80000542 <panic>

00000000800023c2 <exit>:
{
    800023c2:	7179                	addi	sp,sp,-48
    800023c4:	f406                	sd	ra,40(sp)
    800023c6:	f022                	sd	s0,32(sp)
    800023c8:	ec26                	sd	s1,24(sp)
    800023ca:	e84a                	sd	s2,16(sp)
    800023cc:	e44e                	sd	s3,8(sp)
    800023ce:	e052                	sd	s4,0(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	70a080e7          	jalr	1802(ra) # 80001ade <myproc>
    800023dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800023de:	00007797          	auipc	a5,0x7
    800023e2:	c3a7b783          	ld	a5,-966(a5) # 80009018 <initproc>
    800023e6:	0d850493          	addi	s1,a0,216
    800023ea:	15850913          	addi	s2,a0,344
    800023ee:	02a79363          	bne	a5,a0,80002414 <exit+0x52>
    panic("init exiting");
    800023f2:	00006517          	auipc	a0,0x6
    800023f6:	ea650513          	addi	a0,a0,-346 # 80008298 <digits+0x258>
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	148080e7          	jalr	328(ra) # 80000542 <panic>
      fileclose(f);
    80002402:	00002097          	auipc	ra,0x2
    80002406:	3aa080e7          	jalr	938(ra) # 800047ac <fileclose>
      p->ofile[fd] = 0;
    8000240a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000240e:	04a1                	addi	s1,s1,8
    80002410:	01248563          	beq	s1,s2,8000241a <exit+0x58>
    if(p->ofile[fd]){
    80002414:	6088                	ld	a0,0(s1)
    80002416:	f575                	bnez	a0,80002402 <exit+0x40>
    80002418:	bfdd                	j	8000240e <exit+0x4c>
  begin_op();
    8000241a:	00002097          	auipc	ra,0x2
    8000241e:	ec0080e7          	jalr	-320(ra) # 800042da <begin_op>
  iput(p->cwd);
    80002422:	1589b503          	ld	a0,344(s3)
    80002426:	00001097          	auipc	ra,0x1
    8000242a:	6b2080e7          	jalr	1714(ra) # 80003ad8 <iput>
  end_op();
    8000242e:	00002097          	auipc	ra,0x2
    80002432:	f2c080e7          	jalr	-212(ra) # 8000435a <end_op>
  p->cwd = 0;
    80002436:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000243a:	00007497          	auipc	s1,0x7
    8000243e:	bde48493          	addi	s1,s1,-1058 # 80009018 <initproc>
    80002442:	6088                	ld	a0,0(s1)
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	7ba080e7          	jalr	1978(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    8000244c:	6088                	ld	a0,0(s1)
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	5c0080e7          	jalr	1472(ra) # 80001a0e <wakeup1>
  release(&initproc->lock);
    80002456:	6088                	ld	a0,0(s1)
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	85a080e7          	jalr	-1958(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002460:	854e                	mv	a0,s3
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	79c080e7          	jalr	1948(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    8000246a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000246e:	854e                	mv	a0,s3
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	842080e7          	jalr	-1982(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	784080e7          	jalr	1924(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002482:	854e                	mv	a0,s3
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	77a080e7          	jalr	1914(ra) # 80000bfe <acquire>
  reparent(p);
    8000248c:	854e                	mv	a0,s3
    8000248e:	00000097          	auipc	ra,0x0
    80002492:	d1e080e7          	jalr	-738(ra) # 800021ac <reparent>
  wakeup1(original_parent);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	576080e7          	jalr	1398(ra) # 80001a0e <wakeup1>
  p->xstate = status;
    800024a0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800024a4:	4791                	li	a5,4
    800024a6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	806080e7          	jalr	-2042(ra) # 80000cb2 <release>
  sched();
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	e38080e7          	jalr	-456(ra) # 800022ec <sched>
  panic("zombie exit");
    800024bc:	00006517          	auipc	a0,0x6
    800024c0:	dec50513          	addi	a0,a0,-532 # 800082a8 <digits+0x268>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	07e080e7          	jalr	126(ra) # 80000542 <panic>

00000000800024cc <yield>:
{
    800024cc:	1101                	addi	sp,sp,-32
    800024ce:	ec06                	sd	ra,24(sp)
    800024d0:	e822                	sd	s0,16(sp)
    800024d2:	e426                	sd	s1,8(sp)
    800024d4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	608080e7          	jalr	1544(ra) # 80001ade <myproc>
    800024de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	71e080e7          	jalr	1822(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    800024e8:	4789                	li	a5,2
    800024ea:	cc9c                	sw	a5,24(s1)
  sched();
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	e00080e7          	jalr	-512(ra) # 800022ec <sched>
  release(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7bc080e7          	jalr	1980(ra) # 80000cb2 <release>
}
    800024fe:	60e2                	ld	ra,24(sp)
    80002500:	6442                	ld	s0,16(sp)
    80002502:	64a2                	ld	s1,8(sp)
    80002504:	6105                	addi	sp,sp,32
    80002506:	8082                	ret

0000000080002508 <sleep>:
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	1800                	addi	s0,sp,48
    80002516:	89aa                	mv	s3,a0
    80002518:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	5c4080e7          	jalr	1476(ra) # 80001ade <myproc>
    80002522:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002524:	05250663          	beq	a0,s2,80002570 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6d6080e7          	jalr	1750(ra) # 80000bfe <acquire>
    release(lk);
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	780080e7          	jalr	1920(ra) # 80000cb2 <release>
  p->chan = chan;
    8000253a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000253e:	4785                	li	a5,1
    80002540:	cc9c                	sw	a5,24(s1)
  sched();
    80002542:	00000097          	auipc	ra,0x0
    80002546:	daa080e7          	jalr	-598(ra) # 800022ec <sched>
  p->chan = 0;
    8000254a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	762080e7          	jalr	1890(ra) # 80000cb2 <release>
    acquire(lk);
    80002558:	854a                	mv	a0,s2
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	6a4080e7          	jalr	1700(ra) # 80000bfe <acquire>
}
    80002562:	70a2                	ld	ra,40(sp)
    80002564:	7402                	ld	s0,32(sp)
    80002566:	64e2                	ld	s1,24(sp)
    80002568:	6942                	ld	s2,16(sp)
    8000256a:	69a2                	ld	s3,8(sp)
    8000256c:	6145                	addi	sp,sp,48
    8000256e:	8082                	ret
  p->chan = chan;
    80002570:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002574:	4785                	li	a5,1
    80002576:	cd1c                	sw	a5,24(a0)
  sched();
    80002578:	00000097          	auipc	ra,0x0
    8000257c:	d74080e7          	jalr	-652(ra) # 800022ec <sched>
  p->chan = 0;
    80002580:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002584:	bff9                	j	80002562 <sleep+0x5a>

0000000080002586 <wait>:
{
    80002586:	715d                	addi	sp,sp,-80
    80002588:	e486                	sd	ra,72(sp)
    8000258a:	e0a2                	sd	s0,64(sp)
    8000258c:	fc26                	sd	s1,56(sp)
    8000258e:	f84a                	sd	s2,48(sp)
    80002590:	f44e                	sd	s3,40(sp)
    80002592:	f052                	sd	s4,32(sp)
    80002594:	ec56                	sd	s5,24(sp)
    80002596:	e85a                	sd	s6,16(sp)
    80002598:	e45e                	sd	s7,8(sp)
    8000259a:	0880                	addi	s0,sp,80
    8000259c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	540080e7          	jalr	1344(ra) # 80001ade <myproc>
    800025a6:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	656080e7          	jalr	1622(ra) # 80000bfe <acquire>
    havekids = 0;
    800025b0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025b2:	4a11                	li	s4,4
        havekids = 1;
    800025b4:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025b6:	00015997          	auipc	s3,0x15
    800025ba:	3b298993          	addi	s3,s3,946 # 80017968 <tickslock>
    havekids = 0;
    800025be:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	7a848493          	addi	s1,s1,1960 # 80011d68 <proc>
    800025c8:	a08d                	j	8000262a <wait+0xa4>
          pid = np->pid;
    800025ca:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025ce:	000b0e63          	beqz	s6,800025ea <wait+0x64>
    800025d2:	4691                	li	a3,4
    800025d4:	03448613          	addi	a2,s1,52
    800025d8:	85da                	mv	a1,s6
    800025da:	05093503          	ld	a0,80(s2)
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	374080e7          	jalr	884(ra) # 80001952 <copyout>
    800025e6:	02054263          	bltz	a0,8000260a <wait+0x84>
          freeproc(np);
    800025ea:	8526                	mv	a0,s1
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	736080e7          	jalr	1846(ra) # 80001d22 <freeproc>
          release(&np->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6bc080e7          	jalr	1724(ra) # 80000cb2 <release>
          release(&p->lock);
    800025fe:	854a                	mv	a0,s2
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	6b2080e7          	jalr	1714(ra) # 80000cb2 <release>
          return pid;
    80002608:	a8a9                	j	80002662 <wait+0xdc>
            release(&np->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	6a6080e7          	jalr	1702(ra) # 80000cb2 <release>
            release(&p->lock);
    80002614:	854a                	mv	a0,s2
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	69c080e7          	jalr	1692(ra) # 80000cb2 <release>
            return -1;
    8000261e:	59fd                	li	s3,-1
    80002620:	a089                	j	80002662 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002622:	17048493          	addi	s1,s1,368
    80002626:	03348463          	beq	s1,s3,8000264e <wait+0xc8>
      if(np->parent == p){
    8000262a:	709c                	ld	a5,32(s1)
    8000262c:	ff279be3          	bne	a5,s2,80002622 <wait+0x9c>
        acquire(&np->lock);
    80002630:	8526                	mv	a0,s1
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	5cc080e7          	jalr	1484(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    8000263a:	4c9c                	lw	a5,24(s1)
    8000263c:	f94787e3          	beq	a5,s4,800025ca <wait+0x44>
        release(&np->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	670080e7          	jalr	1648(ra) # 80000cb2 <release>
        havekids = 1;
    8000264a:	8756                	mv	a4,s5
    8000264c:	bfd9                	j	80002622 <wait+0x9c>
    if(!havekids || p->killed){
    8000264e:	c701                	beqz	a4,80002656 <wait+0xd0>
    80002650:	03092783          	lw	a5,48(s2)
    80002654:	c39d                	beqz	a5,8000267a <wait+0xf4>
      release(&p->lock);
    80002656:	854a                	mv	a0,s2
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	65a080e7          	jalr	1626(ra) # 80000cb2 <release>
      return -1;
    80002660:	59fd                	li	s3,-1
}
    80002662:	854e                	mv	a0,s3
    80002664:	60a6                	ld	ra,72(sp)
    80002666:	6406                	ld	s0,64(sp)
    80002668:	74e2                	ld	s1,56(sp)
    8000266a:	7942                	ld	s2,48(sp)
    8000266c:	79a2                	ld	s3,40(sp)
    8000266e:	7a02                	ld	s4,32(sp)
    80002670:	6ae2                	ld	s5,24(sp)
    80002672:	6b42                	ld	s6,16(sp)
    80002674:	6ba2                	ld	s7,8(sp)
    80002676:	6161                	addi	sp,sp,80
    80002678:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000267a:	85ca                	mv	a1,s2
    8000267c:	854a                	mv	a0,s2
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	e8a080e7          	jalr	-374(ra) # 80002508 <sleep>
    havekids = 0;
    80002686:	bf25                	j	800025be <wait+0x38>

0000000080002688 <wakeup>:
{
    80002688:	7139                	addi	sp,sp,-64
    8000268a:	fc06                	sd	ra,56(sp)
    8000268c:	f822                	sd	s0,48(sp)
    8000268e:	f426                	sd	s1,40(sp)
    80002690:	f04a                	sd	s2,32(sp)
    80002692:	ec4e                	sd	s3,24(sp)
    80002694:	e852                	sd	s4,16(sp)
    80002696:	e456                	sd	s5,8(sp)
    80002698:	0080                	addi	s0,sp,64
    8000269a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000269c:	0000f497          	auipc	s1,0xf
    800026a0:	6cc48493          	addi	s1,s1,1740 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026a4:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026a6:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026a8:	00015917          	auipc	s2,0x15
    800026ac:	2c090913          	addi	s2,s2,704 # 80017968 <tickslock>
    800026b0:	a811                	j	800026c4 <wakeup+0x3c>
    release(&p->lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5fe080e7          	jalr	1534(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026bc:	17048493          	addi	s1,s1,368
    800026c0:	03248063          	beq	s1,s2,800026e0 <wakeup+0x58>
    acquire(&p->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	538080e7          	jalr	1336(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800026ce:	4c9c                	lw	a5,24(s1)
    800026d0:	ff3791e3          	bne	a5,s3,800026b2 <wakeup+0x2a>
    800026d4:	749c                	ld	a5,40(s1)
    800026d6:	fd479ee3          	bne	a5,s4,800026b2 <wakeup+0x2a>
      p->state = RUNNABLE;
    800026da:	0154ac23          	sw	s5,24(s1)
    800026de:	bfd1                	j	800026b2 <wakeup+0x2a>
}
    800026e0:	70e2                	ld	ra,56(sp)
    800026e2:	7442                	ld	s0,48(sp)
    800026e4:	74a2                	ld	s1,40(sp)
    800026e6:	7902                	ld	s2,32(sp)
    800026e8:	69e2                	ld	s3,24(sp)
    800026ea:	6a42                	ld	s4,16(sp)
    800026ec:	6aa2                	ld	s5,8(sp)
    800026ee:	6121                	addi	sp,sp,64
    800026f0:	8082                	ret

00000000800026f2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800026f2:	7179                	addi	sp,sp,-48
    800026f4:	f406                	sd	ra,40(sp)
    800026f6:	f022                	sd	s0,32(sp)
    800026f8:	ec26                	sd	s1,24(sp)
    800026fa:	e84a                	sd	s2,16(sp)
    800026fc:	e44e                	sd	s3,8(sp)
    800026fe:	1800                	addi	s0,sp,48
    80002700:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002702:	0000f497          	auipc	s1,0xf
    80002706:	66648493          	addi	s1,s1,1638 # 80011d68 <proc>
    8000270a:	00015997          	auipc	s3,0x15
    8000270e:	25e98993          	addi	s3,s3,606 # 80017968 <tickslock>
    acquire(&p->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4ea080e7          	jalr	1258(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    8000271c:	5c9c                	lw	a5,56(s1)
    8000271e:	01278d63          	beq	a5,s2,80002738 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	58e080e7          	jalr	1422(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000272c:	17048493          	addi	s1,s1,368
    80002730:	ff3491e3          	bne	s1,s3,80002712 <kill+0x20>
  }
  return -1;
    80002734:	557d                	li	a0,-1
    80002736:	a821                	j	8000274e <kill+0x5c>
      p->killed = 1;
    80002738:	4785                	li	a5,1
    8000273a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000273c:	4c98                	lw	a4,24(s1)
    8000273e:	00f70f63          	beq	a4,a5,8000275c <kill+0x6a>
      release(&p->lock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	56e080e7          	jalr	1390(ra) # 80000cb2 <release>
      return 0;
    8000274c:	4501                	li	a0,0
}
    8000274e:	70a2                	ld	ra,40(sp)
    80002750:	7402                	ld	s0,32(sp)
    80002752:	64e2                	ld	s1,24(sp)
    80002754:	6942                	ld	s2,16(sp)
    80002756:	69a2                	ld	s3,8(sp)
    80002758:	6145                	addi	sp,sp,48
    8000275a:	8082                	ret
        p->state = RUNNABLE;
    8000275c:	4789                	li	a5,2
    8000275e:	cc9c                	sw	a5,24(s1)
    80002760:	b7cd                	j	80002742 <kill+0x50>

0000000080002762 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002762:	7179                	addi	sp,sp,-48
    80002764:	f406                	sd	ra,40(sp)
    80002766:	f022                	sd	s0,32(sp)
    80002768:	ec26                	sd	s1,24(sp)
    8000276a:	e84a                	sd	s2,16(sp)
    8000276c:	e44e                	sd	s3,8(sp)
    8000276e:	e052                	sd	s4,0(sp)
    80002770:	1800                	addi	s0,sp,48
    80002772:	84aa                	mv	s1,a0
    80002774:	892e                	mv	s2,a1
    80002776:	89b2                	mv	s3,a2
    80002778:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	364080e7          	jalr	868(ra) # 80001ade <myproc>
  if(user_dst){
    80002782:	c08d                	beqz	s1,800027a4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002784:	86d2                	mv	a3,s4
    80002786:	864e                	mv	a2,s3
    80002788:	85ca                	mv	a1,s2
    8000278a:	6928                	ld	a0,80(a0)
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	1c6080e7          	jalr	454(ra) # 80001952 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002794:	70a2                	ld	ra,40(sp)
    80002796:	7402                	ld	s0,32(sp)
    80002798:	64e2                	ld	s1,24(sp)
    8000279a:	6942                	ld	s2,16(sp)
    8000279c:	69a2                	ld	s3,8(sp)
    8000279e:	6a02                	ld	s4,0(sp)
    800027a0:	6145                	addi	sp,sp,48
    800027a2:	8082                	ret
    memmove((char *)dst, src, len);
    800027a4:	000a061b          	sext.w	a2,s4
    800027a8:	85ce                	mv	a1,s3
    800027aa:	854a                	mv	a0,s2
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	5aa080e7          	jalr	1450(ra) # 80000d56 <memmove>
    return 0;
    800027b4:	8526                	mv	a0,s1
    800027b6:	bff9                	j	80002794 <either_copyout+0x32>

00000000800027b8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027b8:	7179                	addi	sp,sp,-48
    800027ba:	f406                	sd	ra,40(sp)
    800027bc:	f022                	sd	s0,32(sp)
    800027be:	ec26                	sd	s1,24(sp)
    800027c0:	e84a                	sd	s2,16(sp)
    800027c2:	e44e                	sd	s3,8(sp)
    800027c4:	e052                	sd	s4,0(sp)
    800027c6:	1800                	addi	s0,sp,48
    800027c8:	892a                	mv	s2,a0
    800027ca:	84ae                	mv	s1,a1
    800027cc:	89b2                	mv	s3,a2
    800027ce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	30e080e7          	jalr	782(ra) # 80001ade <myproc>
  if(user_src){
    800027d8:	c08d                	beqz	s1,800027fa <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027da:	86d2                	mv	a3,s4
    800027dc:	864e                	mv	a2,s3
    800027de:	85ca                	mv	a1,s2
    800027e0:	6928                	ld	a0,80(a0)
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	1fc080e7          	jalr	508(ra) # 800019de <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027ea:	70a2                	ld	ra,40(sp)
    800027ec:	7402                	ld	s0,32(sp)
    800027ee:	64e2                	ld	s1,24(sp)
    800027f0:	6942                	ld	s2,16(sp)
    800027f2:	69a2                	ld	s3,8(sp)
    800027f4:	6a02                	ld	s4,0(sp)
    800027f6:	6145                	addi	sp,sp,48
    800027f8:	8082                	ret
    memmove(dst, (char*)src, len);
    800027fa:	000a061b          	sext.w	a2,s4
    800027fe:	85ce                	mv	a1,s3
    80002800:	854a                	mv	a0,s2
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	554080e7          	jalr	1364(ra) # 80000d56 <memmove>
    return 0;
    8000280a:	8526                	mv	a0,s1
    8000280c:	bff9                	j	800027ea <either_copyin+0x32>

000000008000280e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000280e:	715d                	addi	sp,sp,-80
    80002810:	e486                	sd	ra,72(sp)
    80002812:	e0a2                	sd	s0,64(sp)
    80002814:	fc26                	sd	s1,56(sp)
    80002816:	f84a                	sd	s2,48(sp)
    80002818:	f44e                	sd	s3,40(sp)
    8000281a:	f052                	sd	s4,32(sp)
    8000281c:	ec56                	sd	s5,24(sp)
    8000281e:	e85a                	sd	s6,16(sp)
    80002820:	e45e                	sd	s7,8(sp)
    80002822:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002824:	00006517          	auipc	a0,0x6
    80002828:	8a450513          	addi	a0,a0,-1884 # 800080c8 <digits+0x88>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	d60080e7          	jalr	-672(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002834:	0000f497          	auipc	s1,0xf
    80002838:	69448493          	addi	s1,s1,1684 # 80011ec8 <proc+0x160>
    8000283c:	00015917          	auipc	s2,0x15
    80002840:	28c90913          	addi	s2,s2,652 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002844:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002846:	00006997          	auipc	s3,0x6
    8000284a:	a7298993          	addi	s3,s3,-1422 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    8000284e:	00006a97          	auipc	s5,0x6
    80002852:	a72a8a93          	addi	s5,s5,-1422 # 800082c0 <digits+0x280>
    printf("\n");
    80002856:	00006a17          	auipc	s4,0x6
    8000285a:	872a0a13          	addi	s4,s4,-1934 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285e:	00006b97          	auipc	s7,0x6
    80002862:	a9ab8b93          	addi	s7,s7,-1382 # 800082f8 <states.0>
    80002866:	a00d                	j	80002888 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002868:	ed86a583          	lw	a1,-296(a3)
    8000286c:	8556                	mv	a0,s5
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d1e080e7          	jalr	-738(ra) # 8000058c <printf>
    printf("\n");
    80002876:	8552                	mv	a0,s4
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d14080e7          	jalr	-748(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002880:	17048493          	addi	s1,s1,368
    80002884:	03248163          	beq	s1,s2,800028a6 <procdump+0x98>
    if(p->state == UNUSED)
    80002888:	86a6                	mv	a3,s1
    8000288a:	eb84a783          	lw	a5,-328(s1)
    8000288e:	dbed                	beqz	a5,80002880 <procdump+0x72>
      state = "???";
    80002890:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002892:	fcfb6be3          	bltu	s6,a5,80002868 <procdump+0x5a>
    80002896:	1782                	slli	a5,a5,0x20
    80002898:	9381                	srli	a5,a5,0x20
    8000289a:	078e                	slli	a5,a5,0x3
    8000289c:	97de                	add	a5,a5,s7
    8000289e:	6390                	ld	a2,0(a5)
    800028a0:	f661                	bnez	a2,80002868 <procdump+0x5a>
      state = "???";
    800028a2:	864e                	mv	a2,s3
    800028a4:	b7d1                	j	80002868 <procdump+0x5a>
  }
}
    800028a6:	60a6                	ld	ra,72(sp)
    800028a8:	6406                	ld	s0,64(sp)
    800028aa:	74e2                	ld	s1,56(sp)
    800028ac:	7942                	ld	s2,48(sp)
    800028ae:	79a2                	ld	s3,40(sp)
    800028b0:	7a02                	ld	s4,32(sp)
    800028b2:	6ae2                	ld	s5,24(sp)
    800028b4:	6b42                	ld	s6,16(sp)
    800028b6:	6ba2                	ld	s7,8(sp)
    800028b8:	6161                	addi	sp,sp,80
    800028ba:	8082                	ret

00000000800028bc <swtch>:
    800028bc:	00153023          	sd	ra,0(a0)
    800028c0:	00253423          	sd	sp,8(a0)
    800028c4:	e900                	sd	s0,16(a0)
    800028c6:	ed04                	sd	s1,24(a0)
    800028c8:	03253023          	sd	s2,32(a0)
    800028cc:	03353423          	sd	s3,40(a0)
    800028d0:	03453823          	sd	s4,48(a0)
    800028d4:	03553c23          	sd	s5,56(a0)
    800028d8:	05653023          	sd	s6,64(a0)
    800028dc:	05753423          	sd	s7,72(a0)
    800028e0:	05853823          	sd	s8,80(a0)
    800028e4:	05953c23          	sd	s9,88(a0)
    800028e8:	07a53023          	sd	s10,96(a0)
    800028ec:	07b53423          	sd	s11,104(a0)
    800028f0:	0005b083          	ld	ra,0(a1)
    800028f4:	0085b103          	ld	sp,8(a1)
    800028f8:	6980                	ld	s0,16(a1)
    800028fa:	6d84                	ld	s1,24(a1)
    800028fc:	0205b903          	ld	s2,32(a1)
    80002900:	0285b983          	ld	s3,40(a1)
    80002904:	0305ba03          	ld	s4,48(a1)
    80002908:	0385ba83          	ld	s5,56(a1)
    8000290c:	0405bb03          	ld	s6,64(a1)
    80002910:	0485bb83          	ld	s7,72(a1)
    80002914:	0505bc03          	ld	s8,80(a1)
    80002918:	0585bc83          	ld	s9,88(a1)
    8000291c:	0605bd03          	ld	s10,96(a1)
    80002920:	0685bd83          	ld	s11,104(a1)
    80002924:	8082                	ret

0000000080002926 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002926:	1141                	addi	sp,sp,-16
    80002928:	e406                	sd	ra,8(sp)
    8000292a:	e022                	sd	s0,0(sp)
    8000292c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000292e:	00006597          	auipc	a1,0x6
    80002932:	9f258593          	addi	a1,a1,-1550 # 80008320 <states.0+0x28>
    80002936:	00015517          	auipc	a0,0x15
    8000293a:	03250513          	addi	a0,a0,50 # 80017968 <tickslock>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	230080e7          	jalr	560(ra) # 80000b6e <initlock>
}
    80002946:	60a2                	ld	ra,8(sp)
    80002948:	6402                	ld	s0,0(sp)
    8000294a:	0141                	addi	sp,sp,16
    8000294c:	8082                	ret

000000008000294e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e422                	sd	s0,8(sp)
    80002952:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002954:	00003797          	auipc	a5,0x3
    80002958:	4fc78793          	addi	a5,a5,1276 # 80005e50 <kernelvec>
    8000295c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002960:	6422                	ld	s0,8(sp)
    80002962:	0141                	addi	sp,sp,16
    80002964:	8082                	ret

0000000080002966 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002966:	1141                	addi	sp,sp,-16
    80002968:	e406                	sd	ra,8(sp)
    8000296a:	e022                	sd	s0,0(sp)
    8000296c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	170080e7          	jalr	368(ra) # 80001ade <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002976:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000297a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002980:	00004617          	auipc	a2,0x4
    80002984:	68060613          	addi	a2,a2,1664 # 80007000 <_trampoline>
    80002988:	00004697          	auipc	a3,0x4
    8000298c:	67868693          	addi	a3,a3,1656 # 80007000 <_trampoline>
    80002990:	8e91                	sub	a3,a3,a2
    80002992:	040007b7          	lui	a5,0x4000
    80002996:	17fd                	addi	a5,a5,-1
    80002998:	07b2                	slli	a5,a5,0xc
    8000299a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a0:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029a2:	180026f3          	csrr	a3,satp
    800029a6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029a8:	7138                	ld	a4,96(a0)
    800029aa:	6134                	ld	a3,64(a0)
    800029ac:	6585                	lui	a1,0x1
    800029ae:	96ae                	add	a3,a3,a1
    800029b0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029b2:	7138                	ld	a4,96(a0)
    800029b4:	00000697          	auipc	a3,0x0
    800029b8:	13868693          	addi	a3,a3,312 # 80002aec <usertrap>
    800029bc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029be:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c0:	8692                	mv	a3,tp
    800029c2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029c8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029cc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029d4:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d6:	6f18                	ld	a4,24(a4)
    800029d8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029dc:	692c                	ld	a1,80(a0)
    800029de:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029e0:	00004717          	auipc	a4,0x4
    800029e4:	6b070713          	addi	a4,a4,1712 # 80007090 <userret>
    800029e8:	8f11                	sub	a4,a4,a2
    800029ea:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ec:	577d                	li	a4,-1
    800029ee:	177e                	slli	a4,a4,0x3f
    800029f0:	8dd9                	or	a1,a1,a4
    800029f2:	02000537          	lui	a0,0x2000
    800029f6:	157d                	addi	a0,a0,-1
    800029f8:	0536                	slli	a0,a0,0xd
    800029fa:	9782                	jalr	a5
}
    800029fc:	60a2                	ld	ra,8(sp)
    800029fe:	6402                	ld	s0,0(sp)
    80002a00:	0141                	addi	sp,sp,16
    80002a02:	8082                	ret

0000000080002a04 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a0e:	00015497          	auipc	s1,0x15
    80002a12:	f5a48493          	addi	s1,s1,-166 # 80017968 <tickslock>
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	1e6080e7          	jalr	486(ra) # 80000bfe <acquire>
  ticks++;
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	60050513          	addi	a0,a0,1536 # 80009020 <ticks>
    80002a28:	411c                	lw	a5,0(a0)
    80002a2a:	2785                	addiw	a5,a5,1
    80002a2c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	c5a080e7          	jalr	-934(ra) # 80002688 <wakeup>
  release(&tickslock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	27a080e7          	jalr	634(ra) # 80000cb2 <release>
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6105                	addi	sp,sp,32
    80002a48:	8082                	ret

0000000080002a4a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a54:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a58:	00074d63          	bltz	a4,80002a72 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a5c:	57fd                	li	a5,-1
    80002a5e:	17fe                	slli	a5,a5,0x3f
    80002a60:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a62:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a64:	06f70363          	beq	a4,a5,80002aca <devintr+0x80>
  }
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret
     (scause & 0xff) == 9){
    80002a72:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a76:	46a5                	li	a3,9
    80002a78:	fed792e3          	bne	a5,a3,80002a5c <devintr+0x12>
    int irq = plic_claim();
    80002a7c:	00003097          	auipc	ra,0x3
    80002a80:	4dc080e7          	jalr	1244(ra) # 80005f58 <plic_claim>
    80002a84:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a86:	47a9                	li	a5,10
    80002a88:	02f50763          	beq	a0,a5,80002ab6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a8c:	4785                	li	a5,1
    80002a8e:	02f50963          	beq	a0,a5,80002ac0 <devintr+0x76>
    return 1;
    80002a92:	4505                	li	a0,1
    } else if(irq){
    80002a94:	d8f1                	beqz	s1,80002a68 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a96:	85a6                	mv	a1,s1
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	89050513          	addi	a0,a0,-1904 # 80008328 <states.0+0x30>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aec080e7          	jalr	-1300(ra) # 8000058c <printf>
      plic_complete(irq);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	00003097          	auipc	ra,0x3
    80002aae:	4d2080e7          	jalr	1234(ra) # 80005f7c <plic_complete>
    return 1;
    80002ab2:	4505                	li	a0,1
    80002ab4:	bf55                	j	80002a68 <devintr+0x1e>
      uartintr();
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	f0c080e7          	jalr	-244(ra) # 800009c2 <uartintr>
    80002abe:	b7ed                	j	80002aa8 <devintr+0x5e>
      virtio_disk_intr();
    80002ac0:	00004097          	auipc	ra,0x4
    80002ac4:	936080e7          	jalr	-1738(ra) # 800063f6 <virtio_disk_intr>
    80002ac8:	b7c5                	j	80002aa8 <devintr+0x5e>
    if(cpuid() == 0){
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	fe8080e7          	jalr	-24(ra) # 80001ab2 <cpuid>
    80002ad2:	c901                	beqz	a0,80002ae2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ad8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ada:	14479073          	csrw	sip,a5
    return 2;
    80002ade:	4509                	li	a0,2
    80002ae0:	b761                	j	80002a68 <devintr+0x1e>
      clockintr();
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	f22080e7          	jalr	-222(ra) # 80002a04 <clockintr>
    80002aea:	b7ed                	j	80002ad4 <devintr+0x8a>

0000000080002aec <usertrap>:
{
    80002aec:	1101                	addi	sp,sp,-32
    80002aee:	ec06                	sd	ra,24(sp)
    80002af0:	e822                	sd	s0,16(sp)
    80002af2:	e426                	sd	s1,8(sp)
    80002af4:	e04a                	sd	s2,0(sp)
    80002af6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002afc:	1007f793          	andi	a5,a5,256
    80002b00:	e3ad                	bnez	a5,80002b62 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b02:	00003797          	auipc	a5,0x3
    80002b06:	34e78793          	addi	a5,a5,846 # 80005e50 <kernelvec>
    80002b0a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	fd0080e7          	jalr	-48(ra) # 80001ade <myproc>
    80002b16:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b18:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	14102773          	csrr	a4,sepc
    80002b1e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b20:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b24:	47a1                	li	a5,8
    80002b26:	04f71c63          	bne	a4,a5,80002b7e <usertrap+0x92>
    if(p->killed)
    80002b2a:	591c                	lw	a5,48(a0)
    80002b2c:	e3b9                	bnez	a5,80002b72 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b2e:	70b8                	ld	a4,96(s1)
    80002b30:	6f1c                	ld	a5,24(a4)
    80002b32:	0791                	addi	a5,a5,4
    80002b34:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	2e0080e7          	jalr	736(ra) # 80002e22 <syscall>
  if(p->killed)
    80002b4a:	589c                	lw	a5,48(s1)
    80002b4c:	ebc1                	bnez	a5,80002bdc <usertrap+0xf0>
  usertrapret();
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	e18080e7          	jalr	-488(ra) # 80002966 <usertrapret>
}
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6902                	ld	s2,0(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret
    panic("usertrap: not from user mode");
    80002b62:	00005517          	auipc	a0,0x5
    80002b66:	7e650513          	addi	a0,a0,2022 # 80008348 <states.0+0x50>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	9d8080e7          	jalr	-1576(ra) # 80000542 <panic>
      exit(-1);
    80002b72:	557d                	li	a0,-1
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	84e080e7          	jalr	-1970(ra) # 800023c2 <exit>
    80002b7c:	bf4d                	j	80002b2e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	ecc080e7          	jalr	-308(ra) # 80002a4a <devintr>
    80002b86:	892a                	mv	s2,a0
    80002b88:	c501                	beqz	a0,80002b90 <usertrap+0xa4>
  if(p->killed)
    80002b8a:	589c                	lw	a5,48(s1)
    80002b8c:	c3a1                	beqz	a5,80002bcc <usertrap+0xe0>
    80002b8e:	a815                	j	80002bc2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b90:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b94:	5c90                	lw	a2,56(s1)
    80002b96:	00005517          	auipc	a0,0x5
    80002b9a:	7d250513          	addi	a0,a0,2002 # 80008368 <states.0+0x70>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ee080e7          	jalr	-1554(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002baa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bae:	00005517          	auipc	a0,0x5
    80002bb2:	7ea50513          	addi	a0,a0,2026 # 80008398 <states.0+0xa0>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	9d6080e7          	jalr	-1578(ra) # 8000058c <printf>
    p->killed = 1;
    80002bbe:	4785                	li	a5,1
    80002bc0:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002bc2:	557d                	li	a0,-1
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	7fe080e7          	jalr	2046(ra) # 800023c2 <exit>
  if(which_dev == 2)
    80002bcc:	4789                	li	a5,2
    80002bce:	f8f910e3          	bne	s2,a5,80002b4e <usertrap+0x62>
    yield();
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	8fa080e7          	jalr	-1798(ra) # 800024cc <yield>
    80002bda:	bf95                	j	80002b4e <usertrap+0x62>
  int which_dev = 0;
    80002bdc:	4901                	li	s2,0
    80002bde:	b7d5                	j	80002bc2 <usertrap+0xd6>

0000000080002be0 <kerneltrap>:
{
    80002be0:	7179                	addi	sp,sp,-48
    80002be2:	f406                	sd	ra,40(sp)
    80002be4:	f022                	sd	s0,32(sp)
    80002be6:	ec26                	sd	s1,24(sp)
    80002be8:	e84a                	sd	s2,16(sp)
    80002bea:	e44e                	sd	s3,8(sp)
    80002bec:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bfa:	1004f793          	andi	a5,s1,256
    80002bfe:	cb85                	beqz	a5,80002c2e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c00:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c04:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c06:	ef85                	bnez	a5,80002c3e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	e42080e7          	jalr	-446(ra) # 80002a4a <devintr>
    80002c10:	cd1d                	beqz	a0,80002c4e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c12:	4789                	li	a5,2
    80002c14:	06f50a63          	beq	a0,a5,80002c88 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c18:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10049073          	csrw	sstatus,s1
}
    80002c20:	70a2                	ld	ra,40(sp)
    80002c22:	7402                	ld	s0,32(sp)
    80002c24:	64e2                	ld	s1,24(sp)
    80002c26:	6942                	ld	s2,16(sp)
    80002c28:	69a2                	ld	s3,8(sp)
    80002c2a:	6145                	addi	sp,sp,48
    80002c2c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	78a50513          	addi	a0,a0,1930 # 800083b8 <states.0+0xc0>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	90c080e7          	jalr	-1780(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	7a250513          	addi	a0,a0,1954 # 800083e0 <states.0+0xe8>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	8fc080e7          	jalr	-1796(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002c4e:	85ce                	mv	a1,s3
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	7b050513          	addi	a0,a0,1968 # 80008400 <states.0+0x108>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	934080e7          	jalr	-1740(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c64:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	7a850513          	addi	a0,a0,1960 # 80008410 <states.0+0x118>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	91c080e7          	jalr	-1764(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7b050513          	addi	a0,a0,1968 # 80008428 <states.0+0x130>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8c2080e7          	jalr	-1854(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	e56080e7          	jalr	-426(ra) # 80001ade <myproc>
    80002c90:	d541                	beqz	a0,80002c18 <kerneltrap+0x38>
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	e4c080e7          	jalr	-436(ra) # 80001ade <myproc>
    80002c9a:	4d18                	lw	a4,24(a0)
    80002c9c:	478d                	li	a5,3
    80002c9e:	f6f71de3          	bne	a4,a5,80002c18 <kerneltrap+0x38>
    yield();
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	82a080e7          	jalr	-2006(ra) # 800024cc <yield>
    80002caa:	b7bd                	j	80002c18 <kerneltrap+0x38>

0000000080002cac <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cac:	1101                	addi	sp,sp,-32
    80002cae:	ec06                	sd	ra,24(sp)
    80002cb0:	e822                	sd	s0,16(sp)
    80002cb2:	e426                	sd	s1,8(sp)
    80002cb4:	1000                	addi	s0,sp,32
    80002cb6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	e26080e7          	jalr	-474(ra) # 80001ade <myproc>
  switch (n) {
    80002cc0:	4795                	li	a5,5
    80002cc2:	0497e163          	bltu	a5,s1,80002d04 <argraw+0x58>
    80002cc6:	048a                	slli	s1,s1,0x2
    80002cc8:	00005717          	auipc	a4,0x5
    80002ccc:	79870713          	addi	a4,a4,1944 # 80008460 <states.0+0x168>
    80002cd0:	94ba                	add	s1,s1,a4
    80002cd2:	409c                	lw	a5,0(s1)
    80002cd4:	97ba                	add	a5,a5,a4
    80002cd6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cd8:	713c                	ld	a5,96(a0)
    80002cda:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret
    return p->trapframe->a1;
    80002ce6:	713c                	ld	a5,96(a0)
    80002ce8:	7fa8                	ld	a0,120(a5)
    80002cea:	bfcd                	j	80002cdc <argraw+0x30>
    return p->trapframe->a2;
    80002cec:	713c                	ld	a5,96(a0)
    80002cee:	63c8                	ld	a0,128(a5)
    80002cf0:	b7f5                	j	80002cdc <argraw+0x30>
    return p->trapframe->a3;
    80002cf2:	713c                	ld	a5,96(a0)
    80002cf4:	67c8                	ld	a0,136(a5)
    80002cf6:	b7dd                	j	80002cdc <argraw+0x30>
    return p->trapframe->a4;
    80002cf8:	713c                	ld	a5,96(a0)
    80002cfa:	6bc8                	ld	a0,144(a5)
    80002cfc:	b7c5                	j	80002cdc <argraw+0x30>
    return p->trapframe->a5;
    80002cfe:	713c                	ld	a5,96(a0)
    80002d00:	6fc8                	ld	a0,152(a5)
    80002d02:	bfe9                	j	80002cdc <argraw+0x30>
  panic("argraw");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	73450513          	addi	a0,a0,1844 # 80008438 <states.0+0x140>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	836080e7          	jalr	-1994(ra) # 80000542 <panic>

0000000080002d14 <fetchaddr>:
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	e04a                	sd	s2,0(sp)
    80002d1e:	1000                	addi	s0,sp,32
    80002d20:	84aa                	mv	s1,a0
    80002d22:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	dba080e7          	jalr	-582(ra) # 80001ade <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d2c:	653c                	ld	a5,72(a0)
    80002d2e:	02f4f863          	bgeu	s1,a5,80002d5e <fetchaddr+0x4a>
    80002d32:	00848713          	addi	a4,s1,8
    80002d36:	02e7e663          	bltu	a5,a4,80002d62 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d3a:	46a1                	li	a3,8
    80002d3c:	8626                	mv	a2,s1
    80002d3e:	85ca                	mv	a1,s2
    80002d40:	6928                	ld	a0,80(a0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	c9c080e7          	jalr	-868(ra) # 800019de <copyin>
    80002d4a:	00a03533          	snez	a0,a0
    80002d4e:	40a00533          	neg	a0,a0
}
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	64a2                	ld	s1,8(sp)
    80002d58:	6902                	ld	s2,0(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret
    return -1;
    80002d5e:	557d                	li	a0,-1
    80002d60:	bfcd                	j	80002d52 <fetchaddr+0x3e>
    80002d62:	557d                	li	a0,-1
    80002d64:	b7fd                	j	80002d52 <fetchaddr+0x3e>

0000000080002d66 <fetchstr>:
{
    80002d66:	7179                	addi	sp,sp,-48
    80002d68:	f406                	sd	ra,40(sp)
    80002d6a:	f022                	sd	s0,32(sp)
    80002d6c:	ec26                	sd	s1,24(sp)
    80002d6e:	e84a                	sd	s2,16(sp)
    80002d70:	e44e                	sd	s3,8(sp)
    80002d72:	1800                	addi	s0,sp,48
    80002d74:	892a                	mv	s2,a0
    80002d76:	84ae                	mv	s1,a1
    80002d78:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d64080e7          	jalr	-668(ra) # 80001ade <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d82:	86ce                	mv	a3,s3
    80002d84:	864a                	mv	a2,s2
    80002d86:	85a6                	mv	a1,s1
    80002d88:	6928                	ld	a0,80(a0)
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	c6c080e7          	jalr	-916(ra) # 800019f6 <copyinstr>
  if(err < 0)
    80002d92:	00054763          	bltz	a0,80002da0 <fetchstr+0x3a>
  return strlen(buf);
    80002d96:	8526                	mv	a0,s1
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	0e6080e7          	jalr	230(ra) # 80000e7e <strlen>
}
    80002da0:	70a2                	ld	ra,40(sp)
    80002da2:	7402                	ld	s0,32(sp)
    80002da4:	64e2                	ld	s1,24(sp)
    80002da6:	6942                	ld	s2,16(sp)
    80002da8:	69a2                	ld	s3,8(sp)
    80002daa:	6145                	addi	sp,sp,48
    80002dac:	8082                	ret

0000000080002dae <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	ef2080e7          	jalr	-270(ra) # 80002cac <argraw>
    80002dc2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dc4:	4501                	li	a0,0
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	e426                	sd	s1,8(sp)
    80002dd8:	1000                	addi	s0,sp,32
    80002dda:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	ed0080e7          	jalr	-304(ra) # 80002cac <argraw>
    80002de4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002de6:	4501                	li	a0,0
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	64a2                	ld	s1,8(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	e04a                	sd	s2,0(sp)
    80002dfc:	1000                	addi	s0,sp,32
    80002dfe:	84ae                	mv	s1,a1
    80002e00:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	eaa080e7          	jalr	-342(ra) # 80002cac <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e0a:	864a                	mv	a2,s2
    80002e0c:	85a6                	mv	a1,s1
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	f58080e7          	jalr	-168(ra) # 80002d66 <fetchstr>
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6902                	ld	s2,0(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	e426                	sd	s1,8(sp)
    80002e2a:	e04a                	sd	s2,0(sp)
    80002e2c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	cb0080e7          	jalr	-848(ra) # 80001ade <myproc>
    80002e36:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e38:	06053903          	ld	s2,96(a0)
    80002e3c:	0a893783          	ld	a5,168(s2)
    80002e40:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e44:	37fd                	addiw	a5,a5,-1
    80002e46:	4751                	li	a4,20
    80002e48:	00f76f63          	bltu	a4,a5,80002e66 <syscall+0x44>
    80002e4c:	00369713          	slli	a4,a3,0x3
    80002e50:	00005797          	auipc	a5,0x5
    80002e54:	62878793          	addi	a5,a5,1576 # 80008478 <syscalls>
    80002e58:	97ba                	add	a5,a5,a4
    80002e5a:	639c                	ld	a5,0(a5)
    80002e5c:	c789                	beqz	a5,80002e66 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e5e:	9782                	jalr	a5
    80002e60:	06a93823          	sd	a0,112(s2)
    80002e64:	a839                	j	80002e82 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e66:	16048613          	addi	a2,s1,352
    80002e6a:	5c8c                	lw	a1,56(s1)
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	5d450513          	addi	a0,a0,1492 # 80008440 <states.0+0x148>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	718080e7          	jalr	1816(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e7c:	70bc                	ld	a5,96(s1)
    80002e7e:	577d                	li	a4,-1
    80002e80:	fbb8                	sd	a4,112(a5)
  }
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret

0000000080002e8e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e96:	fec40593          	addi	a1,s0,-20
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	f12080e7          	jalr	-238(ra) # 80002dae <argint>
    return -1;
    80002ea4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ea6:	00054963          	bltz	a0,80002eb8 <sys_exit+0x2a>
  exit(n);
    80002eaa:	fec42503          	lw	a0,-20(s0)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	514080e7          	jalr	1300(ra) # 800023c2 <exit>
  return 0;  // not reached
    80002eb6:	4781                	li	a5,0
}
    80002eb8:	853e                	mv	a0,a5
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	6105                	addi	sp,sp,32
    80002ec0:	8082                	ret

0000000080002ec2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ec2:	1141                	addi	sp,sp,-16
    80002ec4:	e406                	sd	ra,8(sp)
    80002ec6:	e022                	sd	s0,0(sp)
    80002ec8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	c14080e7          	jalr	-1004(ra) # 80001ade <myproc>
}
    80002ed2:	5d08                	lw	a0,56(a0)
    80002ed4:	60a2                	ld	ra,8(sp)
    80002ed6:	6402                	ld	s0,0(sp)
    80002ed8:	0141                	addi	sp,sp,16
    80002eda:	8082                	ret

0000000080002edc <sys_fork>:

uint64
sys_fork(void)
{
    80002edc:	1141                	addi	sp,sp,-16
    80002ede:	e406                	sd	ra,8(sp)
    80002ee0:	e022                	sd	s0,0(sp)
    80002ee2:	0800                	addi	s0,sp,16
  return fork();
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	18a080e7          	jalr	394(ra) # 8000206e <fork>
}
    80002eec:	60a2                	ld	ra,8(sp)
    80002eee:	6402                	ld	s0,0(sp)
    80002ef0:	0141                	addi	sp,sp,16
    80002ef2:	8082                	ret

0000000080002ef4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002efc:	fe840593          	addi	a1,s0,-24
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	ece080e7          	jalr	-306(ra) # 80002dd0 <argaddr>
    80002f0a:	87aa                	mv	a5,a0
    return -1;
    80002f0c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f0e:	0007c863          	bltz	a5,80002f1e <sys_wait+0x2a>
  return wait(p);
    80002f12:	fe843503          	ld	a0,-24(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	670080e7          	jalr	1648(ra) # 80002586 <wait>
}
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f30:	fdc40593          	addi	a1,s0,-36
    80002f34:	4501                	li	a0,0
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	e78080e7          	jalr	-392(ra) # 80002dae <argint>
    return -1;
    80002f3e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f40:	00054f63          	bltz	a0,80002f5e <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	b9a080e7          	jalr	-1126(ra) # 80001ade <myproc>
    80002f4c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f4e:	fdc42503          	lw	a0,-36(s0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	02c080e7          	jalr	44(ra) # 80001f7e <growproc>
    80002f5a:	00054863          	bltz	a0,80002f6a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f5e:	8526                	mv	a0,s1
    80002f60:	70a2                	ld	ra,40(sp)
    80002f62:	7402                	ld	s0,32(sp)
    80002f64:	64e2                	ld	s1,24(sp)
    80002f66:	6145                	addi	sp,sp,48
    80002f68:	8082                	ret
    return -1;
    80002f6a:	54fd                	li	s1,-1
    80002f6c:	bfcd                	j	80002f5e <sys_sbrk+0x38>

0000000080002f6e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f6e:	7139                	addi	sp,sp,-64
    80002f70:	fc06                	sd	ra,56(sp)
    80002f72:	f822                	sd	s0,48(sp)
    80002f74:	f426                	sd	s1,40(sp)
    80002f76:	f04a                	sd	s2,32(sp)
    80002f78:	ec4e                	sd	s3,24(sp)
    80002f7a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f7c:	fcc40593          	addi	a1,s0,-52
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	e2c080e7          	jalr	-468(ra) # 80002dae <argint>
    return -1;
    80002f8a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f8c:	06054563          	bltz	a0,80002ff6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f90:	00015517          	auipc	a0,0x15
    80002f94:	9d850513          	addi	a0,a0,-1576 # 80017968 <tickslock>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	c66080e7          	jalr	-922(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002fa0:	00006917          	auipc	s2,0x6
    80002fa4:	08092903          	lw	s2,128(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fa8:	fcc42783          	lw	a5,-52(s0)
    80002fac:	cf85                	beqz	a5,80002fe4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fae:	00015997          	auipc	s3,0x15
    80002fb2:	9ba98993          	addi	s3,s3,-1606 # 80017968 <tickslock>
    80002fb6:	00006497          	auipc	s1,0x6
    80002fba:	06a48493          	addi	s1,s1,106 # 80009020 <ticks>
    if(myproc()->killed){
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	b20080e7          	jalr	-1248(ra) # 80001ade <myproc>
    80002fc6:	591c                	lw	a5,48(a0)
    80002fc8:	ef9d                	bnez	a5,80003006 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fca:	85ce                	mv	a1,s3
    80002fcc:	8526                	mv	a0,s1
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	53a080e7          	jalr	1338(ra) # 80002508 <sleep>
  while(ticks - ticks0 < n){
    80002fd6:	409c                	lw	a5,0(s1)
    80002fd8:	412787bb          	subw	a5,a5,s2
    80002fdc:	fcc42703          	lw	a4,-52(s0)
    80002fe0:	fce7efe3          	bltu	a5,a4,80002fbe <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fe4:	00015517          	auipc	a0,0x15
    80002fe8:	98450513          	addi	a0,a0,-1660 # 80017968 <tickslock>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	cc6080e7          	jalr	-826(ra) # 80000cb2 <release>
  return 0;
    80002ff4:	4781                	li	a5,0
}
    80002ff6:	853e                	mv	a0,a5
    80002ff8:	70e2                	ld	ra,56(sp)
    80002ffa:	7442                	ld	s0,48(sp)
    80002ffc:	74a2                	ld	s1,40(sp)
    80002ffe:	7902                	ld	s2,32(sp)
    80003000:	69e2                	ld	s3,24(sp)
    80003002:	6121                	addi	sp,sp,64
    80003004:	8082                	ret
      release(&tickslock);
    80003006:	00015517          	auipc	a0,0x15
    8000300a:	96250513          	addi	a0,a0,-1694 # 80017968 <tickslock>
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	ca4080e7          	jalr	-860(ra) # 80000cb2 <release>
      return -1;
    80003016:	57fd                	li	a5,-1
    80003018:	bff9                	j	80002ff6 <sys_sleep+0x88>

000000008000301a <sys_kill>:

uint64
sys_kill(void)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003022:	fec40593          	addi	a1,s0,-20
    80003026:	4501                	li	a0,0
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	d86080e7          	jalr	-634(ra) # 80002dae <argint>
    80003030:	87aa                	mv	a5,a0
    return -1;
    80003032:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003034:	0007c863          	bltz	a5,80003044 <sys_kill+0x2a>
  return kill(pid);
    80003038:	fec42503          	lw	a0,-20(s0)
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	6b6080e7          	jalr	1718(ra) # 800026f2 <kill>
}
    80003044:	60e2                	ld	ra,24(sp)
    80003046:	6442                	ld	s0,16(sp)
    80003048:	6105                	addi	sp,sp,32
    8000304a:	8082                	ret

000000008000304c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	e426                	sd	s1,8(sp)
    80003054:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003056:	00015517          	auipc	a0,0x15
    8000305a:	91250513          	addi	a0,a0,-1774 # 80017968 <tickslock>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	ba0080e7          	jalr	-1120(ra) # 80000bfe <acquire>
  xticks = ticks;
    80003066:	00006497          	auipc	s1,0x6
    8000306a:	fba4a483          	lw	s1,-70(s1) # 80009020 <ticks>
  release(&tickslock);
    8000306e:	00015517          	auipc	a0,0x15
    80003072:	8fa50513          	addi	a0,a0,-1798 # 80017968 <tickslock>
    80003076:	ffffe097          	auipc	ra,0xffffe
    8000307a:	c3c080e7          	jalr	-964(ra) # 80000cb2 <release>
  return xticks;
}
    8000307e:	02049513          	slli	a0,s1,0x20
    80003082:	9101                	srli	a0,a0,0x20
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	64a2                	ld	s1,8(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret

000000008000308e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000308e:	7179                	addi	sp,sp,-48
    80003090:	f406                	sd	ra,40(sp)
    80003092:	f022                	sd	s0,32(sp)
    80003094:	ec26                	sd	s1,24(sp)
    80003096:	e84a                	sd	s2,16(sp)
    80003098:	e44e                	sd	s3,8(sp)
    8000309a:	e052                	sd	s4,0(sp)
    8000309c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000309e:	00005597          	auipc	a1,0x5
    800030a2:	48a58593          	addi	a1,a1,1162 # 80008528 <syscalls+0xb0>
    800030a6:	00015517          	auipc	a0,0x15
    800030aa:	8da50513          	addi	a0,a0,-1830 # 80017980 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	ac0080e7          	jalr	-1344(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030b6:	0001d797          	auipc	a5,0x1d
    800030ba:	8ca78793          	addi	a5,a5,-1846 # 8001f980 <bcache+0x8000>
    800030be:	0001d717          	auipc	a4,0x1d
    800030c2:	b2a70713          	addi	a4,a4,-1238 # 8001fbe8 <bcache+0x8268>
    800030c6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030ca:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ce:	00015497          	auipc	s1,0x15
    800030d2:	8ca48493          	addi	s1,s1,-1846 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    800030d6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030d8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030da:	00005a17          	auipc	s4,0x5
    800030de:	456a0a13          	addi	s4,s4,1110 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030e2:	2b893783          	ld	a5,696(s2)
    800030e6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030e8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030ec:	85d2                	mv	a1,s4
    800030ee:	01048513          	addi	a0,s1,16
    800030f2:	00001097          	auipc	ra,0x1
    800030f6:	4ac080e7          	jalr	1196(ra) # 8000459e <initsleeplock>
    bcache.head.next->prev = b;
    800030fa:	2b893783          	ld	a5,696(s2)
    800030fe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003100:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003104:	45848493          	addi	s1,s1,1112
    80003108:	fd349de3          	bne	s1,s3,800030e2 <binit+0x54>
  }
}
    8000310c:	70a2                	ld	ra,40(sp)
    8000310e:	7402                	ld	s0,32(sp)
    80003110:	64e2                	ld	s1,24(sp)
    80003112:	6942                	ld	s2,16(sp)
    80003114:	69a2                	ld	s3,8(sp)
    80003116:	6a02                	ld	s4,0(sp)
    80003118:	6145                	addi	sp,sp,48
    8000311a:	8082                	ret

000000008000311c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000311c:	7179                	addi	sp,sp,-48
    8000311e:	f406                	sd	ra,40(sp)
    80003120:	f022                	sd	s0,32(sp)
    80003122:	ec26                	sd	s1,24(sp)
    80003124:	e84a                	sd	s2,16(sp)
    80003126:	e44e                	sd	s3,8(sp)
    80003128:	1800                	addi	s0,sp,48
    8000312a:	892a                	mv	s2,a0
    8000312c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000312e:	00015517          	auipc	a0,0x15
    80003132:	85250513          	addi	a0,a0,-1966 # 80017980 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	ac8080e7          	jalr	-1336(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000313e:	0001d497          	auipc	s1,0x1d
    80003142:	afa4b483          	ld	s1,-1286(s1) # 8001fc38 <bcache+0x82b8>
    80003146:	0001d797          	auipc	a5,0x1d
    8000314a:	aa278793          	addi	a5,a5,-1374 # 8001fbe8 <bcache+0x8268>
    8000314e:	02f48f63          	beq	s1,a5,8000318c <bread+0x70>
    80003152:	873e                	mv	a4,a5
    80003154:	a021                	j	8000315c <bread+0x40>
    80003156:	68a4                	ld	s1,80(s1)
    80003158:	02e48a63          	beq	s1,a4,8000318c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000315c:	449c                	lw	a5,8(s1)
    8000315e:	ff279ce3          	bne	a5,s2,80003156 <bread+0x3a>
    80003162:	44dc                	lw	a5,12(s1)
    80003164:	ff3799e3          	bne	a5,s3,80003156 <bread+0x3a>
      b->refcnt++;
    80003168:	40bc                	lw	a5,64(s1)
    8000316a:	2785                	addiw	a5,a5,1
    8000316c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000316e:	00015517          	auipc	a0,0x15
    80003172:	81250513          	addi	a0,a0,-2030 # 80017980 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b3c080e7          	jalr	-1220(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    8000317e:	01048513          	addi	a0,s1,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	456080e7          	jalr	1110(ra) # 800045d8 <acquiresleep>
      return b;
    8000318a:	a8b9                	j	800031e8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000318c:	0001d497          	auipc	s1,0x1d
    80003190:	aa44b483          	ld	s1,-1372(s1) # 8001fc30 <bcache+0x82b0>
    80003194:	0001d797          	auipc	a5,0x1d
    80003198:	a5478793          	addi	a5,a5,-1452 # 8001fbe8 <bcache+0x8268>
    8000319c:	00f48863          	beq	s1,a5,800031ac <bread+0x90>
    800031a0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031a2:	40bc                	lw	a5,64(s1)
    800031a4:	cf81                	beqz	a5,800031bc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031a6:	64a4                	ld	s1,72(s1)
    800031a8:	fee49de3          	bne	s1,a4,800031a2 <bread+0x86>
  panic("bget: no buffers");
    800031ac:	00005517          	auipc	a0,0x5
    800031b0:	38c50513          	addi	a0,a0,908 # 80008538 <syscalls+0xc0>
    800031b4:	ffffd097          	auipc	ra,0xffffd
    800031b8:	38e080e7          	jalr	910(ra) # 80000542 <panic>
      b->dev = dev;
    800031bc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031c0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031c4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031c8:	4785                	li	a5,1
    800031ca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	7b450513          	addi	a0,a0,1972 # 80017980 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	ade080e7          	jalr	-1314(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    800031dc:	01048513          	addi	a0,s1,16
    800031e0:	00001097          	auipc	ra,0x1
    800031e4:	3f8080e7          	jalr	1016(ra) # 800045d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031e8:	409c                	lw	a5,0(s1)
    800031ea:	cb89                	beqz	a5,800031fc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031ec:	8526                	mv	a0,s1
    800031ee:	70a2                	ld	ra,40(sp)
    800031f0:	7402                	ld	s0,32(sp)
    800031f2:	64e2                	ld	s1,24(sp)
    800031f4:	6942                	ld	s2,16(sp)
    800031f6:	69a2                	ld	s3,8(sp)
    800031f8:	6145                	addi	sp,sp,48
    800031fa:	8082                	ret
    virtio_disk_rw(b, 0);
    800031fc:	4581                	li	a1,0
    800031fe:	8526                	mv	a0,s1
    80003200:	00003097          	auipc	ra,0x3
    80003204:	f6c080e7          	jalr	-148(ra) # 8000616c <virtio_disk_rw>
    b->valid = 1;
    80003208:	4785                	li	a5,1
    8000320a:	c09c                	sw	a5,0(s1)
  return b;
    8000320c:	b7c5                	j	800031ec <bread+0xd0>

000000008000320e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000321a:	0541                	addi	a0,a0,16
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	456080e7          	jalr	1110(ra) # 80004672 <holdingsleep>
    80003224:	cd01                	beqz	a0,8000323c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003226:	4585                	li	a1,1
    80003228:	8526                	mv	a0,s1
    8000322a:	00003097          	auipc	ra,0x3
    8000322e:	f42080e7          	jalr	-190(ra) # 8000616c <virtio_disk_rw>
}
    80003232:	60e2                	ld	ra,24(sp)
    80003234:	6442                	ld	s0,16(sp)
    80003236:	64a2                	ld	s1,8(sp)
    80003238:	6105                	addi	sp,sp,32
    8000323a:	8082                	ret
    panic("bwrite");
    8000323c:	00005517          	auipc	a0,0x5
    80003240:	31450513          	addi	a0,a0,788 # 80008550 <syscalls+0xd8>
    80003244:	ffffd097          	auipc	ra,0xffffd
    80003248:	2fe080e7          	jalr	766(ra) # 80000542 <panic>

000000008000324c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	e04a                	sd	s2,0(sp)
    80003256:	1000                	addi	s0,sp,32
    80003258:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000325a:	01050913          	addi	s2,a0,16
    8000325e:	854a                	mv	a0,s2
    80003260:	00001097          	auipc	ra,0x1
    80003264:	412080e7          	jalr	1042(ra) # 80004672 <holdingsleep>
    80003268:	c92d                	beqz	a0,800032da <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	3c2080e7          	jalr	962(ra) # 8000462e <releasesleep>

  acquire(&bcache.lock);
    80003274:	00014517          	auipc	a0,0x14
    80003278:	70c50513          	addi	a0,a0,1804 # 80017980 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	982080e7          	jalr	-1662(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003284:	40bc                	lw	a5,64(s1)
    80003286:	37fd                	addiw	a5,a5,-1
    80003288:	0007871b          	sext.w	a4,a5
    8000328c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000328e:	eb05                	bnez	a4,800032be <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003290:	68bc                	ld	a5,80(s1)
    80003292:	64b8                	ld	a4,72(s1)
    80003294:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003296:	64bc                	ld	a5,72(s1)
    80003298:	68b8                	ld	a4,80(s1)
    8000329a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000329c:	0001c797          	auipc	a5,0x1c
    800032a0:	6e478793          	addi	a5,a5,1764 # 8001f980 <bcache+0x8000>
    800032a4:	2b87b703          	ld	a4,696(a5)
    800032a8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032aa:	0001d717          	auipc	a4,0x1d
    800032ae:	93e70713          	addi	a4,a4,-1730 # 8001fbe8 <bcache+0x8268>
    800032b2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032b4:	2b87b703          	ld	a4,696(a5)
    800032b8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032ba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032be:	00014517          	auipc	a0,0x14
    800032c2:	6c250513          	addi	a0,a0,1730 # 80017980 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	9ec080e7          	jalr	-1556(ra) # 80000cb2 <release>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6902                	ld	s2,0(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret
    panic("brelse");
    800032da:	00005517          	auipc	a0,0x5
    800032de:	27e50513          	addi	a0,a0,638 # 80008558 <syscalls+0xe0>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	260080e7          	jalr	608(ra) # 80000542 <panic>

00000000800032ea <bpin>:

void
bpin(struct buf *b) {
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	1000                	addi	s0,sp,32
    800032f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f6:	00014517          	auipc	a0,0x14
    800032fa:	68a50513          	addi	a0,a0,1674 # 80017980 <bcache>
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	900080e7          	jalr	-1792(ra) # 80000bfe <acquire>
  b->refcnt++;
    80003306:	40bc                	lw	a5,64(s1)
    80003308:	2785                	addiw	a5,a5,1
    8000330a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000330c:	00014517          	auipc	a0,0x14
    80003310:	67450513          	addi	a0,a0,1652 # 80017980 <bcache>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	99e080e7          	jalr	-1634(ra) # 80000cb2 <release>
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret

0000000080003326 <bunpin>:

void
bunpin(struct buf *b) {
    80003326:	1101                	addi	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	e426                	sd	s1,8(sp)
    8000332e:	1000                	addi	s0,sp,32
    80003330:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003332:	00014517          	auipc	a0,0x14
    80003336:	64e50513          	addi	a0,a0,1614 # 80017980 <bcache>
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	8c4080e7          	jalr	-1852(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003342:	40bc                	lw	a5,64(s1)
    80003344:	37fd                	addiw	a5,a5,-1
    80003346:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003348:	00014517          	auipc	a0,0x14
    8000334c:	63850513          	addi	a0,a0,1592 # 80017980 <bcache>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	962080e7          	jalr	-1694(ra) # 80000cb2 <release>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	64a2                	ld	s1,8(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret

0000000080003362 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003362:	1101                	addi	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	e04a                	sd	s2,0(sp)
    8000336c:	1000                	addi	s0,sp,32
    8000336e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003370:	00d5d59b          	srliw	a1,a1,0xd
    80003374:	0001d797          	auipc	a5,0x1d
    80003378:	ce87a783          	lw	a5,-792(a5) # 8002005c <sb+0x1c>
    8000337c:	9dbd                	addw	a1,a1,a5
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	d9e080e7          	jalr	-610(ra) # 8000311c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003386:	0074f713          	andi	a4,s1,7
    8000338a:	4785                	li	a5,1
    8000338c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003390:	14ce                	slli	s1,s1,0x33
    80003392:	90d9                	srli	s1,s1,0x36
    80003394:	00950733          	add	a4,a0,s1
    80003398:	05874703          	lbu	a4,88(a4)
    8000339c:	00e7f6b3          	and	a3,a5,a4
    800033a0:	c69d                	beqz	a3,800033ce <bfree+0x6c>
    800033a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033a4:	94aa                	add	s1,s1,a0
    800033a6:	fff7c793          	not	a5,a5
    800033aa:	8ff9                	and	a5,a5,a4
    800033ac:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	100080e7          	jalr	256(ra) # 800044b0 <log_write>
  brelse(bp);
    800033b8:	854a                	mv	a0,s2
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	e92080e7          	jalr	-366(ra) # 8000324c <brelse>
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6902                	ld	s2,0(sp)
    800033ca:	6105                	addi	sp,sp,32
    800033cc:	8082                	ret
    panic("freeing free block");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	19250513          	addi	a0,a0,402 # 80008560 <syscalls+0xe8>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	16c080e7          	jalr	364(ra) # 80000542 <panic>

00000000800033de <balloc>:
{
    800033de:	711d                	addi	sp,sp,-96
    800033e0:	ec86                	sd	ra,88(sp)
    800033e2:	e8a2                	sd	s0,80(sp)
    800033e4:	e4a6                	sd	s1,72(sp)
    800033e6:	e0ca                	sd	s2,64(sp)
    800033e8:	fc4e                	sd	s3,56(sp)
    800033ea:	f852                	sd	s4,48(sp)
    800033ec:	f456                	sd	s5,40(sp)
    800033ee:	f05a                	sd	s6,32(sp)
    800033f0:	ec5e                	sd	s7,24(sp)
    800033f2:	e862                	sd	s8,16(sp)
    800033f4:	e466                	sd	s9,8(sp)
    800033f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033f8:	0001d797          	auipc	a5,0x1d
    800033fc:	c4c7a783          	lw	a5,-948(a5) # 80020044 <sb+0x4>
    80003400:	cbd1                	beqz	a5,80003494 <balloc+0xb6>
    80003402:	8baa                	mv	s7,a0
    80003404:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003406:	0001db17          	auipc	s6,0x1d
    8000340a:	c3ab0b13          	addi	s6,s6,-966 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003410:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003412:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003414:	6c89                	lui	s9,0x2
    80003416:	a831                	j	80003432 <balloc+0x54>
    brelse(bp);
    80003418:	854a                	mv	a0,s2
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e32080e7          	jalr	-462(ra) # 8000324c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003422:	015c87bb          	addw	a5,s9,s5
    80003426:	00078a9b          	sext.w	s5,a5
    8000342a:	004b2703          	lw	a4,4(s6)
    8000342e:	06eaf363          	bgeu	s5,a4,80003494 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003432:	41fad79b          	sraiw	a5,s5,0x1f
    80003436:	0137d79b          	srliw	a5,a5,0x13
    8000343a:	015787bb          	addw	a5,a5,s5
    8000343e:	40d7d79b          	sraiw	a5,a5,0xd
    80003442:	01cb2583          	lw	a1,28(s6)
    80003446:	9dbd                	addw	a1,a1,a5
    80003448:	855e                	mv	a0,s7
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	cd2080e7          	jalr	-814(ra) # 8000311c <bread>
    80003452:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003454:	004b2503          	lw	a0,4(s6)
    80003458:	000a849b          	sext.w	s1,s5
    8000345c:	8662                	mv	a2,s8
    8000345e:	faa4fde3          	bgeu	s1,a0,80003418 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003462:	41f6579b          	sraiw	a5,a2,0x1f
    80003466:	01d7d69b          	srliw	a3,a5,0x1d
    8000346a:	00c6873b          	addw	a4,a3,a2
    8000346e:	00777793          	andi	a5,a4,7
    80003472:	9f95                	subw	a5,a5,a3
    80003474:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003478:	4037571b          	sraiw	a4,a4,0x3
    8000347c:	00e906b3          	add	a3,s2,a4
    80003480:	0586c683          	lbu	a3,88(a3)
    80003484:	00d7f5b3          	and	a1,a5,a3
    80003488:	cd91                	beqz	a1,800034a4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000348a:	2605                	addiw	a2,a2,1
    8000348c:	2485                	addiw	s1,s1,1
    8000348e:	fd4618e3          	bne	a2,s4,8000345e <balloc+0x80>
    80003492:	b759                	j	80003418 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003494:	00005517          	auipc	a0,0x5
    80003498:	0e450513          	addi	a0,a0,228 # 80008578 <syscalls+0x100>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	0a6080e7          	jalr	166(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034a4:	974a                	add	a4,a4,s2
    800034a6:	8fd5                	or	a5,a5,a3
    800034a8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034ac:	854a                	mv	a0,s2
    800034ae:	00001097          	auipc	ra,0x1
    800034b2:	002080e7          	jalr	2(ra) # 800044b0 <log_write>
        brelse(bp);
    800034b6:	854a                	mv	a0,s2
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	d94080e7          	jalr	-620(ra) # 8000324c <brelse>
  bp = bread(dev, bno);
    800034c0:	85a6                	mv	a1,s1
    800034c2:	855e                	mv	a0,s7
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	c58080e7          	jalr	-936(ra) # 8000311c <bread>
    800034cc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034ce:	40000613          	li	a2,1024
    800034d2:	4581                	li	a1,0
    800034d4:	05850513          	addi	a0,a0,88
    800034d8:	ffffe097          	auipc	ra,0xffffe
    800034dc:	822080e7          	jalr	-2014(ra) # 80000cfa <memset>
  log_write(bp);
    800034e0:	854a                	mv	a0,s2
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	fce080e7          	jalr	-50(ra) # 800044b0 <log_write>
  brelse(bp);
    800034ea:	854a                	mv	a0,s2
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	d60080e7          	jalr	-672(ra) # 8000324c <brelse>
}
    800034f4:	8526                	mv	a0,s1
    800034f6:	60e6                	ld	ra,88(sp)
    800034f8:	6446                	ld	s0,80(sp)
    800034fa:	64a6                	ld	s1,72(sp)
    800034fc:	6906                	ld	s2,64(sp)
    800034fe:	79e2                	ld	s3,56(sp)
    80003500:	7a42                	ld	s4,48(sp)
    80003502:	7aa2                	ld	s5,40(sp)
    80003504:	7b02                	ld	s6,32(sp)
    80003506:	6be2                	ld	s7,24(sp)
    80003508:	6c42                	ld	s8,16(sp)
    8000350a:	6ca2                	ld	s9,8(sp)
    8000350c:	6125                	addi	sp,sp,96
    8000350e:	8082                	ret

0000000080003510 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003510:	7179                	addi	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	e052                	sd	s4,0(sp)
    8000351e:	1800                	addi	s0,sp,48
    80003520:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003522:	47ad                	li	a5,11
    80003524:	04b7fe63          	bgeu	a5,a1,80003580 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003528:	ff45849b          	addiw	s1,a1,-12
    8000352c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003530:	0ff00793          	li	a5,255
    80003534:	0ae7e363          	bltu	a5,a4,800035da <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003538:	08052583          	lw	a1,128(a0)
    8000353c:	c5ad                	beqz	a1,800035a6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000353e:	00092503          	lw	a0,0(s2)
    80003542:	00000097          	auipc	ra,0x0
    80003546:	bda080e7          	jalr	-1062(ra) # 8000311c <bread>
    8000354a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000354c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003550:	02049593          	slli	a1,s1,0x20
    80003554:	9181                	srli	a1,a1,0x20
    80003556:	058a                	slli	a1,a1,0x2
    80003558:	00b784b3          	add	s1,a5,a1
    8000355c:	0004a983          	lw	s3,0(s1)
    80003560:	04098d63          	beqz	s3,800035ba <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003564:	8552                	mv	a0,s4
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	ce6080e7          	jalr	-794(ra) # 8000324c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000356e:	854e                	mv	a0,s3
    80003570:	70a2                	ld	ra,40(sp)
    80003572:	7402                	ld	s0,32(sp)
    80003574:	64e2                	ld	s1,24(sp)
    80003576:	6942                	ld	s2,16(sp)
    80003578:	69a2                	ld	s3,8(sp)
    8000357a:	6a02                	ld	s4,0(sp)
    8000357c:	6145                	addi	sp,sp,48
    8000357e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003580:	02059493          	slli	s1,a1,0x20
    80003584:	9081                	srli	s1,s1,0x20
    80003586:	048a                	slli	s1,s1,0x2
    80003588:	94aa                	add	s1,s1,a0
    8000358a:	0504a983          	lw	s3,80(s1)
    8000358e:	fe0990e3          	bnez	s3,8000356e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003592:	4108                	lw	a0,0(a0)
    80003594:	00000097          	auipc	ra,0x0
    80003598:	e4a080e7          	jalr	-438(ra) # 800033de <balloc>
    8000359c:	0005099b          	sext.w	s3,a0
    800035a0:	0534a823          	sw	s3,80(s1)
    800035a4:	b7e9                	j	8000356e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035a6:	4108                	lw	a0,0(a0)
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	e36080e7          	jalr	-458(ra) # 800033de <balloc>
    800035b0:	0005059b          	sext.w	a1,a0
    800035b4:	08b92023          	sw	a1,128(s2)
    800035b8:	b759                	j	8000353e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035ba:	00092503          	lw	a0,0(s2)
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	e20080e7          	jalr	-480(ra) # 800033de <balloc>
    800035c6:	0005099b          	sext.w	s3,a0
    800035ca:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035ce:	8552                	mv	a0,s4
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	ee0080e7          	jalr	-288(ra) # 800044b0 <log_write>
    800035d8:	b771                	j	80003564 <bmap+0x54>
  panic("bmap: out of range");
    800035da:	00005517          	auipc	a0,0x5
    800035de:	fb650513          	addi	a0,a0,-74 # 80008590 <syscalls+0x118>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	f60080e7          	jalr	-160(ra) # 80000542 <panic>

00000000800035ea <iget>:
{
    800035ea:	7179                	addi	sp,sp,-48
    800035ec:	f406                	sd	ra,40(sp)
    800035ee:	f022                	sd	s0,32(sp)
    800035f0:	ec26                	sd	s1,24(sp)
    800035f2:	e84a                	sd	s2,16(sp)
    800035f4:	e44e                	sd	s3,8(sp)
    800035f6:	e052                	sd	s4,0(sp)
    800035f8:	1800                	addi	s0,sp,48
    800035fa:	89aa                	mv	s3,a0
    800035fc:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035fe:	0001d517          	auipc	a0,0x1d
    80003602:	a6250513          	addi	a0,a0,-1438 # 80020060 <icache>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	5f8080e7          	jalr	1528(ra) # 80000bfe <acquire>
  empty = 0;
    8000360e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003610:	0001d497          	auipc	s1,0x1d
    80003614:	a6848493          	addi	s1,s1,-1432 # 80020078 <icache+0x18>
    80003618:	0001e697          	auipc	a3,0x1e
    8000361c:	4f068693          	addi	a3,a3,1264 # 80021b08 <log>
    80003620:	a039                	j	8000362e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003622:	02090b63          	beqz	s2,80003658 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003626:	08848493          	addi	s1,s1,136
    8000362a:	02d48a63          	beq	s1,a3,8000365e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000362e:	449c                	lw	a5,8(s1)
    80003630:	fef059e3          	blez	a5,80003622 <iget+0x38>
    80003634:	4098                	lw	a4,0(s1)
    80003636:	ff3716e3          	bne	a4,s3,80003622 <iget+0x38>
    8000363a:	40d8                	lw	a4,4(s1)
    8000363c:	ff4713e3          	bne	a4,s4,80003622 <iget+0x38>
      ip->ref++;
    80003640:	2785                	addiw	a5,a5,1
    80003642:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003644:	0001d517          	auipc	a0,0x1d
    80003648:	a1c50513          	addi	a0,a0,-1508 # 80020060 <icache>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	666080e7          	jalr	1638(ra) # 80000cb2 <release>
      return ip;
    80003654:	8926                	mv	s2,s1
    80003656:	a03d                	j	80003684 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003658:	f7f9                	bnez	a5,80003626 <iget+0x3c>
    8000365a:	8926                	mv	s2,s1
    8000365c:	b7e9                	j	80003626 <iget+0x3c>
  if(empty == 0)
    8000365e:	02090c63          	beqz	s2,80003696 <iget+0xac>
  ip->dev = dev;
    80003662:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003666:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000366a:	4785                	li	a5,1
    8000366c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003670:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003674:	0001d517          	auipc	a0,0x1d
    80003678:	9ec50513          	addi	a0,a0,-1556 # 80020060 <icache>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	636080e7          	jalr	1590(ra) # 80000cb2 <release>
}
    80003684:	854a                	mv	a0,s2
    80003686:	70a2                	ld	ra,40(sp)
    80003688:	7402                	ld	s0,32(sp)
    8000368a:	64e2                	ld	s1,24(sp)
    8000368c:	6942                	ld	s2,16(sp)
    8000368e:	69a2                	ld	s3,8(sp)
    80003690:	6a02                	ld	s4,0(sp)
    80003692:	6145                	addi	sp,sp,48
    80003694:	8082                	ret
    panic("iget: no inodes");
    80003696:	00005517          	auipc	a0,0x5
    8000369a:	f1250513          	addi	a0,a0,-238 # 800085a8 <syscalls+0x130>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	ea4080e7          	jalr	-348(ra) # 80000542 <panic>

00000000800036a6 <fsinit>:
fsinit(int dev) {
    800036a6:	7179                	addi	sp,sp,-48
    800036a8:	f406                	sd	ra,40(sp)
    800036aa:	f022                	sd	s0,32(sp)
    800036ac:	ec26                	sd	s1,24(sp)
    800036ae:	e84a                	sd	s2,16(sp)
    800036b0:	e44e                	sd	s3,8(sp)
    800036b2:	1800                	addi	s0,sp,48
    800036b4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036b6:	4585                	li	a1,1
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	a64080e7          	jalr	-1436(ra) # 8000311c <bread>
    800036c0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036c2:	0001d997          	auipc	s3,0x1d
    800036c6:	97e98993          	addi	s3,s3,-1666 # 80020040 <sb>
    800036ca:	02000613          	li	a2,32
    800036ce:	05850593          	addi	a1,a0,88
    800036d2:	854e                	mv	a0,s3
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	682080e7          	jalr	1666(ra) # 80000d56 <memmove>
  brelse(bp);
    800036dc:	8526                	mv	a0,s1
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	b6e080e7          	jalr	-1170(ra) # 8000324c <brelse>
  if(sb.magic != FSMAGIC)
    800036e6:	0009a703          	lw	a4,0(s3)
    800036ea:	102037b7          	lui	a5,0x10203
    800036ee:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036f2:	02f71263          	bne	a4,a5,80003716 <fsinit+0x70>
  initlog(dev, &sb);
    800036f6:	0001d597          	auipc	a1,0x1d
    800036fa:	94a58593          	addi	a1,a1,-1718 # 80020040 <sb>
    800036fe:	854a                	mv	a0,s2
    80003700:	00001097          	auipc	ra,0x1
    80003704:	b38080e7          	jalr	-1224(ra) # 80004238 <initlog>
}
    80003708:	70a2                	ld	ra,40(sp)
    8000370a:	7402                	ld	s0,32(sp)
    8000370c:	64e2                	ld	s1,24(sp)
    8000370e:	6942                	ld	s2,16(sp)
    80003710:	69a2                	ld	s3,8(sp)
    80003712:	6145                	addi	sp,sp,48
    80003714:	8082                	ret
    panic("invalid file system");
    80003716:	00005517          	auipc	a0,0x5
    8000371a:	ea250513          	addi	a0,a0,-350 # 800085b8 <syscalls+0x140>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e24080e7          	jalr	-476(ra) # 80000542 <panic>

0000000080003726 <iinit>:
{
    80003726:	7179                	addi	sp,sp,-48
    80003728:	f406                	sd	ra,40(sp)
    8000372a:	f022                	sd	s0,32(sp)
    8000372c:	ec26                	sd	s1,24(sp)
    8000372e:	e84a                	sd	s2,16(sp)
    80003730:	e44e                	sd	s3,8(sp)
    80003732:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003734:	00005597          	auipc	a1,0x5
    80003738:	e9c58593          	addi	a1,a1,-356 # 800085d0 <syscalls+0x158>
    8000373c:	0001d517          	auipc	a0,0x1d
    80003740:	92450513          	addi	a0,a0,-1756 # 80020060 <icache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	42a080e7          	jalr	1066(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000374c:	0001d497          	auipc	s1,0x1d
    80003750:	93c48493          	addi	s1,s1,-1732 # 80020088 <icache+0x28>
    80003754:	0001e997          	auipc	s3,0x1e
    80003758:	3c498993          	addi	s3,s3,964 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000375c:	00005917          	auipc	s2,0x5
    80003760:	e7c90913          	addi	s2,s2,-388 # 800085d8 <syscalls+0x160>
    80003764:	85ca                	mv	a1,s2
    80003766:	8526                	mv	a0,s1
    80003768:	00001097          	auipc	ra,0x1
    8000376c:	e36080e7          	jalr	-458(ra) # 8000459e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003770:	08848493          	addi	s1,s1,136
    80003774:	ff3498e3          	bne	s1,s3,80003764 <iinit+0x3e>
}
    80003778:	70a2                	ld	ra,40(sp)
    8000377a:	7402                	ld	s0,32(sp)
    8000377c:	64e2                	ld	s1,24(sp)
    8000377e:	6942                	ld	s2,16(sp)
    80003780:	69a2                	ld	s3,8(sp)
    80003782:	6145                	addi	sp,sp,48
    80003784:	8082                	ret

0000000080003786 <ialloc>:
{
    80003786:	715d                	addi	sp,sp,-80
    80003788:	e486                	sd	ra,72(sp)
    8000378a:	e0a2                	sd	s0,64(sp)
    8000378c:	fc26                	sd	s1,56(sp)
    8000378e:	f84a                	sd	s2,48(sp)
    80003790:	f44e                	sd	s3,40(sp)
    80003792:	f052                	sd	s4,32(sp)
    80003794:	ec56                	sd	s5,24(sp)
    80003796:	e85a                	sd	s6,16(sp)
    80003798:	e45e                	sd	s7,8(sp)
    8000379a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000379c:	0001d717          	auipc	a4,0x1d
    800037a0:	8b072703          	lw	a4,-1872(a4) # 8002004c <sb+0xc>
    800037a4:	4785                	li	a5,1
    800037a6:	04e7fa63          	bgeu	a5,a4,800037fa <ialloc+0x74>
    800037aa:	8aaa                	mv	s5,a0
    800037ac:	8bae                	mv	s7,a1
    800037ae:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037b0:	0001da17          	auipc	s4,0x1d
    800037b4:	890a0a13          	addi	s4,s4,-1904 # 80020040 <sb>
    800037b8:	00048b1b          	sext.w	s6,s1
    800037bc:	0044d793          	srli	a5,s1,0x4
    800037c0:	018a2583          	lw	a1,24(s4)
    800037c4:	9dbd                	addw	a1,a1,a5
    800037c6:	8556                	mv	a0,s5
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	954080e7          	jalr	-1708(ra) # 8000311c <bread>
    800037d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037d2:	05850993          	addi	s3,a0,88
    800037d6:	00f4f793          	andi	a5,s1,15
    800037da:	079a                	slli	a5,a5,0x6
    800037dc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037de:	00099783          	lh	a5,0(s3)
    800037e2:	c785                	beqz	a5,8000380a <ialloc+0x84>
    brelse(bp);
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	a68080e7          	jalr	-1432(ra) # 8000324c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ec:	0485                	addi	s1,s1,1
    800037ee:	00ca2703          	lw	a4,12(s4)
    800037f2:	0004879b          	sext.w	a5,s1
    800037f6:	fce7e1e3          	bltu	a5,a4,800037b8 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	de650513          	addi	a0,a0,-538 # 800085e0 <syscalls+0x168>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d40080e7          	jalr	-704(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    8000380a:	04000613          	li	a2,64
    8000380e:	4581                	li	a1,0
    80003810:	854e                	mv	a0,s3
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	4e8080e7          	jalr	1256(ra) # 80000cfa <memset>
      dip->type = type;
    8000381a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	c90080e7          	jalr	-880(ra) # 800044b0 <log_write>
      brelse(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	a22080e7          	jalr	-1502(ra) # 8000324c <brelse>
      return iget(dev, inum);
    80003832:	85da                	mv	a1,s6
    80003834:	8556                	mv	a0,s5
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	db4080e7          	jalr	-588(ra) # 800035ea <iget>
}
    8000383e:	60a6                	ld	ra,72(sp)
    80003840:	6406                	ld	s0,64(sp)
    80003842:	74e2                	ld	s1,56(sp)
    80003844:	7942                	ld	s2,48(sp)
    80003846:	79a2                	ld	s3,40(sp)
    80003848:	7a02                	ld	s4,32(sp)
    8000384a:	6ae2                	ld	s5,24(sp)
    8000384c:	6b42                	ld	s6,16(sp)
    8000384e:	6ba2                	ld	s7,8(sp)
    80003850:	6161                	addi	sp,sp,80
    80003852:	8082                	ret

0000000080003854 <iupdate>:
{
    80003854:	1101                	addi	sp,sp,-32
    80003856:	ec06                	sd	ra,24(sp)
    80003858:	e822                	sd	s0,16(sp)
    8000385a:	e426                	sd	s1,8(sp)
    8000385c:	e04a                	sd	s2,0(sp)
    8000385e:	1000                	addi	s0,sp,32
    80003860:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003862:	415c                	lw	a5,4(a0)
    80003864:	0047d79b          	srliw	a5,a5,0x4
    80003868:	0001c597          	auipc	a1,0x1c
    8000386c:	7f05a583          	lw	a1,2032(a1) # 80020058 <sb+0x18>
    80003870:	9dbd                	addw	a1,a1,a5
    80003872:	4108                	lw	a0,0(a0)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	8a8080e7          	jalr	-1880(ra) # 8000311c <bread>
    8000387c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000387e:	05850793          	addi	a5,a0,88
    80003882:	40c8                	lw	a0,4(s1)
    80003884:	893d                	andi	a0,a0,15
    80003886:	051a                	slli	a0,a0,0x6
    80003888:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000388a:	04449703          	lh	a4,68(s1)
    8000388e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003892:	04649703          	lh	a4,70(s1)
    80003896:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000389a:	04849703          	lh	a4,72(s1)
    8000389e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038a2:	04a49703          	lh	a4,74(s1)
    800038a6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038aa:	44f8                	lw	a4,76(s1)
    800038ac:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ae:	03400613          	li	a2,52
    800038b2:	05048593          	addi	a1,s1,80
    800038b6:	0531                	addi	a0,a0,12
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	49e080e7          	jalr	1182(ra) # 80000d56 <memmove>
  log_write(bp);
    800038c0:	854a                	mv	a0,s2
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	bee080e7          	jalr	-1042(ra) # 800044b0 <log_write>
  brelse(bp);
    800038ca:	854a                	mv	a0,s2
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	980080e7          	jalr	-1664(ra) # 8000324c <brelse>
}
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6902                	ld	s2,0(sp)
    800038dc:	6105                	addi	sp,sp,32
    800038de:	8082                	ret

00000000800038e0 <idup>:
{
    800038e0:	1101                	addi	sp,sp,-32
    800038e2:	ec06                	sd	ra,24(sp)
    800038e4:	e822                	sd	s0,16(sp)
    800038e6:	e426                	sd	s1,8(sp)
    800038e8:	1000                	addi	s0,sp,32
    800038ea:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038ec:	0001c517          	auipc	a0,0x1c
    800038f0:	77450513          	addi	a0,a0,1908 # 80020060 <icache>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	30a080e7          	jalr	778(ra) # 80000bfe <acquire>
  ip->ref++;
    800038fc:	449c                	lw	a5,8(s1)
    800038fe:	2785                	addiw	a5,a5,1
    80003900:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003902:	0001c517          	auipc	a0,0x1c
    80003906:	75e50513          	addi	a0,a0,1886 # 80020060 <icache>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	3a8080e7          	jalr	936(ra) # 80000cb2 <release>
}
    80003912:	8526                	mv	a0,s1
    80003914:	60e2                	ld	ra,24(sp)
    80003916:	6442                	ld	s0,16(sp)
    80003918:	64a2                	ld	s1,8(sp)
    8000391a:	6105                	addi	sp,sp,32
    8000391c:	8082                	ret

000000008000391e <ilock>:
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	e426                	sd	s1,8(sp)
    80003926:	e04a                	sd	s2,0(sp)
    80003928:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000392a:	c115                	beqz	a0,8000394e <ilock+0x30>
    8000392c:	84aa                	mv	s1,a0
    8000392e:	451c                	lw	a5,8(a0)
    80003930:	00f05f63          	blez	a5,8000394e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003934:	0541                	addi	a0,a0,16
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	ca2080e7          	jalr	-862(ra) # 800045d8 <acquiresleep>
  if(ip->valid == 0){
    8000393e:	40bc                	lw	a5,64(s1)
    80003940:	cf99                	beqz	a5,8000395e <ilock+0x40>
}
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6902                	ld	s2,0(sp)
    8000394a:	6105                	addi	sp,sp,32
    8000394c:	8082                	ret
    panic("ilock");
    8000394e:	00005517          	auipc	a0,0x5
    80003952:	caa50513          	addi	a0,a0,-854 # 800085f8 <syscalls+0x180>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	bec080e7          	jalr	-1044(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000395e:	40dc                	lw	a5,4(s1)
    80003960:	0047d79b          	srliw	a5,a5,0x4
    80003964:	0001c597          	auipc	a1,0x1c
    80003968:	6f45a583          	lw	a1,1780(a1) # 80020058 <sb+0x18>
    8000396c:	9dbd                	addw	a1,a1,a5
    8000396e:	4088                	lw	a0,0(s1)
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	7ac080e7          	jalr	1964(ra) # 8000311c <bread>
    80003978:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000397a:	05850593          	addi	a1,a0,88
    8000397e:	40dc                	lw	a5,4(s1)
    80003980:	8bbd                	andi	a5,a5,15
    80003982:	079a                	slli	a5,a5,0x6
    80003984:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003986:	00059783          	lh	a5,0(a1)
    8000398a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000398e:	00259783          	lh	a5,2(a1)
    80003992:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003996:	00459783          	lh	a5,4(a1)
    8000399a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000399e:	00659783          	lh	a5,6(a1)
    800039a2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039a6:	459c                	lw	a5,8(a1)
    800039a8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039aa:	03400613          	li	a2,52
    800039ae:	05b1                	addi	a1,a1,12
    800039b0:	05048513          	addi	a0,s1,80
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	3a2080e7          	jalr	930(ra) # 80000d56 <memmove>
    brelse(bp);
    800039bc:	854a                	mv	a0,s2
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	88e080e7          	jalr	-1906(ra) # 8000324c <brelse>
    ip->valid = 1;
    800039c6:	4785                	li	a5,1
    800039c8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ca:	04449783          	lh	a5,68(s1)
    800039ce:	fbb5                	bnez	a5,80003942 <ilock+0x24>
      panic("ilock: no type");
    800039d0:	00005517          	auipc	a0,0x5
    800039d4:	c3050513          	addi	a0,a0,-976 # 80008600 <syscalls+0x188>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	b6a080e7          	jalr	-1174(ra) # 80000542 <panic>

00000000800039e0 <iunlock>:
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	e04a                	sd	s2,0(sp)
    800039ea:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ec:	c905                	beqz	a0,80003a1c <iunlock+0x3c>
    800039ee:	84aa                	mv	s1,a0
    800039f0:	01050913          	addi	s2,a0,16
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	c7c080e7          	jalr	-900(ra) # 80004672 <holdingsleep>
    800039fe:	cd19                	beqz	a0,80003a1c <iunlock+0x3c>
    80003a00:	449c                	lw	a5,8(s1)
    80003a02:	00f05d63          	blez	a5,80003a1c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a06:	854a                	mv	a0,s2
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	c26080e7          	jalr	-986(ra) # 8000462e <releasesleep>
}
    80003a10:	60e2                	ld	ra,24(sp)
    80003a12:	6442                	ld	s0,16(sp)
    80003a14:	64a2                	ld	s1,8(sp)
    80003a16:	6902                	ld	s2,0(sp)
    80003a18:	6105                	addi	sp,sp,32
    80003a1a:	8082                	ret
    panic("iunlock");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	bf450513          	addi	a0,a0,-1036 # 80008610 <syscalls+0x198>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b1e080e7          	jalr	-1250(ra) # 80000542 <panic>

0000000080003a2c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a2c:	7179                	addi	sp,sp,-48
    80003a2e:	f406                	sd	ra,40(sp)
    80003a30:	f022                	sd	s0,32(sp)
    80003a32:	ec26                	sd	s1,24(sp)
    80003a34:	e84a                	sd	s2,16(sp)
    80003a36:	e44e                	sd	s3,8(sp)
    80003a38:	e052                	sd	s4,0(sp)
    80003a3a:	1800                	addi	s0,sp,48
    80003a3c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a3e:	05050493          	addi	s1,a0,80
    80003a42:	08050913          	addi	s2,a0,128
    80003a46:	a021                	j	80003a4e <itrunc+0x22>
    80003a48:	0491                	addi	s1,s1,4
    80003a4a:	01248d63          	beq	s1,s2,80003a64 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a4e:	408c                	lw	a1,0(s1)
    80003a50:	dde5                	beqz	a1,80003a48 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a52:	0009a503          	lw	a0,0(s3)
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	90c080e7          	jalr	-1780(ra) # 80003362 <bfree>
      ip->addrs[i] = 0;
    80003a5e:	0004a023          	sw	zero,0(s1)
    80003a62:	b7dd                	j	80003a48 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a64:	0809a583          	lw	a1,128(s3)
    80003a68:	e185                	bnez	a1,80003a88 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a6a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a6e:	854e                	mv	a0,s3
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	de4080e7          	jalr	-540(ra) # 80003854 <iupdate>
}
    80003a78:	70a2                	ld	ra,40(sp)
    80003a7a:	7402                	ld	s0,32(sp)
    80003a7c:	64e2                	ld	s1,24(sp)
    80003a7e:	6942                	ld	s2,16(sp)
    80003a80:	69a2                	ld	s3,8(sp)
    80003a82:	6a02                	ld	s4,0(sp)
    80003a84:	6145                	addi	sp,sp,48
    80003a86:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	690080e7          	jalr	1680(ra) # 8000311c <bread>
    80003a94:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a96:	05850493          	addi	s1,a0,88
    80003a9a:	45850913          	addi	s2,a0,1112
    80003a9e:	a021                	j	80003aa6 <itrunc+0x7a>
    80003aa0:	0491                	addi	s1,s1,4
    80003aa2:	01248b63          	beq	s1,s2,80003ab8 <itrunc+0x8c>
      if(a[j])
    80003aa6:	408c                	lw	a1,0(s1)
    80003aa8:	dde5                	beqz	a1,80003aa0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	8b4080e7          	jalr	-1868(ra) # 80003362 <bfree>
    80003ab6:	b7ed                	j	80003aa0 <itrunc+0x74>
    brelse(bp);
    80003ab8:	8552                	mv	a0,s4
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	792080e7          	jalr	1938(ra) # 8000324c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ac2:	0809a583          	lw	a1,128(s3)
    80003ac6:	0009a503          	lw	a0,0(s3)
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	898080e7          	jalr	-1896(ra) # 80003362 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ad2:	0809a023          	sw	zero,128(s3)
    80003ad6:	bf51                	j	80003a6a <itrunc+0x3e>

0000000080003ad8 <iput>:
{
    80003ad8:	1101                	addi	sp,sp,-32
    80003ada:	ec06                	sd	ra,24(sp)
    80003adc:	e822                	sd	s0,16(sp)
    80003ade:	e426                	sd	s1,8(sp)
    80003ae0:	e04a                	sd	s2,0(sp)
    80003ae2:	1000                	addi	s0,sp,32
    80003ae4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ae6:	0001c517          	auipc	a0,0x1c
    80003aea:	57a50513          	addi	a0,a0,1402 # 80020060 <icache>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	110080e7          	jalr	272(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003af6:	4498                	lw	a4,8(s1)
    80003af8:	4785                	li	a5,1
    80003afa:	02f70363          	beq	a4,a5,80003b20 <iput+0x48>
  ip->ref--;
    80003afe:	449c                	lw	a5,8(s1)
    80003b00:	37fd                	addiw	a5,a5,-1
    80003b02:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b04:	0001c517          	auipc	a0,0x1c
    80003b08:	55c50513          	addi	a0,a0,1372 # 80020060 <icache>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	1a6080e7          	jalr	422(ra) # 80000cb2 <release>
}
    80003b14:	60e2                	ld	ra,24(sp)
    80003b16:	6442                	ld	s0,16(sp)
    80003b18:	64a2                	ld	s1,8(sp)
    80003b1a:	6902                	ld	s2,0(sp)
    80003b1c:	6105                	addi	sp,sp,32
    80003b1e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b20:	40bc                	lw	a5,64(s1)
    80003b22:	dff1                	beqz	a5,80003afe <iput+0x26>
    80003b24:	04a49783          	lh	a5,74(s1)
    80003b28:	fbf9                	bnez	a5,80003afe <iput+0x26>
    acquiresleep(&ip->lock);
    80003b2a:	01048913          	addi	s2,s1,16
    80003b2e:	854a                	mv	a0,s2
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	aa8080e7          	jalr	-1368(ra) # 800045d8 <acquiresleep>
    release(&icache.lock);
    80003b38:	0001c517          	auipc	a0,0x1c
    80003b3c:	52850513          	addi	a0,a0,1320 # 80020060 <icache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	172080e7          	jalr	370(ra) # 80000cb2 <release>
    itrunc(ip);
    80003b48:	8526                	mv	a0,s1
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	ee2080e7          	jalr	-286(ra) # 80003a2c <itrunc>
    ip->type = 0;
    80003b52:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b56:	8526                	mv	a0,s1
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	cfc080e7          	jalr	-772(ra) # 80003854 <iupdate>
    ip->valid = 0;
    80003b60:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	ac8080e7          	jalr	-1336(ra) # 8000462e <releasesleep>
    acquire(&icache.lock);
    80003b6e:	0001c517          	auipc	a0,0x1c
    80003b72:	4f250513          	addi	a0,a0,1266 # 80020060 <icache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	088080e7          	jalr	136(ra) # 80000bfe <acquire>
    80003b7e:	b741                	j	80003afe <iput+0x26>

0000000080003b80 <iunlockput>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	1000                	addi	s0,sp,32
    80003b8a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	e54080e7          	jalr	-428(ra) # 800039e0 <iunlock>
  iput(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	f42080e7          	jalr	-190(ra) # 80003ad8 <iput>
}
    80003b9e:	60e2                	ld	ra,24(sp)
    80003ba0:	6442                	ld	s0,16(sp)
    80003ba2:	64a2                	ld	s1,8(sp)
    80003ba4:	6105                	addi	sp,sp,32
    80003ba6:	8082                	ret

0000000080003ba8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ba8:	1141                	addi	sp,sp,-16
    80003baa:	e422                	sd	s0,8(sp)
    80003bac:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bae:	411c                	lw	a5,0(a0)
    80003bb0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bb2:	415c                	lw	a5,4(a0)
    80003bb4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bb6:	04451783          	lh	a5,68(a0)
    80003bba:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bbe:	04a51783          	lh	a5,74(a0)
    80003bc2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bc6:	04c56783          	lwu	a5,76(a0)
    80003bca:	e99c                	sd	a5,16(a1)
}
    80003bcc:	6422                	ld	s0,8(sp)
    80003bce:	0141                	addi	sp,sp,16
    80003bd0:	8082                	ret

0000000080003bd2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd2:	457c                	lw	a5,76(a0)
    80003bd4:	0ed7e863          	bltu	a5,a3,80003cc4 <readi+0xf2>
{
    80003bd8:	7159                	addi	sp,sp,-112
    80003bda:	f486                	sd	ra,104(sp)
    80003bdc:	f0a2                	sd	s0,96(sp)
    80003bde:	eca6                	sd	s1,88(sp)
    80003be0:	e8ca                	sd	s2,80(sp)
    80003be2:	e4ce                	sd	s3,72(sp)
    80003be4:	e0d2                	sd	s4,64(sp)
    80003be6:	fc56                	sd	s5,56(sp)
    80003be8:	f85a                	sd	s6,48(sp)
    80003bea:	f45e                	sd	s7,40(sp)
    80003bec:	f062                	sd	s8,32(sp)
    80003bee:	ec66                	sd	s9,24(sp)
    80003bf0:	e86a                	sd	s10,16(sp)
    80003bf2:	e46e                	sd	s11,8(sp)
    80003bf4:	1880                	addi	s0,sp,112
    80003bf6:	8baa                	mv	s7,a0
    80003bf8:	8c2e                	mv	s8,a1
    80003bfa:	8ab2                	mv	s5,a2
    80003bfc:	84b6                	mv	s1,a3
    80003bfe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c00:	9f35                	addw	a4,a4,a3
    return 0;
    80003c02:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c04:	08d76f63          	bltu	a4,a3,80003ca2 <readi+0xd0>
  if(off + n > ip->size)
    80003c08:	00e7f463          	bgeu	a5,a4,80003c10 <readi+0x3e>
    n = ip->size - off;
    80003c0c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c10:	0a0b0863          	beqz	s6,80003cc0 <readi+0xee>
    80003c14:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c16:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c1a:	5cfd                	li	s9,-1
    80003c1c:	a82d                	j	80003c56 <readi+0x84>
    80003c1e:	020a1d93          	slli	s11,s4,0x20
    80003c22:	020ddd93          	srli	s11,s11,0x20
    80003c26:	05890793          	addi	a5,s2,88
    80003c2a:	86ee                	mv	a3,s11
    80003c2c:	963e                	add	a2,a2,a5
    80003c2e:	85d6                	mv	a1,s5
    80003c30:	8562                	mv	a0,s8
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	b30080e7          	jalr	-1232(ra) # 80002762 <either_copyout>
    80003c3a:	05950d63          	beq	a0,s9,80003c94 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c3e:	854a                	mv	a0,s2
    80003c40:	fffff097          	auipc	ra,0xfffff
    80003c44:	60c080e7          	jalr	1548(ra) # 8000324c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c48:	013a09bb          	addw	s3,s4,s3
    80003c4c:	009a04bb          	addw	s1,s4,s1
    80003c50:	9aee                	add	s5,s5,s11
    80003c52:	0569f663          	bgeu	s3,s6,80003c9e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c56:	000ba903          	lw	s2,0(s7)
    80003c5a:	00a4d59b          	srliw	a1,s1,0xa
    80003c5e:	855e                	mv	a0,s7
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	8b0080e7          	jalr	-1872(ra) # 80003510 <bmap>
    80003c68:	0005059b          	sext.w	a1,a0
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	4ae080e7          	jalr	1198(ra) # 8000311c <bread>
    80003c76:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c78:	3ff4f613          	andi	a2,s1,1023
    80003c7c:	40cd07bb          	subw	a5,s10,a2
    80003c80:	413b073b          	subw	a4,s6,s3
    80003c84:	8a3e                	mv	s4,a5
    80003c86:	2781                	sext.w	a5,a5
    80003c88:	0007069b          	sext.w	a3,a4
    80003c8c:	f8f6f9e3          	bgeu	a3,a5,80003c1e <readi+0x4c>
    80003c90:	8a3a                	mv	s4,a4
    80003c92:	b771                	j	80003c1e <readi+0x4c>
      brelse(bp);
    80003c94:	854a                	mv	a0,s2
    80003c96:	fffff097          	auipc	ra,0xfffff
    80003c9a:	5b6080e7          	jalr	1462(ra) # 8000324c <brelse>
  }
  return tot;
    80003c9e:	0009851b          	sext.w	a0,s3
}
    80003ca2:	70a6                	ld	ra,104(sp)
    80003ca4:	7406                	ld	s0,96(sp)
    80003ca6:	64e6                	ld	s1,88(sp)
    80003ca8:	6946                	ld	s2,80(sp)
    80003caa:	69a6                	ld	s3,72(sp)
    80003cac:	6a06                	ld	s4,64(sp)
    80003cae:	7ae2                	ld	s5,56(sp)
    80003cb0:	7b42                	ld	s6,48(sp)
    80003cb2:	7ba2                	ld	s7,40(sp)
    80003cb4:	7c02                	ld	s8,32(sp)
    80003cb6:	6ce2                	ld	s9,24(sp)
    80003cb8:	6d42                	ld	s10,16(sp)
    80003cba:	6da2                	ld	s11,8(sp)
    80003cbc:	6165                	addi	sp,sp,112
    80003cbe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc0:	89da                	mv	s3,s6
    80003cc2:	bff1                	j	80003c9e <readi+0xcc>
    return 0;
    80003cc4:	4501                	li	a0,0
}
    80003cc6:	8082                	ret

0000000080003cc8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cc8:	457c                	lw	a5,76(a0)
    80003cca:	10d7e663          	bltu	a5,a3,80003dd6 <writei+0x10e>
{
    80003cce:	7159                	addi	sp,sp,-112
    80003cd0:	f486                	sd	ra,104(sp)
    80003cd2:	f0a2                	sd	s0,96(sp)
    80003cd4:	eca6                	sd	s1,88(sp)
    80003cd6:	e8ca                	sd	s2,80(sp)
    80003cd8:	e4ce                	sd	s3,72(sp)
    80003cda:	e0d2                	sd	s4,64(sp)
    80003cdc:	fc56                	sd	s5,56(sp)
    80003cde:	f85a                	sd	s6,48(sp)
    80003ce0:	f45e                	sd	s7,40(sp)
    80003ce2:	f062                	sd	s8,32(sp)
    80003ce4:	ec66                	sd	s9,24(sp)
    80003ce6:	e86a                	sd	s10,16(sp)
    80003ce8:	e46e                	sd	s11,8(sp)
    80003cea:	1880                	addi	s0,sp,112
    80003cec:	8baa                	mv	s7,a0
    80003cee:	8c2e                	mv	s8,a1
    80003cf0:	8ab2                	mv	s5,a2
    80003cf2:	8936                	mv	s2,a3
    80003cf4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cf6:	00e687bb          	addw	a5,a3,a4
    80003cfa:	0ed7e063          	bltu	a5,a3,80003dda <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cfe:	00043737          	lui	a4,0x43
    80003d02:	0cf76e63          	bltu	a4,a5,80003dde <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d06:	0a0b0763          	beqz	s6,80003db4 <writei+0xec>
    80003d0a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d0c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d10:	5cfd                	li	s9,-1
    80003d12:	a091                	j	80003d56 <writei+0x8e>
    80003d14:	02099d93          	slli	s11,s3,0x20
    80003d18:	020ddd93          	srli	s11,s11,0x20
    80003d1c:	05848793          	addi	a5,s1,88
    80003d20:	86ee                	mv	a3,s11
    80003d22:	8656                	mv	a2,s5
    80003d24:	85e2                	mv	a1,s8
    80003d26:	953e                	add	a0,a0,a5
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	a90080e7          	jalr	-1392(ra) # 800027b8 <either_copyin>
    80003d30:	07950263          	beq	a0,s9,80003d94 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d34:	8526                	mv	a0,s1
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	77a080e7          	jalr	1914(ra) # 800044b0 <log_write>
    brelse(bp);
    80003d3e:	8526                	mv	a0,s1
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	50c080e7          	jalr	1292(ra) # 8000324c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d48:	01498a3b          	addw	s4,s3,s4
    80003d4c:	0129893b          	addw	s2,s3,s2
    80003d50:	9aee                	add	s5,s5,s11
    80003d52:	056a7663          	bgeu	s4,s6,80003d9e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d56:	000ba483          	lw	s1,0(s7)
    80003d5a:	00a9559b          	srliw	a1,s2,0xa
    80003d5e:	855e                	mv	a0,s7
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	7b0080e7          	jalr	1968(ra) # 80003510 <bmap>
    80003d68:	0005059b          	sext.w	a1,a0
    80003d6c:	8526                	mv	a0,s1
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	3ae080e7          	jalr	942(ra) # 8000311c <bread>
    80003d76:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d78:	3ff97513          	andi	a0,s2,1023
    80003d7c:	40ad07bb          	subw	a5,s10,a0
    80003d80:	414b073b          	subw	a4,s6,s4
    80003d84:	89be                	mv	s3,a5
    80003d86:	2781                	sext.w	a5,a5
    80003d88:	0007069b          	sext.w	a3,a4
    80003d8c:	f8f6f4e3          	bgeu	a3,a5,80003d14 <writei+0x4c>
    80003d90:	89ba                	mv	s3,a4
    80003d92:	b749                	j	80003d14 <writei+0x4c>
      brelse(bp);
    80003d94:	8526                	mv	a0,s1
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	4b6080e7          	jalr	1206(ra) # 8000324c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d9e:	04cba783          	lw	a5,76(s7)
    80003da2:	0127f463          	bgeu	a5,s2,80003daa <writei+0xe2>
      ip->size = off;
    80003da6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003daa:	855e                	mv	a0,s7
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	aa8080e7          	jalr	-1368(ra) # 80003854 <iupdate>
  }

  return n;
    80003db4:	000b051b          	sext.w	a0,s6
}
    80003db8:	70a6                	ld	ra,104(sp)
    80003dba:	7406                	ld	s0,96(sp)
    80003dbc:	64e6                	ld	s1,88(sp)
    80003dbe:	6946                	ld	s2,80(sp)
    80003dc0:	69a6                	ld	s3,72(sp)
    80003dc2:	6a06                	ld	s4,64(sp)
    80003dc4:	7ae2                	ld	s5,56(sp)
    80003dc6:	7b42                	ld	s6,48(sp)
    80003dc8:	7ba2                	ld	s7,40(sp)
    80003dca:	7c02                	ld	s8,32(sp)
    80003dcc:	6ce2                	ld	s9,24(sp)
    80003dce:	6d42                	ld	s10,16(sp)
    80003dd0:	6da2                	ld	s11,8(sp)
    80003dd2:	6165                	addi	sp,sp,112
    80003dd4:	8082                	ret
    return -1;
    80003dd6:	557d                	li	a0,-1
}
    80003dd8:	8082                	ret
    return -1;
    80003dda:	557d                	li	a0,-1
    80003ddc:	bff1                	j	80003db8 <writei+0xf0>
    return -1;
    80003dde:	557d                	li	a0,-1
    80003de0:	bfe1                	j	80003db8 <writei+0xf0>

0000000080003de2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003de2:	1141                	addi	sp,sp,-16
    80003de4:	e406                	sd	ra,8(sp)
    80003de6:	e022                	sd	s0,0(sp)
    80003de8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dea:	4639                	li	a2,14
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	fe6080e7          	jalr	-26(ra) # 80000dd2 <strncmp>
}
    80003df4:	60a2                	ld	ra,8(sp)
    80003df6:	6402                	ld	s0,0(sp)
    80003df8:	0141                	addi	sp,sp,16
    80003dfa:	8082                	ret

0000000080003dfc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dfc:	7139                	addi	sp,sp,-64
    80003dfe:	fc06                	sd	ra,56(sp)
    80003e00:	f822                	sd	s0,48(sp)
    80003e02:	f426                	sd	s1,40(sp)
    80003e04:	f04a                	sd	s2,32(sp)
    80003e06:	ec4e                	sd	s3,24(sp)
    80003e08:	e852                	sd	s4,16(sp)
    80003e0a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e0c:	04451703          	lh	a4,68(a0)
    80003e10:	4785                	li	a5,1
    80003e12:	00f71a63          	bne	a4,a5,80003e26 <dirlookup+0x2a>
    80003e16:	892a                	mv	s2,a0
    80003e18:	89ae                	mv	s3,a1
    80003e1a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e1c:	457c                	lw	a5,76(a0)
    80003e1e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e20:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e22:	e79d                	bnez	a5,80003e50 <dirlookup+0x54>
    80003e24:	a8a5                	j	80003e9c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e26:	00004517          	auipc	a0,0x4
    80003e2a:	7f250513          	addi	a0,a0,2034 # 80008618 <syscalls+0x1a0>
    80003e2e:	ffffc097          	auipc	ra,0xffffc
    80003e32:	714080e7          	jalr	1812(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003e36:	00004517          	auipc	a0,0x4
    80003e3a:	7fa50513          	addi	a0,a0,2042 # 80008630 <syscalls+0x1b8>
    80003e3e:	ffffc097          	auipc	ra,0xffffc
    80003e42:	704080e7          	jalr	1796(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e46:	24c1                	addiw	s1,s1,16
    80003e48:	04c92783          	lw	a5,76(s2)
    80003e4c:	04f4f763          	bgeu	s1,a5,80003e9a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e50:	4741                	li	a4,16
    80003e52:	86a6                	mv	a3,s1
    80003e54:	fc040613          	addi	a2,s0,-64
    80003e58:	4581                	li	a1,0
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	d76080e7          	jalr	-650(ra) # 80003bd2 <readi>
    80003e64:	47c1                	li	a5,16
    80003e66:	fcf518e3          	bne	a0,a5,80003e36 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e6a:	fc045783          	lhu	a5,-64(s0)
    80003e6e:	dfe1                	beqz	a5,80003e46 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e70:	fc240593          	addi	a1,s0,-62
    80003e74:	854e                	mv	a0,s3
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	f6c080e7          	jalr	-148(ra) # 80003de2 <namecmp>
    80003e7e:	f561                	bnez	a0,80003e46 <dirlookup+0x4a>
      if(poff)
    80003e80:	000a0463          	beqz	s4,80003e88 <dirlookup+0x8c>
        *poff = off;
    80003e84:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e88:	fc045583          	lhu	a1,-64(s0)
    80003e8c:	00092503          	lw	a0,0(s2)
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	75a080e7          	jalr	1882(ra) # 800035ea <iget>
    80003e98:	a011                	j	80003e9c <dirlookup+0xa0>
  return 0;
    80003e9a:	4501                	li	a0,0
}
    80003e9c:	70e2                	ld	ra,56(sp)
    80003e9e:	7442                	ld	s0,48(sp)
    80003ea0:	74a2                	ld	s1,40(sp)
    80003ea2:	7902                	ld	s2,32(sp)
    80003ea4:	69e2                	ld	s3,24(sp)
    80003ea6:	6a42                	ld	s4,16(sp)
    80003ea8:	6121                	addi	sp,sp,64
    80003eaa:	8082                	ret

0000000080003eac <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003eac:	711d                	addi	sp,sp,-96
    80003eae:	ec86                	sd	ra,88(sp)
    80003eb0:	e8a2                	sd	s0,80(sp)
    80003eb2:	e4a6                	sd	s1,72(sp)
    80003eb4:	e0ca                	sd	s2,64(sp)
    80003eb6:	fc4e                	sd	s3,56(sp)
    80003eb8:	f852                	sd	s4,48(sp)
    80003eba:	f456                	sd	s5,40(sp)
    80003ebc:	f05a                	sd	s6,32(sp)
    80003ebe:	ec5e                	sd	s7,24(sp)
    80003ec0:	e862                	sd	s8,16(sp)
    80003ec2:	e466                	sd	s9,8(sp)
    80003ec4:	1080                	addi	s0,sp,96
    80003ec6:	84aa                	mv	s1,a0
    80003ec8:	8aae                	mv	s5,a1
    80003eca:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ecc:	00054703          	lbu	a4,0(a0)
    80003ed0:	02f00793          	li	a5,47
    80003ed4:	02f70363          	beq	a4,a5,80003efa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ed8:	ffffe097          	auipc	ra,0xffffe
    80003edc:	c06080e7          	jalr	-1018(ra) # 80001ade <myproc>
    80003ee0:	15853503          	ld	a0,344(a0)
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	9fc080e7          	jalr	-1540(ra) # 800038e0 <idup>
    80003eec:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eee:	02f00913          	li	s2,47
  len = path - s;
    80003ef2:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003ef4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ef6:	4b85                	li	s7,1
    80003ef8:	a865                	j	80003fb0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003efa:	4585                	li	a1,1
    80003efc:	4505                	li	a0,1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	6ec080e7          	jalr	1772(ra) # 800035ea <iget>
    80003f06:	89aa                	mv	s3,a0
    80003f08:	b7dd                	j	80003eee <namex+0x42>
      iunlockput(ip);
    80003f0a:	854e                	mv	a0,s3
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	c74080e7          	jalr	-908(ra) # 80003b80 <iunlockput>
      return 0;
    80003f14:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f16:	854e                	mv	a0,s3
    80003f18:	60e6                	ld	ra,88(sp)
    80003f1a:	6446                	ld	s0,80(sp)
    80003f1c:	64a6                	ld	s1,72(sp)
    80003f1e:	6906                	ld	s2,64(sp)
    80003f20:	79e2                	ld	s3,56(sp)
    80003f22:	7a42                	ld	s4,48(sp)
    80003f24:	7aa2                	ld	s5,40(sp)
    80003f26:	7b02                	ld	s6,32(sp)
    80003f28:	6be2                	ld	s7,24(sp)
    80003f2a:	6c42                	ld	s8,16(sp)
    80003f2c:	6ca2                	ld	s9,8(sp)
    80003f2e:	6125                	addi	sp,sp,96
    80003f30:	8082                	ret
      iunlock(ip);
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	aac080e7          	jalr	-1364(ra) # 800039e0 <iunlock>
      return ip;
    80003f3c:	bfe9                	j	80003f16 <namex+0x6a>
      iunlockput(ip);
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	c40080e7          	jalr	-960(ra) # 80003b80 <iunlockput>
      return 0;
    80003f48:	89e6                	mv	s3,s9
    80003f4a:	b7f1                	j	80003f16 <namex+0x6a>
  len = path - s;
    80003f4c:	40b48633          	sub	a2,s1,a1
    80003f50:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f54:	099c5463          	bge	s8,s9,80003fdc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f58:	4639                	li	a2,14
    80003f5a:	8552                	mv	a0,s4
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	dfa080e7          	jalr	-518(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003f64:	0004c783          	lbu	a5,0(s1)
    80003f68:	01279763          	bne	a5,s2,80003f76 <namex+0xca>
    path++;
    80003f6c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f6e:	0004c783          	lbu	a5,0(s1)
    80003f72:	ff278de3          	beq	a5,s2,80003f6c <namex+0xc0>
    ilock(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	9a6080e7          	jalr	-1626(ra) # 8000391e <ilock>
    if(ip->type != T_DIR){
    80003f80:	04499783          	lh	a5,68(s3)
    80003f84:	f97793e3          	bne	a5,s7,80003f0a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f88:	000a8563          	beqz	s5,80003f92 <namex+0xe6>
    80003f8c:	0004c783          	lbu	a5,0(s1)
    80003f90:	d3cd                	beqz	a5,80003f32 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f92:	865a                	mv	a2,s6
    80003f94:	85d2                	mv	a1,s4
    80003f96:	854e                	mv	a0,s3
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	e64080e7          	jalr	-412(ra) # 80003dfc <dirlookup>
    80003fa0:	8caa                	mv	s9,a0
    80003fa2:	dd51                	beqz	a0,80003f3e <namex+0x92>
    iunlockput(ip);
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	bda080e7          	jalr	-1062(ra) # 80003b80 <iunlockput>
    ip = next;
    80003fae:	89e6                	mv	s3,s9
  while(*path == '/')
    80003fb0:	0004c783          	lbu	a5,0(s1)
    80003fb4:	05279763          	bne	a5,s2,80004002 <namex+0x156>
    path++;
    80003fb8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	ff278de3          	beq	a5,s2,80003fb8 <namex+0x10c>
  if(*path == 0)
    80003fc2:	c79d                	beqz	a5,80003ff0 <namex+0x144>
    path++;
    80003fc4:	85a6                	mv	a1,s1
  len = path - s;
    80003fc6:	8cda                	mv	s9,s6
    80003fc8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fca:	01278963          	beq	a5,s2,80003fdc <namex+0x130>
    80003fce:	dfbd                	beqz	a5,80003f4c <namex+0xa0>
    path++;
    80003fd0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fd2:	0004c783          	lbu	a5,0(s1)
    80003fd6:	ff279ce3          	bne	a5,s2,80003fce <namex+0x122>
    80003fda:	bf8d                	j	80003f4c <namex+0xa0>
    memmove(name, s, len);
    80003fdc:	2601                	sext.w	a2,a2
    80003fde:	8552                	mv	a0,s4
    80003fe0:	ffffd097          	auipc	ra,0xffffd
    80003fe4:	d76080e7          	jalr	-650(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003fe8:	9cd2                	add	s9,s9,s4
    80003fea:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fee:	bf9d                	j	80003f64 <namex+0xb8>
  if(nameiparent){
    80003ff0:	f20a83e3          	beqz	s5,80003f16 <namex+0x6a>
    iput(ip);
    80003ff4:	854e                	mv	a0,s3
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	ae2080e7          	jalr	-1310(ra) # 80003ad8 <iput>
    return 0;
    80003ffe:	4981                	li	s3,0
    80004000:	bf19                	j	80003f16 <namex+0x6a>
  if(*path == 0)
    80004002:	d7fd                	beqz	a5,80003ff0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	85a6                	mv	a1,s1
    8000400a:	b7d1                	j	80003fce <namex+0x122>

000000008000400c <dirlink>:
{
    8000400c:	7139                	addi	sp,sp,-64
    8000400e:	fc06                	sd	ra,56(sp)
    80004010:	f822                	sd	s0,48(sp)
    80004012:	f426                	sd	s1,40(sp)
    80004014:	f04a                	sd	s2,32(sp)
    80004016:	ec4e                	sd	s3,24(sp)
    80004018:	e852                	sd	s4,16(sp)
    8000401a:	0080                	addi	s0,sp,64
    8000401c:	892a                	mv	s2,a0
    8000401e:	8a2e                	mv	s4,a1
    80004020:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004022:	4601                	li	a2,0
    80004024:	00000097          	auipc	ra,0x0
    80004028:	dd8080e7          	jalr	-552(ra) # 80003dfc <dirlookup>
    8000402c:	e93d                	bnez	a0,800040a2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000402e:	04c92483          	lw	s1,76(s2)
    80004032:	c49d                	beqz	s1,80004060 <dirlink+0x54>
    80004034:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004036:	4741                	li	a4,16
    80004038:	86a6                	mv	a3,s1
    8000403a:	fc040613          	addi	a2,s0,-64
    8000403e:	4581                	li	a1,0
    80004040:	854a                	mv	a0,s2
    80004042:	00000097          	auipc	ra,0x0
    80004046:	b90080e7          	jalr	-1136(ra) # 80003bd2 <readi>
    8000404a:	47c1                	li	a5,16
    8000404c:	06f51163          	bne	a0,a5,800040ae <dirlink+0xa2>
    if(de.inum == 0)
    80004050:	fc045783          	lhu	a5,-64(s0)
    80004054:	c791                	beqz	a5,80004060 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004056:	24c1                	addiw	s1,s1,16
    80004058:	04c92783          	lw	a5,76(s2)
    8000405c:	fcf4ede3          	bltu	s1,a5,80004036 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004060:	4639                	li	a2,14
    80004062:	85d2                	mv	a1,s4
    80004064:	fc240513          	addi	a0,s0,-62
    80004068:	ffffd097          	auipc	ra,0xffffd
    8000406c:	da6080e7          	jalr	-602(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80004070:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004074:	4741                	li	a4,16
    80004076:	86a6                	mv	a3,s1
    80004078:	fc040613          	addi	a2,s0,-64
    8000407c:	4581                	li	a1,0
    8000407e:	854a                	mv	a0,s2
    80004080:	00000097          	auipc	ra,0x0
    80004084:	c48080e7          	jalr	-952(ra) # 80003cc8 <writei>
    80004088:	872a                	mv	a4,a0
    8000408a:	47c1                	li	a5,16
  return 0;
    8000408c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000408e:	02f71863          	bne	a4,a5,800040be <dirlink+0xb2>
}
    80004092:	70e2                	ld	ra,56(sp)
    80004094:	7442                	ld	s0,48(sp)
    80004096:	74a2                	ld	s1,40(sp)
    80004098:	7902                	ld	s2,32(sp)
    8000409a:	69e2                	ld	s3,24(sp)
    8000409c:	6a42                	ld	s4,16(sp)
    8000409e:	6121                	addi	sp,sp,64
    800040a0:	8082                	ret
    iput(ip);
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	a36080e7          	jalr	-1482(ra) # 80003ad8 <iput>
    return -1;
    800040aa:	557d                	li	a0,-1
    800040ac:	b7dd                	j	80004092 <dirlink+0x86>
      panic("dirlink read");
    800040ae:	00004517          	auipc	a0,0x4
    800040b2:	59250513          	addi	a0,a0,1426 # 80008640 <syscalls+0x1c8>
    800040b6:	ffffc097          	auipc	ra,0xffffc
    800040ba:	48c080e7          	jalr	1164(ra) # 80000542 <panic>
    panic("dirlink");
    800040be:	00004517          	auipc	a0,0x4
    800040c2:	69a50513          	addi	a0,a0,1690 # 80008758 <syscalls+0x2e0>
    800040c6:	ffffc097          	auipc	ra,0xffffc
    800040ca:	47c080e7          	jalr	1148(ra) # 80000542 <panic>

00000000800040ce <namei>:

struct inode*
namei(char *path)
{
    800040ce:	1101                	addi	sp,sp,-32
    800040d0:	ec06                	sd	ra,24(sp)
    800040d2:	e822                	sd	s0,16(sp)
    800040d4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040d6:	fe040613          	addi	a2,s0,-32
    800040da:	4581                	li	a1,0
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	dd0080e7          	jalr	-560(ra) # 80003eac <namex>
}
    800040e4:	60e2                	ld	ra,24(sp)
    800040e6:	6442                	ld	s0,16(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret

00000000800040ec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040ec:	1141                	addi	sp,sp,-16
    800040ee:	e406                	sd	ra,8(sp)
    800040f0:	e022                	sd	s0,0(sp)
    800040f2:	0800                	addi	s0,sp,16
    800040f4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040f6:	4585                	li	a1,1
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	db4080e7          	jalr	-588(ra) # 80003eac <namex>
}
    80004100:	60a2                	ld	ra,8(sp)
    80004102:	6402                	ld	s0,0(sp)
    80004104:	0141                	addi	sp,sp,16
    80004106:	8082                	ret

0000000080004108 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004108:	1101                	addi	sp,sp,-32
    8000410a:	ec06                	sd	ra,24(sp)
    8000410c:	e822                	sd	s0,16(sp)
    8000410e:	e426                	sd	s1,8(sp)
    80004110:	e04a                	sd	s2,0(sp)
    80004112:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004114:	0001e917          	auipc	s2,0x1e
    80004118:	9f490913          	addi	s2,s2,-1548 # 80021b08 <log>
    8000411c:	01892583          	lw	a1,24(s2)
    80004120:	02892503          	lw	a0,40(s2)
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	ff8080e7          	jalr	-8(ra) # 8000311c <bread>
    8000412c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000412e:	02c92683          	lw	a3,44(s2)
    80004132:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004134:	02d05763          	blez	a3,80004162 <write_head+0x5a>
    80004138:	0001e797          	auipc	a5,0x1e
    8000413c:	a0078793          	addi	a5,a5,-1536 # 80021b38 <log+0x30>
    80004140:	05c50713          	addi	a4,a0,92
    80004144:	36fd                	addiw	a3,a3,-1
    80004146:	1682                	slli	a3,a3,0x20
    80004148:	9281                	srli	a3,a3,0x20
    8000414a:	068a                	slli	a3,a3,0x2
    8000414c:	0001e617          	auipc	a2,0x1e
    80004150:	9f060613          	addi	a2,a2,-1552 # 80021b3c <log+0x34>
    80004154:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004156:	4390                	lw	a2,0(a5)
    80004158:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000415a:	0791                	addi	a5,a5,4
    8000415c:	0711                	addi	a4,a4,4
    8000415e:	fed79ce3          	bne	a5,a3,80004156 <write_head+0x4e>
  }
  bwrite(buf);
    80004162:	8526                	mv	a0,s1
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	0aa080e7          	jalr	170(ra) # 8000320e <bwrite>
  brelse(buf);
    8000416c:	8526                	mv	a0,s1
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	0de080e7          	jalr	222(ra) # 8000324c <brelse>
}
    80004176:	60e2                	ld	ra,24(sp)
    80004178:	6442                	ld	s0,16(sp)
    8000417a:	64a2                	ld	s1,8(sp)
    8000417c:	6902                	ld	s2,0(sp)
    8000417e:	6105                	addi	sp,sp,32
    80004180:	8082                	ret

0000000080004182 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004182:	0001e797          	auipc	a5,0x1e
    80004186:	9b27a783          	lw	a5,-1614(a5) # 80021b34 <log+0x2c>
    8000418a:	0af05663          	blez	a5,80004236 <install_trans+0xb4>
{
    8000418e:	7139                	addi	sp,sp,-64
    80004190:	fc06                	sd	ra,56(sp)
    80004192:	f822                	sd	s0,48(sp)
    80004194:	f426                	sd	s1,40(sp)
    80004196:	f04a                	sd	s2,32(sp)
    80004198:	ec4e                	sd	s3,24(sp)
    8000419a:	e852                	sd	s4,16(sp)
    8000419c:	e456                	sd	s5,8(sp)
    8000419e:	0080                	addi	s0,sp,64
    800041a0:	0001ea97          	auipc	s5,0x1e
    800041a4:	998a8a93          	addi	s5,s5,-1640 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041aa:	0001e997          	auipc	s3,0x1e
    800041ae:	95e98993          	addi	s3,s3,-1698 # 80021b08 <log>
    800041b2:	0189a583          	lw	a1,24(s3)
    800041b6:	014585bb          	addw	a1,a1,s4
    800041ba:	2585                	addiw	a1,a1,1
    800041bc:	0289a503          	lw	a0,40(s3)
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	f5c080e7          	jalr	-164(ra) # 8000311c <bread>
    800041c8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041ca:	000aa583          	lw	a1,0(s5)
    800041ce:	0289a503          	lw	a0,40(s3)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	f4a080e7          	jalr	-182(ra) # 8000311c <bread>
    800041da:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041dc:	40000613          	li	a2,1024
    800041e0:	05890593          	addi	a1,s2,88
    800041e4:	05850513          	addi	a0,a0,88
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	b6e080e7          	jalr	-1170(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041f0:	8526                	mv	a0,s1
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	01c080e7          	jalr	28(ra) # 8000320e <bwrite>
    bunpin(dbuf);
    800041fa:	8526                	mv	a0,s1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	12a080e7          	jalr	298(ra) # 80003326 <bunpin>
    brelse(lbuf);
    80004204:	854a                	mv	a0,s2
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	046080e7          	jalr	70(ra) # 8000324c <brelse>
    brelse(dbuf);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	03c080e7          	jalr	60(ra) # 8000324c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004218:	2a05                	addiw	s4,s4,1
    8000421a:	0a91                	addi	s5,s5,4
    8000421c:	02c9a783          	lw	a5,44(s3)
    80004220:	f8fa49e3          	blt	s4,a5,800041b2 <install_trans+0x30>
}
    80004224:	70e2                	ld	ra,56(sp)
    80004226:	7442                	ld	s0,48(sp)
    80004228:	74a2                	ld	s1,40(sp)
    8000422a:	7902                	ld	s2,32(sp)
    8000422c:	69e2                	ld	s3,24(sp)
    8000422e:	6a42                	ld	s4,16(sp)
    80004230:	6aa2                	ld	s5,8(sp)
    80004232:	6121                	addi	sp,sp,64
    80004234:	8082                	ret
    80004236:	8082                	ret

0000000080004238 <initlog>:
{
    80004238:	7179                	addi	sp,sp,-48
    8000423a:	f406                	sd	ra,40(sp)
    8000423c:	f022                	sd	s0,32(sp)
    8000423e:	ec26                	sd	s1,24(sp)
    80004240:	e84a                	sd	s2,16(sp)
    80004242:	e44e                	sd	s3,8(sp)
    80004244:	1800                	addi	s0,sp,48
    80004246:	892a                	mv	s2,a0
    80004248:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000424a:	0001e497          	auipc	s1,0x1e
    8000424e:	8be48493          	addi	s1,s1,-1858 # 80021b08 <log>
    80004252:	00004597          	auipc	a1,0x4
    80004256:	3fe58593          	addi	a1,a1,1022 # 80008650 <syscalls+0x1d8>
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	912080e7          	jalr	-1774(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80004264:	0149a583          	lw	a1,20(s3)
    80004268:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000426a:	0109a783          	lw	a5,16(s3)
    8000426e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004270:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004274:	854a                	mv	a0,s2
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	ea6080e7          	jalr	-346(ra) # 8000311c <bread>
  log.lh.n = lh->n;
    8000427e:	4d34                	lw	a3,88(a0)
    80004280:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004282:	02d05563          	blez	a3,800042ac <initlog+0x74>
    80004286:	05c50793          	addi	a5,a0,92
    8000428a:	0001e717          	auipc	a4,0x1e
    8000428e:	8ae70713          	addi	a4,a4,-1874 # 80021b38 <log+0x30>
    80004292:	36fd                	addiw	a3,a3,-1
    80004294:	1682                	slli	a3,a3,0x20
    80004296:	9281                	srli	a3,a3,0x20
    80004298:	068a                	slli	a3,a3,0x2
    8000429a:	06050613          	addi	a2,a0,96
    8000429e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042a0:	4390                	lw	a2,0(a5)
    800042a2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042a4:	0791                	addi	a5,a5,4
    800042a6:	0711                	addi	a4,a4,4
    800042a8:	fed79ce3          	bne	a5,a3,800042a0 <initlog+0x68>
  brelse(buf);
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	fa0080e7          	jalr	-96(ra) # 8000324c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	ece080e7          	jalr	-306(ra) # 80004182 <install_trans>
  log.lh.n = 0;
    800042bc:	0001e797          	auipc	a5,0x1e
    800042c0:	8607ac23          	sw	zero,-1928(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	e44080e7          	jalr	-444(ra) # 80004108 <write_head>
}
    800042cc:	70a2                	ld	ra,40(sp)
    800042ce:	7402                	ld	s0,32(sp)
    800042d0:	64e2                	ld	s1,24(sp)
    800042d2:	6942                	ld	s2,16(sp)
    800042d4:	69a2                	ld	s3,8(sp)
    800042d6:	6145                	addi	sp,sp,48
    800042d8:	8082                	ret

00000000800042da <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	e04a                	sd	s2,0(sp)
    800042e4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042e6:	0001e517          	auipc	a0,0x1e
    800042ea:	82250513          	addi	a0,a0,-2014 # 80021b08 <log>
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	910080e7          	jalr	-1776(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    800042f6:	0001e497          	auipc	s1,0x1e
    800042fa:	81248493          	addi	s1,s1,-2030 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042fe:	4979                	li	s2,30
    80004300:	a039                	j	8000430e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004302:	85a6                	mv	a1,s1
    80004304:	8526                	mv	a0,s1
    80004306:	ffffe097          	auipc	ra,0xffffe
    8000430a:	202080e7          	jalr	514(ra) # 80002508 <sleep>
    if(log.committing){
    8000430e:	50dc                	lw	a5,36(s1)
    80004310:	fbed                	bnez	a5,80004302 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004312:	509c                	lw	a5,32(s1)
    80004314:	0017871b          	addiw	a4,a5,1
    80004318:	0007069b          	sext.w	a3,a4
    8000431c:	0027179b          	slliw	a5,a4,0x2
    80004320:	9fb9                	addw	a5,a5,a4
    80004322:	0017979b          	slliw	a5,a5,0x1
    80004326:	54d8                	lw	a4,44(s1)
    80004328:	9fb9                	addw	a5,a5,a4
    8000432a:	00f95963          	bge	s2,a5,8000433c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000432e:	85a6                	mv	a1,s1
    80004330:	8526                	mv	a0,s1
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	1d6080e7          	jalr	470(ra) # 80002508 <sleep>
    8000433a:	bfd1                	j	8000430e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000433c:	0001d517          	auipc	a0,0x1d
    80004340:	7cc50513          	addi	a0,a0,1996 # 80021b08 <log>
    80004344:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	96c080e7          	jalr	-1684(ra) # 80000cb2 <release>
      break;
    }
  }
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	64a2                	ld	s1,8(sp)
    80004354:	6902                	ld	s2,0(sp)
    80004356:	6105                	addi	sp,sp,32
    80004358:	8082                	ret

000000008000435a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000435a:	7139                	addi	sp,sp,-64
    8000435c:	fc06                	sd	ra,56(sp)
    8000435e:	f822                	sd	s0,48(sp)
    80004360:	f426                	sd	s1,40(sp)
    80004362:	f04a                	sd	s2,32(sp)
    80004364:	ec4e                	sd	s3,24(sp)
    80004366:	e852                	sd	s4,16(sp)
    80004368:	e456                	sd	s5,8(sp)
    8000436a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000436c:	0001d497          	auipc	s1,0x1d
    80004370:	79c48493          	addi	s1,s1,1948 # 80021b08 <log>
    80004374:	8526                	mv	a0,s1
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	888080e7          	jalr	-1912(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    8000437e:	509c                	lw	a5,32(s1)
    80004380:	37fd                	addiw	a5,a5,-1
    80004382:	0007891b          	sext.w	s2,a5
    80004386:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004388:	50dc                	lw	a5,36(s1)
    8000438a:	e7b9                	bnez	a5,800043d8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000438c:	04091e63          	bnez	s2,800043e8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004390:	0001d497          	auipc	s1,0x1d
    80004394:	77848493          	addi	s1,s1,1912 # 80021b08 <log>
    80004398:	4785                	li	a5,1
    8000439a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	914080e7          	jalr	-1772(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043a6:	54dc                	lw	a5,44(s1)
    800043a8:	06f04763          	bgtz	a5,80004416 <end_op+0xbc>
    acquire(&log.lock);
    800043ac:	0001d497          	auipc	s1,0x1d
    800043b0:	75c48493          	addi	s1,s1,1884 # 80021b08 <log>
    800043b4:	8526                	mv	a0,s1
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	848080e7          	jalr	-1976(ra) # 80000bfe <acquire>
    log.committing = 0;
    800043be:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043c2:	8526                	mv	a0,s1
    800043c4:	ffffe097          	auipc	ra,0xffffe
    800043c8:	2c4080e7          	jalr	708(ra) # 80002688 <wakeup>
    release(&log.lock);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	8e4080e7          	jalr	-1820(ra) # 80000cb2 <release>
}
    800043d6:	a03d                	j	80004404 <end_op+0xaa>
    panic("log.committing");
    800043d8:	00004517          	auipc	a0,0x4
    800043dc:	28050513          	addi	a0,a0,640 # 80008658 <syscalls+0x1e0>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	162080e7          	jalr	354(ra) # 80000542 <panic>
    wakeup(&log);
    800043e8:	0001d497          	auipc	s1,0x1d
    800043ec:	72048493          	addi	s1,s1,1824 # 80021b08 <log>
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffe097          	auipc	ra,0xffffe
    800043f6:	296080e7          	jalr	662(ra) # 80002688 <wakeup>
  release(&log.lock);
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	8b6080e7          	jalr	-1866(ra) # 80000cb2 <release>
}
    80004404:	70e2                	ld	ra,56(sp)
    80004406:	7442                	ld	s0,48(sp)
    80004408:	74a2                	ld	s1,40(sp)
    8000440a:	7902                	ld	s2,32(sp)
    8000440c:	69e2                	ld	s3,24(sp)
    8000440e:	6a42                	ld	s4,16(sp)
    80004410:	6aa2                	ld	s5,8(sp)
    80004412:	6121                	addi	sp,sp,64
    80004414:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004416:	0001da97          	auipc	s5,0x1d
    8000441a:	722a8a93          	addi	s5,s5,1826 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000441e:	0001da17          	auipc	s4,0x1d
    80004422:	6eaa0a13          	addi	s4,s4,1770 # 80021b08 <log>
    80004426:	018a2583          	lw	a1,24(s4)
    8000442a:	012585bb          	addw	a1,a1,s2
    8000442e:	2585                	addiw	a1,a1,1
    80004430:	028a2503          	lw	a0,40(s4)
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	ce8080e7          	jalr	-792(ra) # 8000311c <bread>
    8000443c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000443e:	000aa583          	lw	a1,0(s5)
    80004442:	028a2503          	lw	a0,40(s4)
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	cd6080e7          	jalr	-810(ra) # 8000311c <bread>
    8000444e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004450:	40000613          	li	a2,1024
    80004454:	05850593          	addi	a1,a0,88
    80004458:	05848513          	addi	a0,s1,88
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	8fa080e7          	jalr	-1798(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    80004464:	8526                	mv	a0,s1
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	da8080e7          	jalr	-600(ra) # 8000320e <bwrite>
    brelse(from);
    8000446e:	854e                	mv	a0,s3
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	ddc080e7          	jalr	-548(ra) # 8000324c <brelse>
    brelse(to);
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	dd2080e7          	jalr	-558(ra) # 8000324c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004482:	2905                	addiw	s2,s2,1
    80004484:	0a91                	addi	s5,s5,4
    80004486:	02ca2783          	lw	a5,44(s4)
    8000448a:	f8f94ee3          	blt	s2,a5,80004426 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	c7a080e7          	jalr	-902(ra) # 80004108 <write_head>
    install_trans(); // Now install writes to home locations
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	cec080e7          	jalr	-788(ra) # 80004182 <install_trans>
    log.lh.n = 0;
    8000449e:	0001d797          	auipc	a5,0x1d
    800044a2:	6807ab23          	sw	zero,1686(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	c62080e7          	jalr	-926(ra) # 80004108 <write_head>
    800044ae:	bdfd                	j	800043ac <end_op+0x52>

00000000800044b0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044b0:	1101                	addi	sp,sp,-32
    800044b2:	ec06                	sd	ra,24(sp)
    800044b4:	e822                	sd	s0,16(sp)
    800044b6:	e426                	sd	s1,8(sp)
    800044b8:	e04a                	sd	s2,0(sp)
    800044ba:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044bc:	0001d717          	auipc	a4,0x1d
    800044c0:	67872703          	lw	a4,1656(a4) # 80021b34 <log+0x2c>
    800044c4:	47f5                	li	a5,29
    800044c6:	08e7c063          	blt	a5,a4,80004546 <log_write+0x96>
    800044ca:	84aa                	mv	s1,a0
    800044cc:	0001d797          	auipc	a5,0x1d
    800044d0:	6587a783          	lw	a5,1624(a5) # 80021b24 <log+0x1c>
    800044d4:	37fd                	addiw	a5,a5,-1
    800044d6:	06f75863          	bge	a4,a5,80004546 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044da:	0001d797          	auipc	a5,0x1d
    800044de:	64e7a783          	lw	a5,1614(a5) # 80021b28 <log+0x20>
    800044e2:	06f05a63          	blez	a5,80004556 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044e6:	0001d917          	auipc	s2,0x1d
    800044ea:	62290913          	addi	s2,s2,1570 # 80021b08 <log>
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	70e080e7          	jalr	1806(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044f8:	02c92603          	lw	a2,44(s2)
    800044fc:	06c05563          	blez	a2,80004566 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004500:	44cc                	lw	a1,12(s1)
    80004502:	0001d717          	auipc	a4,0x1d
    80004506:	63670713          	addi	a4,a4,1590 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000450a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000450c:	4314                	lw	a3,0(a4)
    8000450e:	04b68d63          	beq	a3,a1,80004568 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004512:	2785                	addiw	a5,a5,1
    80004514:	0711                	addi	a4,a4,4
    80004516:	fec79be3          	bne	a5,a2,8000450c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000451a:	0621                	addi	a2,a2,8
    8000451c:	060a                	slli	a2,a2,0x2
    8000451e:	0001d797          	auipc	a5,0x1d
    80004522:	5ea78793          	addi	a5,a5,1514 # 80021b08 <log>
    80004526:	963e                	add	a2,a2,a5
    80004528:	44dc                	lw	a5,12(s1)
    8000452a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000452c:	8526                	mv	a0,s1
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	dbc080e7          	jalr	-580(ra) # 800032ea <bpin>
    log.lh.n++;
    80004536:	0001d717          	auipc	a4,0x1d
    8000453a:	5d270713          	addi	a4,a4,1490 # 80021b08 <log>
    8000453e:	575c                	lw	a5,44(a4)
    80004540:	2785                	addiw	a5,a5,1
    80004542:	d75c                	sw	a5,44(a4)
    80004544:	a83d                	j	80004582 <log_write+0xd2>
    panic("too big a transaction");
    80004546:	00004517          	auipc	a0,0x4
    8000454a:	12250513          	addi	a0,a0,290 # 80008668 <syscalls+0x1f0>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	ff4080e7          	jalr	-12(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004556:	00004517          	auipc	a0,0x4
    8000455a:	12a50513          	addi	a0,a0,298 # 80008680 <syscalls+0x208>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	fe4080e7          	jalr	-28(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004566:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004568:	00878713          	addi	a4,a5,8
    8000456c:	00271693          	slli	a3,a4,0x2
    80004570:	0001d717          	auipc	a4,0x1d
    80004574:	59870713          	addi	a4,a4,1432 # 80021b08 <log>
    80004578:	9736                	add	a4,a4,a3
    8000457a:	44d4                	lw	a3,12(s1)
    8000457c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000457e:	faf607e3          	beq	a2,a5,8000452c <log_write+0x7c>
  }
  release(&log.lock);
    80004582:	0001d517          	auipc	a0,0x1d
    80004586:	58650513          	addi	a0,a0,1414 # 80021b08 <log>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	728080e7          	jalr	1832(ra) # 80000cb2 <release>
}
    80004592:	60e2                	ld	ra,24(sp)
    80004594:	6442                	ld	s0,16(sp)
    80004596:	64a2                	ld	s1,8(sp)
    80004598:	6902                	ld	s2,0(sp)
    8000459a:	6105                	addi	sp,sp,32
    8000459c:	8082                	ret

000000008000459e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	e04a                	sd	s2,0(sp)
    800045a8:	1000                	addi	s0,sp,32
    800045aa:	84aa                	mv	s1,a0
    800045ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045ae:	00004597          	auipc	a1,0x4
    800045b2:	0f258593          	addi	a1,a1,242 # 800086a0 <syscalls+0x228>
    800045b6:	0521                	addi	a0,a0,8
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	5b6080e7          	jalr	1462(ra) # 80000b6e <initlock>
  lk->name = name;
    800045c0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045c8:	0204a423          	sw	zero,40(s1)
}
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6902                	ld	s2,0(sp)
    800045d4:	6105                	addi	sp,sp,32
    800045d6:	8082                	ret

00000000800045d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045d8:	1101                	addi	sp,sp,-32
    800045da:	ec06                	sd	ra,24(sp)
    800045dc:	e822                	sd	s0,16(sp)
    800045de:	e426                	sd	s1,8(sp)
    800045e0:	e04a                	sd	s2,0(sp)
    800045e2:	1000                	addi	s0,sp,32
    800045e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e6:	00850913          	addi	s2,a0,8
    800045ea:	854a                	mv	a0,s2
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	612080e7          	jalr	1554(ra) # 80000bfe <acquire>
  while (lk->locked) {
    800045f4:	409c                	lw	a5,0(s1)
    800045f6:	cb89                	beqz	a5,80004608 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045f8:	85ca                	mv	a1,s2
    800045fa:	8526                	mv	a0,s1
    800045fc:	ffffe097          	auipc	ra,0xffffe
    80004600:	f0c080e7          	jalr	-244(ra) # 80002508 <sleep>
  while (lk->locked) {
    80004604:	409c                	lw	a5,0(s1)
    80004606:	fbed                	bnez	a5,800045f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004608:	4785                	li	a5,1
    8000460a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	4d2080e7          	jalr	1234(ra) # 80001ade <myproc>
    80004614:	5d1c                	lw	a5,56(a0)
    80004616:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	698080e7          	jalr	1688(ra) # 80000cb2 <release>
}
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6902                	ld	s2,0(sp)
    8000462a:	6105                	addi	sp,sp,32
    8000462c:	8082                	ret

000000008000462e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000462e:	1101                	addi	sp,sp,-32
    80004630:	ec06                	sd	ra,24(sp)
    80004632:	e822                	sd	s0,16(sp)
    80004634:	e426                	sd	s1,8(sp)
    80004636:	e04a                	sd	s2,0(sp)
    80004638:	1000                	addi	s0,sp,32
    8000463a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000463c:	00850913          	addi	s2,a0,8
    80004640:	854a                	mv	a0,s2
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	5bc080e7          	jalr	1468(ra) # 80000bfe <acquire>
  lk->locked = 0;
    8000464a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000464e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004652:	8526                	mv	a0,s1
    80004654:	ffffe097          	auipc	ra,0xffffe
    80004658:	034080e7          	jalr	52(ra) # 80002688 <wakeup>
  release(&lk->lk);
    8000465c:	854a                	mv	a0,s2
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	654080e7          	jalr	1620(ra) # 80000cb2 <release>
}
    80004666:	60e2                	ld	ra,24(sp)
    80004668:	6442                	ld	s0,16(sp)
    8000466a:	64a2                	ld	s1,8(sp)
    8000466c:	6902                	ld	s2,0(sp)
    8000466e:	6105                	addi	sp,sp,32
    80004670:	8082                	ret

0000000080004672 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004672:	7179                	addi	sp,sp,-48
    80004674:	f406                	sd	ra,40(sp)
    80004676:	f022                	sd	s0,32(sp)
    80004678:	ec26                	sd	s1,24(sp)
    8000467a:	e84a                	sd	s2,16(sp)
    8000467c:	e44e                	sd	s3,8(sp)
    8000467e:	1800                	addi	s0,sp,48
    80004680:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004682:	00850913          	addi	s2,a0,8
    80004686:	854a                	mv	a0,s2
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	576080e7          	jalr	1398(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004690:	409c                	lw	a5,0(s1)
    80004692:	ef99                	bnez	a5,800046b0 <holdingsleep+0x3e>
    80004694:	4481                	li	s1,0
  release(&lk->lk);
    80004696:	854a                	mv	a0,s2
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	61a080e7          	jalr	1562(ra) # 80000cb2 <release>
  return r;
}
    800046a0:	8526                	mv	a0,s1
    800046a2:	70a2                	ld	ra,40(sp)
    800046a4:	7402                	ld	s0,32(sp)
    800046a6:	64e2                	ld	s1,24(sp)
    800046a8:	6942                	ld	s2,16(sp)
    800046aa:	69a2                	ld	s3,8(sp)
    800046ac:	6145                	addi	sp,sp,48
    800046ae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b0:	0284a983          	lw	s3,40(s1)
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	42a080e7          	jalr	1066(ra) # 80001ade <myproc>
    800046bc:	5d04                	lw	s1,56(a0)
    800046be:	413484b3          	sub	s1,s1,s3
    800046c2:	0014b493          	seqz	s1,s1
    800046c6:	bfc1                	j	80004696 <holdingsleep+0x24>

00000000800046c8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046c8:	1141                	addi	sp,sp,-16
    800046ca:	e406                	sd	ra,8(sp)
    800046cc:	e022                	sd	s0,0(sp)
    800046ce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046d0:	00004597          	auipc	a1,0x4
    800046d4:	fe058593          	addi	a1,a1,-32 # 800086b0 <syscalls+0x238>
    800046d8:	0001d517          	auipc	a0,0x1d
    800046dc:	57850513          	addi	a0,a0,1400 # 80021c50 <ftable>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	48e080e7          	jalr	1166(ra) # 80000b6e <initlock>
}
    800046e8:	60a2                	ld	ra,8(sp)
    800046ea:	6402                	ld	s0,0(sp)
    800046ec:	0141                	addi	sp,sp,16
    800046ee:	8082                	ret

00000000800046f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046f0:	1101                	addi	sp,sp,-32
    800046f2:	ec06                	sd	ra,24(sp)
    800046f4:	e822                	sd	s0,16(sp)
    800046f6:	e426                	sd	s1,8(sp)
    800046f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046fa:	0001d517          	auipc	a0,0x1d
    800046fe:	55650513          	addi	a0,a0,1366 # 80021c50 <ftable>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4fc080e7          	jalr	1276(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000470a:	0001d497          	auipc	s1,0x1d
    8000470e:	55e48493          	addi	s1,s1,1374 # 80021c68 <ftable+0x18>
    80004712:	0001e717          	auipc	a4,0x1e
    80004716:	4f670713          	addi	a4,a4,1270 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000471a:	40dc                	lw	a5,4(s1)
    8000471c:	cf99                	beqz	a5,8000473a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000471e:	02848493          	addi	s1,s1,40
    80004722:	fee49ce3          	bne	s1,a4,8000471a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	52a50513          	addi	a0,a0,1322 # 80021c50 <ftable>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	584080e7          	jalr	1412(ra) # 80000cb2 <release>
  return 0;
    80004736:	4481                	li	s1,0
    80004738:	a819                	j	8000474e <filealloc+0x5e>
      f->ref = 1;
    8000473a:	4785                	li	a5,1
    8000473c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000473e:	0001d517          	auipc	a0,0x1d
    80004742:	51250513          	addi	a0,a0,1298 # 80021c50 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	56c080e7          	jalr	1388(ra) # 80000cb2 <release>
}
    8000474e:	8526                	mv	a0,s1
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6105                	addi	sp,sp,32
    80004758:	8082                	ret

000000008000475a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000475a:	1101                	addi	sp,sp,-32
    8000475c:	ec06                	sd	ra,24(sp)
    8000475e:	e822                	sd	s0,16(sp)
    80004760:	e426                	sd	s1,8(sp)
    80004762:	1000                	addi	s0,sp,32
    80004764:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004766:	0001d517          	auipc	a0,0x1d
    8000476a:	4ea50513          	addi	a0,a0,1258 # 80021c50 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	490080e7          	jalr	1168(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	02f05263          	blez	a5,8000479c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000477c:	2785                	addiw	a5,a5,1
    8000477e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	4d050513          	addi	a0,a0,1232 # 80021c50 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	52a080e7          	jalr	1322(ra) # 80000cb2 <release>
  return f;
}
    80004790:	8526                	mv	a0,s1
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	64a2                	ld	s1,8(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret
    panic("filedup");
    8000479c:	00004517          	auipc	a0,0x4
    800047a0:	f1c50513          	addi	a0,a0,-228 # 800086b8 <syscalls+0x240>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	d9e080e7          	jalr	-610(ra) # 80000542 <panic>

00000000800047ac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047ac:	7139                	addi	sp,sp,-64
    800047ae:	fc06                	sd	ra,56(sp)
    800047b0:	f822                	sd	s0,48(sp)
    800047b2:	f426                	sd	s1,40(sp)
    800047b4:	f04a                	sd	s2,32(sp)
    800047b6:	ec4e                	sd	s3,24(sp)
    800047b8:	e852                	sd	s4,16(sp)
    800047ba:	e456                	sd	s5,8(sp)
    800047bc:	0080                	addi	s0,sp,64
    800047be:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047c0:	0001d517          	auipc	a0,0x1d
    800047c4:	49050513          	addi	a0,a0,1168 # 80021c50 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	436080e7          	jalr	1078(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    800047d0:	40dc                	lw	a5,4(s1)
    800047d2:	06f05163          	blez	a5,80004834 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047d6:	37fd                	addiw	a5,a5,-1
    800047d8:	0007871b          	sext.w	a4,a5
    800047dc:	c0dc                	sw	a5,4(s1)
    800047de:	06e04363          	bgtz	a4,80004844 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047e2:	0004a903          	lw	s2,0(s1)
    800047e6:	0094ca83          	lbu	s5,9(s1)
    800047ea:	0104ba03          	ld	s4,16(s1)
    800047ee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047f2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047f6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047fa:	0001d517          	auipc	a0,0x1d
    800047fe:	45650513          	addi	a0,a0,1110 # 80021c50 <ftable>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	4b0080e7          	jalr	1200(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    8000480a:	4785                	li	a5,1
    8000480c:	04f90d63          	beq	s2,a5,80004866 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004810:	3979                	addiw	s2,s2,-2
    80004812:	4785                	li	a5,1
    80004814:	0527e063          	bltu	a5,s2,80004854 <fileclose+0xa8>
    begin_op();
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	ac2080e7          	jalr	-1342(ra) # 800042da <begin_op>
    iput(ff.ip);
    80004820:	854e                	mv	a0,s3
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	2b6080e7          	jalr	694(ra) # 80003ad8 <iput>
    end_op();
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	b30080e7          	jalr	-1232(ra) # 8000435a <end_op>
    80004832:	a00d                	j	80004854 <fileclose+0xa8>
    panic("fileclose");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	e8c50513          	addi	a0,a0,-372 # 800086c0 <syscalls+0x248>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	d06080e7          	jalr	-762(ra) # 80000542 <panic>
    release(&ftable.lock);
    80004844:	0001d517          	auipc	a0,0x1d
    80004848:	40c50513          	addi	a0,a0,1036 # 80021c50 <ftable>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	466080e7          	jalr	1126(ra) # 80000cb2 <release>
  }
}
    80004854:	70e2                	ld	ra,56(sp)
    80004856:	7442                	ld	s0,48(sp)
    80004858:	74a2                	ld	s1,40(sp)
    8000485a:	7902                	ld	s2,32(sp)
    8000485c:	69e2                	ld	s3,24(sp)
    8000485e:	6a42                	ld	s4,16(sp)
    80004860:	6aa2                	ld	s5,8(sp)
    80004862:	6121                	addi	sp,sp,64
    80004864:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004866:	85d6                	mv	a1,s5
    80004868:	8552                	mv	a0,s4
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	372080e7          	jalr	882(ra) # 80004bdc <pipeclose>
    80004872:	b7cd                	j	80004854 <fileclose+0xa8>

0000000080004874 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004874:	715d                	addi	sp,sp,-80
    80004876:	e486                	sd	ra,72(sp)
    80004878:	e0a2                	sd	s0,64(sp)
    8000487a:	fc26                	sd	s1,56(sp)
    8000487c:	f84a                	sd	s2,48(sp)
    8000487e:	f44e                	sd	s3,40(sp)
    80004880:	0880                	addi	s0,sp,80
    80004882:	84aa                	mv	s1,a0
    80004884:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004886:	ffffd097          	auipc	ra,0xffffd
    8000488a:	258080e7          	jalr	600(ra) # 80001ade <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	37f9                	addiw	a5,a5,-2
    80004892:	4705                	li	a4,1
    80004894:	04f76763          	bltu	a4,a5,800048e2 <filestat+0x6e>
    80004898:	892a                	mv	s2,a0
    ilock(f->ip);
    8000489a:	6c88                	ld	a0,24(s1)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	082080e7          	jalr	130(ra) # 8000391e <ilock>
    stati(f->ip, &st);
    800048a4:	fb840593          	addi	a1,s0,-72
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	2fe080e7          	jalr	766(ra) # 80003ba8 <stati>
    iunlock(f->ip);
    800048b2:	6c88                	ld	a0,24(s1)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	12c080e7          	jalr	300(ra) # 800039e0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048bc:	46e1                	li	a3,24
    800048be:	fb840613          	addi	a2,s0,-72
    800048c2:	85ce                	mv	a1,s3
    800048c4:	05093503          	ld	a0,80(s2)
    800048c8:	ffffd097          	auipc	ra,0xffffd
    800048cc:	08a080e7          	jalr	138(ra) # 80001952 <copyout>
    800048d0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048d4:	60a6                	ld	ra,72(sp)
    800048d6:	6406                	ld	s0,64(sp)
    800048d8:	74e2                	ld	s1,56(sp)
    800048da:	7942                	ld	s2,48(sp)
    800048dc:	79a2                	ld	s3,40(sp)
    800048de:	6161                	addi	sp,sp,80
    800048e0:	8082                	ret
  return -1;
    800048e2:	557d                	li	a0,-1
    800048e4:	bfc5                	j	800048d4 <filestat+0x60>

00000000800048e6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048e6:	7179                	addi	sp,sp,-48
    800048e8:	f406                	sd	ra,40(sp)
    800048ea:	f022                	sd	s0,32(sp)
    800048ec:	ec26                	sd	s1,24(sp)
    800048ee:	e84a                	sd	s2,16(sp)
    800048f0:	e44e                	sd	s3,8(sp)
    800048f2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048f4:	00854783          	lbu	a5,8(a0)
    800048f8:	c3d5                	beqz	a5,8000499c <fileread+0xb6>
    800048fa:	84aa                	mv	s1,a0
    800048fc:	89ae                	mv	s3,a1
    800048fe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004900:	411c                	lw	a5,0(a0)
    80004902:	4705                	li	a4,1
    80004904:	04e78963          	beq	a5,a4,80004956 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004908:	470d                	li	a4,3
    8000490a:	04e78d63          	beq	a5,a4,80004964 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000490e:	4709                	li	a4,2
    80004910:	06e79e63          	bne	a5,a4,8000498c <fileread+0xa6>
    ilock(f->ip);
    80004914:	6d08                	ld	a0,24(a0)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	008080e7          	jalr	8(ra) # 8000391e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000491e:	874a                	mv	a4,s2
    80004920:	5094                	lw	a3,32(s1)
    80004922:	864e                	mv	a2,s3
    80004924:	4585                	li	a1,1
    80004926:	6c88                	ld	a0,24(s1)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	2aa080e7          	jalr	682(ra) # 80003bd2 <readi>
    80004930:	892a                	mv	s2,a0
    80004932:	00a05563          	blez	a0,8000493c <fileread+0x56>
      f->off += r;
    80004936:	509c                	lw	a5,32(s1)
    80004938:	9fa9                	addw	a5,a5,a0
    8000493a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000493c:	6c88                	ld	a0,24(s1)
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	0a2080e7          	jalr	162(ra) # 800039e0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004946:	854a                	mv	a0,s2
    80004948:	70a2                	ld	ra,40(sp)
    8000494a:	7402                	ld	s0,32(sp)
    8000494c:	64e2                	ld	s1,24(sp)
    8000494e:	6942                	ld	s2,16(sp)
    80004950:	69a2                	ld	s3,8(sp)
    80004952:	6145                	addi	sp,sp,48
    80004954:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004956:	6908                	ld	a0,16(a0)
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	3f4080e7          	jalr	1012(ra) # 80004d4c <piperead>
    80004960:	892a                	mv	s2,a0
    80004962:	b7d5                	j	80004946 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004964:	02451783          	lh	a5,36(a0)
    80004968:	03079693          	slli	a3,a5,0x30
    8000496c:	92c1                	srli	a3,a3,0x30
    8000496e:	4725                	li	a4,9
    80004970:	02d76863          	bltu	a4,a3,800049a0 <fileread+0xba>
    80004974:	0792                	slli	a5,a5,0x4
    80004976:	0001d717          	auipc	a4,0x1d
    8000497a:	23a70713          	addi	a4,a4,570 # 80021bb0 <devsw>
    8000497e:	97ba                	add	a5,a5,a4
    80004980:	639c                	ld	a5,0(a5)
    80004982:	c38d                	beqz	a5,800049a4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004984:	4505                	li	a0,1
    80004986:	9782                	jalr	a5
    80004988:	892a                	mv	s2,a0
    8000498a:	bf75                	j	80004946 <fileread+0x60>
    panic("fileread");
    8000498c:	00004517          	auipc	a0,0x4
    80004990:	d4450513          	addi	a0,a0,-700 # 800086d0 <syscalls+0x258>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	bae080e7          	jalr	-1106(ra) # 80000542 <panic>
    return -1;
    8000499c:	597d                	li	s2,-1
    8000499e:	b765                	j	80004946 <fileread+0x60>
      return -1;
    800049a0:	597d                	li	s2,-1
    800049a2:	b755                	j	80004946 <fileread+0x60>
    800049a4:	597d                	li	s2,-1
    800049a6:	b745                	j	80004946 <fileread+0x60>

00000000800049a8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049a8:	00954783          	lbu	a5,9(a0)
    800049ac:	14078563          	beqz	a5,80004af6 <filewrite+0x14e>
{
    800049b0:	715d                	addi	sp,sp,-80
    800049b2:	e486                	sd	ra,72(sp)
    800049b4:	e0a2                	sd	s0,64(sp)
    800049b6:	fc26                	sd	s1,56(sp)
    800049b8:	f84a                	sd	s2,48(sp)
    800049ba:	f44e                	sd	s3,40(sp)
    800049bc:	f052                	sd	s4,32(sp)
    800049be:	ec56                	sd	s5,24(sp)
    800049c0:	e85a                	sd	s6,16(sp)
    800049c2:	e45e                	sd	s7,8(sp)
    800049c4:	e062                	sd	s8,0(sp)
    800049c6:	0880                	addi	s0,sp,80
    800049c8:	892a                	mv	s2,a0
    800049ca:	8aae                	mv	s5,a1
    800049cc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ce:	411c                	lw	a5,0(a0)
    800049d0:	4705                	li	a4,1
    800049d2:	02e78263          	beq	a5,a4,800049f6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d6:	470d                	li	a4,3
    800049d8:	02e78563          	beq	a5,a4,80004a02 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049dc:	4709                	li	a4,2
    800049de:	10e79463          	bne	a5,a4,80004ae6 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049e2:	0ec05e63          	blez	a2,80004ade <filewrite+0x136>
    int i = 0;
    800049e6:	4981                	li	s3,0
    800049e8:	6b05                	lui	s6,0x1
    800049ea:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049ee:	6b85                	lui	s7,0x1
    800049f0:	c00b8b9b          	addiw	s7,s7,-1024
    800049f4:	a851                	j	80004a88 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049f6:	6908                	ld	a0,16(a0)
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	254080e7          	jalr	596(ra) # 80004c4c <pipewrite>
    80004a00:	a85d                	j	80004ab6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a02:	02451783          	lh	a5,36(a0)
    80004a06:	03079693          	slli	a3,a5,0x30
    80004a0a:	92c1                	srli	a3,a3,0x30
    80004a0c:	4725                	li	a4,9
    80004a0e:	0ed76663          	bltu	a4,a3,80004afa <filewrite+0x152>
    80004a12:	0792                	slli	a5,a5,0x4
    80004a14:	0001d717          	auipc	a4,0x1d
    80004a18:	19c70713          	addi	a4,a4,412 # 80021bb0 <devsw>
    80004a1c:	97ba                	add	a5,a5,a4
    80004a1e:	679c                	ld	a5,8(a5)
    80004a20:	cff9                	beqz	a5,80004afe <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a22:	4505                	li	a0,1
    80004a24:	9782                	jalr	a5
    80004a26:	a841                	j	80004ab6 <filewrite+0x10e>
    80004a28:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	8ae080e7          	jalr	-1874(ra) # 800042da <begin_op>
      ilock(f->ip);
    80004a34:	01893503          	ld	a0,24(s2)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	ee6080e7          	jalr	-282(ra) # 8000391e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a40:	8762                	mv	a4,s8
    80004a42:	02092683          	lw	a3,32(s2)
    80004a46:	01598633          	add	a2,s3,s5
    80004a4a:	4585                	li	a1,1
    80004a4c:	01893503          	ld	a0,24(s2)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	278080e7          	jalr	632(ra) # 80003cc8 <writei>
    80004a58:	84aa                	mv	s1,a0
    80004a5a:	02a05f63          	blez	a0,80004a98 <filewrite+0xf0>
        f->off += r;
    80004a5e:	02092783          	lw	a5,32(s2)
    80004a62:	9fa9                	addw	a5,a5,a0
    80004a64:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a68:	01893503          	ld	a0,24(s2)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	f74080e7          	jalr	-140(ra) # 800039e0 <iunlock>
      end_op();
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	8e6080e7          	jalr	-1818(ra) # 8000435a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a7c:	049c1963          	bne	s8,s1,80004ace <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a80:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a84:	0349d663          	bge	s3,s4,80004ab0 <filewrite+0x108>
      int n1 = n - i;
    80004a88:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a8c:	84be                	mv	s1,a5
    80004a8e:	2781                	sext.w	a5,a5
    80004a90:	f8fb5ce3          	bge	s6,a5,80004a28 <filewrite+0x80>
    80004a94:	84de                	mv	s1,s7
    80004a96:	bf49                	j	80004a28 <filewrite+0x80>
      iunlock(f->ip);
    80004a98:	01893503          	ld	a0,24(s2)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	f44080e7          	jalr	-188(ra) # 800039e0 <iunlock>
      end_op();
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	8b6080e7          	jalr	-1866(ra) # 8000435a <end_op>
      if(r < 0)
    80004aac:	fc04d8e3          	bgez	s1,80004a7c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ab0:	8552                	mv	a0,s4
    80004ab2:	033a1863          	bne	s4,s3,80004ae2 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ab6:	60a6                	ld	ra,72(sp)
    80004ab8:	6406                	ld	s0,64(sp)
    80004aba:	74e2                	ld	s1,56(sp)
    80004abc:	7942                	ld	s2,48(sp)
    80004abe:	79a2                	ld	s3,40(sp)
    80004ac0:	7a02                	ld	s4,32(sp)
    80004ac2:	6ae2                	ld	s5,24(sp)
    80004ac4:	6b42                	ld	s6,16(sp)
    80004ac6:	6ba2                	ld	s7,8(sp)
    80004ac8:	6c02                	ld	s8,0(sp)
    80004aca:	6161                	addi	sp,sp,80
    80004acc:	8082                	ret
        panic("short filewrite");
    80004ace:	00004517          	auipc	a0,0x4
    80004ad2:	c1250513          	addi	a0,a0,-1006 # 800086e0 <syscalls+0x268>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	a6c080e7          	jalr	-1428(ra) # 80000542 <panic>
    int i = 0;
    80004ade:	4981                	li	s3,0
    80004ae0:	bfc1                	j	80004ab0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004ae2:	557d                	li	a0,-1
    80004ae4:	bfc9                	j	80004ab6 <filewrite+0x10e>
    panic("filewrite");
    80004ae6:	00004517          	auipc	a0,0x4
    80004aea:	c0a50513          	addi	a0,a0,-1014 # 800086f0 <syscalls+0x278>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	a54080e7          	jalr	-1452(ra) # 80000542 <panic>
    return -1;
    80004af6:	557d                	li	a0,-1
}
    80004af8:	8082                	ret
      return -1;
    80004afa:	557d                	li	a0,-1
    80004afc:	bf6d                	j	80004ab6 <filewrite+0x10e>
    80004afe:	557d                	li	a0,-1
    80004b00:	bf5d                	j	80004ab6 <filewrite+0x10e>

0000000080004b02 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b02:	7179                	addi	sp,sp,-48
    80004b04:	f406                	sd	ra,40(sp)
    80004b06:	f022                	sd	s0,32(sp)
    80004b08:	ec26                	sd	s1,24(sp)
    80004b0a:	e84a                	sd	s2,16(sp)
    80004b0c:	e44e                	sd	s3,8(sp)
    80004b0e:	e052                	sd	s4,0(sp)
    80004b10:	1800                	addi	s0,sp,48
    80004b12:	84aa                	mv	s1,a0
    80004b14:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b16:	0005b023          	sd	zero,0(a1)
    80004b1a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	bd2080e7          	jalr	-1070(ra) # 800046f0 <filealloc>
    80004b26:	e088                	sd	a0,0(s1)
    80004b28:	c551                	beqz	a0,80004bb4 <pipealloc+0xb2>
    80004b2a:	00000097          	auipc	ra,0x0
    80004b2e:	bc6080e7          	jalr	-1082(ra) # 800046f0 <filealloc>
    80004b32:	00aa3023          	sd	a0,0(s4)
    80004b36:	c92d                	beqz	a0,80004ba8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	fd6080e7          	jalr	-42(ra) # 80000b0e <kalloc>
    80004b40:	892a                	mv	s2,a0
    80004b42:	c125                	beqz	a0,80004ba2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b44:	4985                	li	s3,1
    80004b46:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b4a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b4e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b52:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b56:	00004597          	auipc	a1,0x4
    80004b5a:	baa58593          	addi	a1,a1,-1110 # 80008700 <syscalls+0x288>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	010080e7          	jalr	16(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004b66:	609c                	ld	a5,0(s1)
    80004b68:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b6c:	609c                	ld	a5,0(s1)
    80004b6e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b72:	609c                	ld	a5,0(s1)
    80004b74:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b78:	609c                	ld	a5,0(s1)
    80004b7a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b7e:	000a3783          	ld	a5,0(s4)
    80004b82:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b86:	000a3783          	ld	a5,0(s4)
    80004b8a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b8e:	000a3783          	ld	a5,0(s4)
    80004b92:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b96:	000a3783          	ld	a5,0(s4)
    80004b9a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b9e:	4501                	li	a0,0
    80004ba0:	a025                	j	80004bc8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ba2:	6088                	ld	a0,0(s1)
    80004ba4:	e501                	bnez	a0,80004bac <pipealloc+0xaa>
    80004ba6:	a039                	j	80004bb4 <pipealloc+0xb2>
    80004ba8:	6088                	ld	a0,0(s1)
    80004baa:	c51d                	beqz	a0,80004bd8 <pipealloc+0xd6>
    fileclose(*f0);
    80004bac:	00000097          	auipc	ra,0x0
    80004bb0:	c00080e7          	jalr	-1024(ra) # 800047ac <fileclose>
  if(*f1)
    80004bb4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bb8:	557d                	li	a0,-1
  if(*f1)
    80004bba:	c799                	beqz	a5,80004bc8 <pipealloc+0xc6>
    fileclose(*f1);
    80004bbc:	853e                	mv	a0,a5
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	bee080e7          	jalr	-1042(ra) # 800047ac <fileclose>
  return -1;
    80004bc6:	557d                	li	a0,-1
}
    80004bc8:	70a2                	ld	ra,40(sp)
    80004bca:	7402                	ld	s0,32(sp)
    80004bcc:	64e2                	ld	s1,24(sp)
    80004bce:	6942                	ld	s2,16(sp)
    80004bd0:	69a2                	ld	s3,8(sp)
    80004bd2:	6a02                	ld	s4,0(sp)
    80004bd4:	6145                	addi	sp,sp,48
    80004bd6:	8082                	ret
  return -1;
    80004bd8:	557d                	li	a0,-1
    80004bda:	b7fd                	j	80004bc8 <pipealloc+0xc6>

0000000080004bdc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bdc:	1101                	addi	sp,sp,-32
    80004bde:	ec06                	sd	ra,24(sp)
    80004be0:	e822                	sd	s0,16(sp)
    80004be2:	e426                	sd	s1,8(sp)
    80004be4:	e04a                	sd	s2,0(sp)
    80004be6:	1000                	addi	s0,sp,32
    80004be8:	84aa                	mv	s1,a0
    80004bea:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	012080e7          	jalr	18(ra) # 80000bfe <acquire>
  if(writable){
    80004bf4:	02090d63          	beqz	s2,80004c2e <pipeclose+0x52>
    pi->writeopen = 0;
    80004bf8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bfc:	21848513          	addi	a0,s1,536
    80004c00:	ffffe097          	auipc	ra,0xffffe
    80004c04:	a88080e7          	jalr	-1400(ra) # 80002688 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c08:	2204b783          	ld	a5,544(s1)
    80004c0c:	eb95                	bnez	a5,80004c40 <pipeclose+0x64>
    release(&pi->lock);
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	0a2080e7          	jalr	162(ra) # 80000cb2 <release>
    kfree((char*)pi);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	df8080e7          	jalr	-520(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004c22:	60e2                	ld	ra,24(sp)
    80004c24:	6442                	ld	s0,16(sp)
    80004c26:	64a2                	ld	s1,8(sp)
    80004c28:	6902                	ld	s2,0(sp)
    80004c2a:	6105                	addi	sp,sp,32
    80004c2c:	8082                	ret
    pi->readopen = 0;
    80004c2e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c32:	21c48513          	addi	a0,s1,540
    80004c36:	ffffe097          	auipc	ra,0xffffe
    80004c3a:	a52080e7          	jalr	-1454(ra) # 80002688 <wakeup>
    80004c3e:	b7e9                	j	80004c08 <pipeclose+0x2c>
    release(&pi->lock);
    80004c40:	8526                	mv	a0,s1
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	070080e7          	jalr	112(ra) # 80000cb2 <release>
}
    80004c4a:	bfe1                	j	80004c22 <pipeclose+0x46>

0000000080004c4c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c4c:	711d                	addi	sp,sp,-96
    80004c4e:	ec86                	sd	ra,88(sp)
    80004c50:	e8a2                	sd	s0,80(sp)
    80004c52:	e4a6                	sd	s1,72(sp)
    80004c54:	e0ca                	sd	s2,64(sp)
    80004c56:	fc4e                	sd	s3,56(sp)
    80004c58:	f852                	sd	s4,48(sp)
    80004c5a:	f456                	sd	s5,40(sp)
    80004c5c:	f05a                	sd	s6,32(sp)
    80004c5e:	ec5e                	sd	s7,24(sp)
    80004c60:	e862                	sd	s8,16(sp)
    80004c62:	1080                	addi	s0,sp,96
    80004c64:	84aa                	mv	s1,a0
    80004c66:	8b2e                	mv	s6,a1
    80004c68:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	e74080e7          	jalr	-396(ra) # 80001ade <myproc>
    80004c72:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	f88080e7          	jalr	-120(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004c7e:	09505763          	blez	s5,80004d0c <pipewrite+0xc0>
    80004c82:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c84:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c88:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c8c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c8e:	2184a783          	lw	a5,536(s1)
    80004c92:	21c4a703          	lw	a4,540(s1)
    80004c96:	2007879b          	addiw	a5,a5,512
    80004c9a:	02f71b63          	bne	a4,a5,80004cd0 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c9e:	2204a783          	lw	a5,544(s1)
    80004ca2:	c3d1                	beqz	a5,80004d26 <pipewrite+0xda>
    80004ca4:	03092783          	lw	a5,48(s2)
    80004ca8:	efbd                	bnez	a5,80004d26 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004caa:	8552                	mv	a0,s4
    80004cac:	ffffe097          	auipc	ra,0xffffe
    80004cb0:	9dc080e7          	jalr	-1572(ra) # 80002688 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cb4:	85a6                	mv	a1,s1
    80004cb6:	854e                	mv	a0,s3
    80004cb8:	ffffe097          	auipc	ra,0xffffe
    80004cbc:	850080e7          	jalr	-1968(ra) # 80002508 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cc0:	2184a783          	lw	a5,536(s1)
    80004cc4:	21c4a703          	lw	a4,540(s1)
    80004cc8:	2007879b          	addiw	a5,a5,512
    80004ccc:	fcf709e3          	beq	a4,a5,80004c9e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cd0:	4685                	li	a3,1
    80004cd2:	865a                	mv	a2,s6
    80004cd4:	faf40593          	addi	a1,s0,-81
    80004cd8:	05093503          	ld	a0,80(s2)
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	d02080e7          	jalr	-766(ra) # 800019de <copyin>
    80004ce4:	03850563          	beq	a0,s8,80004d0e <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ce8:	21c4a783          	lw	a5,540(s1)
    80004cec:	0017871b          	addiw	a4,a5,1
    80004cf0:	20e4ae23          	sw	a4,540(s1)
    80004cf4:	1ff7f793          	andi	a5,a5,511
    80004cf8:	97a6                	add	a5,a5,s1
    80004cfa:	faf44703          	lbu	a4,-81(s0)
    80004cfe:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d02:	2b85                	addiw	s7,s7,1
    80004d04:	0b05                	addi	s6,s6,1
    80004d06:	f97a94e3          	bne	s5,s7,80004c8e <pipewrite+0x42>
    80004d0a:	a011                	j	80004d0e <pipewrite+0xc2>
    80004d0c:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d0e:	21848513          	addi	a0,s1,536
    80004d12:	ffffe097          	auipc	ra,0xffffe
    80004d16:	976080e7          	jalr	-1674(ra) # 80002688 <wakeup>
  release(&pi->lock);
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	f96080e7          	jalr	-106(ra) # 80000cb2 <release>
  return i;
    80004d24:	a039                	j	80004d32 <pipewrite+0xe6>
        release(&pi->lock);
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	f8a080e7          	jalr	-118(ra) # 80000cb2 <release>
        return -1;
    80004d30:	5bfd                	li	s7,-1
}
    80004d32:	855e                	mv	a0,s7
    80004d34:	60e6                	ld	ra,88(sp)
    80004d36:	6446                	ld	s0,80(sp)
    80004d38:	64a6                	ld	s1,72(sp)
    80004d3a:	6906                	ld	s2,64(sp)
    80004d3c:	79e2                	ld	s3,56(sp)
    80004d3e:	7a42                	ld	s4,48(sp)
    80004d40:	7aa2                	ld	s5,40(sp)
    80004d42:	7b02                	ld	s6,32(sp)
    80004d44:	6be2                	ld	s7,24(sp)
    80004d46:	6c42                	ld	s8,16(sp)
    80004d48:	6125                	addi	sp,sp,96
    80004d4a:	8082                	ret

0000000080004d4c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d4c:	715d                	addi	sp,sp,-80
    80004d4e:	e486                	sd	ra,72(sp)
    80004d50:	e0a2                	sd	s0,64(sp)
    80004d52:	fc26                	sd	s1,56(sp)
    80004d54:	f84a                	sd	s2,48(sp)
    80004d56:	f44e                	sd	s3,40(sp)
    80004d58:	f052                	sd	s4,32(sp)
    80004d5a:	ec56                	sd	s5,24(sp)
    80004d5c:	e85a                	sd	s6,16(sp)
    80004d5e:	0880                	addi	s0,sp,80
    80004d60:	84aa                	mv	s1,a0
    80004d62:	892e                	mv	s2,a1
    80004d64:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	d78080e7          	jalr	-648(ra) # 80001ade <myproc>
    80004d6e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	e8c080e7          	jalr	-372(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d7a:	2184a703          	lw	a4,536(s1)
    80004d7e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d82:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d86:	02f71463          	bne	a4,a5,80004dae <piperead+0x62>
    80004d8a:	2244a783          	lw	a5,548(s1)
    80004d8e:	c385                	beqz	a5,80004dae <piperead+0x62>
    if(pr->killed){
    80004d90:	030a2783          	lw	a5,48(s4)
    80004d94:	ebc1                	bnez	a5,80004e24 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d96:	85a6                	mv	a1,s1
    80004d98:	854e                	mv	a0,s3
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	76e080e7          	jalr	1902(ra) # 80002508 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	2184a703          	lw	a4,536(s1)
    80004da6:	21c4a783          	lw	a5,540(s1)
    80004daa:	fef700e3          	beq	a4,a5,80004d8a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004db0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db2:	05505363          	blez	s5,80004df8 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004db6:	2184a783          	lw	a5,536(s1)
    80004dba:	21c4a703          	lw	a4,540(s1)
    80004dbe:	02f70d63          	beq	a4,a5,80004df8 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dc2:	0017871b          	addiw	a4,a5,1
    80004dc6:	20e4ac23          	sw	a4,536(s1)
    80004dca:	1ff7f793          	andi	a5,a5,511
    80004dce:	97a6                	add	a5,a5,s1
    80004dd0:	0187c783          	lbu	a5,24(a5)
    80004dd4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd8:	4685                	li	a3,1
    80004dda:	fbf40613          	addi	a2,s0,-65
    80004dde:	85ca                	mv	a1,s2
    80004de0:	050a3503          	ld	a0,80(s4)
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	b6e080e7          	jalr	-1170(ra) # 80001952 <copyout>
    80004dec:	01650663          	beq	a0,s6,80004df8 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df0:	2985                	addiw	s3,s3,1
    80004df2:	0905                	addi	s2,s2,1
    80004df4:	fd3a91e3          	bne	s5,s3,80004db6 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004df8:	21c48513          	addi	a0,s1,540
    80004dfc:	ffffe097          	auipc	ra,0xffffe
    80004e00:	88c080e7          	jalr	-1908(ra) # 80002688 <wakeup>
  release(&pi->lock);
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	eac080e7          	jalr	-340(ra) # 80000cb2 <release>
  return i;
}
    80004e0e:	854e                	mv	a0,s3
    80004e10:	60a6                	ld	ra,72(sp)
    80004e12:	6406                	ld	s0,64(sp)
    80004e14:	74e2                	ld	s1,56(sp)
    80004e16:	7942                	ld	s2,48(sp)
    80004e18:	79a2                	ld	s3,40(sp)
    80004e1a:	7a02                	ld	s4,32(sp)
    80004e1c:	6ae2                	ld	s5,24(sp)
    80004e1e:	6b42                	ld	s6,16(sp)
    80004e20:	6161                	addi	sp,sp,80
    80004e22:	8082                	ret
      release(&pi->lock);
    80004e24:	8526                	mv	a0,s1
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	e8c080e7          	jalr	-372(ra) # 80000cb2 <release>
      return -1;
    80004e2e:	59fd                	li	s3,-1
    80004e30:	bff9                	j	80004e0e <piperead+0xc2>

0000000080004e32 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e32:	de010113          	addi	sp,sp,-544
    80004e36:	20113c23          	sd	ra,536(sp)
    80004e3a:	20813823          	sd	s0,528(sp)
    80004e3e:	20913423          	sd	s1,520(sp)
    80004e42:	21213023          	sd	s2,512(sp)
    80004e46:	ffce                	sd	s3,504(sp)
    80004e48:	fbd2                	sd	s4,496(sp)
    80004e4a:	f7d6                	sd	s5,488(sp)
    80004e4c:	f3da                	sd	s6,480(sp)
    80004e4e:	efde                	sd	s7,472(sp)
    80004e50:	ebe2                	sd	s8,464(sp)
    80004e52:	e7e6                	sd	s9,456(sp)
    80004e54:	e3ea                	sd	s10,448(sp)
    80004e56:	ff6e                	sd	s11,440(sp)
    80004e58:	1400                	addi	s0,sp,544
    80004e5a:	892a                	mv	s2,a0
    80004e5c:	dea43423          	sd	a0,-536(s0)
    80004e60:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	c7a080e7          	jalr	-902(ra) # 80001ade <myproc>
    80004e6c:	84aa                	mv	s1,a0

  begin_op();
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	46c080e7          	jalr	1132(ra) # 800042da <begin_op>

  if((ip = namei(path)) == 0){
    80004e76:	854a                	mv	a0,s2
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	256080e7          	jalr	598(ra) # 800040ce <namei>
    80004e80:	c93d                	beqz	a0,80004ef6 <exec+0xc4>
    80004e82:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	a9a080e7          	jalr	-1382(ra) # 8000391e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e8c:	04000713          	li	a4,64
    80004e90:	4681                	li	a3,0
    80004e92:	e4840613          	addi	a2,s0,-440
    80004e96:	4581                	li	a1,0
    80004e98:	8556                	mv	a0,s5
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	d38080e7          	jalr	-712(ra) # 80003bd2 <readi>
    80004ea2:	04000793          	li	a5,64
    80004ea6:	00f51a63          	bne	a0,a5,80004eba <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004eaa:	e4842703          	lw	a4,-440(s0)
    80004eae:	464c47b7          	lui	a5,0x464c4
    80004eb2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eb6:	04f70663          	beq	a4,a5,80004f02 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eba:	8556                	mv	a0,s5
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	cc4080e7          	jalr	-828(ra) # 80003b80 <iunlockput>
    end_op();
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	496080e7          	jalr	1174(ra) # 8000435a <end_op>
  }
  return -1;
    80004ecc:	557d                	li	a0,-1
}
    80004ece:	21813083          	ld	ra,536(sp)
    80004ed2:	21013403          	ld	s0,528(sp)
    80004ed6:	20813483          	ld	s1,520(sp)
    80004eda:	20013903          	ld	s2,512(sp)
    80004ede:	79fe                	ld	s3,504(sp)
    80004ee0:	7a5e                	ld	s4,496(sp)
    80004ee2:	7abe                	ld	s5,488(sp)
    80004ee4:	7b1e                	ld	s6,480(sp)
    80004ee6:	6bfe                	ld	s7,472(sp)
    80004ee8:	6c5e                	ld	s8,464(sp)
    80004eea:	6cbe                	ld	s9,456(sp)
    80004eec:	6d1e                	ld	s10,448(sp)
    80004eee:	7dfa                	ld	s11,440(sp)
    80004ef0:	22010113          	addi	sp,sp,544
    80004ef4:	8082                	ret
    end_op();
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	464080e7          	jalr	1124(ra) # 8000435a <end_op>
    return -1;
    80004efe:	557d                	li	a0,-1
    80004f00:	b7f9                	j	80004ece <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f02:	8526                	mv	a0,s1
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	c9e080e7          	jalr	-866(ra) # 80001ba2 <proc_pagetable>
    80004f0c:	8b2a                	mv	s6,a0
    80004f0e:	d555                	beqz	a0,80004eba <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f10:	e6842783          	lw	a5,-408(s0)
    80004f14:	e8045703          	lhu	a4,-384(s0)
    80004f18:	c735                	beqz	a4,80004f84 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f1a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f1c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f20:	6a05                	lui	s4,0x1
    80004f22:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f26:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f2a:	6d85                	lui	s11,0x1
    80004f2c:	7d7d                	lui	s10,0xfffff
    80004f2e:	ac9d                	j	800051a4 <exec+0x372>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f30:	00003517          	auipc	a0,0x3
    80004f34:	7d850513          	addi	a0,a0,2008 # 80008708 <syscalls+0x290>
    80004f38:	ffffb097          	auipc	ra,0xffffb
    80004f3c:	60a080e7          	jalr	1546(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f40:	874a                	mv	a4,s2
    80004f42:	009c86bb          	addw	a3,s9,s1
    80004f46:	4581                	li	a1,0
    80004f48:	8556                	mv	a0,s5
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	c88080e7          	jalr	-888(ra) # 80003bd2 <readi>
    80004f52:	2501                	sext.w	a0,a0
    80004f54:	1ea91c63          	bne	s2,a0,8000514c <exec+0x31a>
  for(i = 0; i < sz; i += PGSIZE){
    80004f58:	009d84bb          	addw	s1,s11,s1
    80004f5c:	013d09bb          	addw	s3,s10,s3
    80004f60:	2374f263          	bgeu	s1,s7,80005184 <exec+0x352>
    pa = walkaddr(pagetable, va + i);
    80004f64:	02049593          	slli	a1,s1,0x20
    80004f68:	9181                	srli	a1,a1,0x20
    80004f6a:	95e2                	add	a1,a1,s8
    80004f6c:	855a                	mv	a0,s6
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	21a080e7          	jalr	538(ra) # 80001188 <walkaddr>
    80004f76:	862a                	mv	a2,a0
    if(pa == 0)
    80004f78:	dd45                	beqz	a0,80004f30 <exec+0xfe>
      n = PGSIZE;
    80004f7a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f7c:	fd49f2e3          	bgeu	s3,s4,80004f40 <exec+0x10e>
      n = sz - i;
    80004f80:	894e                	mv	s2,s3
    80004f82:	bf7d                	j	80004f40 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f84:	4481                	li	s1,0
  iunlockput(ip);
    80004f86:	8556                	mv	a0,s5
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	bf8080e7          	jalr	-1032(ra) # 80003b80 <iunlockput>
  end_op();
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	3ca080e7          	jalr	970(ra) # 8000435a <end_op>
  p = myproc();
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	b46080e7          	jalr	-1210(ra) # 80001ade <myproc>
    80004fa0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fa2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004fa6:	6785                	lui	a5,0x1
    80004fa8:	17fd                	addi	a5,a5,-1
    80004faa:	94be                	add	s1,s1,a5
    80004fac:	77fd                	lui	a5,0xfffff
    80004fae:	8cfd                	and	s1,s1,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fb0:	6609                	lui	a2,0x2
    80004fb2:	9626                	add	a2,a2,s1
    80004fb4:	85a6                	mv	a1,s1
    80004fb6:	855a                	mv	a0,s6
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	75c080e7          	jalr	1884(ra) # 80001714 <uvmalloc>
    80004fc0:	892a                	mv	s2,a0
    80004fc2:	dea43c23          	sd	a0,-520(s0)
    80004fc6:	e509                	bnez	a0,80004fd0 <exec+0x19e>
  sz = PGROUNDUP(sz);
    80004fc8:	de943c23          	sd	s1,-520(s0)
  ip = 0;
    80004fcc:	4a81                	li	s5,0
    80004fce:	aabd                	j	8000514c <exec+0x31a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fd0:	75f9                	lui	a1,0xffffe
    80004fd2:	95aa                	add	a1,a1,a0
    80004fd4:	855a                	mv	a0,s6
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	94a080e7          	jalr	-1718(ra) # 80001920 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fde:	7c7d                	lui	s8,0xfffff
    80004fe0:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80004fe2:	df043783          	ld	a5,-528(s0)
    80004fe6:	6388                	ld	a0,0(a5)
    80004fe8:	c52d                	beqz	a0,80005052 <exec+0x220>
    80004fea:	e8840993          	addi	s3,s0,-376
    80004fee:	f8840a93          	addi	s5,s0,-120
    80004ff2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	e8a080e7          	jalr	-374(ra) # 80000e7e <strlen>
    80004ffc:	0015079b          	addiw	a5,a0,1
    80005000:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005004:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005008:	17896663          	bltu	s2,s8,80005174 <exec+0x342>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000500c:	df043d03          	ld	s10,-528(s0)
    80005010:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80005014:	8552                	mv	a0,s4
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	e68080e7          	jalr	-408(ra) # 80000e7e <strlen>
    8000501e:	0015069b          	addiw	a3,a0,1
    80005022:	8652                	mv	a2,s4
    80005024:	85ca                	mv	a1,s2
    80005026:	855a                	mv	a0,s6
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	92a080e7          	jalr	-1750(ra) # 80001952 <copyout>
    80005030:	14054463          	bltz	a0,80005178 <exec+0x346>
    ustack[argc] = sp;
    80005034:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005038:	0485                	addi	s1,s1,1
    8000503a:	008d0793          	addi	a5,s10,8
    8000503e:	def43823          	sd	a5,-528(s0)
    80005042:	008d3503          	ld	a0,8(s10)
    80005046:	c909                	beqz	a0,80005058 <exec+0x226>
    if(argc >= MAXARG)
    80005048:	09a1                	addi	s3,s3,8
    8000504a:	fb3a95e3          	bne	s5,s3,80004ff4 <exec+0x1c2>
  ip = 0;
    8000504e:	4a81                	li	s5,0
    80005050:	a8f5                	j	8000514c <exec+0x31a>
  sp = sz;
    80005052:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005056:	4481                	li	s1,0
  ustack[argc] = 0;
    80005058:	00349793          	slli	a5,s1,0x3
    8000505c:	f9040713          	addi	a4,s0,-112
    80005060:	97ba                	add	a5,a5,a4
    80005062:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ed8>
  sp -= (argc+1) * sizeof(uint64);
    80005066:	00148693          	addi	a3,s1,1
    8000506a:	068e                	slli	a3,a3,0x3
    8000506c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005070:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80005074:	4a81                	li	s5,0
  if(sp < stackbase)
    80005076:	0d896b63          	bltu	s2,s8,8000514c <exec+0x31a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000507a:	e8840613          	addi	a2,s0,-376
    8000507e:	85ca                	mv	a1,s2
    80005080:	855a                	mv	a0,s6
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	8d0080e7          	jalr	-1840(ra) # 80001952 <copyout>
    8000508a:	0e054963          	bltz	a0,8000517c <exec+0x34a>
  p->trapframe->a1 = sp;
    8000508e:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    80005092:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005096:	de843783          	ld	a5,-536(s0)
    8000509a:	0007c703          	lbu	a4,0(a5)
    8000509e:	cf11                	beqz	a4,800050ba <exec+0x288>
    800050a0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050a2:	02f00693          	li	a3,47
    800050a6:	a039                	j	800050b4 <exec+0x282>
      last = s+1;
    800050a8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050ac:	0785                	addi	a5,a5,1
    800050ae:	fff7c703          	lbu	a4,-1(a5)
    800050b2:	c701                	beqz	a4,800050ba <exec+0x288>
    if(*s == '/')
    800050b4:	fed71ce3          	bne	a4,a3,800050ac <exec+0x27a>
    800050b8:	bfc5                	j	800050a8 <exec+0x276>
  safestrcpy(p->name, last, sizeof(p->name));
    800050ba:	4641                	li	a2,16
    800050bc:	de843583          	ld	a1,-536(s0)
    800050c0:	160b8513          	addi	a0,s7,352
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	d88080e7          	jalr	-632(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    800050cc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050d0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050d4:	df843783          	ld	a5,-520(s0)
    800050d8:	04fbb423          	sd	a5,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050dc:	060bb783          	ld	a5,96(s7)
    800050e0:	e6043703          	ld	a4,-416(s0)
    800050e4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050e6:	060bb783          	ld	a5,96(s7)
    800050ea:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050ee:	85e6                	mv	a1,s9
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	be0080e7          	jalr	-1056(ra) # 80001cd0 <proc_freepagetable>
  uvmunmap(p->kpagetable,0,PGROUNDUP(oldsz)/PGSIZE,0);
    800050f8:	6605                	lui	a2,0x1
    800050fa:	167d                	addi	a2,a2,-1
    800050fc:	9666                	add	a2,a2,s9
    800050fe:	4681                	li	a3,0
    80005100:	8231                	srli	a2,a2,0xc
    80005102:	4581                	li	a1,0
    80005104:	058bb503          	ld	a0,88(s7)
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	3bc080e7          	jalr	956(ra) # 800014c4 <uvmunmap>
  if(upg2ukpg(p->pagetable,p->kpagetable,0,p->sz)<0)
    80005110:	048bb683          	ld	a3,72(s7)
    80005114:	4601                	li	a2,0
    80005116:	058bb583          	ld	a1,88(s7)
    8000511a:	050bb503          	ld	a0,80(s7)
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	45c080e7          	jalr	1116(ra) # 8000157a <upg2ukpg>
    80005126:	04054d63          	bltz	a0,80005180 <exec+0x34e>
  if(p->pid==1)
    8000512a:	038ba703          	lw	a4,56(s7)
    8000512e:	4785                	li	a5,1
    80005130:	00f70563          	beq	a4,a5,8000513a <exec+0x308>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005134:	0004851b          	sext.w	a0,s1
    80005138:	bb59                	j	80004ece <exec+0x9c>
    vmprint(p->pagetable);
    8000513a:	050bb503          	ld	a0,80(s7)
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	f4c080e7          	jalr	-180(ra) # 8000108a <vmprint>
    80005146:	b7fd                	j	80005134 <exec+0x302>
    80005148:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000514c:	df843583          	ld	a1,-520(s0)
    80005150:	855a                	mv	a0,s6
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	b7e080e7          	jalr	-1154(ra) # 80001cd0 <proc_freepagetable>
  if(ip){
    8000515a:	d60a90e3          	bnez	s5,80004eba <exec+0x88>
  return -1;
    8000515e:	557d                	li	a0,-1
    80005160:	b3bd                	j	80004ece <exec+0x9c>
    80005162:	de943c23          	sd	s1,-520(s0)
    80005166:	b7dd                	j	8000514c <exec+0x31a>
    80005168:	de943c23          	sd	s1,-520(s0)
    8000516c:	b7c5                	j	8000514c <exec+0x31a>
    8000516e:	de943c23          	sd	s1,-520(s0)
    80005172:	bfe9                	j	8000514c <exec+0x31a>
  ip = 0;
    80005174:	4a81                	li	s5,0
    80005176:	bfd9                	j	8000514c <exec+0x31a>
    80005178:	4a81                	li	s5,0
    8000517a:	bfc9                	j	8000514c <exec+0x31a>
    8000517c:	4a81                	li	s5,0
    8000517e:	b7f9                	j	8000514c <exec+0x31a>
    80005180:	4a81                	li	s5,0
    80005182:	b7e9                	j	8000514c <exec+0x31a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005184:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005188:	e0843783          	ld	a5,-504(s0)
    8000518c:	0017869b          	addiw	a3,a5,1
    80005190:	e0d43423          	sd	a3,-504(s0)
    80005194:	e0043783          	ld	a5,-512(s0)
    80005198:	0387879b          	addiw	a5,a5,56
    8000519c:	e8045703          	lhu	a4,-384(s0)
    800051a0:	dee6d3e3          	bge	a3,a4,80004f86 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051a4:	2781                	sext.w	a5,a5
    800051a6:	e0f43023          	sd	a5,-512(s0)
    800051aa:	03800713          	li	a4,56
    800051ae:	86be                	mv	a3,a5
    800051b0:	e1040613          	addi	a2,s0,-496
    800051b4:	4581                	li	a1,0
    800051b6:	8556                	mv	a0,s5
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	a1a080e7          	jalr	-1510(ra) # 80003bd2 <readi>
    800051c0:	03800793          	li	a5,56
    800051c4:	f8f512e3          	bne	a0,a5,80005148 <exec+0x316>
    if(ph.type != ELF_PROG_LOAD)
    800051c8:	e1042783          	lw	a5,-496(s0)
    800051cc:	4705                	li	a4,1
    800051ce:	fae79de3          	bne	a5,a4,80005188 <exec+0x356>
    if(ph.memsz < ph.filesz)
    800051d2:	e3843603          	ld	a2,-456(s0)
    800051d6:	e3043783          	ld	a5,-464(s0)
    800051da:	f8f664e3          	bltu	a2,a5,80005162 <exec+0x330>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051de:	e2043783          	ld	a5,-480(s0)
    800051e2:	963e                	add	a2,a2,a5
    800051e4:	f8f662e3          	bltu	a2,a5,80005168 <exec+0x336>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051e8:	85a6                	mv	a1,s1
    800051ea:	855a                	mv	a0,s6
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	528080e7          	jalr	1320(ra) # 80001714 <uvmalloc>
    800051f4:	dea43c23          	sd	a0,-520(s0)
    800051f8:	d93d                	beqz	a0,8000516e <exec+0x33c>
    if(ph.vaddr % PGSIZE != 0)
    800051fa:	e2043c03          	ld	s8,-480(s0)
    800051fe:	de043783          	ld	a5,-544(s0)
    80005202:	00fc77b3          	and	a5,s8,a5
    80005206:	f3b9                	bnez	a5,8000514c <exec+0x31a>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005208:	e1842c83          	lw	s9,-488(s0)
    8000520c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005210:	f60b8ae3          	beqz	s7,80005184 <exec+0x352>
    80005214:	89de                	mv	s3,s7
    80005216:	4481                	li	s1,0
    80005218:	b3b1                	j	80004f64 <exec+0x132>

000000008000521a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000521a:	7179                	addi	sp,sp,-48
    8000521c:	f406                	sd	ra,40(sp)
    8000521e:	f022                	sd	s0,32(sp)
    80005220:	ec26                	sd	s1,24(sp)
    80005222:	e84a                	sd	s2,16(sp)
    80005224:	1800                	addi	s0,sp,48
    80005226:	892e                	mv	s2,a1
    80005228:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000522a:	fdc40593          	addi	a1,s0,-36
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	b80080e7          	jalr	-1152(ra) # 80002dae <argint>
    80005236:	04054063          	bltz	a0,80005276 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000523a:	fdc42703          	lw	a4,-36(s0)
    8000523e:	47bd                	li	a5,15
    80005240:	02e7ed63          	bltu	a5,a4,8000527a <argfd+0x60>
    80005244:	ffffd097          	auipc	ra,0xffffd
    80005248:	89a080e7          	jalr	-1894(ra) # 80001ade <myproc>
    8000524c:	fdc42703          	lw	a4,-36(s0)
    80005250:	01a70793          	addi	a5,a4,26
    80005254:	078e                	slli	a5,a5,0x3
    80005256:	953e                	add	a0,a0,a5
    80005258:	651c                	ld	a5,8(a0)
    8000525a:	c395                	beqz	a5,8000527e <argfd+0x64>
    return -1;
  if(pfd)
    8000525c:	00090463          	beqz	s2,80005264 <argfd+0x4a>
    *pfd = fd;
    80005260:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005264:	4501                	li	a0,0
  if(pf)
    80005266:	c091                	beqz	s1,8000526a <argfd+0x50>
    *pf = f;
    80005268:	e09c                	sd	a5,0(s1)
}
    8000526a:	70a2                	ld	ra,40(sp)
    8000526c:	7402                	ld	s0,32(sp)
    8000526e:	64e2                	ld	s1,24(sp)
    80005270:	6942                	ld	s2,16(sp)
    80005272:	6145                	addi	sp,sp,48
    80005274:	8082                	ret
    return -1;
    80005276:	557d                	li	a0,-1
    80005278:	bfcd                	j	8000526a <argfd+0x50>
    return -1;
    8000527a:	557d                	li	a0,-1
    8000527c:	b7fd                	j	8000526a <argfd+0x50>
    8000527e:	557d                	li	a0,-1
    80005280:	b7ed                	j	8000526a <argfd+0x50>

0000000080005282 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005282:	1101                	addi	sp,sp,-32
    80005284:	ec06                	sd	ra,24(sp)
    80005286:	e822                	sd	s0,16(sp)
    80005288:	e426                	sd	s1,8(sp)
    8000528a:	1000                	addi	s0,sp,32
    8000528c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000528e:	ffffd097          	auipc	ra,0xffffd
    80005292:	850080e7          	jalr	-1968(ra) # 80001ade <myproc>
    80005296:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005298:	0d850793          	addi	a5,a0,216
    8000529c:	4501                	li	a0,0
    8000529e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052a0:	6398                	ld	a4,0(a5)
    800052a2:	cb19                	beqz	a4,800052b8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052a4:	2505                	addiw	a0,a0,1
    800052a6:	07a1                	addi	a5,a5,8
    800052a8:	fed51ce3          	bne	a0,a3,800052a0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052ac:	557d                	li	a0,-1
}
    800052ae:	60e2                	ld	ra,24(sp)
    800052b0:	6442                	ld	s0,16(sp)
    800052b2:	64a2                	ld	s1,8(sp)
    800052b4:	6105                	addi	sp,sp,32
    800052b6:	8082                	ret
      p->ofile[fd] = f;
    800052b8:	01a50793          	addi	a5,a0,26
    800052bc:	078e                	slli	a5,a5,0x3
    800052be:	963e                	add	a2,a2,a5
    800052c0:	e604                	sd	s1,8(a2)
      return fd;
    800052c2:	b7f5                	j	800052ae <fdalloc+0x2c>

00000000800052c4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052c4:	715d                	addi	sp,sp,-80
    800052c6:	e486                	sd	ra,72(sp)
    800052c8:	e0a2                	sd	s0,64(sp)
    800052ca:	fc26                	sd	s1,56(sp)
    800052cc:	f84a                	sd	s2,48(sp)
    800052ce:	f44e                	sd	s3,40(sp)
    800052d0:	f052                	sd	s4,32(sp)
    800052d2:	ec56                	sd	s5,24(sp)
    800052d4:	0880                	addi	s0,sp,80
    800052d6:	89ae                	mv	s3,a1
    800052d8:	8ab2                	mv	s5,a2
    800052da:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052dc:	fb040593          	addi	a1,s0,-80
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	e0c080e7          	jalr	-500(ra) # 800040ec <nameiparent>
    800052e8:	892a                	mv	s2,a0
    800052ea:	12050e63          	beqz	a0,80005426 <create+0x162>
    return 0;

  ilock(dp);
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	630080e7          	jalr	1584(ra) # 8000391e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052f6:	4601                	li	a2,0
    800052f8:	fb040593          	addi	a1,s0,-80
    800052fc:	854a                	mv	a0,s2
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	afe080e7          	jalr	-1282(ra) # 80003dfc <dirlookup>
    80005306:	84aa                	mv	s1,a0
    80005308:	c921                	beqz	a0,80005358 <create+0x94>
    iunlockput(dp);
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	874080e7          	jalr	-1932(ra) # 80003b80 <iunlockput>
    ilock(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	608080e7          	jalr	1544(ra) # 8000391e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000531e:	2981                	sext.w	s3,s3
    80005320:	4789                	li	a5,2
    80005322:	02f99463          	bne	s3,a5,8000534a <create+0x86>
    80005326:	0444d783          	lhu	a5,68(s1)
    8000532a:	37f9                	addiw	a5,a5,-2
    8000532c:	17c2                	slli	a5,a5,0x30
    8000532e:	93c1                	srli	a5,a5,0x30
    80005330:	4705                	li	a4,1
    80005332:	00f76c63          	bltu	a4,a5,8000534a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005336:	8526                	mv	a0,s1
    80005338:	60a6                	ld	ra,72(sp)
    8000533a:	6406                	ld	s0,64(sp)
    8000533c:	74e2                	ld	s1,56(sp)
    8000533e:	7942                	ld	s2,48(sp)
    80005340:	79a2                	ld	s3,40(sp)
    80005342:	7a02                	ld	s4,32(sp)
    80005344:	6ae2                	ld	s5,24(sp)
    80005346:	6161                	addi	sp,sp,80
    80005348:	8082                	ret
    iunlockput(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	834080e7          	jalr	-1996(ra) # 80003b80 <iunlockput>
    return 0;
    80005354:	4481                	li	s1,0
    80005356:	b7c5                	j	80005336 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005358:	85ce                	mv	a1,s3
    8000535a:	00092503          	lw	a0,0(s2)
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	428080e7          	jalr	1064(ra) # 80003786 <ialloc>
    80005366:	84aa                	mv	s1,a0
    80005368:	c521                	beqz	a0,800053b0 <create+0xec>
  ilock(ip);
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	5b4080e7          	jalr	1460(ra) # 8000391e <ilock>
  ip->major = major;
    80005372:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005376:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000537a:	4a05                	li	s4,1
    8000537c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005380:	8526                	mv	a0,s1
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	4d2080e7          	jalr	1234(ra) # 80003854 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000538a:	2981                	sext.w	s3,s3
    8000538c:	03498a63          	beq	s3,s4,800053c0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005390:	40d0                	lw	a2,4(s1)
    80005392:	fb040593          	addi	a1,s0,-80
    80005396:	854a                	mv	a0,s2
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	c74080e7          	jalr	-908(ra) # 8000400c <dirlink>
    800053a0:	06054b63          	bltz	a0,80005416 <create+0x152>
  iunlockput(dp);
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	7da080e7          	jalr	2010(ra) # 80003b80 <iunlockput>
  return ip;
    800053ae:	b761                	j	80005336 <create+0x72>
    panic("create: ialloc");
    800053b0:	00003517          	auipc	a0,0x3
    800053b4:	37850513          	addi	a0,a0,888 # 80008728 <syscalls+0x2b0>
    800053b8:	ffffb097          	auipc	ra,0xffffb
    800053bc:	18a080e7          	jalr	394(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    800053c0:	04a95783          	lhu	a5,74(s2)
    800053c4:	2785                	addiw	a5,a5,1
    800053c6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053ca:	854a                	mv	a0,s2
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	488080e7          	jalr	1160(ra) # 80003854 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d4:	40d0                	lw	a2,4(s1)
    800053d6:	00003597          	auipc	a1,0x3
    800053da:	36258593          	addi	a1,a1,866 # 80008738 <syscalls+0x2c0>
    800053de:	8526                	mv	a0,s1
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	c2c080e7          	jalr	-980(ra) # 8000400c <dirlink>
    800053e8:	00054f63          	bltz	a0,80005406 <create+0x142>
    800053ec:	00492603          	lw	a2,4(s2)
    800053f0:	00003597          	auipc	a1,0x3
    800053f4:	ce058593          	addi	a1,a1,-800 # 800080d0 <digits+0x90>
    800053f8:	8526                	mv	a0,s1
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	c12080e7          	jalr	-1006(ra) # 8000400c <dirlink>
    80005402:	f80557e3          	bgez	a0,80005390 <create+0xcc>
      panic("create dots");
    80005406:	00003517          	auipc	a0,0x3
    8000540a:	33a50513          	addi	a0,a0,826 # 80008740 <syscalls+0x2c8>
    8000540e:	ffffb097          	auipc	ra,0xffffb
    80005412:	134080e7          	jalr	308(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005416:	00003517          	auipc	a0,0x3
    8000541a:	33a50513          	addi	a0,a0,826 # 80008750 <syscalls+0x2d8>
    8000541e:	ffffb097          	auipc	ra,0xffffb
    80005422:	124080e7          	jalr	292(ra) # 80000542 <panic>
    return 0;
    80005426:	84aa                	mv	s1,a0
    80005428:	b739                	j	80005336 <create+0x72>

000000008000542a <sys_dup>:
{
    8000542a:	7179                	addi	sp,sp,-48
    8000542c:	f406                	sd	ra,40(sp)
    8000542e:	f022                	sd	s0,32(sp)
    80005430:	ec26                	sd	s1,24(sp)
    80005432:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005434:	fd840613          	addi	a2,s0,-40
    80005438:	4581                	li	a1,0
    8000543a:	4501                	li	a0,0
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	dde080e7          	jalr	-546(ra) # 8000521a <argfd>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005446:	02054363          	bltz	a0,8000546c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000544a:	fd843503          	ld	a0,-40(s0)
    8000544e:	00000097          	auipc	ra,0x0
    80005452:	e34080e7          	jalr	-460(ra) # 80005282 <fdalloc>
    80005456:	84aa                	mv	s1,a0
    return -1;
    80005458:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000545a:	00054963          	bltz	a0,8000546c <sys_dup+0x42>
  filedup(f);
    8000545e:	fd843503          	ld	a0,-40(s0)
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	2f8080e7          	jalr	760(ra) # 8000475a <filedup>
  return fd;
    8000546a:	87a6                	mv	a5,s1
}
    8000546c:	853e                	mv	a0,a5
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	64e2                	ld	s1,24(sp)
    80005474:	6145                	addi	sp,sp,48
    80005476:	8082                	ret

0000000080005478 <sys_read>:
{
    80005478:	7179                	addi	sp,sp,-48
    8000547a:	f406                	sd	ra,40(sp)
    8000547c:	f022                	sd	s0,32(sp)
    8000547e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005480:	fe840613          	addi	a2,s0,-24
    80005484:	4581                	li	a1,0
    80005486:	4501                	li	a0,0
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	d92080e7          	jalr	-622(ra) # 8000521a <argfd>
    return -1;
    80005490:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005492:	04054163          	bltz	a0,800054d4 <sys_read+0x5c>
    80005496:	fe440593          	addi	a1,s0,-28
    8000549a:	4509                	li	a0,2
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	912080e7          	jalr	-1774(ra) # 80002dae <argint>
    return -1;
    800054a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a6:	02054763          	bltz	a0,800054d4 <sys_read+0x5c>
    800054aa:	fd840593          	addi	a1,s0,-40
    800054ae:	4505                	li	a0,1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	920080e7          	jalr	-1760(ra) # 80002dd0 <argaddr>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ba:	00054d63          	bltz	a0,800054d4 <sys_read+0x5c>
  return fileread(f, p, n);
    800054be:	fe442603          	lw	a2,-28(s0)
    800054c2:	fd843583          	ld	a1,-40(s0)
    800054c6:	fe843503          	ld	a0,-24(s0)
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	41c080e7          	jalr	1052(ra) # 800048e6 <fileread>
    800054d2:	87aa                	mv	a5,a0
}
    800054d4:	853e                	mv	a0,a5
    800054d6:	70a2                	ld	ra,40(sp)
    800054d8:	7402                	ld	s0,32(sp)
    800054da:	6145                	addi	sp,sp,48
    800054dc:	8082                	ret

00000000800054de <sys_write>:
{
    800054de:	7179                	addi	sp,sp,-48
    800054e0:	f406                	sd	ra,40(sp)
    800054e2:	f022                	sd	s0,32(sp)
    800054e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	fe840613          	addi	a2,s0,-24
    800054ea:	4581                	li	a1,0
    800054ec:	4501                	li	a0,0
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	d2c080e7          	jalr	-724(ra) # 8000521a <argfd>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f8:	04054163          	bltz	a0,8000553a <sys_write+0x5c>
    800054fc:	fe440593          	addi	a1,s0,-28
    80005500:	4509                	li	a0,2
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	8ac080e7          	jalr	-1876(ra) # 80002dae <argint>
    return -1;
    8000550a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550c:	02054763          	bltz	a0,8000553a <sys_write+0x5c>
    80005510:	fd840593          	addi	a1,s0,-40
    80005514:	4505                	li	a0,1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	8ba080e7          	jalr	-1862(ra) # 80002dd0 <argaddr>
    return -1;
    8000551e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005520:	00054d63          	bltz	a0,8000553a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005524:	fe442603          	lw	a2,-28(s0)
    80005528:	fd843583          	ld	a1,-40(s0)
    8000552c:	fe843503          	ld	a0,-24(s0)
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	478080e7          	jalr	1144(ra) # 800049a8 <filewrite>
    80005538:	87aa                	mv	a5,a0
}
    8000553a:	853e                	mv	a0,a5
    8000553c:	70a2                	ld	ra,40(sp)
    8000553e:	7402                	ld	s0,32(sp)
    80005540:	6145                	addi	sp,sp,48
    80005542:	8082                	ret

0000000080005544 <sys_close>:
{
    80005544:	1101                	addi	sp,sp,-32
    80005546:	ec06                	sd	ra,24(sp)
    80005548:	e822                	sd	s0,16(sp)
    8000554a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000554c:	fe040613          	addi	a2,s0,-32
    80005550:	fec40593          	addi	a1,s0,-20
    80005554:	4501                	li	a0,0
    80005556:	00000097          	auipc	ra,0x0
    8000555a:	cc4080e7          	jalr	-828(ra) # 8000521a <argfd>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005560:	02054463          	bltz	a0,80005588 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005564:	ffffc097          	auipc	ra,0xffffc
    80005568:	57a080e7          	jalr	1402(ra) # 80001ade <myproc>
    8000556c:	fec42783          	lw	a5,-20(s0)
    80005570:	07e9                	addi	a5,a5,26
    80005572:	078e                	slli	a5,a5,0x3
    80005574:	97aa                	add	a5,a5,a0
    80005576:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000557a:	fe043503          	ld	a0,-32(s0)
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	22e080e7          	jalr	558(ra) # 800047ac <fileclose>
  return 0;
    80005586:	4781                	li	a5,0
}
    80005588:	853e                	mv	a0,a5
    8000558a:	60e2                	ld	ra,24(sp)
    8000558c:	6442                	ld	s0,16(sp)
    8000558e:	6105                	addi	sp,sp,32
    80005590:	8082                	ret

0000000080005592 <sys_fstat>:
{
    80005592:	1101                	addi	sp,sp,-32
    80005594:	ec06                	sd	ra,24(sp)
    80005596:	e822                	sd	s0,16(sp)
    80005598:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	c78080e7          	jalr	-904(ra) # 8000521a <argfd>
    return -1;
    800055aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ac:	02054563          	bltz	a0,800055d6 <sys_fstat+0x44>
    800055b0:	fe040593          	addi	a1,s0,-32
    800055b4:	4505                	li	a0,1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	81a080e7          	jalr	-2022(ra) # 80002dd0 <argaddr>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c0:	00054b63          	bltz	a0,800055d6 <sys_fstat+0x44>
  return filestat(f, st);
    800055c4:	fe043583          	ld	a1,-32(s0)
    800055c8:	fe843503          	ld	a0,-24(s0)
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	2a8080e7          	jalr	680(ra) # 80004874 <filestat>
    800055d4:	87aa                	mv	a5,a0
}
    800055d6:	853e                	mv	a0,a5
    800055d8:	60e2                	ld	ra,24(sp)
    800055da:	6442                	ld	s0,16(sp)
    800055dc:	6105                	addi	sp,sp,32
    800055de:	8082                	ret

00000000800055e0 <sys_link>:
{
    800055e0:	7169                	addi	sp,sp,-304
    800055e2:	f606                	sd	ra,296(sp)
    800055e4:	f222                	sd	s0,288(sp)
    800055e6:	ee26                	sd	s1,280(sp)
    800055e8:	ea4a                	sd	s2,272(sp)
    800055ea:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ec:	08000613          	li	a2,128
    800055f0:	ed040593          	addi	a1,s0,-304
    800055f4:	4501                	li	a0,0
    800055f6:	ffffd097          	auipc	ra,0xffffd
    800055fa:	7fc080e7          	jalr	2044(ra) # 80002df2 <argstr>
    return -1;
    800055fe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005600:	10054e63          	bltz	a0,8000571c <sys_link+0x13c>
    80005604:	08000613          	li	a2,128
    80005608:	f5040593          	addi	a1,s0,-176
    8000560c:	4505                	li	a0,1
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	7e4080e7          	jalr	2020(ra) # 80002df2 <argstr>
    return -1;
    80005616:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005618:	10054263          	bltz	a0,8000571c <sys_link+0x13c>
  begin_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	cbe080e7          	jalr	-834(ra) # 800042da <begin_op>
  if((ip = namei(old)) == 0){
    80005624:	ed040513          	addi	a0,s0,-304
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	aa6080e7          	jalr	-1370(ra) # 800040ce <namei>
    80005630:	84aa                	mv	s1,a0
    80005632:	c551                	beqz	a0,800056be <sys_link+0xde>
  ilock(ip);
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	2ea080e7          	jalr	746(ra) # 8000391e <ilock>
  if(ip->type == T_DIR){
    8000563c:	04449703          	lh	a4,68(s1)
    80005640:	4785                	li	a5,1
    80005642:	08f70463          	beq	a4,a5,800056ca <sys_link+0xea>
  ip->nlink++;
    80005646:	04a4d783          	lhu	a5,74(s1)
    8000564a:	2785                	addiw	a5,a5,1
    8000564c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	202080e7          	jalr	514(ra) # 80003854 <iupdate>
  iunlock(ip);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	384080e7          	jalr	900(ra) # 800039e0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005664:	fd040593          	addi	a1,s0,-48
    80005668:	f5040513          	addi	a0,s0,-176
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	a80080e7          	jalr	-1408(ra) # 800040ec <nameiparent>
    80005674:	892a                	mv	s2,a0
    80005676:	c935                	beqz	a0,800056ea <sys_link+0x10a>
  ilock(dp);
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	2a6080e7          	jalr	678(ra) # 8000391e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005680:	00092703          	lw	a4,0(s2)
    80005684:	409c                	lw	a5,0(s1)
    80005686:	04f71d63          	bne	a4,a5,800056e0 <sys_link+0x100>
    8000568a:	40d0                	lw	a2,4(s1)
    8000568c:	fd040593          	addi	a1,s0,-48
    80005690:	854a                	mv	a0,s2
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	97a080e7          	jalr	-1670(ra) # 8000400c <dirlink>
    8000569a:	04054363          	bltz	a0,800056e0 <sys_link+0x100>
  iunlockput(dp);
    8000569e:	854a                	mv	a0,s2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	4e0080e7          	jalr	1248(ra) # 80003b80 <iunlockput>
  iput(ip);
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	42e080e7          	jalr	1070(ra) # 80003ad8 <iput>
  end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	ca8080e7          	jalr	-856(ra) # 8000435a <end_op>
  return 0;
    800056ba:	4781                	li	a5,0
    800056bc:	a085                	j	8000571c <sys_link+0x13c>
    end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	c9c080e7          	jalr	-868(ra) # 8000435a <end_op>
    return -1;
    800056c6:	57fd                	li	a5,-1
    800056c8:	a891                	j	8000571c <sys_link+0x13c>
    iunlockput(ip);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	4b4080e7          	jalr	1204(ra) # 80003b80 <iunlockput>
    end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	c86080e7          	jalr	-890(ra) # 8000435a <end_op>
    return -1;
    800056dc:	57fd                	li	a5,-1
    800056de:	a83d                	j	8000571c <sys_link+0x13c>
    iunlockput(dp);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	49e080e7          	jalr	1182(ra) # 80003b80 <iunlockput>
  ilock(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	232080e7          	jalr	562(ra) # 8000391e <ilock>
  ip->nlink--;
    800056f4:	04a4d783          	lhu	a5,74(s1)
    800056f8:	37fd                	addiw	a5,a5,-1
    800056fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	154080e7          	jalr	340(ra) # 80003854 <iupdate>
  iunlockput(ip);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	476080e7          	jalr	1142(ra) # 80003b80 <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	c48080e7          	jalr	-952(ra) # 8000435a <end_op>
  return -1;
    8000571a:	57fd                	li	a5,-1
}
    8000571c:	853e                	mv	a0,a5
    8000571e:	70b2                	ld	ra,296(sp)
    80005720:	7412                	ld	s0,288(sp)
    80005722:	64f2                	ld	s1,280(sp)
    80005724:	6952                	ld	s2,272(sp)
    80005726:	6155                	addi	sp,sp,304
    80005728:	8082                	ret

000000008000572a <sys_unlink>:
{
    8000572a:	7151                	addi	sp,sp,-240
    8000572c:	f586                	sd	ra,232(sp)
    8000572e:	f1a2                	sd	s0,224(sp)
    80005730:	eda6                	sd	s1,216(sp)
    80005732:	e9ca                	sd	s2,208(sp)
    80005734:	e5ce                	sd	s3,200(sp)
    80005736:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005738:	08000613          	li	a2,128
    8000573c:	f3040593          	addi	a1,s0,-208
    80005740:	4501                	li	a0,0
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	6b0080e7          	jalr	1712(ra) # 80002df2 <argstr>
    8000574a:	18054163          	bltz	a0,800058cc <sys_unlink+0x1a2>
  begin_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	b8c080e7          	jalr	-1140(ra) # 800042da <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005756:	fb040593          	addi	a1,s0,-80
    8000575a:	f3040513          	addi	a0,s0,-208
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	98e080e7          	jalr	-1650(ra) # 800040ec <nameiparent>
    80005766:	84aa                	mv	s1,a0
    80005768:	c979                	beqz	a0,8000583e <sys_unlink+0x114>
  ilock(dp);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	1b4080e7          	jalr	436(ra) # 8000391e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005772:	00003597          	auipc	a1,0x3
    80005776:	fc658593          	addi	a1,a1,-58 # 80008738 <syscalls+0x2c0>
    8000577a:	fb040513          	addi	a0,s0,-80
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	664080e7          	jalr	1636(ra) # 80003de2 <namecmp>
    80005786:	14050a63          	beqz	a0,800058da <sys_unlink+0x1b0>
    8000578a:	00003597          	auipc	a1,0x3
    8000578e:	94658593          	addi	a1,a1,-1722 # 800080d0 <digits+0x90>
    80005792:	fb040513          	addi	a0,s0,-80
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	64c080e7          	jalr	1612(ra) # 80003de2 <namecmp>
    8000579e:	12050e63          	beqz	a0,800058da <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057a2:	f2c40613          	addi	a2,s0,-212
    800057a6:	fb040593          	addi	a1,s0,-80
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	650080e7          	jalr	1616(ra) # 80003dfc <dirlookup>
    800057b4:	892a                	mv	s2,a0
    800057b6:	12050263          	beqz	a0,800058da <sys_unlink+0x1b0>
  ilock(ip);
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	164080e7          	jalr	356(ra) # 8000391e <ilock>
  if(ip->nlink < 1)
    800057c2:	04a91783          	lh	a5,74(s2)
    800057c6:	08f05263          	blez	a5,8000584a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057ca:	04491703          	lh	a4,68(s2)
    800057ce:	4785                	li	a5,1
    800057d0:	08f70563          	beq	a4,a5,8000585a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057d4:	4641                	li	a2,16
    800057d6:	4581                	li	a1,0
    800057d8:	fc040513          	addi	a0,s0,-64
    800057dc:	ffffb097          	auipc	ra,0xffffb
    800057e0:	51e080e7          	jalr	1310(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e4:	4741                	li	a4,16
    800057e6:	f2c42683          	lw	a3,-212(s0)
    800057ea:	fc040613          	addi	a2,s0,-64
    800057ee:	4581                	li	a1,0
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	4d6080e7          	jalr	1238(ra) # 80003cc8 <writei>
    800057fa:	47c1                	li	a5,16
    800057fc:	0af51563          	bne	a0,a5,800058a6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005800:	04491703          	lh	a4,68(s2)
    80005804:	4785                	li	a5,1
    80005806:	0af70863          	beq	a4,a5,800058b6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	374080e7          	jalr	884(ra) # 80003b80 <iunlockput>
  ip->nlink--;
    80005814:	04a95783          	lhu	a5,74(s2)
    80005818:	37fd                	addiw	a5,a5,-1
    8000581a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	034080e7          	jalr	52(ra) # 80003854 <iupdate>
  iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	356080e7          	jalr	854(ra) # 80003b80 <iunlockput>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	b28080e7          	jalr	-1240(ra) # 8000435a <end_op>
  return 0;
    8000583a:	4501                	li	a0,0
    8000583c:	a84d                	j	800058ee <sys_unlink+0x1c4>
    end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	b1c080e7          	jalr	-1252(ra) # 8000435a <end_op>
    return -1;
    80005846:	557d                	li	a0,-1
    80005848:	a05d                	j	800058ee <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000584a:	00003517          	auipc	a0,0x3
    8000584e:	f1650513          	addi	a0,a0,-234 # 80008760 <syscalls+0x2e8>
    80005852:	ffffb097          	auipc	ra,0xffffb
    80005856:	cf0080e7          	jalr	-784(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585a:	04c92703          	lw	a4,76(s2)
    8000585e:	02000793          	li	a5,32
    80005862:	f6e7f9e3          	bgeu	a5,a4,800057d4 <sys_unlink+0xaa>
    80005866:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000586a:	4741                	li	a4,16
    8000586c:	86ce                	mv	a3,s3
    8000586e:	f1840613          	addi	a2,s0,-232
    80005872:	4581                	li	a1,0
    80005874:	854a                	mv	a0,s2
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	35c080e7          	jalr	860(ra) # 80003bd2 <readi>
    8000587e:	47c1                	li	a5,16
    80005880:	00f51b63          	bne	a0,a5,80005896 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005884:	f1845783          	lhu	a5,-232(s0)
    80005888:	e7a1                	bnez	a5,800058d0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000588a:	29c1                	addiw	s3,s3,16
    8000588c:	04c92783          	lw	a5,76(s2)
    80005890:	fcf9ede3          	bltu	s3,a5,8000586a <sys_unlink+0x140>
    80005894:	b781                	j	800057d4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005896:	00003517          	auipc	a0,0x3
    8000589a:	ee250513          	addi	a0,a0,-286 # 80008778 <syscalls+0x300>
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	ca4080e7          	jalr	-860(ra) # 80000542 <panic>
    panic("unlink: writei");
    800058a6:	00003517          	auipc	a0,0x3
    800058aa:	eea50513          	addi	a0,a0,-278 # 80008790 <syscalls+0x318>
    800058ae:	ffffb097          	auipc	ra,0xffffb
    800058b2:	c94080e7          	jalr	-876(ra) # 80000542 <panic>
    dp->nlink--;
    800058b6:	04a4d783          	lhu	a5,74(s1)
    800058ba:	37fd                	addiw	a5,a5,-1
    800058bc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	f92080e7          	jalr	-110(ra) # 80003854 <iupdate>
    800058ca:	b781                	j	8000580a <sys_unlink+0xe0>
    return -1;
    800058cc:	557d                	li	a0,-1
    800058ce:	a005                	j	800058ee <sys_unlink+0x1c4>
    iunlockput(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	2ae080e7          	jalr	686(ra) # 80003b80 <iunlockput>
  iunlockput(dp);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	2a4080e7          	jalr	676(ra) # 80003b80 <iunlockput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	a76080e7          	jalr	-1418(ra) # 8000435a <end_op>
  return -1;
    800058ec:	557d                	li	a0,-1
}
    800058ee:	70ae                	ld	ra,232(sp)
    800058f0:	740e                	ld	s0,224(sp)
    800058f2:	64ee                	ld	s1,216(sp)
    800058f4:	694e                	ld	s2,208(sp)
    800058f6:	69ae                	ld	s3,200(sp)
    800058f8:	616d                	addi	sp,sp,240
    800058fa:	8082                	ret

00000000800058fc <sys_open>:

uint64
sys_open(void)
{
    800058fc:	7131                	addi	sp,sp,-192
    800058fe:	fd06                	sd	ra,184(sp)
    80005900:	f922                	sd	s0,176(sp)
    80005902:	f526                	sd	s1,168(sp)
    80005904:	f14a                	sd	s2,160(sp)
    80005906:	ed4e                	sd	s3,152(sp)
    80005908:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000590a:	08000613          	li	a2,128
    8000590e:	f5040593          	addi	a1,s0,-176
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	4de080e7          	jalr	1246(ra) # 80002df2 <argstr>
    return -1;
    8000591c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000591e:	0c054163          	bltz	a0,800059e0 <sys_open+0xe4>
    80005922:	f4c40593          	addi	a1,s0,-180
    80005926:	4505                	li	a0,1
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	486080e7          	jalr	1158(ra) # 80002dae <argint>
    80005930:	0a054863          	bltz	a0,800059e0 <sys_open+0xe4>

  begin_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	9a6080e7          	jalr	-1626(ra) # 800042da <begin_op>

  if(omode & O_CREATE){
    8000593c:	f4c42783          	lw	a5,-180(s0)
    80005940:	2007f793          	andi	a5,a5,512
    80005944:	cbdd                	beqz	a5,800059fa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005946:	4681                	li	a3,0
    80005948:	4601                	li	a2,0
    8000594a:	4589                	li	a1,2
    8000594c:	f5040513          	addi	a0,s0,-176
    80005950:	00000097          	auipc	ra,0x0
    80005954:	974080e7          	jalr	-1676(ra) # 800052c4 <create>
    80005958:	892a                	mv	s2,a0
    if(ip == 0){
    8000595a:	c959                	beqz	a0,800059f0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000595c:	04491703          	lh	a4,68(s2)
    80005960:	478d                	li	a5,3
    80005962:	00f71763          	bne	a4,a5,80005970 <sys_open+0x74>
    80005966:	04695703          	lhu	a4,70(s2)
    8000596a:	47a5                	li	a5,9
    8000596c:	0ce7ec63          	bltu	a5,a4,80005a44 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	d80080e7          	jalr	-640(ra) # 800046f0 <filealloc>
    80005978:	89aa                	mv	s3,a0
    8000597a:	10050263          	beqz	a0,80005a7e <sys_open+0x182>
    8000597e:	00000097          	auipc	ra,0x0
    80005982:	904080e7          	jalr	-1788(ra) # 80005282 <fdalloc>
    80005986:	84aa                	mv	s1,a0
    80005988:	0e054663          	bltz	a0,80005a74 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000598c:	04491703          	lh	a4,68(s2)
    80005990:	478d                	li	a5,3
    80005992:	0cf70463          	beq	a4,a5,80005a5a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005996:	4789                	li	a5,2
    80005998:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000599c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059a0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059a4:	f4c42783          	lw	a5,-180(s0)
    800059a8:	0017c713          	xori	a4,a5,1
    800059ac:	8b05                	andi	a4,a4,1
    800059ae:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059b2:	0037f713          	andi	a4,a5,3
    800059b6:	00e03733          	snez	a4,a4
    800059ba:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059be:	4007f793          	andi	a5,a5,1024
    800059c2:	c791                	beqz	a5,800059ce <sys_open+0xd2>
    800059c4:	04491703          	lh	a4,68(s2)
    800059c8:	4789                	li	a5,2
    800059ca:	08f70f63          	beq	a4,a5,80005a68 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059ce:	854a                	mv	a0,s2
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	010080e7          	jalr	16(ra) # 800039e0 <iunlock>
  end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	982080e7          	jalr	-1662(ra) # 8000435a <end_op>

  return fd;
}
    800059e0:	8526                	mv	a0,s1
    800059e2:	70ea                	ld	ra,184(sp)
    800059e4:	744a                	ld	s0,176(sp)
    800059e6:	74aa                	ld	s1,168(sp)
    800059e8:	790a                	ld	s2,160(sp)
    800059ea:	69ea                	ld	s3,152(sp)
    800059ec:	6129                	addi	sp,sp,192
    800059ee:	8082                	ret
      end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	96a080e7          	jalr	-1686(ra) # 8000435a <end_op>
      return -1;
    800059f8:	b7e5                	j	800059e0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059fa:	f5040513          	addi	a0,s0,-176
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	6d0080e7          	jalr	1744(ra) # 800040ce <namei>
    80005a06:	892a                	mv	s2,a0
    80005a08:	c905                	beqz	a0,80005a38 <sys_open+0x13c>
    ilock(ip);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	f14080e7          	jalr	-236(ra) # 8000391e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a12:	04491703          	lh	a4,68(s2)
    80005a16:	4785                	li	a5,1
    80005a18:	f4f712e3          	bne	a4,a5,8000595c <sys_open+0x60>
    80005a1c:	f4c42783          	lw	a5,-180(s0)
    80005a20:	dba1                	beqz	a5,80005970 <sys_open+0x74>
      iunlockput(ip);
    80005a22:	854a                	mv	a0,s2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	15c080e7          	jalr	348(ra) # 80003b80 <iunlockput>
      end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	92e080e7          	jalr	-1746(ra) # 8000435a <end_op>
      return -1;
    80005a34:	54fd                	li	s1,-1
    80005a36:	b76d                	j	800059e0 <sys_open+0xe4>
      end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	922080e7          	jalr	-1758(ra) # 8000435a <end_op>
      return -1;
    80005a40:	54fd                	li	s1,-1
    80005a42:	bf79                	j	800059e0 <sys_open+0xe4>
    iunlockput(ip);
    80005a44:	854a                	mv	a0,s2
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	13a080e7          	jalr	314(ra) # 80003b80 <iunlockput>
    end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	90c080e7          	jalr	-1780(ra) # 8000435a <end_op>
    return -1;
    80005a56:	54fd                	li	s1,-1
    80005a58:	b761                	j	800059e0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a5a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a5e:	04691783          	lh	a5,70(s2)
    80005a62:	02f99223          	sh	a5,36(s3)
    80005a66:	bf2d                	j	800059a0 <sys_open+0xa4>
    itrunc(ip);
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	fc2080e7          	jalr	-62(ra) # 80003a2c <itrunc>
    80005a72:	bfb1                	j	800059ce <sys_open+0xd2>
      fileclose(f);
    80005a74:	854e                	mv	a0,s3
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	d36080e7          	jalr	-714(ra) # 800047ac <fileclose>
    iunlockput(ip);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	100080e7          	jalr	256(ra) # 80003b80 <iunlockput>
    end_op();
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	8d2080e7          	jalr	-1838(ra) # 8000435a <end_op>
    return -1;
    80005a90:	54fd                	li	s1,-1
    80005a92:	b7b9                	j	800059e0 <sys_open+0xe4>

0000000080005a94 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a94:	7175                	addi	sp,sp,-144
    80005a96:	e506                	sd	ra,136(sp)
    80005a98:	e122                	sd	s0,128(sp)
    80005a9a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	83e080e7          	jalr	-1986(ra) # 800042da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aa4:	08000613          	li	a2,128
    80005aa8:	f7040593          	addi	a1,s0,-144
    80005aac:	4501                	li	a0,0
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	344080e7          	jalr	836(ra) # 80002df2 <argstr>
    80005ab6:	02054963          	bltz	a0,80005ae8 <sys_mkdir+0x54>
    80005aba:	4681                	li	a3,0
    80005abc:	4601                	li	a2,0
    80005abe:	4585                	li	a1,1
    80005ac0:	f7040513          	addi	a0,s0,-144
    80005ac4:	00000097          	auipc	ra,0x0
    80005ac8:	800080e7          	jalr	-2048(ra) # 800052c4 <create>
    80005acc:	cd11                	beqz	a0,80005ae8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	0b2080e7          	jalr	178(ra) # 80003b80 <iunlockput>
  end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	884080e7          	jalr	-1916(ra) # 8000435a <end_op>
  return 0;
    80005ade:	4501                	li	a0,0
}
    80005ae0:	60aa                	ld	ra,136(sp)
    80005ae2:	640a                	ld	s0,128(sp)
    80005ae4:	6149                	addi	sp,sp,144
    80005ae6:	8082                	ret
    end_op();
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	872080e7          	jalr	-1934(ra) # 8000435a <end_op>
    return -1;
    80005af0:	557d                	li	a0,-1
    80005af2:	b7fd                	j	80005ae0 <sys_mkdir+0x4c>

0000000080005af4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005af4:	7135                	addi	sp,sp,-160
    80005af6:	ed06                	sd	ra,152(sp)
    80005af8:	e922                	sd	s0,144(sp)
    80005afa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	7de080e7          	jalr	2014(ra) # 800042da <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b04:	08000613          	li	a2,128
    80005b08:	f7040593          	addi	a1,s0,-144
    80005b0c:	4501                	li	a0,0
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	2e4080e7          	jalr	740(ra) # 80002df2 <argstr>
    80005b16:	04054a63          	bltz	a0,80005b6a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b1a:	f6c40593          	addi	a1,s0,-148
    80005b1e:	4505                	li	a0,1
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	28e080e7          	jalr	654(ra) # 80002dae <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b28:	04054163          	bltz	a0,80005b6a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b2c:	f6840593          	addi	a1,s0,-152
    80005b30:	4509                	li	a0,2
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	27c080e7          	jalr	636(ra) # 80002dae <argint>
     argint(1, &major) < 0 ||
    80005b3a:	02054863          	bltz	a0,80005b6a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b3e:	f6841683          	lh	a3,-152(s0)
    80005b42:	f6c41603          	lh	a2,-148(s0)
    80005b46:	458d                	li	a1,3
    80005b48:	f7040513          	addi	a0,s0,-144
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	778080e7          	jalr	1912(ra) # 800052c4 <create>
     argint(2, &minor) < 0 ||
    80005b54:	c919                	beqz	a0,80005b6a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	02a080e7          	jalr	42(ra) # 80003b80 <iunlockput>
  end_op();
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	7fc080e7          	jalr	2044(ra) # 8000435a <end_op>
  return 0;
    80005b66:	4501                	li	a0,0
    80005b68:	a031                	j	80005b74 <sys_mknod+0x80>
    end_op();
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	7f0080e7          	jalr	2032(ra) # 8000435a <end_op>
    return -1;
    80005b72:	557d                	li	a0,-1
}
    80005b74:	60ea                	ld	ra,152(sp)
    80005b76:	644a                	ld	s0,144(sp)
    80005b78:	610d                	addi	sp,sp,160
    80005b7a:	8082                	ret

0000000080005b7c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b7c:	7135                	addi	sp,sp,-160
    80005b7e:	ed06                	sd	ra,152(sp)
    80005b80:	e922                	sd	s0,144(sp)
    80005b82:	e526                	sd	s1,136(sp)
    80005b84:	e14a                	sd	s2,128(sp)
    80005b86:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	f56080e7          	jalr	-170(ra) # 80001ade <myproc>
    80005b90:	892a                	mv	s2,a0
  
  begin_op();
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	748080e7          	jalr	1864(ra) # 800042da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b9a:	08000613          	li	a2,128
    80005b9e:	f6040593          	addi	a1,s0,-160
    80005ba2:	4501                	li	a0,0
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	24e080e7          	jalr	590(ra) # 80002df2 <argstr>
    80005bac:	04054b63          	bltz	a0,80005c02 <sys_chdir+0x86>
    80005bb0:	f6040513          	addi	a0,s0,-160
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	51a080e7          	jalr	1306(ra) # 800040ce <namei>
    80005bbc:	84aa                	mv	s1,a0
    80005bbe:	c131                	beqz	a0,80005c02 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	d5e080e7          	jalr	-674(ra) # 8000391e <ilock>
  if(ip->type != T_DIR){
    80005bc8:	04449703          	lh	a4,68(s1)
    80005bcc:	4785                	li	a5,1
    80005bce:	04f71063          	bne	a4,a5,80005c0e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	e0c080e7          	jalr	-500(ra) # 800039e0 <iunlock>
  iput(p->cwd);
    80005bdc:	15893503          	ld	a0,344(s2)
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	ef8080e7          	jalr	-264(ra) # 80003ad8 <iput>
  end_op();
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	772080e7          	jalr	1906(ra) # 8000435a <end_op>
  p->cwd = ip;
    80005bf0:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bf4:	4501                	li	a0,0
}
    80005bf6:	60ea                	ld	ra,152(sp)
    80005bf8:	644a                	ld	s0,144(sp)
    80005bfa:	64aa                	ld	s1,136(sp)
    80005bfc:	690a                	ld	s2,128(sp)
    80005bfe:	610d                	addi	sp,sp,160
    80005c00:	8082                	ret
    end_op();
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	758080e7          	jalr	1880(ra) # 8000435a <end_op>
    return -1;
    80005c0a:	557d                	li	a0,-1
    80005c0c:	b7ed                	j	80005bf6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c0e:	8526                	mv	a0,s1
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	f70080e7          	jalr	-144(ra) # 80003b80 <iunlockput>
    end_op();
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	742080e7          	jalr	1858(ra) # 8000435a <end_op>
    return -1;
    80005c20:	557d                	li	a0,-1
    80005c22:	bfd1                	j	80005bf6 <sys_chdir+0x7a>

0000000080005c24 <sys_exec>:

uint64
sys_exec(void)
{
    80005c24:	7145                	addi	sp,sp,-464
    80005c26:	e786                	sd	ra,456(sp)
    80005c28:	e3a2                	sd	s0,448(sp)
    80005c2a:	ff26                	sd	s1,440(sp)
    80005c2c:	fb4a                	sd	s2,432(sp)
    80005c2e:	f74e                	sd	s3,424(sp)
    80005c30:	f352                	sd	s4,416(sp)
    80005c32:	ef56                	sd	s5,408(sp)
    80005c34:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c36:	08000613          	li	a2,128
    80005c3a:	f4040593          	addi	a1,s0,-192
    80005c3e:	4501                	li	a0,0
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	1b2080e7          	jalr	434(ra) # 80002df2 <argstr>
    return -1;
    80005c48:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c4a:	0c054a63          	bltz	a0,80005d1e <sys_exec+0xfa>
    80005c4e:	e3840593          	addi	a1,s0,-456
    80005c52:	4505                	li	a0,1
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	17c080e7          	jalr	380(ra) # 80002dd0 <argaddr>
    80005c5c:	0c054163          	bltz	a0,80005d1e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c60:	10000613          	li	a2,256
    80005c64:	4581                	li	a1,0
    80005c66:	e4040513          	addi	a0,s0,-448
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	090080e7          	jalr	144(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c72:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c76:	89a6                	mv	s3,s1
    80005c78:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c7a:	02000a13          	li	s4,32
    80005c7e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c82:	00391793          	slli	a5,s2,0x3
    80005c86:	e3040593          	addi	a1,s0,-464
    80005c8a:	e3843503          	ld	a0,-456(s0)
    80005c8e:	953e                	add	a0,a0,a5
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	084080e7          	jalr	132(ra) # 80002d14 <fetchaddr>
    80005c98:	02054a63          	bltz	a0,80005ccc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c9c:	e3043783          	ld	a5,-464(s0)
    80005ca0:	c3b9                	beqz	a5,80005ce6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	e6c080e7          	jalr	-404(ra) # 80000b0e <kalloc>
    80005caa:	85aa                	mv	a1,a0
    80005cac:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cb0:	cd11                	beqz	a0,80005ccc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb2:	6605                	lui	a2,0x1
    80005cb4:	e3043503          	ld	a0,-464(s0)
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	0ae080e7          	jalr	174(ra) # 80002d66 <fetchstr>
    80005cc0:	00054663          	bltz	a0,80005ccc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cc4:	0905                	addi	s2,s2,1
    80005cc6:	09a1                	addi	s3,s3,8
    80005cc8:	fb491be3          	bne	s2,s4,80005c7e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ccc:	10048913          	addi	s2,s1,256
    80005cd0:	6088                	ld	a0,0(s1)
    80005cd2:	c529                	beqz	a0,80005d1c <sys_exec+0xf8>
    kfree(argv[i]);
    80005cd4:	ffffb097          	auipc	ra,0xffffb
    80005cd8:	d3e080e7          	jalr	-706(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cdc:	04a1                	addi	s1,s1,8
    80005cde:	ff2499e3          	bne	s1,s2,80005cd0 <sys_exec+0xac>
  return -1;
    80005ce2:	597d                	li	s2,-1
    80005ce4:	a82d                	j	80005d1e <sys_exec+0xfa>
      argv[i] = 0;
    80005ce6:	0a8e                	slli	s5,s5,0x3
    80005ce8:	fc040793          	addi	a5,s0,-64
    80005cec:	9abe                	add	s5,s5,a5
    80005cee:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cf2:	e4040593          	addi	a1,s0,-448
    80005cf6:	f4040513          	addi	a0,s0,-192
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	138080e7          	jalr	312(ra) # 80004e32 <exec>
    80005d02:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d04:	10048993          	addi	s3,s1,256
    80005d08:	6088                	ld	a0,0(s1)
    80005d0a:	c911                	beqz	a0,80005d1e <sys_exec+0xfa>
    kfree(argv[i]);
    80005d0c:	ffffb097          	auipc	ra,0xffffb
    80005d10:	d06080e7          	jalr	-762(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d14:	04a1                	addi	s1,s1,8
    80005d16:	ff3499e3          	bne	s1,s3,80005d08 <sys_exec+0xe4>
    80005d1a:	a011                	j	80005d1e <sys_exec+0xfa>
  return -1;
    80005d1c:	597d                	li	s2,-1
}
    80005d1e:	854a                	mv	a0,s2
    80005d20:	60be                	ld	ra,456(sp)
    80005d22:	641e                	ld	s0,448(sp)
    80005d24:	74fa                	ld	s1,440(sp)
    80005d26:	795a                	ld	s2,432(sp)
    80005d28:	79ba                	ld	s3,424(sp)
    80005d2a:	7a1a                	ld	s4,416(sp)
    80005d2c:	6afa                	ld	s5,408(sp)
    80005d2e:	6179                	addi	sp,sp,464
    80005d30:	8082                	ret

0000000080005d32 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d32:	7139                	addi	sp,sp,-64
    80005d34:	fc06                	sd	ra,56(sp)
    80005d36:	f822                	sd	s0,48(sp)
    80005d38:	f426                	sd	s1,40(sp)
    80005d3a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d3c:	ffffc097          	auipc	ra,0xffffc
    80005d40:	da2080e7          	jalr	-606(ra) # 80001ade <myproc>
    80005d44:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d46:	fd840593          	addi	a1,s0,-40
    80005d4a:	4501                	li	a0,0
    80005d4c:	ffffd097          	auipc	ra,0xffffd
    80005d50:	084080e7          	jalr	132(ra) # 80002dd0 <argaddr>
    return -1;
    80005d54:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d56:	0e054063          	bltz	a0,80005e36 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d5a:	fc840593          	addi	a1,s0,-56
    80005d5e:	fd040513          	addi	a0,s0,-48
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	da0080e7          	jalr	-608(ra) # 80004b02 <pipealloc>
    return -1;
    80005d6a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d6c:	0c054563          	bltz	a0,80005e36 <sys_pipe+0x104>
  fd0 = -1;
    80005d70:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d74:	fd043503          	ld	a0,-48(s0)
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	50a080e7          	jalr	1290(ra) # 80005282 <fdalloc>
    80005d80:	fca42223          	sw	a0,-60(s0)
    80005d84:	08054c63          	bltz	a0,80005e1c <sys_pipe+0xea>
    80005d88:	fc843503          	ld	a0,-56(s0)
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	4f6080e7          	jalr	1270(ra) # 80005282 <fdalloc>
    80005d94:	fca42023          	sw	a0,-64(s0)
    80005d98:	06054863          	bltz	a0,80005e08 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9c:	4691                	li	a3,4
    80005d9e:	fc440613          	addi	a2,s0,-60
    80005da2:	fd843583          	ld	a1,-40(s0)
    80005da6:	68a8                	ld	a0,80(s1)
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	baa080e7          	jalr	-1110(ra) # 80001952 <copyout>
    80005db0:	02054063          	bltz	a0,80005dd0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db4:	4691                	li	a3,4
    80005db6:	fc040613          	addi	a2,s0,-64
    80005dba:	fd843583          	ld	a1,-40(s0)
    80005dbe:	0591                	addi	a1,a1,4
    80005dc0:	68a8                	ld	a0,80(s1)
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	b90080e7          	jalr	-1136(ra) # 80001952 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dcc:	06055563          	bgez	a0,80005e36 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dd0:	fc442783          	lw	a5,-60(s0)
    80005dd4:	07e9                	addi	a5,a5,26
    80005dd6:	078e                	slli	a5,a5,0x3
    80005dd8:	97a6                	add	a5,a5,s1
    80005dda:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005dde:	fc042503          	lw	a0,-64(s0)
    80005de2:	0569                	addi	a0,a0,26
    80005de4:	050e                	slli	a0,a0,0x3
    80005de6:	9526                	add	a0,a0,s1
    80005de8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dec:	fd043503          	ld	a0,-48(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	9bc080e7          	jalr	-1604(ra) # 800047ac <fileclose>
    fileclose(wf);
    80005df8:	fc843503          	ld	a0,-56(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	9b0080e7          	jalr	-1616(ra) # 800047ac <fileclose>
    return -1;
    80005e04:	57fd                	li	a5,-1
    80005e06:	a805                	j	80005e36 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e08:	fc442783          	lw	a5,-60(s0)
    80005e0c:	0007c863          	bltz	a5,80005e1c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e10:	01a78513          	addi	a0,a5,26
    80005e14:	050e                	slli	a0,a0,0x3
    80005e16:	9526                	add	a0,a0,s1
    80005e18:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e1c:	fd043503          	ld	a0,-48(s0)
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	98c080e7          	jalr	-1652(ra) # 800047ac <fileclose>
    fileclose(wf);
    80005e28:	fc843503          	ld	a0,-56(s0)
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	980080e7          	jalr	-1664(ra) # 800047ac <fileclose>
    return -1;
    80005e34:	57fd                	li	a5,-1
}
    80005e36:	853e                	mv	a0,a5
    80005e38:	70e2                	ld	ra,56(sp)
    80005e3a:	7442                	ld	s0,48(sp)
    80005e3c:	74a2                	ld	s1,40(sp)
    80005e3e:	6121                	addi	sp,sp,64
    80005e40:	8082                	ret
	...

0000000080005e50 <kernelvec>:
    80005e50:	7111                	addi	sp,sp,-256
    80005e52:	e006                	sd	ra,0(sp)
    80005e54:	e40a                	sd	sp,8(sp)
    80005e56:	e80e                	sd	gp,16(sp)
    80005e58:	ec12                	sd	tp,24(sp)
    80005e5a:	f016                	sd	t0,32(sp)
    80005e5c:	f41a                	sd	t1,40(sp)
    80005e5e:	f81e                	sd	t2,48(sp)
    80005e60:	fc22                	sd	s0,56(sp)
    80005e62:	e0a6                	sd	s1,64(sp)
    80005e64:	e4aa                	sd	a0,72(sp)
    80005e66:	e8ae                	sd	a1,80(sp)
    80005e68:	ecb2                	sd	a2,88(sp)
    80005e6a:	f0b6                	sd	a3,96(sp)
    80005e6c:	f4ba                	sd	a4,104(sp)
    80005e6e:	f8be                	sd	a5,112(sp)
    80005e70:	fcc2                	sd	a6,120(sp)
    80005e72:	e146                	sd	a7,128(sp)
    80005e74:	e54a                	sd	s2,136(sp)
    80005e76:	e94e                	sd	s3,144(sp)
    80005e78:	ed52                	sd	s4,152(sp)
    80005e7a:	f156                	sd	s5,160(sp)
    80005e7c:	f55a                	sd	s6,168(sp)
    80005e7e:	f95e                	sd	s7,176(sp)
    80005e80:	fd62                	sd	s8,184(sp)
    80005e82:	e1e6                	sd	s9,192(sp)
    80005e84:	e5ea                	sd	s10,200(sp)
    80005e86:	e9ee                	sd	s11,208(sp)
    80005e88:	edf2                	sd	t3,216(sp)
    80005e8a:	f1f6                	sd	t4,224(sp)
    80005e8c:	f5fa                	sd	t5,232(sp)
    80005e8e:	f9fe                	sd	t6,240(sp)
    80005e90:	d51fc0ef          	jal	ra,80002be0 <kerneltrap>
    80005e94:	6082                	ld	ra,0(sp)
    80005e96:	6122                	ld	sp,8(sp)
    80005e98:	61c2                	ld	gp,16(sp)
    80005e9a:	7282                	ld	t0,32(sp)
    80005e9c:	7322                	ld	t1,40(sp)
    80005e9e:	73c2                	ld	t2,48(sp)
    80005ea0:	7462                	ld	s0,56(sp)
    80005ea2:	6486                	ld	s1,64(sp)
    80005ea4:	6526                	ld	a0,72(sp)
    80005ea6:	65c6                	ld	a1,80(sp)
    80005ea8:	6666                	ld	a2,88(sp)
    80005eaa:	7686                	ld	a3,96(sp)
    80005eac:	7726                	ld	a4,104(sp)
    80005eae:	77c6                	ld	a5,112(sp)
    80005eb0:	7866                	ld	a6,120(sp)
    80005eb2:	688a                	ld	a7,128(sp)
    80005eb4:	692a                	ld	s2,136(sp)
    80005eb6:	69ca                	ld	s3,144(sp)
    80005eb8:	6a6a                	ld	s4,152(sp)
    80005eba:	7a8a                	ld	s5,160(sp)
    80005ebc:	7b2a                	ld	s6,168(sp)
    80005ebe:	7bca                	ld	s7,176(sp)
    80005ec0:	7c6a                	ld	s8,184(sp)
    80005ec2:	6c8e                	ld	s9,192(sp)
    80005ec4:	6d2e                	ld	s10,200(sp)
    80005ec6:	6dce                	ld	s11,208(sp)
    80005ec8:	6e6e                	ld	t3,216(sp)
    80005eca:	7e8e                	ld	t4,224(sp)
    80005ecc:	7f2e                	ld	t5,232(sp)
    80005ece:	7fce                	ld	t6,240(sp)
    80005ed0:	6111                	addi	sp,sp,256
    80005ed2:	10200073          	sret
    80005ed6:	00000013          	nop
    80005eda:	00000013          	nop
    80005ede:	0001                	nop

0000000080005ee0 <timervec>:
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	e10c                	sd	a1,0(a0)
    80005ee6:	e510                	sd	a2,8(a0)
    80005ee8:	e914                	sd	a3,16(a0)
    80005eea:	710c                	ld	a1,32(a0)
    80005eec:	7510                	ld	a2,40(a0)
    80005eee:	6194                	ld	a3,0(a1)
    80005ef0:	96b2                	add	a3,a3,a2
    80005ef2:	e194                	sd	a3,0(a1)
    80005ef4:	4589                	li	a1,2
    80005ef6:	14459073          	csrw	sip,a1
    80005efa:	6914                	ld	a3,16(a0)
    80005efc:	6510                	ld	a2,8(a0)
    80005efe:	610c                	ld	a1,0(a0)
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	30200073          	mret
	...

0000000080005f0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f0a:	1141                	addi	sp,sp,-16
    80005f0c:	e422                	sd	s0,8(sp)
    80005f0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f10:	0c0007b7          	lui	a5,0xc000
    80005f14:	4705                	li	a4,1
    80005f16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f18:	c3d8                	sw	a4,4(a5)
}
    80005f1a:	6422                	ld	s0,8(sp)
    80005f1c:	0141                	addi	sp,sp,16
    80005f1e:	8082                	ret

0000000080005f20 <plicinithart>:

void
plicinithart(void)
{
    80005f20:	1141                	addi	sp,sp,-16
    80005f22:	e406                	sd	ra,8(sp)
    80005f24:	e022                	sd	s0,0(sp)
    80005f26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	b8a080e7          	jalr	-1142(ra) # 80001ab2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f30:	0085171b          	slliw	a4,a0,0x8
    80005f34:	0c0027b7          	lui	a5,0xc002
    80005f38:	97ba                	add	a5,a5,a4
    80005f3a:	40200713          	li	a4,1026
    80005f3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f42:	00d5151b          	slliw	a0,a0,0xd
    80005f46:	0c2017b7          	lui	a5,0xc201
    80005f4a:	953e                	add	a0,a0,a5
    80005f4c:	00052023          	sw	zero,0(a0)
}
    80005f50:	60a2                	ld	ra,8(sp)
    80005f52:	6402                	ld	s0,0(sp)
    80005f54:	0141                	addi	sp,sp,16
    80005f56:	8082                	ret

0000000080005f58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f58:	1141                	addi	sp,sp,-16
    80005f5a:	e406                	sd	ra,8(sp)
    80005f5c:	e022                	sd	s0,0(sp)
    80005f5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f60:	ffffc097          	auipc	ra,0xffffc
    80005f64:	b52080e7          	jalr	-1198(ra) # 80001ab2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f68:	00d5179b          	slliw	a5,a0,0xd
    80005f6c:	0c201537          	lui	a0,0xc201
    80005f70:	953e                	add	a0,a0,a5
  return irq;
}
    80005f72:	4148                	lw	a0,4(a0)
    80005f74:	60a2                	ld	ra,8(sp)
    80005f76:	6402                	ld	s0,0(sp)
    80005f78:	0141                	addi	sp,sp,16
    80005f7a:	8082                	ret

0000000080005f7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f7c:	1101                	addi	sp,sp,-32
    80005f7e:	ec06                	sd	ra,24(sp)
    80005f80:	e822                	sd	s0,16(sp)
    80005f82:	e426                	sd	s1,8(sp)
    80005f84:	1000                	addi	s0,sp,32
    80005f86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f88:	ffffc097          	auipc	ra,0xffffc
    80005f8c:	b2a080e7          	jalr	-1238(ra) # 80001ab2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f90:	00d5151b          	slliw	a0,a0,0xd
    80005f94:	0c2017b7          	lui	a5,0xc201
    80005f98:	97aa                	add	a5,a5,a0
    80005f9a:	c3c4                	sw	s1,4(a5)
}
    80005f9c:	60e2                	ld	ra,24(sp)
    80005f9e:	6442                	ld	s0,16(sp)
    80005fa0:	64a2                	ld	s1,8(sp)
    80005fa2:	6105                	addi	sp,sp,32
    80005fa4:	8082                	ret

0000000080005fa6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fa6:	1141                	addi	sp,sp,-16
    80005fa8:	e406                	sd	ra,8(sp)
    80005faa:	e022                	sd	s0,0(sp)
    80005fac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fae:	479d                	li	a5,7
    80005fb0:	04a7cc63          	blt	a5,a0,80006008 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fb4:	0001d797          	auipc	a5,0x1d
    80005fb8:	04c78793          	addi	a5,a5,76 # 80023000 <disk>
    80005fbc:	00a78733          	add	a4,a5,a0
    80005fc0:	6789                	lui	a5,0x2
    80005fc2:	97ba                	add	a5,a5,a4
    80005fc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fc8:	eba1                	bnez	a5,80006018 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fca:	00451713          	slli	a4,a0,0x4
    80005fce:	0001f797          	auipc	a5,0x1f
    80005fd2:	0327b783          	ld	a5,50(a5) # 80025000 <disk+0x2000>
    80005fd6:	97ba                	add	a5,a5,a4
    80005fd8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fdc:	0001d797          	auipc	a5,0x1d
    80005fe0:	02478793          	addi	a5,a5,36 # 80023000 <disk>
    80005fe4:	97aa                	add	a5,a5,a0
    80005fe6:	6509                	lui	a0,0x2
    80005fe8:	953e                	add	a0,a0,a5
    80005fea:	4785                	li	a5,1
    80005fec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ff0:	0001f517          	auipc	a0,0x1f
    80005ff4:	02850513          	addi	a0,a0,40 # 80025018 <disk+0x2018>
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	690080e7          	jalr	1680(ra) # 80002688 <wakeup>
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret
    panic("virtio_disk_intr 1");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	79850513          	addi	a0,a0,1944 # 800087a0 <syscalls+0x328>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	532080e7          	jalr	1330(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80006018:	00002517          	auipc	a0,0x2
    8000601c:	7a050513          	addi	a0,a0,1952 # 800087b8 <syscalls+0x340>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	522080e7          	jalr	1314(ra) # 80000542 <panic>

0000000080006028 <virtio_disk_init>:
{
    80006028:	1101                	addi	sp,sp,-32
    8000602a:	ec06                	sd	ra,24(sp)
    8000602c:	e822                	sd	s0,16(sp)
    8000602e:	e426                	sd	s1,8(sp)
    80006030:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006032:	00002597          	auipc	a1,0x2
    80006036:	79e58593          	addi	a1,a1,1950 # 800087d0 <syscalls+0x358>
    8000603a:	0001f517          	auipc	a0,0x1f
    8000603e:	06e50513          	addi	a0,a0,110 # 800250a8 <disk+0x20a8>
    80006042:	ffffb097          	auipc	ra,0xffffb
    80006046:	b2c080e7          	jalr	-1236(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	4398                	lw	a4,0(a5)
    80006050:	2701                	sext.w	a4,a4
    80006052:	747277b7          	lui	a5,0x74727
    80006056:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000605a:	0ef71163          	bne	a4,a5,8000613c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	43dc                	lw	a5,4(a5)
    80006064:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006066:	4705                	li	a4,1
    80006068:	0ce79a63          	bne	a5,a4,8000613c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000606c:	100017b7          	lui	a5,0x10001
    80006070:	479c                	lw	a5,8(a5)
    80006072:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006074:	4709                	li	a4,2
    80006076:	0ce79363          	bne	a5,a4,8000613c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000607a:	100017b7          	lui	a5,0x10001
    8000607e:	47d8                	lw	a4,12(a5)
    80006080:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006082:	554d47b7          	lui	a5,0x554d4
    80006086:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000608a:	0af71963          	bne	a4,a5,8000613c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	4705                	li	a4,1
    80006094:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006096:	470d                	li	a4,3
    80006098:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000609a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000609c:	c7ffe737          	lui	a4,0xc7ffe
    800060a0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800060a4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060a6:	2701                	sext.w	a4,a4
    800060a8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060aa:	472d                	li	a4,11
    800060ac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	473d                	li	a4,15
    800060b0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060b2:	6705                	lui	a4,0x1
    800060b4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060b6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060ba:	5bdc                	lw	a5,52(a5)
    800060bc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060be:	c7d9                	beqz	a5,8000614c <virtio_disk_init+0x124>
  if(max < NUM)
    800060c0:	471d                	li	a4,7
    800060c2:	08f77d63          	bgeu	a4,a5,8000615c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060c6:	100014b7          	lui	s1,0x10001
    800060ca:	47a1                	li	a5,8
    800060cc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060ce:	6609                	lui	a2,0x2
    800060d0:	4581                	li	a1,0
    800060d2:	0001d517          	auipc	a0,0x1d
    800060d6:	f2e50513          	addi	a0,a0,-210 # 80023000 <disk>
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	c20080e7          	jalr	-992(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060e2:	0001d717          	auipc	a4,0x1d
    800060e6:	f1e70713          	addi	a4,a4,-226 # 80023000 <disk>
    800060ea:	00c75793          	srli	a5,a4,0xc
    800060ee:	2781                	sext.w	a5,a5
    800060f0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060f2:	0001f797          	auipc	a5,0x1f
    800060f6:	f0e78793          	addi	a5,a5,-242 # 80025000 <disk+0x2000>
    800060fa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060fc:	0001d717          	auipc	a4,0x1d
    80006100:	f8470713          	addi	a4,a4,-124 # 80023080 <disk+0x80>
    80006104:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006106:	0001e717          	auipc	a4,0x1e
    8000610a:	efa70713          	addi	a4,a4,-262 # 80024000 <disk+0x1000>
    8000610e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006110:	4705                	li	a4,1
    80006112:	00e78c23          	sb	a4,24(a5)
    80006116:	00e78ca3          	sb	a4,25(a5)
    8000611a:	00e78d23          	sb	a4,26(a5)
    8000611e:	00e78da3          	sb	a4,27(a5)
    80006122:	00e78e23          	sb	a4,28(a5)
    80006126:	00e78ea3          	sb	a4,29(a5)
    8000612a:	00e78f23          	sb	a4,30(a5)
    8000612e:	00e78fa3          	sb	a4,31(a5)
}
    80006132:	60e2                	ld	ra,24(sp)
    80006134:	6442                	ld	s0,16(sp)
    80006136:	64a2                	ld	s1,8(sp)
    80006138:	6105                	addi	sp,sp,32
    8000613a:	8082                	ret
    panic("could not find virtio disk");
    8000613c:	00002517          	auipc	a0,0x2
    80006140:	6a450513          	addi	a0,a0,1700 # 800087e0 <syscalls+0x368>
    80006144:	ffffa097          	auipc	ra,0xffffa
    80006148:	3fe080e7          	jalr	1022(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    8000614c:	00002517          	auipc	a0,0x2
    80006150:	6b450513          	addi	a0,a0,1716 # 80008800 <syscalls+0x388>
    80006154:	ffffa097          	auipc	ra,0xffffa
    80006158:	3ee080e7          	jalr	1006(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	6c450513          	addi	a0,a0,1732 # 80008820 <syscalls+0x3a8>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3de080e7          	jalr	990(ra) # 80000542 <panic>

000000008000616c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000616c:	7175                	addi	sp,sp,-144
    8000616e:	e506                	sd	ra,136(sp)
    80006170:	e122                	sd	s0,128(sp)
    80006172:	fca6                	sd	s1,120(sp)
    80006174:	f8ca                	sd	s2,112(sp)
    80006176:	f4ce                	sd	s3,104(sp)
    80006178:	f0d2                	sd	s4,96(sp)
    8000617a:	ecd6                	sd	s5,88(sp)
    8000617c:	e8da                	sd	s6,80(sp)
    8000617e:	e4de                	sd	s7,72(sp)
    80006180:	e0e2                	sd	s8,64(sp)
    80006182:	fc66                	sd	s9,56(sp)
    80006184:	f86a                	sd	s10,48(sp)
    80006186:	f46e                	sd	s11,40(sp)
    80006188:	0900                	addi	s0,sp,144
    8000618a:	8aaa                	mv	s5,a0
    8000618c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000618e:	00c52c83          	lw	s9,12(a0)
    80006192:	001c9c9b          	slliw	s9,s9,0x1
    80006196:	1c82                	slli	s9,s9,0x20
    80006198:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000619c:	0001f517          	auipc	a0,0x1f
    800061a0:	f0c50513          	addi	a0,a0,-244 # 800250a8 <disk+0x20a8>
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	a5a080e7          	jalr	-1446(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    800061ac:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061ae:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061b0:	0001dc17          	auipc	s8,0x1d
    800061b4:	e50c0c13          	addi	s8,s8,-432 # 80023000 <disk>
    800061b8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061ba:	4b0d                	li	s6,3
    800061bc:	a0ad                	j	80006226 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061be:	00fc0733          	add	a4,s8,a5
    800061c2:	975e                	add	a4,a4,s7
    800061c4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061c8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061ca:	0207c563          	bltz	a5,800061f4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061ce:	2905                	addiw	s2,s2,1
    800061d0:	0611                	addi	a2,a2,4
    800061d2:	19690d63          	beq	s2,s6,8000636c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061d6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061d8:	0001f717          	auipc	a4,0x1f
    800061dc:	e4070713          	addi	a4,a4,-448 # 80025018 <disk+0x2018>
    800061e0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061e2:	00074683          	lbu	a3,0(a4)
    800061e6:	fee1                	bnez	a3,800061be <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061e8:	2785                	addiw	a5,a5,1
    800061ea:	0705                	addi	a4,a4,1
    800061ec:	fe979be3          	bne	a5,s1,800061e2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061f0:	57fd                	li	a5,-1
    800061f2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061f4:	01205d63          	blez	s2,8000620e <virtio_disk_rw+0xa2>
    800061f8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061fa:	000a2503          	lw	a0,0(s4)
    800061fe:	00000097          	auipc	ra,0x0
    80006202:	da8080e7          	jalr	-600(ra) # 80005fa6 <free_desc>
      for(int j = 0; j < i; j++)
    80006206:	2d85                	addiw	s11,s11,1
    80006208:	0a11                	addi	s4,s4,4
    8000620a:	ffb918e3          	bne	s2,s11,800061fa <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000620e:	0001f597          	auipc	a1,0x1f
    80006212:	e9a58593          	addi	a1,a1,-358 # 800250a8 <disk+0x20a8>
    80006216:	0001f517          	auipc	a0,0x1f
    8000621a:	e0250513          	addi	a0,a0,-510 # 80025018 <disk+0x2018>
    8000621e:	ffffc097          	auipc	ra,0xffffc
    80006222:	2ea080e7          	jalr	746(ra) # 80002508 <sleep>
  for(int i = 0; i < 3; i++){
    80006226:	f8040a13          	addi	s4,s0,-128
{
    8000622a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000622c:	894e                	mv	s2,s3
    8000622e:	b765                	j	800061d6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006230:	0001f717          	auipc	a4,0x1f
    80006234:	dd073703          	ld	a4,-560(a4) # 80025000 <disk+0x2000>
    80006238:	973e                	add	a4,a4,a5
    8000623a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000623e:	0001d517          	auipc	a0,0x1d
    80006242:	dc250513          	addi	a0,a0,-574 # 80023000 <disk>
    80006246:	0001f717          	auipc	a4,0x1f
    8000624a:	dba70713          	addi	a4,a4,-582 # 80025000 <disk+0x2000>
    8000624e:	6314                	ld	a3,0(a4)
    80006250:	96be                	add	a3,a3,a5
    80006252:	00c6d603          	lhu	a2,12(a3)
    80006256:	00166613          	ori	a2,a2,1
    8000625a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000625e:	f8842683          	lw	a3,-120(s0)
    80006262:	6310                	ld	a2,0(a4)
    80006264:	97b2                	add	a5,a5,a2
    80006266:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000626a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000626e:	0612                	slli	a2,a2,0x4
    80006270:	962a                	add	a2,a2,a0
    80006272:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006276:	00469793          	slli	a5,a3,0x4
    8000627a:	630c                	ld	a1,0(a4)
    8000627c:	95be                	add	a1,a1,a5
    8000627e:	6689                	lui	a3,0x2
    80006280:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006284:	96ca                	add	a3,a3,s2
    80006286:	96aa                	add	a3,a3,a0
    80006288:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000628a:	6314                	ld	a3,0(a4)
    8000628c:	96be                	add	a3,a3,a5
    8000628e:	4585                	li	a1,1
    80006290:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006292:	6314                	ld	a3,0(a4)
    80006294:	96be                	add	a3,a3,a5
    80006296:	4509                	li	a0,2
    80006298:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000629c:	6314                	ld	a3,0(a4)
    8000629e:	97b6                	add	a5,a5,a3
    800062a0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062a4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062a8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062ac:	6714                	ld	a3,8(a4)
    800062ae:	0026d783          	lhu	a5,2(a3)
    800062b2:	8b9d                	andi	a5,a5,7
    800062b4:	0789                	addi	a5,a5,2
    800062b6:	0786                	slli	a5,a5,0x1
    800062b8:	97b6                	add	a5,a5,a3
    800062ba:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062be:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062c2:	6718                	ld	a4,8(a4)
    800062c4:	00275783          	lhu	a5,2(a4)
    800062c8:	2785                	addiw	a5,a5,1
    800062ca:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ce:	100017b7          	lui	a5,0x10001
    800062d2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062d6:	004aa783          	lw	a5,4(s5)
    800062da:	02b79163          	bne	a5,a1,800062fc <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062de:	0001f917          	auipc	s2,0x1f
    800062e2:	dca90913          	addi	s2,s2,-566 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062e8:	85ca                	mv	a1,s2
    800062ea:	8556                	mv	a0,s5
    800062ec:	ffffc097          	auipc	ra,0xffffc
    800062f0:	21c080e7          	jalr	540(ra) # 80002508 <sleep>
  while(b->disk == 1) {
    800062f4:	004aa783          	lw	a5,4(s5)
    800062f8:	fe9788e3          	beq	a5,s1,800062e8 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062fc:	f8042483          	lw	s1,-128(s0)
    80006300:	20048793          	addi	a5,s1,512
    80006304:	00479713          	slli	a4,a5,0x4
    80006308:	0001d797          	auipc	a5,0x1d
    8000630c:	cf878793          	addi	a5,a5,-776 # 80023000 <disk>
    80006310:	97ba                	add	a5,a5,a4
    80006312:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006316:	0001f917          	auipc	s2,0x1f
    8000631a:	cea90913          	addi	s2,s2,-790 # 80025000 <disk+0x2000>
    8000631e:	a019                	j	80006324 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006320:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006324:	8526                	mv	a0,s1
    80006326:	00000097          	auipc	ra,0x0
    8000632a:	c80080e7          	jalr	-896(ra) # 80005fa6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000632e:	0492                	slli	s1,s1,0x4
    80006330:	00093783          	ld	a5,0(s2)
    80006334:	94be                	add	s1,s1,a5
    80006336:	00c4d783          	lhu	a5,12(s1)
    8000633a:	8b85                	andi	a5,a5,1
    8000633c:	f3f5                	bnez	a5,80006320 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000633e:	0001f517          	auipc	a0,0x1f
    80006342:	d6a50513          	addi	a0,a0,-662 # 800250a8 <disk+0x20a8>
    80006346:	ffffb097          	auipc	ra,0xffffb
    8000634a:	96c080e7          	jalr	-1684(ra) # 80000cb2 <release>
}
    8000634e:	60aa                	ld	ra,136(sp)
    80006350:	640a                	ld	s0,128(sp)
    80006352:	74e6                	ld	s1,120(sp)
    80006354:	7946                	ld	s2,112(sp)
    80006356:	79a6                	ld	s3,104(sp)
    80006358:	7a06                	ld	s4,96(sp)
    8000635a:	6ae6                	ld	s5,88(sp)
    8000635c:	6b46                	ld	s6,80(sp)
    8000635e:	6ba6                	ld	s7,72(sp)
    80006360:	6c06                	ld	s8,64(sp)
    80006362:	7ce2                	ld	s9,56(sp)
    80006364:	7d42                	ld	s10,48(sp)
    80006366:	7da2                	ld	s11,40(sp)
    80006368:	6149                	addi	sp,sp,144
    8000636a:	8082                	ret
  if(write)
    8000636c:	01a037b3          	snez	a5,s10
    80006370:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006374:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006378:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000637c:	f8042483          	lw	s1,-128(s0)
    80006380:	00449913          	slli	s2,s1,0x4
    80006384:	0001f997          	auipc	s3,0x1f
    80006388:	c7c98993          	addi	s3,s3,-900 # 80025000 <disk+0x2000>
    8000638c:	0009ba03          	ld	s4,0(s3)
    80006390:	9a4a                	add	s4,s4,s2
    80006392:	f7040513          	addi	a0,s0,-144
    80006396:	ffffb097          	auipc	ra,0xffffb
    8000639a:	e34080e7          	jalr	-460(ra) # 800011ca <kvmpa>
    8000639e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063a2:	0009b783          	ld	a5,0(s3)
    800063a6:	97ca                	add	a5,a5,s2
    800063a8:	4741                	li	a4,16
    800063aa:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063ac:	0009b783          	ld	a5,0(s3)
    800063b0:	97ca                	add	a5,a5,s2
    800063b2:	4705                	li	a4,1
    800063b4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063b8:	f8442783          	lw	a5,-124(s0)
    800063bc:	0009b703          	ld	a4,0(s3)
    800063c0:	974a                	add	a4,a4,s2
    800063c2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063c6:	0792                	slli	a5,a5,0x4
    800063c8:	0009b703          	ld	a4,0(s3)
    800063cc:	973e                	add	a4,a4,a5
    800063ce:	058a8693          	addi	a3,s5,88
    800063d2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063d4:	0009b703          	ld	a4,0(s3)
    800063d8:	973e                	add	a4,a4,a5
    800063da:	40000693          	li	a3,1024
    800063de:	c714                	sw	a3,8(a4)
  if(write)
    800063e0:	e40d18e3          	bnez	s10,80006230 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063e4:	0001f717          	auipc	a4,0x1f
    800063e8:	c1c73703          	ld	a4,-996(a4) # 80025000 <disk+0x2000>
    800063ec:	973e                	add	a4,a4,a5
    800063ee:	4689                	li	a3,2
    800063f0:	00d71623          	sh	a3,12(a4)
    800063f4:	b5a9                	j	8000623e <virtio_disk_rw+0xd2>

00000000800063f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063f6:	1101                	addi	sp,sp,-32
    800063f8:	ec06                	sd	ra,24(sp)
    800063fa:	e822                	sd	s0,16(sp)
    800063fc:	e426                	sd	s1,8(sp)
    800063fe:	e04a                	sd	s2,0(sp)
    80006400:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006402:	0001f517          	auipc	a0,0x1f
    80006406:	ca650513          	addi	a0,a0,-858 # 800250a8 <disk+0x20a8>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	7f4080e7          	jalr	2036(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006412:	0001f717          	auipc	a4,0x1f
    80006416:	bee70713          	addi	a4,a4,-1042 # 80025000 <disk+0x2000>
    8000641a:	02075783          	lhu	a5,32(a4)
    8000641e:	6b18                	ld	a4,16(a4)
    80006420:	00275683          	lhu	a3,2(a4)
    80006424:	8ebd                	xor	a3,a3,a5
    80006426:	8a9d                	andi	a3,a3,7
    80006428:	cab9                	beqz	a3,8000647e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000642a:	0001d917          	auipc	s2,0x1d
    8000642e:	bd690913          	addi	s2,s2,-1066 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006432:	0001f497          	auipc	s1,0x1f
    80006436:	bce48493          	addi	s1,s1,-1074 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000643a:	078e                	slli	a5,a5,0x3
    8000643c:	97ba                	add	a5,a5,a4
    8000643e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006440:	20078713          	addi	a4,a5,512
    80006444:	0712                	slli	a4,a4,0x4
    80006446:	974a                	add	a4,a4,s2
    80006448:	03074703          	lbu	a4,48(a4)
    8000644c:	ef21                	bnez	a4,800064a4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000644e:	20078793          	addi	a5,a5,512
    80006452:	0792                	slli	a5,a5,0x4
    80006454:	97ca                	add	a5,a5,s2
    80006456:	7798                	ld	a4,40(a5)
    80006458:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000645c:	7788                	ld	a0,40(a5)
    8000645e:	ffffc097          	auipc	ra,0xffffc
    80006462:	22a080e7          	jalr	554(ra) # 80002688 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006466:	0204d783          	lhu	a5,32(s1)
    8000646a:	2785                	addiw	a5,a5,1
    8000646c:	8b9d                	andi	a5,a5,7
    8000646e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006472:	6898                	ld	a4,16(s1)
    80006474:	00275683          	lhu	a3,2(a4)
    80006478:	8a9d                	andi	a3,a3,7
    8000647a:	fcf690e3          	bne	a3,a5,8000643a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000647e:	10001737          	lui	a4,0x10001
    80006482:	533c                	lw	a5,96(a4)
    80006484:	8b8d                	andi	a5,a5,3
    80006486:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006488:	0001f517          	auipc	a0,0x1f
    8000648c:	c2050513          	addi	a0,a0,-992 # 800250a8 <disk+0x20a8>
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	822080e7          	jalr	-2014(ra) # 80000cb2 <release>
}
    80006498:	60e2                	ld	ra,24(sp)
    8000649a:	6442                	ld	s0,16(sp)
    8000649c:	64a2                	ld	s1,8(sp)
    8000649e:	6902                	ld	s2,0(sp)
    800064a0:	6105                	addi	sp,sp,32
    800064a2:	8082                	ret
      panic("virtio_disk_intr status");
    800064a4:	00002517          	auipc	a0,0x2
    800064a8:	39c50513          	addi	a0,a0,924 # 80008840 <syscalls+0x3c8>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	096080e7          	jalr	150(ra) # 80000542 <panic>

00000000800064b4 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800064b4:	7179                	addi	sp,sp,-48
    800064b6:	f406                	sd	ra,40(sp)
    800064b8:	f022                	sd	s0,32(sp)
    800064ba:	ec26                	sd	s1,24(sp)
    800064bc:	e84a                	sd	s2,16(sp)
    800064be:	e44e                	sd	s3,8(sp)
    800064c0:	e052                	sd	s4,0(sp)
    800064c2:	1800                	addi	s0,sp,48
    800064c4:	892a                	mv	s2,a0
    800064c6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800064c8:	00003a17          	auipc	s4,0x3
    800064cc:	b60a0a13          	addi	s4,s4,-1184 # 80009028 <stats>
    800064d0:	000a2683          	lw	a3,0(s4)
    800064d4:	00002617          	auipc	a2,0x2
    800064d8:	38460613          	addi	a2,a2,900 # 80008858 <syscalls+0x3e0>
    800064dc:	00000097          	auipc	ra,0x0
    800064e0:	2c2080e7          	jalr	706(ra) # 8000679e <snprintf>
    800064e4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800064e6:	004a2683          	lw	a3,4(s4)
    800064ea:	00002617          	auipc	a2,0x2
    800064ee:	37e60613          	addi	a2,a2,894 # 80008868 <syscalls+0x3f0>
    800064f2:	85ce                	mv	a1,s3
    800064f4:	954a                	add	a0,a0,s2
    800064f6:	00000097          	auipc	ra,0x0
    800064fa:	2a8080e7          	jalr	680(ra) # 8000679e <snprintf>
  return n;
}
    800064fe:	9d25                	addw	a0,a0,s1
    80006500:	70a2                	ld	ra,40(sp)
    80006502:	7402                	ld	s0,32(sp)
    80006504:	64e2                	ld	s1,24(sp)
    80006506:	6942                	ld	s2,16(sp)
    80006508:	69a2                	ld	s3,8(sp)
    8000650a:	6a02                	ld	s4,0(sp)
    8000650c:	6145                	addi	sp,sp,48
    8000650e:	8082                	ret

0000000080006510 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006510:	7179                	addi	sp,sp,-48
    80006512:	f406                	sd	ra,40(sp)
    80006514:	f022                	sd	s0,32(sp)
    80006516:	ec26                	sd	s1,24(sp)
    80006518:	e84a                	sd	s2,16(sp)
    8000651a:	e44e                	sd	s3,8(sp)
    8000651c:	1800                	addi	s0,sp,48
    8000651e:	89ae                	mv	s3,a1
    80006520:	84b2                	mv	s1,a2
    80006522:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006524:	ffffb097          	auipc	ra,0xffffb
    80006528:	5ba080e7          	jalr	1466(ra) # 80001ade <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000652c:	653c                	ld	a5,72(a0)
    8000652e:	02f4ff63          	bgeu	s1,a5,8000656c <copyin_new+0x5c>
    80006532:	01248733          	add	a4,s1,s2
    80006536:	02f77d63          	bgeu	a4,a5,80006570 <copyin_new+0x60>
    8000653a:	02976d63          	bltu	a4,s1,80006574 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000653e:	0009061b          	sext.w	a2,s2
    80006542:	85a6                	mv	a1,s1
    80006544:	854e                	mv	a0,s3
    80006546:	ffffb097          	auipc	ra,0xffffb
    8000654a:	810080e7          	jalr	-2032(ra) # 80000d56 <memmove>
  stats.ncopyin++;   // XXX lock
    8000654e:	00003717          	auipc	a4,0x3
    80006552:	ada70713          	addi	a4,a4,-1318 # 80009028 <stats>
    80006556:	431c                	lw	a5,0(a4)
    80006558:	2785                	addiw	a5,a5,1
    8000655a:	c31c                	sw	a5,0(a4)
  return 0;
    8000655c:	4501                	li	a0,0
}
    8000655e:	70a2                	ld	ra,40(sp)
    80006560:	7402                	ld	s0,32(sp)
    80006562:	64e2                	ld	s1,24(sp)
    80006564:	6942                	ld	s2,16(sp)
    80006566:	69a2                	ld	s3,8(sp)
    80006568:	6145                	addi	sp,sp,48
    8000656a:	8082                	ret
    return -1;
    8000656c:	557d                	li	a0,-1
    8000656e:	bfc5                	j	8000655e <copyin_new+0x4e>
    80006570:	557d                	li	a0,-1
    80006572:	b7f5                	j	8000655e <copyin_new+0x4e>
    80006574:	557d                	li	a0,-1
    80006576:	b7e5                	j	8000655e <copyin_new+0x4e>

0000000080006578 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006578:	7179                	addi	sp,sp,-48
    8000657a:	f406                	sd	ra,40(sp)
    8000657c:	f022                	sd	s0,32(sp)
    8000657e:	ec26                	sd	s1,24(sp)
    80006580:	e84a                	sd	s2,16(sp)
    80006582:	e44e                	sd	s3,8(sp)
    80006584:	1800                	addi	s0,sp,48
    80006586:	89ae                	mv	s3,a1
    80006588:	8932                	mv	s2,a2
    8000658a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000658c:	ffffb097          	auipc	ra,0xffffb
    80006590:	552080e7          	jalr	1362(ra) # 80001ade <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006594:	00003717          	auipc	a4,0x3
    80006598:	a9470713          	addi	a4,a4,-1388 # 80009028 <stats>
    8000659c:	435c                	lw	a5,4(a4)
    8000659e:	2785                	addiw	a5,a5,1
    800065a0:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800065a2:	cc85                	beqz	s1,800065da <copyinstr_new+0x62>
    800065a4:	00990833          	add	a6,s2,s1
    800065a8:	87ca                	mv	a5,s2
    800065aa:	6538                	ld	a4,72(a0)
    800065ac:	00e7ff63          	bgeu	a5,a4,800065ca <copyinstr_new+0x52>
    dst[i] = s[i];
    800065b0:	0007c683          	lbu	a3,0(a5)
    800065b4:	41278733          	sub	a4,a5,s2
    800065b8:	974e                	add	a4,a4,s3
    800065ba:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    800065be:	c285                	beqz	a3,800065de <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800065c0:	0785                	addi	a5,a5,1
    800065c2:	ff0794e3          	bne	a5,a6,800065aa <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800065c6:	557d                	li	a0,-1
    800065c8:	a011                	j	800065cc <copyinstr_new+0x54>
    800065ca:	557d                	li	a0,-1
}
    800065cc:	70a2                	ld	ra,40(sp)
    800065ce:	7402                	ld	s0,32(sp)
    800065d0:	64e2                	ld	s1,24(sp)
    800065d2:	6942                	ld	s2,16(sp)
    800065d4:	69a2                	ld	s3,8(sp)
    800065d6:	6145                	addi	sp,sp,48
    800065d8:	8082                	ret
  return -1;
    800065da:	557d                	li	a0,-1
    800065dc:	bfc5                	j	800065cc <copyinstr_new+0x54>
      return 0;
    800065de:	4501                	li	a0,0
    800065e0:	b7f5                	j	800065cc <copyinstr_new+0x54>

00000000800065e2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800065e2:	1141                	addi	sp,sp,-16
    800065e4:	e422                	sd	s0,8(sp)
    800065e6:	0800                	addi	s0,sp,16
  return -1;
}
    800065e8:	557d                	li	a0,-1
    800065ea:	6422                	ld	s0,8(sp)
    800065ec:	0141                	addi	sp,sp,16
    800065ee:	8082                	ret

00000000800065f0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800065f0:	7179                	addi	sp,sp,-48
    800065f2:	f406                	sd	ra,40(sp)
    800065f4:	f022                	sd	s0,32(sp)
    800065f6:	ec26                	sd	s1,24(sp)
    800065f8:	e84a                	sd	s2,16(sp)
    800065fa:	e44e                	sd	s3,8(sp)
    800065fc:	e052                	sd	s4,0(sp)
    800065fe:	1800                	addi	s0,sp,48
    80006600:	892a                	mv	s2,a0
    80006602:	89ae                	mv	s3,a1
    80006604:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006606:	00020517          	auipc	a0,0x20
    8000660a:	9fa50513          	addi	a0,a0,-1542 # 80026000 <stats>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	5f0080e7          	jalr	1520(ra) # 80000bfe <acquire>

  if(stats.sz == 0) {
    80006616:	00021797          	auipc	a5,0x21
    8000661a:	a027a783          	lw	a5,-1534(a5) # 80027018 <stats+0x1018>
    8000661e:	cbb5                	beqz	a5,80006692 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006620:	00021797          	auipc	a5,0x21
    80006624:	9e078793          	addi	a5,a5,-1568 # 80027000 <stats+0x1000>
    80006628:	4fd8                	lw	a4,28(a5)
    8000662a:	4f9c                	lw	a5,24(a5)
    8000662c:	9f99                	subw	a5,a5,a4
    8000662e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006632:	06d05e63          	blez	a3,800066ae <statsread+0xbe>
    if(m > n)
    80006636:	8a3e                	mv	s4,a5
    80006638:	00d4d363          	bge	s1,a3,8000663e <statsread+0x4e>
    8000663c:	8a26                	mv	s4,s1
    8000663e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006642:	86a6                	mv	a3,s1
    80006644:	00020617          	auipc	a2,0x20
    80006648:	9d460613          	addi	a2,a2,-1580 # 80026018 <stats+0x18>
    8000664c:	963a                	add	a2,a2,a4
    8000664e:	85ce                	mv	a1,s3
    80006650:	854a                	mv	a0,s2
    80006652:	ffffc097          	auipc	ra,0xffffc
    80006656:	110080e7          	jalr	272(ra) # 80002762 <either_copyout>
    8000665a:	57fd                	li	a5,-1
    8000665c:	00f50a63          	beq	a0,a5,80006670 <statsread+0x80>
      stats.off += m;
    80006660:	00021717          	auipc	a4,0x21
    80006664:	9a070713          	addi	a4,a4,-1632 # 80027000 <stats+0x1000>
    80006668:	4f5c                	lw	a5,28(a4)
    8000666a:	014787bb          	addw	a5,a5,s4
    8000666e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006670:	00020517          	auipc	a0,0x20
    80006674:	99050513          	addi	a0,a0,-1648 # 80026000 <stats>
    80006678:	ffffa097          	auipc	ra,0xffffa
    8000667c:	63a080e7          	jalr	1594(ra) # 80000cb2 <release>
  return m;
}
    80006680:	8526                	mv	a0,s1
    80006682:	70a2                	ld	ra,40(sp)
    80006684:	7402                	ld	s0,32(sp)
    80006686:	64e2                	ld	s1,24(sp)
    80006688:	6942                	ld	s2,16(sp)
    8000668a:	69a2                	ld	s3,8(sp)
    8000668c:	6a02                	ld	s4,0(sp)
    8000668e:	6145                	addi	sp,sp,48
    80006690:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006692:	6585                	lui	a1,0x1
    80006694:	00020517          	auipc	a0,0x20
    80006698:	98450513          	addi	a0,a0,-1660 # 80026018 <stats+0x18>
    8000669c:	00000097          	auipc	ra,0x0
    800066a0:	e18080e7          	jalr	-488(ra) # 800064b4 <statscopyin>
    800066a4:	00021797          	auipc	a5,0x21
    800066a8:	96a7aa23          	sw	a0,-1676(a5) # 80027018 <stats+0x1018>
    800066ac:	bf95                	j	80006620 <statsread+0x30>
    stats.sz = 0;
    800066ae:	00021797          	auipc	a5,0x21
    800066b2:	95278793          	addi	a5,a5,-1710 # 80027000 <stats+0x1000>
    800066b6:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800066ba:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800066be:	54fd                	li	s1,-1
    800066c0:	bf45                	j	80006670 <statsread+0x80>

00000000800066c2 <statsinit>:

void
statsinit(void)
{
    800066c2:	1141                	addi	sp,sp,-16
    800066c4:	e406                	sd	ra,8(sp)
    800066c6:	e022                	sd	s0,0(sp)
    800066c8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800066ca:	00002597          	auipc	a1,0x2
    800066ce:	1ae58593          	addi	a1,a1,430 # 80008878 <syscalls+0x400>
    800066d2:	00020517          	auipc	a0,0x20
    800066d6:	92e50513          	addi	a0,a0,-1746 # 80026000 <stats>
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	494080e7          	jalr	1172(ra) # 80000b6e <initlock>

  devsw[STATS].read = statsread;
    800066e2:	0001b797          	auipc	a5,0x1b
    800066e6:	4ce78793          	addi	a5,a5,1230 # 80021bb0 <devsw>
    800066ea:	00000717          	auipc	a4,0x0
    800066ee:	f0670713          	addi	a4,a4,-250 # 800065f0 <statsread>
    800066f2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800066f4:	00000717          	auipc	a4,0x0
    800066f8:	eee70713          	addi	a4,a4,-274 # 800065e2 <statswrite>
    800066fc:	f798                	sd	a4,40(a5)
}
    800066fe:	60a2                	ld	ra,8(sp)
    80006700:	6402                	ld	s0,0(sp)
    80006702:	0141                	addi	sp,sp,16
    80006704:	8082                	ret

0000000080006706 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006706:	1101                	addi	sp,sp,-32
    80006708:	ec22                	sd	s0,24(sp)
    8000670a:	1000                	addi	s0,sp,32
    8000670c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000670e:	c299                	beqz	a3,80006714 <sprintint+0xe>
    80006710:	0805c163          	bltz	a1,80006792 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006714:	2581                	sext.w	a1,a1
    80006716:	4301                	li	t1,0

  i = 0;
    80006718:	fe040713          	addi	a4,s0,-32
    8000671c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000671e:	2601                	sext.w	a2,a2
    80006720:	00002697          	auipc	a3,0x2
    80006724:	16068693          	addi	a3,a3,352 # 80008880 <digits>
    80006728:	88aa                	mv	a7,a0
    8000672a:	2505                	addiw	a0,a0,1
    8000672c:	02c5f7bb          	remuw	a5,a1,a2
    80006730:	1782                	slli	a5,a5,0x20
    80006732:	9381                	srli	a5,a5,0x20
    80006734:	97b6                	add	a5,a5,a3
    80006736:	0007c783          	lbu	a5,0(a5)
    8000673a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000673e:	0005879b          	sext.w	a5,a1
    80006742:	02c5d5bb          	divuw	a1,a1,a2
    80006746:	0705                	addi	a4,a4,1
    80006748:	fec7f0e3          	bgeu	a5,a2,80006728 <sprintint+0x22>

  if(sign)
    8000674c:	00030b63          	beqz	t1,80006762 <sprintint+0x5c>
    buf[i++] = '-';
    80006750:	ff040793          	addi	a5,s0,-16
    80006754:	97aa                	add	a5,a5,a0
    80006756:	02d00713          	li	a4,45
    8000675a:	fee78823          	sb	a4,-16(a5)
    8000675e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006762:	02a05c63          	blez	a0,8000679a <sprintint+0x94>
    80006766:	fe040793          	addi	a5,s0,-32
    8000676a:	00a78733          	add	a4,a5,a0
    8000676e:	87c2                	mv	a5,a6
    80006770:	0805                	addi	a6,a6,1
    80006772:	fff5061b          	addiw	a2,a0,-1
    80006776:	1602                	slli	a2,a2,0x20
    80006778:	9201                	srli	a2,a2,0x20
    8000677a:	9642                	add	a2,a2,a6
  *s = c;
    8000677c:	fff74683          	lbu	a3,-1(a4)
    80006780:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006784:	177d                	addi	a4,a4,-1
    80006786:	0785                	addi	a5,a5,1
    80006788:	fec79ae3          	bne	a5,a2,8000677c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000678c:	6462                	ld	s0,24(sp)
    8000678e:	6105                	addi	sp,sp,32
    80006790:	8082                	ret
    x = -xx;
    80006792:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006796:	4305                	li	t1,1
    x = -xx;
    80006798:	b741                	j	80006718 <sprintint+0x12>
  while(--i >= 0)
    8000679a:	4501                	li	a0,0
    8000679c:	bfc5                	j	8000678c <sprintint+0x86>

000000008000679e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000679e:	7135                	addi	sp,sp,-160
    800067a0:	f486                	sd	ra,104(sp)
    800067a2:	f0a2                	sd	s0,96(sp)
    800067a4:	eca6                	sd	s1,88(sp)
    800067a6:	e8ca                	sd	s2,80(sp)
    800067a8:	e4ce                	sd	s3,72(sp)
    800067aa:	e0d2                	sd	s4,64(sp)
    800067ac:	fc56                	sd	s5,56(sp)
    800067ae:	f85a                	sd	s6,48(sp)
    800067b0:	f45e                	sd	s7,40(sp)
    800067b2:	f062                	sd	s8,32(sp)
    800067b4:	ec66                	sd	s9,24(sp)
    800067b6:	e86a                	sd	s10,16(sp)
    800067b8:	1880                	addi	s0,sp,112
    800067ba:	e414                	sd	a3,8(s0)
    800067bc:	e818                	sd	a4,16(s0)
    800067be:	ec1c                	sd	a5,24(s0)
    800067c0:	03043023          	sd	a6,32(s0)
    800067c4:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800067c8:	c61d                	beqz	a2,800067f6 <snprintf+0x58>
    800067ca:	8baa                	mv	s7,a0
    800067cc:	89ae                	mv	s3,a1
    800067ce:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800067d0:	00840793          	addi	a5,s0,8
    800067d4:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    800067d8:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067da:	4901                	li	s2,0
    800067dc:	02b05563          	blez	a1,80006806 <snprintf+0x68>
    if(c != '%'){
    800067e0:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800067e4:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800067e8:	02800d13          	li	s10,40
    switch(c){
    800067ec:	07800c93          	li	s9,120
    800067f0:	06400c13          	li	s8,100
    800067f4:	a01d                	j	8000681a <snprintf+0x7c>
    panic("null fmt");
    800067f6:	00002517          	auipc	a0,0x2
    800067fa:	83250513          	addi	a0,a0,-1998 # 80008028 <etext+0x28>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	d44080e7          	jalr	-700(ra) # 80000542 <panic>
  int off = 0;
    80006806:	4481                	li	s1,0
    80006808:	a86d                	j	800068c2 <snprintf+0x124>
  *s = c;
    8000680a:	009b8733          	add	a4,s7,s1
    8000680e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006812:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006814:	2905                	addiw	s2,s2,1
    80006816:	0b34d663          	bge	s1,s3,800068c2 <snprintf+0x124>
    8000681a:	012a07b3          	add	a5,s4,s2
    8000681e:	0007c783          	lbu	a5,0(a5)
    80006822:	0007871b          	sext.w	a4,a5
    80006826:	cfd1                	beqz	a5,800068c2 <snprintf+0x124>
    if(c != '%'){
    80006828:	ff5711e3          	bne	a4,s5,8000680a <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    8000682c:	2905                	addiw	s2,s2,1
    8000682e:	012a07b3          	add	a5,s4,s2
    80006832:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006836:	c7d1                	beqz	a5,800068c2 <snprintf+0x124>
    switch(c){
    80006838:	05678c63          	beq	a5,s6,80006890 <snprintf+0xf2>
    8000683c:	02fb6763          	bltu	s6,a5,8000686a <snprintf+0xcc>
    80006840:	0b578663          	beq	a5,s5,800068ec <snprintf+0x14e>
    80006844:	0b879a63          	bne	a5,s8,800068f8 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006848:	f9843783          	ld	a5,-104(s0)
    8000684c:	00878713          	addi	a4,a5,8
    80006850:	f8e43c23          	sd	a4,-104(s0)
    80006854:	4685                	li	a3,1
    80006856:	4629                	li	a2,10
    80006858:	438c                	lw	a1,0(a5)
    8000685a:	009b8533          	add	a0,s7,s1
    8000685e:	00000097          	auipc	ra,0x0
    80006862:	ea8080e7          	jalr	-344(ra) # 80006706 <sprintint>
    80006866:	9ca9                	addw	s1,s1,a0
      break;
    80006868:	b775                	j	80006814 <snprintf+0x76>
    switch(c){
    8000686a:	09979763          	bne	a5,s9,800068f8 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    8000686e:	f9843783          	ld	a5,-104(s0)
    80006872:	00878713          	addi	a4,a5,8
    80006876:	f8e43c23          	sd	a4,-104(s0)
    8000687a:	4685                	li	a3,1
    8000687c:	4641                	li	a2,16
    8000687e:	438c                	lw	a1,0(a5)
    80006880:	009b8533          	add	a0,s7,s1
    80006884:	00000097          	auipc	ra,0x0
    80006888:	e82080e7          	jalr	-382(ra) # 80006706 <sprintint>
    8000688c:	9ca9                	addw	s1,s1,a0
      break;
    8000688e:	b759                	j	80006814 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    80006890:	f9843783          	ld	a5,-104(s0)
    80006894:	00878713          	addi	a4,a5,8
    80006898:	f8e43c23          	sd	a4,-104(s0)
    8000689c:	639c                	ld	a5,0(a5)
    8000689e:	c3a9                	beqz	a5,800068e0 <snprintf+0x142>
      for(; *s && off < sz; s++)
    800068a0:	0007c703          	lbu	a4,0(a5)
    800068a4:	db25                	beqz	a4,80006814 <snprintf+0x76>
    800068a6:	0134de63          	bge	s1,s3,800068c2 <snprintf+0x124>
    800068aa:	009b86b3          	add	a3,s7,s1
  *s = c;
    800068ae:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800068b2:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800068b4:	0785                	addi	a5,a5,1
    800068b6:	0007c703          	lbu	a4,0(a5)
    800068ba:	df29                	beqz	a4,80006814 <snprintf+0x76>
    800068bc:	0685                	addi	a3,a3,1
    800068be:	fe9998e3          	bne	s3,s1,800068ae <snprintf+0x110>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800068c2:	8526                	mv	a0,s1
    800068c4:	70a6                	ld	ra,104(sp)
    800068c6:	7406                	ld	s0,96(sp)
    800068c8:	64e6                	ld	s1,88(sp)
    800068ca:	6946                	ld	s2,80(sp)
    800068cc:	69a6                	ld	s3,72(sp)
    800068ce:	6a06                	ld	s4,64(sp)
    800068d0:	7ae2                	ld	s5,56(sp)
    800068d2:	7b42                	ld	s6,48(sp)
    800068d4:	7ba2                	ld	s7,40(sp)
    800068d6:	7c02                	ld	s8,32(sp)
    800068d8:	6ce2                	ld	s9,24(sp)
    800068da:	6d42                	ld	s10,16(sp)
    800068dc:	610d                	addi	sp,sp,160
    800068de:	8082                	ret
        s = "(null)";
    800068e0:	00001797          	auipc	a5,0x1
    800068e4:	74078793          	addi	a5,a5,1856 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800068e8:	876a                	mv	a4,s10
    800068ea:	bf75                	j	800068a6 <snprintf+0x108>
  *s = c;
    800068ec:	009b87b3          	add	a5,s7,s1
    800068f0:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800068f4:	2485                	addiw	s1,s1,1
      break;
    800068f6:	bf39                	j	80006814 <snprintf+0x76>
  *s = c;
    800068f8:	009b8733          	add	a4,s7,s1
    800068fc:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    80006900:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006904:	975e                	add	a4,a4,s7
    80006906:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000690a:	2489                	addiw	s1,s1,2
      break;
    8000690c:	b721                	j	80006814 <snprintf+0x76>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
