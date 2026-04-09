import {expect, test, type Page} from '@playwright/test';

const appUrl = '/?enable-flutter-web-semantics=true';

test('capture console/pageerror during menu open', async ({page}) => {
  const consoleMessages: string[] = [];
  const pageErrors: string[] = [];
  const crashEvents: string[] = [];

  page.on('console', (msg) => {
    consoleMessages.push(`[${msg.type()}] ${msg.text()}`);
  });
  page.on('pageerror', (err) => {
    pageErrors.push(`${err.name}: ${err.message}\n${err.stack ?? ''}`);
  });
  page.on('crash', () => {
    crashEvents.push('page crashed');
  });
  page.on('close', () => {
    crashEvents.push('page closed');
  });

  try {
    await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
    // eslint-disable-next-line no-console
    console.log('STEP_1_GOTO_DONE');

    await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
    // eslint-disable-next-line no-console
    console.log('STEP_2_OPEN_MENU_VISIBLE');

    await page.waitForTimeout(500);

    await page.getByRole('button', {name: 'Open menu'}).click({force: true});
    // eslint-disable-next-line no-console
    console.log('STEP_3_CLICK_DONE');

    // Short waits to observe what happens after the click
    for (let i = 0; i < 6; i++) {
      await page.waitForTimeout(500);
      // eslint-disable-next-line no-console
      console.log(`STEP_4_WAIT_${i}_DONE`);
      try {
        const alive = await page.evaluate(() => typeof document !== 'undefined');
        // eslint-disable-next-line no-console
        console.log(`STEP_4_ALIVE_${i}=${alive}`);
      } catch (e) {
        // eslint-disable-next-line no-console
        console.log(`STEP_4_ALIVE_${i}_ERROR=${(e as Error).message}`);
      }
    }
  } finally {
    // eslint-disable-next-line no-console
    console.log('CONSOLE_MESSAGES=', JSON.stringify(consoleMessages, null, 2));
    // eslint-disable-next-line no-console
    console.log('PAGE_ERRORS=', JSON.stringify(pageErrors, null, 2));
    // eslint-disable-next-line no-console
    console.log('CRASH_EVENTS=', JSON.stringify(crashEvents, null, 2));
  }
});
