#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
OBJDUMP="${OBJDUMP:-objdump}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$MACHINE/$testname
mkdir -p $t

cat <<'EOF' | $CC -x assembler -c -o $t/a.o -Wa,-L -
.globl _start, foo
_start:
foo:
bar:
.L.baz:
EOF

./mold -o $t/exe $t/a.o
readelf --symbols $t/exe > $t/log
grep -Fq _start $t/log
grep -Fq foo $t/log
grep -Fq bar $t/log

if [ $MACHINE '!=' riscv32 ] && [ $MACHINE '!=' riscv64 ]; then
  grep -Fq .L.baz $t/log
fi

./mold -o $t/exe $t/a.o -strip-all
readelf --symbols $t/exe > $t/log
! grep -Fq _start $t/log || false
! grep -Fq foo $t/log || false
! grep -Fq bar $t/log || false

if [ $MACHINE '!=' riscv32 ] && [ $MACHINE '!=' riscv64 ]; then
  ! grep -Fq .L.baz $t/log || false
fi

echo OK
