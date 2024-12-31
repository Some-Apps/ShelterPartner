const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { PubSub } = require('@google-cloud/pubsub');

admin.initializeApp();

const projectId = "development-e5282";
const scheduledReportTopicName = 'scheduled-report-topic';

// Initialize Pub/Sub client outside the function handler
const pubSubClient = new PubSub({ projectId });

exports.scheduleReportInvoker = functions.https.onRequest(async (req, res) => {
    console.log('Function triggered by Pub/Sub message:', req.body.message.messageId);

    const now = new Date();
    const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const currentDayOfWeek = daysOfWeek[now.getDay()];
    const currentDayOfMonth = now.getDate();

    try {
        console.log('Fetching shelters from Firestore...');
        const sheltersSnapshot = await admin.firestore().collection('shelters').get();
        console.log(`Fetched ${sheltersSnapshot.size} shelters.`);

        for (const doc of sheltersSnapshot.docs) {
            const shelterData = doc.data();
            const shelterId = doc.id;
            console.log(`Processing shelter: ${shelterId}`);

            const shelterSettings = shelterData.shelterSettings || {};
            const scheduledReports = shelterSettings.scheduledReports || [];
            console.log(`Found ${scheduledReports.length} scheduled reports.`);

            for (const report of scheduledReports) {
                console.log('Processing report:', report);
                const frequency = report.frequency;
                let shouldSend = false;

                if (frequency === 'Daily') {
                    shouldSend = true;
                } else if (frequency === 'Weekly' && report.dayOfWeek === currentDayOfWeek) {
                    shouldSend = true;
                } else if (frequency === 'Monthly' && parseInt(report.dayOfMonth, 10) === currentDayOfMonth) {
                    shouldSend = true;
                }

                console.log('Should send report:', shouldSend);

                if (shouldSend) {
                    const reportWithShelterId = {
                        ...report,
                        shelterId: shelterId,
                    };
                    const dataBuffer = Buffer.from(JSON.stringify(reportWithShelterId));

                    try {
                        const messageId = await pubSubClient
                            .topic(scheduledReportTopicName)
                            .publish(dataBuffer);
                        console.log(`Published message ID: ${messageId} for report ID: ${report.id || 'N/A'}`);
                    } catch (error) {
                        console.error(`Error publishing message for report ${report.id || 'N/A'}:`, error);
                    }
                }
            }
        }

        console.log('Function completed successfully.');
        res.status(200).send('Function completed successfully');
    } catch (error) {
        console.error('Error processing message:', error);
        res.status(500).send('Error processing message');
    }
});
