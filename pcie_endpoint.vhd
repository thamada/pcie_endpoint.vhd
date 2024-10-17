-- Time-stamp: <2024-10-17 16:42:51 hamada>
-- Copyright (c) 2024 by Tsuyoshi Hamada
--
-- PCIe エンドポイントの簡略化された実装例
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pcie_endpoint is
    Port (
        -- 物理層インターフェース（シリアルデータ）
        pcie_tx_p  : out std_logic;
        pcie_tx_n  : out std_logic;
        pcie_rx_p  : in  std_logic;
        pcie_rx_n  : in  std_logic;
        -- リファレンスクロックとリセット
        refclk     : in  std_logic;
        reset_n    : in  std_logic;
        -- ユーザーインターフェース
        user_clk       : out std_logic;
        user_reset     : out std_logic;
        user_data_in   : out std_logic_vector(31 downto 0);
        user_data_out  : in  std_logic_vector(31 downto 0)
    );
end pcie_endpoint;

architecture rtl of pcie_endpoint is

    -- 内部クロック・リセット信号
    signal core_clk     : std_logic;
    signal core_reset_n : std_logic;

    -- 物理層信号
    signal tx_serial_data : std_logic;
    signal rx_serial_data : std_logic;

    -- データリンク層信号
    signal tx_data_link : std_logic_vector(7 downto 0);
    signal rx_data_link : std_logic_vector(7 downto 0);

    -- トランザクション層信号
    signal tx_transaction : std_logic_vector(31 downto 0);
    signal rx_transaction : std_logic_vector(31 downto 0);

    -- エンコーディング/デコーディング用の信号（8b/10bなど）
    signal tx_encoded : std_logic_vector(9 downto 0);
    signal rx_encoded : std_logic_vector(9 downto 0);

begin

    ----------------------------------------
    -- クロックとリセットの生成
    ----------------------------------------
    core_clk     <= refclk;
    core_reset_n <= reset_n;

    user_clk     <= core_clk;
    user_reset   <= not core_reset_n;

    ----------------------------------------
    -- 物理層の実装
    ----------------------------------------

    -- シリアライザ：パラレルデータをシリアルデータに変換
    serializer : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                tx_serial_data <= '0';
            else
                tx_serial_data <= tx_encoded(0);  -- 簡略化のためビット0のみ送信
            end if;
        end if;
    end process;

    -- デシリアライザ：シリアルデータをパラレルデータに変換
    deserializer : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                rx_encoded <= (others => '0');
            else
                rx_encoded(0) <= rx_serial_data;  -- 簡略化のためビット0のみ受信
            end if;
        end if;
    end process;

    -- 差動信号への変換（簡略化）
    pcie_tx_p <= tx_serial_data;
    pcie_tx_n <= not tx_serial_data;
    rx_serial_data <= pcie_rx_p;

    ----------------------------------------
    -- データリンク層の実装
    ----------------------------------------

    -- エンコーディング（8b/10bなどの簡略版）
    encoding : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                tx_encoded <= (others => '0');
            else
                tx_encoded <= "00" & tx_data_link;  -- 簡略化したエンコーディング
            end if;
        end if;
    end process;

    -- デコーディング
    decoding : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                rx_data_link <= (others => '0');
            else
                rx_data_link <= rx_encoded(7 downto 0);  -- 簡略化したデコーディング
            end if;
        end if;
    end process;

    ----------------------------------------
    -- トランザクション層の実装
    ----------------------------------------

    -- パケットの生成
    transaction_layer_tx : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                tx_data_link <= (others => '0');
            else
                tx_data_link <= tx_transaction(7 downto 0);  -- 簡略化
            end if;
        end if;
    end process;

    -- パケットの受信
    transaction_layer_rx : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                rx_transaction <= (others => '0');
            else
                rx_transaction(7 downto 0) <= rx_data_link;  -- 簡略化
            end if;
        end if;
    end process;

    ----------------------------------------
    -- ユーザーインターフェースへの接続
    ----------------------------------------

    user_data_in <= rx_transaction;

    process(core_clk)
    begin
        if rising_edge(core_clk) then
            if core_reset_n = '0' then
                tx_transaction <= (others => '0');
            else
                tx_transaction <= user_data_out;
            end if;
        end if;
    end process;

end rtl;
