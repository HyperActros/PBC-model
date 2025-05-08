# PBC-model
自动化基于abaqus的inp文件导入新的周期性边界条件（PBC）
本代码基于 https://www.youtube.com/watch?v=pRcRsmR4DMo 《How to SEMI-AUTOMATICALLY apply Periodic Boundary Conditions in ABAQUS - Dr. Michael Okereke》修改。
建议看一下原视频，因为PBC有几种不同施加类型。（例如Digimat软件里使用的是三点约束，这里用的是四点约束）
原代码是半自动的，需要自己找节点序号很麻烦，故自动化。
