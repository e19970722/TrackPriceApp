"""OG tag extraction from a Playwright page object."""
from typing import Optional
from urllib.parse import urljoin

from playwright.async_api import Page


async def extract_og_tags(page: Page, base_url: str) -> tuple[Optional[str], Optional[str]]:
    """Return (og_title, og_image) from the page's Open Graph meta tags.

    Both values default to None when the tag is absent or unreadable.
    *og_image* is resolved to an absolute URL using *base_url*.
    """
    og_title: Optional[str] = None
    og_image: Optional[str] = None

    try:
        og_title = await page.locator('meta[property="og:title"]').get_attribute(
            "content", timeout=3000
        )
    except Exception:
        pass

    try:
        raw_img = await page.locator('meta[property="og:image"]').get_attribute(
            "content", timeout=3000
        )
        if raw_img:
            og_image = urljoin(base_url, raw_img)
    except Exception:
        pass

    return og_title, og_image
