library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.com_components.all;
use work.hash_components.all;

entity main is
  generic (
    -- UART baudrate
    g_uart_baud_rate : integer := 115200;
    -- Clock frequency in Hz (important for UART communication)
    g_clock_freq : integer := 100000000
  );
  port (
    sys_clk : in std_logic;
    tx_pin  : out std_logic;
    rx_pin  : in std_logic
  );
end main;

architecture Behavioral of main is

  constant mining_core_count : integer :=16;
  type found_array is array (0 to mining_core_count -1) of std_logic;
  signal found_core_signals : found_array;
  signal found_bus_signals : found_array;

  type nonce_array is array (0 to mining_core_count - 1) of std_logic_vector(31 downto 0);
  signal nonce_core_signals : nonce_array;
  signal nonce_bus_signals : nonce_array;

  constant r_clocks_per_uart_bit : integer := g_clock_freq/g_uart_baud_rate;

  -- Clock 100 Mhz -> 200 Mhz
  component clk_core is
    port (
      clk_in1  : in std_logic;
      clk_out1 : out std_logic;
      clk_out2 : out std_logic
    );
  end component clk_core;

  signal r_clk100 : std_logic := 'U';
  signal r_clk200 : std_logic := 'U';

  --communication with com_controller from nonce_master
  signal r_in_header_fin    : std_logic                      := '0';
  signal r_in_header        : std_logic_vector(639 downto 0) := (others => '0');

  --Nonce_master <-> Mining-Cores
  signal mining_enable : std_logic := '0';
  signal reset         : std_logic := '0';
  signal threshold   : std_logic_vector(31 downto 0)  := (others => '0');

  signal resetCores         : std_logic := '0';
  signal start_nonce  : unsigned(31 downto 0) := x"11111111";

  signal first_buffer_out : std_logic_vector(255 downto 0) ;
  signal first_buffer_in : std_logic_vector(255 downto 0) := x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
  signal first_buffer_ready : std_logic;
  -- Indicates if we're done with the first buffer
  signal first_buffer_done : std_logic;
  signal ready_to_inc_time : std_logic;

  -- Make sure we only reset when the first new header comes in
  signal gaveToCores        : std_logic;

  signal timeStamp : unsigned(31 downto 0) := x"00000000";

