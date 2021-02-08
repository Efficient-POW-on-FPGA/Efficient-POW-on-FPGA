library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package hash_components is
    type compressor_state is array(0 to 7) of unsigned(31 downto 0);

    component padder_512 is
        port (
            clk              : in std_logic;
            pre_hash         : in std_logic_vector(255 downto 0);
            enable_hashing   : in std_logic;
            extending_ready  : in std_logic;
            reset            : in std_logic;
            padded_message   : out std_logic_vector(511 downto 0);
            enable_extending : out std_logic;
            padding_ready    : out std_logic
        );
    end component;

    component extender is
        port (
            clk                : in std_logic;
            padded_chunk       : in std_logic_vector(511 downto 0);
            extending_enable   : in std_logic;
            reset              : in std_logic;
            compressor_1        : out   unsigned(31 downto 0);
            compressor_2        : out   unsigned(31 downto 0);
            compression_chunk_is_new : out std_logic;
            compression_wk_is_new : out std_logic;
            compression_wk_is_last : out std_logic;
            extending_ready    : out std_logic
        );
    end component;

    component compressor is
        port (
            clk    : in std_logic;
            reset  : in std_logic;
            wk_is_new : in std_logic;
            wk_is_last : in std_logic;
            chunk_is_new : in std_logic;
            wk_1        : in   unsigned(31 downto 0);
            wk_2        : in   unsigned(31 downto 0);
            hash   : out std_logic_vector(255 downto 0)
        );
    end component;

    component compressor_second_stage is
        port (
            clk    : in std_logic;
            reset  : in std_logic;
            state_init : in std_logic_vector(255 downto 0);
            wk_is_new : in std_logic;
            wk_is_last : in std_logic;
            chunk_is_new : in std_logic;
            wk_1        : in   unsigned(31 downto 0);
            wk_2        : in   unsigned(31 downto 0);
            hash   : out std_logic_vector(255 downto 0)
        );
    end component;

    component nonce_generator_and_padder is
        generic (
            step        : unsigned(31 downto 0);
            is_first    : std_logic
        );
        port (
        clk                 : in    std_logic;
        header_chunk_one    : in    std_logic_vector(511 downto 0);
        header_chunk_two    : in    std_logic_vector(31 downto 0);
        start               : in    unsigned(31 downto 0)  := x"00000000";
        -- Note: Threshold and Timestamp are received in big endian, so we switch them internally
        timestamp           : in    unsigned(31 downto 0)  := x"00000000";
        threshold           : in    std_logic_vector(31 downto 0)  := x"00000000";
        extending_ready     : in    std_logic;
        new_header          : in    std_logic;
        reset_in            : in    std_logic;
        padded_message      : out   std_logic_vector(511 downto 0);
        enable_extending    : out   std_logic;
        nonce               : out   unsigned(31 downto 0)
                );
    end component;

    component comparator is
        port (
            clk               : in std_logic;
            reset             : in std_logic;
            target            : in std_logic_vector(31 downto 0);
            hash_value        : in std_logic_vector(255 downto 0);
            comparator_enable : in std_logic;
            hash_out          : out std_logic_vector(255 downto 0);
            hash_found        : out std_logic
        );
    end component;

    component mining_core is
        generic (
            modulo_remainder: unsigned(31 downto 0);
            step : unsigned(31 downto 0);
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
    end component;

    component nonce_master is
      port(
        clk                 : in    std_logic;
        -- We only need the end of the header, as this is where the threshold is encoded
        header_in           : in    std_logic_vector(31 downto 0);
        header_enable       : in    std_logic;
        reset               : out   std_logic;
        threshold_out       : out   std_logic_vector(31 downto 0);
        mining_enable       : out   std_logic
        );
    end component;

    component bus_comp is
      port(
        -- Found signal propagated through by other buses
        found_bus           : in    std_logic;
        -- Found signal passed by the belonging comparator
        found_comp          : in    std_logic;
        -- Nonce from previous bus
        nonce_bus           : in    std_logic_vector(31 downto 0);
        -- Nonce from belonging comparator
        nonce_comp          : in    std_logic_vector(31 downto 0);
        
        nonce_out           : out   std_logic_vector(31 downto 0);
        found_out           : out   std_logic
      );
    end component;


end package hash_components;
