library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nonce_generator_and_padder is
  generic(
    step                : unsigned(31 downto 0)  := x"00000001";
    is_first            : std_logic
    );
  port(
    clk                 : in    std_logic;
    header_chunk_one    : in    std_logic_vector(511 downto 0);
    header_chunk_two    : in    std_logic_vector(31 downto 0);
    -- Note: Startnonce, Threshold, and Timestamp are received in big endian, as that makes them easier to work with,
    -- so we switch them internally.
    start               : in    unsigned(31 downto 0)  := x"00000000";
    timestamp           : in    unsigned(31 downto 0)  := x"00000000";
    threshold           : in    std_logic_vector(31 downto 0)  := x"00000000";
    extending_ready     : in    std_logic;
    new_header          : in    std_logic;
    reset_in            : in    std_logic;
    padded_message      : out   std_logic_vector(511 downto 0);
    enable_extending    : out   std_logic;
    nonce               : out   unsigned(31 downto 0)
  );
end nonce_generator_and_padder;


architecture arch of nonce_generator_and_padder is

  -- Since we increment by step immediatly, we start off at start-step
  signal nonce_internal : unsigned(31 downto 0);
  signal enable_extending_internal : std_logic := '0';
  signal reset_internal         : std_logic := '0';

  -- We only need to pass forward the second chunk for each header, as the first chunk is always the same
  -- This bit tracks wether the first chunk has already been processed for a header

  signal generated_first : std_logic := '0';

  -- is current output the first 512 bit chunk?
  signal first_chunk : std_logic;


begin

  -- Since message is always 640 bits, padded is always msg + 1 bit + 373 0 bits +
  -- 640 in binary (1010000000) (10 bits)
  GENERATE_PADDED : if is_first = '0' generate
    padded_message <= header_chunk_two & std_logic_vector(timestamp(7 downto 0)) & 
      std_logic_vector(timestamp(15 downto 8)) & std_logic_vector(timestamp(23 downto 16)) & 
      std_logic_vector(timestamp(31 downto 24)) & std_logic_vector(threshold(7 downto 0)) & 
      std_logic_vector(threshold(15 downto 8)) & std_logic_vector(threshold(23 downto 16)) & 
      std_logic_vector(threshold(31 downto 24)) & std_logic_vector(nonce_internal(7 downto 0)) &
      std_logic_vector(nonce_internal(15 downto 8)) & std_logic_vector(nonce_internal(23 downto 16)) & 
      std_logic_vector(nonce_internal(31 downto 24)) & '1' & (382 downto 10 => '0') & "1010000000";
  end generate;

  GENERATE_PADDED_FIRST : if is_first = '1' generate
    padded_message <= header_chunk_one when generated_first = '0' else header_chunk_two &
    std_logic_vector(timestamp(7 downto 0)) & std_logic_vector(timestamp(15 downto 8)) &
    std_logic_vector(timestamp(23 downto 16)) & std_logic_vector(timestamp(31 downto 24)) &
    std_logic_vector(threshold(7 downto 0)) & std_logic_vector(threshold(15 downto 8)) &
    std_logic_vector(threshold(23 downto 16)) & std_logic_vector(threshold(31 downto 24)) &
    std_logic_vector(nonce_internal(7 downto 0)) & std_logic_vector(nonce_internal(15 downto 8)) & 
    std_logic_vector(nonce_internal(23 downto 16)) & std_logic_vector(nonce_internal(31 downto 24)) &
    '1' & (382 downto 10 => '0') & "1010000000";
  end generate;

  nonce <= nonce_internal;
  enable_extending <= extending_ready and enable_extending_internal;

  process(clk, reset_in)
  begin
    -- Async reset
    if(reset_in = '1') then
      reset_internal <= '1';
      -- Subtracting twice because every core immediately adds step to their nonce_internal and first core skips first nonce 
      -- due to the length extension optimization. Handling it like this is not as clean, but saves logic cells and makes no
      -- difference as each nonce is just as valid for the bitcoin sha-256
      nonce_internal <= start - step - step;
      enable_extending_internal <= '0';
      generated_first <= '0';
      first_chunk <= '1';

    else

    if rising_edge(clk) then

      if(reset_internal = '1') then 
        reset_internal <= '0';

      else 
        -- If new header, we send the first chunk one time (i.e. we set generated first to 0)
        if(new_header = '1') then
          nonce_internal <= start - step - step;
          if is_first = '1' then
            generated_first <= '0';
          else
            generated_first <= '1';
          end if;
          reset_internal <= '1';
          first_chunk <= '1';
        end if;

        -- If enable_generating, we increment our nonce and reset the pipeline but DONT reset generated_first, meaning
        -- we only send the second chunk with the new nonce
        if(extending_ready = '1' and enable_extending_internal = '0') then
          -- After compressor has buffered first part of the hash, set
          -- generated_first to 1
          if first_chunk = '0' and generated_first = '0' then
            generated_first <= '1';
          else
            nonce_internal <= nonce_internal + step;
          end if;

          reset_internal <= '1';
          enable_extending_internal <= '1';


        end if;

        if extending_ready = '0' and enable_extending_internal = '0' then
          first_chunk <= '0';
        end if;
        
      
        if enable_extending_internal = '1'  then
            enable_extending_internal <= '0';
        end if;
          
    end if;
    end if;

    end if;

  end process;

end architecture;
