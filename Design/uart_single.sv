`timescale 1ns / 1ps
 
module uart_single
#(
parameter clk_freq = 1000000,
parameter baud_rate = 9600
)
(
  input clk,rst, 
  input rx,
  input [7:0] dintx,
  input newd,en_tx,en_rx,
  output tx, 
  output [7:0] doutrx,
  output donetx,
  output donerx
    );
    
wire txrx;                      // wire that goes from tx(output of uarttx) to rx(input to uartrx )
 
uarttx 
#(clk_freq, baud_rate) 
utx   
(.clk(clk), .rst(rst), .newd(newd), .tx_data(dintx), .tx(tx), .donetx(donetx), .en_tx(en_tx));   
 
uartrx 
#(clk_freq, baud_rate)
rtx
(.clk(clk), .rst(rst), .rx(rx), .done(donerx), .rxdata(doutrx), .en_rx(en_rx));    
    
    
endmodule
 
 
//////////////////////////////////////////////////////////////////
 
module uarttx
#(
parameter clk_freq = 1000000,
parameter baud_rate = 9600
)
(
input clk,rst,
input newd,en_tx,
input [7:0] tx_data,
output reg tx,
output reg donetx
);
 
  localparam clkcount = (clk_freq/baud_rate); ///x
  
integer count = 0;
integer counts = 0;
 
reg uclk = 0;
  
enum bit[1:0] {idle = 2'b00, start = 2'b01, transfer = 2'b10, done = 2'b11} state;
 
 ///////////uart_clock_gen
  always@(posedge clk)
    begin
      if(count < clkcount/2)
        count <= count + 1;
      else begin
        count <= 0;
        uclk <= ~uclk;
      end 
    end
  
  
  reg [7:0] din;
  ////////////////////Reset decoder
  
  
  always@(posedge uclk)
    begin
      if(rst) 
      begin
        state <= idle;
      end
     else
     begin
     case(state)
       idle:
         begin
           counts <= 0;
           tx <= 1'b1;
           donetx <= 1'b0;
           
           if( en_tx && newd) 
           begin
             state <= transfer;
             din <= tx_data;
             tx <= 1'b0;                            // acts like start bit
           end
           else
             state <= idle;       
         end
       
 
      
      transfer: begin
        if(counts <= 7) begin
           counts <= counts + 1;
           tx <= din[counts];                    // 
           state <= transfer;
        end
        else 
        begin
           counts <= 0;
           tx <= 1'b1;
           state <= idle;
          donetx <= 1'b1;
        end
      end
      
 
      
     
      default : state <= idle;
    endcase
  end
end
 
endmodule
 
 
 
////////////////////////////////////////////////////////////////////
 
 
 
 
module uartrx
#(
parameter clk_freq = 1000000, //MHz
parameter baud_rate = 9600
    )
 (
input clk,
input rst,
input rx,en_rx,
output reg done,
output reg [7:0] rxdata
);
    
localparam clkcount = (clk_freq/baud_rate);
  
integer count = 0;
integer counts = 0;
  
reg uclk = 0;
  
  
enum bit[1:0] {idle = 2'b00, start = 2'b01} state;
 
 ///////////uart_clock_gen
  always@(posedge clk)
    begin
      if(count < clkcount/2)
        count <= count + 1;
      else begin
        count <= 0;
        uclk <= ~uclk;
      end 
    end
  
  
 
  always@(posedge uclk)
    begin
      if(rst) 
      begin
     rxdata <= 8'h00;
     counts <= 0;
     done <= 1'b0;
      end
     else
     begin
     case(state)
       
     idle : 
     begin
     rxdata <= 8'h00;
     counts <= 0;
     done <= 1'b0;
     
     if(rx == 1'b0 && en_rx)
       state <= start;
     else
       state <= idle;
     end
     
     start: 
     begin
       if(counts <= 7)
      begin
     counts <= counts + 1;
     rxdata <= {rx, rxdata[7:1]};
     end
     else
     begin
     counts <= 0;
     done <= 1'b1;
     state <= idle;
     end
     end
   
   
   default : state <= idle;
   
   endcase
 
end
 
end
 
endmodule
 
 
///////////////////////////////////////////////////////////////////
 


