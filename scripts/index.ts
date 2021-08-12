import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

export const sendToDevice = functions.firestore
    .document("transaction/{transactionId}")
    .onCreate(async (snapshot) => {
      const transactionSnapshot = snapshot;

      const data = transactionSnapshot.data();
      if (data != null) {
        const userId = data.userId;
        const userSnapshot = await db
            .collection("user-data")
            .doc(userId)
            .get();
        const userData = userSnapshot.data();
        if (userData != null) {
          const userToken = userData.token;
          const payload: admin.messaging.Message = {
            token: userToken,
            notification: {
              title: "Transaksi Baru!",
              body: "Transaksimu telah tercatat di database kami.",
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              title: "Transaksi Baru!",
              body: "Transaksimu telah tercatat di database kami.",
            },
            android: {
              priority: "high",
            },
            apns: {
              headers: {
                "apns-priority": "5",
              },
            },
          };
          const result = await fcm.send(payload);
          return result;
        }
      }
      return "Not Found!";
    });
