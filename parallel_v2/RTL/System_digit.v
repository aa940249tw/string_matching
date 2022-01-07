`timescale 1ns / 1ps

module System_digit #(parameter DWIDTH = 8, weight_max_length = 32, in_strlen = 23, strlen = 10,
                                groups = 4, num = 4, max_number_of_weight = num*groups, total_weights = 100) 
    (
        //input [in_strlen*DWIDTH-1:0] string,
        //input [weight_max_length*DWIDTH-1:0] weight,
        input clk,
        input reset,
        output [150*2+1:0] result
    );
    
    //wire [strlen*DWIDTH-1:0] string_to_controller;
    wire [max_number_of_weight*DWIDTH-1:0] weight_cut;
    wire weight_enable, string_enable;
    wire [max_number_of_weight*DWIDTH-1:0] weight_length;
    wire [7:0] weight_count;
    wire [max_number_of_weight-1:0] router_to_controller;
    wire [max_number_of_weight*DWIDTH-1:0] controller_to_router;
    wire [max_number_of_weight-1:0] pe_alu;
    wire [max_number_of_weight-1:0] pe_en;
    wire [max_number_of_weight-1:0] controller_result;
    wire [max_number_of_weight-1:0] result_from_pe;
    wire [max_number_of_weight-1:0] to_pe_alu;
    wire [max_number_of_weight-1:0] to_pe_en;
    wire [max_number_of_weight*DWIDTH-1:0] router_to_pe;
    wire signal_from_controller;
    wire string_finish;
    wire string_ready;
    
    
    string_match #(.DWIDTH(DWIDTH), .strlen(strlen), .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight)) controller (
        .clk(clk),
        .reset(reset),
        .weight_enable(weight_enable),
        .string_finish(string_finish),
        //.string_enable(string_enable),
        .weight(weight_cut),
        //.string(string_to_controller),
        .router_output(router_to_controller),
        .len_arr(weight_length),
        .weight_count(weight_count),
        .router_input(controller_to_router),
        .alu(pe_alu),
        .en(pe_en),
        .result(result),
        .done(signal_from_controller),
        .string_ready(string_ready)
    );
    
    /*
    weight_cut_digit #(.DWIDTH(DWIDTH), .weight_max_length(weight_max_length), .max_number_of_weight(max_number_of_weight)) cut(
        .clk(clk),
        .reset_n(reset),
        .enable(1),
        .weight(weight),
        .weight_cut(weight_cut),
        .weight_enable(weight_enable),
        .weight_length(weight_length),
        .weight_count(weight_count)
    );
    */
    
    weight_cut_ver2 #(.DWIDTH(DWIDTH), .weight_max_length(weight_max_length), .max_number_of_weight(max_number_of_weight), .buffer_size()) cut(
        .clk(clk),
        .reset(reset),
        .enable(1),
        .string_ready(string_ready),
        .signal_from_controller(signal_from_controller),
        .weight_cut(weight_cut),
        .weight_enable(weight_enable),
        .weight_length(weight_length),
        .weight_count(weight_count),
        .string_finish(string_finish)
    );
    
    /*
    string_preprocess #(.DWIDTH(DWIDTH), .in_strlen(in_strlen), .out_strlen(strlen)) preprocess (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in_string(string),
        .out_string(string_to_controller),
        .string_en(string_enable),
        .signal_from_controller(signal_from_controller)
    );
    */
    
    generate 
        genvar i, j;
        for(i = 0; i < num*groups; i = i+1) begin: group_pes
            PE #(.DWIDTH(DWIDTH)) pe (
                .clk(clk),
                .reset(reset),
                .en(to_pe_en[(i/num)*num + i%num]),
                .ALU_op(to_pe_alu[(i/num)*num + i%num]),
                .in_char(router_to_pe[((i/num)*num + i%num)*DWIDTH+:DWIDTH]),
                .out_down(result_from_pe[((i/num)*num + i%num)])
            );
        end
        for(j = 0; j < groups; j = j+1) begin: group_routers
            router #(.DWIDTH(DWIDTH), .num(num)) routers (
                .str_arr(controller_to_router[j*num*DWIDTH+:num*DWIDTH]),
                .ALU(pe_alu[j*num+:num]),
                .en(pe_en[j*num+:num]),
                .result_from_pe(result_from_pe[j*num+:num]),
                .result(router_to_controller[j*num+:num]),
                .ALU_to_pe(to_pe_alu[j*num+:num]),
                .en_to_pe(to_pe_en[j*num+:num]),
                .str_to_pe(router_to_pe[j*num*DWIDTH+:num*DWIDTH])
            );
        end
    endgenerate
endmodule