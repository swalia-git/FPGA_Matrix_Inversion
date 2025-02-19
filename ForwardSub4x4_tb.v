`timescale 1ns/1ps

module tb_ForwardSub4x4();
  reg         clk, rst, start;
  reg [511:0] L_in;
  reg [127:0] b_in;
  wire [127:0] y_out;
  wire         done;
  
  // Instantiate the module
  ForwardSub4x4 dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .L_in(L_in),
    .b_in(b_in),
    .done(done),
    .y_out(y_out)
  );
  
  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz
  
  // Test stimulus
  initial begin
    rst = 1; start = 0; L_in = 0; b_in = 0;
    #20 rst = 0;
    
    // Example: L = [[2,0,0,0],
    //               [1,3,0,0],
    //               [2,4,2,0],
    //               [1,2,3,4]]
    // Flatten row-major (16 x 32-bit):
    // L[0] = 2, L[1] = 0, L[2] = 0, L[3] = 0,
    // L[4] = 1, L[5] = 3, L[6] = 0, L[7] = 0, ...
    
    L_in[  31:  0] = 2;   // L[0]
    L_in[  63: 32] = 0;   // L[1]
    L_in[  95: 64] = 0;   // L[2]
    L_in[ 127: 96] = 0;   // L[3]
    L_in[ 159:128] = 1;   // L[4]
    L_in[ 191:160] = 3;   // L[5]
    L_in[ 223:192] = 0;   // L[6]
    L_in[ 255:224] = 0;   // L[7]
    L_in[ 287:256] = 2;   // L[8]
    L_in[ 319:288] = 4;   // L[9]
    L_in[ 351:320] = 2;   // L[10]
    L_in[ 383:352] = 0;   // L[11]
    L_in[ 415:384] = 1;   // L[12]
    L_in[ 447:416] = 2;   // L[13]
    L_in[ 479:448] = 3;   // L[14]
    L_in[ 511:480] = 4;   // L[15]
    
    // b = (4, 13, 14, 28) => row vector of length=4
    // Flatten: b[0]=4, b[1]=13, b[2]=14, b[3]=28
    b_in[ 31:  0] = 4;
    b_in[ 63: 32] = 13;
    b_in[ 95: 64] = 14;
    b_in[127: 96] = 28;
    
    #10 start = 1;
    #10 start = 0; // remove start
    
    // Wait for done
    wait(done==1);
    #20;
    
    // Display results
    $display("y_out = %d, %d, %d, %d",
      y_out[ 31:0],
      y_out[ 63:32],
      y_out[ 95:64],
      y_out[127:96]);
    $finish;
  end
endmodule