begin
  -- Start nonce is the last 32 bits of the header, with inverted endianess as this makes it easier to handle for the generator
  start_nonce(31 downto 24) <= unsigned(r_in_header(7 downto 0));
  start_nonce(23 downto 16) <= unsigned(r_in_header(15 downto 8));
  start_nonce(15 downto 8) <= unsigned(r_in_header(23 downto 16));
  start_nonce(7 downto 0) <= unsigned(r_in_header(31 downto 24));

  process(r_clk100)
  begin

    if rising_edge(r_clk100) then
      if resetCores = '1' then
        resetCores <= '0';
      end if;

      if first_buffer_ready = '1' then
        first_buffer_in <= first_buffer_out;
        first_buffer_done <= '1';
  
        if gaveToCores = '0' then 
          resetCores <= '1';
          gaveToCores <= '1';
        end if;
  
      end if;

      -- Gets triggered when new header arrives
      if reset = '1' and resetCores = '0' then 
        resetCores <= '1';
        gaveToCores <= '0';
        ready_to_inc_time <= '1';
        first_buffer_done <= '0';
        first_buffer_in <= x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
        -- Save the timestamp & switch the endianess so we can increment it later if needed
        timeStamp(7 downto 0)   <=  unsigned(r_in_header(95 downto 88));
        timeStamp(15 downto 8)   <=  unsigned(r_in_header(87 downto 80));
        timeStamp(23 downto 16)   <=  unsigned(r_in_header(79 downto 72));
        timeStamp(31 downto 24)   <=  unsigned(r_in_header(71 downto 64));
      end if;


      -- Handle overflow case for incrementing timestamp
      if start_nonce < (4*mining_core_count) then
        if unsigned(nonce_core_signals(0)) <= (x"ffffffff" - (4*mining_core_count)) and unsigned(nonce_core_signals(0)) >= (x"ffffffff" - (5*mining_core_count)) and first_buffer_done = '1' and ready_to_inc_time = '1' then
          timeStamp <= timeStamp +1;
          ready_to_inc_time <= '0';

        end if;

        if unsigned(nonce_core_signals(0)) < (x"ffffffff" - (5*mining_core_count)) or  unsigned(nonce_core_signals(0)) > (x"ffffffff" - (4*mining_core_count)) then
          ready_to_inc_time <= '1';        
        end if ;

      --Increment if nonce < start_nonce - 4*step. 4 steps because mining core starts at the nonce passed to it from the
      -- generator -2*steps and generator starts at nonce - 2*steps (explanation for this in the components)
      else
        if unsigned(nonce_core_signals(0)) + (5*mining_core_count) >= start_nonce and unsigned(nonce_core_signals(0)) + (4*mining_core_count) < start_nonce and  first_buffer_done = '1' and ready_to_inc_time = '1' then
            timeStamp <= timeStamp +1;
            ready_to_inc_time <= '0';
          end if;
          -- Makes sure we only incremend the timesgtamp once
         if unsigned(nonce_core_signals(0)) > start_nonce then
            ready_to_inc_time <= '1';        
          end if ;

      end if;

    end if;
  end process;

  clk_core_inst : clk_core
  port map(
    clk_in1  => sys_clk,
    clk_out1 => r_clk100,
    clk_out2 => r_clk200
  );

  c_com_controller : com_controller
  generic map(
    g_clks_per_bit => r_clocks_per_uart_bit
  )
  port map(
    i_clk              => r_clk100,
    rx                 => rx_pin,
    tx                 => tx_pin,
    i_found            => found_bus_signals(mining_core_count - 1),
    i_found_nonce      => nonce_bus_signals(mining_core_count - 1),
    o_in_header        => r_in_header,
    o_in_header_fin    => r_in_header_fin
  );

  nonce_master_imp : nonce_master
  port map(
    clk           => r_clk100,
    -- We only need the end of the header before the nonce, as this is where the threshold is encoded
    header_in     => r_in_header(63 downto 32),
    header_enable => r_in_header_fin,
    reset         => reset,
    threshold_out => threshold,
    mining_enable => mining_enable
  );

  -- Generate cores from 1 to mining_core_count - 1, since the
  -- first bus takes in the signals differently
  generate_cores : for I in 1 to mining_core_count - 1 generate
    core: mining_core
      generic map(
        -- Partition potential nonce set for mining_core_count many ranges.
        -- Each core starts counting at I and adds mining_core_count by each step
        modulo_remainder => to_unsigned(I,32), 
        step  => to_unsigned(mining_core_count, 32),
        is_first => '0'
      )
      port map(
        clk           => r_clk100,
        reset         => resetCores,
        -- Pass header without timestamp, threshold & nonce appended, as we pass these seperately already
        header_chunk_one    => r_in_header(639 downto 128),
        header_chunk_two    => r_in_header(127 downto 96), 
        start_nonce   => start_nonce,
        threshold     => threshold,
        timestamp     => timeStamp,
        mining_enable => mining_enable,
        hash_buffer_in   => first_buffer_in,
        hash_buffer_out  => open,
        buffer_ready => open,
        found         => found_core_signals(I),
        nonce_found   => nonce_core_signals(I),
        hash          => open
        --TODO: Remove hash in core
      );
    transfer_bus: bus_comp
    port map(
      found_bus => found_bus_signals(I-1),
      found_comp => found_core_signals(I),
      nonce_bus => nonce_bus_signals(I-1),
      nonce_comp => nonce_core_signals(I),
      nonce_out => nonce_bus_signals(I),
      found_out => found_bus_signals(I)
    );
  end generate;


  -- First bus and mining_core, as the bus here needs to take in the core twice
  -- and doing it like this is more readable than making the generate statement more complicated
  bus_0 : bus_comp
  port map(
    found_bus => found_core_signals(0),
    found_comp => found_core_signals(0),
    nonce_bus => nonce_core_signals(0),
    nonce_comp => nonce_core_signals(0),
    nonce_out => nonce_bus_signals(0),
    found_out => found_bus_signals(0)
  );

  mining_core_0 : mining_core
  generic map(
    modulo_remainder => x"00000000",
    step  => to_unsigned(mining_core_count, 32),
    is_first => '1'
  )
  port map(
    clk           => r_clk100,
    reset         => reset,
    -- Pass header without timestamp, threshold & nonce appended, as we pass these seperately already
    header_chunk_one    => r_in_header(639 downto 128),
    header_chunk_two    => r_in_header(127 downto 96), 
    start_nonce   => start_nonce,
    threshold     => threshold,
    timestamp     => timeStamp,
    mining_enable => mining_enable,
    hash_buffer_in   => first_buffer_in,
    hash_buffer_out  => first_buffer_out,
    buffer_ready => first_buffer_ready,
    found         => found_core_signals(0),
    nonce_found   => nonce_core_signals(0),
    hash          => open
  );

end Behavioral;
