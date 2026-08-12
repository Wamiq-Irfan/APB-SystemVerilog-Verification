module apb_slave( 
    input  logic        PCLK, 
    input  logic        PRESETn, 
    input  logic        PSEL, 
    input  logic        PENABLE, 
    input  logic        PWRITE, 
    input  logic [7:0]  PADDR, 
    input  logic [31:0] PWDATA, 
    output logic [31:0] PRDATA, 
    output logic        PREADY, 
    output logic        PSLVERR 
); 
logic [31:0] mem [0:255]; 
integer i; 
always_ff @(posedge PCLK or negedge 
PRESETn) 
begin 
    if(!PRESETn) 
    begin 
        for(i = 0; i < 256; i = i + 1) 
            mem[i] <= 32'd0; 
 
        PRDATA  <= 32'd0; 
        PREADY  <= 1'b0; 
        PSLVERR <= 1'b0; 
    end 
    else 
    begin 
        PREADY  <= 1'b0; 
        PSLVERR <= 1'b0; 
        if(PSEL && PENABLE) 
        begin 
            PREADY <= 1'b1; 
            if(PADDR == 8'hFF) 
            begin 
                PSLVERR <= 1'b1; 
                PRDATA  <= 32'd0; 
            end 
            else 
            begin 
                PSLVERR <= 1'b0; 
                if(PWRITE) 
                begin 
                    mem[PADDR] <= PWDATA; 
                end 
                else 
                begin 
                    PRDATA <= mem[PADDR]; 
                end 
            end 
        end 
    end 
end 
endmodule 
