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
        input [1:0] dphy_data_lp_n,
        input [1:0] dphy_data_lp_p,
        input dphy_hs_clock_clk_n,
        input dphy_hs_clock_clk_p,
        input [1:0] dphy_data_hs_n,
        input [1:0] dphy_data_hs_p,
        
        input             rgbmode,   // RGB444 or YUV422
        input             swap_r_b,  // swaps red with blue
        output     [11:0] dataout_test,
        output reg [3:0]  led_test,
        output reg [c_nb_img_pxls-1:0] addr,
        output reg [c_nb_buf-1:0]      dout,
        output reg        we
    );

    // Outputs from the CSI subsystem
    wire [31:0] video_out_tdata;
    wire [63:0] video_out_tuser;
    wire video_out_tvalid;
    wire frame_start;

    // Reset synchronizer as per https://docs.amd.com/r/en-US/pg232-mipi-csi2-rx/Port-Descriptions
    reg [2:0] rstn_sync;
    always @(posedge clk) begin
        rstn_sync[2:1] <= rstn_sync[1:0];
        rstn_sync[0] <= ~rst;
    end

    always @(posedge clk) begin
        if (rst) begin
            addr <= 0;
        end else if (video_out_tvalid) begin
            addr <= frame_start ? 0 : frame_start + 1;
        end
    end

    assign frame_start = video_out_tuser[0];

    always @(posedge clk) begin // TODO: doesn't dither yet!
        we <= video_out_tvalid;
        dout <= {video_out_tdata[7+ 0:8-  c_nb_buf_red+ 0],
                 video_out_tdata[7+ 8:8-c_nb_buf_green+ 8],
                 video_out_tdata[7+16:8- c_nb_buf_blue+16]};
    end

    mipi_csi2_rx_subsystem_0 (
        .dphy_clk_200M(clk),
        .rxbyteclkhs(rxbyteclkhs), // Something PHY related that we don't need
        .system_rst_out(), // Indicates some sort of PLL hiccup
        .video_aclk(clk), // NOTE: this can be lower if needed! Minimum appears to be 42 MHz
        .video_aresetn(rstn_sync),
        .ctrl_core_en(1), // Sleep is forbidden
        .active_lanes(2-1), // Number of lanes - 1 is what goes here
        .ctrl_dis_in_prgs(),
        .errsotsynchs_intr(),
        .errsoths_intr(),
        .cl_stopstate_intr(),
        .dl0_stopstate_intr(),
        .dl1_stopstate_intr(),
        .crc_status_intr(),
        .ecc_status_intr(),
        .linebuffer_full(),
        .frame_rcvd_pulse_out(),
        .video_out_tdata(video_out_tdata), // Actual cool video gaming data
        .video_out_tdest(), // TODO: not sure what this is but it does not appear to be relevant with 1 camera
        .video_out_tlast(), // This is not needed
        .video_out_tready(1), // We are always ready to accept data
        .video_out_tuser(video_out_tuser),
        .video_out_tvalid(video_out_tvalid),
        .mipi_phy_if_clk_hs_n(dphy_hs_clock_clk_n),
        .mipi_phy_if_clk_hs_p(dphy_hs_clock_clk_p),
        .mipi_phy_if_clk_lp_n(dphy_clk_lp_n),
        .mipi_phy_if_clk_lp_p(dphy_clk_lp_p),
        .mipi_phy_if_data_hs_n(dphy_data_hs_n),
        .mipi_phy_if_data_hs_p(dphy_data_hs_p),
        .mipi_phy_if_data_lp_n(dphy_data_lp_n),
        .mipi_phy_if_data_lp_p(dphy_data_lp_p)
    );
endmodule