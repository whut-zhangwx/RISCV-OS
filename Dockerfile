FROM whutzhangwx/riscv-os:env
ADD . /root/os
WORKDIR /root/os
SHELL [ "/bin/bash", "--login", "-c" ]