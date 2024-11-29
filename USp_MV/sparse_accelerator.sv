//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Louym21
// 
// Create Date: 06/25/2024 06:31:07 PM
// Design Name: 
// Module Name: sparse_accelerator
// Project Name: lab3 HW
// Target Devices: xc7z030ffg676-2
// Tool Versions: vivado 2023.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sparse_accelerator#
(   
    parameter PE_NUM   =   4,  // number of PEs
    parameter W_ROW    =   16,  // input weight rows
    parameter W_COL    =   8,  // input weight columns
	parameter BW_ACT   =   8,  // bit length of activation
    parameter BW_W     =   8,  // bit length of weight
    parameter BW_P     =   7,  // bit length of p
    parameter BW_Z     =   3,  // bit length of z
    parameter BW_ACCU  =   32    // bit length of accu result   
    )(
    input        clk,
    input        reset_n,
    //control signal
    input        PE_mac_enable,      // high active
    input        PE_clear_acc,
    // data signal 
    input   signed     [BW_ACT-1:0]    PE_act_in [W_COL-1:0] ,         // input activation
    input   signed     [BW_W-1:0]      PE_w_in[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0],         // input weight
    input   signed     [BW_P-1:0]      PE_p_in[PE_NUM-1:0][W_COL:0],         // input p
    input   signed     [BW_Z-1:0]      PE_z_in[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0],         // input z
    input              [7:0]           PE_res_shift_num,
    output  reg signed [BW_ACT-1:0]    PE_result_out [W_ROW-1:0],     // output result
    output  reg                        all_finished
    //debug ports  
    // output  reg signed [$clog2(W_ROW/PE_NUM)+1:0]     PE_remain_numbers[PE_NUM-1:0],
    // output  reg signed [BW_W-1:0]                   PE_queue_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0],
    // output  reg signed [BW_ACCU-1:0]                PE_result_out_reg [W_ROW-1:0],
    // output  reg signed [$clog2(W_ROW):0]            PE_queue_index_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0],
    // output  reg                                     finished,
    // output  reg signed [$clog2(W_ROW):0]            PE_act_index,
    // output  reg                                     buffer_read,
    // output  wire signed[BW_ACT-1:0]                 act,
    // output  wire                                    flag[PE_NUM-1:0],
    // output  reg signed [BW_W-1:0]                   PE_w_in_reg[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0],
    // output  wire signed[BW_ACCU-1:0]                adder
);    
    reg signed [BW_ACT-1:0]                 PE_act_in_reg [W_COL-1:0];      // input buffer
    reg signed [BW_W-1:0]                   PE_w_in_reg[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];      // weight buffer
    reg signed [BW_P-1:0]                   PE_p_in_reg[PE_NUM-1:0][W_COL:0];
    reg signed [BW_Z-1:0]                   PE_z_in_reg[PE_NUM-1:0][W_ROW*W_COL/PE_NUM-1:0];
    reg signed [BW_ACCU-1:0]                PE_result_out_reg [W_ROW-1:0];  
    reg signed [BW_W-1:0]                   PE_queue_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0];
    reg        [$clog2(W_ROW)-1:0]          PE_queue_index_reg [PE_NUM-1:0][W_ROW/PE_NUM-1:0];
    reg signed  [$clog2(W_ROW):0]          PE_act_index;
    reg                                     PE_clear_acc_reg; 
    reg                                     finished; 
    reg signed [$clog2(W_ROW/PE_NUM)+1:0]   PE_remain_numbers[PE_NUM-1:0];
    reg                                     buffer_read;
    wire                                     flag[PE_NUM-1:0];
    assign act=PE_act_in_reg[PE_act_index];
    //control the clear signal
    always @(posedge clk or negedge reset_n) begin
        if(~reset_n) begin 
            PE_clear_acc_reg <='0;
        end
        else begin
            PE_clear_acc_reg <= PE_clear_acc;
        end        
    end
    
   
    //control the input wpz array
    integer i,j;
    
    always @(posedge clk or negedge reset_n) begin
        if(~reset_n||PE_clear_acc_reg) begin 
            for (i = 0; i < PE_NUM; i = i + 1) begin
                for (j = 0; j < W_ROW*W_COL/PE_NUM; j = j + 1) begin
                    PE_w_in_reg[i][j] <= '0;
                    PE_z_in_reg[i][j] <= '0;
                end 
                for (j = 0; j < W_COL; j = j + 1) begin
                    PE_p_in_reg[i][j] <= '0; 
                    PE_act_in_reg[j] <= '0;
                end
            end
        end
        else begin
            if(all_finished)begin
                all_finished<=0;
                finished<=0;
                PE_w_in_reg <= PE_w_in;
                PE_z_in_reg <= PE_z_in;
                PE_p_in_reg <= PE_p_in;
                PE_act_in_reg <= PE_act_in;
            end
            else 
            begin//remain the same
                PE_w_in_reg <= PE_w_in_reg;
                PE_z_in_reg <= PE_z_in_reg;
                PE_p_in_reg <= PE_p_in_reg;
                PE_act_in_reg <= PE_act_in_reg;
            end
        end
    end


    assign adder=PE_act_in_reg[PE_act_index]*PE_queue_reg[0][0];
    //control the activation index and finished signal
    integer k,a;
    always @(posedge clk or negedge reset_n) begin
        if(~reset_n||PE_clear_acc_reg) begin 
            PE_act_index<=-1;
            all_finished<=0;
            finished<=1;
            buffer_read<=0;
        end
        else begin
            if(~all_finished)begin
                if(finished)begin//Last column of W is calculated out, find the new column index
                    for(k=1;k<=W_COL+1;k=k+1)begin
                        if(k+PE_act_index>=W_COL)begin
                            all_finished<=1;//No nonzero activation left, all finished
                            PE_act_index<=-1;//prepare for next round
                            break;
                        end
                        else begin//finished 1->0
                            if(PE_act_in_reg[k+PE_act_index]!='0)begin
                                PE_act_index<=k+PE_act_index;//Get the index of the next activation
                                a=1;
                                for(integer y=0;y<PE_NUM;y=y+1)begin:line2
                                    PE_remain_numbers[y]<=PE_p_in_reg[y][k+PE_act_index+1]-PE_p_in_reg[y][k+PE_act_index];
                                    if(PE_p_in_reg[y][k+PE_act_index+1]-PE_p_in_reg[y][k+PE_act_index]>'0)begin
                                        a=0;
                                    end
                                end
                                if(a==1)begin//go to the next column directly!
                                    finished<=1;
                                    buffer_read<=0;
                                end
                                else begin
                                    finished<=0;
                                    buffer_read<=1;
                                end
                                break;
                            end
                        end
                    end
                end
                else begin//finished 0->1
                    a=1;
                    for(integer x=0;x<PE_NUM;x=x+1)begin
                        if(flag[x])begin
                            a=0;
                        end
                    end
                    finished<=(a==1);
                end 
            end
        end
    end

    //core code    
    genvar gv_i;
    integer l;
    generate
        for (gv_i = 0; gv_i < PE_NUM; gv_i = gv_i + 1) begin : line
        assign flag[gv_i]=PE_remain_numbers[gv_i]>0;
            //control the queue buffer 
            always @(posedge clk or negedge reset_n) begin
                if(~reset_n||all_finished||PE_clear_acc_reg) begin 
                    for (j = 0; j < W_ROW/PE_NUM; j = j + 1) begin
                        PE_queue_reg[gv_i][j] <= '0;
                        PE_queue_index_reg[gv_i][j] <= '0; 
                        PE_remain_numbers[gv_i]<='0;
                    end//reset the queue buffer
                end
                else begin
                    if(buffer_read)begin//buffer refresh 
                        buffer_read<=0;                    
                        if(PE_p_in_reg[gv_i][PE_act_index+1]-PE_p_in_reg[gv_i][PE_act_index]>0)begin//Nozero w exists!
                            l=0;
                            for(integer buffer_i=0;buffer_i<W_ROW/PE_NUM;buffer_i=buffer_i+1)begin
                                l=l+PE_z_in_reg[gv_i][buffer_i+PE_p_in_reg[gv_i][PE_act_index]];
                                PE_queue_index_reg[gv_i][buffer_i] <=l*W_ROW/PE_NUM+gv_i;
                                PE_queue_reg[gv_i][buffer_i] <= PE_w_in_reg[gv_i][buffer_i+PE_p_in_reg[gv_i][PE_act_index]];
                                l=l+1;
                                if(buffer_i==PE_p_in_reg[gv_i][PE_act_index+1]-1-PE_p_in_reg[gv_i][PE_act_index])
                                    break;
                            end                            
                        end
                        
                    end
                    else begin//buffer iteration and PE calculation
                        if(PE_remain_numbers[gv_i]>'0&&PE_mac_enable&&PE_act_index>='0)begin
                            PE_result_out_reg[PE_queue_index_reg[gv_i][0]]<=PE_result_out_reg[PE_queue_index_reg[gv_i][0]]+PE_act_in_reg[PE_act_index]*PE_queue_reg[gv_i][0];
                            for(j = 0; j < W_ROW/PE_NUM-1; j = j + 1) begin 
                                PE_queue_reg[gv_i][j]<=PE_queue_reg[gv_i][j+1];
                                PE_queue_index_reg[gv_i][j]<=PE_queue_index_reg[gv_i][j+1];
                            end
                            PE_queue_reg[gv_i][W_ROW/PE_NUM-1]<='0;
                            PE_queue_index_reg[gv_i][W_ROW/PE_NUM-1]<='0;
                            PE_remain_numbers[gv_i]<=PE_remain_numbers[gv_i]-1;
                        end                       
                    end
                end
            end
        end
    endgenerate



    genvar gv_j;

    generate
        for (gv_j = 0; gv_j < W_ROW; gv_j = gv_j + 1) begin : line1

            wire signed [BW_ACCU-1:0]PE_result_shift_temp;
            always @(posedge clk or negedge reset_n) begin
                if(~reset_n) begin 
                    PE_result_out_reg[gv_j] <= '0;
                end
                else if(~PE_mac_enable) begin 
                    PE_result_out_reg[gv_j] <= PE_result_out_reg[gv_j];
                end
                else if(PE_clear_acc_reg) begin
                    PE_result_out_reg[gv_j] <= '0;
                end
            end

            assign PE_result_shift_temp = PE_result_out_reg[gv_j] >>> PE_res_shift_num;
            always @(posedge clk or negedge reset_n) begin
                if(~reset_n) begin
                    PE_result_out[gv_j] <= '0;
                end
                else if(PE_result_shift_temp>127) begin
                    PE_result_out[gv_j] <= 127;
                end
                else if(PE_result_shift_temp<-128) begin
                    PE_result_out[gv_j] <= -128;
                end
                else begin
                    PE_result_out[gv_j] <= PE_result_shift_temp[BW_ACT-1:0];  
                end
            end
        end

    endgenerate

     
endmodule
