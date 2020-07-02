
`timescale 1ns/10ps
module ahb_gen_bfm       (

                         A2F_HCLK,
                         A2F_HRESET,

                         A2F_HADDRS,
                         A2F_HSEL,
                         A2F_HTRANSS,
                         A2F_HSIZES,
                         A2F_HWRITES,
                         A2F_HREADYS,
                         A2F_HWDATAS,

                         A2F_HREADYOUTS,
                         A2F_HRESPS,
                         A2F_HRDATAS

			             );

parameter                ADDRWIDTH                   = 32;
parameter                DATAWIDTH                   = 32;

parameter                DEFAULT_AHB_ADDRESS         = {(ADDRWIDTH){1'b1}};

parameter                STD_CLK_DLY                 = 2;

parameter                ENABLE_AHB_REG_WR_DEBUG_MSG = 1'b1;
parameter                ENABLE_AHB_REG_RD_DEBUG_MSG = 1'b1;

parameter                TEST_MSG_ARRAY_SIZE         = (64 * 8);

input                    A2F_HCLK;
input                    A2F_HRESET;

output  [ADDRWIDTH-1:0]  A2F_HADDRS;
output                   A2F_HSEL;
output            [1:0]  A2F_HTRANSS;
output            [2:0]  A2F_HSIZES;
output                   A2F_HWRITES;
output                   A2F_HREADYS;
output  [DATAWIDTH-1:0]  A2F_HWDATAS;

input                    A2F_HREADYOUTS;
input                    A2F_HRESPS;
input   [DATAWIDTH-1:0]  A2F_HRDATAS;


wire                     A2F_HCLK;
wire                     A2F_HRESET;

reg     [ADDRWIDTH-1:0]  A2F_HADDRS;
reg                      A2F_HSEL;
reg               [1:0]  A2F_HTRANSS;
reg               [2:0]  A2F_HSIZES;
reg                      A2F_HWRITES;
reg                      A2F_HREADYS;
reg     [DATAWIDTH-1:0]  A2F_HWDATAS;

wire                     A2F_HREADYOUTS;
wire                     A2F_HRESPS;
wire    [DATAWIDTH-1:0]  A2F_HRDATAS;


reg	   [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg1;  
reg	   [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg2;  
reg	   [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg3;  
reg	   [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg4;  
reg    [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg5;  
reg    [TEST_MSG_ARRAY_SIZE-1:0]  ahb_bfm_msg6;  

initial
begin

    A2F_HADDRS   <=  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL     <=  1'b0;                 
    A2F_HTRANSS  <=  2'h0;                 
    A2F_HSIZES   <=  3'h0;                 
    A2F_HWRITES  <=  1'b0;                 
    A2F_HREADYS  <=  1'b0;                 
    A2F_HWDATAS  <=  {(DATAWIDTH){1'b0}};  

	ahb_bfm_msg1 <= "NO ACTIVITY";		
	ahb_bfm_msg2 <= "NO ACTIVITY";		
	ahb_bfm_msg3 <= "NO ACTIVITY";		
	ahb_bfm_msg4 <= "NO ACTIVITY";		
    ahb_bfm_msg5 <= "NO ACTIVITY";      
    ahb_bfm_msg6 <= "NO ACTIVITY";      
end

`ifdef GSIM
task ahb_read_al4s3b_fabric;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
input             [2:0]	TARGET_XFR_SIZE;       
output  [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg1  = "AHB Single Read";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  TARGET_ADDRESS;       


    A2F_HSEL      =  1'b1;                 
    A2F_HREADYS   =  1'b1;                 
    A2F_HTRANSS   =  2'h2;                 

    A2F_HSIZES    =  TARGET_XFR_SIZE;      

    A2F_HWRITES   =  1'b0;                 
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}};  

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";

    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";

end
endtask


task ahb_write_al4s3b_fabric;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
input             [2:0]	TARGET_XFR_SIZE;       
input   [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg1  = "AHB Single Write";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  TARGET_ADDRESS;       

    A2F_HSEL      =  1'b1;                 
    A2F_HREADYS   =  1'b1;                 
    A2F_HTRANSS   =  2'h2;                 
	
    A2F_HSIZES    =  TARGET_XFR_SIZE;     

    A2F_HWRITES   =  1'b1;                
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}}; 

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";

    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 
    A2F_HWDATAS   =  TARGET_DATA;          
    A2F_HWRITES   =  1'b0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";

end
endtask

task ahb_read_word_al4s3b_fabric;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
output  [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin
	
    wait (A2F_HRESET == 0);
    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg1  = "AHB Single Read";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  TARGET_ADDRESS;       

    A2F_HSEL      =  1'b1;                
    A2F_HREADYS   =  1'b1;                
    A2F_HTRANSS   =  2'h2;                

    A2F_HSIZES    =  3'b010;               

    A2F_HWRITES   =  1'b0;                 
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}};  

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";


    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";

end
endtask


task ahb_write_word_al4s3b_fabric;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
input   [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin

	wait (A2F_HRESET == 0);
	
    @(posedge A2F_HCLK) #STD_CLK_DLY;


	ahb_bfm_msg1  = "AHB Single Write";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  TARGET_ADDRESS;      

    A2F_HSEL      =  1'b1;                
    A2F_HREADYS   =  1'b1;                
    A2F_HTRANSS   =  2'h2;                

    A2F_HSIZES    =  3'b010;               

    A2F_HWRITES   =  1'b1;                 
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}};  

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";


    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 
    A2F_HWDATAS   =  TARGET_DATA;          
    A2F_HWRITES   =  1'b0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";
	
end
endtask

task ahb_write_al4s3b_fabric_mod;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
input             [2:0]	TARGET_XFR_SIZE;       
input   [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg1  = "AHB Single Write";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  {TARGET_ADDRESS[ADDRWIDTH-1:11],(TARGET_ADDRESS[10:0] << 2)} ;       

    A2F_HSEL      =  1'b1;                
    A2F_HREADYS   =  1'b1;                
    A2F_HTRANSS   =  2'h2;                

    A2F_HSIZES    =  TARGET_XFR_SIZE;    

    A2F_HWRITES   =  1'b1;               
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}};

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";

    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 
    A2F_HWDATAS   =  TARGET_DATA;          
    A2F_HWRITES   =  1'b0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";

end
endtask


task ahb_read_al4s3b_fabric_mod;
input   [ADDRWIDTH-1:0]	TARGET_ADDRESS;        
input             [2:0]	TARGET_XFR_SIZE;       
output  [DATAWIDTH-1:0]	TARGET_DATA;           

reg     [DATAWIDTH-1:0]   read_data;

integer i, j, k;

