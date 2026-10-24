"""Builds MagnaVita and publishes it to https://ruva-releases.vercel.app.

Usage (from frontend/):  python tool/release.py "What changed"

- The build number is the git commit count, so every release is newer
  than the last (Android only installs updates with a higher number).
- Release builds carry NO API keys: the Gemini key is entered on the phone
  (Settings → Meal photo estimates) and survives updates.
- The app reads version.json on launch and offers "New version available".
- The version name is SERIES.NNN: NNN counts commits since the series began
  (small changes). For a bigger release, bump SERIES and set SERIES_FROM to
  the current commit count, so the next release is SERIES.001.
"""
import json
import os
import shutil
import subprocess
import sys

URL = 'https://ruva-releases.vercel.app'
SERIES, SERIES_FROM = '1.2', 76  # build 77 was 1.2.001
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SITE = os.path.join(ROOT, 'release_site')


def run(*cmd):
    print('>', ' '.join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True, shell=os.name == 'nt')


def main():
    notes = sys.argv[1] if len(sys.argv) > 1 else ''
    if subprocess.run(['git', 'status', '--porcelain', 'lib'], cwd=ROOT, capture_output=True, text=True).stdout.strip():
        sys.exit('Commit your changes first: the build number comes from the commit count.')
    build = int(subprocess.run(['git', 'rev-list', '--count', 'HEAD'], cwd=ROOT, capture_output=True, text=True,
                               check=True).stdout.strip())
    version = f'{SERIES}.{build - SERIES_FROM:03d}'

    run('flutter', 'build', 'apk', '--release', '--split-per-abi', f'--build-name={version}', f'--build-number={build}',
        f'--dart-define=BUILD_NUMBER={build}', f'--dart-define=VERSION_NAME={version}', f'--dart-define=UPDATE_URL={URL}')

    # Fresh files each time, but keep release_site/.vercel (the project link).
    os.makedirs(SITE, exist_ok=True)
    for name in os.listdir(SITE):
        if not name.startswith('.'):
            os.remove(os.path.join(SITE, name))
    apk = f'magnavita-{build}.apk'
    shutil.copy(os.path.join(ROOT, 'build', 'app', 'outputs', 'flutter-apk', 'app-arm64-v8a-release.apk'),
                os.path.join(SITE, apk))
    with open(os.path.join(SITE, 'version.json'), 'w', encoding='utf-8') as f:
        json.dump({'build': build, 'version': version, 'apk': apk, 'notes': notes}, f)
    with open(os.path.join(SITE, 'vercel.json'), 'w', encoding='utf-8') as f:
        json.dump({'headers': [
            {'source': '/(.*)', 'headers': [{'key': 'X-Robots-Tag', 'value': 'noindex'}]},
            {'source': '/version.json', 'headers': [{'key': 'Cache-Control', 'value': 'no-store'}]},
            {'source': '/(.*).apk', 'headers': [{'key': 'Content-Type', 'value': 'application/vnd.android.package-archive'}]},
        ]}, f)
    with open(os.path.join(SITE, 'index.html'), 'w', encoding='utf-8') as f:
        f.write(f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex"><title>MagnaVita</title>
<style>
  body {{ margin: 0; font-family: system-ui, sans-serif; background: #F6FCEF; color: #1A2A20; }}
  main {{ max-width: 420px; margin: 0 auto; padding: 48px 20px; text-align: center; }}
  h1 {{ color: #135D44; margin: 0 0 4px; }}
  a.btn {{ display: inline-block; margin: 24px 0 12px; padding: 14px 28px; border-radius: 999px;
          background: #135D44; color: #fff; text-decoration: none; font-weight: 600; }}
  p.small {{ color: #4C5A50; font-size: 14px; }}
</style></head>
<body><main>
  <h1>MagnaVita</h1>
  <p class="small">Version {version}{(' · ' + notes) if notes else ''}</p>
  <a class="btn" href="{apk}">Download for Android</a>
  <p class="small">Open the downloaded file and tap <b>Update</b>. Your data stays on your phone.</p>
</main></body></html>
''')
    run('npx', '--yes', 'vercel', 'deploy', 'release_site', '--prod', '--yes')
    print(f'Published {version} (build {build}): {URL}')


if __name__ == '__main__':
    main()
