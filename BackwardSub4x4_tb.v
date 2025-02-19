// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module tb_BackwardSub4x4();
  reg         clk, rst, start;
  reg [511:0] U_in;
  reg [127:0] y_in;
  wire [127:0] x_out;
  wire         done;
  
  // Instantiate
  BackwardSub4x4 dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .U_in(U_in),
    .y_in(y_in),
    .done(done),
    .x_out(x_out)
  );
  
  // Clock
  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    rst=1; start=0; U_in=0; y_in=0;
    #20 rst=0;
    
    // Example U = [[4,2,3,1],
    //              [0,2,1,2],
    //              [0,0,1,3],
    //              [0,0,0,2]]
    
    U_in[ 31:  0] = 4;   // U[0]
    U_in[ 63: 32] = 2;   // U[1]
    U_in[ 95: 64] = 3;   // U[2]
    U_in[127: 96] = 1;   // U[3]
    U_in[159:128] = 0;   // U[4]
    U_in[191:160] = 2;   // U[5]
    U_in[223:192] = 1;   // U[6]
    U_in[255:224] = 2;   // U[7]
    U_in[287:256] = 0;   // U[8]
    U_in[319:288] = 0;   // U[9]
    U_in[351:320] = 1;   // U[10]
    U_in[383:352] = 3;   // U[11]
    U_in[415:384] = 0;   // U[12]
    U_in[447:416] = 0;   // U[13]
    U_in[479:448] = 0;   // U[14]
    U_in[511:480] = 2;   // U[15]
    
    // Suppose we have y=(18, 7, 5, 6)
    y_in[ 31:0]   = 18;
    y_in[ 63:32]  = 7;
    y_in[ 95:64]  = 5;
    y_in[127:96]  = 6;
    
    #10 start=1;
    #10 start=0;
    
    wait(done==1);
    #20;
    
    $display("x_out= %d, %d, %d, %d",
      x_out[ 31:0],
      x_out[ 63:32],
      x_out[ 95:64],
      x_out[127:96]);
    $finish;
  end
endmodule