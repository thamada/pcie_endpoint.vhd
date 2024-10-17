-- Copyright(c) 2024 Tsuyoshi Hamada

-----------------------------------------------------------------------------------------
-- 1. 8b/10b エンコーディングの実装
--
--   8b/10bエンコーディングは、8ビットのデータを10ビットのコードに変換し、
--   DCバランスとエラー検出を可能にします。
--
--   * エンコードテーブル：実際の8b/10bエンコーディングでは、特定のア
--     ルゴリズムまたはテーブルを使用して8ビットの入力を10ビットに変換
--     します。
--
--   * 簡略化：ここでは、エンコードテーブルを簡略化しています。実際の
--     実装では、正確なエンコード値を定義する必要があります。
-----------------------------------------------------------------------------------------

-- 8b/10b エンコーダ
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity encoder_8b10b is
    Port (
        clk      : in  std_logic;
        reset_n  : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(9 downto 0)
    );
end encoder_8b10b;

architecture rtl of encoder_8b10b is

    -- エンコード用のテーブル（簡略化）
    type encode_table is array (0 to 255) of std_logic_vector(9 downto 0);
    constant encoding_table : encode_table := (
        -- 実際のエンコード値を定義
        -- ここでは簡略化のため全てを '0' にしています
        others => (others => '0')
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                data_out <= (others => '0');
            else
                data_out <= encoding_table(to_integer(unsigned(data_in)));
            end if;
        end if;
    end process;

end rtl;


-----------------------------------------------------------------------------------------
-- 2. リンクトレーニングの実装
--   リンクトレーニングは、通信相手とリンクの確立を行うプロセスです。
--   * ステートマシン：リンクトレーニングの状態を管理するためにステートマシンを使用しています。
--   * トレーニングシーケンス：実際には、特定のシーケンスやハンドシェイクを実装します。
-----------------------------------------------------------------------------------------

-- リンクトレーニングモジュール
entity link_training is
    Port (
        clk           : in  std_logic;
        reset_n       : in  std_logic;
        training_done : out std_logic;
        -- 他の信号（リンク状態、制御信号など）
    );
end link_training;

architecture rtl of link_training is

    type state_type is (IDLE, TRAINING, COMPLETED);
    signal state : state_type;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state <= IDLE;
                training_done <= '0';
            else
                case state is
                    when IDLE =>
                        -- トレーニング開始条件
                        state <= TRAINING;
                    when TRAINING =>
                        -- トレーニングシーケンスの実行
                        -- 条件が満たされたらCOMPLETEDへ
                        state <= COMPLETED;
                    when COMPLETED =>
                        training_done <= '1';
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end rtl;


-----------------------------------------------------------------------------------------
-- 3. フロー制御の実装
--   フロー制御は、データの送受信を調整し、オーバーフローを防ぎます。
--   * クレジットベースのフロー制御：送信可能なデータ量をクレジットで管理します。
--   * クレジットの増減：データの送受信に応じてクレジットを調整します。
-----------------------------------------------------------------------------------------

-- フロー制御モジュール
entity flow_control is
    Port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        tx_ready     : in  std_logic;
        rx_valid     : in  std_logic;
        flow_control : out std_logic
    );
end flow_control;

architecture rtl of flow_control is

    signal credit_count : integer range 0 to 16 := 16;  -- クレジットの初期値

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                credit_count <= 16;
                flow_control <= '0';
            else
                if tx_ready = '1' and credit_count > 0 then
                    credit_count <= credit_count - 1;
                end if;
                if rx_valid = '1' then
                    credit_count <= credit_count + 1;
                end if;
                if credit_count = 0 then
                    flow_control <= '1';  -- フロー制御をアサート
                else
                    flow_control <= '0';
                end if;
            end if;
        end if;
    end process;

end rtl;

-----------------------------------------------------------------------------------------
-- 4. エラーチェックの実装
--  データの整合性を確認するために、CRCなどのエラーチェックを行います。
--  * CRC計算：データに対してCRCを計算し、エラーを検出します。
--  * 簡略化：実際のCRCアルゴリズムは複雑ですが、ここでは簡略化しています。
-----------------------------------------------------------------------------------------

-- CRC計算モジュール
entity crc_checker is
    Port (
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        data_in    : in  std_logic_vector(31 downto 0);
        crc_error  : out std_logic
    );
