import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  // Playwright設定で定義されたbaseUrl（http://localhost:3000）にアクセス
  await page.goto('/');

  // <h1>タグを取得
  const title = page.locator('h1');

  // <h1>タグの中身が "Hello, Playwright!" であることを確認
  // ※ アプリ（index.html）側が間違っているため、最初はここで失敗します。
  await expect(title).toHaveText('Hello, Playwright!');
});