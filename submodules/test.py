#!/usr/bin/env python3
"""
Финальный сбор контекста для добавления кастомного пункта в Settings.
Запускать из ~/amneziafrok/Telegram-iOS
"""
import subprocess
from pathlib import Path

TASKS = [
    ("PeerInfoScreen.swift — enum секций (120-200)",
     ["sed", "-n", "120,200p",
      "./submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift"]),
    ("PeerInfoSettingsItems.swift — начало файла (импорты + сигнатура функции)",
     ["sed", "-n", "1,40p",
      "./submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoSettingsItems.swift"]),
    ("PeerInfoSettingsItems.swift — контекст вокруг powerSaving item (200-260)",
     ["sed", "-n", "200,260p",
      "./submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoSettingsItems.swift"]),
    ("PresentationResourcesSettings.swift — как объявлены иконки",
     ["sed", "-n", "1,40p",
      "./submodules/TelegramPresentationData/Sources/Resources/PresentationResourcesSettings.swift"]),
    ("PeerInfoScreenDisclosureItem.swift — сигнатура инициализатора",
     ["sed", "-n", "1,60p",
      "./submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenDisclosureItem.swift"]),
]

def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        return r.stdout.strip() or "(пусто)"
    except Exception as e:
        return f"Ошибка: {e}"

def main():
    lines = [f"=== Финальный контекст: {Path.cwd()} ===\n"]
    for title, cmd in TASKS:
        lines.append("-"*70)
        lines.append(f"### {title}")
        lines.append(f"$ {' '.join(cmd)}")
        lines.append("-"*70)
        lines.append(run(cmd))
        lines.append("")
    print("\n".join(lines))

if __name__ == "__main__":
    main()