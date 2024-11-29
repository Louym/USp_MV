module pe_array #(
	parameter MAC_NUM    =   4,  // number of multiply-accumulation units
	parameter BW_ACT     =   8,  // bit length of activation
    parameter BW_WET     =   8,  // bit length of weight
    parameter BW_ACCU    =   32    // bit length of accu result    
)(
    input        clk,
    input        reset_n,
    // // control signal
    input        PE_mac_enable,      // high active
    input        PE_clear_acc,
    // data signal 
    input   signed     [BW_ACT-1:0]    PE_act_in [MAC_NUM-1:0] ,         // input activation
    input   signed     [BW_WET-1:0]    PE_wet_in,         // input weight
    input              [7:0]           PE_res_shift_num,
    output  reg signed [BW_ACT-1:0]    PE_result_out [MAC_NUM-1:0]     // output result   
);

    reg signed [BW_ACT-1:0]    PE_act_in_reg [MAC_NUM-1:0] ;      // input buffer
    reg signed [BW_WET-1:0]    PE_wet_in_reg;      // weight buffer
    reg signed [BW_ACCU-1:0]   PE_result_out_reg [MAC_NUM-1:0];  
    reg PE_clear_acc_reg; //????????????????buffer???????1 cycle??????????????1 cycle

    always @(posedge clk or negedge reset_n) begin
        if(~reset_n) begin 
            PE_clear_acc_reg <= '0;
        end
        else begin
            PE_clear_acc_reg <= PE_clear_acc;
        end        
    end

    always @(posedge clk or negedge reset_n) begin
        if(~reset_n) begin // ??¦Ë????
            PE_wet_in_reg <= '0;
        end
        else begin
            PE_wet_in_reg <= PE_wet_in;
        end
    end



    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < MAC_NUM; gv_i = gv_i + 1) begin : line

            wire signed [BW_ACCU-1:0]PE_result_shift_temp;
            always @(posedge clk or negedge reset_n) begin
                if(~reset_n) begin // ??¦Ë????
                    PE_act_in_reg[gv_i] <= '0;
                end
                else begin
                    PE_act_in_reg[gv_i] <= PE_act_in[gv_i];
                end
            end

            always @(posedge clk or negedge reset_n) begin
                if(~reset_n) begin // ??¦Ë????
                    PE_result_out_reg[gv_i] <= '0;
                end
                else if(~PE_mac_enable) begin //???????????
                    PE_result_out_reg[gv_i] <= PE_result_out_reg[gv_i];
                end
                else if(PE_clear_acc_reg) begin
                    PE_result_out_reg[gv_i] <= '0;
                end
                else begin //?????????
                    PE_result_out_reg[gv_i] <= PE_result_out_reg[gv_i] + PE_wet_in_reg*PE_act_in_reg[gv_i];
                end
            end

            assign PE_result_shift_temp = PE_result_out_reg[gv_i] >>> PE_res_shift_num;
            always @(posedge clk or negedge reset_n) begin
                if(~reset_n) begin
                    PE_result_out[gv_i] <= '0;
                end
                else if(PE_result_shift_temp>127) begin
                    PE_result_out[gv_i] <= 127;
                end
                else if(PE_result_shift_temp<-128) begin
                    PE_result_out[gv_i] <= -128;
                end
                else begin
                    PE_result_out[gv_i] <= PE_result_shift_temp[BW_ACT-1:0];  //?????¦Ë
                end
            end
        end

    endgenerate
endmodule