#!/bin/bash
# Lara Maia <lara@craft.net.br> 2015

if test $(id -u) != 0
then
    echo "Você precisa executar como ROOT!"
    exit 1
fi

function checkexec() {
    eval "$@" || exit 1
}; trap 'checkexec' DEBUG

function checkmv() {
    test -f "$1" && mv "$1" "$2"
}

pushd /usr/src/linux

# limpar source antes da compilação
make distclean

# aplicar patchs adicionais
curl -o gcc.patch 'https://raw.githubusercontent.com/graysky2/kernel_gcc_patch/master/enable_additional_cpu_optimizations_for_gcc_v4.9%2B_kernel_v3.15%2B.patch'
patch -Np1 -i gcc.patch

# Atualizar configuração preferida
cp /boot/kernel.config /usr/src/linux/.config
make silentoldconfig
checkmv /boot/kernel.config /boot/kernel.config.old
cp .config /boot/kernel.config

# Abrir menu de configuração
make menuconfig
#make gconfig

# Compilar o kernel
make -j5

# Instalar o kernel e módulos selecionados
make modules_install
checkmv /boot/kernel /boot/kernel.old
cp arch/x86/boot/bzImage /boot/kernel
checkmv /boot/System.map /boot/System.map.old
cp System.map /boot/System.map

# Preparar e recompilar módulos externos
make modules_prepare
emerge @module-rebuild

popd

# Atualizar bootloader
./linux_stub_loader.sh