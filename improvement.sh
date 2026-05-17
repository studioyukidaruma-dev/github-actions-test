# 1. コードをプッシュ
git add .
git commit -m "fix: AI update"
git push origin $(git branch --show-current)

# 2. 自分のコミットに対するActionsが終わるまで待機
# ※ --exit-status をつけると、Actionsが失敗した時に gh コマンド自体が異常終了(非0)になります
gh run watch $(git rev-parse HEAD) --exit-status

# 3. 失敗していた場合のみ、JSONレポートをダウンロードしてAIハーネスへ
if [ $? -ne 0 ]; then
    echo "❌ テスト失敗。レポートをダウンロード中..."
    
    # 該当するコミットのRun IDを取得し、そこからArtifactをダウンロード
    RUN_ID=$(gh run list --commit $(git rev-parse HEAD) --json databaseId --jq '.[0].databaseId')
    gh run download $RUN_ID --name playwright-report --dir ./
    
    # # これでローカルに 「test-result.json」 が降ってくるのでAIに渡す
    # python your_harness.py --fix test-result.json
else
    echo "✅ テスト成功！"
fi