const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const RADIUS_KM = 3;

function toNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function distanceKm(lat1, lon1, lat2, lon2) {
  const rad = value => value * Math.PI / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

exports.notifyNearbyCitizensOfHazard = onDocumentCreated(
  { document: 'blocked_road_reports/{reportId}', region: 'asia-south1' },
  async event => {
    const report = event.data?.data();
    if (!report) return;
    const reportLat = toNumber(report.latitude);
    const reportLon = toNumber(report.longitude);
    if (reportLat === null || reportLon === null) return;

    const usersSnapshot = await db.collection('users').get();
    const messages = [];
    for (const userDoc of usersSnapshot.docs) {
      if (userDoc.id === report.citizenId) continue;
      const user = userDoc.data();
      const lat = toNumber(user.profileLatitude ?? user.latitude);
      const lon = toNumber(user.profileLongitude ?? user.longitude);
      if (lat === null || lon === null) continue;
      if (distanceKm(reportLat, reportLon, lat, lon) > RADIUS_KM) continue;
      const tokens = Array.isArray(user.fcmTokens)
        ? user.fcmTokens.filter(token => typeof token === 'string' && token.length > 0)
        : (typeof user.fcmToken === 'string' ? [user.fcmToken] : []);
      if (tokens.length === 0) continue;
      const description = String(report.description || 'A hazard has been reported nearby.').slice(0, 120);
      for (let i = 0; i < tokens.length; i += 500) {
        messages.push({
          tokens: tokens.slice(i, i + 500),
          notification: {
            title: 'Hazard reported near you',
            body: `${description} Please open ResQNet to verify the report.`,
          },
          data: {
            type: 'hazard_verification',
            reportId: event.params.reportId,
          },
          android: { priority: 'high', notification: { channelId: 'resqnet_hazards' } },
        });
      }
    }

    for (const message of messages) {
      const result = await getMessaging().sendEachForMulticast(message);
      const invalid = [];
      result.responses.forEach((response, index) => {
        if (!response.success && [
          'messaging/invalid-registration-token',
          'messaging/registration-token-not-registered',
        ].includes(response.error?.code)) invalid.push(message.tokens[index]);
      });
      if (invalid.length) {
        const batch = db.batch();
        for (const userDoc of usersSnapshot.docs) {
          const user = userDoc.data();
          const tokens = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
          const stale = tokens.filter(token => invalid.includes(token));
          if (stale.length) batch.update(userDoc.ref, { fcmTokens: tokens.filter(token => !stale.includes(token)) });
        }
        await batch.commit();
      }
    }
  }
);
