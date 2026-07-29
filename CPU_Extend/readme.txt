本CPU是一个五级流水CPU，上限最高可以到达100MHZ稳定输出。
CPU已经接入了Vivado工程中，只需要修改官方已经给出的IROM和DRAM既可启动CPU
CPU已经参与的上版测试和trace测试。
上板子的CPU和trace测试的cpu所用的DRAM和IROM逻辑不同所以已经修改上板的代码用于匹配官方的模板
vivado文件中已经完成烧录bit流，直接上板就可启动
进行trace测试时代码：需要linux平台
1 |cd ~
2 |git clone https://gitee.com/hitsz-cslab/cdp-tests.git
3 |cd cdp-tests

1|cd cdp-tests
2|make

1|make run TEST=sltu
设计源代码中包含设计报告中的所有模块
trace测试网址：https://gitee.com/hitsz-cslab/cpu/blob/master/docs/trace/env_diy.md，此文件夹中包含所有的测试指令集代码。以及tb文件。
