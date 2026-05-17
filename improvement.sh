# 1. コードをプッシュ
git add .
git commit -m "fix: AI update"
git push origin $(git branch --show-current)

# 2. 正しくActionsの起動を待ってからIDを取得する
echo "⌛ GitHub Actionsが起動するのを待っています..."
sleep 3 

RUN_ID=""
for i in {1..5}; do
    RUN_ID=$(gh run list --commit $(git rev-parse HEAD) --json databaseId --jq '.[0].databaseId' 2>/dev/null)
    # 【修正】「-not -z」から「! -z」に変更
    if [ ! -z "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
        break
    fi
    sleep 2
done

if [ -z "$RUN_ID" ] || [ "$RUN_ID" == "null" ]; then
    echo "❌ GitHub Actionsの起動を確認できませんでした。"
    exit 1
fi

echo "🚀 Actions (ID: $RUN_ID) の実行を監視中..."
gh run watch $RUN_ID --exit-status

# 3. 失敗していた場合のみ、JSONレポートをダウンロードしてAIへ
if [ $? -ne 0 ]; then
    echo "❌ テスト失敗。レポートをダウンロード中..."
    
    # ローカルにある古い古いファイルを確実に削除
    rm -f test-result.json
    
    # ダウンロードを実行（カレントディレクトリに直接 test-result.json が降ってきます）
    gh run download $RUN_ID --name playwright-report --dir ./
    
    # ファイルが本当に存在し、中身があるか（空でないか）チェック
    if [ -s "test-result.json" ]; then
        echo "🤖 正しいテスト結果を検出しました。AIハーネスを実行します..."
        # python3 your_harness.py --fix test-result.json
    else
        echo "⚠️ test-result.json はダウンロードされましたが、まだ空です。Actions側のログを確認してください。"
    fi
else
    echo "✅ テスト成功！"
fi