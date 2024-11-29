
`timescale 1ns/1ps
`define CLK_PERIOD          10 //100MHz

module tb; // testbench

	parameter PE_NUM   =   4;  // number of units
	parameter BW_ACT   =   8;  // bit length of activation
    parameter BW_W     =   8;  // bit length of weight
    parameter BW_P     =   7;  // bit length of weight
    parameter BW_Z     =   3;  // bit length of weight
    parameter BW_ACCU  =   32;    // bit length of accu result  

   parameter IA_H = 576;
   parameter IA_W = 1024;
   parameter Weight_H = 128;
   parameter Weight_W = 576; 
   parameter OA_H = 128;
   parameter OA_W = 1024;


    //small scale test
    // parameter IA_H = 16;//576;
    // parameter IA_W = 3;//1024;
    // parameter Weight_H = 64;//128;
    // parameter Weight_W = 16;//576; 
    // parameter OA_H = 64;//128;
    // parameter OA_W = 3;//1024;
    
    //diverse sparsity
    //  parameter IA_H = 32;
    //  parameter IA_W = 32;
    //  parameter Weight_H = 128;
    //  parameter Weight_W = 32; 
    //  parameter OA_H = 128;
    //  parameter OA_W = 32;

    parameter W_ROW=16;
    parameter W_COL=8;

    reg clk;
    reg reset_n;
    reg PE_mac_enable;
    reg PE_clear_acc;

    reg signed [BW_ACT-1:0]    PE_act_in [W_COL-1:0];         // input activation
    reg signed [BW_W-1:0]      PE_w_in[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];         // input weight
    reg signed [BW_P-1:0]      PE_p_in[PE_NUM-1:0][W_COL:0];  
    reg signed [BW_Z-1:0]      PE_z_in[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];
    reg  [7:0]                 PE_res_shift_num;
    wire signed [BW_ACT-1:0]   PE_result_out [W_ROW-1:0];    // output result   

    reg signed [BW_ACT-1:0]    Input_activation_main_memory[IA_H-1:0][IA_W-1:0]; // main memory (DRAM)
    reg signed [BW_W-1:0]      W_main_memory[Weight_H/W_ROW-1:0][Weight_W/W_COL-1:0][PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];
    reg signed [BW_P-1:0]      P_main_memory[Weight_H/W_ROW-1:0][Weight_W/W_COL-1:0][PE_NUM-1:0][W_COL:0];
    reg signed [BW_Z-1:0]      Z_main_memory[Weight_H/W_ROW-1:0][Weight_W/W_COL-1:0][PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];
    reg signed [BW_ACT-1:0]    Output_activation_main_memory[OA_H-1:0][OA_W-1:0];
    reg signed [BW_ACT-1:0]    reference_output[OA_H-1:0][OA_W-1:0];
    wire                       all_finished;
    integer m,j,i;
    //debug ports
    // reg signed [$clog2(W_ROW/PE_NUM)+1:0]     PE_remain_numbers[PE_NUM-1:0];
    // reg signed [BW_W-1:0]                   PE_queue_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0];
    // reg signed [BW_ACCU-1:0]                PE_result_out_reg [W_ROW-1:0];
    // reg                                     finished;
    // reg signed [$clog2(W_ROW):0]            PE_act_index;
    // reg                                     buffer_read;
    // wire       [BW_ACT-1:0]                 act;
    // wire                                    flag[PE_NUM-1:0];
    // reg signed [$clog2(W_ROW):0]            PE_queue_index_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0];
    // reg signed [BW_W-1:0]                   PE_w_in_reg[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];
    // wire signed[BW_ACCU-1:0]                adder;
    
    sparse_accelerator #(
        .PE_NUM(PE_NUM),
        .W_ROW(W_ROW),
        .W_COL(W_COL),
	    .BW_ACT(BW_ACT),
        .BW_W(BW_W),
        .BW_P(BW_P),
        .BW_Z(BW_Z),
        .BW_ACCU(BW_ACCU)
    )my_sparse_accelerator(
        .clk(clk),
        .reset_n(reset_n),
        .PE_mac_enable(PE_mac_enable),
        .PE_clear_acc(PE_clear_acc),
        .PE_act_in(PE_act_in),
        .PE_w_in(PE_w_in),
        .PE_p_in(PE_p_in),
        .PE_z_in(PE_z_in),
        .PE_res_shift_num(PE_res_shift_num),
        .PE_result_out(PE_result_out),
        .all_finished(all_finished)
        //debug ports
        // .PE_remain_numbers(PE_remain_numbers),
        // .PE_queue_reg(PE_queue_reg),
        // .PE_result_out_reg(PE_result_out_reg),
        // .finished(finished),
        // .PE_act_index(PE_act_index),
        // .buffer_read(buffer_read),
        // .act(act),
        // .flag(flag),
        // .PE_queue_index_reg(PE_queue_index_reg),
        // .PE_w_in_reg(PE_w_in_reg),
        // .adder(adder)
    );

    initial begin
        clk = 0;
        reset_n = 1;
        PE_res_shift_num <= 8;
        PE_clear_acc = 0;
        for(integer x=0;x<W_COL;x=x+1)begin
            PE_act_in[x]<='0;
        end
        for(integer x=0;x<PE_NUM;x=x+1)begin
            for(integer y=0;y<W_COL*W_ROW/PE_NUM;y=y+1)begin
                PE_z_in[x][y]<='0;
                PE_w_in[x][y]<='0;
            end
            for(integer y=0;y<W_COL+1;y=y+1)begin
                PE_p_in[x][y]<='0;
            end
        end
        forever begin
            #(`CLK_PERIOD/2) clk = ~clk; //clock
        end
    end
    integer wrong_num=0; // a validation metric
    initial begin
        @(negedge clk); 
        reset_n = 0; //reset
        
        // read data
       $readmemb("D:/Desktop/lab3/code/activation_col_bin.txt", Input_activation_main_memory);
       $readmemb("D:/Desktop/lab3/code/w_bin.txt", W_main_memory);
       $readmemb("D:/Desktop/lab3/code/p_bin.txt", P_main_memory);
       $readmemb("D:/Desktop/lab3/code/z_bin.txt", Z_main_memory);
       $readmemb("D:/Desktop/lab3/code/output_col_bin.txt", reference_output);
        //small scale test
        // $readmemb("D:/Desktop/lab3/code/a1.txt", Input_activation_main_memory);
        // $readmemb("D:/Desktop/lab3/code/w1.txt", W_main_memory);
        // $readmemb("D:/Desktop/lab3/code/p1.txt", P_main_memory);
        // $readmemb("D:/Desktop/lab3/code/z1.txt", Z_main_memory);
        // $readmemb("D:/Desktop/lab3/code/o1.txt", reference_output);
        //diverse sparsity
        //  $readmemb("D:/Desktop/lab3/code/diverse_sparsity/ad.txt", Input_activation_main_memory);
        //  $readmemb("D:/Desktop/lab3/code/diverse_sparsity/wd.txt", W_main_memory);
        //  $readmemb("D:/Desktop/lab3/code/diverse_sparsity/pd.txt", P_main_memory);
        //  $readmemb("D:/Desktop/lab3/code/diverse_sparsity/zd.txt", Z_main_memory);
        //  $readmemb("D:/Desktop/lab3/code/diverse_sparsity/od.txt", reference_output);
        
        // loop nest
        @(negedge clk);
        reset_n = 1;
        
        
        PE_mac_enable = 1;
        //OA stationary
        for(m=0;m<OA_W;m=m+1) begin//One column of OA
            for(j=0;j<Weight_H/W_ROW;j=j+1) begin
                for(i=0;i<Weight_W/W_COL+1;i=i+1) begin
                    @(negedge clk) begin
                        if(i==0) begin
                            PE_clear_acc <= 0; // remove the old results and start
                        end
                        if(i<Weight_W/W_COL)begin
                            PE_w_in   <=    W_main_memory[j][i];
                            PE_p_in   <=    P_main_memory[j][i];
                            PE_z_in   <=    Z_main_memory[j][i];
                            for(integer x=0;x<W_COL;x=x+1)begin
                                PE_act_in[x] <= Input_activation_main_memory[x+i*W_COL][m];
                            end
                        end                        
                    end//input 
                    //wait
                    while(~all_finished)begin
                        @(negedge clk);
                    end                 
                end
                for(integer n=0;n<W_ROW;n=n+1) begin
                    Output_activation_main_memory[j*W_ROW+n][m] <= PE_result_out[n];
                end
                PE_clear_acc <= 1;
                                      
            end
        end
        
        
        
        
        
        //validation
        for(integer k=0;k<OA_H;k=k+1) begin
            for(integer p=0;p<OA_W;p=p+1) begin
                if(Output_activation_main_memory[k][p]!=reference_output[k][p]) begin
                    $display("wrong at (%d %d), output %d, reference %d", k, p, Output_activation_main_memory[k][p], reference_output[k][p]);
                    wrong_num = wrong_num + 1;
                end
            end
        end
        $display("wrong num: %d",wrong_num);
        @(negedge clk)
        $finish(0);//(important for getting the running time)
    end

endmodule