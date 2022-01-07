`timescale 1ns / 1ps

module tb();
    parameter DWIDTH = 8;
    parameter weight_max_length = 32;
    parameter in_strlen = 32;
    parameter strlen = 1500;
    parameter groups = 16;
    parameter num = 16;
    parameter max_number_of_weight = num*groups;
    //reg [in_strlen*DWIDTH-1:0] string;
    //reg [weight_max_length*DWIDTH-1:0] weight;
    reg clk;
    reg reset;
    wire [150*2+1:0] result;
    //reg  [DWIDTH-1:0] input_string [0:in_strlen-1];
    reg [100:0] counter;
    wire [0:1] result_arr [150:0];

    System_digit #(.DWIDTH(DWIDTH), .weight_max_length(weight_max_length), .strlen(strlen), .in_strlen(in_strlen),
    .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight)) test (
        //.string(string),
        //.weight(weight),
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    initial begin
        clk = 0;
        reset = 1;
        //$readmemh("input.mem", input_string); 

        #20
        reset = 0;
        counter = 0;
        //string = "71 104 48 115 116 11 10 11 12 61";
        /*
        for(i = 0; i < in_strlen; i = i+1) begin
            string[(in_strlen-i)*DWIDTH-1-:DWIDTH] = input_string[i];
        end
        */
        //weight = "5 71 104 48 115 116\n3 11 12 61";
    end
    always #10 clk = ~clk;

    always @(posedge clk) counter = counter + 1;

    genvar i;
    generate
        for(i = 0; i <= 150; i = i + 1) assign result_arr[i] = result[i*2+:2];
    endgenerate

endmodule