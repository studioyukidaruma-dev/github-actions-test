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
    gh run download $RUN_ID --name playwright-report --dir ./ --clobber # --clobberで上書き許可
    
    # 【修正】「python」から「python3」に変更
    python3 your_harness.py --fix test-result.json
else
    echo "✅ テスト成功！"
fi