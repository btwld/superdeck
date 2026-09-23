import {expect, test, type Page} from '@playwright/test';

const appUrl = '/';

async function waitForAppReady(page: Page) {
  // The engine exposes this opt-in before it creates the semantics tree.
  // Enable it explicitly instead of relying on an engine-specific URL flag.
  await page
    .getByRole('button', {name: 'Enable accessibility'})
    .dispatchEvent('click');
  await expect.poll(() => hasSemanticsLabel(page, 'Open menu')).toBe(true);
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
}

async function openApp(page: Page) {
  await page.goto(appUrl, {waitUntil: 'domcontentloaded'});
  await waitForAppReady(page);
  await page.waitForTimeout(250);
}

async function clickSemanticsButton(page: Page, label: string) {
  const rect = await waitForTappableSemanticsRect(page, label);
  await page.mouse.click(rect.x, rect.y);
  await page.waitForTimeout(500);
}

async function pressSemanticsButton(page: Page, label: string) {
  const focused = await waitForTappableSemanticsFocus(page, label);
  if (!focused) {
    throw new Error(`Could not focus tappable semantics node for "${label}"`);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
}

async function waitForTappableSemanticsRect(page: Page, label: string) {
  const rect = await waitForTappableSemantics(page, label, 'rect');
  if (rect == null || typeof rect === 'boolean') {
    throw new Error(`Could not find tappable semantics node for "${label}"`);
  }

  return rect;
}

async function waitForTappableSemanticsFocus(page: Page, label: string) {
  return (await waitForTappableSemantics(page, label, 'focus')) === true;
}

async function waitForTappableSemantics(
  page: Page,
  label: string,
  mode: 'focus' | 'rect',
) {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    const result = await page.evaluate(({semanticLabel, action}) => {
      const labeledNode = Array.from(
        document.querySelectorAll('flt-semantics[aria-label]'),
      ).find((node) => node.getAttribute('aria-label') === semanticLabel);
      const childTappable = labeledNode?.querySelector(
        ':scope > flt-semantics[flt-tappable]',
      );
      const directTappable =
        labeledNode instanceof HTMLElement &&
        labeledNode.hasAttribute('flt-tappable')
          ? labeledNode
          : null;
      const tappableNode = childTappable ?? directTappable;
      if (!(tappableNode instanceof HTMLElement)) {
        return false;
      }

      const bounds = tappableNode.getBoundingClientRect();
      if (bounds.width <= 0 || bounds.height <= 0) {
        return false;
      }

      const isFullscreenWrapper =
        tappableNode === directTappable &&
        bounds.width >= window.innerWidth &&
        bounds.height >= window.innerHeight;
      if (isFullscreenWrapper) {
        return null;
      }

      if (action === 'focus') {
        tappableNode.focus();
        return document.activeElement === tappableNode;
      }

      return {
        x: bounds.left + bounds.width / 2,
        y: bounds.top + bounds.height / 2,
      };
    }, {semanticLabel: label, action: mode});

    if (result != null) {
      return result;
    }

    await page.waitForTimeout(100);
  }

  return null;
}

async function hasSemanticsLabel(page: Page, label: string) {
  return page.evaluate((semanticLabel) => {
    return Array.from(
      document.querySelectorAll('flt-semantics[aria-label]'),
    ).some((node) => node.getAttribute('aria-label') === semanticLabel);
  }, label);
}

async function openMenu(page: Page) {
  await pressSemanticsButton(page, 'Open menu');
  await expect
    .poll(async () => {
      try {
        await readSlideCounter(page);
        return true;
      } catch {
        return false;
      }
    })
    .toBe(true);
  await page.waitForTimeout(750);
}

async function expectSlideCounter(page: Page, slideNumber: number) {
  // The semantics tree is rebuilt after a navigation, so a read can land
  // before any label exists. Keep polling instead of failing on that frame.
  await expect
    .poll(async () => {
      try {
        return (await readSlideCounter(page)).current;
      } catch {
        return null;
      }
    })
    .toBe(slideNumber);
}

async function readSlideCounter(
  page: Page,
): Promise<{current: number; total: number}> {
  const labels = await page.evaluate(() => {
    const nodes = Array.from(
      document.querySelectorAll('flt-semantics[aria-label]'),
    );
    return nodes.map((node) => node.getAttribute('aria-label') ?? '');
  });

  const counterLabel =
    labels.filter((value) => /\d+\s+of\s+\d+/i.test(value)).at(-1) ?? '';
  const slideLabel =
    labels.filter((value) => /^Slide\s+\d+/i.test(value)).at(-1) ?? '';
  const slideMatch = slideLabel.match(/^Slide\s+(\d+)/i);
  const counterMatch = counterLabel.match(/(\d+)\s+of\s+(\d+)/i);
  const current = slideMatch?.[1] ?? counterMatch?.[1];
  const total = counterMatch?.[2];

  if (current == null || total == null) {
    throw new Error(
      `Could not parse slide counter from ${JSON.stringify(labels)}`,
    );
  }

  return {
    current: Number.parseInt(current, 10),
    total: Number.parseInt(total, 10),
  };
}

test('app boots without error UI', async ({page}) => {
  await openApp(page);
  await openMenu(page);

  const counter = await readSlideCounter(page);
  expect(counter.current).toBe(1);
  await expect(page.getByText('Error loading presentation')).toHaveCount(0);
});

test('menu navigation advances slide', async ({page}) => {
  await openApp(page);
  await openMenu(page);
  const {total} = await readSlideCounter(page);

  if (total > 1) {
    await clickSemanticsButton(page, 'Next slide');
    await expectSlideCounter(page, 2);

    await clickSemanticsButton(page, 'Previous slide');
    await expectSlideCounter(page, 1);
    return;
  }

  await expectSlideCounter(page, 1);
});

test('the address bar follows the active slide', async ({page}) => {
  await openApp(page);
  await openMenu(page);
  const {total} = await readSlideCounter(page);
  test.skip(total < 2, 'the demo deck has a single slide');

  await clickSemanticsButton(page, 'Next slide');
  await expectSlideCounter(page, 2);
  expect(page.url()).toContain('/slides/1');

  await page.goBack();
  await expectSlideCounter(page, 1);
});

test('an out-of-range slide link is corrected in place', async ({page}) => {
  await openApp(page);
  await openMenu(page);
  const {total} = await readSlideCounter(page);

  await page.evaluate(() => {
    window.location.hash = '#/slides/99';
  });
  await page.waitForTimeout(750);

  // The deck corrects the impossible slide to its last one, and the address
  // bar stops naming a slide the deck does not have. The history depth is
  // deliberately not asserted: for a link the page changed in place, the
  // engine rewrites that entry itself, so `replace` and `go` leave the same
  // history and an assertion on it would pass either way.
  await expectSlideCounter(page, total);
  expect(page.url()).not.toContain('/slides/99');
});

test('panel controls support mouse interactions', async ({page}) => {
  await openApp(page);
  await openMenu(page);

  await expect.poll(() => hasSemanticsLabel(page, 'Open notes panel')).toBe(
    true,
  );
  await expect.poll(() => hasSemanticsLabel(page, 'Close menu')).toBe(true);

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

  await expect
    .poll(() => hasSemanticsLabel(page, 'Regenerate thumbnails'))
    .toBe(true);
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
  await openMenu(page);
  const {total} = await readSlideCounter(page);
  if (total > 1) {
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
