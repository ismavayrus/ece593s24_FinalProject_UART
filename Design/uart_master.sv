module uart_master(
    input clk_tx, //clock
    input [7:0]data, //input from main bus or other module
    input en_tx, //enable signal to Tx UART 
    
    output reg u_tx, //output to another uart 
    output reg u_tx_done //Tx is done
   
);

parameter clk_freq = 50000000; //MHz
parameter baud_rate = 19200; //bits per second
localparam clkcount = (clk_freq/baud_rate);

//reg [2:0] state_tx;
// reg [2:0] state_rx;
reg [2:0] count;
reg [7:0] din;

integer counts = 0;
 
//reg uclk = 0;
  
 ///////////uart_clock_gen
 /* always@(posedge clk)
    begin
      if(counts < clkcount/2)
        counts <= counts + 1;
      else begin
        count <= 0;
        uclk <= ~uclk;
      end 
    end */
  

/*
parameter IDLE = 3'b000;
parameter START = 3'b001;
parameter DATA = 3'b010;
parameter PARITY = 3'b011;
parameter DONE = 3'b100;    */

enum bit[2:0]{ IDLE = 3'b000,
 START = 3'b001,
 DATA = 3'b010,
 PARITY = 3'b011,
  DONE = 3'b100} state_tx;

always @(posedge clk_tx ) begin
    case (state_tx)

    START: begin
        if (en_tx) begin
            state_tx <= DATA;
            din <= data;
            u_tx <= 0;
            u_tx_done <= 0;
            count <= 0;
        end
        else begin
            u_tx <= 1'bz;
            // state_tx <= START;
        end
        // u_tx <= 0;
        // state_tx <= DATA;
        // count <= 0;
        
    end

    DATA: begin
        count <= count + 1;
        if (count == 3'b111) begin
            u_tx <= din[count];
      		//$display("Trasmit done : %d ", u_tx);
            state_tx <= PARITY;
        end
        else u_tx <= din[count];
    end

    PARITY: begin
        u_tx <= ^din;  // even parity
        state_tx <= DONE;
    end

    DONE: begin
        u_tx_done <= 1;
        u_tx <= 0;
        state_tx <= START;
    end
    
    default: begin
        state_tx <= START;
    end
    endcase
end

endmodule
  
