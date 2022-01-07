`timescale 1ns / 1ps

module input_controller #(parameter DWIDTH = 8, strlen = 100, groups = 16, num = 16, max_number_of_weight = num*groups,
                                    weight_num = 23331, string_num = 25, queue_buffer = max_number_of_weight*3) 
    (
        input clk,
        input reset,    
        input [max_number_of_weight-1:0] router_output,
        output reg [max_number_of_weight*DWIDTH-1:0] router_input,
        output reg [max_number_of_weight-1:0] alu,
        output reg [max_number_of_weight-1:0] en,
        output reg [weight_num-1:0] result,
        output reg done
    );
    
    reg [DWIDTH-1:0] weights [0:1000000];
    reg [DWIDTH-1:0] strings [0:1000000];
    reg [DWIDTH*2:0] strings_len [0:string_num];
    reg [DWIDTH*2:0] weights_len [0:weight_num];
    
    initial begin
        $readmemh("weight.mem", weights);
        $readmemh("input.mem", strings);
        $readmemh("str_len.mem", strings_len);
        $readmemh("w_len.mem", weights_len);
    end
    
    reg [DWIDTH*2-1:0] match_queue [0:queue_buffer-1];
    reg [24:0] queue_size, queue_size_n, old_size, old_size_n, new_size, new_size_n;
    reg [2:0] state, state_n;
    reg [max_number_of_weight*DWIDTH-1:0] router_input_n;
    reg [max_number_of_weight-1:0] en_n;
    reg [max_number_of_weight-1:0] alu_n;
    reg [weight_num-1:0] result_n;
    reg [DWIDTH*2-1:0] cur_weight_num, cur_weight_num_n;
    reg [DWIDTH-1:0] cur_string_num, cur_string_num_n;
    reg [strlen*DWIDTH-1:0] string;
    reg signed [24:0] i, j;
    reg signed [24:0] a, b;
    reg [7:0] pos, pos_n;
    
    always @(posedge clk) begin
        if(reset) begin
            router_input <= {max_number_of_weight{8'd0}};
            alu <= 0;
            en <= 0;
            result <= 0;
            cur_weight_num <= 0;
            cur_string_num <= 0;
            pos <= 0;
            queue_size <= 0;
            old_size <= 0;
            new_size <= 0;
            done <= 0;
            state <= 0;
            for(a = 0; a < queue_buffer; a = a+1) match_queue[a] <= 0;
            string <= 0;
        end
        else begin
            router_input <= router_input_n;
            alu <= alu_n;
            en <= en_n;
            result <= result_n; 
            cur_weight_num <= cur_weight_num_n;
            cur_string_num <= cur_string_num_n;
            queue_size <= queue_size_n;
            old_size <= old_size_n;
            new_size <= new_size_n;
            state <= state_n;
            pos <= pos_n;
            if(state == 3'b011) begin
                for(a = ((queue_size > max_number_of_weight) ? max_number_of_weight : queue_size) , b = 0; b < queue_buffer; a = a+1, b = b+1) begin
                    match_queue[b] <= (b < queue_size_n) ? match_queue[a] : 0;
                end
            end
            else if(state_n == 3'b001) for(a = 0; a < queue_buffer; a = a+1) match_queue[a] <= 0;
        end
    end
    
    always @(*) begin
        router_input_n = router_input;
        alu_n = alu;
        en_n = en;
        state_n = state;
        cur_string_num_n = cur_string_num;
        cur_weight_num_n = cur_weight_num;
        queue_size_n = queue_size;
        old_size_n = old_size;
        new_size_n = new_size;
        result_n = result;
        pos_n = pos;
        case(state)
            3'b000: begin // Initialize, Switch String
                result_n = 0;
                router_input_n = 0;
                string = 0;
                if(cur_string_num < string_num) begin
                    for(i = strings_len[cur_string_num]; i < strings_len[cur_string_num+1]; i = i+1) begin
                        string[(i-strings_len[cur_string_num])*DWIDTH+:DWIDTH] = strings[i];
                    end
                    cur_weight_num_n = 0;
                    state_n = 3'd1;
                end
                else done = 1;
            end
            3'b001: begin // Push start state to stack, prepare first string input
                en_n = 0;
                router_input_n = 0;
                queue_size_n = 0;
                alu_n = {max_number_of_weight{1'b1}};
                for(i = 0; i < max_number_of_weight; i = i+1) begin
                    router_input_n[i*DWIDTH+:DWIDTH] = string[0+:DWIDTH];
                end
                pos_n = 1;
                for(j = 0; j < max_number_of_weight && cur_weight_num+j < weight_num; j = j+1) begin
                    match_queue[j][DWIDTH*2-1-:DWIDTH] = j;
                    match_queue[j][0+:DWIDTH] = 8'd1;
                    queue_size_n = queue_size_n + 1;
                end
                old_size_n = queue_size_n;
                new_size_n = 0;
                state_n = 3'd2;
            end
            3'b010: begin // Prepare stack weight
                en_n = 0;
                alu_n = 0;
                router_input_n = 0;
                
                for(i = 0; i < queue_size && i < max_number_of_weight; i = i+1) begin
                    en_n[i] = 1;
                    router_input_n[i*DWIDTH+:DWIDTH] = weights[weights_len[cur_weight_num + match_queue[i][DWIDTH*2-1-:DWIDTH]] + match_queue[i][0+:DWIDTH] - 1];
                end
                
                state_n = 3'd3;
            end
            3'b011: begin // Prepare string, check pe result
                en_n = 0;
                alu_n = {max_number_of_weight{1'b1}};
                router_input_n = 0;
                
                for(j = 0; j < queue_size && j < max_number_of_weight; j = j+1) begin
                    if(old_size_n == 0) begin
                        old_size_n = new_size_n - 1;
                        new_size_n = 0;
                    end
                    else begin
                        old_size_n = old_size_n - 1;
                    end
                    // Just Push first state
                    if(match_queue[j][0+:DWIDTH] == 1) begin
                        match_queue[queue_size_n][DWIDTH*2-1-:DWIDTH] = match_queue[j][DWIDTH*2-1-:DWIDTH];
                        match_queue[queue_size_n][0+:DWIDTH] = match_queue[j][0+:DWIDTH];
                        queue_size_n = queue_size_n + 1;
                        new_size_n = new_size_n + 1;
                    end
                    //Check output of the router
                    if(router_output[j]) begin
                        if(match_queue[j][0+:DWIDTH]+1 > weights_len[match_queue[j][DWIDTH*2-1-:DWIDTH]+1+cur_weight_num] - weights_len[match_queue[j][DWIDTH*2-1-:DWIDTH]+cur_weight_num]) 
                            result_n[match_queue[j][DWIDTH*2-1-:DWIDTH] + cur_weight_num] = 1;
                        else begin
                            match_queue[queue_size_n][DWIDTH*2-1-:DWIDTH] = match_queue[j][DWIDTH*2-1-:DWIDTH];
                            match_queue[queue_size_n][0+:DWIDTH] = match_queue[j][0+:DWIDTH]+1;
                            queue_size_n = queue_size_n + 1;
                            new_size_n = new_size_n + 1;
                        end
                    end
                end
                queue_size_n = queue_size_n - j;
                
                if(pos == (strings_len[cur_string_num+1]-strings_len[cur_string_num]-1) || queue_size_n == 0) begin
                    if(cur_weight_num + max_number_of_weight > weight_num) begin
                        state_n = 3'd0;
                        cur_string_num_n = cur_string_num + 1;
                    end
                    else begin
                        state_n = 3'd1;
                        cur_weight_num_n = cur_weight_num + max_number_of_weight;                        
                    end
                end
                else begin
                    if(old_size_n < max_number_of_weight) begin
                        for(i = 0; i < max_number_of_weight && i < queue_size; i = i+1) begin
                            if(i < old_size_n) router_input_n[i*DWIDTH+:DWIDTH] = string[(pos-1)*DWIDTH+:DWIDTH];
                            else router_input_n[i*DWIDTH+:DWIDTH] = string[pos*DWIDTH+:DWIDTH];
                        end
                        pos_n = pos + 1;
                        state_n = 3'd2;
                    end
                    else begin
                        for(i = 0; i < max_number_of_weight; i = i+1) begin
                            en_n[i] = 1;
                            alu_n[i] = 0;
                            router_input_n[i*DWIDTH+:DWIDTH] = weights[weights_len[cur_weight_num + match_queue[i+max_number_of_weight][DWIDTH*2-1-:DWIDTH]] 
                                                                       + match_queue[i+max_number_of_weight][0+:DWIDTH] - 1];
                        end
                        state_n = 3'd3;
                    end
                end
            end
            ///////////////////////////////////////////////////////////////////////////////////
            /*
            3'b100: begin
                en_n = 0;
                alu_n = 0;
                router_input_n = 0;
                
                for(i = 0; i < queue_size && i < max_number_of_weight; i = i+1) begin
                    en_n[i] = 1;
                    router_input_n[i*DWIDTH+:DWIDTH] = weights[weights_len[cur_weight_num + match_queue[i][DWIDTH*2-1-:DWIDTH]] + match_queue[i][0+:DWIDTH] - 1];
                end
                
                for(j = 0; j < temp_size && queue_size_n < queue_buffer; j = j+1) begin
                    if(router_output[j]) begin
                        if(match_queue[j][0+:DWIDTH]+1 > weights_len[match_queue[j][DWIDTH*2-1-:DWIDTH]+1+cur_weight_num] - weights_len[match_queue[j][DWIDTH*2-1-:DWIDTH]+cur_weight_num]) 
                            result_n[match_queue[j][DWIDTH*2-1-:DWIDTH] + cur_weight_num] = 1;
                        else begin
                            match_queue[queue_size_n][DWIDTH*2-1-:DWIDTH] = match_queue[j][DWIDTH*2-1-:DWIDTH];
                            match_queue[queue_size_n][0+:DWIDTH] = match_queue[j][0+:DWIDTH]+1;
                            queue_size_n = queue_size_n + 1;
                        end
                    end
                end
                temp_size_n = 0;
                queue_size_n = queue_size_n - temp_size;
                
                if(queue_size >= 2 * max_number_of_weight) begin
                    state_n = 3'd4;
                    temp_size_n = max_number_of_weight;
                end
                else begin
                    state_n = 3'd3;
                    temp_size_n = queue_size > max_number_of_weight ? max_number_of_weight : queue_size;
                end
            end
            */
        endcase
    end
    
endmodule
