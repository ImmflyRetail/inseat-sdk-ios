# Changelog — iOS SDK

All notable changes to the iOS SDK will be documented in this file.

## [1.1.0]

### Added
- Initialization data is now cached locally — the network call is skipped on subsequent app launches until the cache expires
- Product JSON downloads are now authenticated
- Product sync now uses ETag — unchanged product data is no longer re-downloaded
- `lastProductUpdateDate` — indicates when product data was last successfully updated
- New observers for menus and categories

### Changed
- Improved product sync reliability and timing

### Fixed
- `lastProductUpdateDate` now correctly reflects the time product data was last successfully applied
- Stale promotion images are cleaned up when new product data is processed
- Invalid shop documents are now detected and removed
- Promotions are correctly sorted, falling back to name when no sort order is defined
- Thread-safety improvements and bug fixes
- Performance improvements

---

## [1.0.3]

### Fixed
- Thread-safety improvements and bug fixes

---

## [1.0.2]

### Fixed
- Bug fixes and performance improvements

---

## [1.0.1]

### Fixed
- Bug fixes and performance improvements

---

## [1.0.0]

- Initial release
