// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_Registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/03	
// last update    : 2016/02/03
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to registers and memory 
//              located in the programmable FPGA.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/02/03      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module AL4S3B_FPGA_Registers ( 

                         // AHB-To_FPGA Bridge I/F
                         //
                         WBs_ADR_i,
                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_CLK_i,
                         WBs_RST_i,
                         WBs_DAT_o,
                         WBs_ACK_o,

                         //
                         // Misc
                         //
						 CLK_4M_CNTL_o,
						 CLK_1M_CNTL_o,
                         Device_ID_o,
						 
						 Mode_Sel_o,  	     
						 PWM_En_o,  	         
						 Idle_Pol_o,          
						 
						 Freq_Cycle_Reg1_o,   
						 Freq_Cycle_Toggle1_o,
						 Duty_Cycle_Reg1_o,   
						 Duty_Cycle_Toggle1_o,
						 
						 Freq_Cycle_Reg2_o,   
						 Freq_Cycle_Toggle2_o,
						 Duty_Cycle_Reg2_o,   
						 Duty_Cycle_Toggle2_o,
						 
						 Freq_Cycle_Reg3_o,   
						 Freq_Cycle_Toggle3_o,
						 Duty_Cycle_Reg3_o,   
						 Duty_Cycle_Toggle3_o,
						 
						 Freq_Cycle_Reg4_o,   
						 Freq_Cycle_Toggle4_o,
						 Duty_Cycle_Reg4_o,   
						 Duty_Cycle_Toggle4_o,						 
						 
				         GPIO_IN_i,
				         GPIO_OUT_o,
				         GPIO_OE_o

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7  ;   // Allow for up to 128 registers in the FPGA
parameter                DATAWIDTH                   =  32  ;   // Allow for up to 128 registers in the FPGA

parameter                FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter                FPGA_MODE_SEL_ADR         =  7'h1; 
parameter                FPGA_GPIO_IN_REG_ADR1     =  7'h2; 
parameter                FPGA_GPIO_IN_REG_ADR2     =  7'h3;
parameter                FPGA_GPIO_OUT_REG_ADR1    =  7'h4; 
parameter                FPGA_GPIO_OUT_REG_ADR2    =  7'h5; 
parameter                FPGA_GPIO_OE_REG_ADR1     =  7'h6; 
parameter                FPGA_GPIO_OE_REG_ADR2     =  7'h7;

parameter                FPGA_PWM_EN_POL_ADR       =  7'h8; 
parameter                FPGA_DUTY_CYCLE_ADR1      =  7'h9; 
parameter                FPGA_FREQ_CYCLE_ADR1      =  7'hA;
parameter                FPGA_DUTY_CYCLE_ADR2      =  7'hB;
parameter                FPGA_FREQ_CYCLE_ADR2      =  7'hC;
parameter                FPGA_DUTY_CYCLE_ADR3      =  7'hD;
parameter                FPGA_FREQ_CYCLE_ADR3      =  7'hE;
parameter                FPGA_DUTY_CYCLE_ADR4      =  7'hF;
parameter                FPGA_FREQ_CYCLE_ADR4      =  7'h10;

parameter                AL4S3B_DEVICE_ID            = 16'h0;
parameter                AL4S3B_REV_LEVEL            = 32'h0;
parameter                AL4S3B_GPIO_REG             = 46'h0;
parameter                AL4S3B_GPIO_OE_REG          = 46'h0;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   FPGA
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   FPGA
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   FPGA
input                    WBs_WE_i      ;  // Write Enable               to   FPGA
input                    WBs_STB_i     ;  // Strobe Signal              to   FPGA
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   FPGA
input                    WBs_CLK_i     ;  // FPGA Clock               from FPGA
input                    WBs_RST_i     ;  // FPGA Reset               to   FPGA
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from FPGA
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from FPGA

//
// Misc
//
output           [31:0]  Device_ID_o   ;

output 					 CLK_4M_CNTL_o;
output 					 CLK_1M_CNTL_o;

// GPIO
//
input            [45:0]  GPIO_IN_i     ;
output           [45:0]  GPIO_OUT_o    ;
output           [45:0]  GPIO_OE_o     ;

