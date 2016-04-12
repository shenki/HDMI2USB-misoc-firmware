export ARCH=or1k
export BOARD=minispartan6
export TARGET=base
export SERIAL=/dev/ttyUSB1
export RAM_ADDR=0x40000000

shopt -s expand_aliases
source scripts/setup-env.sh
