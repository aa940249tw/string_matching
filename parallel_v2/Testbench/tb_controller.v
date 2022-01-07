`timescale 1ns / 1ps

module tb_controller();
    parameter DWIDTH = 8,
              strlen = 6, 
              groups = 4, 
              num = 4, 
              max_number_of_weight = num*groups;
              
    reg clk;
    reg reset;
    reg weight_enable;
    reg string_enable;
    reg [num*groups*DWIDTH-1:0] weight;
    reg [strlen*DWIDTH-1:0] string;
    reg [max_number_of_weight*8-1:0] len_arr;
    reg [7:0] weight_count;
    wire [num*groups*DWIDTH-1:0] router_input;
    wire done;
    
    string_match #(.DWIDTH(DWIDTH), .strlen(strlen), .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight)) tb_con (
        .clk(clk),
        .reset(reset),
        .weight_enable(weight_enable),
        .string_enable(string_enable),
        .weight(weight),
        .string(string),
        .len_arr(len_arr),
        .weight_count(weight_count),
        .router_input(router_input),
        .done(done)
    );
    
    initial begin
        clk = 0;
        reset = 1;
        weight_enable = 0;
        string_enable = 0;
        
        #20
        reset = 0;
        weight_enable = 1;
        string_enable = 1;
        string = "47683073740b0a0b0c3d";
        weight = "47683073740b0a0b0c3d47683073740b";
        len_arr = {{21}, {(max_number_of_weight-1){8'd0}}};
        weight_count = 8'd1;
        
        #40
        weight_enable = 0;
        string_enable = 0;
        
        #220
        weight_enable = 1;
        string_enable = 1;
        string = "47683073740b0a0b0c3d";
        weight = "0102030405060708090a010200000000";
        len_arr = {{8'd21}, {8'd5}, {8'd2}, {(max_number_of_weight-3){8'd0}}};
        weight_count = 8'd3;
        
    end    
    
    always #10 clk = ~clk;   
    
endmodule
