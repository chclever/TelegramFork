#!/usr/bin/env python3
import os
import subprocess
import json
from datetime import datetime

def run_command(cmd):
    """Выполняет команду и возвращает вывод"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        return f"Error: {e}"

def collect_files():
    """Собирает информацию о файлах"""
    
    print("🔍 Сбор информации о проекте Telegram iOS...")
    print("=" * 60)
    
    # 1. Информация о структуре
    info = {
        "timestamp": datetime.now().isoformat(),
        "project_root": os.getcwd()
    }
    
    # 2. Список всех файлов в SettingsUI
    print("\n📁 1. Структура SettingsUI:")
    print("-" * 40)
    settingsui_files = run_command("find submodules/SettingsUI/Sources -name '*.swift' | sort")
    print(settingsui_files)
    
    # 3. Основной файл настроек
    print("\n📄 2. SettingsController.swift (первые 200 строк):")
    print("-" * 40)
    settings_controller = run_command("head -200 submodules/SettingsUI/Sources/SettingsController.swift")
    print(settings_controller)
    
    # 4. Поиск пункта "Amnezia"
    print("\n🔍 3. Поиск 'Amnezia' в коде:")
    print("-" * 40)
    amnezia_search = run_command("grep -r 'Amnezia\\|amneziamods' submodules/SettingsUI/Sources/ --include='*.swift' | head -50")
    print(amnezia_search if amnezia_search else "Не найдено")
    
    # 5. Файлы AmneziaMods
    print("\n📂 4. Файлы AmneziaMods:")
    print("-" * 40)
    amnezia_files = run_command("ls -la submodules/SettingsUI/Sources/AmneziaMods/ 2>/dev/null || echo 'Папка не существует'")
    print(amnezia_files)
    
    # 6. Содержимое AmneziaMods Controller
    print("\n📄 5. AmneizaModsController.swift:")
    print("-" * 40)
    amnezia_controller = run_command("cat submodules/SettingsUI/Sources/AmneziaMods/AmneizaModsController.swift 2>/dev/null || echo 'Файл не найден'")
    print(amnezia_controller)
    
    # 7. BUILD.bazel
    print("\n📄 6. BUILD.bazel для SettingsUI:")
    print("-" * 40)
    build_file = run_command("cat submodules/SettingsUI/BUILD.bazel 2>/dev/null || echo 'Файл не найден'")
    print(build_file)
    
    # 8. PeerInfoScreenSettingsActions (где вы добавляли пункт)
    print("\n📄 7. PeerInfoScreenSettingsActions.swift (с .amneziamods):")
    print("-" * 40)
    peerinfo_file = run_command("grep -A 20 -B 5 'case .amneziamods' submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenSettingsActions.swift 2>/dev/null || echo 'Файл не найден'")
    print(peerinfo_file)
    
    # 9. Все файлы с настройками
    print("\n📄 8. Другие файлы настроек:")
    print("-" * 40)
    other_settings = run_command("find submodules/SettingsUI/Sources -name '*Settings*.swift' | grep -v 'Bubble\\|Notification\\|Reaction\\|Translation' | head -10")
    print(other_settings)
    
    # 10. Структура проекта (первые 2 уровня)
    print("\n📁 9. Структура проекта (TelegramUI/Settings):")
    print("-" * 40)
    project_structure = run_command("ls -la submodules/TelegramUI/Components/ 2>/dev/null | head -30")
    print(project_structure)
    
    # 11. Поиск места добавления пунктов меню
    print("\n🔍 10. Поиск функций создания пунктов меню:")
    print("-" * 40)
    menu_items = run_command("grep -r 'func.*items\\|SettingsBlockItem\\|SettingsButtonItem' submodules/SettingsUI/Sources/SettingsController.swift | head -30")
    print(menu_items)
    
    # 12. Версия Xcode и Swift
    print("\n🛠️ 11. Информация о среде:")
    print("-" * 40)
    xcode_version = run_command("xcodebuild -version 2>/dev/null || echo 'Xcode not found'")
    swift_version = run_command("swift --version 2>/dev/null || echo 'Swift not found'")
    print(f"Xcode: {xcode_version[:200]}")
    print(f"Swift: {swift_version[:200]}")
    
    print("\n" + "=" * 60)
    print("✅ Сбор информации завершен!")
    print("📋 Скопируйте этот вывод и отправьте мне.")

if __name__ == "__main__":
    collect_files()
