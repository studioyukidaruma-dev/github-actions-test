import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html', # ローカル実行時のレポート。Actions上ではJSONで出力します。
  
  use: {
    // テスト対象のURL。ローカルサーバーのURLを指定。
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // テスト実行前にローカルサーバーを起動する設定
  webServer: {
    command: 'npm run serve', # package.jsonのscriptsにある"serve"コマンドを実行
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});