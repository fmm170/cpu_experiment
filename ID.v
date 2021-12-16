`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    input wire [37:0] wb_to_id,
    input wire [37:0] ex_to_id,
    input wire [37:0] mem_to_id,
    output wire stallreq_for_load,
    
    
    input wire rec_type,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,
    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    
    output wire [`BR_WD-1:0] br_bus ,
    input wire [31:0] lo_rdata,
    input wire [31:0] hi_rdata,
    input wire hilo_e,
    output wire [31:0] hi_data,
    output wire [31:0] lo_data,
    input wire [64:0] mem_to_id_hilo,
    input wire [64:0] wb_to_id_hilo
);

   reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;
    reg [31:0] inst_reg ;
    reg flag1;
    reg [31:0] inst_reg_div ;
    reg flag2;
    
    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

    
     
     
    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    
    always @ (posedge clk) begin
        if (stall[1]  == 1'b1) begin     //000111
            flag1 <= 1'b1;
            inst_reg <= inst;
        end
        else if (stall[2]==`Stop && stall[3]==`Stop) begin
            flag2<= 1'b1;
            inst_reg_div <= inst_sram_rdata;
        end
        else begin
            flag1 <= 1'b0;
            inst_reg <= 32'b0;
            
            flag2 <= 1'b0;
            inst_reg_div <= 32'b0;
        end
    end
    
    assign inst = flag1 ? inst_reg : flag2 ? inst_reg_div : inst_sram_rdata ;
                  
       
  
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;
    

    wire [31:0] hi_data_r;
    wire [31:0] lo_data_r;
    
    wire mem_we;
    wire [31:0] mem_lo_rdata;
    wire [31:0] mem_hi_rdata;
    
    wire wb_we;
    wire [31:0] wb_lo_rdata;
    wire [31:0] wb_hi_rdata;
   
    
    assign { 
        mem_we,
        mem_hi_rdata,
        mem_lo_rdata
   }= mem_to_id_hilo;
    
    assign { 
        wb_we,
        wb_hi_rdata,
        wb_lo_rdata
    }= wb_to_id_hilo;

   assign hi_data =  mem_we ? mem_hi_rdata :
                     wb_we ? wb_hi_rdata :
                     hi_data_r ; 
         
   assign lo_data =  mem_we ? mem_lo_rdata :
                     wb_we ? wb_lo_rdata :
                     lo_data_r ; 






    

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [3:0] data_ram_ren;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;


    wire ex_id_wreg;
    wire [4:0] ex_id_waddr;
    wire [31:0] ex_id_wdata;

    wire mem_id_wreg;
    wire [4:0] mem_id_waddr;
    wire [31:0] mem_id_wdata;//
    
    wire wb_id_wreg;
    wire [4:0] wb_id_waddr;
    wire [31:0] wb_id_wdata;


    assign {
        ex_id_wreg,
        ex_id_waddr,
        ex_id_wdata
    } = ex_to_id;//
    
    assign {
        mem_id_wreg,
        mem_id_waddr,
        mem_id_wdata
    } = mem_to_id;//

        assign {
        wb_id_wreg,
        wb_id_waddr,  
        
        wb_id_wdata
    } = wb_to_id;//
    
//assign rdata1 = ((ex_id_wreg) && (ex_id_waddr == rs)) ? ex_id_wdata :
//                    ((mem_id_wreg) && (mem_id_waddr == rs)) ? mem_id_wdata :
//                    ((wb_id_wreg) && (wb_id_waddr == rs)) ? wb_id_wdata : rdata1;
//   assign rdata2 = ((ex_id_wreg) && (ex_id_waddr == rt)) ? ex_id_wdata :
//                    ((mem_id_wreg) && (mem_id_waddr == rt)) ? mem_id_wdata :
//                    ((wb_id_wreg) && (wb_id_waddr == rt)) ? wb_id_wdata : rdata2;

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .ex_to_id(ex_to_id),
        .mem_to_id(mem_to_id),
        .wb_to_id(wb_to_id),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );
    
    
    hilo my_hilo(
        .clk(clk),
        .rst(rst),
        .we(hilo_e),
        .hi_rdata(hi_rdata),
        .lo_rdata(lo_rdata),
        .hi_data1(hi_data_r),
        .lo_data1(lo_data_r)
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];
    
    assign stallreq_for_load = ( rec_type && ( ( rs == ex_to_id[36:32] ) || ( rt == ex_to_id[36:32] ) ) );

     wire inst_ori, inst_lui, inst_addiu, inst_beq, inst_subu, inst_jr, inst_jal, inst_addu, inst_bne, inst_sll, inst_or, inst_xor, inst_lw, inst_sw, inst_sltu;
    wire inst_slt, inst_slti, inst_sltiu, inst_j, inst_add, inst_addi, inst_sub, inst_and, inst_andi, inst_nor, inst_xori, inst_sllv, inst_sra, inst_srav;
    wire inst_srl, inst_srlv, inst_bgez, inst_bgtz, inst_blez, inst_bltz, inst_bltzal, inst_bgezal, inst_jalr, inst_mflo, inst_mfhi,inst_mthi, inst_mtlo;
    wire inst_mult, inst_multu, inst_div, inst_divu, inst_lb, inst_lbu, inst_lh, inst_lhu, inst_sb, inst_sh ;
    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_subu    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0011 ) ;
    assign inst_jr      = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b00_1000 ) && ( inst[20:11] ==10'b00_0000_0000 ) ;
    assign inst_jal     = op_d[6'b00_0011] ; 
    assign inst_addu    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0001 ) ; 
    assign inst_bne     = op_d[6'b00_0101] ;
    assign inst_sll     = op_d[6'b00_0000] && ( func === 6'b00_0000 ) && ( rs == 5'b00_000 );
    assign inst_or      = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0101 ) ;
    assign inst_xor     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0110 ) ;
    assign inst_lw      = op_d[6'b10_0011] ;
    assign inst_sw      = op_d[6'b10_1011] ;
    assign inst_sltu    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_1011 ) ;
    assign inst_sw      = op_d[6'b10_1011] ;
    assign inst_slt     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_1010 ) ;
    assign inst_slti    = op_d[6'b00_1010] ;
    assign inst_sltiu   = op_d[6'b00_1011] ;
    assign inst_j       = op_d[6'b00_0010] ;
    assign inst_add     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0000 ) ;
    assign inst_addi    = op_d[6'b00_1000] ;
    assign inst_sub     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0010 ) ;
    assign inst_and     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0100 ) ;
    assign inst_andi    = op_d[6'b00_1100] ;
    assign inst_nor     = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b10_0111 ) ;
    assign inst_xori    = op_d[6'b00_1110] ;
    assign inst_sllv    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b00_0100 ) ;
    assign inst_sra     = op_d[6'b00_0000] && ( rs === 5'b00_000 ) && ( func === 6'b00_0011 ) ;
    assign inst_srav    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b00_0111 ) ;
    assign inst_srl     = op_d[6'b00_0000] && ( rs === 5'b00_000 ) && ( func === 6'b00_0010 ) ;
    assign inst_srlv    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b00_0110 ) ;
    assign inst_bgez    = op_d[6'b00_0001] && ( rt === 5'b00_001 )  ;
    assign inst_bgtz    = op_d[6'b00_0111] && ( rt === 5'b00_000 )  ;
    assign inst_blez    = op_d[6'b00_0110] && ( rt === 5'b00_000 )  ;
    assign inst_bltz    = op_d[6'b00_0001] && ( rt === 5'b00_000 )  ;
    assign inst_bltzal  = op_d[6'b00_0001] && ( rt === 5'b10_000 )  ;
    assign inst_bgezal  = op_d[6'b00_0001] && ( rt === 5'b10_001 )  ;
    assign inst_jalr    = op_d[6'b00_0000] && ( sa === 5'b00_000 ) && ( func === 6'b00_1001 ) && ( rt==5'b00_000 ) ; 
    assign inst_mflo    = op_d[6'b00_0000] && ( inst[25:16] === 10'b00_0000_0000 ) && ( sa == 5'b00_000 ) && ( func === 6'b01_0010 )  ; 
    assign inst_mult    = op_d[6'b00_0000] && ( inst[15:6] === 10'b00_0000_0000 ) && ( func === 6'b01_1000 ) ;
    assign inst_multu   = op_d[6'b00_0000] && ( inst[15:6] === 10'b00_0000_0000 ) && ( func === 6'b01_1001 ) ;
    assign inst_div     = op_d[6'b00_0000] && ( inst[15:6] === 10'b00_0000_0000 ) && ( func === 6'b01_1010 ) ;
    assign inst_divu    = op_d[6'b00_0000] && ( inst[15:6] === 10'b00_0000_0000 ) && ( func === 6'b01_1011 ) ;
    assign inst_mfhi    = op_d[6'b00_0000] && ( inst[25:16] === 10'b00_0000_0000 ) && ( sa == 5'b00_000 ) && ( func === 6'b01_0000 )  ; 
    assign inst_mtlo    = op_d[6'b00_0000] && ( inst[20:6] === 15'b00_0000_0000_0000_0 ) && ( func === 6'b01_0000 )  ; 
    assign inst_mthi    = op_d[6'b00_0000] && ( inst[20:6] === 15'b00_0000_0000_0000_0 ) && ( func === 6'b01_0001 )  ; 
    assign inst_lb      = op_d[6'b10_0000] ;
    assign inst_lbu     = op_d[6'b10_0100] ;
    assign inst_lh      = op_d[6'b100001];
    assign inst_lhu     = op_d[6'b100101];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];
    
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_subu | inst_addu | inst_or | inst_xor | inst_lw | inst_sw | inst_sltu | inst_slt | inst_slti | inst_sltiu 
                             | inst_add | inst_addi | inst_sub | inst_and | inst_andi | inst_nor | inst_xori | inst_sllv | inst_srav | inst_srlv | inst_mult | inst_multu 
                             | inst_div | inst_divu | inst_mtlo | inst_mthi | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;

    
    // rt to reg2
    assign sel_alu_src2[0] = inst_subu | inst_addu | inst_sll | inst_or | inst_xor | inst_sltu | inst_slt | inst_add | inst_sub | inst_and | inst_nor |  inst_sllv
                             | inst_sra | inst_srav | inst_srl | inst_srlv | inst_mult | inst_multu | inst_div | inst_divu ;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lui | inst_lw | inst_sw | inst_slti | inst_sltiu | inst_addi | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;



    assign op_add = inst_addiu | inst_jal | inst_addu | inst_lw | inst_sw | inst_add | inst_addi | inst_bltzal | inst_bgezal | inst_jalr | inst_lb | inst_lbu | inst_lh
                   | inst_lhu | inst_sb | inst_sh ;
    assign op_sub = inst_subu | inst_sub;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_and = inst_and | inst_andi  ;
    assign op_nor = inst_nor;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor | inst_xori;
    assign op_sll = inst_sll | inst_sllv;
    assign op_srl = inst_srl | inst_srlv;
    assign op_sra = inst_sra | inst_srav;
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};



    // load and store enable
    assign data_ram_en = inst_lw | inst_sw | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh;

    // write enable    0 load 1 store
    assign data_ram_wen =  ( inst_lw | inst_lb | inst_lbu | inst_lh | inst_lhu ) ? 4'b0000 : 4'b1111;

    assign data_ram_ren =  inst_lw  ? 4'b1111 :
                              inst_lb  ? 4'b0001 :
                              inst_lbu ? 4'b0010 :
                              inst_lh  ? 4'b0011 :
                              inst_lhu ? 4'b0100 :
                              inst_sb  ? 4'b0101 :
                              inst_sh  ? 4'b0111 : 4'b0000;

    // regfile store enable
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_subu | inst_jal | inst_addu | inst_sll | inst_or | inst_xor | inst_lw | inst_sltu | inst_slt | inst_slti
                   | inst_sltiu | inst_add | inst_addi | inst_sub | inst_and | inst_andi | inst_nor | inst_xori | inst_sllv | inst_sra | inst_srav | inst_srl | inst_srlv
                   | inst_bltzal | inst_bgezal | inst_jalr | inst_mflo | inst_mfhi | inst_lb | inst_lbu | inst_lh | inst_lhu;



    // store in [rd]
    assign sel_rf_dst[0] = inst_subu | inst_addu | inst_sll | inst_or | inst_xor | inst_sltu | inst_slt | inst_add | inst_sub | inst_and | inst_nor | inst_sllv
                           | inst_sra | inst_srav | inst_srl | inst_srlv | inst_jalr | inst_mflo | inst_mfhi;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu | inst_lw | inst_slti | inst_sltiu | inst_addi | inst_andi | inst_xori | inst_lb | inst_lbu | inst_lh
                           | inst_lhu ;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bltzal | inst_bgezal;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res =  ( inst_lw | inst_lb | inst_lbu | inst_lh | inst_lhu ) ? 1'b1 : 1'b0 ;


    assign id_to_ex_bus = {
        data_ram_ren, //162:159
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };


    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_uneq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (rdata1 == rdata2);
    assign rs_uneq_rt = (rdata1 != rdata2);
    assign rt_bgez = ( rdata1[31] == 1'b0 ) ;
    assign rt_bgtz = ( ( rdata1[31] == 1'b0 ) && ( rdata1 != 32'b0) ) ;
    assign rt_blez = ( ( rdata1[31] == 1'b1 ) || ( rdata1 == 32'b0) ) ;
    assign rt_bltz =  ( rdata1[31] == 1'b1 ) ;
    assign rt_bltzal = ( rdata1[31] == 1'b1 ) ;
    assign rt_bgezal = ( rdata1[31] == 1'b0 ) ;
    
    
    
    
    assign br_e = (inst_beq & rs_eq_rt)| (inst_jr ) | (inst_jal) | (inst_bne & rs_uneq_rt) | ( inst_j ) | ( inst_bgez & rt_bgez ) | ( inst_bgtz & rt_bgtz )
                   | ( inst_blez & rt_blez ) | ( inst_bltz & rt_bltz ) | ( inst_bltzal & rt_bltzal ) | ( inst_bgezal & rt_bgezal ) | ( inst_jalr );
    assign br_addr = inst_beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_jr ? rdata1 : 
                     inst_jal ? { pc_plus_4[31:28], inst[25:0], 2'b0 } : 
                     inst_bne ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) : 
                     inst_j ? {  pc_plus_4[31:28] , inst[25:0] , 2'b0 } :
                     inst_bgez ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) :
                     inst_bgtz ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) :
                     inst_blez ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) : 
                     inst_bltz ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) : 
                     inst_bltzal ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) : 
                     inst_bgezal ? ( pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0} ) :
                     inst_jalr ?  rdata1 :
                     32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    


endmodule