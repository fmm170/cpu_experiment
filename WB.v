`include "lib/defines.vh"
module WB(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    

    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    


  
    output wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    output wire [37:0] wb_to_id,
    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [31:0] lo_rdata,
    output wire [31:0] hi_rdata,
    output wire  hilo_e, 
    input wire [64:0] mem_to_wb_hilo,
    output wire [64:0] wb_to_id_hilo
);

    reg [`MEM_TO_WB_WD-1:0] mem_to_wb_bus_r;
    reg[64:0] mem_to_wb_hilo_r;
    
    wire [31:0] wb_lo_rdata;
    wire [31:0] wb_hi_rdata;
    wire wb_we_hilo;
    
    assign {
        wb_we_hilo , 
        wb_hi_rdata , 
        wb_lo_rdata
    } = mem_to_wb_hilo;
    
    always @ (posedge clk) begin
        if (rst) begin
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
            mem_to_wb_hilo_r <= 65'b0;
        end
        // else if (flush) begin
        //     mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        // end
        else if (stall[4]==`Stop && stall[5]==`NoStop) begin
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
            mem_to_wb_hilo_r <= 65'b0;
        end
        else if (stall[4]==`NoStop) begin
            mem_to_wb_bus_r <= mem_to_wb_bus;
            mem_to_wb_hilo_r <= mem_to_wb_hilo;
        end
    end
   
   assign {
       hilo_e,
       hi_rdata,
       lo_rdata
   } = mem_to_wb_hilo_r;
   
   assign wb_to_id_hilo = mem_to_wb_hilo_r;

    wire [31:0] wb_pc;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;

    assign {
        wb_pc,
        rf_we,
        rf_waddr,
        rf_wdata
    } = mem_to_wb_bus_r;

    // assign wb_to_rf_bus = mem_to_wb_bus_r[`WB_TO_RF_WD-1:0];
    assign wb_to_rf_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };
    
    assign wb_to_id = {
        rf_we,
        rf_waddr,
        rf_wdata
    };

    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = {4{rf_we}};
    assign debug_wb_rf_wnum = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;

    
endmodule