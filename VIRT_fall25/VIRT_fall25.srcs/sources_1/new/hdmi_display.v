//------------------------------------------------------------------------------
// HDMI Display Wrapper
// Replaces vga_display module for HDMI output via RGB2DVI IP
// - Generates 640x480@60Hz timing
// - Scales 320x240 frame buffer to 640x480 (2x2 pixel replication)
// - Converts RGB444 to RGB888 via bit replication
// - Maintains compatibility with original vga_display interface
//------------------------------------------------------------------------------

module hdmi_display
  #(parameter
      // Frame buffer parameters (320x240)
      c_img_cols    = 320,
      c_img_rows    = 240,
      c_img_pxls    = c_img_cols * c_img_rows,
      c_nb_img_pxls = 17,  // 320*240=76,800 -> 2^17
      
      c_nb_buf_red   = 4,
      c_nb_buf_green = 4,
      c_nb_buf_blue  = 4,
      c_nb_buf       = c_nb_buf_red + c_nb_buf_green + c_nb_buf_blue,
      
      // HDMI output resolution (640x480@60Hz)
      c_hdmi_cols = 640,
      c_hdmi_rows = 480,
      
      // 640x480@60Hz timing parameters (25.175 MHz pixel clock)
      c_h_sync_pulse   = 96,
      c_h_back_porch   = 48,
      c_h_active       = 640,
      c_h_front_porch  = 16,
      c_h_total        = 800,
      
      c_v_sync_pulse   = 2,
      c_v_back_porch   = 33,
      c_v_active       = 480,
      c_v_front_porch  = 10,
      c_v_total        = 525
    )
    (
      input  rst,
      input  clk,              // 25 MHz pixel clock
      input  rgbmode,
      input  testmode,
      input  [c_nb_buf-1:0] frame_pixel,
      output reg [c_nb_img_pxls-1:0] frame_addr,
      
      // HDMI/RGB2DVI outputs
      output reg hsync_out,
      output reg vsync_out,
      output reg de_out,       // Data enable for RGB2DVI
      output reg [7:0] hdmi_red,
      output reg [7:0] hdmi_green,
      output reg [7:0] hdmi_blue
    );

  // Timing counters
  reg [10:0] h_count;  // Horizontal counter (0-799)
  reg [9:0]  v_count;  // Vertical counter (0-524)
  
  // Timing signals (combinatorial)
  wire h_active;
  wire v_active;
  wire visible;
  wire hsync;
  wire vsync;
  
  // Scaled image coordinates (640x480)
  wire [9:0] hdmi_col;
  wire [8:0] hdmi_row;
  
  // Frame buffer coordinates (320x240)
  wire [8:0] fb_col;
  wire [7:0] fb_row;
  
  // Area indicators
  reg img_active;
  reg txt1_active;
  reg txt2_active;
  reg bwt_active;
  reg clt_active;
  
  // Text rendering
  reg [7:0] char_rgbmode;
  reg [7:0] char_testmode;
  wire [2:0] char_row;
  wire [2:0] char_col;
  wire [3:0] addr_rom_rgb;
  wire [3:0] addr_rom_test;
  
  // Text area parameters (scaled to 640x480)
  parameter C_TXT_ROW_MIN  = 496;  // 248*2
  parameter C_TXT_ROW_MAX  = 512;  // 256*2
  parameter C_TXT1_COL_MIN = 16;   // 8*2
  parameter C_TXT1_COL_MAX = 32;   // 16*2
  parameter C_TXT2_COL_MIN = 32;   // 16*2
  parameter C_TXT2_COL_MAX = 48;   // 24*2
  
  // BW test area (scaled)
  parameter C_BWT_ROW_MIN = 480;   // 240*2
  parameter C_BWT_ROW_MAX = 512;   // 256*2
  parameter C_BWT_COL_MIN = 256;   // 128*2
  parameter C_BWT_COL_MAX = 512;   // 256*2
  
  // Color test area (scaled)
  parameter C_CLT_ROW_MIN = 512;   // 256*2
  parameter C_CLT_ROW_MAX = 768;   // 384*2 (off-screen in 640x480)
  parameter C_CLT_COL_MIN = 0;
  parameter C_CLT_COL_MAX = 512;   // 256*2

  //----------------------------------------------------------------------------
  // Horizontal and Vertical Counters
  //----------------------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      h_count <= 0;
      v_count <= 0;
    end else begin
      if (h_count == c_h_total - 1) begin
        h_count <= 0;
        if (v_count == c_v_total - 1)
          v_count <= 0;
        else
          v_count <= v_count + 1;
      end else begin
        h_count <= h_count + 1;
      end
    end
  end

  //----------------------------------------------------------------------------
  // Timing Signals
  //----------------------------------------------------------------------------
  assign hsync = (h_count < c_h_sync_pulse) ? 1'b0 : 1'b1;
  assign vsync = (v_count < c_v_sync_pulse) ? 1'b0 : 1'b1;
  
  assign h_active = (h_count >= (c_h_sync_pulse + c_h_back_porch)) && 
                    (h_count < (c_h_sync_pulse + c_h_back_porch + c_h_active));
  assign v_active = (v_count >= (c_v_sync_pulse + c_v_back_porch)) && 
                    (v_count < (c_v_sync_pulse + c_v_back_porch + c_v_active));
  
  assign visible = h_active && v_active;
  
  // Active area coordinates
  assign hdmi_col = h_active ? (h_count - (c_h_sync_pulse + c_h_back_porch)) : 10'd0;
  assign hdmi_row = v_active ? (v_count - (c_v_sync_pulse + c_v_back_porch)) : 9'd0;
  
  // Map 640x480 coordinates to 320x240 frame buffer (divide by 2)
  assign fb_col = hdmi_col[9:1];  // Divide by 2
  assign fb_row = hdmi_row[8:1];  // Divide by 2
  
  // Text character position (scaled)
  assign char_row = hdmi_row[3:1];  // Divide by 2 for text scaling
  assign char_col = hdmi_col[3:1];
  assign addr_rom_rgb  = {~rgbmode, char_row};
  assign addr_rom_test = {testmode, char_row};

  //----------------------------------------------------------------------------
  // Area Detection
  //----------------------------------------------------------------------------
  always @(*) begin
    img_active  = (hdmi_col < (c_img_cols * 2)) && (hdmi_row < (c_img_rows * 2));
    txt1_active = (hdmi_row >= C_TXT_ROW_MIN && hdmi_row < C_TXT_ROW_MAX) &&
                  (hdmi_col >= C_TXT1_COL_MIN && hdmi_col < C_TXT1_COL_MAX);
    txt2_active = (hdmi_row >= C_TXT_ROW_MIN && hdmi_row < C_TXT_ROW_MAX) &&
                  (hdmi_col >= C_TXT2_COL_MIN && hdmi_col < C_TXT2_COL_MAX);
    bwt_active  = (hdmi_row >= C_BWT_ROW_MIN && hdmi_row < C_BWT_ROW_MAX) &&
                  (hdmi_col >= C_BWT_COL_MIN && hdmi_col < C_BWT_COL_MAX);
    clt_active  = (hdmi_row >= C_CLT_ROW_MIN && hdmi_row < C_CLT_ROW_MAX) &&
                  (hdmi_col >= C_CLT_COL_MIN && hdmi_col < C_CLT_COL_MAX);
  end

  //----------------------------------------------------------------------------
  // Frame Buffer Address Generation
  //----------------------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      frame_addr <= 0;
    end else begin
      if (visible && img_active) begin
        // Only increment on even pixels/rows to avoid reading same pixel 4 times
        if (hdmi_col[0] == 1'b0 && hdmi_row[0] == 1'b0) begin
          frame_addr <= fb_row * c_img_cols + fb_col;
        end
      end else if (!v_active) begin
        frame_addr <= 0;
      end
    end
  end

  //----------------------------------------------------------------------------
  // Text ROM (RGB/YUV indicator)
  //----------------------------------------------------------------------------
  always @(posedge clk) begin
    case (addr_rom_rgb)
      4'h0: char_rgbmode <= 8'b11111100; // R: RGB
      4'h1: char_rgbmode <= 8'b10000010;
      4'h2: char_rgbmode <= 8'b10000010;
      4'h3: char_rgbmode <= 8'b11111100;
      4'h4: char_rgbmode <= 8'b10001000;
      4'h5: char_rgbmode <= 8'b10000100;
      4'h6: char_rgbmode <= 8'b10000010;
      4'h7: char_rgbmode <= 8'b00000000;
      4'h8: char_rgbmode <= 8'b10000010; // Y: YUV
      4'h9: char_rgbmode <= 8'b01000100;
      4'hA: char_rgbmode <= 8'b00111000;
      4'hB: char_rgbmode <= 8'b00010000;
      4'hC: char_rgbmode <= 8'b00010000;
      4'hD: char_rgbmode <= 8'b00010000;
      4'hE: char_rgbmode <= 8'b00010000;
      4'hF: char_rgbmode <= 8'b00000000;
    endcase
  end

  always @(posedge clk) begin
    case (addr_rom_test)
      4'h0: char_testmode <= 8'b10000010; // N: Normal
      4'h1: char_testmode <= 8'b11000010;
      4'h2: char_testmode <= 8'b10100010;
      4'h3: char_testmode <= 8'b10010010;
      4'h4: char_testmode <= 8'b10001010;
      4'h5: char_testmode <= 8'b10000110;
      4'h6: char_testmode <= 8'b10000010;
      4'h7: char_testmode <= 8'b00000000;
      4'h8: char_testmode <= 8'b11111110; // T: Test
      4'h9: char_testmode <= 8'b00010000;
      4'hA: char_testmode <= 8'b00010000;
      4'hB: char_testmode <= 8'b00010000;
      4'hC: char_testmode <= 8'b00010000;
      4'hD: char_testmode <= 8'b00010000;
      4'hE: char_testmode <= 8'b00010000;
      4'hF: char_testmode <= 8'b00000000;
    endcase
  end

  //----------------------------------------------------------------------------
  // Pixel Data Output (RGB444 -> RGB888 with bit replication)
  //----------------------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      hdmi_red   <= 8'h00;
      hdmi_green <= 8'h00;
      hdmi_blue  <= 8'h00;
      hsync_out  <= 1'b1;
      vsync_out  <= 1'b1;
      de_out     <= 1'b0;
    end else begin
      hsync_out <= hsync;
      vsync_out <= vsync;
      de_out    <= visible;
      
      if (visible) begin
        if (img_active) begin
          // Frame buffer image
          if (rgbmode) begin
            // RGB mode: replicate 4-bit colors to 8-bit
            hdmi_red   <= {frame_pixel[11:8], frame_pixel[11:8]};
            hdmi_green <= {frame_pixel[7:4],  frame_pixel[7:4]};
            hdmi_blue  <= {frame_pixel[3:0],  frame_pixel[3:0]};
          end else begin
            // YUV mode: grayscale (Y component)
            hdmi_red   <= {frame_pixel[7:4], frame_pixel[7:4]};
            hdmi_green <= {frame_pixel[7:4], frame_pixel[7:4]};
            hdmi_blue  <= {frame_pixel[7:4], frame_pixel[7:4]};
          end
        end else if (txt1_active && char_rgbmode[7-char_col]) begin
          // Text 1: RGB/YUV indicator
          hdmi_red   <= 8'hFF;
          hdmi_green <= 8'hFF;
          hdmi_blue  <= 8'hFF;
        end else if (txt2_active && char_testmode[7-char_col]) begin
          // Text 2: Normal/Test indicator
          hdmi_red   <= 8'hFF;
          hdmi_green <= 8'hFF;
          hdmi_blue  <= 8'hFF;
        end else if (bwt_active) begin
          // Black/white test pattern
          hdmi_red   <= {hdmi_col[7:4], hdmi_col[7:4]};
          hdmi_green <= {hdmi_col[7:4], hdmi_col[7:4]};
          hdmi_blue  <= {hdmi_col[7:4], hdmi_col[7:4]};
        end else if (clt_active) begin
          // Color test pattern
          hdmi_red   <= {hdmi_col[8:5], hdmi_col[8:5]};
          hdmi_green <= {hdmi_col[6:3], hdmi_col[6:3]};
          hdmi_blue  <= {hdmi_row[6:3], hdmi_row[6:3]};
        end else begin
          // Black background
          hdmi_red   <= 8'h00;
          hdmi_green <= 8'h00;
          hdmi_blue  <= 8'h00;
        end
      end else begin
        // Blanking period
        hdmi_red   <= 8'h00;
        hdmi_green <= 8'h00;
        hdmi_blue  <= 8'h00;
      end
    end
  end

endmodule