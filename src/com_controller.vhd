library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--used to control the UART-Interface, buffer data and handle the bus communication
entity com_controller is
	generic (
		g_CLKS_PER_BIT : integer
	);
	port (
		i_clk : in std_logic;
		--bare UART signals
		rx : in std_logic;
		tx : out std_logic;

		--signals from mining cores
		i_found       : in std_logic;
		i_found_nonce : in std_logic_vector(31 downto 0);

		--signals to mining cores
		o_in_header     : out std_logic_vector(639 downto 0);
		o_in_header_fin : out std_logic
	);
end com_controller;

architecture arch of com_controller is
	--connect uart logic
	component uart_receiver is
		generic (
			g_CLKS_PER_BIT : integer
		);
		port (
			i_Clk       : in std_logic;
			i_RX_Serial : in std_logic;
			o_RX_DV     : out std_logic;
			o_RX_Byte   : out std_logic_vector(7 downto 0)
		);
	end component;

	component uart_transceiver is
		generic (
			g_CLKS_PER_BIT : integer
		);
		port (
			i_Clk       : in std_logic;
			i_TX_DV     : in std_logic;
			i_TX_Byte   : in std_logic_vector(7 downto 0);
			o_TX_Active : out std_logic;
			o_TX_Serial : out std_logic;
			o_TX_Done   : out std_logic
		);
	end component;

	--type for state machine
	type state is (s_receiving, s_execute_fn,s_end_byte, s_reset);
	signal com_state : state := s_receiving;

	--function identifiers for REG_READ and REG_WRITE
	constant r_func_write_header : std_logic_vector(7 downto 0) := "00000011";
	constant r_func_hash_read    : std_logic_vector(7 downto 0) := "00000100";

	signal r_function          : std_logic_vector(7 downto 0);
	signal r_in_payload_length : std_logic_vector(7 downto 0);

	--signals for handling the UART
	signal r_receive_dv   : std_logic;
	signal r_receive_byte : std_logic_vector(7 downto 0);

	signal r_tranceive_dv     : std_logic;
	signal r_tranceive_byte   : std_logic_vector(7 downto 0);
	signal r_tranceive_active : std_logic;

	signal r_in_header     : std_logic_vector(639 downto 0) := (others => '0');
	signal r_in_header_fin : std_logic                      := '0';

	signal r_out_found : std_logic                      := '0';
	signal r_out_nonce : std_logic_vector(31 downto 0)  := (others => '0');

	signal r_values_read : std_logic := '0';

	--pointers for fifo buffers
	signal r_request_byte_ctr : integer range 0 to 90 := 0;
	signal r_reply_byte_ctr   : integer range 0 to 6 := 0;

	--was every byte of reply payload written to uart
	signal r_everything_written : std_logic := '0';

	--must wait before writing to uart
	signal r_uart_write_wait : std_logic := '0';

begin
	--wire components
	c_com_controller_rx : uart_receiver
	generic map(g_CLKS_PER_BIT => g_CLKS_PER_BIT)
	port map(
		i_CLK       => i_clk,
		i_RX_Serial => rx,
		o_rx_dv     => r_receive_dv,
		o_rx_byte   => r_receive_byte
	);

	c_com_controller_tx : uart_transceiver
	generic map(g_CLKS_PER_BIT => g_CLKS_PER_BIT)
	port map(
		i_Clk       => i_clk,
		i_TX_DV     => r_tranceive_dv,
		i_TX_Byte   => r_tranceive_byte,
		o_TX_Active => r_tranceive_active,
		o_TX_Serial => tx,
		o_TX_Done   => open
	);

	o_in_header     <= r_in_header;
	o_in_header_fin <= r_in_header_fin;

	--receive bytes from uart and buffer them
	p_read_from_uart : process (i_clk)
	begin
		if rising_edge(i_clk) then
			if r_in_header_fin = '1' then
				r_in_header_fin <= '0';
			end if;

			case com_state is

				when s_reset =>
					--Reset control signals
					r_request_byte_ctr <= 0;
					r_reply_byte_ctr   <= 0;
					r_values_read      <= '0';
					r_tranceive_dv     <= '0';
					com_state          <= s_receiving;

				when s_receiving =>
					-- Byte from Uart available
					if r_receive_dv = '1' then

						r_request_byte_ctr <= r_request_byte_ctr + 1;
						
						-- Read in payload length
						if r_request_byte_ctr = 0 then
							r_in_payload_length <= r_receive_byte;

						-- Snd byte (reply length) is a rudiment, but there for backwards compatibility

						-- Read in function id
						elsif r_request_byte_ctr = 2 then
							r_function <= r_receive_byte;

						-- Read in header bytes
						elsif r_request_byte_ctr > 2 then
							r_in_header <= r_in_header(631 downto 0) & r_receive_byte;
						end if;

					end if;
					
					-- Change state when request length reached
					if r_request_byte_ctr > 2 and r_request_byte_ctr = to_integer(unsigned(r_in_payload_length)) + 3 then
						com_state <= s_execute_fn;
					end if;

				when s_execute_fn =>

					case r_function is
					
						-- Send header
						when r_func_write_header =>
							-- Activate Header 
							r_in_header_fin <= '1';

							com_state <= s_end_byte;

						-- Read Hash
						when r_func_hash_read =>
							
							-- Read values from mining-cores before transceiving
							if r_values_read = '0' then
								r_out_nonce   <= i_found_nonce;
								r_out_found   <= i_found;
								r_values_read <= '1';
							else
								
								if (r_uart_write_wait = '1') then
									r_uart_write_wait <= '0';
								end if;

								-- Still bytes of reply left
								if r_tranceive_active = '0' and r_uart_write_wait = '0' and r_reply_byte_ctr < 5 then
									
									--Found byte
									if r_reply_byte_ctr = 0 then
										r_tranceive_byte <= "0000000" & r_out_found;

									-- Nonce
									else
										r_tranceive_byte <= r_out_nonce(31 downto 24);
										r_out_nonce      <= r_out_nonce(23 downto 0) & x"00";
									end if;

									r_tranceive_dv    <= '1';
									r_reply_byte_ctr  <= r_reply_byte_ctr + 1;

									-- Wait for one cylce
									r_uart_write_wait <= '1';
								
								-- Do nothing
								else
									r_tranceive_dv <= '0';
								end if;
								
								-- On end of reply -> send end byte + reset
								if r_reply_byte_ctr = 5 and r_tranceive_active = '0' and r_uart_write_wait = '0' then
									com_state        <= s_end_byte;
								end if;

							end if;

							
							when others =>
						end case;

				when s_end_byte => 
					if r_tranceive_active = '0' and r_uart_write_wait = '0' then
						-- Send end byte
						r_tranceive_byte <= "11000101";
						r_tranceive_dv   <= '1';
						com_state       <= s_reset;
					else
						r_tranceive_dv <= '0';
					end if;
			end case;
		end if;

	end process;

end arch;