////////////////////////////////////////////////////////////////////
////                                                            ////
////  compile_param.vh	                                        ////
////                                                            ////
////  Compile Parameter file for r_tx_rx_wrap		            ////
////////////////////////////////////////////////////////////////////


//`timescale 1ns / 1ps

// 7'h00 - 7'h4F : reserved for sensor hub (or something else)
parameter	ADR_PSB_REP_DEL_LSB =		7'h40;
parameter	ADR_PSB_REP_DEL_MSB =		7'h41;
parameter	ADR_PSB_REP_DEL_LSB_1 =		7'h42;
parameter	ADR_PSB_ID_LSB =			7'h50;
parameter	ADR_PSB_ID_MSB =			7'h51;
parameter	ADR_PSB_VER_LSB =			7'h52;
parameter	ADR_PSB_VER_MSB =			7'h53;
parameter	ADR_COMMAND =				7'h54;
parameter	ADR_STAT_CTRL =				7'h55;
parameter	ADR_CRR_CYC_LEN_LSB =		7'h56;
parameter	ADR_CRR_CYC_LEN_MSB =		7'h57;
parameter	ADR_TX_DUTY_RX_LIMIT_LSB =	7'h58;
parameter	ADR_TX_DUTY_RX_LIMIT_MSB =	7'h59;
parameter	ADR_CODE_BGN_LSB =			7'h5A;
parameter	ADR_CODE_BGN_MSB =			7'h5B;
parameter	ADR_CODE_END_LSB =			7'h5C;
parameter	ADR_CODE_END_MSB =			7'h5D;
parameter	ADR_TX_RPT_LEN_RX_CTRL =	7'h5E;
parameter	ADR_CODE_ADR_IDX =			7'h5F;

// 7'h60 - 7'h7F : Code Address Space

parameter	PSB_ID_LSB = 	8'h02;	// tentative
parameter	PSB_ID_MSB = 	8'h10;	// tentative
parameter	PSB_VER_LSB = 	8'h01;	// tentative
parameter	PSB_VER_MSB = 	8'h00;	// tentative
