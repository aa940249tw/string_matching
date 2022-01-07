`timescale 1ns / 1ps

module result #(parameter DWIDTH = 8, num = 4, groups = 4, max_number_of_weight = num*groups, total_weights = 100)(
        input clk,
        input reset,
        input [max_number_of_weight-1:0] router_output,
        input [DWIDTH*max_number_of_weight-1:0] str_table,
        input signal_from_controller,
        output reg [total_weights:0] string_results
    );
    
    reg state, state_n;
    reg [total_weights-1:0] string_results_n;
    reg [4:0] i;
    
    always @(*) begin
        state_n = state;
        string_results_n = string_results;
        if(signal_from_controller) begin
            for(i = 0; i < max_number_of_weight; i = i+1) begin
                string_results_n[str_table[i]] = string_results_n[str_table[i]] && router_ouput[i];
            end
        end
    end
    
    always @(posedge clk) begin
        if(reset) begin
            state <= 0;
            string_results <= 1;
        end
        else begin
            state <= state_n;
            string_results <= string_results_n;
        end
    end
endmodule
