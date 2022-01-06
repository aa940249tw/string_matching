`timescale 1ns / 1ps

module weight_cut #(parameter DWIDTH = 8, groups = 4, num = 4, max_number_of_weight = num*groups, 
                    weight_num = 2000, buffer_size=46000)(
        input clk,
        input reset,
        input enable,
        input [num:0] signal_from_controller,
        input string_ready,
        output reg [max_number_of_weight*DWIDTH-1:0] weight_cut,
        output reg weight_enable,
        output reg string_finish
    );
    
    reg [DWIDTH-1:0] RAM [0:buffer_size-1];
    reg [8*2:0] weights_len [0:weight_num];
    reg [8*3*num-1:0] cur_pos, cur_pos_n;
    reg state, state_n;
    reg weight_enable_n, string_finish_n;
    reg [max_number_of_weight*DWIDTH-1:0] weight_cut_n;
    reg [8:0] i, j;
    reg [16:0] cur_index, cur_index_n;
    
    
    initial begin
        $readmemh("test_weight.mem", RAM);
        $readmemh("test_w_len.mem", weights_len);
    end
    
     always @(posedge clk) begin
        if(reset || ~enable) begin
            weight_cut <= 0;
            weight_enable <= 0; 
            state <= 1;
            cur_pos <= 0; 
            cur_index <= 0;
            string_finish <= 0;
        end
        else begin
            weight_cut <= weight_cut_n;
            weight_enable <= weight_enable_n;
            state <= state_n;
            cur_pos <= cur_pos_n;
            cur_index <= cur_index_n;
            string_finish <= string_finish_n;
        end
    end
    
    always @(*) begin
       cur_index_n = cur_index;
       cur_pos_n = cur_pos;
       state_n = state;
       string_finish_n = 0;
       weight_cut_n = weight_cut;
        case (state) 
            1'b0: begin
                if(cur_index < weight_num && (signal_from_controller[num] || cur_index == 0)) begin
                    weight_enable_n =1;
                    for(i = 0; i < num && cur_index+i < weight_num; i = i+1) begin
                        if(signal_from_controller[i] && cur_pos[i*24+:8]+num <  weights_len[cur_pos_n[i*24+8+:16]+1]-weights_len[cur_pos_n[i*24+8+:16]]) begin
                            cur_pos_n[i*24+:8] = cur_pos[i*24+:8] + num;
                            for(j = 0; j < num && cur_pos_n[i*24+:8]+j <  weights_len[cur_pos_n[i*24+8+:16]+1]-weights_len[cur_pos_n[i*24+8+:16]]; j = j+1) begin
                                weight_cut_n[i*DWIDTH*num + j*DWIDTH+:8] = RAM[weights_len[cur_pos_n[i*24+8+:16]] + j]; 
                            end
                        end
                        else begin
                            cur_pos_n[i*24+:8] = 0;
                            cur_pos_n[i*24+8+:16] = cur_index_n;
                            for(j = 0; j < num; j = j+1) begin
                                weight_cut_n[i*DWIDTH*num + j*DWIDTH+:8] = RAM[weights_len[cur_pos_n[i*24+8+:16]] + j]; 
                            end
                            cur_index_n = cur_index_n + 1;
                        end
                    end
                end
                else begin
                    weight_enable_n = 0;
                    if(cur_index >= weight_num-1) begin
                        state_n = 1'b1;
                        string_finish_n = 1'b1;
                    end
                end
            end
            1'b1 : begin
                weight_cut_n = 0;
                weight_enable_n = 0;
                cur_pos_n = 0;
                cur_index_n = 0;
                state_n = 0;
                string_finish_n = 1'b1;
                state_n = string_ready ? 1'b0 : 1'b1;
            end    
        endcase
    end   
endmodule
