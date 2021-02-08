----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Receiver.  This receiver is able to
-- receive 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When receive is complete o_rx_dv will be
-- driven high for one clock cycle.
--
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.vhpi_access.all;

entity uart_receiver is
  generic (
    g_CLKS_PER_BIT : integer
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end uart_receiver;


architecture rtl of uart_receiver is

  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                     s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;

  signal r_b :std_logic_vector(31 downto 0) :=(others=>'1');
  signal r_RX_Byte   : std_logic_vector(7 downto 0)        := (others => '0');
  signal r_RX_DV     : std_logic                           := '0';

begin



  -- Purpose: Control RX state machine
  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      case r_SM_Main is

        when s_Idle =>
          r_RX_DV     <= '0';
            r_SM_Main <= s_RX_Start_Bit;



        -- Check middle of start bit to make sure it's still low
        when s_RX_Start_Bit =>
              r_SM_Main   <= s_RX_Data_Bits;


        -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
        when s_RX_Data_Bits =>
        report"x";
              r_SM_Main   <= s_RX_Stop_Bit;
	       r_b<=std_logic_vector(to_unsigned(receive_byte,32));


        -- Receive Stop bit.  Stop bit = 1
        when s_RX_Stop_Bit =>
	    if r_b(8)='0' then
	    r_RX_Byte <= r_b(7 downto 0);
            r_RX_DV     <= '1';
            r_SM_Main   <= s_Cleanup;
            else
	    r_b<=std_logic_vector(to_unsigned(receive_byte,32));
            end if;


        -- Stay here 1 clock
        when s_Cleanup =>
          r_SM_Main <= s_Idle;
          r_RX_DV   <= '0';


        when others =>
          r_SM_Main <= s_Idle;

      end case;
    end if;
  end process p_UART_RX;

  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;

end rtl;
