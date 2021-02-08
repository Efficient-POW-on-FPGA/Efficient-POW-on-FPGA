library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity extender is
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
end extender;

architecture arch of extender is
  -- create message schedule array with 16 entries of 32-bit words
  -- the message array is split in two arrays so that only one write operation occurs per clock cycle (and it is used as distributed RAM)
  -- even indexes are stored in msg_array and odd ones in msg_array_odd
  type message_array is array(0 to 7) of unsigned(31 downto 0);
  signal msg_array, msg_array_odd : message_array;
  -- save current array (writing) index
  signal extending_enable_internal : std_logic := '0';

  type consts is array(0 to 63) of unsigned(31 downto 0);
  constant k : consts := (
    x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
    x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
    x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
    x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
    x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
    x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
    x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
    x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
  );

begin

  --compression_chunk_is_new <= '1' when current_msg = 2 else '0';

  process(clk, reset)
    variable extending_ready_internal : std_logic := '1';
    variable cur_msg_value, cur_msg_value_2: unsigned(31 downto 0);
    variable current_msg : integer range 0 to 63;
    variable current_msg_div : integer range 0 to 31; -- current_msg divided by 2
  begin
    
    if reset='1' then
      -- async reset
      --current_msg := 0;
      extending_ready <= '1';
      extending_ready_internal := '1';
      extending_enable_internal <= '0';
      compression_wk_is_new <= '0';
      
    else
      if rising_edge(clk) then

        if extending_enable = '1' then
          -- process a new message chunk
          extending_ready_internal := '0';
          current_msg := 0;
        end if;

        current_msg_div := to_integer(to_unsigned(current_msg, 6) srl 1);

        if current_msg < 16 then
          cur_msg_value := unsigned(padded_chunk(511-current_msg*32 downto 480-current_msg*32));
          cur_msg_value_2 := unsigned(padded_chunk(479-current_msg*32 downto 448-current_msg*32));
        else
          
          cur_msg_value := msg_array(current_msg_div mod 8)
                  + (rotate_right(msg_array_odd((current_msg_div) mod 8), 7) 
                      xor rotate_right(msg_array_odd((current_msg_div) mod 8), 18) 
                      xor shift_right(msg_array_odd((current_msg_div) mod 8), 3))
                  + msg_array_odd((current_msg_div-4) mod 8)
                  + (rotate_right(msg_array((current_msg_div-1) mod 8), 17) 
                      xor rotate_right(msg_array((current_msg_div-1) mod 8), 19) 
                      xor shift_right(msg_array((current_msg_div-1) mod 8), 10));

          cur_msg_value_2 := msg_array_odd((current_msg_div-8) mod 8)
                  + (rotate_right(msg_array((current_msg_div-7) mod 8), 7) 
                    xor rotate_right(msg_array((current_msg_div-7) mod 8), 18) 
                    xor shift_right(msg_array((current_msg_div-7) mod 8), 3))
                  + msg_array((current_msg_div-3) mod 8)
                  + (rotate_right(msg_array_odd((current_msg_div-1) mod 8), 17) 
                    xor rotate_right(msg_array_odd((current_msg_div-1) mod 8), 19) 
                    xor shift_right(msg_array_odd((current_msg_div-1) mod 8), 10));

        end if;

        -- write cur_msg_values in message schedule array
        msg_array(current_msg_div mod 8) <= cur_msg_value;
        msg_array_odd(current_msg_div mod 8) <= cur_msg_value_2;
        
        extending_enable_internal <= extending_enable;

        
        --send msg_array(current_msg)
        if extending_ready_internal='0' or current_msg /= 0 then

          -- send next 32bit word to compressor
          compression_wk_is_new <= '1';

          -- transfer next extended word to compressor
          compressor_1 <= cur_msg_value + k(current_msg);
          compressor_2 <= cur_msg_value_2 + k(current_msg+1);

          if current_msg = 0 then
            compression_chunk_is_new <= '1';
          else
            compression_chunk_is_new <= '0';
          end if;

          if current_msg = 60 then
            extending_ready_internal := '1';
          end if;
          
          if current_msg < 62 then
            current_msg := current_msg + 2;
            compression_wk_is_last <= '0';
          else
            compression_wk_is_last <= '1';
            current_msg := 0;
          end if;


        else
          compression_wk_is_new <= '0';
        end if;

        extending_ready <= extending_ready_internal;
        
      end if;
      
    end if;
  end process;

end architecture;

