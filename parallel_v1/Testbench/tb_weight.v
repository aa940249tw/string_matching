`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2021 08:50:45 PM
// Design Name: 
// Module Name: tb_weight
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_weight;
    parameter DWIDTH = 8;
    parameter weight_num = 23331;
    parameter strlen = 150;
    parameter groups = 4;
    parameter num = 4;
    parameter max_number_of_weight = num*groups;   
    parameter buffer_size = 370128;
    
    reg clk;
    reg reset;
    reg enable;
    reg [num:0] signal_from_controller;
    reg string_ready;
    wire [max_number_of_weight*DWIDTH-1:0] weight_cut;
    wire weight_enable;
    wire string_finish;
    weight_cut #(.DWIDTH(DWIDTH), .strlen(strlen), .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight), .weight_num(weight_num), .buffer_size(buffer_size))
    test(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .signal_from_controller(signal_from_controller),
        .string_ready(string_ready),
        .weight_cut(weight_cut),
        .weight_enable(weight_enable),
        .string_finish(string_finish)
    );
    
    initial begin
        clk = 0;
        reset = 1;
        
        #20
        reset = 0;
        enable = 0;
        signal_from_controller = 5'b00000;
        string_ready=1;
        #20
        enable = 1;
        signal_from_controller = 5'b10000;
    end

    always #10 clk = ~clk;

endmodule
