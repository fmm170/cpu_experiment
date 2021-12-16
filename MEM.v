`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    output wire [37:0] mem_to_id,
    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus, 
    input wire [64:0] ex_to_mem_hilo, 
    output wire [64:0] mem_to_wb_hilo,
    output wire [64:0] mem_to_id_hilo
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;
    reg [64:0] mem_to_wb_hilo_r;
    
    wire [31:0] mem_lo_rdata;
    wire [31:0] mem_hi_rdata;
    wire mem_we_hilo;
    
    assign {
        mem_we_hilo , 
        mem_hi_rdata , 
        mem_lo_rdata
    }=  ex_to_mem_hilo;
    
    
    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            mem_to_wb_hilo_r <= 65'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            mem_to_wb_hilo_r <= 65'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
            mem_to_wb_hilo_r <= ex_to_mem_hilo ;
        end
    end

   assign mem_to_wb_hilo= mem_to_wb_hilo_r;
   assign mem_to_id_hilo= mem_to_wb_hilo_r;
   
    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    wire [3:0] data_ram_ren;

    assign {
        data_ram_ren, //79:76
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;



//    assign mem_result =  data_sram_rdata ;

    assign mem_result =   (data_ram_ren==4'b1111 && data_ram_en==1'b1) ? data_sram_rdata :
                          (data_ram_ren==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{24{data_sram_rdata[7]}},data_sram_rdata[7:0]}) :
                          (data_ram_ren==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({{24{data_sram_rdata[15]}},data_sram_rdata[15:8]}) :
                          (data_ram_ren==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}) :
                          (data_ram_ren==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({{24{data_sram_rdata[31]}},data_sram_rdata[31:24]}) :
                          (data_ram_ren==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({24'b0,data_sram_rdata[7:0]}) :
                          (data_ram_ren==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({24'b0,data_sram_rdata[15:8]}) :
                          (data_ram_ren==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({24'b0,data_sram_rdata[23:16]}) :
                          (data_ram_ren==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({24'b0,data_sram_rdata[31:24]}) :
                          (data_ram_ren==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{16{data_sram_rdata[15]}},data_sram_rdata[15:0]}) :
                          (data_ram_ren==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}) :
                          (data_ram_ren==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({16'b0,data_sram_rdata[15:0]}) :
                          (data_ram_ren==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({16'b0,data_sram_rdata[31:16]}) : data_sram_rdata;
                          
                          
   assign rf_wdata = sel_rf_res ? mem_result : ex_result;
   
   
    assign mem_to_wb_bus = {
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };
  assign mem_to_id = {
        rf_we,
        rf_waddr,
        rf_wdata
    };



endmodule