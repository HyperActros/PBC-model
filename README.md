# PBC-model （MATLAB ONLY）
自动化基于Abaqus的inp文件导入新的周期性边界条件（PBC）

本代码基于 https://www.youtube.com/watch?v=pRcRsmR4DMo 《How to SEMI-AUTOMATICALLY apply Periodic Boundary Conditions in ABAQUS - Dr. Michael Okereke》修改。

建议看一下原视频，因为PBC有几种不同施加类型。（例如Digimat软件里使用的是三点约束，这里用的是四点约束）

原代码是半自动的，需要自己找节点序号很麻烦，故自动化。

# HOW TO USE
用MATLAB打开Automated_Add_PBC_Program.m，修改inpFileName和outputFileName（15、16行），在同一个路径下运行该脚本。

将得到的'outputFile.inp'导入到Abaqus软件内。
