----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Transmitter. This transmitter is able
-- to transmit 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit. When transmit is complete o_TX_Done will be
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

entity uart_transceiver is
  generic
    (
      g_CLKS_PER_BIT : integer
      );
  port
    (
      i_Clk       : in  std_logic;
      i_TX_DV     : in  std_logic;
      i_TX_Byte   : in  std_logic_vector(7 downto 0);
      o_TX_Active : out std_logic;
      o_TX_Serial : out std_logic;
      o_TX_Done   : out std_logic
      );
end uart_transceiver;
architecture RTL of uart_transceiver is

  type t_SM_Main is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits,
                     s_TX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;

  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT - 1 := 0;
  signal r_Bit_Index : integer range 0 to 7                  := 0;  -- 8 Bits Total
  signal r_TX_Data   : std_logic_vector(7 downto 0)          := (others => '0');
  signal r_TX_Done   : std_logic                             := '0';

begin
  p_uart_transceiver : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      case r_SM_Main is

        when s_Idle =>
          r_TX_Done   <= '0';

          if i_TX_DV = '1' then
            o_TX_Active <= '1';
            r_TX_Data   <= i_TX_Byte;
            r_SM_Main   <= s_TX_Start_Bit;
          else
            o_TX_Active <= '0';
            r_SM_Main   <= s_Idle;
          end if;
        -- Send out Start Bit. Start bit = 0
        when s_TX_Start_Bit =>
            r_SM_Main   <= s_TX_Data_Bits;
        -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish
        when s_TX_Data_Bits =>
            report"x";
       	     send_byte(to_integer(unsigned(r_TX_Data)));
              r_SM_Main   <= s_TX_Stop_Bit;
        -- Send out Stop bit. Stop bit = 1
        when s_TX_Stop_Bit =>
            r_SM_Main   <= s_Cleanup;
        -- Stay here 1 clock
        when s_Cleanup =>
          o_TX_Active <= '0';
          r_TX_Done   <= '1';
          r_SM_Main   <= s_Idle;
        when others =>
          r_SM_Main <= s_Idle;

      end case;
    end if;
  end process p_uart_transceiver;

  o_TX_Done <= r_TX_Done;

end RTL;
