`timescale 1ns / 1ps

module string_match #(parameter DWIDTH = 8, strlen = 100, groups = 4, num = 4, max_number_of_weight = num*groups, buffer_size=997) (
        input clk,
        input reset,
        input weight_enable,
        input string_finish,
        //input string_enable,
        input [max_number_of_weight*DWIDTH-1:0] weight,
        //input [strlen*DWIDTH-1:0] string,
        input [max_number_of_weight-1:0] router_output,
        input [max_number_of_weight*8-1:0] len_arr,
        input [7:0] weight_count,
        output reg [max_number_of_weight*DWIDTH-1:0] router_input,
        output reg [max_number_of_weight-1:0] alu,
        output reg  [max_number_of_weight-1:0] en,
        output reg [150*2+1:0] result,
        output reg done,
        output reg string_ready
    );
    reg [DWIDTH-1:0] RAM [0:buffer_size-1];
    reg [DWIDTH-1:0] string [0:strlen-1];
    reg [DWIDTH-1:0] now_strlen;
    initial begin
        $readmemh("Entity_input.mem", RAM);
    end    
    
    reg [7:0] pos, pos_next;
    reg [max_number_of_weight-1:0] en_n;
    reg [max_number_of_weight-1:0] alu_n;
    reg [max_number_of_weight*DWIDTH-1:0] router_input_n;
    reg signed [16:0] i, j, k,m;
    reg [1:0] state, state_n;
    reg [8*max_number_of_weight-1:0] pos_table;
    reg [8*max_number_of_weight-1:0] str_table;
    reg [DWIDTH*4-1:0] cur_address, cur_address_n;
    reg done_n;
    reg [7:0] cur_len;
    reg [8:0] weight_counting;
    reg [150*2+1:0] result_n;
    reg string_ready_n;
    
    always @(posedge clk) begin
        if(reset) begin
            result <= {151{2'd2}};
            alu <= {max_number_of_weight{1'b1}};
            en <= 0;
            state <= 0;
            pos <= 0;
            router_input <= {max_number_of_weight{8'd0}};
            done <= 0;
            cur_len <= 1;
            weight_counting <= 1;
            now_strlen <= 0;
            cur_address <= 0;
            string_ready <= 0;
            for(m=0;m<strlen;m=m+1) string[m] <= 8'd0;
        end
        else begin
            pos <= pos_next;
            state <= state_n;
            alu <= alu_n;
            en <= en_n;
            router_input <= router_input_n;    
            done <= done_n; 
            result <= result_n;
            cur_address <= cur_address_n;
            string_ready <= string_ready_n;
        end
    end
    
    always @(*) begin
        pos_next = pos;
        state_n = state;
        alu_n = alu;
        en_n = en;
        router_input_n = router_input;
        done_n = done;
        result_n = result;
        cur_address_n = cur_address;
        string_ready_n = 0;
        case (state)
            /*
            2'b00: begin
                state_n = weight_enable ? 1 : 0;
            end
            */
            2'b00: begin
                if(cur_address < buffer_size) begin
                    cur_address_n = cur_address_n == 0 ? 0 : cur_address_n + 1;
                    now_strlen = RAM[cur_address_n];
                    if(now_strlen<200) begin
                        for(i=0;i<now_strlen;i=i+1) begin
                            string[i] = RAM[cur_address_n+i+1];
                        end
                    end
                    else begin
                        for(i=0;i<200;i=i+1) begin
                            string[i] = RAM[cur_address_n+i+1];
                        end
                    end
                    cur_address_n = cur_address_n+now_strlen;
                    state_n = 2'b01;
                    string_ready_n = 1'b1;     
                end 
                else begin
                    state_n = 2'b00;
                end  
            end
            2'b01: begin
                if(weight_enable) begin
                    state_n = 2'b10;
                    router_input_n = weight;
                    pos_table = 0;
                    str_table = 0;
                    for(i = 1, k = max_number_of_weight; i <= weight_count; i = i+1) begin
                        for(j = cur_len; j <= len_arr[(max_number_of_weight-i+1)*8-1-:8] && k >= 0; j = j+1, k = k-1) begin
                            if(k == 0) begin
                                cur_len = j;
                                weight_counting = weight_counting - 1;
                            end
                            else begin
                                pos_table[k*8-1-:8] = j;
                                str_table[k*8-1-:8] = weight_counting;
                                cur_len = 1;
                            end
                        end
                        weight_counting = weight_counting + 1;
                    end
                end
            end
            2'b10: begin
                pos_next = pos == now_strlen ? pos : pos + 1;
                alu_n = {max_number_of_weight{1'b0}};
                en_n = {max_number_of_weight{1'b0}};
                if (pos < now_strlen) begin
                    for(i = max_number_of_weight; i > 0; i = i-1) begin
                        if(pos_table[i*8-1-:8] == 0) router_input_n[i*DWIDTH-1-:DWIDTH] <= 8'd0;
                        else if(pos + len_arr[(max_number_of_weight - (str_table[i*8-1-:8] - str_table[max_number_of_weight*8-1-:8]))*8-1-:8] > now_strlen) router_input_n[i*DWIDTH-1-:DWIDTH] <= 8'd0;
                        else if(pos + pos_table[i*8-1-:8] > now_strlen) router_input_n[i*DWIDTH-1-:DWIDTH] <= 8'd0;
                        //else if(result[str_table[i*8-1-:8]*2+:2] == 0) router_input_n[i*DWIDTH-1-:DWIDTH] <= 8'd0;
                        else begin
                            router_input_n[i*DWIDTH-1-:DWIDTH] <= string[(pos+(pos_table[i*8-1-:8]-1))];
                            en_n[i-1] = 1;
                        end
                    end
                end
                if (pos == now_strlen-1 || en_n == 0)begin
                    state_n = 2'b11;
                    done_n = 1'b1;
                    router_input_n = {max_number_of_weight{8'd0}};
                end
                
                for(j = 0; j < max_number_of_weight; j = j+1) begin
                    if (en[j]) begin
                        result_n[str_table[j*8+:8]*2+:2] = (result_n[str_table[j*8+:8]*2+:2] == 2'd2) ? router_output[j] : (result_n[str_table[j*8+:8]*2+:2] && router_output[j]);
                    end
                end
            end
            2'b11: begin
                state_n = string_finish ? 2'b00:2'b01;
                string_ready_n = 1'b0;
                done_n = 1'b0;
                pos_next = 0;
                router_input_n = {max_number_of_weight{8'd0}};
                en_n = 0;
                alu_n = {max_number_of_weight{1'b1}};
            end
        endcase
    end
    
    
endmodule