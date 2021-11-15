#!/bin/bash
#Script to build kernel
#Made by incinerator (kangs from various sources hehe) without losing braincells.. It just works

#colourful hehe
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;31m$*\e[0m"
}

# Set tg var.
function sendTG() {
    curl -s "https://api.telegram.org/bot$TOKEN/sendmessage" --data "text=${*}&chat_id=$CHATID&parse_mode=HTML" > /dev/null
}

#setup

MAIN=$(readlink -f ../)
KERNELDIR=$(readlink -f .)
BRANCH=$(git branch --show-current)
CHATID=$CHATID
HEAD=$(git log --oneline -1)

#Start build notification
sendTG "Build Started"

export KBUILD_BUILD_USER=" "
export KBUILD_BUILD_HOST=" "

#Take compiling options

echo "
Select Compiler and press ENTER
1 = Proton-Clang
2 = GCC"

read comp

if [[ $comp == "1" ]]
  then
    COMPILER=proton-clang
    msg "
    Compiling with Proton-Clang
    "
elif [[ $comp == "2" ]]
  then
    COMPILER=gcc
    msg "
    Compiling with GCC
    "
fi

echo "
Make Clean?
Press 1 if YES / press anything if NO
And press ENTER"

read clean

if [[ $clean == "1" ]]
  then
    msg "
    || Cleaning Sources ||
    "
    make clean && make mrproper
   else
    err "
    || Dirty Build ||
    "
  fi

START=$(date +"%s")

#Start Compilation

if [ $COMPILER = "proton-clang" ]
  then

make ARCH=arm64 X00T_defconfig O=out -j$(nproc --all)
  make -j$(nproc --all) O=out \
        CC="$MAIN/proton-clang/bin/clang" \
            CROSS_COMPILE="$MAIN/proton-clang/bin/aarch64-linux-gnu-" \
                CROSS_COMPILE_ARM32="$MAIN/proton-clang/bin/arm-linux-gnueabi-" \

elif [ $COMPILER = "gcc" ]
  then

export CROSS_COMPILE=$MAIN/gcc/arm64-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=$MAIN/gcc/arm32-gcc/bin/arm-eabi-

make ARCH=arm64 X00T_defconfig O=out j$(nproc --all)
make -j$(nproc --all) O=out

fi

END=$(date +"%s")
DIFF=$(($END - $START))

COMPILED_IMAGE=out/arch/arm64/boot/Image.gz-dtb
if [[ -f ${COMPILED_IMAGE} ]];

then

#Make the kernel a flashable zip

mv out/arch/arm64/boot/Image.gz-dtb $MAIN/AnyKernel3
cd $MAIN/AnyKernel3
zip -r9 Inferno-`date +%d%m%Y_%H%M`.zip * -x "*.zip"

#Push the kernel zip
ZIP=$(ls -t1 |  head -n 1)
curl "https://api.telegram.org/bot$TOKEN/sendDocument" -F chat_id="$CHATID" -F document=@"$ZIP" -F caption="Kernel Compiled in $DIFF seconds
TC= $COMPILER
Branch= $BRANCH
HEAD= $HEAD"

msg "
                          ⡆⣐⢕⢕⢕⢕⢕⢕⢕⢕⠅⢗⢕⢕⢕⢕⢕⢕⢕⠕⠕⢕⢕⢕⢕⢕⢕⢕⢕⢕
                          ⢐⢕⢕⢕⢕⢕⣕⢕⢕⠕⠁⢕⢕⢕⢕⢕⢕⢕⢕⠅⡄⢕⢕⢕⢕⢕⢕⢕⢕⢕
                          ⢕⢕⢕⢕⢕⠅⢗⢕⠕⣠⠄⣗⢕⢕⠕⢕⢕⢕⠕⢠⣿⠐⢕⢕⢕⠑⢕⢕⠵⢕
                          ⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
                          ⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
                          ⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
                          ⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
                          ⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
                          ⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
                          ⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
                          ⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
                          ⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
                          ⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
                          ⣿⣦⡀⣿⣿⣷⣶⣬⣍⣛⣛⣛⡛⠿⠿⠿⠛⠛⢛⣛⣉⣭⣤⣂⢜⠕⢑⣡⣴⣿
"

msg "
▒█░▄▀ ▒█▀▀▀ ▒█▀▀█ ▒█▄░▒█ ▒█▀▀▀ ▒█░░░ 　 ▒█▀▀█ ▒█▀▀▀█ ▒█▀▄▀█ ▒█▀▀█ ▀█▀ ▒█░░░ ▒█▀▀▀ ▒█▀▀▄
▒█▀▄░ ▒█▀▀▀ ▒█▄▄▀ ▒█▒█▒█ ▒█▀▀▀ ▒█░░░ 　 ▒█░░░ ▒█░░▒█ ▒█▒█▒█ ▒█▄▄█ ▒█░ ▒█░░░ ▒█▀▀▀ ▒█░▒█
▒█░▒█ ▒█▄▄▄ ▒█░▒█ ▒█░░▀█ ▒█▄▄▄ ▒█▄▄█ 　 ▒█▄▄█ ▒█▄▄▄█ ▒█░░▒█ ▒█░░░ ▄█▄ ▒█▄▄█ ▒█▄▄▄ ▒█▄▄▀
                        ▒█▀▀▀█ ▒█▀▀▀ ▒█▄░▒█ ▒█▀▀█ ░█▀▀█ ▀█▀
                        ░▀▀▀▄▄ ▒█▀▀▀ ▒█▒█▒█ ▒█▄▄█ ▒█▄▄█ ▒█░
                        ▒█▄▄▄█ ▒█▄▄▄ ▒█░░▀█ ▒█░░░ ▒█░▒█ ▄█▄
"

else

#Push build failed notif to telegram
sendTG "Builed failed"

err "
▒█▀▀█ ▒█░▒█ ▀█▀ ▒█░░░ ▒█▀▀▄ 　 ▒█▀▀▀ ░█▀▀█ ▀█▀ ▒█░░░ ▒█▀▀▀ ▒█▀▀▄
▒█▀▀▄ ▒█░▒█ ▒█░ ▒█░░░ ▒█░▒█ 　 ▒█▀▀▀ ▒█▄▄█ ▒█░ ▒█░░░ ▒█▀▀▀ ▒█░▒█
▒█▄▄█ ░▀▄▄▀ ▄█▄ ▒█▄▄█ ▒█▄▄▀ 　 ▒█░░░ ▒█░▒█ ▄█▄ ▒█▄▄█ ▒█▄▄▄ ▒█▄▄▀
             ▒█▀▀▀█ ▒█▀▀▀ ▒█▄░▒█ ▒█▀▀█ ░█▀▀█ ▀█▀
             ░▀▀▀▄▄ ▒█▀▀▀ ▒█▒█▒█ ▒█▄▄█ ▒█▄▄█ ▒█░
             ▒█▄▄▄█ ▒█▄▄▄ ▒█░░▀█ ▒█░░░ ▒█░▒█ ▄█▄
"

fi

echo "
Kernel compilation time : $DIFF s"
cd $KERNELDIR
