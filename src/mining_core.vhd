library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity mining_core is
  generic (
    modulo_remainder: unsigned(31 downto 0);
    step  : unsigned(31 downto 0);
    is_first : std_logic
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
end mining_core;

architecture v1 of mining_core is

  signal hash_buffer_in_internal : std_logic_vector(255 downto 0);
  -- tell vivado not to merge buffers
  attribute dont_touch : string;
  attribute dont_touch of hash_buffer_in_internal : signal is "true";

  -- Mining-Core <-> Generator
  signal generator_ready   : std_logic;
  signal start_inner       : unsigned(31 downto 0);
  -- Set when new header arrives
  signal new_header        : std_logic := '0';

  -- Generator <-> Extender 1
  signal nonce_current  : unsigned(31 downto 0);
  signal extending_enable : std_logic;
  signal padded_chunk     : std_logic_vector(511 downto 0);
  signal extending_ready  : std_logic;

  --Extender 1 <-> Compressor 1

  signal compression_wk_is_new : std_logic;
  signal compression_wk_is_last : std_logic;
  signal compression_chunk_is_new : std_logic;
  signal extended_word_1_1 : unsigned(31 downto 0);
  signal extended_word_1_2 : unsigned(31 downto 0);

  --Compressor 1 <-> Padder-512

  signal padding_enable_2 : std_logic := '0';
  signal pre_hash_value   : std_logic_vector(255 downto 0);
  signal padding_ready_2  : std_logic;

  --Padder-512 <-> Extender 2

  signal extending_enable_2 : std_logic;
  signal padded_chunk_2     : std_logic_vector(511 downto 0);
  signal extending_ready_2  : std_logic;

  --Extender 2 <-> Compressor 2

  signal compression_wk_is_new_2 : std_logic;
  signal compression_wk_is_last_2 : std_logic;
  signal compression_chunk_is_new_2 : std_logic;
  signal extended_word_2_1 : unsigned(31 downto 0);
  signal extended_word_2_2 : unsigned(31 downto 0);

  --Compressor 2 <-> Comparator
  signal hash_value_compressor : std_logic_vector(255 downto 0);

  --Comparator <-> Mining-Core
  signal comparator_enable: std_logic := '0';
  signal hash_found : std_logic;


  -- Track mining core progress
  signal hash_ready_2     : std_logic := '0'; -- set to 1 when extender 1 is started
  signal hash_ready_1     : std_logic := '0'; -- set to 1 when extender 1 has finished
  signal started_second : std_logic := '0';
  signal comparator_enable_i : std_logic := '0'; -- used to ignore first comparator_enable signal (hash might be wrong due to buffer timing delay)

  -- Global finished signal
  signal done : std_logic := '0';
  signal setBuffer : std_logic := '0';
  signal override  : std_logic := '0';

  signal chunk_one : std_logic_vector(511 downto 0);

begin

  start_inner <= modulo_remainder + start_nonce;
  buffer_ready <= override;
  hash_buffer_out <= pre_hash_value;
  chunk_one <= (others=> 'U') when is_first = '0' else header_chunk_one;

  com_process : process (clk, reset)
  begin
    if reset = '1' then
      found <= '0';
      comparator_enable <= '0';
      comparator_enable_i <= '0';
      done <= '0';
      started_second <= '0';
      setBuffer <= '0';
      override <= '0';
      hash_ready_1 <= '0';
      hash_ready_2 <= '0';

    elsif rising_edge(clk) then

      hash_buffer_in_internal <= hash_buffer_in;

      if (new_header = '1') then
        new_header <= '0';
      end if;

      if override = '1' then  
        setBuffer <= '1';
        override <= '0';
      end if;

      if extending_ready = '0' then
        hash_ready_2 <= '1';
      end if;

      hash_ready_1 <= (hash_ready_2 and extending_ready and not hash_ready_1);

      -- Only override the buffer out the first time
      if is_first = '1' and hash_ready_1 = '1' and setBuffer = '0' then
        -- Override one cycle later
        override <= '1';
      elsif hash_ready_1 = '1' and setBuffer = '1' then
        padding_enable_2 <= '1';         
      end if;

      if is_first = '0' and hash_ready_1 = '1' then
        padding_enable_2 <= '1';         
      end if;

      if padding_enable_2 = '1' then
        padding_enable_2 <= '0';
      end if;

      if(comparator_enable = '1') then 
        comparator_enable <= '0';
      end if;

      if hash_found = '1' then 
        -- current nonce is already two greater than latest nonce of comparator,
        -- so decrease it by two
        nonce_found <= std_logic_vector(nonce_current-step-step);
  
        found <= '1';
        comparator_enable <= '0';
        comparator_enable_i <= '0';
        done <= '1';

      elsif done = '0' or mining_enable = '1' then

        nonce_found <= std_logic_vector(nonce_current-step-step);

        --On mining_enable means a new header is here, so we use new header 
        -- to start the generation 
        if mining_enable = '1' and new_header = '0' then
          comparator_enable <= '0';
          comparator_enable_i <= '0';
          new_header <= '1';
          done <= '0';
          found <= '0';
          started_second <= '0';
        else
          
          new_header <= '0';
        
          if(extending_enable_2 = '1') then
            started_second <= '1';
          end if;

          -- if last compressor has finished (one cycle after extender), enable comparator
          if(extending_enable_2 = '1' and started_second = '1') then 
            if comparator_enable_i = '1' then
              comparator_enable <= '1';
            end if;
            comparator_enable_i <= '1';
          end if;

        end if;

      end if;

    end if;

  end process;

  generator : nonce_generator_and_padder
  generic map(
    step  => step,
    is_first => is_first
  )
  port map(
    clk               => clk,
    header_chunk_one  => chunk_one,
    header_chunk_two  => header_chunk_two, 
    start             => start_inner,
    timestamp         => timestamp,
    threshold         => threshold,
    extending_ready   => extending_ready,
    new_header        => new_header,
    reset_in          => reset,
    padded_message    => padded_chunk,
    enable_extending  => extending_enable,
    nonce             => nonce_current
  );

  extender_1 : extender
  port map(
    clk                => clk,
    padded_chunk       => padded_chunk,
    extending_enable   => extending_enable,
    reset              => reset,
    compressor_1       => extended_word_1_1,
    compressor_2       => extended_word_1_2,
    compression_wk_is_new => compression_wk_is_new,
    compression_wk_is_last => compression_wk_is_last,
    compression_chunk_is_new => compression_chunk_is_new,
    extending_ready    => extending_ready
  );

  compressor_1 : compressor_second_stage
  port map(
    clk    => clk,
    reset      => reset,
    state_init => hash_buffer_in_internal,
    wk_is_new => compression_wk_is_new,
    wk_is_last => compression_wk_is_last,
    chunk_is_new => compression_chunk_is_new,
    wk_1 => extended_word_1_1,
    wk_2 => extended_word_1_2,
    hash   => pre_hash_value
  );

  padder_2 : padder_512
  port map(
    clk              => clk,
    pre_hash         => pre_hash_value,
    enable_hashing   => padding_enable_2,
    extending_ready  => extending_ready_2,
    reset            => reset,
    padded_message   => padded_chunk_2,
    enable_extending => extending_enable_2,
    padding_ready    => padding_ready_2
  );

  extender_2 : extender
  port map(
    clk                => clk,
    padded_chunk       => padded_chunk_2,
    extending_enable   => extending_enable_2,
    reset              => reset,
    compressor_1       => extended_word_2_1,
    compressor_2       => extended_word_2_2,
    compression_wk_is_new => compression_wk_is_new_2,
    compression_wk_is_last => compression_wk_is_last_2,
    compression_chunk_is_new => compression_chunk_is_new_2,
    extending_ready    => extending_ready_2
  );

  compressor_2 : compressor
  port map(
    clk    => clk,
    reset  => reset,
    wk_is_new => compression_wk_is_new_2,
    wk_is_last => compression_wk_is_last_2,
    chunk_is_new => compression_chunk_is_new_2,
    wk_1 => extended_word_2_1,
    wk_2 => extended_word_2_2,
    hash   => hash_value_compressor
  );

  comparator_1 : comparator
  port map(
    clk               => clk,
    reset             => reset,
    target            => threshold,
    hash_value        => hash_value_compressor,
    comparator_enable => comparator_enable,
    hash_out          => hash,
    hash_found        => hash_found
  );

end v1;
