#!/usr/bin/env node

// Script to retrieve total code coverage ratio from codecov.io
// for a given commit hash, and upload it to the S3 bucket.

const https = require('https');
const zlib = require('zlib');
const AWS = require('aws-sdk');
const {execSync} = require('child_process');

const args = process.argv.slice(2);
const options = {
    help: false
};

const usage = 'usage: publish_coverage.js [options]\n' +
'options: \n' +
'  -h, --help \n' +
'  -C, --component <Component Name> \n' +
'  -c, --commit <Commit Hash> \n' +
'  -t, --token <Access token> \n';

for (var i = 0; i < args.length; i++) {
    var arg = args[i];

    switch(arg) {
    case '-h':
    case '--help':
        options.help = true;
        break;
    case '-C':
    case '--component':
        options.componentName = args[i + 1];
        break;
    case '-c':
    case '--commit':
        options.commitId = args[i + 1];
        break;
    case '-t':
    case '--token':
        options.accessToken = args[i + 1];
        break;
    }
}

if (options.help == true) {
    console.log(usage);
    process.exit(0);
}

// Access token
const token = options.accessToken ? options.accessToken : process.env.CODECOV_DOWNLOAD_TOKEN;
if (!token) {
    throw new Error ('access token is not set');
}

// Commit hash
const commitHash = options.commitId ? options.commitId : process.env['CIRCLE_SHA1'];
if (!options.componentName || !commitHash) {
    console.log(usage);
    process.exit(0);
}

// Commit Message
const commitMessage = execSync(`git show --pretty=format:%s -s ${commitHash}`).toString().trim();
if (!commitMessage) {
    throw new Error ('Commit message is missing');
}

const date = new Date().toISOString().substring(0, 19);

process.on('uncaughtException', (err) => {
    console.error(err);
    process.exit(1);
});

// Parse the response received from codecov.io and build the
// data point that is going to be uploaded to S3 bucket.
function parseResponse(data) {
    if (data && data.commit) {
        if (!data.commit.totals || !data.commit.totals.c) {
            return;
        }

        const source = {
            code_coverage: Number(data.commit.totals.c),
            component: options.componentName,
            commit: commitHash,
            commit_message: commitMessage,
            created_at: date
        };

        console.log(data);
        return source;
    }
}

// Upload to data source used by Mapbox internal metrics dashboards
function uploadData(data) {
    return new AWS.S3({region: 'us-east-1'}).putObject({
        Body: zlib.gzipSync(JSON.stringify(data)),
        Bucket: 'mapbox-loading-dock',
        Key: `raw/mobile_staging.codecoverage_v2/${date.substring(0,10)}/${options.componentName}-coverage-${commitHash}.json.gz`,
        CacheControl: 'max-age=300',
        ContentEncoding: 'gzip',
        ContentType: 'application/json'
    }).promise();
}

// Attempt to retrieve code coverage report from codecov.io
// for a given commit hash.
function httpRequest() {
    const options = {
        hostname: 'codecov.io',
        port: 443,
        path: '/api/gh/mapbox/mapbox-navigation-ios/commit/' + commitHash,
        method: 'GET',
        headers: {
            'Authorization': `token ${token}`
        }
    };

    return new Promise((resolve, reject) => {
        setTimeout(function() {
            const req = https.request(options, (res) => {
                var body = [];
                res.on('data', (chunk) => {
                    body.push(chunk);
                }).on('error', (error) => {
                    reject(error);
                }).on('end', () => {
                    if (res.statusCode < 200 || res.statusCode >= 300) {
                        return reject(new Error('Failed to fetch coverage report from codecov.io. StatusCode=' + res.statusCode));
                    }

                    try {
                        body = JSON.parse(Buffer.concat(body).toString());
                        resolve(body);
                    } catch(e) {
                        reject(e);
                    }
                });
            });

            // Reject on error
            req.on('error', (err) => {
                reject(err);
            });

            req.end();
        }, 30000);
    });
}

var errResponse = false;
const publishWithRetry = (maxRetries) =>  {
    httpRequest().then((body) => {
        const dataSource = parseResponse(body);
        if (dataSource) {
            return //uploadData(dataSource);
        } else {
            errResponse = true;
            throw new Error('Failed to parse coverage report received from codecov.io.');
        }
    }).then(data => {
        console.log('Successfully uploaded code coverage metrics to S3');
    }).catch(err => {
        if (maxRetries > 1 && errResponse) {
            console.log('Invalid coverage report received. Trying to retrieve again.');
            errResponse = false;
            return publishWithRetry(maxRetries - 1);
        }

        console.error('Failed to upload code coverage metrics to S3: ' + err.message);
    });
};

// Fetch and publish code coverage report
publishWithRetry(5);