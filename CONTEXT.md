# Context

## Domain glossary

- **Account** — a locally stored Pixiv login entry that can become the active session.
- **Token** — the Pixiv access token and refresh token pair used for authenticated API requests.
- **Work** — a Pixiv illustration or manga item shown in feeds, detail pages, and bookmarks.
- **Bookmark** — the saved relationship between an account and a work, with public/private visibility.
- **Feed** — a paginated list of works such as following, recommendation, ranking, search, or user works.
- **Download** — an explicit image save requested by the user and tracked through `requestMgr`.
- **Cache** — a local file or network cache entry used to speed up thumbnails and repeated image fetches.
- **Request Lock** — the global QML flag that prevents overlapping feed requests while a page is already loading.