end crc_checker;

architecture rtl of crc_checker is

    signal crc_reg : std_logic_vector(7 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                crc_reg <= (others => '0');
                crc_error <= '0';
            else
                -- 簡略化したCRC計算
                crc_reg <= crc_reg xor data_in(7 downto 0);
                if crc_reg /= "00000000" then
                    crc_error <= '1';
                else
                    crc_error <= '0';
                end if;
            end if;
        end if;
    end process;

end rtl;


-----------------------------------------------------------------------------------------
-- 5. コンフィギュレーションスペースの管理
--   デバイスの設定やステータス情報を保持します。
--   コンフィギュレーションスペースモジュール
--   * コンフィギュレーションレジスタ：アドレスごとに設定値を保持します。
--   * 読み書き操作：ホストからの読み書き要求に応答します。
-----------------------------------------------------------------------------------------

-- コンフィギュレーションスペースモジュール
entity configuration_space is
    Port (
        clk            : in  std_logic;
        reset_n        : in  std_logic;
        cfg_address    : in  std_logic_vector(5 downto 0);
        cfg_data_in    : in  std_logic_vector(31 downto 0);
        cfg_data_out   : out std_logic_vector(31 downto 0);
        cfg_read       : in  std_logic;
        cfg_write      : in  std_logic
    );
end configuration_space;

architecture rtl of configuration_space is

    type cfg_space_array is array (0 to 63) of std_logic_vector(31 downto 0);
    signal cfg_space : cfg_space_array;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                cfg_space <= (others => (others => '0'));
                cfg_data_out <= (others => '0');
            else
                if cfg_write = '1' then
                    cfg_space(to_integer(unsigned(cfg_address))) <= cfg_data_in;
                end if;
                if cfg_read = '1' then
                    cfg_data_out <= cfg_space(to_integer(unsigned(cfg_address)));
                end if;
            end if;
        end if;
    end process;

end rtl;

-----------------------------------------------------------------------------------------
-- トップレベルPCIeエンドポイント
entity pcie_endpoint is
    Port (
        -- 物理層インターフェース
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

    -- 内部信号の宣言
    signal core_clk       : std_logic;
    signal core_reset_n   : std_logic;
    signal training_done  : std_logic;
    signal flow_control   : std_logic;
    signal crc_error      : std_logic;
    signal encoded_data   : std_logic_vector(9 downto 0);
    signal decoded_data   : std_logic_vector(7 downto 0);

begin

    -- クロックとリセットの配線
    core_clk     <= refclk;
    core_reset_n <= reset_n;

    user_clk     <= core_clk;
    user_reset   <= not core_reset_n;

    -- リンクトレーニングのインスタンス
    lt_inst : entity work.link_training
        port map (
            clk           => core_clk,
            reset_n       => core_reset_n,
            training_done => training_done
        );

    -- フロー制御のインスタンス
    fc_inst : entity work.flow_control
        port map (
            clk          => core_clk,
            reset_n      => core_reset_n,
            tx_ready     => '1',  -- 簡略化
            rx_valid     => '1',  -- 簡略化
            flow_control => flow_control
        );

    -- エラーチェックのインスタンス
    crc_inst : entity work.crc_checker
        port map (
            clk       => core_clk,
            reset_n   => core_reset_n,
            data_in   => user_data_out,
            crc_error => crc_error
        );

    -- コンフィギュレーションスペースのインスタンス
    cfg_inst : entity work.configuration_space
        port map (
            clk          => core_clk,
            reset_n      => core_reset_n,
            cfg_address  => (others => '0'),  -- 簡略化
            cfg_data_in  => (others => '0'),  -- 簡略化
            cfg_data_out => open,
            cfg_read     => '0',
            cfg_write    => '0'
        );

    -- 8b/10bエンコーダのインスタンス
    enc_inst : entity work.encoder_8b10b
        port map (
            clk      => core_clk,
            reset_n  => core_reset_n,
            data_in  => user_data_out(7 downto 0),
            data_out => encoded_data
        );

    -- 物理層への接続（簡略化）
    pcie_tx_p <= encoded_data(0);
    pcie_tx_n <= not encoded_data(0);
    -- 受信データの処理は省略

    -- ユーザーインターフェースへの接続
    user_data_in <= (others => '0');  -- 簡略化

end rtl;

