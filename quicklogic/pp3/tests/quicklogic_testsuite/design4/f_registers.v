// -----------------------------------------------------------------------------
// title          : f_registers
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : f_registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2019/04/Jan	
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Provides 512*32 Fabric Ram access to M4
// -----------------------------------------------------------------------------
// copyright (c) 2019
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author                   description
// 2019/04/Jan      1.0        Anand Wadke              Created.
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

`define USEDMA0
//`define USEDMA1
//`define USEDMA2
//`define USEDMA3

module f_registers ( 
                         
            WBs_CLK_i,          
            WBs_RST_i,   
          
            WBs_ADR_i,          
            WBs_CYC_i,  
            WBs_CYC_DMA_i,  
            WBs_CYC_COEFF_RAM_i, 
            WBs_CYC_RealImg_RAM_i, 
 			
            WBs_BYTE_STB_i,     
            WBs_WE_i,           
            WBs_STB_i,          
            WBs_DAT_i,          
            WBs_DAT_o, 
            WBs_DMA_DAT_o, 
            WBs_f_RealImg_RAM_DAT_o,	
            WBs_COEF_RAM_DAT_o,	
			
            WBs_ACK_o, 

            stage_cnt_o,
            f_point_o,
            ena_perstgscale_o,
			ena_bit_rev_o,//enabled during write mode only
			
			f_en_o,
			
			f_IRQ_o   ,  
			f_IRQ_EN_o,

            f_done_i,	
			f_busy_i,
            f_start_o, 

			wb_CosSin_RAM_aDDR_o,
			wb_CosSin_RAM_Wen_o,
			wb_CosSin_RAM_Data_o,	
			wb_CosSin_RAM_Data_i,	
			//wb_CosSin_RAM_rd_access_ctrl_o,
			
			wb_f_realImg_RAM_aDDR_o,	 
			wb_f_realImg_RAM_Data_i,	 
			wb_f_real_RAM_Data_o,	 
			wb_f_realImg_RAM_Wen_o,	 
			//wb_f_RAM_wr_rd_Mast_sel_o,
			wb_f_realimgbar_ram_rd_switch_o,
			
		

`ifdef USEDMA0			
			DMA0_Clr_i,  
			DMA0_Done_i,
			DMA0_Start_o,
			DMA0_Done_IRQ_o, 
			DMA0_Done_IRQ_EN_o,
`endif			
`ifdef USEDMA1	        	
			DMA1_Clr_i, 
			DMA1_Done_i,
			DMA1_Start_o, 
			DMA1_Done_IRQ_o,
			DMA1_Done_IRQ_EN_o,
`endif  
`ifdef USEDMA2       	
			DMA2_Clr_i,
            DMA2_Done_i,
			DMA2_Start_o,
			DMA2_Done_IRQ_o, 
            DMA2_Done_IRQ_EN_o,			
`endif 
`ifdef USEDMA3         	
			DMA3_Clr_i,
			DMA3_Done_i,
			DMA3_Start_o,
			DMA3_Done_IRQ_o, 
			DMA3_Done_IRQ_EN_o
`endif			
         	
      
			
            );


//------Port Parameters----------------
//
parameter                ADDRWIDTH                   =   9           ;
parameter                COEFFADDRWIDTH              =   9           ;
parameter                fRAMADDRWIDTH             =   9           ;

parameter                DATAWIDTH                   =  32           ;

parameter       		 AL4S3B_DEVICE_ID            = 20'h00FFD;   
parameter       		 AL4S3B_REV_LEVEL            = 16'h0001;

parameter                IDREV_REG_ADR          	 =  10'h0         ;
parameter                RESERVED          	         =  10'h1         ;
parameter                f_CTRL_REG_ADR          	 =  10'h2         ;
parameter                f_POINT_REG_ADR           =  10'h3         ;
parameter                INTR_STS_REG_ADR          	 =  10'h4         ;
parameter                INTR_EN_REG_ADR             =  10'h5         ;
parameter                DMA_EN_REG_ADR              =  10'h0         ;
parameter                DMA_STS_REG_ADR             =  10'h1         ;
parameter                DMA_INTR_EN_REG_ADR         =  10'h2         ;
parameter                RESERVED_3                  =  10'hB         ;//9'hB         ;
parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area

