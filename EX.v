`include "lib/defines.vh"

module EX(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    output wire [37:0] ex_to_id,
    output wire rec_type,
    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire stallreq_for_ex,
    input wire [31:0] hi_data,
    input wire [31:0] lo_data,
    output wire [64:0] ex_to_mem_hilo
);

    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        // else if (flush) begin
        //     id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        // end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        else if (stall[2]==`NoStop) begin
            id_to_ex_bus_r <= id_to_ex_bus;
        end
    end

    wire [31:0] ex_pc, inst;
    wire [11:0] alu_op;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;
    reg is_in_delayslot;

    wire [31:0] lo_rdata;
    wire [31:0] hi_rdata;
    wire ex_we_hilo;
    wire [31:0] store_hilo;
    wire [3:0] data_ram_ren;
    
    
    assign {
        data_ram_ren , //162:159
        ex_pc,          // 148:117
        inst,           // 116:85
        alu_op,         // 84:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,         // 63:32
        rf_rdata2          // 31:0
    } = id_to_ex_bus_r;

    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    assign imm_sign_extend = {{16{inst[15]}},inst[15:0]};
    assign imm_zero_extend = {16'b0, inst[15:0]};
    assign sa_zero_extend = {27'b0,inst[10:6]};

    wire [31:0] alu_src1, alu_src2;
    wire [31:0] alu_result, ex_result;

    assign alu_src1 = sel_alu_src1[1] ? ex_pc :
                      sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend :
                      sel_alu_src2[2] ? 32'd8 :
                      sel_alu_src2[3] ? imm_zero_extend : rf_rdata2;
    
    alu u_alu(
    	.alu_control (alu_op ),
        .alu_src1    (alu_src1    ),
        .alu_src2    (alu_src2    ),
        .alu_result  (alu_result  )
    );
    
   assign store_hilo = inst_mflo ? lo_data : 
                       inst_mfhi ? hi_data : 32'b0;
                       
   assign ex_result = (inst_mflo|inst_mfhi) ? store_hilo :alu_result;

    assign ex_to_id = {
        rf_we,
        rf_waddr,
        ex_result
    };
    
        
    
    
    assign ex_to_mem_bus = {
        data_ram_ren, //79:76
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };


    assign data_sram_en = data_ram_en;
    assign data_sram_wen =   (data_ram_ren==4'b0101 && ex_result[1:0] == 2'b00 )? 4'b0001 
                            :(data_ram_ren==4'b0101 && ex_result[1:0] == 2'b01 )? 4'b0010
                            :(data_ram_ren==4'b0101 && ex_result[1:0] == 2'b10 )? 4'b0100
                            :(data_ram_ren==4'b0101 && ex_result[1:0] == 2'b11 )? 4'b1000
                            :(data_ram_ren==4'b0111 && ex_result[1:0] == 2'b00 )? 4'b0011
                            :(data_ram_ren==4'b0111 && ex_result[1:0] == 2'b10 )? 4'b1100
                            : data_ram_wen;    
    assign data_sram_addr = ex_result; 
    assign data_sram_wdata = data_sram_wen==4'b1111 ? rf_rdata2 
                            :data_sram_wen==4'b0001 ? {24'b0,rf_rdata2[7:0]}
                            :data_sram_wen==4'b0010 ? {16'b0,rf_rdata2[7:0],8'b0}
                            :data_sram_wen==4'b0100 ? {8'b0,rf_rdata2[7:0],16'b0}
                            :data_sram_wen==4'b1000 ? {rf_rdata2[7:0],24'b0}
                            :data_sram_wen==4'b0011 ? {16'b0,rf_rdata2[15:0]}
                            :data_sram_wen==4'b1100 ? {rf_rdata2[15:0],16'b0}
                            :32'b0;

    assign rec_type = ( inst[31:26] == 6'b100011 ) ? 1'b1:1'b0;



//    // MUL part
//    wire [63:0] mul_result;
//    wire mul_signed; // 有符号乘法标�??
//    wire inst_mult, inst_multu;
//    wire [31:0] mul_src1;
//    wire [31:0] mul_src2;
    
//    assign mul_signed = inst_mult ? 1'b1 : 1'b0 ;//mult 1 multu0
//    assign mul_src1 = (inst_mult | inst_multu) ? alu_src1 :32'b0;
//    assign mul_src2 = (inst_mult | inst_multu) ? alu_src2 :32'b0;
    
    
//    mul u_mul(
//    	.clk        (clk            ),
//        .resetn     (~rst           ),
//        .mul_signed (mul_signed     ),
//        .ina        (mul_src1      ), // 
//        .inb        (mul_src2      ), // 
//        .result     (mul_result     ) // 
//    );

// MUL part
   wire [63:0] mul_result;
   reg stallreq_for_mul;
    wire mul_ready_i;
    reg signed_mul_o; //�Ƿ����з��ų˷�
    reg [31:0] mul_opdata1_o;
    reg [31:0] mul_opdata2_o;
    reg mul_start_o;
    mymul my_mul(
        .rst            (rst           ),
	    .clk            (clk            ),
	    .signed_mul_i   (signed_mul_o     ),
	    .mult1_o            (mul_opdata1_o      ),
	    .mult2_o            (mul_opdata2_o      ),
	    .start_i        (mul_start_o      ),
	    .result_o       (mul_result     ),
	    .ready_o        (mul_ready_i     )
    );
    always @ (*) begin
        if (rst) begin
            stallreq_for_mul = `NoStop;
            mul_opdata1_o = `ZeroWord;
            mul_opdata2_o = `ZeroWord;
            mul_start_o = `MulStop;
            signed_mul_o = 1'b0;
        end
        else begin
            stallreq_for_mul = `NoStop;
            mul_opdata1_o = `ZeroWord;
            mul_opdata2_o = `ZeroWord;
            mul_start_o = `MulStop;
            signed_mul_o = 1'b0;
            case ({inst_mult,inst_multu})
                2'b10:begin
                    if (mul_ready_i == `MulResultNotReady) begin
                        mul_opdata1_o = rf_rdata1;
                        mul_opdata2_o = rf_rdata2;
                        mul_start_o = `MulStart;
                        signed_mul_o = 1'b1;
                        stallreq_for_mul = `Stop;
                    end
                    else if (mul_ready_i == `MulResultReady) begin
                        mul_opdata1_o = rf_rdata1;
                        mul_opdata2_o = rf_rdata2;
                        mul_start_o = `MulStop;
                        signed_mul_o = 1'b1;
                        stallreq_for_mul = `NoStop;
                    end
                    else begin
                        mul_opdata1_o = `ZeroWord;
                        mul_opdata2_o = `ZeroWord;
                        mul_start_o = `MulStop;
                        signed_mul_o = 1'b0;
                        stallreq_for_mul = `NoStop;
                    end
                end
                2'b01:begin
                    if (mul_ready_i == `MulResultNotReady) begin
                        mul_opdata1_o = rf_rdata1;
                        mul_opdata2_o = rf_rdata2;
                        mul_start_o = `MulStart;
                        signed_mul_o = 1'b0;
                        stallreq_for_mul = `Stop;
                    end
                    else if (mul_ready_i == `MulResultReady) begin
                        mul_opdata1_o = rf_rdata1;
                        mul_opdata2_o = rf_rdata2;
                        mul_start_o = `MulStop;
                        signed_mul_o = 1'b0;
                        stallreq_for_mul = `NoStop;
                    end
                    else begin
                        mul_opdata1_o = `ZeroWord;
                        mul_opdata2_o = `ZeroWord;
                        mul_start_o = `MulStop;
                        signed_mul_o = 1'b0;
                        stallreq_for_mul = `NoStop;
                    end
                end
                default:begin
                end
            endcase
        end
    end
    
    // DIV part
    wire [63:0] div_result;
    wire inst_div, inst_divu;
    wire div_ready_i;
    reg stallreq_for_div;
    

    reg [31:0] div_opdata1_o;
    reg [31:0] div_opdata2_o;
    reg div_start_o;
    reg signed_div_o;
    
    

    div u_div(
    	.rst          (rst          ),
        .clk          (clk          ),
        .signed_div_i (signed_div_o ),
        .opdata1_i    (div_opdata1_o    ),
        .opdata2_i    (div_opdata2_o    ),
        .start_i      (div_start_o      ),
        .annul_i      (1'b0      ),
        .result_o     (div_result     ), // 除法结果 64bit
        .ready_o      (div_ready_i      )
    );

    always @ (*) begin
        if (rst) begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
        end
        else begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
            case ({inst_div,inst_divu})
            
                2'b10:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                2'b01:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                default:begin
                end
            endcase
        end
    end
    
    
    assign inst_divu  = ( inst[31:26] == 6'b00_0000 && inst[15:6] === 10'b00_0000_0000 && inst[5:0] === 6'b01_1011 ) ? 1'b1 : 1'b0 ;
    assign inst_div   = ( inst[31:26] == 6'b00_0000 && inst[15:6] === 10'b00_0000_0000 && inst[5:0] === 6'b01_1010 ) ? 1'b1 : 1'b0 ;
    assign inst_mult  = ( inst[31:26] == 6'b00_0000 && inst[15:6] === 10'b00_0000_0000 && inst[5:0] === 6'b01_1000 ) ? 1'b1 : 1'b0 ;
    assign inst_multu = ( inst[31:26] == 6'b00_0000 && inst[15:6] === 10'b00_0000_0000 && inst[5:0] === 6'b01_1001 ) ? 1'b1 : 1'b0 ;
    assign inst_mflo  = ( inst[31:26] == 6'b00_0000 && inst[25:16] === 10'b00_0000_0000  &&  inst[10:6] == 5'b00_000  &&  inst[5:0] === 6'b01_0010 ) ? 1'b1 : 1'b0  ;
    assign inst_mfhi  = ( inst[31:26] == 6'b00_0000 && inst[25:16] === 10'b00_0000_0000  &&  inst[10:6] == 5'b00_000  &&  inst[5:0] === 6'b01_0000 ) ? 1'b1 : 1'b0  ;
    assign inst_mtlo  = ( inst[31:26] == 6'b00_0000 && inst[20:6] == 15'b00_0000_0000_0000_0 && inst[5:0] === 6'b01_0011 ) ? 1'b1 : 1'b0  ;
    assign inst_mthi  = ( inst[31:26] == 6'b00_0000 && inst[20:6] == 15'b00_0000_0000_0000_0 && inst[5:0] === 6'b01_0001 ) ? 1'b1 : 1'b0  ;
    
    

    assign stallreq_for_ex = (( div_ready_i==1'b0 & div_start_o==1'b1 )||( mul_ready_i==1'b0 & mul_start_o==1'b1 ))? 1'b1 :1'b0;
    
    assign lo_rdata = ( inst_mult | inst_multu ) ? mul_result[31:0] : 
                      ( inst_div | inst_divu ) ? div_result[31:0]  :
                      inst_mthi ? lo_data :
                      inst_mtlo ? rf_rdata1 : lo_data ;
                      
    assign hi_rdata = ( inst_mult | inst_multu ) ? mul_result[63:32] :
                      ( inst_div | inst_divu ) ? div_result[63:32] :
                      inst_mthi ? rf_rdata1 :
                      inst_mtlo ? hi_data : hi_data;
    assign ex_we_hilo = ( inst_mult | inst_multu | inst_div | inst_divu | inst_mthi | inst_mtlo ) ? 1'b1 :1'b1; 
                       
    
    assign ex_to_mem_hilo = { ex_we_hilo, hi_rdata, lo_rdata } ; 
    

    
endmodule