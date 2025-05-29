const { Firestore } = require('@google-cloud/firestore');
const csvWriter = require('csv-writer').createObjectCsvWriter;
const nodemailer = require('nodemailer');
const moment = require('moment-timezone');
const path = require('path');
const os = require('os');

// Initialize Firestore
const db = new Firestore();
console.log('Initialized Firestore client.');

/**
 * Cloud Function to generate and send animal activity reports.
 * @param {Object} req - The HTTP request object.
 * @param {Object} res - The HTTP response object.
 */
exports.scheduledReport = async (req, res) => {
    console.log('Function `scheduledReport` invoked.');

    try {
        const requestJson = req.body;
        console.log('Request body received:', JSON.stringify(requestJson));

        // Validate request body
        if (!requestJson || !requestJson.message || !requestJson.message.data) {
            console.error('Invalid request: Missing `message` or `data` field.');
            res.status(400).send('Invalid request: Missing `message` or `data` field.');
            return;
        }
        console.log('Request body is valid.');

        // Decode base64 data
        let decodedData;
        try {
            decodedData = Buffer.from(requestJson.message.data, 'base64').toString('utf-8');
            console.log('Decoded data:', decodedData);
        } catch (decodeError) {
            console.error('Error decoding base64 data:', decodeError);
            res.status(400).send('Invalid data encoding.');
            return;
        }

        // Parse JSON
        let messageData;
        try {
            messageData = JSON.parse(decodedData);
            console.log('Parsed message data:', JSON.stringify(messageData));
        } catch (parseError) {
            console.error('Error parsing JSON data:', parseError);
            res.status(400).send('Invalid JSON data.');
            return;
        }

        const shelterId = messageData.shelterId;
        const email = messageData.email;
        const frequency = messageData.frequency;

        console.log(`Extracted Parameters - Shelter ID: ${shelterId}, Email: ${email}, Frequency: ${frequency}`);

        // Validate required parameters
        if (!shelterId || !email || !frequency) {
            console.error('Missing `shelterId`, `email`, or `frequency` in message data.');
            res.status(400).send('shelterId, email, or frequency missing');
            return;
        }

        // Define Chicago timezone
        const chicagoTz = 'America/Chicago';
        console.log(`Timezone set to ${chicagoTz}.`);

        // Determine date range
        const today = moment().tz(chicagoTz).startOf('day');
        let startDate;

        switch (frequency) {
            case 'Daily':
                startDate = moment(today).subtract(1, 'days');
                break;
            case 'Weekly':
                startDate = moment(today).subtract(7, 'days');
                break;
            case 'Monthly':
                startDate = moment(today).subtract(30, 'days');
                break;
            default:
                console.error('Invalid frequency:', frequency);
                res.status(400).send('Invalid frequency');
                return;
        }

        console.log(`Date Range - Start Date: ${startDate.format()}, End Date: ${today.format()}`);

        // Fetch shelter and animal data
        console.log(`Fetching data for Shelter ID: ${shelterId}`);

        const shelterRef = db.collection('shelters').doc(shelterId);

        let catsSnapshot, dogsSnapshot;
        try {
            [catsSnapshot, dogsSnapshot] = await Promise.all([
                shelterRef.collection('cats').get(),
                shelterRef.collection('dogs').get()
            ]);
            console.log(`Fetched ${catsSnapshot.size} Cat documents and ${dogsSnapshot.size} Dog documents.`);
        } catch (firestoreError) {
            console.error('Error fetching data from Firestore:', firestoreError);
            res.status(500).send('Error fetching data from Firestore.');
            return;
        }

        let animalsData = [];

        // Process Cats
        console.log('Processing Cat documents...');
        catsSnapshot.forEach(doc => {
            console.log(`Processing Cat Document ID: ${doc.id}`);
            const data = fetchAnimalData(doc, 'Cat', startDate, today);
            if (data) {
                console.log(`Cat Document ID ${doc.id} has relevant data.`);
                animalsData.push(data);
            } else {
                console.log(`Cat Document ID ${doc.id} has no relevant data.`);
            }
        });

        // Process Dogs
        console.log('Processing Dog documents...');
        dogsSnapshot.forEach(doc => {
            console.log(`Processing Dog Document ID: ${doc.id}`);
            const data = fetchAnimalData(doc, 'Dog', startDate, today);
            if (data) {
                console.log(`Dog Document ID ${doc.id} has relevant data.`);
                animalsData.push(data);
            } else {
                console.log(`Dog Document ID ${doc.id} has no relevant data.`);
            }
        });

        console.log(`Total animals with relevant data: ${animalsData.length}`);

        if (animalsData.length === 0) {
            console.log('No data to report for the specified period.');
            res.status(200).send('No data to report for the specified period.');
            return;
        }

        // Generate CSV file
        const csvFilePath = path.join(os.tmpdir(), 'animal_activity_report.csv');
        console.log(`Generating CSV file at: ${csvFilePath}`);

        const writer = csvWriter({
            path: csvFilePath,
            header: [
                { id: 'id', title: 'ID' },
                { id: 'name', title: 'Name' },
                { id: 'species', title: 'Species' },
                { id: 'noteDate', title: 'Note Date' },
                { id: 'noteAuthor', title: 'Note Author' },
                { id: 'note', title: 'Note' },
                { id: 'logType', title: 'Log Type' },
                { id: 'logStart', title: 'Log Start' },
                { id: 'logEnd', title: 'Log End' },
                { id: 'logDuration', title: 'Log Duration (minutes)' },
                { id: 'logAuthor', title: 'Log Author' },
                { id: 'photoUrl', title: 'Photo URL' } // Added photos column
            ]
        });

        const records = [];

        animalsData.forEach(animal => {
            console.log(`Adding records for Animal ID: ${animal.id}, Name: ${animal.name}, Species: ${animal.species}`);
            let isFirstRowForAnimal = true;

            //Format tags for dispaly
            const formattedTags = animal.tags ? animal.tags.map(tag => `(${tag.name} : ${tag.count})`).join(', ') : '';

            // Add header row for the animal 
            records.push({
                id: isFirstRowForAnimal ? animal.id : '',
                name: isFirstRowForAnimal ? animal.name : '',
                species: isFirstRowForAnimal ? animal.species : '',
                noteDate: '',
                noteAuthor: '',
                note: '',
                logType: '',
                logStart: '',
                logEnd: '',
                logDuration: '',
                logAuthor: '',
                photoUrl: formattedTags // Add formatted tags to the photoUrl column
            });
            // Process notes
            animal.notes.forEach(note => {
                records.push({
                    id: isFirstRowForAnimal ? animal.id : '',
                    name: isFirstRowForAnimal ? animal.name : '',
                    species: isFirstRowForAnimal ? animal.species : '',
                    noteDate: moment(note.timestamp.toDate()).format('MMM D'),
                    noteAuthor: note.author || '',
                    note: note.note || '',
                    logType: '',
                    logStart: '',
                    logEnd: '',
                    logDuration: '',
                    logAuthor: ''
                });
            });

            // Process notes
            animal.notes.forEach(note => {
                records.push({
                    id: isFirstRowForAnimal ? animal.id : '',
                    name: isFirstRowForAnimal ? animal.name : '',
                    species: isFirstRowForAnimal ? animal.species : '',
                    noteDate: moment(note.timestamp.toDate()).format('MMM D'),
                    noteAuthor: note.author || '',
                    note: note.note || '',
                    logType: '',
                    logStart: '',
                    logEnd: '',
                    logDuration: '',
                    logAuthor: '',
                    photoUrl: note.photoUrl || '' // Add photo URL if available
                });
            });

            // Process logs
            animal.logs.forEach(log => {
                const start = moment(log.startTime.toDate());
                const end = moment(log.endTime.toDate());
                const duration = Math.round(moment.duration(end.diff(start)).asMinutes());
                records.push({
                    id: isFirstRowForAnimal ? animal.id : '',
                    name: isFirstRowForAnimal ? animal.name : '',
                    species: isFirstRowForAnimal ? animal.species : '',
                    noteDate: '',
                    noteAuthor: '',
                    note: '',
                    logType: log.type || '',
                    logStart: start.format('MMM D HH:mm'),
                    logEnd: end.format('MMM D HH:mm'),
                    logDuration: duration,
                    logAuthor: log.author || '',
                    photoUrl: '' // No photo URL for logs
                });
                isFirstRowForAnimal = false;
            });
        });

        // Process photos
        animal.photos.forEach(photo => {
            records.push({
                id: isFirstRowForAnimal ? animal.id : '',
                name: isFirstRowForAnimal ? animal.name : '',
                species: isFirstRowForAnimal ? animal.species : '',
                noteDate: '',
                noteAuthor: '',
                note: '',
                logType: log.type || '',
                logStart: start.format('MMM D HH:mm'),
                logEnd: end.format('MMM D HH:mm'),
                logDuration: duration,
                logAuthor: log.author || '',
                photoUrl: photo.url || '' // Add photo URL if available
            });
        });

        console.log(`Total records to write to CSV: ${records.length}`);

        try {
            await writer.writeRecords(records);
            console.log('CSV file generated successfully.');
        } catch (csvError) {
            console.error('Error writing CSV file:', csvError);
            res.status(500).send('Error generating CSV file.');
            return;
        }

        // Generate HTML content for email body
        let htmlContent = '<h1>Animal Activity Report</h1>';
        htmlContent += '<p>See attachment for a more detailed report</p>';

        const catsData = animalsData.filter(animal => animal.species === 'Cat' && (animal.notes.length > 0 || animal.photos.length > 0));
        const dogsData = animalsData.filter(animal => animal.species === 'Dog' && (animal.notes.length > 0 || animal.photos.length > 0));

        // Process Cats for HTML content
        if (catsData.length > 0) {
            htmlContent += '<h2>Cats</h2>';
            catsData.forEach(animal => {
                htmlContent += `<h3>${animal.name}</h3>`;

                //Display formatted tags if available
                if (animal.tags && animal.tags.length > 0) {
                    htmlContent += `<p><strong>Tags:</strong>`;
                    htmlContent += animal.tags.map(tag => `(${tag.name} : ${tag.count})`).join(', ');
                    htmlContent += '</p>';
                }
                htmlContent += '<ul>';

                animal.notes.forEach(note => {
                    htmlContent += `<li>${note.note}</li>`;
                });

                animal.photos.forEach(photo => {
                    htmlContent += `<li><a href="${photo.url}">${photo.url}</a></li>`;
                });

                htmlContent += '</ul>';
            });
        }

        // Process Dogs for HTML content
        if (dogsData.length > 0) {
            htmlContent += '<h2>Dogs</h2>';
            dogsData.forEach(animal => {
                htmlContent += `<h3>${animal.name}</h3>`;

                //Display formatted tags if available
                if (animal.tags && animal.tags.length > 0) {
                    htmlContent += `<p><strong>Tags:</strong>`;
                    htmlContent += animal.tags.map(tag => `(${tag.name} : ${tag.count})`).join(', ');
                    htmlContent += '</p>';
                }
                htmlContent += '<ul>';

                animal.notes.forEach(note => {
                    htmlContent += `<li>${note.note}</li>`;
                });

                animal.photos.forEach(photo => {
                    htmlContent += `<li><a href="${photo.url}">${photo.url}</a></li>`;
                });

                htmlContent += '</ul>';
            });
        }

        // Send email with CSV attachment and HTML content
        console.log(`Sending email to: ${email}`);
        try {
            await sendEmailWithAttachment(email, csvFilePath, startDate, today, htmlContent);
            console.log('Email sent successfully.');
        } catch (emailError) {
            console.error('Error sending email:', emailError);
            res.status(500).send('Error sending email.');
            return;
        }

        res.status(200).send('Report generated and sent successfully');
    } catch (error) {
        console.error(`Unexpected Error: ${error.message}`, error);
        res.status(500).send(`Error generating report: ${error.message}`);
    }
};