//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    			WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    			WBs_RST_i       ; // Fabric Reset               to   Fabric
input   [ADDRWIDTH-3:0]  			WBs_ADR_i       ; // Address Bus                to   Fabric
input                    			WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input                    			WBs_CYC_DMA_i       ; 
input                    			WBs_CYC_COEFF_RAM_i      ;
input                    			WBs_CYC_RealImg_RAM_i      ;

input            [2:0]	 			WBs_BYTE_STB_i  ;
input                    			WBs_WE_i        ; // Write Enable               to   Fabric
input                    			WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [31:0]  			WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  			WBs_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  			WBs_DMA_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  			WBs_f_RealImg_RAM_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  			WBs_COEF_RAM_DAT_o       ; // Read Data Bus              from Fabric
output                   			WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

output	 [3:0]		   				stage_cnt_o;
output   [9:0]         				f_point_o;
output			      				ena_perstgscale_o;
output			      				ena_bit_rev_o;

output			      				f_en_o;

output                   			f_IRQ_EN_o;
output                   			f_IRQ_o;

input                    			f_done_i;	
input                    			f_busy_i; 	
output                    			f_start_o; 	

output   [COEFFADDRWIDTH-1:0]   	wb_CosSin_RAM_aDDR_o;
output 								wb_CosSin_RAM_Wen_o;
output   [DATAWIDTH-1:0] 			wb_CosSin_RAM_Data_o;	
input    [DATAWIDTH-1:0]  			wb_CosSin_RAM_Data_i;	
//output 								wb_CosSin_RAM_rd_access_ctrl_o;
                                    
output  [fRAMADDRWIDTH-1:0] 	    wb_f_realImg_RAM_aDDR_o;	 
input   [DATAWIDTH-1:0]     		wb_f_realImg_RAM_Data_i;	 
output  [DATAWIDTH-1:0]     		wb_f_real_RAM_Data_o;	 
output 								wb_f_realImg_RAM_Wen_o;	 
//output								wb_f_RAM_wr_rd_Mast_sel_o;
output								wb_f_realimgbar_ram_rd_switch_o;		


`ifdef USEDMA0
input	 				 DMA0_Clr_i; 
input	 				 DMA0_Done_i;
output					 DMA0_Start_o;
output					 DMA0_Done_IRQ_o;
output					 DMA0_Done_IRQ_EN_o;
`endif

`ifdef USEDMA1
input	 				 DMA1_Clr_i;
input	 				 DMA1_Done_i;
output					 DMA1_Start_o;
output					 DMA1_Done_IRQ_o;
output					 DMA1_Done_IRQ_EN_o;
`endif
 
`ifdef USEDMA2 
input	 				 DMA2_Clr_i;
input	 				 DMA2_Done_i;
output					 DMA2_Start_o;
output					 DMA2_Done_IRQ_o;
output					 DMA2_Done_IRQ_EN_o;
`endif

`ifdef USEDMA3 
input	 				 DMA3_Clr_i; 
input	 				 DMA3_Done_i;
output					 DMA3_Start_o;
output					 DMA3_Done_IRQ_o;
output					 DMA3_Done_IRQ_EN_o;
`endif

						 
// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
//wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [2:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire             [31:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus
reg     [DATAWIDTH-1:0]  WBs_DMA_DAT_o   ; // Wishbone DMA reg Read   Data Bus
reg                      WBs_ACK_sig       ; // Wishbone Client Acknowledge
//reg                      WBs_ACK_sig_dma       ; // Wishbone Client Acknowledge
reg 					 WBs_ACK_sig_r;



//------Internal Signals---------------
//
wire                     fCTRL_REG_Wr_Dcd ;
wire                     fPNT_REG_Wr_Dcd ;
wire                     INTR_EN_REG_Wr_Dcd ; 
wire                     INTR_STS_REG_Wr_Dcd ; 
wire                     f_RealImg_RAM_ADDR_Wr_Dcd ; 
wire                     f_CosSin_RAM_ADDR_Wr_Dcd  ; 


reg  					 f_en;
reg  					 debug_rst_fram_ptr;
reg  	[2:0]		     f_point_reg;
reg                      f_IRQ_EN_o;
reg                      f_IRQ_o;

reg			      		 ena_bit_rev_o;

//DMA
wire                     DMA_EN_REG_Wr_Dcd ;
wire                     DMA_STS_REG_Wr_Dcd ; 
wire                     DMA_IRQ_EN_REG_Wr_Dcd ;