begin

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg1  = "AHB Single Read";
	ahb_bfm_msg2  = "Address Phase";
	ahb_bfm_msg3  = "SEQ";

    A2F_HADDRS    =  {TARGET_ADDRESS[ADDRWIDTH-1:11],(TARGET_ADDRESS[10:0] << 2)} ;       

    A2F_HSEL      =  1'b1;                 
    A2F_HREADYS   =  1'b1;                 
    A2F_HTRANSS   =  2'h2;                 

    A2F_HSIZES    =  TARGET_XFR_SIZE;      

    A2F_HWRITES   =  1'b0;                 
    A2F_HWDATAS   =  {(DATAWIDTH){1'b0}};  

    @(posedge A2F_HCLK) #STD_CLK_DLY;

	ahb_bfm_msg2  = "Data Phase";
	ahb_bfm_msg3  = "IDLE";
	ahb_bfm_msg4  = "Waiting for Slave";

    A2F_HADDRS    =  DEFAULT_AHB_ADDRESS;  
    A2F_HSEL      =  1'b0;                 
    A2F_HTRANSS   =  2'h0;                 
    A2F_HSIZES    =  3'h0;                 

	while (A2F_HREADYOUTS == 1'b0)
    begin
        @(posedge A2F_HCLK) #STD_CLK_DLY;
    end

    A2F_HREADYS   =  1'b0;             
    TARGET_DATA   = A2F_HRDATAS;       

	ahb_bfm_msg1 <= "NO ACTIVITY";
	ahb_bfm_msg2 <= "NO ACTIVITY";
	ahb_bfm_msg3 <= "NO ACTIVITY";
	ahb_bfm_msg4 <= "NO ACTIVITY";
	ahb_bfm_msg5 <= "NO ACTIVITY";
	ahb_bfm_msg6 <= "NO ACTIVITY";

end
endtask
`endif

endmodule

`timescale 1ns/10ps
module	oscillator_s1 
		(

		OSC_CLK_EN,
		OSC_CLK

		);

parameter 		T_CYCLE_CLK = (1000.0/19.2);

input			OSC_CLK_EN;
output			OSC_CLK;

wire			OSC_CLK_EN;
wire			OSC_CLK;

reg				osc_int_clk;


assign	OSC_CLK = OSC_CLK_EN ? osc_int_clk : 1'bZ;

initial
begin
	osc_int_clk	= 0;	
`ifdef GSIM
	forever				
	begin
		#(T_CYCLE_CLK/2) osc_int_clk = 1;
		#(T_CYCLE_CLK/2) osc_int_clk = 0;
	end 
`endif
end

endmodule

`timescale 1ns/10ps
module sdma_bfm       (

  						sdma_req_i,
						sdma_sreq_i,
						sdma_done_o,
						sdma_active_o

			             );
						 
input    [3:0]  	sdma_req_i;											 
input    [3:0]  	sdma_sreq_i;												 
output   [3:0]  	sdma_done_o;						
output   [3:0]  	sdma_active_o;	

reg [3:0] sdma_done_sig;
reg [3:0] sdma_active_sig;

assign sdma_done_o 		= sdma_done_sig;
assign sdma_active_o 	= sdma_active_sig;

initial 
begin
sdma_done_sig 	<= 4'h0;
sdma_active_sig <= 4'h0;

end

`ifdef GSIM
task drive_dma_active;
input [3:0] dma_active_i;
begin
    sdma_active_sig <= dma_active_i;
	#100;
end
endtask
`endif
endmodule					

`timescale 1ns / 10ps
module ahb2fb_asynbrig_if (

                           A2F_HCLK,       
                           A2F_HRESET,     

                           A2F_HSEL,
                           A2F_HADDRS,
                           A2F_HTRANSS,
                           A2F_HSIZES,
                           A2F_HWRITES,
                           A2F_HREADYS,

                           A2F_HREADYOUTS,
                           A2F_HRESPS,

                           AHB_ASYNC_ADDR_O,
                           AHB_ASYNC_READ_EN_O,
                           AHB_ASYNC_WRITE_EN_O,
                           AHB_ASYNC_BYTE_STROBE_O,

                           AHB_ASYNC_STB_TOGGLE_O,

                           FABRIC_ASYNC_ACK_TOGGLE_I

					       );


    parameter    DATAWIDTH              = 32;
	parameter    APERWIDTH              = 17;

	parameter    STATE_WIDTH            = 1;

	parameter    AHB_ASYNC_IDLE         = 0;
	parameter    AHB_ASYNC_WAIT         = 1;

    input                    A2F_HCLK;       
    input                    A2F_HRESET;     

    input    [APERWIDTH-1:0] A2F_HADDRS;
    input                    A2F_HSEL;
    input              [1:0] A2F_HTRANSS;
    input              [2:0] A2F_HSIZES;
    input                    A2F_HWRITES;
    input                    A2F_HREADYS;

    output                   A2F_HREADYOUTS;
    output                   A2F_HRESPS;

    output   [APERWIDTH-1:0] AHB_ASYNC_ADDR_O;
    output                   AHB_ASYNC_READ_EN_O;
    output                   AHB_ASYNC_WRITE_EN_O;
    output             [3:0] AHB_ASYNC_BYTE_STROBE_O;

    output                   AHB_ASYNC_STB_TOGGLE_O;

    input                    FABRIC_ASYNC_ACK_TOGGLE_I;

    wire                     A2F_HCLK;      
    wire                     A2F_HRESET;    

    wire     [APERWIDTH-1:0] A2F_HADDRS;
    wire                     A2F_HSEL;
    wire               [1:0] A2F_HTRANSS;
    wire               [2:0] A2F_HSIZES;
    wire                     A2F_HWRITES;
    wire                     A2F_HREADYS;

    reg                      A2F_HREADYOUTS;
    reg                      A2F_HREADYOUTS_nxt;

    wire                     A2F_HRESPS;

    reg      [APERWIDTH-1:0] AHB_ASYNC_ADDR_O;
    reg                      AHB_ASYNC_READ_EN_O;
    reg                      AHB_ASYNC_WRITE_EN_O;

    reg                [3:0] AHB_ASYNC_BYTE_STROBE_O;
    reg                [3:0] AHB_ASYNC_BYTE_STROBE_O_nxt;



    reg                      AHB_ASYNC_STB_TOGGLE_O;
    reg                      AHB_ASYNC_STB_TOGGLE_O_nxt;

    wire                     FABRIC_ASYNC_ACK_TOGGLE_I;

    wire                     trans_req;           

	reg    [STATE_WIDTH-1:0] ahb_to_fabric_state;
	reg    [STATE_WIDTH-1:0] ahb_to_fabric_state_nxt;

    reg                      fabric_async_ack_toggle_i_1ff;
    reg                      fabric_async_ack_toggle_i_2ff;
    reg                      fabric_async_ack_toggle_i_3ff;

    wire                     fabric_async_ack;

    assign trans_req        =   A2F_HSEL
	                        &   A2F_HREADYS 
						    &   A2F_HTRANSS[1]; 
                                                

    assign fabric_async_ack = fabric_async_ack_toggle_i_2ff ^ fabric_async_ack_toggle_i_3ff;

    assign A2F_HRESPS       = 1'b0;  

    always @(posedge A2F_HCLK or posedge A2F_HRESET)
    begin
        if (A2F_HRESET)
        begin
	       ahb_to_fabric_state           <=   AHB_ASYNC_IDLE;

           AHB_ASYNC_ADDR_O              <=   {(APERWIDTH){1'b0}}; 
           AHB_ASYNC_READ_EN_O           <=   1'b0;
           AHB_ASYNC_WRITE_EN_O          <=   1'b0;
           AHB_ASYNC_BYTE_STROBE_O       <=   4'b0;

           AHB_ASYNC_STB_TOGGLE_O        <=   1'b0;

           fabric_async_ack_toggle_i_1ff <=   1'b0;
           fabric_async_ack_toggle_i_2ff <=   1'b0;
           fabric_async_ack_toggle_i_3ff <=   1'b0;

           A2F_HREADYOUTS                <=   1'b0;
        end
        else 
        begin
	       ahb_to_fabric_state           <=   ahb_to_fabric_state_nxt;

           if (trans_req)
           begin
               AHB_ASYNC_ADDR_O          <=   A2F_HADDRS[APERWIDTH-1:0];
               AHB_ASYNC_READ_EN_O       <=  ~A2F_HWRITES ;
               AHB_ASYNC_WRITE_EN_O      <=   A2F_HWRITES ;
               AHB_ASYNC_BYTE_STROBE_O   <=   AHB_ASYNC_BYTE_STROBE_O_nxt;
		   end

           AHB_ASYNC_STB_TOGGLE_O        <=   AHB_ASYNC_STB_TOGGLE_O_nxt;

           fabric_async_ack_toggle_i_1ff <=   FABRIC_ASYNC_ACK_TOGGLE_I;
           fabric_async_ack_toggle_i_2ff <=   fabric_async_ack_toggle_i_1ff;
           fabric_async_ack_toggle_i_3ff <=   fabric_async_ack_toggle_i_2ff;

           A2F_HREADYOUTS                <=   A2F_HREADYOUTS_nxt;
        end
    end

    always @(A2F_HSIZES or A2F_HADDRS)
    begin
        case(A2F_HSIZES)
        3'b000:                                
        begin
           case(A2F_HADDRS[1:0])
           2'b00:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0001;
           2'b01:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0010;
           2'b10:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0100;
           2'b11:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b1000;
           default:  AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0000;
           endcase
        end
        3'b001:                                 
        begin
            case(A2F_HADDRS[1])
            1'b0:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0011;
            1'b1:    AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b1100;
            default: AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b0000;
	        endcase
        end
        default:     AHB_ASYNC_BYTE_STROBE_O_nxt <= 4'b1111; 
        endcase
    end

    always @(
            trans_req              or
            fabric_async_ack       or
            AHB_ASYNC_STB_TOGGLE_O or
            ahb_to_fabric_state
    )
    begin
	    case(ahb_to_fabric_state)
	    AHB_ASYNC_IDLE:
        begin
            case(trans_req)
            1'b0:  
            begin
	            ahb_to_fabric_state_nxt    <=  AHB_ASYNC_IDLE;
                A2F_HREADYOUTS_nxt         <=  1'b1;
                AHB_ASYNC_STB_TOGGLE_O_nxt <=  AHB_ASYNC_STB_TOGGLE_O;
            end 
            1'b1: 
            begin
	            ahb_to_fabric_state_nxt    <=  AHB_ASYNC_WAIT;
                A2F_HREADYOUTS_nxt         <=  1'b0;
                AHB_ASYNC_STB_TOGGLE_O_nxt <= ~AHB_ASYNC_STB_TOGGLE_O;
            end 
            endcase
        end
	    AHB_ASYNC_WAIT:
        begin
            AHB_ASYNC_STB_TOGGLE_O_nxt     <=  AHB_ASYNC_STB_TOGGLE_O;

            case(fabric_async_ack)
            1'b0:  
            begin
	            ahb_to_fabric_state_nxt    <=  AHB_ASYNC_WAIT;
                A2F_HREADYOUTS_nxt         <=  1'b0;
            end 
            1'b1:  
            begin
	            ahb_to_fabric_state_nxt    <=  AHB_ASYNC_IDLE;
                A2F_HREADYOUTS_nxt         <=  1'b1;
            end 
            endcase
        end
        default:        
        begin
	        ahb_to_fabric_state_nxt        <=  AHB_ASYNC_IDLE;
            A2F_HREADYOUTS_nxt             <=  1'b0;
            AHB_ASYNC_STB_TOGGLE_O_nxt     <=  AHB_ASYNC_STB_TOGGLE_O;
        end
        endcase
    end
    
endmodule

`timescale 1ns / 10ps
module fb2ahb_asynbrig_if (

                           A2F_HRDATAS,

                           AHB_ASYNC_READ_EN_I,
                           AHB_ASYNC_WRITE_EN_I,
                           AHB_ASYNC_BYTE_STROBE_I,

                           AHB_ASYNC_STB_TOGGLE_I,

                           WB_CLK_I,
                           WB_RST_I,
                           WB_ACK_I,
                           WB_DAT_I,
    
                           WB_CYC_O,
                           WB_BYTE_STB_O,
                           WB_WE_O,
                           WB_RD_O,
                           WB_STB_O,

                           FABRIC_ASYNC_ACK_TOGGLE_O

					       );


    parameter    DATAWIDTH              = 32;

	parameter    STATE_WIDTH            = 1;

	parameter    FAB_ASYNC_IDLE         = 0;
	parameter    FAB_ASYNC_WAIT         = 1;

    output   [DATAWIDTH-1:0] A2F_HRDATAS;

    input                    AHB_ASYNC_READ_EN_I;
    input                    AHB_ASYNC_WRITE_EN_I;
    input              [3:0] AHB_ASYNC_BYTE_STROBE_I;

    input                    AHB_ASYNC_STB_TOGGLE_I;


    input                    WB_CLK_I;
    input                    WB_RST_I;
    input                    WB_ACK_I;
    input    [DATAWIDTH-1:0] WB_DAT_I;
    
    output                   WB_CYC_O;
    output             [3:0] WB_BYTE_STB_O;
    output                   WB_WE_O;
    output                   WB_RD_O;
    output                   WB_STB_O;

    output                   FABRIC_ASYNC_ACK_TOGGLE_O;


    reg      [DATAWIDTH-1:0] A2F_HRDATAS;
    reg      [DATAWIDTH-1:0] A2F_HRDATAS_nxt;

    wire                     AHB_ASYNC_READ_EN_I;
    wire                     AHB_ASYNC_WRITE_EN_I;

    wire               [3:0] AHB_ASYNC_BYTE_STROBE_I;

    wire                     AHB_ASYNC_STB_TOGGLE_I;


    wire                     WB_CLK_I;
    wire                     WB_RST_I;
    wire                     WB_ACK_I;
    
    reg                      WB_CYC_O;
    reg                      WB_CYC_O_nxt;

    reg                [3:0] WB_BYTE_STB_O;
    reg                [3:0] WB_BYTE_STB_O_nxt;

    reg                      WB_WE_O;
    reg                      WB_WE_O_nxt;

    reg                      WB_RD_O;
    reg                      WB_RD_O_nxt;

    reg                      WB_STB_O;
    reg                      WB_STB_O_nxt;

    reg                      FABRIC_ASYNC_ACK_TOGGLE_O;
    reg                      FABRIC_ASYNC_ACK_TOGGLE_O_nxt;

	reg    [STATE_WIDTH-1:0] fabric_to_ahb_state;
	reg    [STATE_WIDTH-1:0] fabric_to_ahb_state_nxt;

    reg                      ahb_async_stb_toggle_i_1ff;
    reg                      ahb_async_stb_toggle_i_2ff;
    reg                      ahb_async_stb_toggle_i_3ff;

    wire                     ahb_async_stb;

    assign ahb_async_stb = ahb_async_stb_toggle_i_2ff ^ ahb_async_stb_toggle_i_3ff;

    always @(posedge WB_CLK_I or posedge WB_RST_I)
    begin
        if (WB_RST_I)
        begin
	        fabric_to_ahb_state         <= FAB_ASYNC_IDLE;

            A2F_HRDATAS                 <= {(DATAWIDTH){1'b0}};

            WB_CYC_O                    <= 1'b0;
            WB_BYTE_STB_O               <= 4'b0;
            WB_WE_O                     <= 1'b0;
            WB_RD_O                     <= 1'b0;
            WB_STB_O                    <= 1'b0;

            FABRIC_ASYNC_ACK_TOGGLE_O   <= 1'b0;

            ahb_async_stb_toggle_i_1ff  <= 1'b0;
            ahb_async_stb_toggle_i_2ff  <= 1'b0;
            ahb_async_stb_toggle_i_3ff  <= 1'b0;

        end
        else 
        begin

	        fabric_to_ahb_state         <=  fabric_to_ahb_state_nxt;

            A2F_HRDATAS                 <=  A2F_HRDATAS_nxt;

            WB_CYC_O                    <=  WB_CYC_O_nxt;
            WB_BYTE_STB_O               <=  WB_BYTE_STB_O_nxt;
            WB_WE_O                     <=  WB_WE_O_nxt;
            WB_RD_O                     <=  WB_RD_O_nxt;
            WB_STB_O                    <=  WB_STB_O_nxt;

            FABRIC_ASYNC_ACK_TOGGLE_O   <=  FABRIC_ASYNC_ACK_TOGGLE_O_nxt;

            ahb_async_stb_toggle_i_1ff  <=  AHB_ASYNC_STB_TOGGLE_I;
            ahb_async_stb_toggle_i_2ff  <=  ahb_async_stb_toggle_i_1ff;
            ahb_async_stb_toggle_i_3ff  <=  ahb_async_stb_toggle_i_2ff;

        end
    end

    always @(
            ahb_async_stb             or
            AHB_ASYNC_READ_EN_I       or
            AHB_ASYNC_WRITE_EN_I      or
            AHB_ASYNC_BYTE_STROBE_I   or
            A2F_HRDATAS               or
            WB_ACK_I                  or
            WB_DAT_I                  or
            WB_CYC_O                  or
            WB_BYTE_STB_O             or
            WB_WE_O                   or
            WB_RD_O                   or
            WB_STB_O                  or
            FABRIC_ASYNC_ACK_TOGGLE_O or
            fabric_to_ahb_state
    )
    begin
	    case(fabric_to_ahb_state)
	    FAB_ASYNC_IDLE:
        begin
            FABRIC_ASYNC_ACK_TOGGLE_O_nxt     <=  FABRIC_ASYNC_ACK_TOGGLE_O;
            A2F_HRDATAS_nxt                   <=  A2F_HRDATAS;

            case(ahb_async_stb)
            1'b0:  
            begin
	            fabric_to_ahb_state_nxt       <=  FAB_ASYNC_IDLE;

                WB_CYC_O_nxt                  <=  1'b0;
                WB_BYTE_STB_O_nxt             <=  4'b0;
                WB_WE_O_nxt                   <=  1'b0;
                WB_RD_O_nxt                   <=  1'b0;
                WB_STB_O_nxt                  <=  1'b0;

            end 
            1'b1: 
            begin
	            fabric_to_ahb_state_nxt       <=  FAB_ASYNC_WAIT;

                WB_CYC_O_nxt                  <=  1'b1;
                WB_BYTE_STB_O_nxt             <=  AHB_ASYNC_BYTE_STROBE_I;
                WB_WE_O_nxt                   <=  AHB_ASYNC_WRITE_EN_I;
                WB_RD_O_nxt                   <=  AHB_ASYNC_READ_EN_I;
                WB_STB_O_nxt                  <=  1'b1;

            end 
            endcase
        end
	    FAB_ASYNC_WAIT:
        begin

            case(WB_ACK_I)
            1'b0:  
            begin
	            fabric_to_ahb_state_nxt       <=  FAB_ASYNC_WAIT;

                A2F_HRDATAS_nxt               <=  A2F_HRDATAS;

                WB_CYC_O_nxt                  <=  WB_CYC_O;
                WB_BYTE_STB_O_nxt             <=  WB_BYTE_STB_O;
                WB_WE_O_nxt                   <=  WB_WE_O;
                WB_RD_O_nxt                   <=  WB_RD_O;
                WB_STB_O_nxt                  <=  WB_STB_O;

                FABRIC_ASYNC_ACK_TOGGLE_O_nxt <=  FABRIC_ASYNC_ACK_TOGGLE_O;
            end 
            1'b1:  
            begin
	            fabric_to_ahb_state_nxt       <=  FAB_ASYNC_IDLE;

                A2F_HRDATAS_nxt               <=  WB_DAT_I;

                WB_CYC_O_nxt                  <=  1'b0;
                WB_BYTE_STB_O_nxt             <=  4'b0;
                WB_WE_O_nxt                   <=  1'b0;
                WB_RD_O_nxt                   <=  1'b0;
                WB_STB_O_nxt                  <=  1'b0;

                FABRIC_ASYNC_ACK_TOGGLE_O_nxt <= ~FABRIC_ASYNC_ACK_TOGGLE_O;
            end 
            endcase
        end
        default:        
        begin
	        fabric_to_ahb_state_nxt           <=  FAB_ASYNC_IDLE;

            A2F_HRDATAS_nxt                   <=  A2F_HRDATAS;

            WB_CYC_O_nxt                      <=  1'b0;
            WB_BYTE_STB_O_nxt                 <=  4'b0;
            WB_WE_O_nxt                       <=  1'b0;
            WB_RD_O_nxt                       <=  1'b0;
            WB_STB_O_nxt                      <=  1'b0;

            FABRIC_ASYNC_ACK_TOGGLE_O_nxt     <=  FABRIC_ASYNC_ACK_TOGGLE_O;
        end
        endcase
    end
    
endmodule

`timescale 1ns / 10ps
module ahb2fb_asynbrig (

                           A2F_HCLK,
                           A2F_HRESET,

                           A2F_HADDRS,
                           A2F_HSEL,
                           A2F_HTRANSS,
                           A2F_HSIZES,
                           A2F_HWRITES,
                           A2F_HREADYS,
                           A2F_HWDATAS,

                           A2F_HREADYOUTS,
                           A2F_HRESPS,
                           A2F_HRDATAS,

                           WB_CLK_I,
                           WB_RST_I,
                           WB_DAT_I,
                           WB_ACK_I,

                           WB_ADR_O,
                           WB_CYC_O,
                           WB_BYTE_STB_O,
                           WB_WE_O,
                           WB_RD_O,
                           WB_STB_O,
                           WB_DAT_O

				         );

    parameter    ADDRWIDTH              = 32;
    parameter    DATAWIDTH              = 32;
	parameter    APERWIDTH              = 17;


    input                    A2F_HCLK;      
    input                    A2F_HRESET;    

    input    [ADDRWIDTH-1:0] A2F_HADDRS;
    input                    A2F_HSEL;
    input              [1:0] A2F_HTRANSS;
    input              [2:0] A2F_HSIZES;
    input                    A2F_HWRITES;
    input                    A2F_HREADYS;
    input    [DATAWIDTH-1:0] A2F_HWDATAS;

    output                   A2F_HREADYOUTS;
    output                   A2F_HRESPS;
    output   [DATAWIDTH-1:0] A2F_HRDATAS;

    input                    WB_CLK_I;       
    input                    WB_RST_I;       
    input    [DATAWIDTH-1:0] WB_DAT_I;       
    input                    WB_ACK_I;       
    
    output   [APERWIDTH-1:0] WB_ADR_O;       
    output                   WB_CYC_O;       
    output             [3:0] WB_BYTE_STB_O;  
    output                   WB_WE_O;        
    output                   WB_RD_O;        
    output                   WB_STB_O;       
    output   [DATAWIDTH-1:0] WB_DAT_O;       


    wire                     A2F_HCLK;       
    wire                     A2F_HRESET;     

    wire     [ADDRWIDTH-1:0] A2F_HADDRS;
    wire                     A2F_HSEL;
    wire               [1:0] A2F_HTRANSS;
    wire               [2:0] A2F_HSIZES;
    wire                     A2F_HWRITES;
    wire                     A2F_HREADYS;
    wire     [DATAWIDTH-1:0] A2F_HWDATAS;

    wire                     A2F_HREADYOUTS;
    wire                     A2F_HRESPS;
    wire     [DATAWIDTH-1:0] A2F_HRDATAS;

    wire                     WB_CLK_I;        
    wire                     WB_RST_I;        
    wire     [DATAWIDTH-1:0] WB_DAT_I;        
    wire                     WB_ACK_I;        
    
    wire     [APERWIDTH-1:0] WB_ADR_O;        
    wire                     WB_CYC_O;        
    wire               [3:0] WB_BYTE_STB_O;   
    wire                     WB_WE_O;         
    wire                     WB_RD_O;         
    wire                     WB_STB_O;        
    wire     [DATAWIDTH-1:0] WB_DAT_O;        

    wire     [APERWIDTH-1:0] ahb_async_addr;
    wire                     ahb_async_read_en;
    wire                     ahb_async_write_en;
    wire               [3:0] ahb_async_byte_strobe;

    wire                     ahb_async_stb_toggle;

    wire                     fabric_async_ack_toggle;

    assign WB_DAT_O    =  A2F_HWDATAS;

    assign WB_ADR_O    =  ahb_async_addr;

	ahb2fb_asynbrig_if         
	                                   #(

      .DATAWIDTH                        ( DATAWIDTH                           ),
      .APERWIDTH                        ( APERWIDTH                           )

                                        )
      u_FFE_ahb_to_fabric_async_bridge_interface         
                                        (
      .A2F_HCLK                         ( A2F_HCLK                            ),
      .A2F_HRESET                       ( A2F_HRESET                          ),

      .A2F_HSEL                         ( A2F_HSEL                            ),
      .A2F_HADDRS                       ( A2F_HADDRS[APERWIDTH-1:0]           ),
      .A2F_HTRANSS                      ( A2F_HTRANSS                         ),
      .A2F_HSIZES                       ( A2F_HSIZES                          ),
      .A2F_HWRITES                      ( A2F_HWRITES                         ),
      .A2F_HREADYS                      ( A2F_HREADYS                         ),

      .A2F_HREADYOUTS                   ( A2F_HREADYOUTS                      ),
      .A2F_HRESPS                       ( A2F_HRESPS                          ),

      .AHB_ASYNC_ADDR_O                 ( ahb_async_addr                      ),
      .AHB_ASYNC_READ_EN_O              ( ahb_async_read_en                   ),
      .AHB_ASYNC_WRITE_EN_O             ( ahb_async_write_en                  ),
      .AHB_ASYNC_BYTE_STROBE_O          ( ahb_async_byte_strobe               ),
      .AHB_ASYNC_STB_TOGGLE_O           ( ahb_async_stb_toggle                ),

	  .FABRIC_ASYNC_ACK_TOGGLE_I        (fabric_async_ack_toggle              )

      );


    fb2ahb_asynbrig_if      u_FFE_fabric_to_ahb_async_bridge_interface         
                                        (
      .A2F_HRDATAS                      ( A2F_HRDATAS                         ),

      .AHB_ASYNC_READ_EN_I              ( ahb_async_read_en                   ),
      .AHB_ASYNC_WRITE_EN_I             ( ahb_async_write_en                  ),
      .AHB_ASYNC_BYTE_STROBE_I          ( ahb_async_byte_strobe               ),
      .AHB_ASYNC_STB_TOGGLE_I           ( ahb_async_stb_toggle                ),

      .WB_CLK_I                         ( WB_CLK_I                            ), 
      .WB_RST_I                         ( WB_RST_I                            ), 
      .WB_ACK_I                         ( WB_ACK_I                            ), 
      .WB_DAT_I                         ( WB_DAT_I                            ), 
    
      .WB_CYC_O                         ( WB_CYC_O                            ), 
      .WB_BYTE_STB_O                    ( WB_BYTE_STB_O                       ), 
      .WB_WE_O                          ( WB_WE_O                             ), 
      .WB_RD_O                          ( WB_RD_O                             ), 
      .WB_STB_O                         ( WB_STB_O                            ), 

	  .FABRIC_ASYNC_ACK_TOGGLE_O        (fabric_async_ack_toggle              )

      );
endmodule


`timescale 1ns/10ps
module qlal4s3b_cell_macro_bfm (

                WBs_ADR,
                WBs_CYC,
                WBs_BYTE_STB,
                WBs_WE,
                WBs_RD, 
                WBs_STB,
                WBs_WR_DAT,
                WB_CLK,
                WB_RST,
                WBs_RD_DAT,
                WBs_ACK,
  
                SDMA_Req,
                SDMA_Sreq,
                SDMA_Done,
                SDMA_Active,

                FB_msg_out,
                FB_Int_Clr,
                FB_Start,
                FB_Busy,

                Sys_Clk0,
                Sys_Clk0_Rst,
                Sys_Clk1,
                Sys_Clk1_Rst,
 
                Sys_PKfb_Clk,
                Sys_PKfb_Rst,
                FB_PKfbData,
                FB_PKfbPush,
                FB_PKfbSOF,
                FB_PKfbEOF,
                FB_PKfbOverflow,

                Sensor_Int,
                TimeStamp,

                Sys_Pclk,
                Sys_Pclk_Rst,
                Sys_PSel,
                SPIm_Paddr,
                SPIm_PEnable,
                SPIm_PWrite,
                SPIm_PWdata,
                SPIm_Prdata,
                SPIm_PReady,
                SPIm_PSlvErr,

                Device_ID,

                FBIO_In,
                FBIO_In_En,
                FBIO_Out,
                FBIO_Out_En,

                SFBIO,
                Device_ID_6S,
                Device_ID_4S,
                SPIm_PWdata_26S,
                SPIm_PWdata_24S,
                SPIm_PWdata_14S,
                SPIm_PWdata_11S,
                SPIm_PWdata_0S,
                SPIm_Paddr_8S,
                SPIm_Paddr_6S,
                FB_PKfbPush_1S,
                FB_PKfbData_31S,
                FB_PKfbData_21S,
                FB_PKfbData_19S,
                FB_PKfbData_9S,
                FB_PKfbData_6S,
                Sys_PKfb_ClkS,
                FB_BusyS,
                WB_CLKS
                );

output  [16:0]  WBs_ADR;
output          WBs_CYC;
output   [3:0]  WBs_BYTE_STB;
output          WBs_WE;
output          WBs_RD;
output          WBs_STB;
output  [31:0]  WBs_WR_DAT;
input           WB_CLK;
output          WB_RST;
input   [31:0]  WBs_RD_DAT;
input           WBs_ACK;

input    [3:0]  SDMA_Req;
input    [3:0]  SDMA_Sreq;
output   [3:0]  SDMA_Done;
output   [3:0]  SDMA_Active;

input    [3:0]  FB_msg_out;
input    [7:0]  FB_Int_Clr;
output          FB_Start;
input           FB_Busy;

output          Sys_Clk0;
output          Sys_Clk0_Rst;
output          Sys_Clk1;
output          Sys_Clk1_Rst;

input           Sys_PKfb_Clk;
output          Sys_PKfb_Rst;
input   [31:0]  FB_PKfbData;
input    [3:0]  FB_PKfbPush;
input           FB_PKfbSOF;
input           FB_PKfbEOF;
output          FB_PKfbOverflow;

output   [7:0]  Sensor_Int;
output  [23:0]  TimeStamp;

output          Sys_Pclk;
output          Sys_Pclk_Rst;
input           Sys_PSel;
input   [15:0]  SPIm_Paddr;
input           SPIm_PEnable;
input           SPIm_PWrite;
input   [31:0]  SPIm_PWdata;
output  [31:0]  SPIm_Prdata;
output          SPIm_PReady;
output          SPIm_PSlvErr;

input   [15:0]  Device_ID;

output  [13:0]  FBIO_In;
input   [13:0]  FBIO_In_En;
input   [13:0]  FBIO_Out;
input   [13:0]  FBIO_Out_En;

inout   [13:0]  SFBIO;
input           Device_ID_6S; 
input           Device_ID_4S; 
input           SPIm_PWdata_26S; 
input           SPIm_PWdata_24S;  
input           SPIm_PWdata_14S; 
input           SPIm_PWdata_11S; 
input           SPIm_PWdata_0S; 
input           SPIm_Paddr_8S; 
input           SPIm_Paddr_6S; 
input           FB_PKfbPush_1S; 
input           FB_PKfbData_31S; 
input           FB_PKfbData_21S;
input           FB_PKfbData_19S;
input           FB_PKfbData_9S;
input           FB_PKfbData_6S;
input           Sys_PKfb_ClkS;
input           FB_BusyS;
input           WB_CLKS;


wire    [16:0]  WBs_ADR;
wire            WBs_CYC;
wire     [3:0]  WBs_BYTE_STB;
wire            WBs_WE;
wire            WBs_RD;
wire            WBs_STB;
wire    [31:0]  WBs_WR_DAT;
wire            WB_CLK;
reg             WB_RST;
wire    [31:0]  WBs_RD_DAT;
wire            WBs_ACK;

wire     [3:0]  SDMA_Req;
wire     [3:0]  SDMA_Sreq;
wire      [3:0]  SDMA_Done;
wire      [3:0]  SDMA_Active;

wire     [3:0]  FB_msg_out;
wire     [7:0]  FB_Int_Clr;
reg             FB_Start;
wire            FB_Busy;

wire            Sys_Clk0;
reg             Sys_Clk0_Rst;
wire            Sys_Clk1;
reg             Sys_Clk1_Rst;

wire            Sys_PKfb_Clk;
reg             Sys_PKfb_Rst;
wire    [31:0]  FB_PKfbData;
wire     [3:0]  FB_PKfbPush;
wire            FB_PKfbSOF;
wire            FB_PKfbEOF;
reg             FB_PKfbOverflow;

reg      [7:0]  Sensor_Int;
reg     [23:0]  TimeStamp;

reg             Sys_Pclk;
reg             Sys_Pclk_Rst;
wire            Sys_PSel;

wire    [15:0]  SPIm_Paddr;
wire            SPIm_PEnable;
wire            SPIm_PWrite;
wire    [31:0]  SPIm_PWdata;
reg     [31:0]  SPIm_Prdata;
reg             SPIm_PReady;
reg             SPIm_PSlvErr;

wire    [15:0]  Device_ID;

reg     [13:0]  FBIO_In;
wire    [13:0]  FBIO_In_En;
wire    [13:0]  FBIO_Out;
wire    [13:0]  FBIO_Out_En;

wire    [13:0]  SFBIO;
wire            Device_ID_6S; 
wire            Device_ID_4S; 

wire            SPIm_PWdata_26S; 
wire            SPIm_PWdata_24S;  
wire            SPIm_PWdata_14S; 
wire            SPIm_PWdata_11S; 
wire            SPIm_PWdata_0S; 
wire            SPIm_Paddr_8S; 
wire            SPIm_Paddr_6S; 

wire            FB_PKfbPush_1S; 
wire            FB_PKfbData_31S; 
wire            FB_PKfbData_21S;
wire            FB_PKfbData_19S;
wire            FB_PKfbData_9S;
wire            FB_PKfbData_6S;
wire            Sys_PKfb_ClkS;

wire            FB_BusyS;
wire            WB_CLKS;

parameter       ADDRWIDTH                   = 32;
parameter       DATAWIDTH                   = 32;
parameter       APERWIDTH                   = 17;

parameter       ENABLE_AHB_REG_WR_DEBUG_MSG = 1'b1;
parameter       ENABLE_AHB_REG_RD_DEBUG_MSG = 1'b1; 

parameter       T_CYCLE_CLK_SYS_CLK0        = 200;
parameter       T_CYCLE_CLK_SYS_CLK1        = 650;
parameter       T_CYCLE_CLK_A2F_HCLK        = (1000.0/(80.0/12)) ; 

parameter       SYS_CLK0_RESET_LOOP         = 5;
parameter       SYS_CLK1_RESET_LOOP         = 5;
parameter       WB_CLK_RESET_LOOP           = 5;
parameter       A2F_HCLK_RESET_LOOP         = 5;

integer         Sys_Clk0_Reset_Loop_Cnt;
integer         Sys_Clk1_Reset_Loop_Cnt;
integer         WB_CLK_Reset_Loop_Cnt;
integer         A2F_HCLK_Reset_Loop_Cnt;


wire            A2F_HCLK;
reg             A2F_HRESET;

wire    [31:0]  A2F_HADDRS;
wire            A2F_HSEL;
wire     [1:0]  A2F_HTRANSS;
wire     [2:0]  A2F_HSIZES;
wire            A2F_HWRITES;
wire            A2F_HREADYS;
wire    [31:0]  A2F_HWDATAS;

wire            A2F_HREADYOUTS;
wire            A2F_HRESPS;
wire    [31:0]  A2F_HRDATAS;

initial
begin

    Sys_Clk0_Rst  <= 1'b1;
`ifdef GSIM
    for (Sys_Clk0_Reset_Loop_Cnt = 0; 
	     Sys_Clk0_Reset_Loop_Cnt < SYS_CLK0_RESET_LOOP; 
         Sys_Clk0_Reset_Loop_Cnt = Sys_Clk0_Reset_Loop_Cnt + 1)
    begin
        wait (Sys_Clk0 == 1'b1) #1;
        wait (Sys_Clk0 == 1'b0) #1;
    end

    wait (Sys_Clk0 == 1'b1) #1;
`endif
    Sys_Clk0_Rst  <= 1'b0;

end

initial
begin

    Sys_Clk1_Rst  <= 1'b1;
`ifdef GSIM
    for (Sys_Clk1_Reset_Loop_Cnt = 0; 
	     Sys_Clk1_Reset_Loop_Cnt < SYS_CLK1_RESET_LOOP; 
         Sys_Clk1_Reset_Loop_Cnt = Sys_Clk1_Reset_Loop_Cnt + 1)
    begin
        wait (Sys_Clk1 == 1'b1) #1;
        wait (Sys_Clk1 == 1'b0) #1;
    end

    wait (Sys_Clk1 == 1'b1) #1;
`endif
    Sys_Clk1_Rst  <= 1'b0;

end

initial
begin

    WB_RST  <= 1'b1;
`ifdef GSIM
    for (WB_CLK_Reset_Loop_Cnt = 0; 
	     WB_CLK_Reset_Loop_Cnt < WB_CLK_RESET_LOOP; 
         WB_CLK_Reset_Loop_Cnt = WB_CLK_Reset_Loop_Cnt + 1)
    begin
        wait (WB_CLK == 1'b1) #1;
        wait (WB_CLK == 1'b0) #1;
    end

    wait (WB_CLK == 1'b1) #1;
`endif
    WB_RST  <= 1'b0;

end

initial
begin

    A2F_HRESET  <= 1'b1;
`ifdef GSIM
    for (A2F_HCLK_Reset_Loop_Cnt = 0; 
	     A2F_HCLK_Reset_Loop_Cnt < A2F_HCLK_RESET_LOOP; 
         A2F_HCLK_Reset_Loop_Cnt = A2F_HCLK_Reset_Loop_Cnt + 1)
    begin
        wait (A2F_HCLK == 1'b1) #1;
        wait (A2F_HCLK == 1'b0) #1;
    end

    wait (A2F_HCLK == 1'b1) #1;
`endif
    A2F_HRESET  <= 1'b0;

end

initial
begin

    FB_Start        <=  1'b0;

    Sys_PKfb_Rst    <=  1'b0;
    FB_PKfbOverflow <=  1'b0;

    Sensor_Int      <=  8'h0;
    TimeStamp       <= 24'h0;

    Sys_Pclk        <=  1'b0;
    Sys_Pclk_Rst    <=  1'b0;

    SPIm_Prdata     <= 32'h0;
    SPIm_PReady     <=  1'b0;
    SPIm_PSlvErr    <=  1'b0;

    FBIO_In         <= 14'h0;

end

ahb2fb_asynbrig 
                                #(
    .ADDRWIDTH                   ( ADDRWIDTH                   ),
    .DATAWIDTH                   ( DATAWIDTH                   ),
	.APERWIDTH                   ( APERWIDTH                   )
	                             )
    u_ffe_ahb_to_fabric_async_bridge 
                                 (

    .A2F_HCLK                    ( A2F_HCLK                    ),
    .A2F_HRESET                  ( A2F_HRESET                  ),

    .A2F_HADDRS                  ( A2F_HADDRS                  ),
    .A2F_HSEL                    ( A2F_HSEL                    ),
    .A2F_HTRANSS                 ( A2F_HTRANSS                 ),
    .A2F_HSIZES                  ( A2F_HSIZES                  ),
    .A2F_HWRITES                 ( A2F_HWRITES                 ),
    .A2F_HREADYS                 ( A2F_HREADYS                 ),
    .A2F_HWDATAS                 ( A2F_HWDATAS                 ),

    .A2F_HREADYOUTS              ( A2F_HREADYOUTS              ),
    .A2F_HRESPS                  ( A2F_HRESPS                  ),
    .A2F_HRDATAS                 ( A2F_HRDATAS                 ),

    .WB_CLK_I                    ( WB_CLK                      ),
    .WB_RST_I                    ( WB_RST                      ),
    .WB_DAT_I                    ( WBs_RD_DAT                  ),
    .WB_ACK_I                    ( WBs_ACK                     ),

    .WB_ADR_O                    ( WBs_ADR                     ),
    .WB_CYC_O                    ( WBs_CYC                     ),
    .WB_BYTE_STB_O               ( WBs_BYTE_STB                ),
    .WB_WE_O                     ( WBs_WE                      ),
    .WB_RD_O                     ( WBs_RD                      ),
    .WB_STB_O                    ( WBs_STB                     ),
    .WB_DAT_O                    ( WBs_WR_DAT                  )

    );


ahb_gen_bfm
                                #(
    .ADDRWIDTH                   ( ADDRWIDTH                   ),
    .DATAWIDTH                   ( DATAWIDTH                   ),
	.DEFAULT_AHB_ADDRESS         ( {(ADDRWIDTH){1'b1}}         ),
	.STD_CLK_DLY                 ( 2                           ),
    .ENABLE_AHB_REG_WR_DEBUG_MSG ( ENABLE_AHB_REG_WR_DEBUG_MSG ),
    .ENABLE_AHB_REG_RD_DEBUG_MSG ( ENABLE_AHB_REG_RD_DEBUG_MSG )
                                 )
    u_ahb_gen_bfm
                                 (
    .A2F_HCLK                    ( A2F_HCLK                    ),
    .A2F_HRESET                  ( A2F_HRESET                  ),

    .A2F_HADDRS                  ( A2F_HADDRS                  ),
    .A2F_HSEL                    ( A2F_HSEL                    ),
    .A2F_HTRANSS                 ( A2F_HTRANSS                 ),
    .A2F_HSIZES                  ( A2F_HSIZES                  ),
    .A2F_HWRITES                 ( A2F_HWRITES                 ),
    .A2F_HREADYS                 ( A2F_HREADYS                 ),
    .A2F_HWDATAS                 ( A2F_HWDATAS                 ),

    .A2F_HREADYOUTS              ( A2F_HREADYOUTS              ),
    .A2F_HRESPS                  ( A2F_HRESPS                  ),
    .A2F_HRDATAS                 ( A2F_HRDATAS                 )

    );

oscillator_s1 #(.T_CYCLE_CLK (T_CYCLE_CLK_SYS_CLK0)) u_osc_sys_clk0   (.OSC_CLK_EN (1'b1), .OSC_CLK (Sys_Clk0));
oscillator_s1 #(.T_CYCLE_CLK (T_CYCLE_CLK_SYS_CLK1)) u_osc_sys_clk1   (.OSC_CLK_EN (1'b1), .OSC_CLK (Sys_Clk1));
oscillator_s1 #(.T_CYCLE_CLK (T_CYCLE_CLK_A2F_HCLK)) u_osc_a2f_hclk   (.OSC_CLK_EN (1'b1), .OSC_CLK (A2F_HCLK));

sdma_bfm sdma_bfm_inst0 (
							.sdma_req_i			( SDMA_Req),
                            .sdma_sreq_i		( SDMA_Sreq),
                            .sdma_done_o		( SDMA_Done),
                            .sdma_active_o		( SDMA_Active)
						);



endmodule 

`timescale 1ns/10ps
(* whitebox *)
(* keep *)
module ASSP(
    input	WB_CLK,
    input	WBs_ACK,
    input	[31:0]WBs_RD_DAT,
    output	[3:0]WBs_BYTE_STB,
    output	WBs_CYC,
    output	WBs_WE,
    output	WBs_RD,
    output	WBs_STB,
    output	[16:0]WBs_ADR,
    input	[3:0]SDMA_Req,
    input	[3:0]SDMA_Sreq,
    output	[3:0]SDMA_Done,
    output	[3:0]SDMA_Active,
    input	[3:0]FB_msg_out,
    input	[7:0]FB_Int_Clr,
    output	FB_Start,
    input	FB_Busy,
    output	WB_RST,
    output	Sys_PKfb_Rst,
    output	Sys_Clk0,
    output	Sys_Clk0_Rst,
    output	Sys_Clk1,
    output	Sys_Clk1_Rst,
    output	Sys_Pclk,
    output	Sys_Pclk_Rst,
    input	Sys_PKfb_Clk,
    input	[31:0]FB_PKfbData,
    output	[31:0]WBs_WR_DAT,
    input	[3:0]FB_PKfbPush,
    input	FB_PKfbSOF,
    input	FB_PKfbEOF,
    output	[7:0]Sensor_Int,
    output	FB_PKfbOverflow,
    output	[23:0]TimeStamp,
    input	Sys_PSel,
    input	[15:0]SPIm_Paddr,
    input	SPIm_PEnable,
    input	SPIm_PWrite,
    input	[31:0]SPIm_PWdata,
    output	SPIm_PReady,
    output	SPIm_PSlvErr,
    output	[31:0]SPIm_Prdata,
    input	[15:0]Device_ID,
    input	[13:0]FBIO_In_En,
    input	[13:0]FBIO_Out,
    input	[13:0]FBIO_Out_En,
    output	[13:0]FBIO_In,
    inout 	[13:0]SFBIO,
    input   Device_ID_6S,
    input   Device_ID_4S,
    input   SPIm_PWdata_26S,
    input   SPIm_PWdata_24S,
    input   SPIm_PWdata_14S,
    input   SPIm_PWdata_11S,
    input   SPIm_PWdata_0S,
    input   SPIm_Paddr_8S,
    input   SPIm_Paddr_6S,
    input   FB_PKfbPush_1S,
    input   FB_PKfbData_31S,
    input   FB_PKfbData_21S,
    input   FB_PKfbData_19S,
    input   FB_PKfbData_9S,
    input   FB_PKfbData_6S,
    input   Sys_PKfb_ClkS,
    input   FB_BusyS,
    input   WB_CLKS);
	
qlal4s3b_cell_macro_bfm	 u_ASSP_bfm_inst(
		.WBs_ADR     (WBs_ADR),
        .WBs_CYC     (WBs_CYC),
        .WBs_BYTE_STB(WBs_BYTE_STB),
        .WBs_WE      (WBs_WE),
        .WBs_RD      (WBs_RD), 
        .WBs_STB     (WBs_STB),
        .WBs_WR_DAT  (WBs_WR_DAT),
        .WB_CLK      (WB_CLK),
        .WB_RST      (WB_RST),
        .WBs_RD_DAT  (WBs_RD_DAT),
        .WBs_ACK     (WBs_ACK),

        .SDMA_Req     (SDMA_Req),
        .SDMA_Sreq    (SDMA_Sreq),
        .SDMA_Done    (SDMA_Done),
        .SDMA_Active  (SDMA_Active),

        .FB_msg_out    (FB_msg_out),
        .FB_Int_Clr    (FB_Int_Clr),
        .FB_Start      (FB_Start),
        .FB_Busy       (FB_Busy),

        .Sys_Clk0      (Sys_Clk0),
        .Sys_Clk0_Rst  (Sys_Clk0_Rst),
        .Sys_Clk1      (Sys_Clk1),
        .Sys_Clk1_Rst  (Sys_Clk1_Rst),

        .Sys_PKfb_Clk     (Sys_PKfb_Clk),
        .Sys_PKfb_Rst     (Sys_PKfb_Rst),
        .FB_PKfbData      (FB_PKfbData),
        .FB_PKfbPush      (FB_PKfbPush),
        .FB_PKfbSOF       (FB_PKfbSOF),
        .FB_PKfbEOF       (FB_PKfbEOF),
        .FB_PKfbOverflow  (FB_PKfbOverflow),

        .Sensor_Int       (Sensor_Int),
        .TimeStamp        (TimeStamp),

        .Sys_Pclk        (Sys_Pclk),
        .Sys_Pclk_Rst    (Sys_Pclk_Rst),
        .Sys_PSel        (Sys_PSel),
        .SPIm_Paddr      (SPIm_Paddr),
        .SPIm_PEnable    (SPIm_PEnable),
        .SPIm_PWrite     (SPIm_PWrite),
        .SPIm_PWdata     (SPIm_PWdata),
        .SPIm_Prdata     (SPIm_Prdata),
        .SPIm_PReady     (SPIm_PReady),
        .SPIm_PSlvErr    (SPIm_PSlvErr),

        .Device_ID		 (Device_ID),

        .FBIO_In         (FBIO_In),
        .FBIO_In_En      (FBIO_In_En),
        .FBIO_Out        (FBIO_Out),
        .FBIO_Out_En     (FBIO_Out_En),

        .SFBIO              (SFBIO),
        .Device_ID_6S       (Device_ID_6S),
        .Device_ID_4S       (Device_ID_4S),
        .SPIm_PWdata_26S    (SPIm_PWdata_26S),
        .SPIm_PWdata_24S    (SPIm_PWdata_24S),
        .SPIm_PWdata_14S    (SPIm_PWdata_14S),
        .SPIm_PWdata_11S    (SPIm_PWdata_11S),
        .SPIm_PWdata_0S     (SPIm_PWdata_0S),
        .SPIm_Paddr_8S      (SPIm_Paddr_8S),
        .SPIm_Paddr_6S      (SPIm_Paddr_6S),
        .FB_PKfbPush_1S     (FB_PKfbPush_1S),
        .FB_PKfbData_31S    (FB_PKfbData_31S),
        .FB_PKfbData_21S    (FB_PKfbData_21S),
        .FB_PKfbData_19S    (FB_PKfbData_19S),
        .FB_PKfbData_9S     (FB_PKfbData_9S),
        .FB_PKfbData_6S     (FB_PKfbData_6S),
        .Sys_PKfb_ClkS      (Sys_PKfb_ClkS),
        .FB_BusyS           (FB_BusyS),
        .WB_CLKS            (WB_CLKS)
		);

endmodule 