/**
 * Fetches animal data within the specified date range.
 * @param {Object} doc - Firestore document.
 * @param {string} species - Species of the animal (Cat/Dog).
 * @param {Object} startDate - Start date (Moment object).
 * @param {Object} endDate - End date (Moment object).
 * @returns {Object|null} - Animal data or null if no relevant data.
 */
function fetchAnimalData(doc, species, startDate, endDate) {
    console.log(`Fetching data for ${species} ID: ${doc.id}`);
    const animal = doc.data();

    if (!animal) {
        console.warn(`No data found for ${species} ID: ${doc.id}`);
        return null;
    }

    const name = animal.name;

    if (!name) {
        console.warn(`No name found for ${species} ID: ${doc.id}`);
        return null;
    }

    const notes = animal.notes || [];
    const logs = animal.logs || [];
    const photos = animal.photos || [];
    const tags = animal.tags || [];

    // Filter notes within the date range
    const filteredNotes = notes.filter(note => {
        if (!note.timestamp) {
            console.warn(`Note without timestamp for ${species} ID: ${doc.id}`);
            return false;
        }
        const noteDate = moment(note.timestamp.toDate()).tz('America/Chicago');
        return noteDate.isBetween(startDate, endDate, null, '[]'); // Inclusive
    });

    console.log(`Filtered Notes for ${species} ID: ${doc.id}: ${filteredNotes.length}`);

    // Filter logs within the date range
    const filteredLogs = logs.filter(log => {
        if (!log.startTime) {
            console.warn(`Log without startTime for ${species} ID: ${doc.id}`);
            return false;
        }
        const logDate = moment(log.startTime.toDate()).tz('America/Chicago');
        return logDate.isBetween(startDate, endDate, null, '[]'); // Inclusive
    });

    console.log(`Filtered Logs for ${species} ID: ${doc.id}: ${filteredLogs.length}`);

    // Filter photos within the date range and uploaded from the app
    const filteredPhotos = photos.filter(photo => {
        if (!photo.timestamp) {
            console.warn(`Photo without timestamp for ${species} ID: ${doc.id}`);
            return false;
        }

        // Check if the photo was uploaded from the app
        const isFromApp = !photo.url?.includes('shelterluv');
        if (!isFromApp) {
            console.log(`Photo not uploaded from app for ${species} ID: ${doc.id}`);
            return false;
        }
        const photoDate = moment(photo.timestamp.toDate()).tz('America/Chicago');
        return photoDate.isBetween(startDate, endDate, null, '[]'); // Inclusive
    });

    console.log(`Filtered Photos for ${species} ID: ${doc.id}: ${filteredPhotos.length}`);

    if (filteredNotes.length > 0 || filteredLogs.length > 0 || filteredPhotos.length > 0) {
        return {
            id: doc.id,
            name: name,
            species: species,
            tags: tags,
            notes: filteredNotes,
            logs: filteredLogs,
            photos: filteredPhotos
        };
    }

    return null;
}

