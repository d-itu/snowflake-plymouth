"""Render deterministic frames from the animated NixOS logo SVG."""

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright


def main() -> None:
    svg = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2])
    chromium = sys.argv[3]

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path=chromium,
            args=["--no-sandbox", "--enable-experimental-web-platform-features"],
        )
        page = browser.new_page(viewport={"width": 697, "height": 256}, device_scale_factor=1)
        page.goto(svg.as_uri(), wait_until="load")
        page.evaluate("document.querySelector('svg').pauseAnimations()")

        for frame in range(180):
            page.evaluate("time => document.querySelector('svg').setCurrentTime(time)", frame / 30)
            page.screenshot(
                path=str(output / f"throbber-{frame + 1:04}.png"),
                omit_background=True,
                animations="allow",
            )

        browser.close()


if __name__ == "__main__":
    main()
