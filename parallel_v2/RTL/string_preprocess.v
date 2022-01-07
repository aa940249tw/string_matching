`timescale 1ns / 1ps

module string_preprocess #(parameter DWIDTH = 8, out_strlen = 10, in_strlen = 32) (
        input [in_strlen*DWIDTH-1:0] in_string,
        input clk,
        input reset,
        input enable,
        input signal_from_controller,
        output reg [out_strlen*DWIDTH-1:0] out_string,
        output reg string_en
    );
    
    reg [out_strlen*DWIDTH-1:0] out_string_n;
    reg string_en_n;
    reg [DWIDTH-1:0] string_reg;
    reg signed [8:0] i, j ;
    reg [7:0] count;
    reg [1:0] state, state_n;
    
    always @(posedge clk) begin
        if(reset || ~enable) begin
            out_string <= {out_strlen*DWIDTH{8'd00}};
            string_en <= 0;
            string_reg <= 0;
            state <= 0;
        end
        else begin
            out_string <= out_string_n;
            string_en <= string_en_n;
            state <= state_n;
        end
    end
    
    always @(*) begin
        out_string_n = out_string;
        string_en_n = string_en;
        state_n = state;
        case (state)
            2'b00: begin
                out_string_n = 0;
                count = out_strlen;
                for(j = in_strlen-1, i = j; j >= 0; j = j-1) begin
                    if(in_string[j*DWIDTH+:DWIDTH] == " " || j == 0) begin
                        string_reg = 0;
                        while(i > j || (j == 0 && i >= j)) begin
                            string_reg = (in_string[i*DWIDTH+:DWIDTH]-48) + string_reg * 10;
                            i = i-1;
                        end
                        out_string_n[count*DWIDTH-1-:DWIDTH] = string_reg;
                        i = j-1;
                        count = count ? count-1 :  0;
                    end
                end
                string_en_n = 1;
                state_n = 2'b01;
            end
            2'b01: begin
                string_en_n = signal_from_controller ? 0 : 1;
                state_n = signal_from_controller ? 2'b00 : 2'b01;
            end
       endcase
    end
endmodule