output           [3:0]   Mode_Sel_o;  	     
output           [3:0]   PWM_En_o  ;	         
output           [3:0]   Idle_Pol_o ;         

output           [15:0]  Freq_Cycle_Reg1_o ;  
output                   Freq_Cycle_Toggle1_o;
output           [15:0]  Duty_Cycle_Reg1_o   ;
output                   Duty_Cycle_Toggle1_o;

output           [15:0]  Freq_Cycle_Reg2_o   ;
output                   Freq_Cycle_Toggle2_o;
output           [15:0]  Duty_Cycle_Reg2_o   ;
output                   Duty_Cycle_Toggle2_o;

output           [15:0]  Freq_Cycle_Reg3_o   ;
output                   Freq_Cycle_Toggle3_o;
output           [15:0]  Duty_Cycle_Reg3_o   ;
output                   Duty_Cycle_Toggle3_o;

output           [15:0]  Freq_Cycle_Reg4_o   ;
output                   Freq_Cycle_Toggle4_o;
output           [15:0]  Duty_Cycle_Reg4_o   ;
output                   Duty_Cycle_Toggle4_o;


// FPGA Global Signals
//
wire                     WBs_CLK_i     ;  // Wishbone FPGA Clock
wire                     WBs_RST_i     ;  // Wishbone FPGA Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Wishbone Address Bus
wire                     WBs_CYC_i     ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [3:0]  WBs_BYTE_STB_i;  // Wishbone Byte   Enables
wire                     WBs_WE_i      ;  // Wishbone Write  Enable Strobe
wire                     WBs_STB_i     ;  // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Wishbone Read   Data Bus

reg                      WBs_ACK_o     ;  // Wishbone Client Acknowledge

// Misc
//
reg               [31:0]  Device_ID_o   ;

// GPIO
//
wire             [45:0]  GPIO_IN_i     ;
reg              [45:0]  GPIO_OUT_o    ;
reg              [45:0]  GPIO_OE_o     ;

reg              [3:0]   Mode_Sel_o;  	     
reg              [3:0]   PWM_En_o  ;	         
reg              [3:0]   Idle_Pol_o ;        

reg              [15:0]  Freq_Cycle_Reg1_o ;  
reg                      Freq_Cycle_Toggle1_o;
reg              [15:0]  Duty_Cycle_Reg1_o   ;
reg                      Duty_Cycle_Toggle1_o; 

reg              [15:0]  Freq_Cycle_Reg2_o   ;
reg                      Freq_Cycle_Toggle2_o;
reg              [15:0]  Duty_Cycle_Reg2_o   ;
reg                      Duty_Cycle_Toggle2_o;

reg              [15:0]  Freq_Cycle_Reg3_o   ;
reg                      Freq_Cycle_Toggle3_o;
reg              [15:0]  Duty_Cycle_Reg3_o   ;
reg                      Duty_Cycle_Toggle3_o;

reg              [15:0]  Freq_Cycle_Reg4_o   ;
reg                      Freq_Cycle_Toggle4_o;
reg              [15:0]  Duty_Cycle_Reg4_o   ;
reg                      Duty_Cycle_Toggle4_o;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire					 FB_Dev_ID_Wr_Dcd      ;
wire                     FB_Mode_Sel_Wr_Dcd    ;
wire                     FB_GPIO_Reg_Wr_Dcd1    ;
wire                     FB_GPIO_Reg_Wr_Dcd2    ;
wire                     FB_GPIO_OE_Reg_Wr_Dcd1 ;
wire                     FB_GPIO_OE_Reg_Wr_Dcd2 ;
wire                     FB_PWM_En_Pol_Wr_Dcd ;

wire                     FB_Dut_Cyc_Wr_Dcd1 ;
wire                     FB_Freq_Cyc_Wr_Dcd1 ;

wire                     FB_Dut_Cyc_Wr_Dcd2 ;
wire                     FB_Freq_Cyc_Wr_Dcd2 ;

wire                     FB_Dut_Cyc_Wr_Dcd3 ;
wire                     FB_Freq_Cyc_Wr_Dcd3 ;

