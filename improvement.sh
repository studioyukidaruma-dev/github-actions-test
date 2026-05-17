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
    
    # 【修正】衝突を防ぐため、ローカルにある古いファイルやフォルダをあらかじめ削除
    rm -f test-result.json
    rm -rf playwright-report
    
    # 【修正】--clobber フラグを削除してダウンロード
    gh run download $RUN_ID --name playwright-report --dir ./
    
    # 【親切設計】フォルダの中にダウンロードされたJSONを、ルート直下に移動させる
    if [ -f "playwright-report/test-result.json" ]; then
        mv playwright-report/test-result.json ./
        rm -rf playwright-report
    fi
    
    # 正しく中身の詰まった test-result.json をPythonに渡す
    echo "🤖 AIハーネスを実行します..."
    # python3 your_harness.py --fix test-result.json
else
    echo "✅ テスト成功！"
fi