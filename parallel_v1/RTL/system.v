`timescale 1ns / 1ps

module system #(parameter DWIDTH = 8, groups = 4, num = 4, max_number_of_weight = num*groups, strlen = 200, weight_num = 23331) 
    (
       input clk,
       input reset 
    );
    
    wire [max_number_of_weight-1:0] router_to_controller;
    wire [max_number_of_weight*DWIDTH-1:0] controller_to_router;
    wire [2*max_number_of_weight-1:0] pe_alu;
    wire [max_number_of_weight-1:0] pe_en;
    
    generate
        genvar a, b;
        for(a = 0; a < groups; a = a+1) begin: router_to_pe
            wire [num-1:0] alu;
            wire [num-1:0] en;
            wire [num*DWIDTH-1:0] in_char;
        end
        for(b = 0; b < groups; b = b+1) begin: pe_to_router
            wire [num-1:0] result;
        end
    endgenerate
    
    wire weight_enable;
    wire string_finish;
    wire string_ready;
    wire [max_number_of_weight*DWIDTH-1:0] weight_cut;
    wire [max_number_of_weight-1:0] router_to_controller;
    wire [max_number_of_weight*DWIDTH-1:0] controller_to_router;
    wire [max_number_of_weight-1:0] pe_alu;
    wire [max_number_of_weight-1:0] pe_en;
    wire [num:0] signal_from_controller;
    
    input_controller #(.DWIDTH(DWIDTH), .strlen(strlen), .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight)) controller (
        .clk(clk),
        .reset(reset),
        .weight_enable(weight_enable),
        .string_finish(string_finish),
        .weight(weight_cut),
        .router_output(router_to_controller),
        .router_input(controller_to_router),
        .alu(pe_alu),
        .en(pe_en),
        .done(signal_from_controller),
        .string_ready(string_ready)
    );
    
    weight_cut #(.DWIDTH(DWIDTH), .groups(groups), .num(num), .max_number_of_weight(max_number_of_weight), 
                 .weight_num(weight_num)) cut (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .signal_from_controller(signal_from_controller),
        .string_ready(string_ready),
        .weight_cut(weight_cut),
        .weight_enable(weight_enable),
        .string_finish(string_finish)
    );
    
    generate
        genvar i, j;
        for(i = 0; i < num*groups; i = i+1) begin: group_pes
            PE #(.DWIDTH(DWIDTH)) pe (
                .clk(clk),
                .reset(reset),
                .en(router_to_pe[i/num].en[i%num]),
                .ALU_op(router_to_pe[i/num].alu[i%num]),
                .in_char(router_to_pe[i/num].in_char[i%num*DWIDTH+:DWIDTH]),
                .out_down(pe_to_router[i/num].result[i%num])
            );
        end
        for(j = 0; j < groups; j = j+1) begin: group_routers
            router #(.DWIDTH(DWIDTH), .num(num)) routers (
                .str_arr(controller_to_router[j*num*DWIDTH+:num*DWIDTH]),
                .ALU(pe_alu[j*num+:num]),
                .en(pe_en[j*num+:num]),
                .result_from_pe(pe_to_router[j].result),
                .result(router_to_controller[j*num+:num]),
                .ALU_to_pe(router_to_pe[j].alu),
                .en_to_pe(router_to_pe[j].en),
                .str_to_pe(router_to_pe[j].in_char)
            );
        end
    endgenerate
endmodule
