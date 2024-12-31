const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { PubSub } = require('@google-cloud/pubsub');

admin.initializeApp();

const projectId = "development-e5282";

// Initialize Pub/Sub client outside the function handler
const pubSubClient = new PubSub({ projectId });

exports.shelterApiKeyPublisher = functions.https.onRequest(async (req, res) => {
    console.log('Function triggered by Pub/Sub message.');

    try {
        console.log('Fetching shelters from Firestore...');
        const sheltersSnapshot = await admin.firestore().collection('shelters').get();
        console.log(`Fetched ${sheltersSnapshot.size} shelters.`);

        for (const doc of sheltersSnapshot.docs) {
            const shelterData = doc.data();
            const shelterId = doc.id;
            console.log(`Processing shelter: ${shelterId}`);

            const managementSoftware = shelterData.managementSoftware;
            if (managementSoftware) {
                let topicName;
                let data; // Initialize data variable

                if (managementSoftware === 'ShelterLuv') {
                    const apiKey = shelterData.shelterSettings.apiKey;
                    if (!apiKey || apiKey.trim() === '') {
                        console.log(`No apiKey for shelter ${shelterId}`);
                        continue;
                    }
                    topicName = 'shelterLuv-sync-topic';
                    data = { apiKey: apiKey, shelterId: shelterId };
                } else if (managementSoftware === 'ShelterManager') {
                    const username = shelterData.shelterSettings.asmUsername;
                    const password = shelterData.shelterSettings.asmPassword;
                    const account = shelterData.shelterSettings.asmAccountNumber;
                    topicName = 'asm-sync-topic';
                    data = { 
                        username: username, 
                        password: password, 
                        account: account, 
                        shelterId: shelterId 
                    };
                    if (!username || username.trim() === '') {
                        console.log(`No apiKey for shelter ${shelterId}`);
                        continue;
                    }
                } else if (managementSoftware === 'Animals First') {
                    const apiKey = shelterData.shelterSettings.apiKey;
                    if (!apiKey || apiKey.trim() === '') {
                        console.log(`No apiKey for shelter ${shelterId}`);
                        continue;
                    }
                    topicName = 'animals-first-topic';
                    data = { apiKey: apiKey, shelterId: shelterId };
                } else {
                    console.log(`Unknown management software for shelter ${shelterId}: ${managementSoftware}`);
                    continue;
                }

                const dataBuffer = Buffer.from(JSON.stringify(data));

                try {
                    const messageId = await pubSubClient
                        .topic(topicName)
                        .publish(dataBuffer);
                    console.log(`Published message ID: ${messageId} for shelter ID: ${shelterId}`);
                } catch (error) {
                    console.error(`Error publishing message for shelter ${shelterId}:`, error);
                }
            } else {
                console.log(`No managementSoftware for shelter ${shelterId}`);
            }
        }

        console.log('Function completed successfully.');
        res.status(200).send('Function completed successfully');
    } catch (error) {
        console.error('Error processing message:', error);
        res.status(500).send('Error processing message');
    }
});
