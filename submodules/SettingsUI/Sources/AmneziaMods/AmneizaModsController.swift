import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import PresentationDataUtils

// MARK: - Экран Amnezia Mods (пустая вкладка)
public func amneziaCustomSettingsScreen(context: AccountContext) -> ViewController {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    
    let controller = ViewController()
    controller.title = "Amnezia Mods"
    controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
    controller.view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    
    // Создаем контейнер для центра
    let containerView = UIView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    controller.view.addSubview(containerView)
    
    // Заголовок
    let titleLabel = UILabel()
    titleLabel.text = "🚀 Amnezia Mods"
    titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .black
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(titleLabel)
    
    // Подзаголовок
    let subtitleLabel = UILabel()
    subtitleLabel.text = "Настройки будут здесь"
    subtitleLabel.font = UIFont.systemFont(ofSize: 16)
    subtitleLabel.textAlignment = .center
    subtitleLabel.textColor = .gray
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(subtitleLabel)
    
    // Иконка
    let emojiLabel = UILabel()
    emojiLabel.text = "⚙️"
    emojiLabel.font = UIFont.systemFont(ofSize: 60)
    emojiLabel.textAlignment = .center
    emojiLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(emojiLabel)
    
    // Версия
    let versionLabel = UILabel()
    versionLabel.text = "v1.0.0"
    versionLabel.font = UIFont.systemFont(ofSize: 12)
    versionLabel.textAlignment = .center
    versionLabel.textColor = .lightGray
    versionLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(versionLabel)
    
    // Центрируем
    NSLayoutConstraint.activate([
        containerView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
        containerView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
        
        emojiLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
        emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        
        titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 16),
        titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        
        versionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
        versionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        versionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
    
    return controller
}
