% This code is made by Junjie Xiao on 2025/01/22
% Special thank to Dr. Michael Okereke
%             YPos
%       N4 ------------ N3
%       |               |
%       |               |
%  XNeg |               | XPos
%       |               |
%       |               |
%       N1 ------------ N2
%             YNeg
%

%% Change the file name and run the program 
inpFileName = 'inputFile.inp';      % 你已经创建好的模型文件名
outputFileName = 'outputFile.inp';  % 输出的模型文件名
Make_Edge_Nodes_Set(inpFileName, outputFileName);
%% Create nodes set as Matrix
% This is father function
function Make_Edge_Nodes_Set(inpFileName, outputFileName)
    % Open the input file
    fidIn = fopen(inpFileName, 'r');
    if fidIn == -1
        error('Could not open input file: %s', inpFileName);
    end
    
    nodes = [];
    inNodeSection = false;

    %逐行读取 .inp 文件内容,如果检测到 *Node，标记为节点部分的开始。
    %遇到另一个 *标记的内容时，结束读取。
    while ~feof(fidIn)
        line = strtrim(fgets(fidIn));
        if startsWith(line, '*Node', 'IgnoreCase', true)
            inNodeSection = true;
            continue;
        end

        if inNodeSection && startsWith(line, '*', 'IgnoreCase', true)
            break;
        end

        if inNodeSection && ~isempty(line)
            data = sscanf(line, '%f,');
            nodes = [nodes; data(:)'];
        end
    end    
    fclose(fidIn);
    %到此，我们有所有节点编号和坐标的数据
    %分别存储到 nodeID 和 coords 中。
    nodeID = nodes(:, 1);
    coords = nodes(:, 2:end);

    % 提取矩形边界的坐标值
    xmin = min(coords(:, 1));
    xmax = max(coords(:, 1));
    ymin = min(coords(:, 2));
    ymax = max(coords(:, 2));

    % 创建四条边的set
    % 将set按升序条件排序
    xNeg = nodes(abs(coords(:, 1) - xmin) < 1e-6);
    xPos = nodes(abs(coords(:, 1) - xmax) < 1e-6);
    yNeg = nodes(abs(coords(:, 2) - ymin) < 1e-6);
    yPos = nodes(abs(coords(:, 2) - ymax) < 1e-6);
    xNeg = sortrows([nodeID(xNeg), coords(xNeg, :)], 3);
    xPos = sortrows([nodeID(xPos), coords(xPos, :)], 3);
    yNeg = sortrows([nodeID(yNeg), coords(yNeg, :)], 2);
    yPos = sortrows([nodeID(yPos), coords(yPos, :)], 2);
    xNegNum = xNeg(:, 1);
    xPosNum = xPos(:, 1);
    yNegNum = yNeg(:, 1);
    yPosNum = yPos(:, 1);
    % Create Corner Nodes
    cornerNodesN1 = xNeg(1,1);
    cornerNodesN2 = yNeg(end,1);
    cornerNodesN3 = xPos(end,1);
    cornerNodesN4 = yPos(1,1);
    cornerNodes     = [cornerNodesN1 cornerNodesN2 cornerNodesN3 cornerNodesN4];
    xPosInt         = setdiff(xPosNum, cornerNodes, 'stable');
    xNegInt         = setdiff(xNegNum, cornerNodes, 'stable');
    yPosInt         = setdiff(yPosNum, cornerNodes, 'stable');
    yNegInt         = setdiff(yNegNum, cornerNodes, 'stable');

    %嵌套函数a
    Writing_Into_OutputFile(inpFileName, outputFileName, ...
        cornerNodesN1, cornerNodesN2, cornerNodesN3, cornerNodesN4, ...
        xNegNum, xPosNum, yNegNum, yPosNum, ...
        xNegInt, xPosInt, yNegInt, yPosInt);
    fprintf('脚本已完成！ %s\n', outputFileName);
end

%% 
function Writing_Into_OutputFile(inpFileName, outputFileName, ...
    N1, N2, N3, N4, xNeg, xPos, yNeg, yPos, x1, x2, y1, y2)
    temp1 = union(xNeg,xPos);
    temp2 = union(temp1,yNeg);
    allEdgeNodes = round(union(temp2,yPos));

    % 创建一个和inp相同的文件
    fidOut = fopen(outputFileName, 'w');
    fidIn = fopen(inpFileName, 'r');

    end_assembly_reached = false;
    insert_code = false;

    while ~feof(fidIn)
        line = fgets(fidIn);

        searchString = '*Instance, name=';
        if contains(line, searchString)
            InstanceName = extractBetween(line, searchString, ',');
            disp(InstanceName);
        end

        if contains(line, '*End Assembly') && ~end_assembly_reached
            end_assembly_reached = true;
            insert_code = true;
        end

        if insert_code
        %嵌套函数b
        writeNodeSet(fidOut, 'xNeg', xNeg, InstanceName);
        writeNodeSet(fidOut, 'xPos', xPos, InstanceName);
        writeNodeSet(fidOut, 'yNeg', yNeg, InstanceName);
        writeNodeSet(fidOut, 'yPos', yPos, InstanceName);
        
        for i = 1:length(allEdgeNodes)
            fprintf(fidOut, ['*Nset, nset=N%d, instance=', InstanceName{1}, ' \n'], allEdgeNodes(i));
            fprintf(fidOut, ' %d, \n', allEdgeNodes(i));
        end
        %嵌套函数c
        PBC_equation_writing(fidOut,x1, x2, N1, N2);
        PBC_equation_writing(fidOut,y1, y2, N1, N4);
        %Connect cornerNodes (only along X-axis)
        for l = 1
            fprintf(fidOut, '** -------------------------------------\n');
            fprintf(fidOut, '** XEdge >> Constraint: Eqn-%d_11_local_axis for N3 \n', l);
            fprintf(fidOut, '*Equation \n');
            fprintf(fidOut, '4 \n');
            fprintf(fidOut, 'N%d, 1, 1. \n', N3);
            fprintf(fidOut, 'N%d, 1, -1. \n', N4);
            fprintf(fidOut, 'N%d, 1, -1. \n', N2);
            fprintf(fidOut, 'N%d, 1, 1. \n', N1);
            %Y-axis degree of freedom for N3
            fprintf(fidOut, '** -------------------------------------\n');
            fprintf(fidOut, '** YEdge >> Constraint: Eqn-%d_22_local_axis for N3 \n', l);
            fprintf(fidOut, '*Equation \n');
            fprintf(fidOut, '4 \n');
            fprintf(fidOut, 'N%d, 2, 1. \n', N3);
            fprintf(fidOut, 'N%d, 2, -1. \n', N4);
            fprintf(fidOut, 'N%d, 2, -1. \n', N2);
            fprintf(fidOut, 'N%d, 2, 1. \n', N1);
        end
        insert_code = false;
        end

        fprintf(fidOut, '%s', line);
    end
    fclose(fidIn);
    fclose(fidOut);
end

%% Write node-set into input file
function writeNodeSet(fid, setName, nodeIDs, Instance)
    fprintf(fid, '*Nset, nset=%s, instance=%s\n', setName, Instance{1});
    for i = 1:length(nodeIDs)
        if mod(i, 5) == 1 && i ~= 1
            fprintf(fid, '\n'); % Add newline for every 5 nodes
        end
        fprintf(fid, '%d, ', nodeIDs(i));
    end
    fprintf(fid, '\n');
end

%% Add PBC for the opposite side
function PBC_equation_writing(fidNSetEqn, Int1, Int2, N1, N2)
    EdgeInt        = [Int1 Int2];
    %fidNSetEqn = fopen(outputFileName, 'a+');
    for j = 1:length(EdgeInt(:, 1))
        for dof = 1:2 % 循环处理 X (dof=1) 和 Y (dof=2) 自由度
            if dof == 1
                axis = 'X';
            else
                axis = 'Y';
            end
            fprintf(fidNSetEqn, '** -------------------------------------\n');
            fprintf(fidNSetEqn, '** %sEdge >> Constraint: Eqn-%d_%d%d_local_axis \n', axis, j, dof, dof);
            fprintf(fidNSetEqn, '*Equation \n');
            fprintf(fidNSetEqn, '4 \n');
            fprintf(fidNSetEqn, 'N%d, %d, 1. \n', EdgeInt(j, 1), dof);
            fprintf(fidNSetEqn, 'N%d, %d, -1. \n', EdgeInt(j, 2), dof);
            fprintf(fidNSetEqn, 'N%d, %d, 1. \n', N1, dof);
            fprintf(fidNSetEqn, 'N%d, %d, -1. \n', N2, dof);

        end
    end
end
