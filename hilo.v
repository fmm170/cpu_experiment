`timescale 1ns / 1ps



module hilo_reg(
    input wire clk, 
    input wire rst,
    input wire we,
    input wire [31:0] hi_rdata,
    input wire [31:0] lo_rdata,
    output reg [31:0] hi_data1,
    output reg [31:0] lo_data1
    );
    always @(posedge clk) begin
        if (rst) begin
            hi_data1<=32'b0;
            lo_data1<=32'b0;
        end
        else if (we ==1'b1)begin
            hi_data1 <= hi_rdata;
            lo_data1 <= lo_rdata;
        end
     end     
endmodule
