# SHU-20 notes

## navbar_*.png investigation
`navbar_*.png` was produced by an **isolated component test**: a stub `Scaffold` with title `"Nav"`, body `Text('body')`, and `MainNavBar` only. It was never a full screen. Renamed to `navbar_component_*.png`. Full NavigationBar+content coverage is `home_*.png` (HomeScreen already embeds `MainNavBar`).

## Coverage added
| Golden prefix | Variants | Notes |
|---|---|---|
| home_ | light/dark/fa_rtl | banner shown (remote not configured in fixture) |
| home_banner_dismissed_ | light/dark/fa_rtl | pref `setup_git_host_banner_dismissed=true` |
| navbar_component_ | light/dark/fa_rtl | isolated MainNavBar (renamed) |
| settings_ | light/dark/fa_rtl | existing |
| editor_ | light/dark/fa_rtl | existing |
| folders_ | light/dark/fa_rtl | FolderListingScreen |
| tags_ | light/dark/fa_rtl | TagListingScreen |
| onboarding_ | light/dark/fa_rtl | OnBoardingScreen |
| git_terminal_ | light/dark/fa_rtl | GitTerminalScreen |
| login_ | light/dark/fa_rtl | LoginPage shell; Supabase init errors ignored offline |
| dialog_rename_ | light/dark | RTL skipped (AlertDialog trivial) |
| dialog_delete_note_ | light/dark | RTL skipped |
| dialog_sorting_ | light/dark | RTL skipped |
| dialog_folder_selection_ | light/dark | RTL skipped |

## Follow-ups (NOT fixed in SHU-20)
- Home: double top bar (Setup Git Host banner + app bar), missing note titles, FAB/icon menu overlapping content
- Settings: mixed filled vs outlined icons after icon consolidation

## Gallery
`dart run tool/generate_golden_gallery.dart` → `test/golden/gallery/index.html` (file://)
