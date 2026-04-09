import {expect, test} from '@playwright/test';

const appUrl = '/?enable-flutter-web-semantics=true';

test('minimal: click open menu and just wait', async ({page}) => {
  const pageErrors: string[] = [];
  page.on('pageerror', (err) => {
    pageErrors.push(`${err.name}: ${err.message}\n${err.stack ?? ''}`);
  });

  await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
  await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
  await page.waitForTimeout(500);

  await page.getByRole('button', {name: 'Open menu'}).click({force: true});

  // Just sleep — no page.evaluate, no polling
  await page.waitForTimeout(5000);

  // eslint-disable-next-line no-console
  console.log('PAGE_ERRORS=', JSON.stringify(pageErrors, null, 2));
  // eslint-disable-next-line no-console
  console.log('ERRORS_COUNT=', pageErrors.length);
});

test('minimal: navigate and immediately look for button (no click)', async ({page}) => {
  const pageErrors: string[] = [];
  page.on('pageerror', (err) => {
    pageErrors.push(`${err.name}: ${err.message}`);
  });

  await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(3000);

  // eslint-disable-next-line no-console
  console.log('NO_CLICK_ERRORS=', JSON.stringify(pageErrors, null, 2));
});

test('minimal: evaluate immediately after goto, no click', async ({page}) => {
  const pageErrors: string[] = [];
  page.on('pageerror', (err) => {
    pageErrors.push(`${err.name}: ${err.message}`);
  });

  await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(500);

  // Just one evaluate, no click
  const count = await page.evaluate(
    () => document.querySelectorAll('flt-semantics').length,
  );
  // eslint-disable-next-line no-console
  console.log('EVALUATE_ONLY_COUNT=', count);
  await page.waitForTimeout(2000);

  // eslint-disable-next-line no-console
  console.log('EVALUATE_ONLY_ERRORS=', JSON.stringify(pageErrors, null, 2));
});
