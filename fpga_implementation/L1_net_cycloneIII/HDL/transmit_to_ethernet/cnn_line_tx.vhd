library IEEE;
use IEEE.STD_LOGIC_1164.all;
use Ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
library work;
use work.bitwidths.all;
use work.cnn_types.all;
use work.params.all;
library std;
use ieee.math_real.all;


entity cnn_line_tx is
  generic (
    PIXEL_SIZE      : integer := GENERAL_BITWIDTH;--8
    IMAGE_WIDTH     : integer := pool1_IMAGE_WIDTH;--222
    IMAGE_HEIGHT    : integer := pool1_IMAGE_WIDTH; --222
    NB_IN_FLOWS     : integer := pool1_OUT_SIZE--64
    );
  port(
    clk   : in std_logic;
    rst_n : in std_logic;

    line_ready     : in  std_logic;
    read_req_board : out std_logic;
    data_board     : in  std_logic_vector(17 downto 0);

    line_select     : out std_logic_vector(1 downto 0);
    empty_line      : in  std_logic;
    read_line       : out std_logic;
    data_level_line : in  std_logic_vector(15 downto 0);
    data_out_line   : in  std_logic_vector(NB_IN_FLOWS*PIXEL_SIZE-1 downto 0);

	 --test 
	 total_bytes_tansferred : out std_logic_vector(31 downto 0);
	 line_count			: out std_logic_vector(15 downto 0);
	 --
	 
	 
    frame_to_tx_size    : out std_logic_vector(15 downto 0);
    frame_to_tx_request : out std_logic;
    frame_to_tx_granted : in  std_logic;
    frame_to_tx_valid   : out std_logic;
    frame_to_tx_eof     : out std_logic;
    frame_to_tx_data    : out std_logic_vector(7 downto 0)
    );
end entity;



architecture rtl of cnn_line_tx is

  constant header_size : integer := 4;

  signal line_count_int   : std_logic_vector(15 downto 0);
  signal packet_index : unsigned(7 downto 0);-- nombre de paquet ethernet pour UNE ligne (ici 10)

  signal line_select_int     : std_logic_vector(1 downto 0);
  signal data_level_line_int : unsigned(15 downto 0);

  signal frame_to_tx_size_int : unsigned(15 downto 0);

  signal rst_n_byte_count_int, en_byte_count_int : std_logic;
  signal byte_count_int                          : unsigned(15 downto 0);

  signal rst_n_pixel_count_int, en_pixel_count_int : std_logic;
  signal pixel_count_int                           : unsigned(15 downto 0);


  -- signal data_tmp_int : std_logic_vector(NB_IN_FLOWS*PIXEL_SIZE-1 downto 0);

  signal vgg_channel_int : integer range 0 to NB_IN_FLOWS-1;

  type TX_STATE_ENUM is (steady, board_0, board_1, load_size, load_size_no_read_req, load_size_no_read_req_last_pixel, hdr_0, hdr_1, hdr_2, hdr_3, hdr_4, hdr_5, wait_one_cycle, data_0, data_1, data_2, shift_data);
  signal TX_STATE : TX_STATE_ENUM;
  
  
  signal total_bytes_tansferred_int : unsigned(31 downto 0);

begin

total_bytes_tansferred 	<= std_logic_vector(total_bytes_tansferred_int);
line_count					<= std_logic_vector(line_count_int);

  line_count_int   <= data_board(15 downto 0);
  line_select      <= line_select_int;
