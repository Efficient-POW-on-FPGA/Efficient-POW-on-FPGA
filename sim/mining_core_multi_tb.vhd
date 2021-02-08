library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity mining_core_multi_tb is
end entity;

architecture v1 of mining_core_multi_tb is
    component mining_core
    generic (
      modulo_remainder : unsigned(31 downto 0) := x"00000000";
      step  : unsigned(31 downto 0) := x"00000001";
      is_first : std_logic := '1'
      );
    port (

        clk              : in std_logic;
        reset            : in std_logic;
        header_chunk_one : in    std_logic_vector(511 downto 0);
        header_chunk_two : in    std_logic_vector(31 downto 0);
        start_nonce      : in unsigned(31 downto 0);
        threshold        : in std_logic_vector(31 downto 0);
        timestamp        : in unsigned(31 downto 0);
        mining_enable    : in std_logic;
        hash_buffer_in   : in std_logic_vector(255 downto 0);
        hash_buffer_out  : out std_logic_vector(255 downto 0); -- only used if is_first
        buffer_ready     : out std_logic := '0'; -- only used if is_first
        found            : out std_logic := '0';
        nonce_found      : out std_logic_vector(31 downto 0);
        hash             : out std_logic_vector(255 downto 0)
    );    
    end component;

    constant max_cycles_per_hash : integer := 400;

    type test_value is record
        header: std_logic_vector(543 downto 0);
        threshold: std_logic_vector(31 downto 0);
        timestamp: unsigned(31 downto 0);
        nonce: std_logic_vector(31 downto 0);
    end record;

    type test_value_array is array (natural range <>) of test_value;


    constant test_values : test_value_array := (
        (x"02000000e18d2da1f7a2bf490d0c803ebfeb03dd2bfb1dfa6a86b31b00000000000000005e590801733042d6c3f5f264693d068bdfbebe23bc6c7c7c813264ba18cf2252",x"73691f18",x"f3ea3f54", x"d0d3e084"),
        (x"010000203625377fee33eddd595c7b69a5efbe4e024f2f5ac16b0d0400000000000000006ecdf76a7a254772c16f97429bef13cf112e034343e74e3eb481abc169d202bf",x"36840518",x"e7f74557", x"2a9d79c9"),
        (x"010000002125ad51135909c5296ac9bd845902adf8921a74710828f82059000000000000cd45ee8754cdc80f9995c8c87c5c9a542f3fa5cf67cd57af3da6a32157484763",x"2a8b091b",x"6d67ee4c",x"f90ee492")
    );

    signal clk, found : std_logic;
    signal done : boolean := false;
    signal reset : std_logic := '1';
    signal mining_enable : std_logic := '0';
    signal header : std_logic_vector(543 downto 0) := test_values(0).header;
    signal start_nonce : unsigned(31 downto 0) := unsigned(test_values(0).nonce);
    signal threshold, threshold_big_endian : std_logic_vector(31 downto 0) := test_values(0).threshold;
    signal timestamp, timestamp_big_endian : unsigned(31 downto 0) := unsigned(test_values(0).timestamp);
    signal nonce_found : std_logic_vector(31 downto 0);
    signal hash : std_logic_vector(255 downto 0);
    signal first_buffer_out : std_logic_vector(255 downto 0);
    signal first_buffer_in : std_logic_vector(255 downto 0) := x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
    signal first_buffer_ready : std_logic;

    -- number of clocks after which simulation ends (at the latest)
    signal n, i, wait_counter : integer := 0;

begin

    mining_core_component : mining_core port map(
        clk => clk,
        reset => reset,
        header_chunk_one    => header(543 downto 32),
        header_chunk_two    => header(31 downto 0), 
        start_nonce => start_nonce,
        threshold => threshold_big_endian,
        timestamp => timestamp_big_endian,
        mining_enable => mining_enable,
        hash_buffer_in => first_buffer_in,
        hash_buffer_out => first_buffer_out, 
        buffer_ready => first_buffer_ready,
        found => found,
        nonce_found => nonce_found,
        hash => hash
    );

    -- Comparator expects the threshhold, timestamp in big endian, therefore we convert it
    threshold_big_endian <= threshold(7 downto 0) & threshold(15 downto 8) & threshold(23 downto 16) & threshold(31 downto 24);
    timestamp_big_endian <= timestamp(7 downto 0) & timestamp(15 downto 8) & timestamp(23 downto 16) & timestamp(31 downto 24);
    process
    begin

        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;

        if n = max_cycles_per_hash * (test_values'length) then
            report integer'IMAGE(n) severity note;
            report "##### FAILED Test Mining Core Multiple! Time out! #####" severity failure;
            wait;
        else
            n <= n + 1;
        end if;

        if done then
            wait;
        end if;

    end process;

    process(clk, first_buffer_ready)
    begin

        if first_buffer_ready = '1' then
            first_buffer_in <= first_buffer_out;
          end if;
      
        if rising_edge(clk) then
            
            -- Reset and start core
            if reset = '1' then
                report "Reset";
                reset <= '0';
                mining_enable <= '1';
            end if;

            if mining_enable = '1' then
                report "Enabled";
                mining_enable <= '0';
            end if;

            if found = '1' then
                if nonce_found = test_values(i).nonce then
                    if wait_counter = 0 then
                        report "Found nonce for " & integer'image(i + 1) & ". header." severity note;
                    end if;

                    -- Stop if all headers are used
                    if i >= test_values'length - 1 then
                        done <= true;
                    end if;
                    
                    -- We wait here for some cycles, because on the FPGA some time is needed to send the data over uart.
                    if wait_counter = 100 then
                        wait_counter <= 0;

                        header <= test_values(i+1).header;
                        start_nonce  <= unsigned(test_values(i+1).nonce);
                        timestamp    <= test_values(i+1).timestamp;
                        threshold <= test_values(i+1).threshold;
                        first_buffer_in <= x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";

                        reset <= '1';
                        i <= i + 1;
                    else
                        wait_counter <= wait_counter + 1;
                    end if;
                    
                else
                    report "##### FAILED Test Mining Core Multiple: Nonce not correct for " & integer'image(i + 1) & ". header! #####" severity failure;
                end if;
            end if;

        end if;
    end process;
    end v1;
