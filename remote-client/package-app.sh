pyinstaller --name 'Syncify' \
            --icon 'img/syncify.icns' \
            --windowed  \
            --add-data='venv/lib/python3.11/site-packages:.' \
            --path venv/lib/python3.11/site-packages \
            syncify.py
