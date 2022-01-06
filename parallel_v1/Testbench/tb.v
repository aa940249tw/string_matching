`timescale 1ns / 1ps

module tb();
    parameter DWIDTH = 8;
    parameter weight_num = 20;
    parameter strlen = 50;
    parameter groups = 4;
    parameter num = 4;
    parameter max_number_of_weight = num*groups; 
    
    reg clk;
    reg reset;
    
    system #(.DWIDTH(DWIDTH), .strlen(strlen), .num(num), .groups(groups), 
             .max_number_of_weight(max_number_of_weight), .weight_num(weight_num))  test (
        .clk(clk),
        .reset(reset)               
    );
    
    initial begin
        clk = 0;
        reset = 1;
        
        #20
        reset = 0;
    end
    
    always #10 clk = ~clk;
    
endmodule