`ifdef USEDMA0
reg  					 DMA0_Done_IRQ_o;
reg						 DMA0_EN;
wire					 DMA0_Start; 
reg  					 DMA0_Done_IRQ_EN_o;
`endif

//`ifdef USEDMA1
reg  					 DMA1_Done_IRQ_o;
reg						 DMA1_EN;
wire					 DMA1_Start;
reg  					 DMA1_Done_IRQ_EN_o;
//`endif

//`ifdef USEDMA2
reg  					 DMA2_Done_IRQ_o;
reg						 DMA2_EN;
wire					 DMA2_Start;
reg  					 DMA2_Done_IRQ_EN_o;
//`endif

//`ifdef USEDMA3
reg  					 DMA3_Done_IRQ_o;
reg						 DMA3_EN;
wire					 DMA3_Start;
reg  					 DMA3_Done_IRQ_EN_o;
//`endif


//reg  [ADDRWIDTH:0]		 fram_addr_ptr;   
reg  [fRAMADDRWIDTH:0]		 fram_addr_ptr;   
					
//wire [31:0]  			 coeff_rd_data_sig;	

wire                     WBs_ACK_f_nxt;

reg                      frealdataload_done;
wire                     frealdataload_done_w;
reg                      frealdataload_done1;
reg                      f_busy_r;
reg                      f_busy_r1;
wire                     f_busy_pulse;

reg      [9:0]                f_point_o;
reg      [3:0]                stage_cnt_o;

wire 					f_done;
reg 					f_done_r;

wire 				    fram_addr_ptr_msb;
wire 				    fram_addr_ptr_msb_toggle;
reg 				    fram_addr_ptr_msb_r1;

reg 					DMA0_Done_IRQ_r1;
reg 					DMA0_Done_IRQ_r2;
wire 					DMA0_Done_pulse;

//------Logic Operations---------------
//
assign WBs_ACK_o = WBs_ACK_sig;
//assign WBs_ACK_o = WBs_ACK_sig_r;


// Determine each register decode
//
assign fCTRL_REG_Wr_Dcd 					= ( WBs_ADR_i[8:0] == f_CTRL_REG_ADR  	) & WBs_CYC_i 	  & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign fPNT_REG_Wr_Dcd  					= ( WBs_ADR_i[8:0] == f_POINT_REG_ADR 	) & WBs_CYC_i 	  & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign INTR_EN_REG_Wr_Dcd 					= ( WBs_ADR_i[8:0] == INTR_EN_REG_ADR   	) & WBs_CYC_i 	  & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign INTR_STS_REG_Wr_Dcd 					= ( WBs_ADR_i[8:0] == INTR_STS_REG_ADR  	) & WBs_CYC_i 	  & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 

assign DMA_EN_REG_Wr_Dcd 					= ( WBs_ADR_i[8:0] == DMA_EN_REG_ADR    	) & WBs_CYC_DMA_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_STS_REG_Wr_Dcd 					= ( WBs_ADR_i[8:0] == DMA_STS_REG_ADR   	) & WBs_CYC_DMA_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_IRQ_EN_REG_Wr_Dcd 				= ( WBs_ADR_i[8:0] == DMA_INTR_EN_REG_ADR   ) & WBs_CYC_DMA_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;


//assign COEFF_RAM_ADDR_REG_Wr_Dcd 		    = ( WBs_ADR_i[8] == COEFF_RAM_ADDR1[9] ) & WBs_CYC_COEFF_RAM_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
//assign COEFF_RAM_ADDR_REG_Wr_Dcd 		    =  WBs_CYC_COEFF_RAM_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
        
assign f_RealImg_RAM_ADDR_Wr_Dcd	        = WBs_CYC_RealImg_RAM_i    & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign f_CosSin_RAM_ADDR_Wr_Dcd 	        = WBs_CYC_COEFF_RAM_i      & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;        
   
   
// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_f_nxt          			=   (WBs_CYC_i | WBs_CYC_COEFF_RAM_i | WBs_CYC_RealImg_RAM_i |WBs_CYC_DMA_i)  & WBs_STB_i & (~WBs_ACK_sig & ~WBs_ACK_sig_r);

assign wb_CosSin_RAM_aDDR_o					=	WBs_ADR_i[8 : 0];
assign wb_CosSin_RAM_Wen_o          		=   f_CosSin_RAM_ADDR_Wr_Dcd;
assign wb_CosSin_RAM_Data_o         		=	WBs_DAT_i[31:0];
assign WBs_COEF_RAM_DAT_o					=   wb_CosSin_RAM_Data_i;	
//assign wb_CosSin_RAM_rd_access_ctrl_o  	    =   ~f_en;