wire                     FB_Dut_Cyc_Wr_Dcd4 ;
wire                     FB_Freq_Cyc_Wr_Dcd4 ;

reg                      dut_cyc1_wr_r1;  
reg                      dut_cyc1_wr_r2;
wire                     dut_cyc1_wr_pos;

reg                      freq_cyc1_wr_r1;  
reg                      freq_cyc1_wr_r2;
wire                     freq_cyc1_wr_pos;

reg                      dut_cyc2_wr_r1;  
reg                      dut_cyc2_wr_r2;
wire                     dut_cyc2_wr_pos;

reg                      freq_cyc2_wr_r1;  
reg                      freq_cyc2_wr_r2;
wire                     freq_cyc2_wr_pos;

reg                      dut_cyc3_wr_r1;  
reg                      dut_cyc3_wr_r2;
wire                     dut_cyc3_wr_pos;

reg                      freq_cyc3_wr_r1;  
reg                      freq_cyc3_wr_r2;
wire                     freq_cyc3_wr_pos;

reg                      dut_cyc4_wr_r1;  
reg                      dut_cyc4_wr_r2;
wire                     dut_cyc4_wr_pos;

reg                      freq_cyc4_wr_r1;  
reg                      freq_cyc4_wr_r2;
wire                     freq_cyc4_wr_pos;

wire					 WBs_ACK_o_nxt;


//------Logic Operations---------------
//
assign CLK_4M_CNTL_o = 1'b0 ;
assign CLK_1M_CNTL_o = 1'b0 ;


