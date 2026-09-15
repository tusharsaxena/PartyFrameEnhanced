# Common tasks

Recipes for the changes this addon actually gets. Each ends at the green gate: `lua tests/run.lua`
and `luacheck .`.

## Add a setting

1. Add the default to `defaults/Profile.lua` under the right section.
2. Add a schema row in that page's `settings/<Page>.lua`: `path`, `page`, `group` (the tab), `order`,
   `type`, `label`, `desc`, `default`. A font, border or bar block comes from `H.FontGroup` /
   `H.BorderGroup` / `H.BarGroup`, never typed out; a color row comes with its class-color companion
   (`H.ColorPair`).
3. Add the `label` and `desc` strings to `locales/enUS.lua`.
4. If the element must react beyond a restyle, add an `onChange`. The seam already publishes
   `CONFIG(<section>)`; features cache config into upvalues on it.
5. If the row's page has a degraded-count pin (`tests/test_optionssetup.lua`), update the count.
6. Regenerate `docs/test-cases.md` if a case changed; update `docs/settings-panel.md` and
   `docs/schema.md`.

## Add a slash verb

1. Append a positional triple `{ "verb", "description", function(rest) … end }` to `NS.COMMANDS` in
   `settings/Slash.lua`. Reserved verbs keep their collection-wide meaning.
2. Anything it changes goes through `NS.SetByPath`, never a table write.
3. Add a case to `tests/test_slash.lua`; update `docs/slash-dispatch.md`.

## Add a frame system (provider)

1. Add a provider table to `modules/Providers.lua` (plan P2): `id`, `label`, `priority`,
   `IsAvailable`, `IsActive`, `ForEachFrame`, `InstallHooks`. Presence-guard it; hooks are
   `hooksecurefunc` / `HookScript` only.
2. List the addon in the TOC's `## OptionalDeps:`.
3. Add its value to `general.provider`'s dropdown and its label to `locales/enUS.lua`.
4. Test detection, unit reading (including a secret attribute) and a re-sort.

## Add a perf bracket

1. Declare the bucket (and its `within`) in `core/PerfSetup.lua`.
2. Bracket with `local t0 = Perf.on and debugprofilestop()` … `if t0 then Perf.Note(key, …) end`,
   using the file-scope `local Perf = NS.Perf`.
3. Update `docs/performance.md`; `tests/test_perfsetup.lua` pins the declared list.

## Add a locale string

Use `L["English text"]` at the call site and add `L["English text"] = "English text"` to
`locales/enUS.lua`. Match game data on ids and tokens (class **token**, not the localized class name),
never on a display string (localization-§4).

## Re-vendor LibKa0s

Never from the sibling's working tree: `git -C ../LibKa0s archive <tag> LibKa0s testkit | tar -x -C
<tmp>`, copy both folders whole, move the `CLAUDE.md` provenance line in the same commit, run the
gate. `/wow-addon:revendor-libka0s` does it all.
