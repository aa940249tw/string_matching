`timescale 1ns / 1ps

module weight_cut_ver2 #(parameter DWIDTH=8, weight_max_length=32, max_number_of_weight=16, buffer_size = 91784) (
        input clk,
        input reset,
        input enable,
        input signal_from_controller,
        input string_ready,
        output reg [max_number_of_weight*DWIDTH-1:0] weight_cut,
        output reg weight_enable,
        output reg [max_number_of_weight*DWIDTH-1:0] weight_length,
        output reg [7:0] weight_count,
        output reg string_finish
    );
    
    reg [DWIDTH-1:0] RAM [0:buffer_size-1];
    
    reg [DWIDTH-1:0] cur_pos, cur_len, cur_pos_n, cur_len_n;
    reg [DWIDTH*4-1:0] cur_address, cur_address_n;
    reg [max_number_of_weight*DWIDTH-1:0] weight_cut_n;
    reg weight_enable_n, string_finish_n;
    reg [max_number_of_weight*DWIDTH-1:0] weight_length_n;
    reg [DWIDTH-1:0] weight_count_n;
    reg state, state_n;
    reg [DWIDTH*2-1:0] count;
    
    initial begin
        $readmemh("entity_v3_pattern.mem", RAM);
    end
    
    always @(posedge clk) begin
        if(reset || ~enable) begin
            weight_cut <= 0;
            weight_enable <= 0;
            weight_length <= 0;
            weight_count <= 0;
            cur_pos <= 0;
            cur_len <= 0;
            cur_address <= 0;
            state <= 0;
            string_finish <= 0;
        end
        else begin
            weight_cut <= weight_cut_n;
            weight_enable <= weight_enable_n;
            weight_length <= weight_length_n;
            weight_count <= weight_count_n;
            state <= state_n;
            cur_pos <= cur_pos_n;
            cur_len <= cur_len_n;
            cur_address <= cur_address_n;
            string_finish <= string_finish_n;
        end
    end
    
    always @(*) begin
        weight_cut_n = weight_cut;
        weight_enable_n = weight_enable;
        weight_length_n = weight_length;
        weight_count_n = weight_count;
        state_n = state;
        cur_len_n = cur_len;
        cur_pos_n = cur_pos;
        cur_address_n = cur_address;
        string_finish_n = 0;
        case (state) 
            1'b0: begin
                if(cur_address < buffer_size && (signal_from_controller || cur_address == 0)) begin
                    count = 0;
                    weight_cut_n = 0;
                    weight_count_n = 0;
                    weight_length_n = 0;
                    if(cur_len_n == cur_pos_n) begin
                        cur_address_n = cur_address_n == 0 ? 0 : cur_address_n + 1;
                        cur_len_n = RAM[cur_address_n];
                        cur_pos_n = 0;
                        weight_count_n = weight_count_n + 1;
                        weight_length_n[max_number_of_weight*DWIDTH-1-:DWIDTH] = cur_len_n;
                    end
                    else begin
                        weight_count_n = weight_count_n + 1;
                        weight_length_n[max_number_of_weight*DWIDTH-1-:DWIDTH] = cur_len_n;
                    end
                
                    while(count < max_number_of_weight) begin
                        cur_address_n = cur_address_n + 1;
                        if(cur_len_n == cur_pos_n) begin
                            cur_len_n = RAM[cur_address_n];
                            cur_pos_n = 0;
                            weight_length_n[(max_number_of_weight-weight_count_n)*DWIDTH-1-:DWIDTH] = cur_len_n;
                            weight_count_n = weight_count_n + 1;
                        end
                        else begin
                            weight_cut_n[(max_number_of_weight-count)*DWIDTH-1-:DWIDTH] = RAM[cur_address_n];
                            cur_pos_n = cur_pos_n + 1; 
                            count = count + 1;
                        end
                    end  
                
                    //state_n = 1;
                    weight_enable_n = 1;  
                end 
                else begin
                    weight_enable_n = 0; 
                    if(cur_address >= buffer_size) begin
                        state_n = 1'b1;
                        string_finish_n = 1'b1;
                    end
                end  
            end
            1'b1 : begin
                weight_cut_n = 0;
                weight_enable_n = 0;
                weight_length_n = 0;
                weight_count_n = 0;
                cur_pos_n = 0;
                cur_len_n = 0;
                cur_address_n = 0;
                state_n = 0;
                string_finish_n = 1'b1;
                state_n = string_ready ? 1'b0 : 1'b1;
            end    
            /*
            1'b1: begin
                if(signal_from_controller) begin
                    state_n = 0;
                    weight_enable_n = 0;
                    weight_cut_n = 0;
                    weight_count_n = 0;
                    weight_length_n = 0;
                end
            end
            */
        endcase
    end
endmodule
