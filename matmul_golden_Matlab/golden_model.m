clc
clear all

% Define the file name
MatrixA_file_name = 'MatrixA.txt';   %'MatrixA file name'
MatrixB_file_name = 'MatrixB.txt';   %'MatrixB file name'
MatrixC_file_name = 'MatrixC.txt';   %'MatrixC file name'
Mod_file_name = 'ModFile.txt';
% Open the file for writing

fidA = fopen(MatrixA_file_name, 'w');
fidB = fopen(MatrixB_file_name, 'w');
fidC = fopen(MatrixC_file_name, 'w');
fidMOD = fopen(Mod_file_name, 'w');

%parameters
DATA_WIDTH = 8;
BUS_WIDTH = 32;
ADDR_WIDTH = 32;
MAX_DIM = BUS_WIDTH/DATA_WIDTH;
num_matrices = 15;
Maxnumber = 2^(DATA_WIDTH-1);
Minnumber = -2^(DATA_WIDTH-1);
history = {};
for i = 1:num_matrices
    % Generate matrices size
    N = randi([1,MAX_DIM]);
    K = randi([1,MAX_DIM]);
    M = randi([1,MAX_DIM]);
    modbit = randi([0,1]);
    
    % Generate random matrices
    random_matrix_A = randi([Minnumber, Maxnumber], N, K);
    random_matrix_B = randi([Minnumber, Maxnumber], K, M);
    random_matrix_C = random_matrix_A * random_matrix_B;
    
    if(modbit)
        for index = 1:i           
           try
            if(size(random_matrix_C)==size(history{index}))
                random_matrix_C = random_matrix_C + history{index};
                fprintf(fidMOD, 'add saved matrix %d to the MatrixC ,', index);  
                break 
            end
           end
        if(index == i)
            modbit = 0;
        end
        end
      end

    fprintf(fidMOD,'modbit = %d ',modbit);
    fprintf(fidMOD, '\n');    
    history{end+1}  = random_matrix_C;

    


    random_matrix_B = random_matrix_B';
    % Write the matrices to the files
    % Save matrix A to file


    fprintf(fidA, '%d x %d\n', N, K);
    for row = 1:N
        fprintf(fidA, '%f\t', random_matrix_A(row, :));
        fprintf(fidA, '\n');
    end
    fprintf(fidA, '\n\n');

    % Save matrix B to file
    fprintf(fidB, '%d x %d\n', K, M);
    %for row = 1:K %in order to print normal.
    for row = 1:M  %in order to print transpose. 
        fprintf(fidB, '%f\t', random_matrix_B(row, :));
        fprintf(fidB, '\n');
    end
    fprintf(fidB, '\n\n');

    % Save matrix C to file
    fprintf(fidC, '%d x %d\n', N, M);
    for row = 1:N
        fprintf(fidC, '%f\t', random_matrix_C(row, :));
        fprintf(fidC, '\n');
    end
    fprintf(fidC, '\n\n');


end
% Close the file
fclose(fidA);
fclose(fidB);
fclose(fidC);
disp(['Matrices saved to file: ', MatrixA_file_name, ', ', MatrixB_file_name, ', ', MatrixC_file_name]);
