const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Triggered whenever a notification document is written to a household.
 * Dispatches an FCM topic push notification to `household_{householdId}`
 * so all flatmates receive high-priority system alerts even when the app
 * is killed or in the background.
 */
exports.dispatchHouseholdNotification = onDocumentCreated(
  "households/{householdId}/notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const householdId = event.params.householdId;
    const notificationId = event.params.notificationId;

    const title = data.title || "CoSpend Update";
    const body = data.body || "New activity in your flat";
    const payerId = data.payerId || "";

    const message = {
      topic: `household_${householdId}`,
      notification: {
        title,
        body,
      },
      data: {
        notificationId,
        householdId,
        payerId,
        route: "/home",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "cospend_expenses",
          sound: "default",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log(`[FCM] Successfully dispatched message to topic household_${householdId}: ${response}`);
    } catch (error) {
      console.error(`[FCM] Error dispatching notification to topic household_${householdId}:`, error);
    }
  }
);
