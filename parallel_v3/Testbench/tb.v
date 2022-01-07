`timescale 1ns / 1ps

module tb();
    parameter DWIDTH = 8;
    parameter weight_num = 23331;
    parameter string_num = 25;
    parameter strlen = 150;
    parameter groups = 4;
    parameter num = 4;
    parameter max_number_of_weight = num*groups;   
    
    reg clk;
    reg reset;
    wire [weight_num-1:0] result;
    
    System #(.DWIDTH(DWIDTH), .weight_num(weight_num), .string_num(string_num), .strlen(strlen),
             .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight)) test (
        .clk(clk),
        .reset(reset),
        .result(result)
    );
    
    initial begin
        clk = 0;
        reset = 1;
        
        #20
        reset = 0;
    end
    
    always #10 clk = ~clk;

endmodule
