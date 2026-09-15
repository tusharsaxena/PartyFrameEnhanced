-- tests/test_vendor_sync.lua — the vendored-payload gate (testing-§11). The implementation ships in
-- the payload it checks (tests/_kit/vendor_sync.lua): it asserts libs/LibKa0s/ and tests/_kit/ are
-- byte-identical to what the LibKa0s repo published at the tag CLAUDE.md's provenance line names,
-- and that the automated-test runner is recorded 100755 in the index. A missing sibling checkout is
-- a SKIP with its reason, never a pass.

local VendorSync = dofile("tests/_kit/vendor_sync.lua")

VendorSync.register(_G.PFE_TEST, {})
