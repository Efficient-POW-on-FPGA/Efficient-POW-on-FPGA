-- testbench for extender

-- this testbench loads a padded_chunk input from an extender_input.txt file
-- (please make sure that the binary string in this file is exactly 512 bits
-- long, perhabs leading zeros are necessary)
-- and prints the outputs in an extender_output.csv file

-- the extender outputs are automatically compared to an extender_output_expected.csv file

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity extender_tb is
end entity;

architecture v1 of extender_tb is
  component extender
    port(
      clk                 : in    std_logic;
      padded_chunk        : in    std_logic_vector(511 downto 0);
      extending_enable    : in    std_logic;
      reset               : in    std_logic;
      compressor_1        : out   unsigned(31 downto 0);
      compressor_2        : out   unsigned(31 downto 0);
      compression_chunk_is_new : out std_logic := '0';
      compression_wk_is_new  : out   std_logic := '0';
      compression_wk_is_last  : out   std_logic := '0';
      extending_ready     : out   std_logic := '0'
    );
  end component;

  -- testbench state
  signal failed : std_logic := '0';

  signal clk, extending_enable, reset, compression_chunk_is_new, compression_wk_is_new, compression_wk_is_last, extending_ready : std_logic;
  signal padded_chunk : std_logic_vector(511 downto 0);
  signal compressor_1, compressor_2 : unsigned(31 downto 0);

  -- loop variable for clock with 100 simulated cycles
  constant num_of_clocks : integer := 50;
  signal i : integer := 0;

  file input_buffer : text;
  file expected_buffer : text;
  file output_buffer : text;

begin

  extender_comp : extender port map(clk => clk, padded_chunk => padded_chunk, extending_enable => extending_enable, reset => reset, compressor_1 => compressor_1, compressor_2 => compressor_2, compression_chunk_is_new => compression_chunk_is_new, compression_wk_is_new => compression_wk_is_new, compression_wk_is_last => compression_wk_is_last, extending_ready => extending_ready);

  -- continuous clock
  process
    -- read line(s) from input_buffer
    variable input_buffer_line : line;
    -- read 512 bits from file
    variable padder_bits : std_logic_vector(511 downto 0);
  begin

    file_open(input_buffer, "../sim/io_files/extender_input.txt", read_mode);
    readline(input_buffer, input_buffer_line);
    read(input_buffer_line, padder_bits);

    file_close(input_buffer);
    
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    padded_chunk <= padder_bits;

    -- store in file if clock cycles finished
    if (i = num_of_clocks) then
      if failed = '0' then
        report "All tests of extender tb passed successfully!" severity note;
      else
        report "Extender testbench finished with errors!" severity failure;
      end if;
      file_close(expected_buffer);
      file_close(output_buffer);
      wait;
    else
      i <= i + 1;
    end if;
  end process;

  file_open(output_buffer, "../sim/io_files/extender_output.csv", write_mode);
  file_open(expected_buffer, "../sim/io_files/extender_output_expected.csv", read_mode);

  process(clk)
    variable write_col_to_output_buf : line;
    variable expected_output_buf_line : line;

    variable expected_output, output_str : string(1 to 128);

    variable tmp : integer;
    variable c : integer;

    variable match : std_logic;
  begin
    if(clk'event and clk='1') then
      -- comment below 'if statement' to avoid header in saved file
      if (i = 0) then 
        write(write_col_to_output_buf, string'("compressor_1, compressor_2, compression_chunk_is_new, compression_wk_is_new, compression_wk_is_last, extending_ready"));
        writeline(output_buffer, write_col_to_output_buf);

        -- read first line
        readline(expected_buffer, expected_output_buf_line);
      end if;

      -- print extender outputs for easier debugging
      if compression_wk_is_new = '1' then
        -- if statement needed to reduce assertion warnings of compressor_1 and compressor_2
        write(write_col_to_output_buf, to_integer(signed(std_logic_vector(compressor_1))));
        write(write_col_to_output_buf, string'(","));
        write(write_col_to_output_buf, to_integer(signed(std_logic_vector(compressor_2))));
        write(write_col_to_output_buf, string'(","));
      else 
        write(write_col_to_output_buf, string'("0,0,"));
      end if;
      write(write_col_to_output_buf, compression_chunk_is_new);
      write(write_col_to_output_buf, string'(","));
      write(write_col_to_output_buf, compression_wk_is_new);
      write(write_col_to_output_buf, string'(","));
      write(write_col_to_output_buf, compression_wk_is_last);
      write(write_col_to_output_buf, string'(","));
      write(write_col_to_output_buf, extending_ready);
      writeline(output_buffer, write_col_to_output_buf);

      c := 1;

      expected_output := (others => '0');
      output_str := (others => '0');

      -- build a string with the actual extender output in the same format as the expected output
      if i >= 12 then
        -- if statement needed because compressor_1 and compressor_2 are undefined in the beginning and would cause assertion warnings
        tmp := to_integer(signed(std_logic_vector(compressor_1)));
        output_str(1 to integer'image(tmp)'length) := integer'image(tmp);
        c := integer'image(tmp)'length + c;
        output_str(c) := ',';
        c := c + 1;

        tmp := to_integer(signed(std_logic_vector(compressor_2)));
        output_str(c to c+integer'image(tmp)'length-1) := integer'image(tmp);
        c := integer'image(tmp)'length + c;
        output_str(c) := ',';
        c := c + 1;
      else
        output_str(1 to 4) := "0,0,";
        c := 5;
      end if;

      if compression_chunk_is_new = '1' then output_str(c) := '1'; else output_str(c) := '0'; end if;
      c := c + 1;
      output_str(c) := ',';
      c := c + 1;

      if compression_wk_is_new = '1' then output_str(c) := '1'; else output_str(c) := '0'; end if;
      c := c + 1;
      output_str(c) := ',';
      c := c + 1;

      if compression_wk_is_last = '1' then output_str(c) := '1'; else output_str(c) := '0'; end if;
      c := c + 1;
      output_str(c) := ',';
      c := c + 1;

      if extending_ready = '1' then output_str(c) := '1'; else output_str(c) := '0'; end if;
      c := c + 1;

      -- test if outputs match expected outputs
      readline(expected_buffer, expected_output_buf_line);
      read(expected_output_buf_line, expected_output(1 to expected_output_buf_line'length));

      match := '1';
      for i in 1 to output_str'length loop
        if output_str(i) /= expected_output(i) then
          match := '0';
        end if;
      end loop;

      if match = '0' then
        report "Extender output didn't match the expected output in line " & integer'image(i) & "! Expected: '" & expected_output & "', but got: '" & output_str & "'!" severity error;
        failed <= '1';
      end if;

      if i = 5 then
        reset <= '1';
      end if;

      if i = 6 then
        reset <= '0';
      end if;

      if i = 10 then
        -- start extender
        extending_enable <= '1';
      end if;

      if i = 11 then
        extending_enable <= '0';
      end if;

    end if;
  end process;

end v1;