/**
 * Sends an email with the CSV attachment.
 * @param {string} toEmail - Recipient's email address.
 * @param {string} filePath - Path to the CSV file.
 * @param {Object} startDate - Start date (Moment object).
 * @param {Object} endDate - End date (Moment object).
 * @param {string} htmlContent - HTML content for the email body.
 */
async function sendEmailWithAttachment(toEmail, filePath, startDate, endDate, htmlContent) {
    console.log('Preparing to send email with attachment.');

    const emailUser = process.env.EMAILADDRESS;
    const emailPassword = process.env.EMAILPASSWORD;

    console.log('Email credentials retrieved from environment variables.');

    if (!emailUser || !emailPassword) {
        console.error('Email credentials are not set in environment variables.');
        throw new Error('Email credentials are not set in environment variables.');
    }

    const subject = `Animal Activity Report ${startDate.format('MMM D')} to ${endDate.format('MMM D')}`;
    console.log(`Email subject: ${subject}`);

    // Create transporter
    let transporter;
    try {
        transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: emailUser,
                pass: emailPassword
            }
        });
        console.log('Nodemailer transporter created successfully.');
    } catch (transporterError) {
        console.error('Error creating Nodemailer transporter:', transporterError);
        throw transporterError;
    }

    // Verify transporter connection configuration
    try {
        await transporter.verify();
        console.log('Nodemailer transporter verified successfully.');
    } catch (verifyError) {
        console.error('Error verifying Nodemailer transporter:', verifyError);
        throw verifyError;
    }

    // Email options
    let mailOptions = {
        from: emailUser,
        to: toEmail,
        subject: subject,
        text: 'Please find attached the animal activity report.',
        html: htmlContent,
        attachments: [
            {
                filename: 'animal_activity_report.csv',
                path: filePath
            }
        ]
    };
    console.log('Mail options prepared:', JSON.stringify(mailOptions, null, 2));

    // Send email
    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('Email sent successfully. Message ID:', info.messageId);
    } catch (sendError) {
        console.error('Error sending email:', sendError);
        throw sendError;
    }
}
