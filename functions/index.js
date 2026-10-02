const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyStudentsQueueUsers = onDocumentUpdated(
  "students/{studentId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const movedToAdvising =
      before.status !== "WAITING_ADVISING" &&
      after.status === "WAITING_ADVISING";
    const paperPrinted =
      before.materialsPrinted !== true && after.materialsPrinted === true;

    if (!movedToAdvising && !paperPrinted) {
      return;
    }

    const tokensSnapshot = await admin
      .firestore()
      .collection("notification_tokens")
      .get();
    const tokenEntries = tokensSnapshot.docs
      .map((doc) => ({ ref: doc.ref, token: doc.data().token }))
      .filter(({ token }) => typeof token === "string" && token.length > 0);
    const tokens = tokenEntries.map(({ token }) => token);

    if (tokens.length === 0) {
      logger.info("No notification devices are registered.");
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: movedToAdvising
          ? "تحويل طالب للإرشاد الأكاديمي"
          : "تمت طباعة ورقة تسجيل المواد",
        body: movedToAdvising
          ? `تم تحويل ${after.name || "طالب"} إلى الإرشاد الأكاديمي`
          : `تم تسجيل طباعة ورقة تسجيل المواد للطالب ${after.name || ""}`,
      },
      data: {
        studentId: event.params.studentId,
        status: after.status,
        event: movedToAdvising ? "advising" : "materials_printed",
      },
    });

    const invalidTokenRefs = [];
    response.responses.forEach((result, index) => {
      if (!result.success) {
        const code = result.error && result.error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokenRefs.push(tokenEntries[index].ref);
        }
      }
    });

    await Promise.all(invalidTokenRefs.map((ref) => ref.delete()));
    logger.info("Queue notification sent.", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);
