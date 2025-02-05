`timescale 1ns/1ps

module tb_LU_Decomposition;

  // Testbench signals
  reg         clk;
  reg         rst;
  reg         start;
  reg  [511:0] A_in;
  wire        done;
  wire [511:0] L_out;
  wire [511:0] U_out;

  // Instantiate the LU_Decomposition module
  LU_Decomposition uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .A_in(A_in),
    .done(done),
    .L_out(L_out),
    .U_out(U_out)
  );

  // Clock generation: 10 ns period (5 ns high, 5 ns low)
  always #5 clk = ~clk;

  initial begin
    // Initialize signals
    clk   = 0;
    rst   = 1;
    start = 0;
    A_in  = 512'b0;

    // Hold reset for a few clock cycles.
    #20;
    rst = 0;

    // Apply the test matrix.
    // The internal ordering of A_in is as follows:
    //   A_in[31:0]      = A[0]  (Row0, Col0)
    //   A_in[63:32]     = A[1]  (Row0, Col1)
    //   A_in[95:64]     = A[2]  (Row0, Col2)
    //   A_in[127:96]    = A[3]  (Row0, Col3)
    //   A_in[159:128]   = A[4]  (Row1, Col0)
    //   A_in[191:160]   = A[5]  (Row1, Col1)
    //   A_in[223:192]   = A[6]  (Row1, Col2)
    //   A_in[255:224]   = A[7]  (Row1, Col3)
    //   A_in[287:256]   = A[8]  (Row2, Col0)
    //   A_in[319:288]   = A[9]  (Row2, Col1)
    //   A_in[351:320]   = A[10] (Row2, Col2)
    //   A_in[383:352]   = A[11] (Row2, Col3)
    //   A_in[415:384]   = A[12] (Row3, Col0)
    //   A_in[447:416]   = A[13] (Row3, Col1)
    //   A_in[479:448]   = A[14] (Row3, Col2)
    //   A_in[511:480]   = A[15] (Row3, Col3)
    //
    // We want:
    //   Row0: 4,  0,  0,  0
    //   Row1: 3,  2,  0,  0
    //   Row2: 0,  0,  3,  0
    //   Row3: 0,  0,  0,  5
    //
    // To pack the bus, note that the right–most 32–bit word becomes A_in[31:0] (i.e. A[0]).
    // Thus, we build the vector as:
    //
    //   { A[15], A[14], A[13], A[12],
    //     A[11], A[10], A[9],  A[8],
    //     A[7],  A[6],  A[5],  A[4],
    //     A[3],  A[2],  A[1],  A[0] }
    //
    // where:
    //   A[15] = 5           (Row3, Col3)
    //   A[14] = 0           (Row3, Col2)
    //   A[13] = 0           (Row3, Col1)
    //   A[12] = 0           (Row3, Col0)
    //   A[11] = 0           (Row2, Col3)
    //   A[10] = 3           (Row2, Col2)
    //   A[9]  = 0           (Row2, Col1)
    //   A[8]  = 0           (Row2, Col0)
    //   A[7]  = 0           (Row1, Col3)
    //   A[6]  = 0           (Row1, Col2)
    //   A[5]  = 2           (Row1, Col1)
    //   A[4]  = 3           (Row1, Col0)
    //   A[3]  = 0           (Row0, Col3)
    //   A[2]  = 0           (Row0, Col2)
    //   A[1]  = 0           (Row0, Col1)
    //   A[0]  = 4           (Row0, Col0)
    A_in = { 32'd5, 32'd0, 32'd0, 32'd0,  // Row3: Col3, Col2, Col1, Col0
             32'd0, 32'd3, 32'd0, 32'd0,  // Row2: Col3, Col2, Col1, Col0
             32'd0, 32'd0, 32'd2, 32'd3,  // Row1: Col3, Col2, Col1, Col0
             32'd0, 32'd0, 32'd0, 32'd4 };// Row0: Col3, Col2, Col1, Col0

    // Give a cycle and then assert 'start'
    #10;
    start = 1;
    #10;
    start = 0;

    // Wait until the module asserts the 'done' signal.
    wait (done == 1);
    #10;

    // Display the computed L and U matrices.
    $display("Computed L matrix:");
    display_matrix(L_out);
    $display("Computed U matrix:");
    display_matrix(U_out);

    #20;
    $finish;
  end

  // Task to display a 4x4 matrix from the packed 512-bit bus.
  // The matrix is stored in row-major order: each element is 32 bits.
  task display_matrix;
    input [511:0] matrix;
    integer r, c;
    reg [31:0] element;
    begin
      for (r = 0; r < 4; r = r + 1) begin
        $write("[ ");
        for (c = 0; c < 4; c = c + 1) begin
          // Each element is located at:
          // matrix[(r*4+c)*32 +: 32]
          element = matrix[(r*4+c)*32 +: 32];
          $write("%0d ", element);
        end
        $write("]\n");
      end
    end
  endtask

endmodule