assign wb_f_realImg_RAM_aDDR_o			=   fram_addr_ptr[fRAMADDRWIDTH-1:0];				 
assign WBs_f_RealImg_RAM_DAT_o			=   wb_f_realImg_RAM_Data_i;	 
assign wb_f_real_RAM_Data_o				=   WBs_DAT_i[31:0];
assign wb_f_realImg_RAM_Wen_o			    =   f_RealImg_RAM_ADDR_Wr_Dcd;
assign wb_f_realimgbar_ram_rd_switch_o	=   fram_addr_ptr[fRAMADDRWIDTH];//Add Additional Comparator logic to support all supported points

//assign f_start_o 							= fram_addr_ptr[9] && frealdataload_done;
assign f_start_o 							= frealdataload_done_w;
assign frealdataload_done_w               = frealdataload_done & ~frealdataload_done1;
assign f_busy_pulse                       = f_busy_r & ~f_busy_r1;

assign fram_addr_ptr_msb           		= fram_addr_ptr[9];//Add comparator logic for all options ,,512,256,128
assign fram_addr_ptr_msb_toggle           = fram_addr_ptr_msb & ~fram_addr_ptr_msb_r1;//Add comparator logic for all options ,,512,256,128

assign f_en_o                             = f_en;



always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		fram_addr_ptr 	  <= 0;
		frealdataload_done  <= 0;
		frealdataload_done1 <= 0;
		
		f_busy_r            <= 0;       
		f_busy_r1           <= 0;       
		fram_addr_ptr_msb_r1           <= 0;       
	end
	else
	begin
	    f_busy_r            	<= f_busy_i  ;
	    f_busy_r1           	<= f_busy_r;
		fram_addr_ptr_msb_r1  <= fram_addr_ptr_msb; 
	
	    if (f_busy_i | debug_rst_fram_ptr)
		begin
		   fram_addr_ptr 		 <= 0;
		end
		else
	    //if (WBs_ACK_sig_r & WBs_CYC_RealImg_RAM_i)
	    if (WBs_ACK_sig & WBs_CYC_RealImg_RAM_i)
	    begin
		   fram_addr_ptr <= fram_addr_ptr + 1;     
		end
		
		//if (f_busy_pulse)
		if (fram_addr_ptr_msb_toggle)
		begin
		   frealdataload_done  <= ~frealdataload_done;
		end
		frealdataload_done1    <= frealdataload_done;
    end
end

