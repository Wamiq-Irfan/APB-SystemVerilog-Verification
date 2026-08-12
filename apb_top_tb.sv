`include "apb_if.sv" 
`include "apb_pkg.sv" 
 
import apb_pkg::*; 
 
module apb_top_tb; 
    logic clk; 
    initial 
        clk = 0; 
    always #5 clk = ~clk; 
    apb_if vif(clk); 
    apb_slave DUT( 
        .PCLK    (clk), 
        .PRESETn (vif.PRESETn), 
        .PSEL    (vif.PSEL), 
        .PENABLE (vif.PENABLE), 
        .PWRITE  (vif.PWRITE), 
        .PADDR   (vif.PADDR), 
        .PWDATA  (vif.PWDATA), 
        .PRDATA  (vif.PRDATA), 
        .PREADY  (vif.PREADY), 
        .PSLVERR (vif.PSLVERR)        
    ); 
    test t; 
    initial 
    begin 
        vif.PRESETn = 0; 
        vif.PSEL    = 0; 
        vif.PENABLE = 0; 
        vif.PWRITE  = 0; 
        vif.PADDR   = 0; 
        vif.PWDATA  = 0; 
        #20; 
        vif.PRESETn = 1; 
        t = new(vif); 
        fork 
            t.run(); 
        join_none 
        #120000; 
        
$display("========================================"); 
        $display("OVERALL COVERAGE = %0.2f%%", 
        t.env.mon.cov.cg.get_coverage()); 
        
$display("========================================"); 
        $finish; 
    end 
endmodule
