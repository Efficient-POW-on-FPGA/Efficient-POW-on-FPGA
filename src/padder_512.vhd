library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity padder_512 is
  port(
    clk                 : in    std_logic;
    pre_hash            : in    std_logic_vector(255 downto 0);
    enable_hashing      : in    std_logic;
    extending_ready     : in    std_logic;
    reset               : in    std_logic;
    padded_message      : out   std_logic_vector(511 downto 0);
    enable_extending    : out   std_logic;
    padding_ready       : out   std_logic
  );
end padder_512;

architecture arch of padder_512 is

  signal ready_internal : std_logic := '1';
  signal enable_extending_internal : std_logic := '0';
  signal extending_ready_internal : std_logic := '0';


begin
  -- The padded message is the original message (256 bit) + a 1 bit
  padded_message(511 downto 255) <= pre_hash & '1';
  -- + 191 0 bits + the 64 bit length (which is always 0b100000000
  -- prefixed by 0s, so we only need to fill the last 9 bit)
  padded_message(254 downto 9) <= (others => '0');
  padded_message(8 downto 0) <= "100000000";

  padding_ready <= ready_internal;
  enable_extending <= enable_extending_internal;

  process(clk, reset)
  begin
    -- Async reset
    if(reset = '1') then
      --padded_message <= (others => '0');
      ready_internal <= '1';
      enable_extending_internal <= '0';
    
      -- No need for two ready signals here, as data is always available straight away
    elsif (rising_edge(clk)) then
        -- "If master_enable_me, ready_self = 0 UNLESS I and all subcomponents are already ready"
        if (extending_ready = '1' and enable_hashing = '1' and enable_extending_internal = '0') then
          ready_internal <= '0';
          enable_extending_internal <= '1';

        -- "If ready_self = 1 and child ready = 1, set ready to 1"
        elsif (extending_ready = '1' and enable_extending_internal = '0') then
          ready_internal <= '1';
        -- "Leave child_extending = 1 on for one full clk cycle"

        elsif(enable_extending_internal = '1')  then
          enable_extending_internal <= '0';  
        end if;

    end if;
    
  end process;

end architecture;
