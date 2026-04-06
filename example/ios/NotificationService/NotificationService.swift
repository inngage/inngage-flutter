import UserNotifications
import FirebaseMessaging

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let bestAttemptContent = self.bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        Messaging.serviceExtension().populateNotificationContent(
            bestAttemptContent,
            withContentHandler: contentHandler
        )
    }

    override func serviceExtensionTimeWillExpire() {
        guard let contentHandler = contentHandler,
              let bestAttemptContent = bestAttemptContent else {
            return
        }

        contentHandler(bestAttemptContent)
    }
}