--frame_to_tx_size <= std_logic_vector(frame_to_tx_size_int + 4); --4 more for header x"CAFE"+x"line_count_int"
  frame_to_tx_size <= std_logic_vector(frame_to_tx_size_int + header_size);  --6 more for header x"DECA"+x"line_count_int+x"pixel_offset_int"

  data_level_line_int <= unsigned(data_level_line);

  
  process(clk, rst_n)
  begin
    if rst_n = '0' then

		total_bytes_tansferred_int	<= (others => '0');
		packet_index			 <= (others => '0');
      read_req_board        <= '0';
      line_select_int       <= (others => '0');
      read_line             <= '0';
      frame_to_tx_request   <= '0';
      frame_to_tx_size_int  <= (others => '0');
      frame_to_tx_valid     <= '0';
      frame_to_tx_eof       <= '0';
      frame_to_tx_data      <= (others => '0');
      byte_count_int        <= (others => '0');
      vgg_channel_int       <= 0;
      TX_STATE              <= steady;

    elsif rising_edge(clk) then
		packet_index 			 <= packet_index;
      read_req_board        <= '0';
      line_select_int       <= line_select_int;
      read_line             <= '0';
      frame_to_tx_size_int  <= frame_to_tx_size_int;
      frame_to_tx_request   <= '0';
      frame_to_tx_valid     <= '0';
      frame_to_tx_eof       <= '0';
      frame_to_tx_data      <= (others => '0');
      byte_count_int        <= (others => '0');
      vgg_channel_int       <= vgg_channel_int;


      case TX_STATE is

        when steady =>
          if line_ready = '1' then
            read_req_board <= '1';
            TX_STATE       <= board_0;
          end if;
          byte_count_int <= (others => '0');

        when board_0 =>                 --wait 1 cycle to get fifo board data
          TX_STATE <= board_1;

        when board_1 =>
          if data_board(17 downto 16) = "01" then
            line_select_int <= "01";
            TX_STATE        <= load_size;
          elsif data_board(17 downto 16) = "10" then
            line_select_int <= "10";
            TX_STATE        <= load_size;
          else
            line_select_int <= (others => '0');
            TX_STATE        <= steady;
          end if;

        when load_size =>-- a revoir
          if data_level_line_int >= 1468 then
            frame_to_tx_size_int <= to_unsigned(1468, 16);
          else
            frame_to_tx_size_int <= data_level_line_int;
          end if;
          frame_to_tx_request <= '1';   --takes 14 clock cycles to complete
          read_line           <= '1';   --load the 64 pixels
          byte_count_int      <= (others => '0');
          TX_STATE            <= hdr_0;

        when load_size_no_read_req =>
          if (data_level_line_int+to_unsigned(NB_IN_FLOWS - vgg_channel_int, 16)) >= 1468 then
            frame_to_tx_size_int <= to_unsigned(1468, 16);
          else
            frame_to_tx_size_int <= data_level_line_int+to_unsigned(NB_IN_FLOWS - vgg_channel_int, 16);--(64-to_unsigned(vgg_channel_int,16)-1);
          end if;
          frame_to_tx_request <= '1';   --takes 14 clock cycles to complete
          read_line           <= '0';
          byte_count_int      <= (others => '0');
          TX_STATE            <= hdr_0;

        when load_size_no_read_req_last_pixel =>
            frame_to_tx_size_int  <= to_unsigned(NB_IN_FLOWS - vgg_channel_int, 16);
            frame_to_tx_request <= '1';   --takes 14 clock cycles to complete
            read_line           <= '0';
            byte_count_int      <= (others => '0');
            TX_STATE            <= hdr_0;



        when hdr_0 =>                   -- ID  =  xDECA =>  VGG
          frame_to_tx_request <= '1';
          if frame_to_tx_granted = '1' then
            frame_to_tx_valid <= '1';
            frame_to_tx_data  <= x"DE";
            TX_STATE          <= hdr_1;
				total_bytes_tansferred_int	<= total_bytes_tansferred_int + 1;
          end if;

        when hdr_1 =>
          frame_to_tx_request <= '1';
          if frame_to_tx_granted = '1' then
            frame_to_tx_valid <= '1';
            frame_to_tx_data  <= x"CA";
            TX_STATE          <= hdr_2;
				total_bytes_tansferred_int	<= total_bytes_tansferred_int + 1;
          end if;

        when hdr_2 =>                   --LINE NUMBER
          frame_to_tx_request <= '1';
          if frame_to_tx_granted = '1' then
            frame_to_tx_valid <= '1';
            frame_to_tx_data  <= std_logic_vector(packet_index);
            TX_STATE          <= hdr_3;
				total_bytes_tansferred_int	<= total_bytes_tansferred_int + 1;
          end if;

        when hdr_3 =>
          frame_to_tx_request <= '1';
          if frame_to_tx_granted = '1' then
            frame_to_tx_valid <= '1';
            frame_to_tx_data  <= line_count_int(7 downto 0);
            TX_STATE          <= shift_data;
				total_bytes_tansferred_int	<= total_bytes_tansferred_int + 1;
          end if;

        when shift_data =>
          frame_to_tx_request <= '1';
          if frame_to_tx_granted = '1' then
				total_bytes_tansferred_int	<= total_bytes_tansferred_int + 1;
            byte_count_int    <= byte_count_int + 1;
            frame_to_tx_valid <= '1';
            frame_to_tx_data  <= data_out_line((vgg_channel_int+1)*PIXEL_SIZE-1 downto vgg_channel_int*PIXEL_SIZE);
            ----------------------------LINE EMPTY
            if empty_line = '1' then --dernier pixel de la ligne
              frame_to_tx_request   <= '1';
              read_line             <= '0';
              if byte_count_int = frame_to_tx_size_int-1 then --paquet terminé							
					frame_to_tx_eof     <= '1';
						if packet_index = 9 then
							packet_index <= (others => '0');
						else
							packet_index	<= packet_index + 1;
						end if;
                if vgg_channel_int = NB_IN_FLOWS - 1 then
                vgg_channel_int     <= 0;
                TX_STATE            <= steady;--line has been transfered
                else
                  vgg_channel_int     <= vgg_channel_int + 1;
                  TX_STATE            <= load_size_no_read_req_last_pixel;
                end if;
              else
                frame_to_tx_eof    <= '0';--fin de paquet ethernet
					 packet_index			<= packet_index;
                if vgg_channel_int = NB_IN_FLOWS - 1 then
                  vgg_channel_int     <= 0;
                  TX_STATE            <= steady;
                else
                  frame_to_tx_eof     <= '0';
                  vgg_channel_int     <= vgg_channel_int + 1;
                  TX_STATE            <= shift_data;
                end if;
              end if;
              ------------------------
            else
              if byte_count_int = frame_to_tx_size_int-1 then --paquet terminé
                read_line           <= '0';
                frame_to_tx_eof     <= '1';--fin de paquet ethernet
					if packet_index = 9 then
						packet_index <= (others => '0');
					else
						packet_index	<= packet_index + 1;
					end if;
                if vgg_channel_int = NB_IN_FLOWS - 1 then
                  vgg_channel_int     <= 0;
                  TX_STATE            <= load_size;--read_req happens at LOAD_SIZE STATE
                else
                  vgg_channel_int     <= vgg_channel_int + 1;
                  TX_STATE            <= load_size_no_read_req;
                end if;
              else
                frame_to_tx_eof    <= '0';
					 packet_index			<= packet_index;
                if vgg_channel_int = NB_IN_FLOWS - 2 then
                  vgg_channel_int     <= vgg_channel_int + 1;
                  read_line           <= '1'; --next pixel
                  TX_STATE            <= shift_data; 
                elsif vgg_channel_int = NB_IN_FLOWS - 1 then
                  vgg_channel_int     <= 0;
                  read_line           <= '0';
                  TX_STATE            <= shift_data;
                else
                  vgg_channel_int     <= vgg_channel_int + 1;
                  read_line           <= '0';
                  TX_STATE            <= shift_data;
                end if;
              end if;
            end if;
          end if;



      when others =>
        read_req_board        <= '0';
        line_select_int       <= (others => '0');
        frame_to_tx_size_int  <= (others => '0');
        frame_to_tx_request   <= '0';
        frame_to_tx_valid     <= '0';
        frame_to_tx_eof       <= '0';
        frame_to_tx_data      <= (others => '0');
        vgg_channel_int       <= 0;
        byte_count_int        <= (others => '0');
        TX_STATE              <= steady;

    end case;

    end if;
  end process;



end architecture;
