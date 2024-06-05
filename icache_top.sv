module icache_top #(
    parameter integer unsigned ICACHE_SIZE = 32,//kB
    parameter integer unsigned ICACHE_LINE_SIZE = 64,//B
    parameter integer unsigned ICACHE_WAYS = 2,

    parameter integer unsigned ICACHE_DOWNSTREAM_ADDR_WIDTH = 32    ,
    parameter integer unsigned ICACHE_DOWNSTREAM_DATA_WIDTH = 256   ,
    parameter integer unsigned ICACHE_DOWNSTREAM_TXNID_WIDTH = 4,
)(
    input  logic                                        clk                         ,
    input  logic                                        rst_n                       ,

    //upstream rxreq
    input  logic                                        upstream_rxreq_vld          ,
    output logic                                        upstream_rxreq_rdy          ,
    input  logic                                        upstream_rxreq_opcode       ,
    input  logic                                        upstream_rxreq_txnid        ,
    input  logic                                        upstream_rxreq_addr         ,

    //upstream txdat
    output logic                                        upstream_txdat_data         , 
    output logic                                        upstream_txdat_en           ,

    //downtream txreq
    output logic                                        downstream_txreq_vld        ,
    input  logic                                        downstream_txreq_rdy        ,
    output logic                                        downstream_txreq_opcode     ,
    output logic [ICACHE_DOWNSTREAM_TXNID_WIDTH-1:0]    downstream_txreq_txnid      ,
    output logic [ICACHE_DOWNSTREAM_ADDR_WIDTH-1:0]     downstream_txreq_addr       ,
    
    //downstream rxdat
    input  logic                                        downstream_rxdat_vld        ,
    output logic                                        downstream_rxdat_rdy        ,
    input  logic                                        downstream_rxdat_opcode     ,
    input  logic [ICACHE_DOWNSTREAM_TXNID_WIDTH-1:0]    downstream_rxdat_txnid      ,
    input  logic [ICACHE_DOWNSTREAM_DATA_WIDTH-1:0]     downstream_rxdat_data       ,

    //downstream rxsnp
    input  logic                                        downstream_rxsnp_vld        ,
    output logic                                        downstream_rxsnp_rdy        ,
    input  logic                                        downstream_rxsnp_opcode     ,
    input  logic                                        downstream_rxsnp_txnid      ,
    input  logic                                        downstream_rxsnp_addr       ,

    //downstream txrsp
    output logic                                        downstream_txrsp_vld        ,
    input  logic                                        downstream_txrsp_rdy        ,
    output logic                                        downstream_txrsp_opcode     

);
    logic   [17:0] tag;
    logic   [7:0] index;
    logic   [5:0] offset;
    assign {tag,index,offset} = cpu_i_req_addr;
    assign v_tag = {valid, tag}

    logic prefetch_req_vld  ;
    logic prefetch_req_rdy  ;
    logic prefetch_req_addr ;

    logic tag_req_vld       ;
    logic tag_req_rdy       ;
    logic tag_req_addr      ;
    logic tag_req_opcode    ;
    logic tag_req_txnid     ;

    logic prefetch_miss_en      ;
    logic prefetch_miss_addr    ;

    icache_req_arbiter u_req_arbiter (
        .clk                        (clk                         ),
        .rst_n                      (rst_n                       ),
        .upstream_rxreq_vld         (upstream_rxreq_vld          ),     
        .upstream_rxreq_rdy         (upstream_rxreq_rdy          ),     
        .upstream_rxreq_opcode      (upstream_rxreq_opcode       ),     
        .upstream_rxreq_txnid       (upstream_rxreq_txnid        ),     
        .upstream_rxreq_addr        (upstream_rxreq_addr         ),     
        .downstream_rxsnp_vld       (downstream_rxsnp_vld        ),     
        .downstream_rxsnp_rdy       (downstream_rxsnp_rdy        ),     
        .downstream_rxsnp_txnid     (downstream_rxsnp_txnid      ),
        .downstream_rxsnp_opcode    (downstream_rxsnp_opcode     ),     
        .downstream_rxsnp_addr      (downstream_rxsnp_addr       ),     
        .prefetch_req_vld           (prefetch_req_vld            ), 
        .prefetch_req_rdy           (prefetch_req_rdy            ), 
        .prefetch_req_addr          (prefetch_req_addr           ), 
        .tag_req_vld                (tag_req_vld                 ),    
        .tag_req_rdy                (tag_req_rdy                 ),    
        .tag_req_addr               (tag_req_addr                ),    
        .tag_req_opcode             (tag_req_opcode              ),    
        .tag_req_txnid              (tag_req_txnid               )
    );


    icache_prefetch_engine u_prefetch_engine (
        .clk                        (clk                ),
        .rst_n                      (rst_n              ),
        .miss                       (prefetch_miss_en   ),
        .addr_in                    (prefetch_miss_addr ),
        .prefetch_req_vld           (prefetch_req_vld   ),
        .prefetch_req_rdy           (prefetch_req_rdy   ),
        .prefetch_req_addr          (prefetch_req_addr  )
    );


    icache_tag_ctrl u_tag_ctrl (
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),

        .tag_req_vld                (tag_req_vld              ),    
        .tag_req_rdy                (tag_req_rdy              ),    
        .tag_req_addr               (tag_req_addr             ),    
        .tag_req_opcode             (tag_req_opcode           ),    
        .tag_req_txnid              (tag_req_txnid            ),

        .downstream_txreq_vld       (downstream_txreq_vld     ),
        .downstream_txreq_rdy       (downstream_txreq_rdy     ),
        .downstream_txreq_opcode    (downstream_txreq_opcode  ),
        .downstream_txreq_txnid     (downstream_txreq_txnid   ),
        .downstream_txreq_addr      (downstream_txreq_addr    ),

        .downstream_txrsp_vld       (downstream_txrsp_vld     ),
        .downstream_txrsp_rdy       (downstream_txrsp_rdy     ),
        .downstream_txrsp_opcode    (downstream_txrsp_opcode  ),

        .prefetch_miss_en           (prefetch_miss_en         ),
        .prefetch_miss_addr         (prefetch_miss_addr       ),

        .mshr_entry_msg             (mshr_entry_msg           ),
        .mshr_linefill_done_en      (mshr_linefill_done_en    ),
        .mshr_linefile_done_idx     (mshr_linefill_done_idx   ),

        .dataram_rd_vld             (dataram_rd_vld           ),
        .dataram_rd_rdy             (dataram_rd_rdy           ),
        .dataram_rd_way             (dataram_rd_way           ),
        .dataram_rd_index           (dataram_rd_index         )
    );




    data_ram_ctrl u_data_ram_ctrl(
        .clk        (clk            ), 
        .rst_n      (rst_n          ),
        .addr_hit   (addr           ),
        .wr_en      (               ),
        .
        .addr_linefill(mshr_data    ), //mshr to linefill
        .data_in    (linefill_data  ),
        .data_out   (req_data_out   ),
        .
    );

//linefill_ctrl?
linefill_ctrl u_linefill_ctrl(
    .clk                (clk                ), 
    .rst_n              (rst_n              ),
    .linefill_en        (mshr_linefill_en   ),
    .linefill_done      (linefill_done      ),
    .linefill_data_in   (l2mem_data_in      ),
    .linefill_addr_in   (mshr_data          ),
    .linefill_data_out  (data_ram_in_data   ),
    .
);

//tag_ram: valid bit, taginfo, index:8bit; offset:6bit;  tag:18bit; valid: 1bit;
spram_256x19 u_tag_ram(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .cs         (       ),
    .wen        (       ),
    .addr       (       ),
    .din        (       ),
    .dout       (       ),
);

//spram_256x512
spram_256x128 u_data_ram_bank0(

);
spram_256x128 u_data_ram_bank1(

);
spram_256x128 u_data_ram_bank2(

);
spram_256x128 u_data_ram_bank3(

);

    icache_sram_wrapper 




endmodule