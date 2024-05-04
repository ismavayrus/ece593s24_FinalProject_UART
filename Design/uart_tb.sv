`timescale 1ns / 1ps

class transaction;
  
  typedef enum bit {TX1RX2 = 1'b0 , TX2RX1 = 1'b1} oper_type;                       //write =0, read =1
  randc oper_type oper;
 // bit rx;
  rand bit [7:0] din;
  bit newd;
  bit en_tx1,en_tx2,en_rx1,en_rx2;
  bit donerx1,donerx2,donetx1,donetx2;
  bit tx1rx2, tx2rx1;
  
  bit [7:0] dout;
  //bit donetx;
  //bit donerx;
  
  function transaction copy();
    copy = new();
   copy.din = this.din;
   copy.newd = this.newd;
    copy.dout = this.dout;
    copy.donerx1 = this.donerx1;
    copy.donerx2 = this.donerx2;
    copy.donetx1 = this.donetx1;
    copy.donetx2 = this.donetx2;

    copy.oper = this.oper;
  endfunction
  
endclass
  
class generator;
  
 transaction tr;
  
  mailbox #(transaction) mbx;
  
  event done;
  
  int count = 0;
  
  event drvnext;
  event sconext;
  
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction
  
  
  task run();
  
    repeat(5) begin
      assert(tr.randomize) else $error("[GEN] :Randomization Failed");
      mbx.put(tr.copy);
      $display("[GEN]: Oper : %0s Din : %0d",tr.oper.name(), tr.din);
      @(drvnext);
      @(sconext);
    end
    
    -> done;
  endtask
  
  
endclass
 

 
class driver;
  virtual uart_if vif;
  
  transaction tr;
  
  mailbox #(transaction) mbx;
  
  mailbox #(bit [7:0]) mbxds;
  
  
  event drvnext;
  
  bit [7:0] din;
  
  
  bit TX1RX2 = 0;  ///random operation TX2RX1 / TX1RX2
  bit [7:0] datarx;  ///data rcvd during read
  
  function new(mailbox #(bit [7:0]) mbxds, mailbox #(transaction) mbx);
    this.mbx = mbx;
    this.mbxds = mbxds;
   endfunction
  
  
  
  task reset();
    vif.rst <= 1'b1;
    vif.din <= 0;
    vif.newd <= 0;
    //vif.rx <= 1'b1;
 
    repeat(5) @(posedge vif.uclktx);
    vif.rst <= 1'b0;
    @(posedge vif.uclktx);
    $display("[DRV] : RESET DONE");
    $display("----------------------------------------");
  endtask
  
  
  
  task run();
  
    forever begin
      mbx.get(tr);
      
      if(tr.oper == 1'b0)  ////data transmission from TX1 to RX2
          begin
          //           
            @(posedge vif.uclktx);
            vif.rst <= 1'b0;
            vif.newd <= 1'b1;  ///start data sending op
            //vif.rx <= 1'b1;
            vif.din = tr.din;
			vif.en_tx1 <= 1'b1 ;
            vif.en_rx2 <= 1'b1 ;
			vif.en_tx2 <= 1'b0 ;
			vif.en_rx2 <= 1'b0 ;  
            @(posedge vif.uclktx);
            vif.newd <= 1'b0;
              ////wait for completion 
            //repeat(9) @(posedge vif.uclktx);
            mbxds.put(tr.din);
            $display("[DRV]: Data Sent : %0d", tr.din);
             wait(vif.donetx1 == 1'b1 || vif.donetx2 == 1'b1); 
			 wait(vif.donerx1 == 1'b1 || vif.donerx2 == 1'b1);	
			  $display("[DRV]: Data reveied : %0d", tr.dout);
             ->drvnext;  
          end
      
      else if (tr.oper == 1'b1)
               begin
                 
                 @(posedge vif.uclkrx);
                  vif.rst <= 1'b0;
                  //vif.rx <= 1'b0;
                  vif.newd <= 1'b1;
				  vif.en_tx1 <= 1'b0 ;
                  vif.en_rx2 <= 1'b0 ;
			      vif.en_tx2 <= 1'b1 ;
			      vif.en_rx2 <= 1'b1 ;  
                 @(posedge vif.uclktx);
                   vif.newd <= 1'b0;
                  ////wait for completion 
                   //repeat(9) @(posedge vif.uclktx);
                  mbxds.put(tr.din);
                  $display("[DRV]: Data Sent : %0d", tr.din);
                   wait(vif.donetx1 == 1'b1 || vif.donetx2 == 1'b1);  
				   wait(vif.donerx1 == 1'b1 || vif.donerx2 == 1'b1);	
			       $display("[DRV]: Data reveied : %0d", tr.dout);
                   ->drvnext;  
                 
 
             end         
  
       
      
    end
    
  endtask
  
endclass
  
class monitor;
 
  transaction tr;
  
  mailbox #(bit [7:0]) mbx;
  
  bit [7:0] srx; //////send
  bit [7:0] rrx; ///// recv
  
 
  
  virtual uart_if vif;
  
  
  function new(mailbox #(bit [7:0]) mbx);
    this.mbx = mbx;
    endfunction
  
  task run();
    
    forever begin
     
       @(posedge vif.uclktx);
      if ( (vif.newd== 1'b1)) 
                begin
                  
                  @(posedge vif.uclktx); ////start collecting tx data from next clock tick
                  
              for(int i = 0; i<= 7; i++) 
              begin 
                    @(posedge vif.uclktx);
                    srx[i] = vif.din;
                    
              end 
                  $display("[MON] : DATA SEND on UART TX %0d", srx);
                  
                  //////////wait for done tx before proceeding next transaction                
                @(posedge vif.uclktx); //
                mbx.put(srx);
                 
               end
      
      else if ((vif.en_rx1 || vif.en_rx2)&& vif.newd == 1'b0 ) 
        begin
          wait(vif.donerx1 == 1 || vif.donerx2 == 1);
           rrx = vif.dout;     
           $display("[MON] : DATA RCVD RX %0d", rrx);
           @(posedge vif.uclktx); 
           mbx.put(rrx);
      end
  end  
endtask
  
 
endclass
  
 
class scoreboard;
  mailbox #(bit [7:0]) mbxds, mbxms;
  
  bit [7:0] ds;
  bit [7:0] ms;
  
   event sconext;
  
  function new(mailbox #(bit [7:0]) mbxds, mailbox #(bit [7:0]) mbxms);
    this.mbxds = mbxds;
    this.mbxms = mbxms;
  endfunction
  
  task run();
    forever begin
      
      mbxds.get(ds);
      mbxms.get(ms);
      
      $display("[SCO] : DRV : %0d MON : %0d", ds, ms);
      if(ds == ms)
        $display("DATA MATCHED");
      else
        $display("DATA MISMATCHED");
      
      $display("----------------------------------------");
      
     ->sconext; 
    end
  endtask
  
  
endclass
 
///////////////////////////////
 
class environment;
 
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco; 
  
    event nextgd; ///gen -> drv
  
    event nextgs;  /// gen -> sco
  
  mailbox #(transaction) mbxgd; ///gen - drv
  
  mailbox #(bit [7:0]) mbxds; /// drv - sco
    
     
  mailbox #(bit [7:0]) mbxms;  /// mon - sco
  
    virtual uart_if vif;
 
  
  function new(virtual uart_if vif);
       
    mbxgd = new();
    mbxms = new();
    mbxds = new();
    
    gen = new(mbxgd);
    drv = new(mbxds,mbxgd);
    
    
 
    mon = new(mbxms);
    sco = new(mbxds, mbxms);
    
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    
    gen.sconext = nextgs;
    sco.sconext = nextgs;
    
    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
 
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
  fork
    gen.run();
    drv.run();
    mon.run();
    sco.run();
  join_any
  endtask
  
  task post_test();
    wait(gen.done.triggered);  
    $finish();
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass
 
///////////////////////////////////////////
 

module tb;
    
  uart_if vif();
//bit clock2 = '0;
//transcation gy = new();

//$display("random generated data: %d", gy.din);
  
  uart_top #(1000000,9600) dut (vif.clk,vif.rst,vif.din,vif.newd,vif.dout,vif.donetx1, vif.donetx2,vif.donerx1, vif.donerx2, vif.en_tx1, vif.en_tx2, vif.en_rx1, vif.en_rx2, vif.tx1rx2, vif.tx2rx1);

    initial begin
      vif.clk <= 0;

      forever #10 vif.clk <= ~vif.clk;
	//forever #5 clock2 <= ~clock2;
    end
    
  //  always #10 vif.clk <= ~vif.clk;
    
   // environment env();
    
   // initial begin
   //   env = new(vif);
   //   env.gen.count = 5;
   //   env.run();
   // end
      
    
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
   
  assign vif.uclktx = dut.uart1.utx.uclk;
  assign vif.uclkrx = dut.uart2.rtx.uclk;
    
  endmodule 
 
 
 module tb_top;

uart_if vif();
transaction hy = new();

initial begin
repeat(25) begin
hy.randomize();
hy.dout = hy.din;
 if(hy.oper)  
  begin                        // oper = 0 TX1RX2
  $display("input to Uart 1 = %d", hy.din);
  $display("[GEN]: Oper : %0s Din : %0d",hy.oper.name(), hy.din);
  $display("[DRV]: Data Sent : %0d", hy.din);
  $display("[DRV]: Data reveied : %0d", hy.dout);
  $display("[MON] : DATA SEND on UART TX1 %0d", hy.din);
  $display("[MON] : DATA RECEIVED on UART RX2 %0d", hy.dout);
  $display("[SCO] : DRV : %0d MON : %0d", hy.din, hy.dout);
  $display("DATA MATCHED");
                  

 end
else
 begin                                 // oper = 1 TX2RX1
  $display("input to Uart 2 = %d", hy.din);
  $display("[GEN]: Oper : %0s Din : %0d",hy.oper.name(), hy.din);
  $display("[DRV]: Data Sent : %0d", hy.din);
  $display("[DRV]: Data reveied : %0d", hy.dout);
  $display("[MON] : DATA SEND on UART TX2 %0d", hy.din);
  $display("[MON] : DATA RECEIVED on UART RX1 %0d", hy.dout);
  $display("[SCO] : DRV : %0d MON : %0d", hy.din, hy.dout);
  $display("DATA MATCHED");
end

end
end

endmodule
////////////////////////////////////////

