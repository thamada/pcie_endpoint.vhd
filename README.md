# pcie_endpoint.vhd
PCIe endpoint core in pure VHDL


## 概略
PCIeプロトコルの完全な物理層およびトランザクション層をVHDLで一から実装
することは非常に複雑であり、ここで全てを提供することは困難です。
ここでは、教育目的で物理層とトランザクション層の主要な要素を含む、より詳細な
VHDLコードの例を実装します。

** 注意 **

PCIeの基本的な動作をシミュレートするための簡略化されたVHDLモデルです。
実際のPCIe規格に完全に準拠しているわけではないことにご注意ください。


## VHDLコードの説明:

- 物理層の実装:
    - シリアライザ/デシリアライザ: serializerとdeserializerプロセスでシリアル通信を簡略化して実装しています。
    - 差動信号: PCIeでは差動信号を使用しますが、ここではシンプルに正論理とその反転で表現しています。
- データリンク層の実装:
    - エンコーディング/デコーディング: 8b/10bエンコーディングの詳細は省略し、データの上位ビットに固定値を追加することで簡略化しています。
- トランザクション層の実装:
    - パケットの生成と受信： トランザクション層のデータをデータリンク層にマッピングしています。
- ユーザーインターフェース:
    - ユーザーデータとトランザクション層データを接続しています。


## 注意事項:

- 簡略化: このコードはPCIeプロトコルの多くの機能を省略しています。実際の実装では、リンクトレーニング、フロー制御、エラーチェック、コンフィギュレーションスペースの管理など、多くの要素が必要です。
- エンコーディング: 実際のPCIeでは、8b/10bや128b/130bエンコーディングが使用されますが、ここでは簡略化しています。
- 物理層: シリアル通信や差動信号の実装はFPGAのトランシーバーモジュールで行われますが、このコードでは詳細を省略しています。


## 発展:

- 詳細な仕様の学習: PCIe規格書を参照し、各層の詳細な仕様を理解すると良いでしょう。
- 階層的な設計: 物理層、データリンク層、トランザクション層ごとにモジュールを分割し、詳細に実装すると良いでしょう。
- 専門的なツールの使用： PCIeの開発には専用のIPコアや検証ツールが必要になる場合があります。それらを使ってみると良いでしょう。
- 検証とデバッグ： シミュレーションと実機検証を通じて、設計が正しく動作することを確認すると良いでしょう。
- FPGAのトランシーバー: 実際のPCIe物理層は、FPGA内蔵の高速トランシーバーを使用して実装されます。これらのトランシーバーは専用のハードウェアブロックであり、ユーザーが直接VHDLで実装するものではありません。個々のFPGAデバイスの説明書に従ってそれらを使ってみると良いでしょう。
- IPコアの利用: FPGAベンダーが提供するPCIe IPコアを使用することで、複雑な部分を抽象化できます。それらのIPコアを使ってみると良いでしょう。
