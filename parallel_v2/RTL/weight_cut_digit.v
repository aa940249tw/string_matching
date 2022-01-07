`timescale 1ns / 1ps

module weight_cut_digit #(
        parameter DWIDTH=8,
        parameter weight_max_length=32,
        parameter max_number_of_weight=16
    )
    (
        input clk,
        input reset_n,
        input enable,
        input [weight_max_length*DWIDTH-1:0] weight,
        output reg [max_number_of_weight*DWIDTH-1:0] weight_cut,
        output reg weight_enable,
        output reg [max_number_of_weight*8-1:0] weight_length,
        output reg [7:0] weight_count
    );
    reg [8:0] clk_count,count,space_count;
    reg [8:0] weight_reg;
    reg signed [8:0] i,j,weight_idx;
    always@(posedge clk) begin
        if(reset_n || ~enable) begin
            weight_idx <= weight_max_length-1;
            weight_enable <= 0;
            weight_count <= 0;
            clk_count <= 0;
            weight_length <= 0;
            count <= max_number_of_weight-1;
            space_count <= 0;
            weight_cut <= 0;
            weight_reg <= 0;
        end
        else begin
            if(clk_count == 0) begin
                clk_count <= clk_count + 1;
                //weight_reg <= weight[18*DWIDTH+:DWIDTH]-48 + weight_reg*10;
                for(j=weight_max_length-1;j>=0;j=j-1)begin
                    weight_reg = 0;
                    if(weight[j*DWIDTH+:DWIDTH]=="\n")begin
                        for(i=weight_idx;i>j;i=i-1) begin
                            weight_reg = (weight[i*DWIDTH+:DWIDTH]-48) + weight_reg * 10;
                            //weight_cut[(count+i-weight_idx)*DWIDTH+:DWIDTH] = weight[i*DWIDTH+:DWIDTH];
                        end
                        weight_cut[count*DWIDTH+:DWIDTH] = weight_reg;
                        count = count - 1; 
                        space_count = 0;  
                        //weight_length[weight_count*8+:8] = j-weight_idx;
                        weight_count = weight_count + 1;
                        weight_idx = j - 1;    
                    end
                    else if(weight[j*DWIDTH+:DWIDTH]==" ") begin  
                        if(space_count != 0) begin                    
                            for(i=weight_idx;i>j;i=i-1) begin
                                weight_reg = (weight[i*DWIDTH+:DWIDTH]-48) + weight_reg * 10;
                                //weight_cut[(count+i-weight_idx)*DWIDTH+:DWIDTH] = weight[i*DWIDTH+:DWIDTH];
                            end
                            weight_cut[count*DWIDTH+:DWIDTH] = weight_reg;
                            count = count - 1;   
                            //weight_length[weight_count*8+:8] = j-weight_idx;
                            //if(j-weight_idx != 0) weight_count = weight_count + 1;
                            weight_idx = j - 1;
                        end
                        else begin
                            for(i=weight_idx;i>j;i=i-1) begin
                                weight_reg = (weight[i*DWIDTH+:DWIDTH]-48) + weight_reg * 10;
                                //weight_cut[(count+i-weight_idx)*DWIDTH+:DWIDTH] = weight[i*DWIDTH+:DWIDTH];
                            end
                            weight_length[(max_number_of_weight-weight_count-1)*8+:8] = weight_reg;
                            weight_idx = j - 1;     
                         end 
                         space_count = space_count + 1;                        
                    end
                    else if(weight[j*DWIDTH+:DWIDTH]==8'd0) begin
                        if(weight_idx-j!=0) begin                     
                            for(i=weight_idx;i>j;i=i-1) begin
                                weight_reg = (weight[i*DWIDTH+:DWIDTH]-48) + weight_reg * 10;
                                //weight_cut[(count+i-weight_idx)*DWIDTH+:DWIDTH] = weight[i*DWIDTH+:DWIDTH];
                            end
                            weight_cut[count*DWIDTH+:DWIDTH] = weight_reg;
                            count = count - 1;   
                            //weight_length[weight_count*8+:8] = j-weight_idx;
                            //if(j-weight_idx != 0) weight_count = weight_count + 1;
                            weight_idx = j - 1;
                        end
                        else weight_idx = j - 1;    
                    end
                end
                for(i=weight_idx;i>j;i=i-1) begin
                    weight_reg = (weight[i*DWIDTH+:DWIDTH]-48) + weight_reg * 10;
                    //weight_cut[(count+i-weight_idx)*DWIDTH+:DWIDTH] = weight[i*DWIDTH+:DWIDTH];
                end
                weight_cut[count*DWIDTH+:DWIDTH] = weight_reg;
                count = count - 1; 
                weight_count = weight_count + 1;  
                weight_idx = j - 1;
            end
            else weight_enable <= 1;
        end
    end
endmodule
