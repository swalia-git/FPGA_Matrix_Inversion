// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module matrix_subtraction_fixed_point_tb;
    // Parameters
    parameter SIZE = 3;           // 3x3 matrices for testing
    parameter INT_WIDTH = 8;      // 8 bits for integer part
    parameter FRAC_WIDTH = 8;     // 8 bits for fractional part
    
    // Total width
    localparam TOTAL_WIDTH = INT_WIDTH + FRAC_WIDTH;
    
    // Scale factor for fixed point (2^FRAC_WIDTH)
    localparam SCALE = 2**FRAC_WIDTH;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg start;
    reg signed [TOTAL_WIDTH-1:0] matrix_a [0:SIZE-1][0:SIZE-1];
    reg signed [TOTAL_WIDTH-1:0] matrix_b [0:SIZE-1][0:SIZE-1];
    wire signed [TOTAL_WIDTH-1:0] result [0:SIZE-1][0:SIZE-1];
    wire done;
    
    // Variables for verification
    real expected;
    real actual;
    real epsilon;
    
    // Function to convert real to fixed point
    function automatic signed [TOTAL_WIDTH-1:0] real_to_fixed(input real r);
        real_to_fixed = r * SCALE;
    endfunction
    
    // Function to convert fixed point to real
    function automatic real fixed_to_real(input signed [TOTAL_WIDTH-1:0] f);
        fixed_to_real = $itor(f) / SCALE;
    endfunction
    
    // Instantiate the Unit Under Test (UUT)
    matrix_subtraction_fixed_point #(
        .SIZE(SIZE),
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .result(result),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end
    
    // Test case data with floating point values
    initial begin
        // Convert from real to fixed point for matrix initialization
        // Matrix A (floating point values)
        matrix_a[0][0] = real_to_fixed(10.5); matrix_a[0][1] = real_to_fixed(20.25); matrix_a[0][2] = real_to_fixed(30.75);
        matrix_a[1][0] = real_to_fixed(40.125); matrix_a[1][1] = real_to_fixed(50.0); matrix_a[1][2] = real_to_fixed(60.375);
        matrix_a[2][0] = real_to_fixed(70.625); matrix_a[2][1] = real_to_fixed(80.25); matrix_a[2][2] = real_to_fixed(90.5);
        
        // Matrix B (floating point values)
        matrix_b[0][0] = real_to_fixed(5.25); matrix_b[0][1] = real_to_fixed(10.125); matrix_b[0][2] = real_to_fixed(15.5);
        matrix_b[1][0] = real_to_fixed(20.75); matrix_b[1][1] = real_to_fixed(25.25); matrix_b[1][2] = real_to_fixed(30.125);
        matrix_b[2][0] = real_to_fixed(35.5); matrix_b[2][1] = real_to_fixed(40.625); matrix_b[2][2] = real_to_fixed(45.75);
    end
    
    // Test procedure
    initial begin
        // Initialize inputs
        reset = 1;
        start = 0;
        epsilon = 0.01; // Small value for floating point comparison
        
        // Apply reset
        #20;
        reset = 0;
        #10;
        
        // Start the subtraction process
        start = 1;
        #10;
        start = 0;
        
        // Wait for done signal
        wait(done);
        #20;
        
        // Display results in floating point format
        $display("Matrix Subtraction Results (Floating Point):");
        $display("Matrix A:");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(matrix_a[i][j]));
            end
            $write("\n");
        end
        
        $display("Matrix B:");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(matrix_b[i][j]));
            end
            $write("\n");
        end
        
        $display("Result (A - B):");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(result[i][j]));
            end
            $write("\n");
        end
        
        // Verify results
        $display("\nVerifying results...");
        
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                expected = fixed_to_real(matrix_a[i][j]) - fixed_to_real(matrix_b[i][j]);
                actual = fixed_to_real(result[i][j]);
                
                if (actual < expected - epsilon || actual > expected + epsilon) begin
                    $display("Error at position [%0d][%0d]: Expected %f, Got %f", 
                             i, j, expected, actual);
                end
            end
        end
        $display("Verification complete!");
        
        // Test a case with negative floating point numbers
        #20;
        $display("\nTesting with negative floating point numbers:");
        
        // Matrix A with negative numbers
        matrix_a[0][0] = real_to_fixed(-10.25); matrix_a[0][1] = real_to_fixed(-5.5);  matrix_a[0][2] = real_to_fixed(0.125);
        matrix_a[1][0] = real_to_fixed(5.75);   matrix_a[1][1] = real_to_fixed(10.375);  matrix_a[1][2] = real_to_fixed(15.5);
        matrix_a[2][0] = real_to_fixed(20.125);  matrix_a[2][1] = real_to_fixed(25.75);  matrix_a[2][2] = real_to_fixed(30.25);
        
        // Matrix B 
        matrix_b[0][0] = real_to_fixed(5.5);   matrix_b[0][1] = real_to_fixed(10.25);  matrix_b[0][2] = real_to_fixed(15.75);
        matrix_b[1][0] = real_to_fixed(-5.25);  matrix_b[1][1] = real_to_fixed(0.375);   matrix_b[1][2] = real_to_fixed(5.125);
        matrix_b[2][0] = real_to_fixed(10.5);  matrix_b[2][1] = real_to_fixed(15.125);  matrix_b[2][2] = real_to_fixed(20.625);
        
        // Start new subtraction
        #10;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done signal
        wait(done);
        #20;
        
        // Display results for negative test
        $display("Matrix A (with negatives):");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(matrix_a[i][j]));
            end
            $write("\n");
        end
        
        $display("Matrix B:");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(matrix_b[i][j]));
            end
            $write("\n");
        end
        
        $display("Result (A - B):");
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                $write("%8.3f ", fixed_to_real(result[i][j]));
            end
            $write("\n");
        end
        
        // Verify results of negative test
        $display("\nVerifying results for negative test...");
        
        for (integer i = 0; i < SIZE; i = i + 1) begin
            for (integer j = 0; j < SIZE; j = j + 1) begin
                expected = fixed_to_real(matrix_a[i][j]) - fixed_to_real(matrix_b[i][j]);
                actual = fixed_to_real(result[i][j]);
                
                if (actual < expected - epsilon || actual > expected + epsilon) begin
                    $display("Error at position [%0d][%0d]: Expected %f, Got %f", 
                             i, j, expected, actual);
                end
            end
        end
        $display("Verification complete!");
        
        // End simulation
        #30;
        $display("Simulation completed successfully!");
        $finish;
    end
    
    // Optional: Save waveform data
    initial begin
        $dumpfile("matrix_subtraction_fixed_point_tb.vcd");
        $dumpvars(0, matrix_subtraction_fixed_point_tb);
    end
    
endmodule