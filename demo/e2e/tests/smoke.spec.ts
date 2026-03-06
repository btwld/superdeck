import {expect, test, type Page} from '@playwright/test';

const appUrl = '/?enable-flutter-web-semantics=true';

async function ensureAccessibilityEnabled(page: Page) {
  const enableAccessibility = page.getByRole('button', {
    name: 'Enable accessibility',
  });

  const accessibilityPromptVisible = await enableAccessibility
    .waitFor({state: 'visible', timeout: 3_000})
    .then(() => true)
    .catch(() => false);

  if (accessibilityPromptVisible) {
    await enableAccessibility.evaluate((node) => {
      if (node instanceof HTMLElement) {
        node.click();
      }
    });
    await enableAccessibility.waitFor({state: 'hidden', timeout: 10_000});
  }
}

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

async function readSlideCounter(page: Page): Promise<{current: number; total: number}> {
  const counter = page.getByRole('group', {name: /\d+ of \d+/}).first();
  await expect(counter).toBeVisible();

  const label = (await counter.getAttribute('aria-label')) ?? (await counter.textContent()) ?? '';
  const match = label.match(/(\d+)\s+of\s+(\d+)/i);
  if (!match) {
    throw new Error(`Could not parse slide counter from "${label}"`);
  }

  return {
    current: Number.parseInt(match[1]!, 10),
    total: Number.parseInt(match[2]!, 10),
  };
}

test('app boots without error UI', async ({page}) => {
  await page.goto(appUrl);
  await ensureAccessibilityEnabled(page);

  const counter = await readSlideCounter(page);
  expect(counter.current).toBe(1);
  await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
});

test('keyboard navigation advances slide', async ({page}) => {
  await page.goto(appUrl);
  await ensureAccessibilityEnabled(page);
  const {total} = await readSlideCounter(page);

  await nextSlideByKeyboard(page);
  if (total > 1) {
    await expectSlideCounter(page, 2);

    await previousSlideByKeyboard(page);
    await expectSlideCounter(page, 1);
    return;
  }

  await expectSlideCounter(page, 1);
});

test('panel controls support mouse interactions', async ({page}) => {
  await page.goto(appUrl);
  await ensureAccessibilityEnabled(page);
  await openMenu(page);
  await expect(page.getByRole('button', {name: 'Open notes panel'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Export PDF'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Close menu'})).toBeVisible();
});

test('menu exposes regenerate thumbnails action', async ({page}) => {
  await page.goto(appUrl);
  await ensureAccessibilityEnabled(page);
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
  await ensureAccessibilityEnabled(page);
  const {total} = await readSlideCounter(page);
  if (total > 1) {
    await nextSlideByKeyboard(page);
    await expectSlideCounter(page, 2);
  } else {
    await expectSlideCounter(page, 1);
  }

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
