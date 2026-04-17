// `default_nettype none

module ov5640_top_ctrl
  (input        rst,              //reset, active high
   input        clk,              //FPGA clock
   input        resend,           //resend the sequence
   input        rgbmode,         //if '1': in RGB, else YUV
   input        testmode,        //if '1': in test mode
   output [5:0] cnt_reg_test,     //to test the count
   output       done,             //all transmission done
   inout        sclk,             //sccb clock
   //output       sdat_in,        //sccb serial data in
   inout        sdat,             //sccb serial data ou
   output reg   power_en          //camera power enable (not power down!)
  );
    localparam CYC_PER_MS = 125000;
    localparam LAST_VLD_STATE = 4'd8;

    reg [7:0] delay_ms;
    reg i2c_en;  
    reg [15:0] i2c_addr;
    reg [7:0] i2c_data;

    reg [3:0] state;
    reg [7:0] ms_counter;
    reg [16:0] clk_counter;

    wire trig_i2c_send;
    
    assign cnt_reg_test[3:0] = state;
    assign done = state >= LAST_VLD_STATE;

    always @* begin
        case (state)
            4'd0: begin
                // Start without power to the camera
                delay_ms = 8'd100;
                power_en = 1'b0;
                i2c_en   = 1'b0;
                i2c_addr = 16'hxxxx;
                i2c_data = 8'hxx;
            end
            4'd1: begin
                // Re-apply power after 100 ms
                delay_ms = 8'd50;
                power_en = 1'b1;
                i2c_en   = 1'b0;
                i2c_addr = 16'hxxxx;
                i2c_data = 8'hxx;
            end
            4'd2: begin
                // “system input clock from pad”???
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h3013;
                i2c_data = 8'h11;
            end
            4'd3: begin
                // Execute software reset
                delay_ms = 8'd10;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h3008;
                i2c_data = 8'h82;
            end
            4'd4: begin
                // Wait 10 miliseconds, de-assert reset, software power down
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h3008;
                i2c_data = 8'h42;
            end
            4'd5: begin
                // Enable MIPI 2-lane
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h300e;
                i2c_data = 8'h45;
            end
            4'd6: begin
                // LP11 when idle (?)
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h4800;
                i2c_data = 8'h14;
            end
            4'd7: begin
                // Switch to RGB888
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h4300;
                i2c_data = 8'h23;
            end
            4'd8: begin
                // Turn camera on (possibly wrong address)
                delay_ms = 8'd1;
                power_en = 1'b1;
                i2c_en   = 1'b1;
                i2c_addr = 16'h3008;
                i2c_data = 8'h02;
            end
            default: begin
                delay_ms = 8'dx;
                power_en = 1'b1;
                i2c_en   = 1'b0;
                i2c_addr = 16'hxxxx;
                i2c_data = 8'hxx;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst | resend) begin
            state <= 4'b0;
            ms_counter <= 8'b0;
            clk_counter <= 17'b0;
        end else begin
            if (clk_counter >= CYC_PER_MS-1) begin
                clk_counter <= 17'b0;
                if (ms_counter + 1 >= delay_ms) begin
                    ms_counter <= 0;
                    if (state >= LAST_VLD_STATE) begin
                        state <= 4'd15;
                    end else begin
                        state <= state + 1;
                    end
                end else begin
                    ms_counter <= ms_counter + 1;
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    assign trig_i2c_send = i2c_en && 
                           ms_counter + 1 >= delay_ms && 
                           clk_counter >= CYC_PER_MS-1 && 
                           state <= LAST_VLD_STATE;

    i2c_master i2c_master_impl (
        .i_clk(clk),       
        .reset_n(~rst),     
        .i_addr_w_rw(8'h78), // Pcam 5c address 
        .i_sub_addr(i2c_addr),  
        .i_sub_len(1'b1),   
        .i_byte_len(1'b1),  
        .i_data_write(i2c_data),
        .req_trans(trig_i2c_send),   
                               
        .data_out(),
        .valid_out(),
                            
        .scl_o(sclk), 
        .sda_o(sdat),     

        .req_data_chunk(),
        .busy(),        
        .nack()         
    );
endmodule