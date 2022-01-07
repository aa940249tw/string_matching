`timescale 1ns / 1ps

module router #(parameter DWIDTH = 8, num = 4) (
        //input clk,
        //input reset, 
        input [num*DWIDTH-1:0] str_arr,
        input [num-1:0] ALU,
        input [num-1:0] en,
        input [num-1:0] result_from_pe,
        output [num-1:0] result,
        output [num-1:0] ALU_to_pe,
        output [num-1:0] en_to_pe,
        output [num*DWIDTH-1:0] str_to_pe
    );
    
    assign ALU_to_pe = ALU;
    assign en_to_pe = en;
    assign str_to_pe = str_arr;
    assign result = result_from_pe;
    
endmodule
