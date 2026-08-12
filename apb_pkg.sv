package apb_pkg;

class transaction;

  rand bit write;
  rand bit [7:0] addr;
  rand bit [31:0] data;

  bit [31:0] rdata;
  bit pslverr;

endclass


class generator;

  mailbox gen2drv;

  function new(mailbox gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();

    transaction tr;
    bit [7:0] addr;

    repeat(1000)
    begin

      addr = $urandom_range(0,255);

      tr = new();
      tr.write = 1;
      tr.addr = addr;

      if($urandom_range(0,2) == 0)
      begin
        tr.data = $urandom_range(1,16'hFFFF);
      end
      else
      begin
        tr.data = $urandom;
      end

      $display(
        "[GEN] WRITE ADDR=%0d DATA=%h",
        tr.addr,
        tr.data
      );

      gen2drv.put(tr);

      tr = new();
      tr.write = 0;
      tr.addr = addr;
      tr.data = 0;

      $display(
        "[GEN] READ ADDR=%0d",
        tr.addr
      );

      gen2drv.put(tr);

    end

  endtask

endclass


class driver;

  virtual apb_if vif;
  mailbox gen2drv;

  function new(
    virtual apb_if vif,
    mailbox gen2drv
  );

    this.vif = vif;
    this.gen2drv = gen2drv;

  endfunction

  task run();

    transaction tr;

    forever
    begin

      gen2drv.get(tr);

      @(posedge vif.PCLK);

      vif.PSEL <= 1;
      vif.PENABLE <= 0;
      vif.PWRITE <= tr.write;
      vif.PADDR <= tr.addr;
      vif.PWDATA <= tr.data;

      @(posedge vif.PCLK);

      vif.PENABLE <= 1;

      @(posedge vif.PCLK);
      #1;

      if(!tr.write)
        tr.rdata = vif.PRDATA;

      vif.PSEL <= 0;
      vif.PENABLE <= 0;

      $display("[DRV] Transaction Done");

    end

  endtask

endclass


class apb_coverage;

  bit cov_write;
  bit [7:0] cov_addr;
  bit [31:0] cov_data;
  bit cov_pready;
  bit cov_pslverr;

  covergroup cg;

    option.at_least = 10;

    pwrite_cp : coverpoint cov_write
    {
      bins read_transaction = {0};
      bins write_transaction = {1};
    }

    addr_cp : coverpoint cov_addr
    {
      bins low_range = {[0:63]};
      bins middle_range = {[64:127]};
      bins high_range = {[128:191]};
      bins upper_range = {[192:255]};
    }

    data_cp : coverpoint cov_data
    {
      bins zero_data = {32'h00000000};
      bins small_data = {[32'h00000001:32'h0000FFFF]};
      bins other_data = default;
    }

    pready_cp : coverpoint cov_pready
    {
      bins wait_state = {0};
      bins ready = {1};
    }

    pslverr_cp : coverpoint cov_pslverr
    {
      bins no_error = {0};
      bins error = {1};
    }

    pwrite_addr_cross :
      cross pwrite_cp, addr_cp;

    pwrite_pready_cross :
      cross pwrite_cp, pready_cp;

    addr_pready_cross :
      cross addr_cp, pready_cp;

    pwrite_pslverr_cross :
      cross pwrite_cp, pslverr_cp;

  endgroup


  function new();
    cg = new();
  endfunction


  function void sample(
    input bit write,
    input bit [7:0] addr,
    input bit [31:0] data,
    input bit pready,
    input bit pslverr
  );

    cov_write = write;
    cov_addr = addr;
    cov_data = data;
    cov_pready = pready;
    cov_pslverr = pslverr;

    cg.sample();

  endfunction

endclass


class monitor;

  virtual apb_if vif;
  mailbox mon2scb;
  apb_coverage cov;

  function new(
    virtual apb_if vif,
    mailbox mon2scb
  );

    this.vif = vif;
    this.mon2scb = mon2scb;
    cov = new();

  endfunction


  task run();

    transaction tr;

    forever
    begin

      @(posedge vif.PCLK);
      #1;

      if(vif.PSEL && vif.PENABLE)
      begin

        tr = new();

        tr.write = vif.PWRITE;
        tr.addr = vif.PADDR;
        tr.data = vif.PWDATA;
        tr.rdata = vif.PRDATA;
        tr.pslverr = vif.PSLVERR;

        cov.sample(
          tr.write,
          tr.addr,
          tr.data,
          vif.PREADY,
          vif.PSLVERR
        );

        if(vif.PREADY)
          mon2scb.put(tr);

        $display(
          "[MON] WRITE=%0d ADDR=%0d DATA=%h RDATA=%h PREADY=%0d PSLVERR=%0d",
          tr.write,
          tr.addr,
          tr.data,
          tr.rdata,
          vif.PREADY,
          vif.PSLVERR
        );

        $display(
          "[COV] Sampled WRITE=%0d ADDR=%0d DATA=%h PREADY=%0d PSLVERR=%0d",
          tr.write,
          tr.addr,
          tr.data,
          vif.PREADY,
          vif.PSLVERR
        );

      end

    end

  endtask

endclass


class scoreboard;

  mailbox mon2scb;
  logic [31:0] model_mem [0:255];

  function new(mailbox mon2scb);

    int i;

    this.mon2scb = mon2scb;

    for(i=0;i<256;i++)
      model_mem[i] = 32'd0;

  endfunction


  task run();

    transaction tr;

    forever
    begin

      mon2scb.get(tr);

      if(tr.pslverr)
      begin

        if(tr.addr == 8'hFF)
        begin

          $display("------------------------------");
          $display("ERROR RESPONSE PASS");
          $display("ADDR = %0d", tr.addr);
          $display("PSLVERR = %0d", tr.pslverr);
          $display("------------------------------");

        end
        else
        begin

          $display("------------------------------");
          $display("ERROR RESPONSE FAIL");
          $display("ADDR = %0d", tr.addr);
          $display("PSLVERR = %0d", tr.pslverr);
          $display("------------------------------");

        end

      end

      else if(tr.write)
      begin

        model_mem[tr.addr] = tr.data;

        $display("---------------------------");
        $display("WRITE PASS");
        $display("ADDR = %0d", tr.addr);
        $display("DATA = %h", tr.data);
        $display("---------------------------");

      end

      else
      begin

        if(model_mem[tr.addr] == tr.rdata)
        begin

          $display("------------------------------");
          $display("READ PASS");
          $display("ADDR = %0d", tr.addr);
          $display("EXPECTED = %h", model_mem[tr.addr]);
          $display("GOT = %h", tr.rdata);
          $display("------------------------------");

        end
        else
        begin

          $display("------------------------------");
          $display("READ FAIL");
          $display("ADDR = %0d", tr.addr);
          $display("EXPECTED = %h", model_mem[tr.addr]);
          $display("GOT = %h", tr.rdata);
          $display("------------------------------");

        end

      end

    end

  endtask

endclass


class environment;

  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;

  mailbox gen2drv;
  mailbox mon2scb;

  function new(virtual apb_if vif);

    gen2drv = new();
    mon2scb = new();

    gen = new(gen2drv);
    drv = new(vif,gen2drv);
    mon = new(vif,mon2scb);
    scb = new(mon2scb);

  endfunction


  task run();

    fork

      gen.run();
      drv.run();
      mon.run();
      scb.run();

    join_none

  endtask

endclass


class test;

  environment env;

  function new(virtual apb_if vif);
    env = new(vif);
  endfunction

  task run();
    env.run();
  endtask

endclass

endpackage
