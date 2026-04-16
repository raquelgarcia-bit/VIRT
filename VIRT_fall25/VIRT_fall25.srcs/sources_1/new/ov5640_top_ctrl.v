`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2026 09:32:26 PM
// Design Name: 
// Module Name: ov5640_top_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ov5640_top_ctrl
  (input        rst,              //reset, active high
   input        clk,              //FPGA clock
   input        resend,           //resend the sequence
   input        rgbmode,         //if '1': in RGB, else YUV
   input        testmode,        //if '1': in test mode
   output [5:0] cnt_reg_test,     //to test the count
   output       done,             //all transmission done
   output       sclk,             //sccb clock
   output       sdat_on,          //transmitting serial ('1')
   //output       sdat_in,        //sccb serial data in
   output       sdat_out,         //sccb serial data ou
   output       ov7670_rst_n,     //camera reset
   output       ov7670_clk,       //camera system clock
   output       ov7670_pwdn       //camera power down
  );


  wire         start_tx;
  wire         sccb_ready;
  wire [6:0]   id;
  wire [7:0]   addr;
  wire [7:0]   data_wr;

  sccb_master i_sccb
  (
    .rst      (rst),
    .clk      (clk),
    .start_tx (start_tx),
    .id       (id),
    .addr     (addr),
    .data_wr  (data_wr),
    .ready    (sccb_ready),
    //.finish_tx    
    .sclk     (sclk),
    .sdat_on  (sdat_on),
    //sdat_in
    .sdat_out (sdat_out)
  );


  ov5640_ctrl_reg i_regs
  (
    .rst          (rst),
    .clk          (clk),
    .rgbmode      (rgbmode),
    .testmode     (testmode),
    .resend       (resend),
    .sccb_ready   (sccb_ready),
    .cnt_reg_test (cnt_reg_test), //test
    .start_tx     (start_tx),
    .done         (done),
    .id           (id),
    .addr         (addr),
    .data_wr      (data_wr),
    .ov7670_rst_n (ov7670_rst_n),
    .ov7670_clk   (), // (ov7670_clk),
    .ov7670_pwdn  (ov7670_pwdn)
  );

endmodule
