import {expect, test, type Page} from '@playwright/test';

const appUrl = '/?enable-flutter-web-semantics=true';

async function waitForAppReady(page: Page) {
  await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
  await expect(
    page.getByRole('group', {name: /\d+ of \d+/}).first(),
  ).toBeVisible();
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
}

async function openApp(page: Page) {
  await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
  await waitForAppReady(page);
  await page.waitForTimeout(250);
}

async function clickSemanticsButton(page: Page, label: string) {
  await page.evaluate((semanticLabel) => {
    const query =
      `flt-semantics[aria-label="${semanticLabel}"] > flt-semantics[flt-tappable]`;
    const node = document.querySelector(query);
    if (!(node instanceof HTMLElement)) {
      throw new Error(
        `Could not find tappable semantics node for "${semanticLabel}"`,
      );
    }
    node.click();
  }, label);
  await page.waitForTimeout(500);
}

async function hasSemanticsLabel(page: Page, label: string) {
  return page.evaluate((semanticLabel) => {
    return document.querySelector(`flt-semantics[aria-label="${semanticLabel}"]`) !== null;
  }, label);
}

async function openMenu(page: Page) {
  await page.getByRole('button', {name: 'Open menu'}).click({force: true});
  await expect(page.getByRole('button', {name: 'Close menu'})).toBeVisible();
  await expect(page.getByRole('button', {name: 'Next slide'})).toBeVisible();
  await page.waitForTimeout(250);
}

async function expectSlideCounter(page: Page, slideNumber: number) {
  await expect
    .poll(async () => (await readSlideCounter(page)).current)
    .toBe(slideNumber);
}

async function readSlideCounter(
  page: Page,
): Promise<{current: number; total: number}> {
  const label = await page.evaluate(() => {
    const nodes = Array.from(document.querySelectorAll('flt-semantics[aria-label]'));
    const matches = nodes
      .map((node) => node.getAttribute('aria-label') ?? '')
      .filter((value) => /\d+\s+of\s+\d+/i.test(value));
    return matches.at(-1) ?? '';
  });
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
  await openApp(page);

  const counter = await readSlideCounter(page);
  expect(counter.current).toBe(1);
  await expect(page.getByRole('button', {name: 'Open menu'})).toBeVisible();
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
});

test('menu navigation advances slide', async ({page}) => {
  await openApp(page);
  const {total} = await readSlideCounter(page);
  await openMenu(page);

  if (total > 1) {
    await clickSemanticsButton(page, 'Next slide');
    await expectSlideCounter(page, 2);

    await clickSemanticsButton(page, 'Previous slide');
    await expectSlideCounter(page, 1);
    return;
  }

  await expectSlideCounter(page, 1);
});

test('panel controls support mouse interactions', async ({page}) => {
  await openApp(page);
  await openMenu(page);

  const openNotesButton = page.getByRole('button', {name: 'Open notes panel'});
  await expect(openNotesButton).toBeVisible();
  await expect(page.getByRole('button', {name: 'Close menu'})).toBeVisible();

  await clickSemanticsButton(page, 'Open notes panel');

  await expect.poll(() => hasSemanticsLabel(page, 'Close notes panel')).toBe(
    true,
  );
  await clickSemanticsButton(page, 'Close notes panel');
  await expect.poll(() => hasSemanticsLabel(page, 'Open notes panel')).toBe(
    true,
  );
});

test('menu exposes regenerate thumbnails action', async ({page}) => {
  await openApp(page);
  await openMenu(page);

  const regenerateButton = page.getByRole('button', {
    name: 'Regenerate thumbnails',
  });
  await expect(regenerateButton).toBeVisible();
  await clickSemanticsButton(page, 'Regenerate thumbnails');
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
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

  await openApp(page);
  const {total} = await readSlideCounter(page);
  if (total > 1) {
    await openMenu(page);
    await clickSemanticsButton(page, 'Next slide');
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
