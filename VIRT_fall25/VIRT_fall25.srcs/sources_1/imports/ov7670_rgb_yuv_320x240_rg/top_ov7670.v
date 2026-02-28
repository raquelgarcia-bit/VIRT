//------------------------------------------------------------------------------
//   Felipe Machado Sanchez
//   Area de Tecnologia Electronica
//   Universidad Rey Juan Carlos
//   https://github.com/felipe-m
//
//   top module with debuging modules
//------------------------------------------------------------------------------//

module top_ov7670
  # (parameter
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
      c_nb_img_pxls =  17,  //320*240=76,800 -> 2^17

      // QQVGA
      //c_img_cols    = 160, // 8 bits
      //c_img_rows    = 120, //  7 bits
      //c_img_pxls    = c_img_cols * c_img_rows,
      //c_nb_img_pxls =  15,  //160*120=19.200 -> 2^15
      // QQVGA /2
      //c_img_cols    = 80, // 7 bits
      //c_img_rows    = 60, //  6 bits
      //c_img_pxls    = c_img_cols * c_img_rows,
      //c_nb_img_pxls =  13,  //80*60=4800 -> 2^13

       c_nb_buf_red   =  4,  // n bits for red in the buffer (memory)
       c_nb_buf_green =  4,  // n bits for green in the buffer (memory)
       c_nb_buf_blue  =  4,  // n bits for blue in the buffer (memory)
       // word width of the memory (buffer)
       c_nb_buf       =   c_nb_buf_red + c_nb_buf_green + c_nb_buf_blue
    )
    (input        rst,
     input        clk_125mhz_in,

     input        btnc,          //select RGB -> YUV -> RGB test -> YUV test

     output       ov7670_sioc,
     output       ov7670_siod,

     output       ov7670_rst_n,
     output       ov7670_pwdn,  // not used, not enough pins
     input        ov7670_vsync,
     input        ov7670_href,
     input        ov7670_pclk,
     output       ov7670_xclk,
     input  [7:0] ov7670_d,
     
     output TMDS_Clk_p,
     output TMDS_Clk_n,
     output [2:0] TMDS_Data_p,
     output [2:0] TMDS_Data_n,

     output [3:0] led,

     // FIXME: May need to be internal wires, if not then added to constraint file
     // not sure but setting these as internal wires caused 11 new errors
     output       hdmi_hsync,
     output       hdmi_vsync

    );

    wire [7:0] hdmi_red;
    wire [7:0] hdmi_green;
    wire [7:0] hdmi_blue;

    wire          vga_visible;
    wire          vga_new_pxl;
    wire [10-1:0] vga_col;
    wire [10-1:0] vga_row;

    wire          vga_hsync_wr; // intermediate signal, not registered (wire)
    wire          vga_vsync_wr; // intermediate signal, not registered (wire
   
    wire [c_nb_img_pxls-1:0] frame_addr;
    wire [c_nb_buf-1:0]    frame_pixel;

    wire [c_nb_img_pxls-1:0] capture_addr;
    wire [c_nb_buf-1:0]    capture_data;
    wire          capture_we;
    wire          resend;
    wire          config_finished;

    wire          sdat_on;
    wire          sdat_out;  // not making it INOUT, just out, but 3-state

    //wire          clk100mhz;

    wire          rgbmode;
    wire          testmode;
    wire          locked_wire;
    parameter     swap_r_b = 1'b1; // red and blue are swapped
    
    wire          de;
    wire          clk_25mhz;
    wire          clk_125mhz;
    wire          clk_locked;
    
    //wire       hdmi_hsync;
    //wire       hdmi_vsync;


  // 100 MHz clock (already is, only difference with ULX3S
   //pll i_pll
     //(
      //.clkin(clk25mhz),
      //.clkout0(clk100mhz),
      //.locked(locked_wire)
             //);

    
    clk_wiz_0 clk_wizard (
      .clk_out1(clk_25mhz),      // 25 MHz pixel clock
      .clk_out2(clk_125mhz),     // 125 MHz serial clock
      .clk_out3(ov7670_xclk),    // 25 MHz camera clock
      .reset(rst),
      .locked(clk_locked),
      .clk_in1(clk_125mhz_in)    // 125 MHz from board
    );
    
    // Combined reset - holds system reset until clocks are stable
    wire rst_sys = rst | ~clk_locked;
    
    mode_sel sw2_mode_sel 
    (
      .rst     (rst_sys),
      .clk     (clk_25mhz),
      .sig_in  (btnc),
      .rgbmode (rgbmode),
      .testmode(testmode)
    );
    
    rgb2dvi_0 rgb2dvi_inst (
      // TMDS outputs (to top module ports -> HDMI connector)
      .TMDS_Clk_p(TMDS_Clk_p),
      .TMDS_Clk_n(TMDS_Clk_n),
      .TMDS_Data_p(TMDS_Data_p),     // [2:0]
      .TMDS_Data_n(TMDS_Data_n),     // [2:0]
      
      // Video inputs (from hdmi_display module)
      .vid_pData({hdmi_red, hdmi_green, hdmi_blue}),  // [23:0] concatenated
      .vid_pVDE(de),             // data enable
      .vid_pHSync(hdmi_hsync),        // hsync
      .vid_pVSync(hdmi_vsync),        // vsync
      
      // Clock inputs (from Clock Wizard)
      .PixelClk(clk_25mhz),
      .SerialClk(clk_125mhz),
      
      // Reset (from top module input)
      .aRst(rst_sys)
    );

