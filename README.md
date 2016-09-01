# SprintBurndownChart4Trello

Trello で管理をしているタスクのバーンダウンチャートを表示するツール

## Install

```
bundle install
```

## Usage

```
bundle exec rackup -p 3000
```

ブラウザから下記URLにアクセス

```
http://localhost:3000/sbc/<board identifer>/phX/spY
```
各値に関しては下記参照

## Setting
### Trello API

1. プロジェクト直下に `settings.yml`を作成する。
2. 下記の内容を記載する。

```
Key: <API Key>
Token: <API Token>
BoardId:
  <board identifer 1>: <board id1> 
  <board identifer 2>: <board id2>
```
* `API Key`、`API Token`
	* Trello API を使用するために必要な値。取得方法は省略
* `board identifer`
	* チャートを表示するために使用するボードを識別するための文字列。後述するが、この部分の文字列が URL に含まれる。
* `board id`
	* チャートを表示するために使用するボードのid。`curl` とかで、Trello API を使用して見つける。

### Target date range
* チャートにする対象のフェイズ・スプリント・日付は`data/sprint_date.yml`に指定する。

```
Phase A :
 Sprint X :
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
 Sprint Y :
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
  - "yyyy-MM-dd"
```

## Trello rule

チャート化をするために必要なリストやカードの作成ルール

* リスト
	* DONE
		* 完了したカードを置くためのリスト
	* Phase**XX**_SP**YY**
		* スプリントが終了した時にDONE内のカードをアーカイブするためのリスト。このリストを作成してリストごとアーカイブする。
		* **XX**、**YY**は`data/sprint_date.yml`内のPhaseとSprintの値と一致する必要がある
* カード 
	* 見積もり時間
		* `(XX) カード名`
	* 追加タスク
		* `追加タスク`という名前のラベルを作成して、カードに設定する