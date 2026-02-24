import {expect, test, type Page} from '@playwright/test';

const appUrl = '/?enable-flutter-web-semantics=true';

async function openMenu(page: Page) {
  await page.getByRole('button', {name: 'Open menu'}).click({force: true});
  await expect(page.getByRole('button', {name: 'Close menu'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Next slide'})).toBeVisible();
}

async function nextSlideByKeyboard(page: Page) {
  await page.keyboard.down('Meta');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.up('Meta');
}

async function previousSlideByKeyboard(page: Page) {
  await page.keyboard.down('Meta');
  await page.keyboard.press('ArrowUp');
  await page.keyboard.up('Meta');
}

async function expectSlideCounter(page: Page, slideNumber: number) {
  await expect(
    page.getByRole('group', {name: new RegExp(`${slideNumber} of \\d+`)}),
  ).toBeVisible();
}

test('app boots without error UI', async ({page}) => {
  await page.goto(appUrl);

  await expectSlideCounter(page, 1);
  await expect(
    page.getByRole('img', {name: /SuperDeck Build presentations with Flutter/i}),
  ).toBeVisible();
  await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
});

test('keyboard navigation advances slide', async ({page}) => {
  await page.goto(appUrl);
  await expectSlideCounter(page, 1);

  await nextSlideByKeyboard(page);
  await expectSlideCounter(page, 2);

  await previousSlideByKeyboard(page);
  await expectSlideCounter(page, 1);
});

test('panel controls support mouse interactions', async ({page}) => {
  await page.goto(appUrl);
  await openMenu(page);
  await expect(page.getByRole('button', {name: 'Open notes panel'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Export PDF'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Close menu'})).toBeVisible();
});

test('menu exposes regenerate thumbnails action', async ({page}) => {
  await page.goto(appUrl);
  await openMenu(page);

  const regenerateButton = page.getByRole('button', {
    name: 'Regenerate thumbnails',
  });
  await expect(regenerateButton).toBeVisible();
  await regenerateButton.dispatchEvent('click');
});

test('asset-heavy slide renders without fatal console/network errors', async ({
  page,
}) => {
  const consoleErrors: string[] = [];
  const failedRequests: string[] = [];

  page.on('console', (message) => {
    if (message.type() === 'error') {
      consoleErrors.push(message.text());
    }
  });

  page.on('requestfailed', (request) => {
    failedRequests.push(request.url());
  });

  await page.goto(appUrl);
  await expectSlideCounter(page, 1);
  await nextSlideByKeyboard(page);
  await expectSlideCounter(page, 2);
  await expect(
    page.getByRole('img', {name: /Leo Farias|Founder\/CEO\/CTO/i}),
  ).toBeVisible();

  const unexpectedConsoleErrors = consoleErrors.filter(
    (error) => !error.toLowerCase().includes('overflowed'),
  );
  const unexpectedFailedRequests = failedRequests.filter((url) => {
    return (
      !url.includes('fonts.googleapis.com') &&
      !url.includes('fonts.gstatic.com')
    );
  });

  expect(unexpectedConsoleErrors).toEqual([]);
  expect(unexpectedFailedRequests).toEqual([]);
});
