# 1. コードをプッシュ (ここは既に成功しています)
git add .
git commit -m "fix: AI update"
git push origin $(git branch --show-current)

# ==========================================
# 2. 【修正】正しくActionsの起動を待ってからIDを取得する
# ==========================================
echo "⌛ GitHub Actionsが起動するのを待っています..."
sleep 3 # プッシュ直後はActionsがまだ生成されていないため、3秒待つ

RUN_ID=""
# 最大5回、ActionsのIDが取得できるまでループ（2秒おき）
for i in {1..5}; do
    RUN_ID=$(gh run list --commit $(git rev-parse HEAD) --json databaseId --jq '.[0].databaseId' 2>/dev/null)
    if [ -not -z "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
        break
    fi
    sleep 2
done

if [ -z "$RUN_ID" ] || [ "$RUN_ID" == "null" ]; then
    echo "❌ GitHub Actionsの起動を確認できませんでした。リポジトリのActionsタブが無効になっていないか確認してください。"
    exit 1
fi

echo "🚀 Actions (ID: $RUN_ID) の実行を監視中..."
# コミットハッシュではなく、取得した「数字のID」を渡して監視する
gh run watch $RUN_ID --exit-status

# ==========================================
# 3. 失敗していた場合のみ、JSONレポートをダウンロードしてAIへ
# ==========================================
if [ $? -ne 0 ]; then
    echo "❌ テスト失敗。レポートをダウンロード中..."
    gh run download $RUN_ID --name playwright-report --dir ./
    
    # AIハーネスの実行（例）
    python your_harness.py --fix test-result.json
else
    echo "✅ テスト成功！"
fi