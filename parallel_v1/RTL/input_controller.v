`timescale 1ns / 1ps

module input_controller #(parameter DWIDTH = 8, strlen = 100, groups = 4, num = 4, max_number_of_weight = num*groups, buffer_size=1032)(
        input clk,
        input reset,
        input weight_enable,
        input string_finish,
        input [max_number_of_weight*DWIDTH-1:0] weight,
        input [max_number_of_weight-1:0] router_output,
        output reg [max_number_of_weight*DWIDTH-1:0] router_input,
        output reg [max_number_of_weight-1:0] alu,
        output reg  [max_number_of_weight-1:0] en,
        output reg [num:0] done,
        output reg string_ready
    );
    
    reg [DWIDTH-1:0] RAM [0:buffer_size-1];
    reg [strlen*DWIDTH-1:0] string;
    reg [DWIDTH-1:0] now_strlen;
    
    initial begin
        $readmemh("test_input.mem", RAM);
    end
    
    reg [7:0] pos, pos_n;
    reg [max_number_of_weight-1:0] en_n;
    reg [max_number_of_weight-1:0] alu_n;
    reg [max_number_of_weight*DWIDTH-1:0] router_input_n;
    reg [1:0] state, state_n;
    reg [16:0] i, j;
    reg [23:0] cur_address, cur_address_n;
    reg string_ready_n;
    reg [num:0] done_n;
    
    
    always @(posedge clk) begin
        if(reset) begin
            pos <= 0;
            state <= 0;
            alu <= 0;
            en <= 0;
            router_input <= 0;
            done <= 0;
            cur_address <= 0;
            string <= 0;
            string_ready <= 0;
        end
        else begin
            pos <= pos_n;
            state <= state_n;
            en <= en_n;
            alu <= alu_n;
            router_input <= router_input_n;
            done <= done_n;
            cur_address <= cur_address_n;
            string_ready <= string_ready_n;
        end
    end
    
    always @(*) begin
        pos_n = pos;
        state_n = state;
        alu_n = 0;
        en_n = 0;
        router_input_n = 0;
        done_n = done;
        string_ready_n = 0;
        cur_address_n = cur_address;
        case (state)
            2'b00: begin
                if(cur_address < buffer_size) begin
                    cur_address_n = cur_address_n == 0 ? 0 : cur_address_n + 1;
                    now_strlen = RAM[cur_address_n];
                    if(now_strlen<200) begin
                        for(i=0;i<now_strlen;i=i+1) begin
                            string[i*DWIDTH+:DWIDTH] = RAM[cur_address_n+i+1];
                        end
                    end
                    else begin
                        for(i=0;i<200;i=i+1) begin
                            string[i*DWIDTH+:DWIDTH] = RAM[cur_address_n+i+1];
                        end
                    end
                    cur_address_n = cur_address_n+now_strlen;
                    state_n = 2'b01;
                    string_ready_n = 1'b1; 
                    done_n = 5'b10000;  
                end
                else state_n = 2'b00;
            end
            2'b01: begin
                pos_n = 0;
                done_n = 0;
                if(weight_enable) begin
                    alu_n = {max_number_of_weight{1'b1}};
                    en_n = 0;
                    state_n = 2'd2;
                    router_input_n = weight;
                end
            end
            2'b10: begin
                pos_n = (pos+num == now_strlen-1) ? pos : pos + 1;
                if(pos < now_strlen) begin
                    for(i = 0; i < num; i = i+1) begin
                        if(done[i] == 0) begin
                            en_n[i*num+:num] = {num{1'b1}};
                            router_input_n[i*DWIDTH*num+:num*DWIDTH] = string[pos*DWIDTH+:num*DWIDTH];
                        end 
                    end
                end
                if (pos+num == now_strlen-1 || en_n == 0)begin
                    state_n = string_finish ? 2'b00:2'b01;
                    done_n[num] = 1'b1;
                    router_input_n = 0;
                end
                
                for(j = 0; j < num; j = j+1) begin
                    if(router_output[j*num+:num] == {num{1'b1}}) begin
                        done_n[j] = 1'b1;
                    end
                end
            end
        endcase
    end
    
endmodule
