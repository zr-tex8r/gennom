gennom
======

LaTeX：「源暎ノンブル」フォントをLaTeXで使う

### 前提環境

  * フォーマット： LaTeX
  * エンジン：pdfTeX（DVI出力のみ※）・e-pTeX・e-upTeX（・LuaTeX）  
    ※pdfTeXのPDF出力でのTrueTypeフォントサポートは不十分なので、
    「源暎ノンブル」のフォント形式はサポートされないようだ。  
    ※LuaLaTeXのサポートは試験的で一部の使用が未確定。
  * DVIウェア（DVI出力時）： dvipdfmx
  * 「源暎ノンブル」のフォントファイル（GenEiNombre.ttf）  
    ※以下のサイトからダウンロードできます。  
    源暎フォント置き場  
    https://okoneya.jp/font/download.html#dl-genb

### インストール

  - `*.sty`     → $TEXMF/tex/latex/gennom/
  - `tfm/*.tfm` → $TEXMF/fonts/tfm/public/gennom/
  - `vf/*.vf`   → $TEXMF/fonts/vf/public/gennom/
  - 「源暎ノンブル」のフォントファイル`GenEiNombre.ttf`を
    `$TEXMF/fonts/truetype/`以下のどこかに置く。
    ※OSにインストールしていて既にTeXから見えている場合は不要。

### ライセンス

本パッケージは MIT ライセンスの下で配布される。


gennom パッケージ
-----------------

### パッケージ読込

`\usepackage`で読み込む。

    \usepackage[<ドライバオプション>]{gennom}

DVI出力でdvipdfmxを用いる場合は`dvipdfmx`オプションを指定する。

### 使用法

パッケージを読み込むと、`gennom`の（欧文）ファミリ名で「源暎ノンブル」が
使えるようになる。

※元々「源暎ノンブル」フォント自体が単一のシェープのみをもつため太字や斜体はサポートされない。
※非UnicodeエンジンでサポートされるエンコーディングはOT1・T1・LY1・TS1。

以下の命令が提供される。

  * `\gennomfamily`：`gennom`ファミリに切り替える宣言型フォント命令。
  * `\textgennom{‹テキスト›}`：引数のテキストを`gennom`ファミリで出力。


更新履歴
--------

  * Version 0.2  ‹2021/11/11›
      - 最初の公開版。

--------------------
Takayuki YATO (aka. "ZR")  
https://github.com/zr-tex8r