//assign f_done = f_done_i & ~ f_done_r;

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        f_en                                  <= 1'b0;
        f_point_reg                           <= 0;
		f_IRQ_o       	        			<= 1'b0;
		f_IRQ_EN_o       	    			    <= 1'b0;
		debug_rst_fram_ptr       	    			<= 1'b0;
		
        WBs_ACK_sig           					<= 1'b0; 
		WBs_ACK_sig_r           		    	<= 1'b0;
		
		//f_done_r                              <= 0;
		//f_done_r1                              <= 0;
		
    end  
    else
    begin
	    if ( fCTRL_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin
            f_en  		<=  WBs_DAT_i[0];
		end	
		
	    if ( fCTRL_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin
            debug_rst_fram_ptr  <=  WBs_DAT_i[2];
		end	
        else
           	 debug_rst_fram_ptr  <=  0; 	
	
        if ( fPNT_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            f_point_reg   <=  WBs_DAT_i[2:0];
		end	
			
		if ( INTR_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		    f_IRQ_EN_o    <=  WBs_DAT_i[0];
		end
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || f_done_i)
        begin
            f_IRQ_o   <=  f_done_i ? 1'b1 : WBs_DAT_i[0];
        end	

        		
		
        WBs_ACK_sig               <=  WBs_ACK_f_nxt;
		WBs_ACK_sig_r			  <=  WBs_ACK_sig;		
		
		//f_done_r                              <= f_done_i;
		//f_done_r1                             <= f_done_r;
		
    end  
end

`ifdef USEDMA0	
assign DMA0_Start 						= f_done_i | ~f_busy_i; 
assign DMA0_Start_o 				    = DMA0_Start & DMA0_EN;
`endif

`ifdef USEDMA1	
assign DMA1_Start 						= f_done_i; 
assign DMA1_Start_o 				    = DMA1_Start & DMA1_EN;
`endif

`ifdef USEDMA2	
assign DMA2_Start 						= f_done_i; 
assign DMA2_Start_o 				    = DMA2_Start & DMA2_EN;
`endif

`ifdef USEDMA3	
assign DMA3_Start 						= f_done_i; 
assign DMA3_Start_o 				    = DMA3_Start & DMA3_EN;
`endif

always @(*)
begin
     case (f_point_reg)
	   3'h0:   f_point_o <= 512;
	   3'h1:   f_point_o <= 256;
	   3'h2:   f_point_o <= 128;
	   3'h3:   f_point_o <= 64;
	   3'h4:   f_point_o <= 32;
	   default:   f_point_o <= 512;

	 
	 endcase
end	 
	 
always @(*)
begin
     case (f_point_reg)
	   3'h0:   stage_cnt_o <= 9;//8;//9;
	   3'h1:   stage_cnt_o <= 8;//7;//8;
	   3'h2:   stage_cnt_o <= 7;//6;//7;
	   3'h3:   stage_cnt_o <= 6;//5;//6;
	   3'h4:   stage_cnt_o <= 5;//
	   default:   stage_cnt_o <= 8;

	 
	 endcase
end	 

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
//`ifdef USEDMA0	
		DMA0_EN	 		    				    <= 1'b0;
		//DMA0_Done_IRQ_o	 					    <= 1'b0;
		DMA0_Done_IRQ_EN_o					    <= 1'b0;
//`endif		
//`ifdef USEDMA1			
		DMA1_EN	 		    				    <= 1'b0;
		DMA1_Done_IRQ_o	 					    <= 1'b0;
		DMA1_Done_IRQ_EN_o					    <= 1'b0;
//`endif		
//`ifdef USEDMA2			
		DMA2_EN	 		    				    <= 1'b0;
		DMA2_Done_IRQ_o	 					    <= 1'b0;
		DMA2_Done_IRQ_EN_o					    <= 1'b0;
//`endif		
//`ifdef USEDMA3			
		DMA3_EN	 		    				    <= 1'b0;
		DMA3_Done_IRQ_o	 					    <= 1'b0;		
		DMA3_Done_IRQ_EN_o					    <= 1'b0;
//`endif
    end  
    else
    begin
`ifdef USEDMA0		
        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA0_EN  <=  WBs_DAT_i[0];
		end	
		else if (DMA0_Clr_i)
		begin
			DMA0_EN  <=  1'b0;
		end
		
        if ( DMA_IRQ_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA0_Done_IRQ_EN_o  <=  WBs_DAT_i[0];
		end	

/* 		if ( (DMA_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA0_Done_i)
        begin
            DMA0_Done_IRQ_o   <=  DMA0_Done_i ? 1'b1 : WBs_DAT_i[0];
        end */
`endif		

`ifdef USEDMA1		
        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA1_EN  <=  WBs_DAT_i[1];
		end	
        else if (DMA1_Clr_i)
		begin
			DMA1_EN  <=  1'b0;
		end	
		
        if ( DMA_IRQ_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA1_Done_IRQ_EN_o  <=  WBs_DAT_i[1];
		end

/* 		if ( (DMA_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA1_Done_i)
        begin
            DMA1_Done_IRQ_o   <=  DMA1_Done_i ? 1'b1 : WBs_DAT_i[1];
        end	 */		
`endif	

`ifdef USEDMA2		
        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA2_EN  <=  WBs_DAT_i[2];
		end	
		else if (DMA2_Clr_i)
		begin
			DMA2_EN  <=  1'b0;
		end
		
        if ( DMA_IRQ_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA2_Done_IRQ_EN_o  <=  WBs_DAT_i[2];
		end	

/* 		if ( (DMA_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA2_Done_i)
        begin
            DMA2_Done_IRQ_o   <=  DMA2_Done_i ? 1'b1 : WBs_DAT_i[2];
        end	 */	
`endif	

`ifdef USEDMA3		
        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA3_EN  <=  WBs_DAT_i[3];
		end	
        else if (DMA3_Clr_i)
		begin
			DMA3_EN  <=  1'b0;
		end	
		
        if ( DMA_IRQ_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            DMA3_Done_IRQ_EN_o  <=  WBs_DAT_i[3];
		end		
		
/* 		if ( (DMA_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA3_Done_i)
        begin
            DMA3_Done_IRQ_o   <=  DMA3_Done_i ? 1'b1 : WBs_DAT_i[3];
        end	 */		
`endif	


    end  
end



always @( posedge WBs_CLK_i or posedge WBs_RST_i or posedge DMA0_Done_i)
begin
    if (WBs_RST_i)
    begin
	    DMA0_Done_IRQ_o   <= 1'b0;
	end
	else
    if (DMA0_Done_i)
    begin
	    DMA0_Done_IRQ_o   <= 1'b1;
	end	
	else
	begin
		if ( (DMA_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]))
        begin
            DMA0_Done_IRQ_o   <=  WBs_DAT_i[0];
        end	
	
	end
end	
	

assign DMA0_Done_pulse = DMA0_Done_IRQ_r1 & ~DMA0_Done_IRQ_r2;
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
     if (WBs_RST_i)
	 begin
	     ena_bit_rev_o <= 1'b1;
	     DMA0_Done_IRQ_r1 <= 1'b0;
	     DMA0_Done_IRQ_r2 <= 1'b0;
	 end
	 else
	 begin
	     if (DMA0_Done_pulse)  
	        ena_bit_rev_o <= ~ena_bit_rev_o;
			
		DMA0_Done_IRQ_r1 <= DMA0_Done_IRQ_o;	
		DMA0_Done_IRQ_r2 <= DMA0_Done_IRQ_r1;	
     end
end

//assign DMA_Status = {30'h0,Tx_DMA_Done_IRQ_o,DMA0_Done_IRQ_o};

// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              or
		 f_en                 or
            
	    f_point_reg           or
        f_IRQ_o       	    or
  	    f_IRQ_EN_o       	   

 		             
 )
 begin
    case(WBs_ADR_i[8:0])
	
	IDREV_REG_ADR    		 : WBs_DAT_o <= {4'h0,AL4S3B_DEVICE_ID[15:0],AL4S3B_REV_LEVEL[11:0]};
	f_CTRL_REG_ADR         : WBs_DAT_o <= { 31'h0,f_en}; 
	RESERVED                 : WBs_DAT_o <= 0;
	f_POINT_REG_ADR        : WBs_DAT_o <= { 29'h0,f_point_reg};
	INTR_STS_REG_ADR         : WBs_DAT_o <= { 31'h0,f_IRQ_o}; 
	INTR_EN_REG_ADR          : WBs_DAT_o <= { 31'h0,f_IRQ_EN_o}; 

	default                 : WBs_DAT_o <= 32'h0 ;
	endcase
end

always @(
         WBs_ADR_i              or
`ifdef USEDMA0	
		DMA0_EN	 		    	or		 
		DMA0_Done_IRQ_o	 		or		 
		DMA0_Done_IRQ_EN_o				 
`endif				 
`ifdef USEDMA1	
                                or				 
		DMA1_EN	 		    	or		 
		DMA1_Done_IRQ_o	 		or		 
		DMA1_Done_IRQ_EN_o				 
`endif				 
`ifdef USEDMA2	
                                or				 
		DMA2_EN	 		    	or		 
		DMA2_Done_IRQ_o	 		or		 
		DMA2_Done_IRQ_EN_o				 
`endif				 
`ifdef USEDMA3
                                or					 
		DMA3_EN	 		    	or		 
		DMA3_Done_IRQ_o	 		or				 
		DMA3_Done_IRQ_EN_o				 
`endif		 
	

 		             
 )
 begin
    case(WBs_ADR_i[8:0])
	
	  DMA_EN_REG_ADR       :   WBs_DMA_DAT_o <=  {28'h0,	DMA3_EN,	DMA2_EN,	DMA1_EN,	DMA0_EN};
	  DMA_STS_REG_ADR      :   WBs_DMA_DAT_o <=  {28'h0,	DMA3_Done_IRQ_o,	DMA2_Done_IRQ_o,	DMA1_Done_IRQ_o,	DMA0_Done_IRQ_o};
	  DMA_INTR_EN_REG_ADR  :   WBs_DMA_DAT_o <=  {28'h0,	DMA3_Done_IRQ_EN_o,	DMA2_Done_IRQ_EN_o,	DMA1_Done_IRQ_EN_o,	DMA0_Done_IRQ_EN_o};

	default                :   WBs_DMA_DAT_o <= 32'h0 ;
	endcase
end

	 
 
endmodule
