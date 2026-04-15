`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2026 07:04:50 PM
// Design Name: 
// Module Name: ov5640_capture
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


module ov5640_capture
    #(parameter
        // VGA
        //c_img_cols    = 640, // 10 bits
        //c_img_rows    = 480, //  9 bits
        //c_img_pxls    = c_img_cols * c_img_rows,
        //c_nb_line_pxls = 10, // log2i(c_img_cols-1) + 1;
        // c_nb_img_pxls = log2i(c_img_pxls-1) + 1
        //c_nb_img_pxls =  19,  //640*480=307,200 -> 2^19=524,288
        // QVGA
        c_img_cols    = 320, // 9 bits
        c_img_rows    = 240, // 8 bits
        c_img_pxls    = c_img_cols * c_img_rows,
        c_nb_line_pxls = 9, // log2i(c_img_cols-1) + 1;
        c_nb_img_pxls =  17,  //320*240=76,800 -> 2^17
        // QQVGA
        //c_img_cols    = 160, // 8 bits
        //c_img_rows    = 120, //  7 bits
        //c_img_pxls    = c_img_cols * c_img_rows,
        //c_nb_line_pxls = 8, // log2i(c_img_cols-1) + 1;
        //c_nb_img_pxls =  15,  //160*120=19.200 -> 2^15
        // QQVGA/2
        //c_img_cols    = 80, // 7 bits
        //c_img_rows    = 60, // 6 bits
        //c_img_pxls    = c_img_cols * c_img_rows,
        //c_nb_line_pxls = 7, // log2i(c_img_cols-1) + 1;
        //c_nb_img_pxls =  13,  //80*60=4800 -> 2^13


        c_nb_buf_red   =  4,  // n bits for red in the buffer (memory)
        c_nb_buf_green =  4,  // n bits for green in the buffer (memory)
        c_nb_buf_blue  =  4,  // n bits for blue in the buffer (memory)
        // word width of the memory (buffer)
        c_nb_buf       =   c_nb_buf_red + c_nb_buf_green + c_nb_buf_blue
    )
    (
        input              rst,    // FPGA reset
        input              clk,    // 200 MHz clock

        input dphy_clk_lp_n,
        input dphy_clk_lp_p,
        input dphy_data_lp_n,
        input dphy_data_lp_p,
        input dphy_hs_clock_clk_n,
        input dphy_hs_clock_clk_p,
        input dphy_data_hs_n,
        input dphy_data_hs_p,
        
        input             rgbmode,   // RGB444 or YUV422
        input             swap_r_b,  // swaps red with blue
        output     [11:0] dataout_test,
        output reg [3:0]  led_test,
        output     [c_nb_img_pxls-1:0] addr,
        output     [c_nb_buf-1:0]      dout,
        output            we
    );

endmodule