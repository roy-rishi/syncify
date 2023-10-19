pyinstaller --name 'Syncify' \
            --icon 'img/syncify.icns' \
            --windowed  \
            --add-data='venv/lib/*/site-packages:.' \
            --path venv/lib/*/site-packages \
            syncify.py
