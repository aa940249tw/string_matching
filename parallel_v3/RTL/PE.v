`timescale 1ns / 1ps

module PE #(parameter DWIDTH = 8)(
        input clk,
        input reset,
        input en,
        input [1:0] ALU_op,
        input [DWIDTH-1:0] in_char,
        output reg out_down
    );
    
    reg [DWIDTH-1:0] weight_reg, string_reg;
    
    always @(*) begin
        if (ALU_op == 0) begin
            weight_reg = in_char;
        end
        else if (ALU_op == 1) begin
            string_reg = in_char;
        end
    end
    
    always @(posedge clk) begin
        if(reset) begin
            out_down <= 1'b0;
            weight_reg <= 8'd0;
            string_reg <= 8'd0;
        end
    end
    
    always @(negedge clk) begin
        if(en) begin
            if (ALU_op == 2) out_down <= (string_reg == in_char) ? 1 : 0;
            else out_down <= (weight_reg == string_reg) ? 1 : 0;
        end
        else out_down <= 0;
    end
    
endmodule