// Define the FPGA's local register write enables
//
assign FB_Dev_ID_Wr_Dcd       = ( WBs_ADR_i == FPGA_REG_ID_VALUE_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Mode_Sel_Wr_Dcd     = ( WBs_ADR_i == FPGA_MODE_SEL_ADR  ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_Reg_Wr_Dcd1    = ( WBs_ADR_i == FPGA_GPIO_OUT_REG_ADR1    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_Reg_Wr_Dcd2    = ( WBs_ADR_i == FPGA_GPIO_OUT_REG_ADR2    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_OE_Reg_Wr_Dcd1 = ( WBs_ADR_i == FPGA_GPIO_OE_REG_ADR1     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_OE_Reg_Wr_Dcd2 = ( WBs_ADR_i == FPGA_GPIO_OE_REG_ADR2     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_PWM_En_Pol_Wr_Dcd  = ( WBs_ADR_i == FPGA_PWM_EN_POL_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);  

assign FB_Dut_Cyc_Wr_Dcd1  = ( WBs_ADR_i == FPGA_DUTY_CYCLE_ADR1 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o); 
assign FB_Freq_Cyc_Wr_Dcd1  = ( WBs_ADR_i == FPGA_FREQ_CYCLE_ADR1 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_Dut_Cyc_Wr_Dcd2  = ( WBs_ADR_i == FPGA_DUTY_CYCLE_ADR2 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Freq_Cyc_Wr_Dcd2  = ( WBs_ADR_i == FPGA_FREQ_CYCLE_ADR2 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_Dut_Cyc_Wr_Dcd3  = ( WBs_ADR_i == FPGA_DUTY_CYCLE_ADR3 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Freq_Cyc_Wr_Dcd3  = ( WBs_ADR_i == FPGA_FREQ_CYCLE_ADR3 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_Dut_Cyc_Wr_Dcd4  = ( WBs_ADR_i == FPGA_DUTY_CYCLE_ADR4 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Freq_Cyc_Wr_Dcd4  = ( WBs_ADR_i == FPGA_FREQ_CYCLE_ADR4 ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o); 

// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the FPGA's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		Mode_Sel_o    	  <= 4'h0    ;    
		PWM_En_o    	  <= 4'h0    ;
		Idle_Pol_o    	  <= 4'h0    ;
        GPIO_OUT_o        <= AL4S3B_GPIO_REG     ;
        GPIO_OE_o         <= AL4S3B_GPIO_OE_REG  ;
        WBs_ACK_o         <=  1'b0               ;
		Device_ID_o		  <=  32'hce1a0001        ;
		Duty_Cycle_Reg1_o <=  16'h0               ; 
		Freq_Cycle_Reg1_o <=  16'h0               ;
		Duty_Cycle_Reg2_o <=  16'h0               ;
		Freq_Cycle_Reg2_o <=  16'h0               ;
		Duty_Cycle_Reg3_o <=  16'h0               ;
		Freq_Cycle_Reg3_o <=  16'h0               ;
		Duty_Cycle_Reg4_o <=  16'h0               ;
		Freq_Cycle_Reg4_o <=  16'h0               ; 
    end  
    else
    begin
	
		if(FB_Dev_ID_Wr_Dcd && WBs_BYTE_STB_i[0])
			Device_ID_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Dev_ID_Wr_Dcd && WBs_BYTE_STB_i[1])
			Device_ID_o[15:8]         <= WBs_DAT_i[15:8] ;

        if(FB_Dev_ID_Wr_Dcd && WBs_BYTE_STB_i[2])
			Device_ID_o[23:16]        <= WBs_DAT_i[23:16];

        if(FB_Dev_ID_Wr_Dcd && WBs_BYTE_STB_i[3])
			Device_ID_o[31:24]        <= WBs_DAT_i[31:24];	
		
        //		

        if(FB_Mode_Sel_Wr_Dcd   && WBs_BYTE_STB_i[0])
			Mode_Sel_o[3:0]     <= WBs_DAT_i[3:0]  ;

        // Define the GPIO Register 
        //
        if(FB_GPIO_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[0]) 
			GPIO_OUT_o[7:0]         <= WBs_DAT_i[7:0]  ;

        if(FB_GPIO_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[1])
			GPIO_OUT_o[15:8]        <= WBs_DAT_i[15:8] ;

        if(FB_GPIO_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[2])
			GPIO_OUT_o[23:16]       <= WBs_DAT_i[23:16];
			
		if(FB_GPIO_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[3])
			GPIO_OUT_o[31:24]       <= WBs_DAT_i[31:24];
			
		if(FB_GPIO_Reg_Wr_Dcd2    && WBs_BYTE_STB_i[0]) 
			GPIO_OUT_o[39:32]         <= WBs_DAT_i[7:0]  ;
			
		if(FB_GPIO_Reg_Wr_Dcd2    && WBs_BYTE_STB_i[1]) 
			GPIO_OUT_o[45:40]         <= WBs_DAT_i[13:8]  ;


        // Define the GPIO Control Register 
        //
        if(FB_GPIO_OE_Reg_Wr_Dcd1 && WBs_BYTE_STB_i[0])
			GPIO_OE_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_GPIO_OE_Reg_Wr_Dcd1 && WBs_BYTE_STB_i[1])
			GPIO_OE_o[15:8]         <= WBs_DAT_i[15:8] ;

        if(FB_GPIO_OE_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[2])
			GPIO_OE_o[23:16]       <= WBs_DAT_i[23:16];
			
		if(FB_GPIO_OE_Reg_Wr_Dcd1    && WBs_BYTE_STB_i[3])
			GPIO_OE_o[31:24]       <= WBs_DAT_i[31:24];
		
	    if(FB_GPIO_OE_Reg_Wr_Dcd2    && WBs_BYTE_STB_i[0]) 
			GPIO_OE_o[39:32]         <= WBs_DAT_i[7:0]  ;
			
		if(FB_GPIO_OE_Reg_Wr_Dcd2    && WBs_BYTE_STB_i[1]) 
			GPIO_OE_o[45:40]         <= WBs_DAT_i[13:8]  ;
			
		//pwm_en & pol
		if(FB_PWM_En_Pol_Wr_Dcd && WBs_BYTE_STB_i[0])
			PWM_En_o[3:0]          <= WBs_DAT_i[3:0]  ;  

        if(FB_PWM_En_Pol_Wr_Dcd && WBs_BYTE_STB_i[1])
			Idle_Pol_o[3:0]        <= WBs_DAT_i[11:8] ;	
			
        // duty cycle & freq cycle reg   
		//#1
		if(FB_Dut_Cyc_Wr_Dcd1 && WBs_BYTE_STB_i[0])   
			Duty_Cycle_Reg1_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Dut_Cyc_Wr_Dcd1 && WBs_BYTE_STB_i[1])
			Duty_Cycle_Reg1_o[15:8]         <= WBs_DAT_i[15:8] ;

		if(FB_Freq_Cyc_Wr_Dcd1 && WBs_BYTE_STB_i[0])   
			Freq_Cycle_Reg1_o[7:0]          <= WBs_DAT_i[7:0]  ; 

        if(FB_Freq_Cyc_Wr_Dcd1 && WBs_BYTE_STB_i[1])
			Freq_Cycle_Reg1_o[15:8]         <= WBs_DAT_i[15:8] ;
		
		//#2
		if(FB_Dut_Cyc_Wr_Dcd2 && WBs_BYTE_STB_i[0])   
			Duty_Cycle_Reg2_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Dut_Cyc_Wr_Dcd2 && WBs_BYTE_STB_i[1])
			Duty_Cycle_Reg2_o[15:8]         <= WBs_DAT_i[15:8] ;

		if(FB_Freq_Cyc_Wr_Dcd2 && WBs_BYTE_STB_i[0])   
			Freq_Cycle_Reg2_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Freq_Cyc_Wr_Dcd2 && WBs_BYTE_STB_i[1])
			Freq_Cycle_Reg2_o[15:8]         <= WBs_DAT_i[15:8] ;
		
		//#3
		if(FB_Dut_Cyc_Wr_Dcd3 && WBs_BYTE_STB_i[0])   
			Duty_Cycle_Reg3_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Dut_Cyc_Wr_Dcd3 && WBs_BYTE_STB_i[1])
			Duty_Cycle_Reg3_o[15:8]         <= WBs_DAT_i[15:8] ;

		if(FB_Freq_Cyc_Wr_Dcd3 && WBs_BYTE_STB_i[0])   
			Freq_Cycle_Reg3_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Freq_Cyc_Wr_Dcd3 && WBs_BYTE_STB_i[1])
			Freq_Cycle_Reg3_o[15:8]         <= WBs_DAT_i[15:8] ;
		
		//#4
		if(FB_Dut_Cyc_Wr_Dcd4 && WBs_BYTE_STB_i[0])   
			Duty_Cycle_Reg4_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Dut_Cyc_Wr_Dcd4 && WBs_BYTE_STB_i[1])
			Duty_Cycle_Reg4_o[15:8]         <= WBs_DAT_i[15:8] ;

		if(FB_Freq_Cyc_Wr_Dcd4 && WBs_BYTE_STB_i[0])   
			Freq_Cycle_Reg4_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_Freq_Cyc_Wr_Dcd4 && WBs_BYTE_STB_i[1])
			Freq_Cycle_Reg4_o[15:8]         <= WBs_DAT_i[15:8] ;

        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
    end  
end

// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i         or
         Device_ID_o       or
         Mode_Sel_o		   or
         GPIO_IN_i         or
         GPIO_OUT_o        or
         GPIO_OE_o         or       
         PWM_En_o          or
		 Idle_Pol_o        or
		 Duty_Cycle_Reg1_o or
		 Freq_Cycle_Reg1_o or
		 Duty_Cycle_Reg2_o or
		 Freq_Cycle_Reg2_o or
		 Duty_Cycle_Reg3_o or
		 Freq_Cycle_Reg3_o or
		 Duty_Cycle_Reg4_o or
		 Freq_Cycle_Reg4_o 
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    FPGA_REG_ID_VALUE_ADR     : WBs_DAT_o <= Device_ID_o         			 ;
    FPGA_MODE_SEL_ADR         : WBs_DAT_o <= { 28'h0, Mode_Sel_o		    };  
    FPGA_GPIO_IN_REG_ADR1     : WBs_DAT_o <= GPIO_IN_i[31:0]               ; 
	FPGA_GPIO_IN_REG_ADR2     : WBs_DAT_o <= { 18'h0, GPIO_IN_i[45:32]    };
    FPGA_GPIO_OUT_REG_ADR1    : WBs_DAT_o <= GPIO_OUT_o[31:0]              ;
	FPGA_GPIO_OUT_REG_ADR2    : WBs_DAT_o <= { 18'h0, GPIO_OUT_o[45:32]    };
    FPGA_GPIO_OE_REG_ADR1     : WBs_DAT_o <= GPIO_OE_o[31:0]               ;
	FPGA_GPIO_OE_REG_ADR2     : WBs_DAT_o <= { 18'h0, GPIO_OE_o[45:32]    };
    FPGA_PWM_EN_POL_ADR       : WBs_DAT_o <= { 16'h0,4'h0,Idle_Pol_o,4'h0,PWM_En_o};	  	
    FPGA_DUTY_CYCLE_ADR1      : WBs_DAT_o <= { 16'h0,Duty_Cycle_Reg1_o};	  
    FPGA_FREQ_CYCLE_ADR1      : WBs_DAT_o <= { 16'h0,Freq_Cycle_Reg1_o};		
    FPGA_DUTY_CYCLE_ADR2      : WBs_DAT_o <= { 16'h0,Duty_Cycle_Reg2_o};	  
    FPGA_FREQ_CYCLE_ADR2      : WBs_DAT_o <= { 16'h0,Freq_Cycle_Reg2_o};	
    FPGA_DUTY_CYCLE_ADR3      : WBs_DAT_o <= { 16'h0,Duty_Cycle_Reg3_o};	  
    FPGA_FREQ_CYCLE_ADR3      : WBs_DAT_o <= { 16'h0,Freq_Cycle_Reg3_o};	
    FPGA_DUTY_CYCLE_ADR4      : WBs_DAT_o <= { 16'h0,Duty_Cycle_Reg4_o};	  
    FPGA_FREQ_CYCLE_ADR4      : WBs_DAT_o <= { 16'h0,Freq_Cycle_Reg4_o};	
	default                     : WBs_DAT_o <= AL4S3B_DEF_REG_VALUE 		 ;
	endcase
end


//
//
//PWM1
always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      dut_cyc1_wr_r1    <= 1'b0;
	  dut_cyc1_wr_r2    <= 1'b0;
	end
  else begin
      dut_cyc1_wr_r1    <= FB_Dut_Cyc_Wr_Dcd1;
	  dut_cyc1_wr_r2    <= dut_cyc1_wr_r1;
	end
end
assign dut_cyc1_wr_pos = dut_cyc1_wr_r1 & ~dut_cyc1_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Duty_Cycle_Toggle1_o    <= 1'b0;
	end
  else begin
      if (dut_cyc1_wr_pos)
        Duty_Cycle_Toggle1_o    <= 1'b1;
	  else
	    Duty_Cycle_Toggle1_o    <= 1'b0;
	end
end

always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      freq_cyc1_wr_r1    <= 1'b0;
	  freq_cyc1_wr_r2    <= 1'b0;
	end
  else begin
      freq_cyc1_wr_r1    <= FB_Freq_Cyc_Wr_Dcd1;
	  freq_cyc1_wr_r2    <= freq_cyc1_wr_r1;
	end
end
assign freq_cyc1_wr_pos = freq_cyc1_wr_r1 & ~freq_cyc1_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Freq_Cycle_Toggle1_o    <= 1'b0;
	end
  else begin
      if (freq_cyc1_wr_pos)
        Freq_Cycle_Toggle1_o    <= 1'b1;
	  else
	    Freq_Cycle_Toggle1_o    <= 1'b0;
	end
end

//PWM2
always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      dut_cyc2_wr_r1    <= 1'b0;
	  dut_cyc2_wr_r2    <= 1'b0;
	end
  else begin
      dut_cyc2_wr_r1    <= FB_Dut_Cyc_Wr_Dcd2;
	  dut_cyc2_wr_r2    <= dut_cyc2_wr_r1;
	end
end
assign dut_cyc2_wr_pos = dut_cyc2_wr_r1 & ~dut_cyc2_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Duty_Cycle_Toggle2_o    <= 1'b0;
	end
  else begin
      if (dut_cyc2_wr_pos)
        Duty_Cycle_Toggle2_o    <= 1'b1;
	  else
	    Duty_Cycle_Toggle2_o    <= 1'b0;
	end
end

always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      freq_cyc2_wr_r1    <= 1'b0;
	  freq_cyc2_wr_r2    <= 1'b0;
	end
  else begin
      freq_cyc2_wr_r1    <= FB_Freq_Cyc_Wr_Dcd2;
	  freq_cyc2_wr_r2    <= freq_cyc2_wr_r1;
	end
end
assign freq_cyc2_wr_pos = freq_cyc2_wr_r1 & ~freq_cyc2_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Freq_Cycle_Toggle2_o    <= 1'b0;
	end
  else begin
      if (freq_cyc2_wr_pos)
        Freq_Cycle_Toggle2_o    <= 1'b1;
	  else
	    Freq_Cycle_Toggle2_o    <= 1'b0;
	end
end	

//PWM3
always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      dut_cyc3_wr_r1    <= 1'b0;
	  dut_cyc3_wr_r2    <= 1'b0;
	end
  else begin
      dut_cyc3_wr_r1    <= FB_Dut_Cyc_Wr_Dcd3;
	  dut_cyc3_wr_r2    <= dut_cyc3_wr_r1;
	end
end
assign dut_cyc3_wr_pos = dut_cyc3_wr_r1 & ~dut_cyc3_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Duty_Cycle_Toggle3_o    <= 1'b0;
	end
  else begin
      if (dut_cyc3_wr_pos)
        Duty_Cycle_Toggle3_o    <= 1'b1;
	  else
	    Duty_Cycle_Toggle3_o    <= 1'b0;
	end
end

always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      freq_cyc3_wr_r1    <= 1'b0;
	  freq_cyc3_wr_r2    <= 1'b0;
	end
  else begin
      freq_cyc3_wr_r1    <= FB_Freq_Cyc_Wr_Dcd3;
	  freq_cyc3_wr_r2    <= freq_cyc3_wr_r1;
	end
end
assign freq_cyc3_wr_pos = freq_cyc3_wr_r1 & ~freq_cyc3_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Freq_Cycle_Toggle3_o    <= 1'b0;
	end
  else begin
      if (freq_cyc3_wr_pos)
        Freq_Cycle_Toggle3_o    <= 1'b1;
	  else
	    Freq_Cycle_Toggle3_o    <= 1'b0;
	end
end	

//PWM4
always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      dut_cyc4_wr_r1    <= 1'b0;
	  dut_cyc4_wr_r2    <= 1'b0;
	end
  else begin
      dut_cyc4_wr_r1    <= FB_Dut_Cyc_Wr_Dcd4;
	  dut_cyc4_wr_r2    <= dut_cyc4_wr_r1;
	end
end
assign dut_cyc4_wr_pos = dut_cyc4_wr_r1 & ~dut_cyc4_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Duty_Cycle_Toggle4_o    <= 1'b0;
	end
  else begin
      if (dut_cyc4_wr_pos)
        Duty_Cycle_Toggle4_o    <= 1'b1;
	  else
	    Duty_Cycle_Toggle4_o    <= 1'b0;
	end
end

always @ (posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
  if ( WBs_RST_i ) begin
      freq_cyc4_wr_r1    <= 1'b0;
	  freq_cyc4_wr_r2    <= 1'b0;
	end
  else begin
      freq_cyc4_wr_r1    <= FB_Freq_Cyc_Wr_Dcd4;
	  freq_cyc4_wr_r2    <= freq_cyc4_wr_r1;
	end
end
assign freq_cyc4_wr_pos = freq_cyc4_wr_r1 & ~freq_cyc4_wr_r2;

always @ (posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
  if ( WBs_RST_i ) begin
        Freq_Cycle_Toggle4_o    <= 1'b0;
	end
  else begin
      if (freq_cyc4_wr_pos)
        Freq_Cycle_Toggle4_o    <= 1'b1;
	  else
	    Freq_Cycle_Toggle4_o    <= 1'b0;
	end
end	

endmodule