// FIXME: replace VGA modules w appropriate HDMI modules
/*   vga_sync i_vga 
   (
     .rst     (rst),
     .clk     (clk100mhz),
     .visible (vga_visible),
     .new_pxl (vga_new_pxl),
     .hsync   (vga_hsync_wr),
     .vsync   (vga_vsync_wr),
     .col     (vga_col),
     .row     (vga_row)
  );*/

// FIXME: replace VGA modules w appropriate HDMI modules
/*  vga_display I_ov_display 
  (
     .rst        (rst),
     .clk        (clk100mhz),
     .visible    (vga_visible),
     .new_pxl    (vga_new_pxl),
     .hsync      (vga_hsync_wr),
     .vsync      (vga_vsync_wr),
     .rgbmode    (rgbmode),
     .testmode   (testmode),
     .col        (vga_col),
     .row        (vga_row),
     .frame_pixel(frame_pixel),
     .frame_addr (frame_addr),
     .hsync_out  (vga_hsync),
     .vsync_out  (vga_vsync),
     .vga_red    (vga_red),
     .vga_green  (vga_green),
     .vga_blue   (vga_blue)
  );*/

  hdmi_display I_ov_display
  (
      .rst          (rst_sys),
      .clk          (clk_25mhz), // 25 MHz pixel clock
      .rgbmode      (rgbmode),
      .testmode     (testmode),
      .frame_pixel  (frame_pixel),
      .frame_addr   (frame_addr),      
      .hsync_out    (hdmi_hsync),
      .vsync_out    (hdmi_vsync),
      .de_out       (de), // Data enable for RGB2DVI
      .hdmi_red     (hdmi_red),
      .hdmi_green   (hdmi_green),
      .hdmi_blue    (hdmi_blue)
  );


  frame_buffer fb  
  (
     .clk     (clk_25mhz),
     .wea     (capture_we),
     .addra   (capture_addr),
     .dina    (capture_data),
     .addrb   (frame_addr),
     .doutb   (frame_pixel)
   );

  ov7670_capture capture 
  (
     .rst          (rst_sys),
     .clk          (clk_25mhz),
     .pclk         (ov7670_pclk),
     .vsync        (ov7670_vsync),
     .href         (ov7670_href),
     .rgbmode      (rgbmode),
     .swap_r_b     (swap_r_b),
     //.dataout_test (ov_capture_datatest),
     //.led_test     (led[3:0]),
     .data         (ov7670_d),
     .addr         (capture_addr),
     .dout         (capture_data),
     .we           (capture_we)
  );
  
  ov7670_top_ctrl controller 
  (
     .rst          (rst_sys),
     .clk          (clk_25mhz),
     .resend       (resend),
     .rgbmode      (rgbmode),
     .testmode     (testmode),
     .cnt_reg_test (led[3:0]),
     .done         (config_finished),
     .sclk         (ov7670_sioc),
     .sdat_on      (sdat_on),
     .sdat_out     (sdat_out),
     .ov7670_rst_n (ov7670_rst_n),
     .ov7670_clk   (ov7670_xclk),
     .ov7670_pwdn  (ov7670_pwdn)
  );

  assign resend = 1'b0;
  assign ov7670_siod = sdat_on ? sdat_out : 1'bz;

  assign led[7] = config_finished;
  assign led[6] = 1'b0;


endmodule

